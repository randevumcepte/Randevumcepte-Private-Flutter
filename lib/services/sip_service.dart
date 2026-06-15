import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:uuid/uuid.dart';

import '../Models/user.dart';
import '../navigatorkey.dart';
import '../Frontend/dialpad.dart';
import '../yonetici/santral/sipsrc/callscreen.dart';

/// Santral (FreePBX/Asterisk) WebRTC/WSS sabitleri. Tum beyaz-etiket
/// buildlerde ayni altyapi kullanildigi icin merkezi const olarak tutulur.
const String kSipWsUrl = 'wss://santral.randevumcepte.com.tr:8089/ws';
const String kSipDomain = 'santral.randevumcepte.com.tr';

/// Softphone (SIP/WebRTC) ana anahtari. Google Play hassas on plan hizmeti
/// izinlerini (FOREGROUND_SERVICE_MICROPHONE/PHONE_CALL) beyan+video istedigi
/// ve ozellik henuz tam dogrulanmadigi icin bu surumde KAPALI. Kapaliyken
/// register ve CallKit dinleyicisi hic baslamaz, dolayisiyla on plan hizmeti
/// tetiklenmez (izinler manifestten cikarildigi icin cokme riski olmaz).
/// Softphone hazir olunca: bunu true yap + AndroidManifest.xml'deki
/// tools:node="remove" satirlarini normal izinlere cevir + Play beyanini doldur.
const bool kSoftphoneEnabled = true;

/// Tek [SIPUAHelper]'i sahiplenen singleton servis.
///
/// UI (KeyPad/DialPadWidget) ve arka plan push akisi ayni helper'i paylasir,
/// boylece dahili tek sefer register olur. Gelen cagriyi CallKit /
/// ConnectionService UI'si ile (kilitli ekran dahil) gosterir, kullanici
/// kabul edince cagriyi yanitlar ve [CallScreenWidget]'a yonlendirir.
///
/// Cikis akislari:
/// - Login sonrasi: [attachUi] + [baslat] cagrilir (navigasyondan bagimsiz
///   kalici register).
/// - Push ile uyandirma (uygulama kapali): FCM/VoIP push CallKit'i gosterir;
///   kullanici Kabul'e basinca [_onCallkitEvent] -> [baslat] register eder,
///   gelen INVITE geldiginde [_pendingAutoAnswer] sayesinde otomatik yanitlar.
class SipService implements SipUaHelperListener {
  SipService._();
  static final SipService instance = SipService._();

  final SIPUAHelper helper = SIPUAHelper();
  final ValueNotifier<RegistrationStateEnum?> registrationState =
      ValueNotifier<RegistrationStateEnum?>(null);

  bool _started = false;
  bool _listenerBound = false;
  bool _callkitBound = false;

  String dahili = '';
  String _dahiliSifre = '';

  // CallScreen yonlendirmesi icin UI referanslari (nav bar tarafindan set edilir).
  Kullanici? _kullanici;
  DialPadManager? _dialPadManager;

  Call? _activeCall;
  String? _activeCallkitId;
  // Uygulama push ile acildiginda kullanici Kabul'e bastiysa ama INVITE henuz
  // gelmediyse: INVITE geldiginde otomatik yanitla.
  bool _pendingAutoAnswer = false;

  /// Nav bar initState'te cagrilir. CallScreen'e parametre saglamak icin
  /// gerekli UI referanslarini saklar.
  void attachUi(Kullanici kullanici, DialPadManager dialPadManager) {
    _kullanici = kullanici;
    _dialPadManager = dialPadManager;
  }

  /// SIP register'i baslatir. dahili/sifre verilirse onlar kullanilir ve
  /// prefs'e yazilir (push-accept yolunun yeniden yukleyebilmesi icin);
  /// verilmezse prefs'ten yuklenir. Idempotent — tekrar cagrilirsa yeniden
  /// register eder.
  Future<void> baslat({String? dahiliNo, String? sifre}) async {
    if (!kSoftphoneEnabled) {
      log('SIP: softphone kapali (kSoftphoneEnabled=false), register atlandi');
      return;
    }
    _bindHelperListener();
    _bindCallkitEvents();

    // Idempotency: ayni dahili/sifre ile zaten baslatildiysa tekrar stop/start
    // yapma. Nav bar ve dialpad ikisi de baslat() cagirdigi icin, bu olmadan
    // her cagri unregister(Expires:0)+register yapip kaydi "flap" ettiriyordu.
    final yeniDahili =
        (dahiliNo != null && dahiliNo.isNotEmpty) ? dahiliNo : dahili;
    final yeniSifre = sifre ?? _dahiliSifre;
    if (_started && yeniDahili == dahili && yeniSifre == _dahiliSifre) {
      log('SIP: zaten baslatildi (dahili=$dahili), tekrar register atlandi');
      return;
    }

    if (dahiliNo != null && dahiliNo.isNotEmpty && sifre != null) {
      dahili = dahiliNo;
      _dahiliSifre = sifre;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sip_dahili', dahili);
      await prefs.setString('sip_dahili_sifre', _dahiliSifre);
    } else if (dahili.isEmpty) {
      final yuklendi = await _prefstenYukle();
      if (!yuklendi) {
        log('SIP: dahili bulunamadi, register atlandi');
        return;
      }
    }
    if (dahili.isEmpty || dahili == 'null') {
      log('SIP: gecersiz dahili, register atlandi');
      return;
    }

    final settings = UaSettings()
      ..webSocketUrl = kSipWsUrl
      ..webSocketSettings.allowBadCertificate = true
      ..uri = 'sip:$dahili@$kSipDomain'
      ..authorizationUser = dahili
      ..password = _dahiliSifre
      ..displayName = dahili
      ..transportType = TransportType.WS
      ..register = true
      ..userAgent = 'Randevumcepte SIP v1.0.0'
      ..dtmfMode = DtmfMode.RFC2833;

    try {
      if (_started) {
        helper.stop();
      }
      await helper.start(settings);
      _started = true;
      log('SIP: register baslatildi (dahili=$dahili)');
    } catch (e) {
      log('SIP baslatilamadi: $e');
    }
  }

  Future<bool> _prefstenYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('sip_dahili') ?? '';
    final s = prefs.getString('sip_dahili_sifre') ?? '';
    if (d.isEmpty || d == 'null') return false;
    dahili = d;
    _dahiliSifre = s;
    return true;
  }

  /// Logout / oturum kapatmada cagrilir.
  Future<void> durdur() async {
    try {
      if (_started) helper.stop();
    } catch (_) {}
    _started = false;
    _activeCall = null;
    registrationState.value = null;
  }

  bool get kayitli =>
      registrationState.value == RegistrationStateEnum.REGISTERED;

  void _bindHelperListener() {
    if (_listenerBound) return;
    helper.addSipUaHelperListener(this);
    _listenerBound = true;
  }

  // ---------------------------------------------------------------------------
  // Giden cagri (DialPadWidget bunu da kullanabilir; merkezi yardimci)
  // ---------------------------------------------------------------------------
  Future<void> ara(String hedef) async {
    if (hedef.isEmpty) return;
    await Permission.microphone.request();
    final mediaStream = await navigator.mediaDevices
        .getUserMedia(<String, dynamic>{'audio': true, 'video': false});
    helper.call(hedef, mediaStream: mediaStream);
  }

  // ---------------------------------------------------------------------------
  // Gelen cagri — CallKit/ConnectionService gosterimi + yanitlama
  // ---------------------------------------------------------------------------
  Future<void> _gelenCagriUIGoster(Call call) async {
    _activeCallkitId = const Uuid().v4();
    final arayan = call.remote_identity ?? 'Bilinmeyen';
    await FlutterCallkitIncoming.showCallkitIncoming(
        gelenCagriParams(_activeCallkitId!, arayan));
  }

  /// main()'de erken cagrilir: CallKit olay dinleyicisini baglar; boylece
  /// uygulama push-accept ile acildiginda Kabul olayi kacirilmaz.
  void initCallkitListener() {
    if (!kSoftphoneEnabled) return;
    _bindCallkitEvents();
  }

  Future<void> _cagriyiYanitla() async {
    final call = _activeCall;
    if (call == null) return;
    try {
      await Permission.microphone.request();
      final mediaStream = await navigator.mediaDevices
          .getUserMedia(<String, dynamic>{'audio': true, 'video': false});
      call.answer(helper.buildCallOptions(true), mediaStream: mediaStream);
      _callScreenAc(call);
    } catch (e) {
      log('SIP: cagri yanitlanamadi: $e');
    }
  }

  void _callScreenAc(Call call) {
    final nav = navigatorKey.currentState;
    final k = _kullanici;
    final dpm = _dialPadManager;
    if (nav == null || k == null || dpm == null) {
      log('SIP: CallScreen acilamadi (UI referansi yok)');
      return;
    }
    nav.push(MaterialPageRoute(
      builder: (_) => CallScreenWidget(helper, call, dpm, k),
    ));
  }

  Future<void> _callkitTemizle() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
    _activeCallkitId = null;
  }

  void _bindCallkitEvents() {
    if (_callkitBound) return;
    _callkitBound = true;
    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      switch (event.event) {
        case Event.actionCallAccept:
          // Push ile uyandirma: register ol; INVITE varsa yanitla, yoksa
          // INVITE geldiginde otomatik yanitla.
          if (!_started || !kayitli) {
            _pendingAutoAnswer = true;
            await baslat();
          }
          if (_activeCall != null) {
            await _cagriyiYanitla();
          } else {
            _pendingAutoAnswer = true;
          }
          break;
        case Event.actionCallDecline:
          _activeCall?.hangup({'status_code': 603});
          _activeCall = null;
          _pendingAutoAnswer = false;
          await _callkitTemizle();
          break;
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          _activeCall?.hangup();
          _activeCall = null;
          _pendingAutoAnswer = false;
          break;
        case Event.actionCallCallback:
          // Cevapsiz arama bildiriminden geri ara
          final number = event.body?['number']?.toString() ?? '';
          if (number.isNotEmpty && _dialPadManager != null && _kullanici != null) {
            final ctx = navigatorKey.currentContext;
            if (ctx != null) {
              _dialPadManager!.updateDialPad(ctx, true, number, _kullanici!);
            }
          }
          break;
        default:
          break;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // SipUaHelperListener
  // ---------------------------------------------------------------------------
  @override
  void registrationStateChanged(RegistrationState state) {
    registrationState.value = state.state;
    log('SIP register durum: ${state.state}');
  }

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void callStateChanged(Call call, CallState callState) {
    // Yalnizca GELEN cagrilari merkezi olarak yonet. Giden cagrilar
    // DialPadWidget tarafindan ele alinir (CallScreen'e oradan gidilir).
    if (callState.state == CallStateEnum.CALL_INITIATION &&
        call.direction == 'INCOMING') {
      _activeCall = call;
      if (_pendingAutoAnswer) {
        _pendingAutoAnswer = false;
        _cagriyiYanitla();
      } else {
        _gelenCagriUIGoster(call);
      }
      return;
    }

    if (callState.state == CallStateEnum.ENDED ||
        callState.state == CallStateEnum.FAILED) {
      if (identical(call, _activeCall)) {
        _activeCall = null;
        _pendingAutoAnswer = false;
        _callkitTemizle();
      }
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}
}

/// Gelen cagri icin CallKit/ConnectionService parametreleri (kilitli ekran
/// dahil). Hem canli INVITE (SipService) hem de FCM push (arka plan isolate)
/// ayni gorunumu kullanir.
CallKitParams gelenCagriParams(String id, String arayan) => CallKitParams(
      id: id,
      nameCaller: arayan,
      appName: 'Randevumcepte',
      handle: arayan,
      type: 0,
      duration: 30000,
      textAccept: 'YANITLA',
      textDecline: 'REDDET',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Cevapsiz Arama',
        callbackText: 'Geri Ara',
      ),
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'Gelen Arama',
        missedCallNotificationChannelName: 'Cevapsiz Arama',
        isShowFullLockedScreen: true,
        isImportant: true,
        isBot: false,
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

/// FCM data mesajindan (type=='sip_incoming') CallKit gelen-cagri UI'sini
/// gosterir. Arka plan isolate'inden cagrilabilir (singleton durumu gerekmez).
/// Kullanici Kabul'e basinca uygulama acilir, [SipService.baslat] register
/// olur ve gelen INVITE otomatik yanitlanir.
@pragma('vm:entry-point')
Future<void> sipIncomingCallkitGoster(Map<String, dynamic> data) async {
  final arayan =
      (data['caller'] ?? data['arayan'] ?? 'Bilinmeyen').toString();
  final id = (data['call_id'] ?? const Uuid().v4()).toString();
  await FlutterCallkitIncoming.showCallkitIncoming(gelenCagriParams(id, arayan));
}
