import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/navigatorkey.dart';
import 'package:randevu_sistem/services/notification_popup.dart';
import 'package:randevu_sistem/services/notification_router.dart';
import 'package:randevu_sistem/services/notification_types.dart';

/// Backend host'u sabit. Build'e göre değişiyorsa burayı tek noktadan değiştir.
const _apiBase = 'https://apptest.randevumcepte.com.tr/api/v1';

/// Android bildirim kanalları. Tipler buradaki id'lere göre dağıtılır.
const _channelDefault   = AndroidNotificationChannel(
  'rmc_default',
  'Genel Bildirimler',
  description: 'Genel uygulama bildirimleri',
  importance: Importance.defaultImportance,
);
const _channelImportant = AndroidNotificationChannel(
  'rmc_important',
  'Önemli Bildirimler',
  description: 'Randevu, mesaj, ödeme gibi önemli bildirimler',
  importance: Importance.high,
);
const _channelPromo     = AndroidNotificationChannel(
  'rmc_promo',
  'Kampanya ve İndirimler',
  description: 'Kampanya, indirim ve çark hatırlatmaları',
  importance: Importance.high,
);

/// Arka planda gelen FCM mesajları için top-level handler.
/// Burada UI çizilmez; sadece data işlenir / log atılır.
@pragma('vm:entry-point')
Future<void> rmcNotificationBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('🔔 [BG] FCM mesaj: ${message.messageId} data=${message.data}');
}

/// Token / izin durumu. UI bunu dinleyip uyarı banner'ı gösterebilir.
enum NotificationStatus {
  unknown,           // henuz init olmadi
  ok,                // token alindi
  permissionDenied,  // kullanici izin vermedi
  unavailable,       // Google Play Services yok / iOS APNS yok / network vs.
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;

  /// UI tarafi bunu dinler. Token yoksa banner gosterilebilir.
  static final ValueNotifier<NotificationStatus> status =
      ValueNotifier<NotificationStatus>(NotificationStatus.unknown);

  Timer? _retryTimer;
  int _retryAttempt = 0;

  /// main() içinde Firebase.initializeApp()'den SONRA çağır.
  /// Kullanıcı login değilse bile token alınıp local'e yazılır;
  /// login sonrası registerForUser() ile backend'e bağlanır.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1) Permission
    await _requestPermission();

    // 2) Android channels
    await _createAndroidChannels();

    // 3) iOS foreground gösterimi (banner + sound + badge)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4) Local notifications init (foreground banner için)
    await _initLocalPlugin();

    // 5) Foreground mesaj akışı
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 6) Tıklamayla arka plandan açılma
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    // 7) Uygulama tamamen kapalıyken tıklama ile açılış
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // İlk frame çizildikten sonra yönlendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onMessageOpened(initial);
      });
    }

    // 8) Token al ve local'e yaz
    await _refreshLocalToken();

    // 9) Token refresh listener
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _fcm.onTokenRefresh.listen((token) async {
      log('🔁 FCM token yenilendi');
      _currentToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      // Eğer login'liyse otomatik yeniden kaydet
      final tip = prefs.getString('notif_kullanici_tipi');
      if (tip != null) {
        await _sendRegisterRequest(prefs, token, tip);
      }
    });
  }

  Future<void> _requestPermission() async {
    // iOS / macOS / Android 13+
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    log('🔔 FCM permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      status.value = NotificationStatus.permissionDenied;
    }

    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  Future<void> _createAndroidChannels() async {
    if (!Platform.isAndroid) return;
    final plugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(_channelDefault);
    await plugin?.createNotificationChannel(_channelImportant);
    await plugin?.createNotificationChannel(_channelPromo);
  }

  Future<void> _initLocalPlugin() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload));
          _handleTap(NotificationPayload.fromMap(data));
        } catch (e) {
          log('Local notif payload parse hata: $e');
        }
      },
    );
  }

  Future<bool> _refreshLocalToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        log('✅ FCM token: ${token.substring(0, 24)}...');
        status.value = NotificationStatus.ok;
        _retryAttempt = 0;
        _stopRetryTimer();
        return true;
      }
      log('⚠️ FCM token bos dondu');
      _markTokenUnavailable();
      return false;
    } catch (e) {
      log('❌ FCM token alınamadı: $e');
      _markTokenUnavailable();
      return false;
    }
  }

  /// Token alinamadiginda: status'u uygun degere set et + retry timer baslat.
  /// Permission denied durumu zaten _requestPermission'da set ediliyor; o
  /// durumda timer baslatma anlamsiz (retry yine de denenebilir, kullanici
  /// ayarlardan izin actiysa yakalariz).
  void _markTokenUnavailable() {
    if (status.value != NotificationStatus.permissionDenied) {
      status.value = NotificationStatus.unavailable;
    }
    _startRetryTimer();
  }

  /// 5 dk arayla token + register denemesi. Token gelirse otomatik durur.
  void _startRetryTimer() {
    if (_retryTimer != null && _retryTimer!.isActive) return;
    _retryTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      _retryAttempt++;
      log('🔁 FCM token retry attempt=$_retryAttempt');
      // izin tekrar dene (kullanici Ayarlar'dan acmis olabilir)
      try {
        final settings = await _fcm.requestPermission(
          alert: true, badge: true, sound: true, provisional: false,
        );
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          // izin ok → token al
          if (status.value == NotificationStatus.permissionDenied) {
            status.value = NotificationStatus.unavailable;
          }
        }
      } catch (_) {}

      final ok = await _refreshLocalToken();
      if (ok) {
        // Login durumundaysa backend'e de yeniden kaydet
        final prefs = await SharedPreferences.getInstance();
        final tip = prefs.getString('notif_kullanici_tipi');
        if (tip != null && _currentToken != null) {
          await _sendRegisterRequest(prefs, _currentToken!, tip);
        }
      }
    });
  }

  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// App lifecycle: foreground'a gelince hemen bir kez dene (timer'i beklemeden).
  Future<void> onAppResumed() async {
    if (status.value == NotificationStatus.ok) return;
    log('▶️ App resumed → FCM token retry');
    await _refreshLocalToken();
    if (_currentToken != null) {
      final prefs = await SharedPreferences.getInstance();
      final tip = prefs.getString('notif_kullanici_tipi');
      if (tip != null) {
        await _sendRegisterRequest(prefs, _currentToken!, tip);
      }
    }
  }

  /// Login sonrası çağrılır. Müşteri için userId, personel için personelId,
  /// salon sahibi için yetkiliId verilir. Sadece ilgili olan dolu olur.
  Future<void> registerForUser({
    required String kullaniciTipi, // 'musteri' | 'personel' | 'yetkili'
    String? userId,
    String? personelId,
    String? yetkiliId,
    String? salonId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = _currentToken ?? prefs.getString('fcm_token');
    if (token == null || token.isEmpty) {
      await _refreshLocalToken();
    }
    final t = _currentToken ?? prefs.getString('fcm_token');
    if (t == null || t.isEmpty) {
      log('⚠️ Token yok, kayıt atlandı');
      return;
    }

    await prefs.setString('notif_kullanici_tipi', kullaniciTipi);
    if (userId != null)     await prefs.setString('notif_user_id', userId);
    if (personelId != null) await prefs.setString('notif_personel_id', personelId);
    if (yetkiliId != null)  await prefs.setString('notif_yetkili_id', yetkiliId);
    if (salonId != null)    await prefs.setString('notif_salon_id', salonId);

    await _sendRegisterRequest(prefs, t, kullaniciTipi);
  }

  Future<void> _sendRegisterRequest(
      SharedPreferences prefs, String token, String tip) async {
    String? cihazId;
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        cihazId = (await info.androidInfo).id;
      } else if (Platform.isIOS) {
        cihazId = (await info.iosInfo).identifierForVendor;
      }
    } catch (_) {}

    String appBundle = '';
    try {
      appBundle = (await PackageInfo.fromPlatform()).packageName;
    } catch (_) {}

    final body = {
      'token': token,
      'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web'),
      'kullanici_tipi': tip,
      'user_id': prefs.getString('notif_user_id') ?? '',
      'personel_id': prefs.getString('notif_personel_id') ?? '',
      'yetkili_id': prefs.getString('notif_yetkili_id') ?? '',
      'salon_id': prefs.getString('notif_salon_id') ?? '',
      'cihaz': cihazId ?? '',
      'app_bundle': appBundle,
    };

    try {
      final res = await http.post(
        Uri.parse('$_apiBase/bildirim/cihaz-kaydet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        log('✅ Bildirim cihazı kayıtlı: ${res.body}');
      } else {
        log('⚠️ Bildirim cihazı kayıt başarısız ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      log('❌ Bildirim cihazı kayıt hata: $e');
    }
  }

  /// Logout sırasında çağrılır — token pasifleştirilir.
  Future<void> unregister() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _currentToken ?? prefs.getString('fcm_token');
    if (token == null) return;

    try {
      await http.post(
        Uri.parse('$_apiBase/bildirim/cihaz-sil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      log('Token sil hata: $e');
    }

    await prefs.remove('notif_kullanici_tipi');
    await prefs.remove('notif_user_id');
    await prefs.remove('notif_personel_id');
    await prefs.remove('notif_yetkili_id');
    await prefs.remove('notif_salon_id');
  }

  // ─── Foreground / Tap handler'lar ────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    log('🔔 [FG] ${message.notification?.title} data=${message.data}');
    final payload = NotificationPayload.fromMap(message.data);

    // Yetki degisti → Yetki.tazele tetiklenir; eski cache ile fark varsa
    // Yetki.yetkiAyarlariDegisti notifier'i true olur ve bottom_nav
    // listener'i otomatik popup + logout akisini calistirir.
    if (payload.type == NotificationTypes.yetkiDegisti) {
      _handleYetkiDegisti();
      return;
    }

    // Promosyon tipleri → büyük popup
    if (NotificationTypes.isPopup(payload.type)) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        await showPromoNotificationPopup(
          ctx,
          payload: payload,
          fallbackTitle: message.notification?.title,
          fallbackBody: message.notification?.body,
        );
        return;
      }
    }

    // Diğer tipler → local notification olarak banner göster
    await _showAsLocal(message, payload);
  }

  Future<void> _onMessageOpened(RemoteMessage message) async {
    log('👉 [TAP] ${message.notification?.title} data=${message.data}');
    final payload = NotificationPayload.fromMap(message.data);
    _handleTap(payload);
  }

  void _handleTap(NotificationPayload payload) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    // Yetki guncellendi → tazele + dialog + logout otomatik calisir.
    if (payload.type == NotificationTypes.yetkiDegisti) {
      _handleYetkiDegisti();
      return;
    }

    // Popup tipleri tıklamada da popup'la açılır
    if (NotificationTypes.isPopup(payload.type)) {
      showPromoNotificationPopup(ctx, payload: payload);
      return;
    }

    NotificationRouter.route(ctx, payload);
  }

  /// Push: yetki ayarlari guncellendi. Salonid'yi mevcut secili subeden alip
  /// Yetki.tazele cagirir. Yetki cache eski ile karsilastirilir; fark varsa
  /// Yetki.yetkiAyarlariDegisti notifier'i tetiklenir ve bottom_nav'deki
  /// listener popup + zorla logout akisini baslatir.
  Future<void> _handleYetkiDegisti() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? salonid = prefs.getString('sube');
      salonid = (salonid != null && salonid.isNotEmpty) ? salonid : null;
      if (salonid != null) {
        await Yetki.tazele(salonid: salonid);
      } else {
        // Sube bilinmiyorsa cache'i tamamen temizle → kullanici tekrar
        // login olunca taze yetki cekecek.
        await Yetki.temizle();
      }
    } catch (e) {
      log('Yetki push handler hatasi: $e');
    }
  }

  Future<void> _showAsLocal(
      RemoteMessage message, NotificationPayload payload) async {
    final n = message.notification;
    final title = payload.title ?? n?.title ?? 'Bildirim';
    final body  = payload.body  ?? n?.body  ?? '';

    final channelId = NotificationTypes.isPopup(payload.type)
        ? _channelPromo.id
        : NotificationTypes.isHighPriority(payload.type)
            ? _channelImportant.id
            : _channelDefault.id;

    AndroidNotificationDetails androidDetails;
    if (payload.image != null) {
      // BigPictureStyle — resimli notification
      androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == _channelImportant.id
            ? 'Önemli Bildirimler'
            : channelId == _channelPromo.id
                ? 'Kampanya ve İndirimler'
                : 'Genel Bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigPictureStyleInformation(
          await _resolveBigPicture(payload.image!),
          contentTitle: title,
          summaryText: body,
        ),
      );
    } else {
      androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == _channelImportant.id
            ? 'Önemli Bildirimler'
            : channelId == _channelPromo.id
                ? 'Kampanya ve İndirimler'
                : 'Genel Bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
      );
    }

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: payload.image != null
          ? [DarwinNotificationAttachment(payload.image!)]
          : null,
    );

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(payload.raw),
    );
  }

  Future<ByteArrayAndroidBitmap> _resolveBigPicture(String url) async {
    final res = await http.get(Uri.parse(url));
    return ByteArrayAndroidBitmap.fromBase64String(base64Encode(res.bodyBytes));
  }
}
