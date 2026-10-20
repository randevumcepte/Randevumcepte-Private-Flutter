import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:uuid/uuid.dart';

/// Mobil SIP softphone servisi (sip_ua + flutter_webrtc + CallKit).
///
/// Sunucu: santral.randevumcepte.com.tr:8089 (WSS), chan_sip WebRTC dahilisi.
/// Dahili bilgisi uygulamada `salon_personelleri.dahili_no_webrtc` /
/// `dahili_sifre_webrtc` kolonlarindan okunur (basic_bottom_nav_bar.dart).
///
/// 2026-10: app'ten sokulmustu, store uyumu (Play FGS + Apple VoIP) icin
/// kapatilmisti; sunucu tarafi [[softphone_server_webrtc]] ile duzeltilince
/// client sifirdan geri entegre edildi. Store beyanlari ayrica yapilacak.
// Store incelemesi icin GECICI kapali. Appeal sonrasi + yeni paket adi ile
// tekrar true yapilacak; sunucu tarafi hazir, degisiklik tek satir.
const bool kSoftphoneEnabled = false;

// Sesli Asistan (Patron Asistani + Sesli Randevu). Store incelemesi icin
// kapali; test tamamlaninca true yap. Kapali iken home ekranindaki
// "Asistan" FAB gizlenir, MIC/Speech permission istenmez.
const bool kAsistanEnabled = false;

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
  final ValueNotifier<Call?> activeCall = ValueNotifier<Call?>(null);
  final ValueNotifier<CallStateEnum?> callState =
      ValueNotifier<CallStateEnum?>(null);

  String? _dahili;
  String? _dahiliSifre;
  bool _started = false;
  bool _callkitListenerKuruldu = false;
  String? _currentCallkitId;

  bool get registered => _helper.registered;

  /// Dahili bilgisiyle register ol. Dahili zaten baslatilmissa (dahili
  /// degistiyse) yeniden baslatir.
  Future<void> init({
    required String dahili,
    required String dahiliSifre,
  }) async {
    if (!kSoftphoneEnabled) return;
    if (dahili.isEmpty || dahili == 'null') return;

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
      if (registered) {
        _helper.unregister();
      }
      _helper.stop();
    } catch (_) {}
    _helper.removeSipUaHelperListener(this);
    await _endCallkit();
    _started = false;
    registrationState.value = RegistrationStateEnum.UNREGISTERED;
    activeCall.value = null;
    callState.value = null;
  }

  // --- Giden cagri ---
  Future<bool> cagriBaslat(String hedef) async {
    if (!kSoftphoneEnabled || !_helper.registered) return false;
    final String dest =
        hedef.contains('@') ? hedef : 'sip:$hedef@$kSipDomain';
    return _helper.call(dest, voiceOnly: true);
  }

  // --- Gelen cagri cevapla / kapat ---
  void cevapla() {
    activeCall.value?.answer(_answerOptions());
  }

  void kapatCagri() {
    activeCall.value?.hangup();
    _endCallkit();
  }

  void sessizToggle(bool sessiz) {
    final Call? call = activeCall.value;
    if (call == null) return;
    if (sessiz) {
      call.mute(true, false);
    } else {
      call.unmute(true, false);
    }
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

  // =========================================================================
  // SipUaHelperListener
  // =========================================================================
  @override
  void registrationStateChanged(RegistrationState state) {
    registrationState.value = state.state;
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
        // sip_ua 1.1.0'da Call.direction String donuyor ('incoming'/'outgoing').
        if (call.direction == 'incoming') {
          _showIncomingCallkit(call);
        }
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        activeCall.value = null;
        _endCallkit();
        break;
      default:
        break;
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
        default:
          break;
      }
    });
  }

  Future<void> _showIncomingCallkit(Call call) async {
    final String id = const Uuid().v4();
    _currentCallkitId = id;
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
