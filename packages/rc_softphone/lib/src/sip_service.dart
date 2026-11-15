import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show Helper;
import 'package:sip_ua/sip_ua.dart';
import 'package:uuid/uuid.dart';

import 'arama_ekrani.dart';
import 'ios_ses.dart';

/// Mobil SIP softphone servisi (sip_ua + flutter_webrtc + CallKit).
///
/// Sunucu: santral.randevumcepte.com.tr:8089 (WSS), chan_sip WebRTC dahilisi.
/// Dahili bilgisi `salon_personelleri.dahili_no_webrtc` / `dahili_sifre_webrtc`
/// kolonlarindan okunur (basic_bottom_nav_bar.dart).
///
/// Aktif bir cagri basladiginda (giden) ya da gelen cagri cevaplandiginda
/// [AramaEkrani] verilen navigatorKey uzerinden otomatik acilir; cagri
/// bitince ekran kendini kapatir.
const String kSipDomain = 'santral.randevumcepte.com.tr';
const String kSipWssUrl = 'wss://santral.randevumcepte.com.tr:8089/ws';

class SipService implements SipUaHelperListener {
  SipService._();
  static final SipService instance = SipService._();

  final SIPUAHelper _helper = SIPUAHelper();
  SIPUAHelper get helper => _helper;

  // --- UI'nin dinledigi durumlar ---
  final ValueNotifier<RegistrationStateEnum?> registrationState =
      ValueNotifier<RegistrationStateEnum?>(null);
  final ValueNotifier<bool> kayitli = ValueNotifier<bool>(false);
  final ValueNotifier<Call?> activeCall = ValueNotifier<Call?>(null);
  final ValueNotifier<CallStateEnum?> callState =
      ValueNotifier<CallStateEnum?>(null);
  final ValueNotifier<bool> sessiz = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hoparlor = ValueNotifier<bool>(false);
  final ValueNotifier<bool> beklemede = ValueNotifier<bool>(false);

  /// Karsi taraf acinca dolar; sure sayaci buradan hesaplanir.
  final ValueNotifier<DateTime?> baglandiZamani = ValueNotifier<DateTime?>(null);

  /// Son cagrinin bitis/hata aciklamasi (ekranda kisa sure gosterilir).
  final ValueNotifier<String?> bitisNedeni = ValueNotifier<String?>(null);

  /// Ekranda gosterilecek karsi taraf adi (giden aramada uygulama verir).
  String? karsiTarafAdi;
  String? karsiTarafNumara;

  String? _dahili;
  String? _dahiliSifre;
  bool _started = false;
  bool _callkitListenerKuruldu = false;
  String? _currentCallkitId;

  /// Su anki cagri CallKit uzerinden mi geldi? (iOS ses koprusu icin)
  bool _callkitCagrisi = false;
  bool _ekranAcik = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  bool get registered => _helper.registered;

  /// Dahili bilgisiyle register ol. Dahili degistiyse yeniden baslatir.
  Future<void> init({
    required String dahili,
    required String dahiliSifre,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    if (navigatorKey != null) _navigatorKey = navigatorKey;
    if (dahili.isEmpty || dahili == 'null') return;
    if (dahiliSifre.isEmpty || dahiliSifre == 'null') return;

    // Ayni dahili zaten baslatildiysa tekrar baslatma.
    if (_started && _dahili == dahili && _dahiliSifre == dahiliSifre) return;

    _dahili = dahili;
    _dahiliSifre = dahiliSifre;

    _kurCallkitListener();

    if (_started) {
      await _restart();
    } else {
      _start();
    }
  }

  void _start() {
    final UaSettings settings = UaSettings();
    settings.webSocketUrl = kSipWssUrl;
    settings.webSocketSettings.allowBadCertificate = false;
    settings.webSocketSettings.userAgent = 'RandevumcepteMobil (sip_ua)';
    settings.uri = 'sip:$_dahili@$kSipDomain';
    settings.authorizationUser = _dahili;
    settings.password = _dahiliSifre;
    settings.displayName = _dahili;
    settings.userAgent = 'RandevumcepteMobil';
    settings.dtmfMode = DtmfMode.RFC2833;
    settings.transportType = TransportType.WS;
    settings.register = true;
    settings.register_expires = 600;
    settings.contact_uri = 'sip:$_dahili@$kSipDomain;transport=ws';

    _helper.addSipUaHelperListener(this);
    _helper.start(settings);
    _started = true;
  }

  Future<void> _restart() async {
    try {
      _helper.stop();
    } catch (_) {}
    // Transport'un kapanmasi icin kisa bekleme.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _start();
  }

  /// Logout / dahili degisimi / lisans bitimi gibi durumlarda kapat.
  Future<void> kapat() async {
    try {
      activeCall.value?.hangup();
    } catch (_) {}
    try {
      if (registered) {
        _helper.unregister();
      }
      _helper.stop();
    } catch (_) {}
    _helper.removeSipUaHelperListener(this);
    await _endCallkit();
    _started = false;
    _dahili = null;
    _dahiliSifre = null;
    registrationState.value = RegistrationStateEnum.UNREGISTERED;
    kayitli.value = false;
    _cagriDurumunuSifirla();
  }

  // --- Giden cagri ---
  /// [hedef]: dis numara ('05xx...') ya da dahili. [gorunenAd] ekranda
  /// numara yerine gosterilir (musteri adi gibi).
  Future<bool> cagriBaslat(String hedef, {String? gorunenAd}) async {
    if (!_helper.registered) return false;
    if (activeCall.value != null) return false; // tek hat
    final String temiz = hedef.contains('@')
        ? hedef
        : hedef.replaceAll(RegExp(r'[^0-9*#+]'), '');
    if (temiz.isEmpty) return false;
    karsiTarafAdi = gorunenAd;
    karsiTarafNumara = temiz;
    bitisNedeni.value = null;
    final String dest = temiz.contains('@') ? temiz : 'sip:$temiz@$kSipDomain';
    return _helper.call(dest, voiceOnly: true);
  }

  // --- Cagri kontrolleri ---
  void cevapla() {
    activeCall.value?.answer(_answerOptions());
  }

  void kapatCagri() {
    try {
      activeCall.value?.hangup();
    } catch (_) {}
    _endCallkit();
  }

  void sessizToggle([bool? deger]) {
    final Call? call = activeCall.value;
    if (call == null) return;
    final bool yeni = deger ?? !sessiz.value;
    if (yeni) {
      call.mute(true, false);
    } else {
      call.unmute(true, false);
    }
    sessiz.value = yeni;
  }

  Future<void> hoparlorToggle([bool? deger]) async {
    final bool yeni = deger ?? !hoparlor.value;
    try {
      await Helper.setSpeakerphoneOn(yeni);
      hoparlor.value = yeni;
    } catch (e) {
      if (kDebugMode) debugPrint('[SIP] hoparlor hatasi: $e');
    }
  }

  void beklemeToggle() {
    final Call? call = activeCall.value;
    if (call == null) return;
    if (beklemede.value) {
      call.unhold();
    } else {
      call.hold();
    }
    beklemede.value = !beklemede.value;
  }

  void dtmfGonder(String tus) {
    activeCall.value?.sendDTMF(tus);
  }

  Map<String, dynamic> _answerOptions() {
    return <String, dynamic>{
      'mediaConstraints': <String, dynamic>{
        'audio': true,
        'video': false,
      },
    };
  }

  /// sip_ua 1.0.1 'INCOMING'/'OUTGOING' String, 1.1.0 Direction enum doner;
  /// ikisinde de calissin diye metin uzerinden bakilir.
  static bool _gelenMi(Call call) =>
      call.direction.toString().toLowerCase().contains('incoming');

  void _cagriDurumunuSifirla() {
    if (_callkitCagrisi) {
      _callkitCagrisi = false;
      IosSes.otomatikSeseDon();
    }
    activeCall.value = null;
    callState.value = null;
    sessiz.value = false;
    beklemede.value = false;
    baglandiZamani.value = null;
    if (hoparlor.value) {
      hoparlorToggle(false);
    }
  }

  // =========================================================================
  // Arama ekrani
  // =========================================================================
  void _ekraniAc() {
    if (_ekranAcik) return;
    final NavigatorState? nav = _navigatorKey?.currentState;
    if (nav == null) return;
    _ekranAcik = true;
    nav
        .push(MaterialPageRoute<void>(
          builder: (_) => const AramaEkrani(),
          fullscreenDialog: true,
        ))
        .whenComplete(() => _ekranAcik = false);
  }

  // =========================================================================
  // SipUaHelperListener
  // =========================================================================
  @override
  void registrationStateChanged(RegistrationState state) {
    registrationState.value = state.state;
    kayitli.value = state.state == RegistrationStateEnum.REGISTERED;
    if (kDebugMode) {
      debugPrint('[SIP] register => ${state.state} (${state.cause?.cause})');
    }
  }

  @override
  void transportStateChanged(TransportState state) {
    if (kDebugMode) debugPrint('[SIP] transport => ${state.state}');
  }

  @override
  void callStateChanged(Call call, CallState state) {
    callState.value = state.state;
    if (kDebugMode) {
      debugPrint('[SIP] call => ${state.state} dir=${call.direction}');
    }
    switch (state.state) {
      case CallStateEnum.CALL_INITIATION:
        activeCall.value = call;
        if (_gelenMi(call)) {
          karsiTarafAdi = (call.remote_display_name?.isNotEmpty ?? false)
              ? call.remote_display_name
              : null;
          karsiTarafNumara = call.remote_identity;
          bitisNedeni.value = null;
          _showIncomingCallkit(call);
        } else {
          _ekraniAc();
        }
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        baglandiZamani.value ??= DateTime.now();
        final String? ckId = _currentCallkitId;
        if (ckId != null) {
          // CallKit'e "baglandi" de (iOS sure/durum + ses kesintisi yonetimi).
          FlutterCallkitIncoming.setCallConnected(ckId).catchError((_) {});
        }
        // Gelen cagri CallKit'ten (ya da uygulamadan) cevaplandi.
        _ekraniAc();
        break;
      case CallStateEnum.HOLD:
        beklemede.value = true;
        break;
      case CallStateEnum.UNHOLD:
        beklemede.value = false;
        break;
      case CallStateEnum.ENDED:
        bitisNedeni.value = 'Arama sonlandı';
        _cagriDurumunuSifirla();
        _endCallkit();
        break;
      case CallStateEnum.FAILED:
        bitisNedeni.value = _hataMetni(state.cause?.cause);
        _cagriDurumunuSifirla();
        _endCallkit();
        break;
      default:
        break;
    }
  }

  static String _hataMetni(String? neden) {
    switch (neden) {
      case 'Busy':
        return 'Hat meşgul';
      case 'Rejected':
        return 'Arama reddedildi';
      case 'Unavailable':
      case 'Not Found':
        return 'Numaraya ulaşılamadı';
      case 'No Answer':
        return 'Cevap yok';
      case 'Canceled':
        return 'Arama iptal edildi';
      case 'User Denied Media Access':
        return 'Mikrofon izni verilmedi';
      default:
        return (neden == null || neden.isEmpty)
            ? 'Arama başarısız'
            : 'Arama başarısız ($neden)';
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  // =========================================================================
  // CallKit (gelen cagri UI + aksiyonlari)
  // =========================================================================
  void _kurCallkitListener() {
    if (_callkitListenerKuruldu) return;
    _callkitListenerKuruldu = true;
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      switch (event.event) {
        case Event.actionCallAccept:
          cevapla();
          break;
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          kapatCagri();
          break;
        case Event.actionCallToggleAudioSession:
          // iOS: CallKit ses oturumunu acti/kapatti -> WebRTC'ye bildir.
          final dynamic body = event.body;
          final bool acik = body is Map && body['isActivate'] == true;
          if (acik) {
            IosSes.callkitSesAktif();
          } else {
            IosSes.callkitSesPasif();
          }
          break;
        default:
          break;
      }
    });
  }

  Future<void> _showIncomingCallkit(Call call) async {
    final String id = const Uuid().v4();
    _currentCallkitId = id;
    _callkitCagrisi = true;
    // iOS: ses oturumunu CallKit acana kadar WebRTC beklesin (manuel mod).
    await IosSes.callkitIcinHazirla();
    final CallKitParams params = CallKitParams(
      id: id,
      nameCaller: (call.remote_display_name?.isNotEmpty ?? false)
          ? call.remote_display_name
          : (call.remote_identity ?? 'Gelen Arama'),
      handle: call.remote_identity ?? '',
      type: 0, // sesli
      textAccept: 'Cevapla',
      textDecline: 'Reddet',
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: false,
        audioSessionMode: 'default',
        audioSessionActive: true,
        supportsDTMF: true,
        supportsHolding: true,
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> _endCallkit() async {
    final String? id = _currentCallkitId;
    if (id != null) {
      try {
        await FlutterCallkitIncoming.endCall(id);
      } catch (_) {}
      _currentCallkitId = null;
    }
  }
}
