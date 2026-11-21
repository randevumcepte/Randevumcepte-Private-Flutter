import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart'
    show Helper, MediaStream, navigator;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:uuid/uuid.dart';

import 'arama_ekrani.dart';
import 'ios_push.dart';
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

/// Softphone backend uclari (SoftphoneApiController). Kimlik = dahili + sifre.
const String kSoftphoneApi = 'https://app.randevumcepte.com.tr/api/v1/softphone';

/// iOS VoIP push ile gelen, henuz SIP INVITE'i gelmemis cagri.
class _PushCagri {
  _PushCagri(this.uuid, this.numara, this.arayan);
  final String uuid;
  final String numara;
  final String arayan;
  final DateTime zaman = DateTime.now();
  bool kabul = false; // CallKit'te INVITE gelmeden cevaplandi
  bool red = false; // CallKit'te reddedildi
  bool bagli = false; // INVITE geldi ve bu cagriya baglandi
}

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

  /// Push cagrisi "Cevapla" ile kabul edildi, SIP INVITE'i bekleniyor.
  /// Arama ekrani bu surede "Baglaniyor..." gosterir, kapanmaz.
  final ValueNotifier<bool> pushBaglaniyor = ValueNotifier<bool>(false);

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

  // --- iOS VoIP push ---
  static const String _kDahili = 'rc_sp_dahili';
  static const String _kSifre = 'rc_sp_sifre';
  // Android: arka plan isolate'inin (FCM) gosterdigi cagri; ana isolate okur.
  static const String _kBekleyen = 'rc_sp_bekleyen_push';
  bool _fcmDinleniyor = false;
  bool _pushKuruldu = false;
  _PushCagri? _push;
  Timer? _pushZamanAsimi;
  String? _hazirBekleyen; // register olunca santrale "hazirim" denecek uuid
  String? _kayitliToken; // backend'e son kaydedilen VoIP token
  // Android: "Cevapla"dan sonra INVITE beklenirken onceden alinan mikrofon.
  // answer() bunu kullanir (getUserMedia ~1-2 sn kazanilir). sip_ua disaridan
  // verilen akisi kapatmaz; cagri bitince burada kapatilir.
  MediaStream? _onMedya;
  bool _onMedyaAliniyor = false;

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
    _pushKur();
    _kimlikSakla(dahili, dahiliSifre);
    if (!kIsWeb && Platform.isIOS) {
      _tokenKaydet(await IosPush.voipToken());
    } else if (!kIsWeb && Platform.isAndroid) {
      _androidTokenKur();
    }

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

  /// Uygulama acilisinda (main) cagrilir. Uygulama gelen cagri push'u ile
  /// uyandirildiysa, ana ekran yuklenmesini beklemeden kayitli dahiliyle
  /// santrale baglanir ve bekleyen cagriyi karsilar.
  ///
  /// true: uygulama CallKit'te "Cevapla"ya basilarak acildi. Uygulama splash /
  /// surum kontrolu yerine dogrudan arama ekranini ([AramaEkrani] onBitti ile)
  /// gostermeli.
  Future<bool> erkenBaslat({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return false;
    if (navigatorKey != null) _navigatorKey = navigatorKey;
    _kurCallkitListener();
    _pushKur();
    final Map<String, dynamic>? bekleyen = Platform.isIOS
        ? await IosPush.bekleyenPush()
        : await _androidBekleyenOku();
    if (bekleyen == null) return false;
    // Android: kullanici bildirimden "Cevapla"ya basip uygulamayi actiysa.
    final bool kabul = await _callkitKabulMu((bekleyen['uuid'] ?? '').toString())
        .timeout(const Duration(seconds: 2), onTimeout: () => false);
    await _pushGeldi(bekleyen, kabul: kabul);
    return kabul && pushBaglaniyor.value;
  }

  /// Arama ekrani acildi/kapandi (otomatik ekran ikinci kez acilmasin).
  void ekranDurumu(bool acik) => _ekranAcik = acik;

  /// FCM mesaji softphone gelen cagrisi mi? Oyleyse isler ve true doner
  /// (uygulamanin normal bildirim akisi bu mesaji atlamali).
  /// [arkaPlan]: FCM arka plan isolate'i (uygulama kapali/arka planda).
  Future<bool> pushIsle(Map<String, dynamic> data, {bool arkaPlan = false}) async {
    final String kaynak = data['kaynak']?.toString() ?? '';
    if (kaynak != 'softphone_cagri' && kaynak != 'softphone_iptal') return false;
    if (kIsWeb || !Platform.isAndroid) return true; // iOS PushKit kullanir
    final String uuid = (data['uuid'] ?? '').toString();
    if (uuid.isEmpty) return true;
    if (kaynak == 'softphone_iptal') {
      // Santral: cagri bitti (arayan kapatti / kuyruk denemesi doldu).
      await _pushIptal(uuid, arkaPlan: arkaPlan);
      return true;
    }
    // Cihaz cevrimdisiyken bekleyip gec dusen push: cagri coktan bitti.
    if (_pushBayatMi(data['gonderim'])) {
      if (kDebugMode) debugPrint('[SIP] bayat push atlandi: $uuid');
      return true;
    }
    final Map<String, dynamic> m = <String, dynamic>{
      'uuid': uuid,
      'numara': (data['numara'] ?? '').toString(),
      'arayan': (data['arayan'] ?? '').toString(),
    };
    if (arkaPlan) {
      await _arkaPlanCagriGoster(m);
    } else {
      _kurCallkitListener();
      await _pushGeldi(m, callkitGoster: true);
    }
    return true;
  }

  /// Logout / dahili degisimi / lisans bitimi gibi durumlarda kapat.
  Future<void> kapat() async {
    // Bu cihaza artik VoIP push gelmesin.
    final String? tok = _kayitliToken;
    if (tok != null && _dahili != null) {
      _api('voip-token-sil', <String, dynamic>{'token': tok});
    }
    _kayitliToken = null;
    _kimlikSil();
    _push = null;
    _pushZamanAsimi?.cancel();
    _hazirBekleyen = null;
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

  /// Arama butonu: kayitliysa hemen true. Dahili var ama kayit dusmusse
  /// (arka planda soket kapandi vb.) temiz yeniden kayit dener, [bekle]
  /// kadar REGISTERED bekler. Devam eden cagri varken yeniden baglanmaz.
  Future<bool> aramayaHazir({Duration bekle = const Duration(seconds: 4)}) async {
    if (_dahili == null || _dahiliSifre == null) return false;
    if (_helper.registered) return true;
    if (activeCall.value != null) return false;
    if (_started) {
      await _restart();
    } else {
      _start();
    }
    if (_helper.registered) return true;
    final Completer<bool> c = Completer<bool>();
    void dinle() {
      if (kayitli.value && !c.isCompleted) c.complete(true);
    }
    kayitli.addListener(dinle);
    try {
      return await c.future.timeout(bekle, onTimeout: () => _helper.registered);
    } finally {
      kayitli.removeListener(dinle);
    }
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
    final _PushCagri? p = _push;
    if (activeCall.value == null && p != null && !p.bagli) {
      // "Cevapla"dan sonra, INVITE gelmeden ekrandan kapatildi.
      p.red = true; // gec gelen INVITE 486 ile reddedilir
      _api('hazir', <String, dynamic>{'uuid': p.uuid, 'durum': 'red'});
      IosPush.pushTuketildi();
      _androidBekleyenSil();
      FlutterCallkitIncoming.endCall(p.uuid).catchError((_) {});
      bitisNedeni.value = 'Arama sonlandı';
      _pushBaglantiBitti();
      return;
    }
    try {
      activeCall.value?.hangup();
    } catch (_) {}
    _endCallkit();
  }

  /// INVITE beklemesi bitti (baglandi / reddedildi / zaman asimi).
  void _pushBaglantiBitti() {
    pushBaglaniyor.value = false;
    if (activeCall.value == null) _onMedyaBirak();
  }

  /// "Cevapla" ile kabul edilen push cagrisi: arama ekranini hemen ac,
  /// Android'de mikrofonu INVITE beklenirken hazirla.
  void _pushKabulEdildi(_PushCagri p) {
    p.kabul = true;
    karsiTarafAdi = p.arayan.isNotEmpty ? p.arayan : null;
    karsiTarafNumara = p.numara.isNotEmpty ? p.numara : null;
    bitisNedeni.value = null;
    pushBaglaniyor.value = true;
    _ekraniAc(); // soguk acilista navigator yok: main ekrani kendisi gosterir
    _onMedyaHazirla();
  }

  Future<void> _onMedyaHazirla() async {
    // iOS'ta mikrofon CallKit ses oturumu acilinca alinmali (manuel ses modu).
    if (kIsWeb || !Platform.isAndroid) return;
    if (_onMedya != null || _onMedyaAliniyor) return;
    _onMedyaAliniyor = true;
    try {
      final MediaStream m = await navigator.mediaDevices
          .getUserMedia(<String, dynamic>{'audio': true, 'video': false});
      // Bu arada cagri bittiyse/iptal olduysa hemen birak.
      if (!pushBaglaniyor.value && activeCall.value == null) {
        await _akisiKapat(m);
      } else {
        _onMedya = m;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SIP] on mikrofon alinamadi: $e');
    } finally {
      _onMedyaAliniyor = false;
    }
  }

  void _onMedyaBirak() {
    final MediaStream? m = _onMedya;
    _onMedya = null;
    if (m != null) _akisiKapat(m);
  }

  static Future<void> _akisiKapat(MediaStream m) async {
    try {
      for (final t in m.getTracks()) {
        await t.stop();
      }
      await m.dispose();
    } catch (_) {}
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
    if (!kIsWeb && Platform.isIOS) {
      // iOS: CallKit ses oturumunu yeniden kurmadan sadece cikis yonu.
      final bool? gercek = await IosSes.hoparlor(yeni);
      hoparlor.value = gercek ?? yeni;
      return;
    }
    try {
      await Helper.setSpeakerphoneOn(yeni);
      hoparlor.value = yeni;
    } catch (e) {
      if (kDebugMode) debugPrint('[SIP] hoparlor hatasi: $e');
    }
  }

  void beklemeToggle() => _beklemeAyarla(!beklemede.value);

  /// Beklet/Devam. Ekrandaki durumu burada degistirmiyoruz: sip_ua'nin
  /// HOLD/UNHOLD (local) olayi gunceller. sip_ua istegi reddederse (baska
  /// re-INVITE suruyor, gorusme henuz kurulmadi vb.) ekran yanlis gostermez.
  void _beklemeAyarla(bool beklet) {
    final Call? call = activeCall.value;
    if (call == null || beklet == beklemede.value) return;
    final bool gonderildi =
        beklet ? call.session.hold() : call.session.unhold();
    if (kDebugMode && !gonderildi) {
      debugPrint('[SIP] ${beklet ? 'hold' : 'unhold'} reddedildi');
    }
  }

  void dtmfGonder(String tus) {
    activeCall.value?.sendDTMF(tus);
  }

  Map<String, dynamic> _answerOptions() {
    return <String, dynamic>{
      // sip_ua cevaplamada pcConfig verilmezse STUN'suz (bos iceServers)
      // baglanti kurar: cevapta sadece yerel IP olur, NAT arkasindaki cihazin
      // genel adresi santralin ICE listesine girmez ve Asterisk DTLS'i
      // dusurur ("Source not in ICE active candidate list") -> iki yon sessiz.
      // Giden aramadaki (sip_ua call) ayarin aynisi.
      'pcConfig': <String, dynamic>{
        'sdpSemantics': 'unified-plan',
        'iceTransportPolicy': 'all',
        'iceServers': <Map<String, String>>[
          <String, String>{'urls': 'stun:stun.l.google.com:19302'},
        ],
      },
      'mediaConstraints': <String, dynamic>{
        'audio': true,
        'video': false,
      },
      if (_onMedya != null) 'mediaStream': _onMedya,
    };
  }

  /// sip_ua 1.0.1 'INCOMING'/'OUTGOING' String, 1.1.0 Direction enum doner;
  /// ikisinde de calissin diye metin uzerinden bakilir.
  static bool _gelenMi(Call call) =>
      call.direction.toString().toLowerCase().contains('incoming');

  void _cagriDurumunuSifirla() {
    pushBaglaniyor.value = false;
    _onMedyaBirak();
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
    final String? bekleyenUuid = _hazirBekleyen;
    if (kayitli.value && bekleyenUuid != null) {
      _hazirBekleyen = null;
      _api('hazir', <String, dynamic>{'uuid': bekleyenUuid, 'durum': 'hazir'});
    }
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
    final Call? mevcut = activeCall.value;
    if (mevcut != null && mevcut.id != call.id) {
      // Tek hat: gorusme surerken gelen ikinci cagri mesgul ile reddedilir;
      // onun olaylari (FAILED/ENDED) mevcut cagrinin durumunu bozmaz.
      if (state.state == CallStateEnum.CALL_INITIATION && _gelenMi(call)) {
        if (kDebugMode) debugPrint('[SIP] ikinci gelen cagri 486 ile reddedildi');
        try {
          call.hangup(<String, dynamic>{'status_code': 486});
        } catch (_) {}
      }
      return;
    }
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
          _gelenCagriyiKarsila(call);
        } else {
          _ekraniAc();
        }
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        baglandiZamani.value ??= DateTime.now();
        // Buton "kapali" diye baslamasin: gercek cikisi oku (iOS).
        IosSes.hoparlorAcikMi().then((bool? h) {
          if (h != null && activeCall.value != null) hoparlor.value = h;
        });
        final String? ckId = _currentCallkitId;
        if (ckId != null) {
          // CallKit'e "baglandi" de (iOS sure/durum + ses kesintisi yonetimi).
          FlutterCallkitIncoming.setCallConnected(ckId).catchError((_) {});
        }
        // Gelen cagri CallKit'ten (ya da uygulamadan) cevaplandi.
        _ekraniAc();
        break;
      // Sadece bizim bekletmemiz: santral/karsi taraf bizi beklemeye alirsa
      // (remote) "Beklet" butonu degismez (unhold zaten reddedilirdi).
      case CallStateEnum.HOLD:
        if (state.originator == 'local') beklemede.value = true;
        break;
      case CallStateEnum.UNHOLD:
        if (state.originator == 'local') beklemede.value = false;
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
    // iOS: hoparlor CallKit sistem ekranindan/kulaklikla degisirse buton da degissin.
    IosSes.yonDinle((bool h) {
      if (activeCall.value != null) hoparlor.value = h;
    });
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      final dynamic govde = event.body;
      final String? olayId = govde is Map ? govde['id']?.toString() : null;
      final _PushCagri? p = _push;
      // INVITE'i henuz gelmemis push cagrisi mi?
      final bool pushCagrisi = activeCall.value == null &&
          p != null &&
          !p.bagli &&
          (olayId == null || olayId.toLowerCase() == p.uuid.toLowerCase());
      switch (event.event) {
        case Event.actionCallIncoming:
          // Android: FCM arka plan isolate'i cagriyi gosterdi; ana isolate
          // hayattaysa hemen santrale baglanip "hazir" desin (calarken).
          _androidCallkitOlayi(govde, kabul: false);
          break;
        case Event.actionCallAccept:
          if (pushCagrisi) {
            _pushKabulEdildi(p); // INVITE gelince otomatik cevaplanir
          } else if (activeCall.value != null) {
            cevapla();
          } else {
            _androidCallkitOlayi(govde, kabul: true);
          }
          break;
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          if (pushCagrisi) {
            p.red = true;
            // Reddet/kapat: santral aramayi tamamen sonlandirir ("red").
            // Calma suresi dolduysa (timeout) bilincli red degil: sadece bu
            // deneme biter, arayan kuyrukta bekler ("mesgul").
            final bool zamanAsimi = event.event == Event.actionCallTimeout;
            _api('hazir', <String, dynamic>{
              'uuid': p.uuid,
              'durum': zamanAsimi ? 'mesgul' : 'red',
            });
            IosPush.pushTuketildi();
            bitisNedeni.value = 'Arama sonlandı';
            _pushBaglantiBitti();
          } else if (activeCall.value == null &&
              olayId != null &&
              (p == null || olayId.toLowerCase() != p.uuid.toLowerCase())) {
            // Eski bir cagri ekrani kapandi (kuyrugun onceki denemesi / iptal):
            // su anki cagriyi reddetme.
          } else {
            kapatCagri();
          }
          break;
        case Event.actionCallToggleHold:
          // iOS CallKit ekranindaki Beklet dugmesi.
          final dynamic govdeHold = event.body;
          if (govdeHold is Map && govdeHold['isOnHold'] is bool) {
            _beklemeAyarla(govdeHold['isOnHold'] as bool);
          }
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
    final CallKitParams params = _callkitParams(
        id,
        (call.remote_display_name?.isNotEmpty ?? false)
            ? call.remote_display_name!
            : (call.remote_identity ?? 'Gelen Arama'),
        call.remote_identity ?? '');
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    // Gec gelen VoIP push ikinci bir CallKit ekrani acmasin.
    IosPush.dartCagrisi(id);
  }

  Future<void> _endCallkit() async {
    final String? id = _currentCallkitId;
    if (id != null) {
      IosPush.dartCagrisi(null);
      try {
        await FlutterCallkitIncoming.endCall(id);
      } catch (_) {}
      _currentCallkitId = null;
    }
  }

  // =========================================================================
  // iOS VoIP push (PushKit) — uygulama kapali/arka plandayken gelen cagri
  // =========================================================================
  //
  // Akis: santral dahiliyi cagirmadan once backend'den bu dahilinin VoIP
  // token'larini alir, APNs'e push yollar ve "hazir" cevabini bekler (~9 sn).
  // Native taraf push gelince CallKit'i hemen acar; burada santrale
  // (yeniden) register olunup "hazir" denir; santral cagriyi o zaman
  // gonderir ve INVITE ayni CallKit cagrisina baglanir. Kullanici INVITE'tan
  // once "Cevapla"ya bastiysa INVITE gelince otomatik cevaplanir.

  void _pushKur() {
    if (_pushKuruldu || kIsWeb || !Platform.isIOS) return;
    _pushKuruldu = true;
    IosPush.dinle(
      onToken: (String t) => _tokenKaydet(t),
      onPush: (Map<String, dynamic> m) => _pushGeldi(m),
    );
  }

  Future<void> _tokenKaydet(String token) async {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    if (token.isEmpty || _dahili == null) return;
    if (token == _kayitliToken) return;
    // Android: bundle bos; backend Firebase projesini token kaydindan/salondan cozer.
    final String bundle = Platform.isIOS ? await IosPush.bundleId() : '';
    final bool ok = await _api('voip-token', <String, dynamic>{
      'token': token,
      'bundle': bundle,
      'platform': Platform.isIOS ? 'ios' : 'android',
    });
    if (ok) _kayitliToken = token;
  }

  Future<void> _pushGeldi(Map<String, dynamic> m,
      {bool kabul = false, bool callkitGoster = false}) async {
    final String uuid = (m['uuid'] ?? '').toString();
    if (uuid.isEmpty) return;
    // Ayni push birden fazla yoldan gelebilir (kanal / bekleyen / callkit olayi).
    if (_push?.uuid == uuid) {
      if (kabul && !_push!.kabul && !_push!.bagli) _pushKabulEdildi(_push!);
      return;
    }
    // Native, Dart'in kendi actigi cagrinin UUID'sini kullandi (gec push).
    if (_currentCallkitId?.toLowerCase() == uuid.toLowerCase()) return;

    final _PushCagri? onceki = _push;
    // Zaten konusmadaysa ya da "Cevapla"dan sonra baglaniyorsa: tek hat,
    // bu cagri bu cihaza gelmesin.
    if (activeCall.value != null ||
        (onceki != null && !onceki.bagli && onceki.kabul)) {
      FlutterCallkitIncoming.endCall(uuid).catchError((_) {});
      IosPush.pushTuketildi();
      if (_dahili != null) {
        // "mesgul": sadece bu deneme reddedilir, arayan kuyrukta bekler.
        // ("red" kullanicinin Reddet'idir: santral aramayi tamamen sonlandirir.)
        _api('hazir', <String, dynamic>{'uuid': uuid, 'durum': 'mesgul'});
      }
      return;
    }

    // Cevaplanmamis eski push (kuyrugun onceki denemesi): ekrani ust uste
    // birikmesin.
    if (onceki != null && !onceki.bagli) {
      FlutterCallkitIncoming.endCall(onceki.uuid).catchError((_) {});
    }

    final _PushCagri p = _PushCagri(
        uuid, (m['numara'] ?? '').toString(), (m['arayan'] ?? '').toString());
    _push = p;
    if (kabul) _pushKabulEdildi(p);
    // Gec gelen push'ta cagri santralde bitmis olabilir: sor, bittiyse kapat.
    _durumSor(uuid).then((String? d) {
      if (d == 'bitti' && identical(_push, p) && !p.bagli) _pushIptal(uuid);
    });
    if (callkitGoster) {
      await IosSes.callkitIcinHazirla();
      await FlutterCallkitIncoming.showCallkitIncoming(_callkitParams(
          uuid, p.arayan.isNotEmpty ? p.arayan : (p.numara.isNotEmpty ? p.numara : 'Gelen Arama'),
          p.numara, pushtan: true));
    }
    _pushZamanAsimi?.cancel();
    // Santral en fazla ~9 sn bekler + calma; INVITE hic gelmezse CallKit'i kapat.
    _pushZamanAsimi = Timer(const Duration(seconds: 25), () {
      if (identical(_push, p) && !p.bagli) {
        _push = null;
        IosPush.pushTuketildi();
        _androidBekleyenSil();
        FlutterCallkitIncoming.endCall(p.uuid).catchError((_) {});
        if (pushBaglaniyor.value) {
          bitisNedeni.value = 'Bağlantı kurulamadı';
          _pushBaglantiBitti();
        }
      }
    });

    // Uygulama push ile sifirdan acildiysa dahili henuz yok: kayitli olanla basla.
    if (_dahili == null) {
      final List<String>? k = await _kimlikOku();
      if (k == null) {
        // Cikis yapilmis; cagri karsilanamaz.
        _push = null;
        IosPush.pushTuketildi();
        FlutterCallkitIncoming.endCall(uuid).catchError((_) {});
        _pushBaglantiBitti();
        return;
      }
      _hazirBekleyen = uuid;
      await init(dahili: k[0], dahiliSifre: k[1]);
      return;
    }

    final bool onPlanda =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (_started && _helper.registered && onPlanda) {
      // Baglanti canli: hemen "hazir".
      _api('hazir', <String, dynamic>{'uuid': uuid, 'durum': 'hazir'});
    } else {
      // Arka planda iOS soketi dondurmus/kapatmis olabilir: temiz yeniden kayit.
      _hazirBekleyen = uuid;
      if (_started) {
        await _restart();
      } else {
        _start();
      }
    }
  }

  /// Gelen INVITE: bekleyen push cagrisi varsa ona bagla, yoksa CallKit ac.
  Future<void> _gelenCagriyiKarsila(Call call) async {
    final _PushCagri? p = _push;
    if (p == null ||
        p.bagli ||
        DateTime.now().difference(p.zaman) > const Duration(seconds: 40)) {
      await _showIncomingCallkit(call);
      return;
    }
    p.bagli = true;
    _push = null;
    _pushZamanAsimi?.cancel();
    IosPush.pushTuketildi();
    _androidBekleyenSil();
    // activeCall artik dolu: ekran cagriyi izler, on mikrofon answer'a gider.
    pushBaglaniyor.value = false;
    // Push'taki ad (musteri adi) santralin From basligindan daha anlamli.
    if (p.arayan.isNotEmpty) karsiTarafAdi = p.arayan;
    if (p.numara.isNotEmpty) karsiTarafNumara = p.numara;

    if (p.red) {
      try {
        call.hangup(<String, dynamic>{'status_code': 486});
      } catch (_) {}
      return;
    }

    _currentCallkitId = p.uuid;
    _callkitCagrisi = true;
    await IosSes.callkitIcinHazirla();

    // Kabul olayi Dart dinlemeye baslamadan gelmis olabilir (kilit ekrani).
    final bool kabul = p.kabul || await _callkitKabulMu(p.uuid);
    if (kabul) {
      cevapla();
      // CallKit ses oturumu kabul aninda zaten acildi; WebRTC'ye bildir.
      await IosSes.callkitSesAktif();
    }
  }

  Future<bool> _api(String uc, Map<String, dynamic> govde) async {
    final String? d = _dahili;
    final String? s = _dahiliSifre;
    if (d == null || s == null) return false;
    try {
      final http.Response r = await http
          .post(
            Uri.parse('$kSoftphoneApi/$uc'),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{'dahili': d, 'sifre': s, ...govde}),
          )
          .timeout(const Duration(seconds: 8));
      if (kDebugMode) debugPrint('[SIP] api $uc => ${r.statusCode}');
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('[SIP] api $uc hatasi: $e');
      return false;
    }
  }

  Future<void> _kimlikSakla(String d, String s) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_kDahili, d);
      await p.setString(_kSifre, s);
    } catch (_) {}
  }

  Future<List<String>?> _kimlikOku() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? d = p.getString(_kDahili);
      final String? s = p.getString(_kSifre);
      if (d == null || s == null || d.isEmpty || s.isEmpty) return null;
      return <String>[d, s];
    } catch (_) {
      return null;
    }
  }

  Future<void> _kimlikSil() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.remove(_kDahili);
      await p.remove(_kSifre);
    } catch (_) {}
  }

  static CallKitParams _callkitParams(String id, String ad, String numara,
      {bool pushtan = false}) {
    return CallKitParams(
      id: id,
      nameCaller: ad,
      handle: numara,
      type: 0, // sesli
      duration: 30000,
      textAccept: 'Cevapla',
      textDecline: 'Reddet',
      extra: <String, dynamic>{if (pushtan) 'kaynak': 'softphone_push'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        isShowFullLockedScreen: true,
        isShowCallID: true,
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: false,
        // voiceChat: iOS ahize sesini gorusme seviyesine ayarlar, yanki
        // engelleme duzgun calisir (WebRTC'nin onerisi). 'default' modda
        // kulaktaki ses cok kisik kaliyordu.
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
        supportsDTMF: true,
        supportsHolding: true,
      ),
    );
  }

  Future<bool> _callkitKabulMu(String uuid) async {
    if (uuid.isEmpty) return false;
    try {
      final dynamic aktifler = await FlutterCallkitIncoming.activeCalls();
      if (aktifler is List) {
        for (final dynamic c in aktifler) {
          if (c is Map &&
              c['id']?.toString().toLowerCase() == uuid.toLowerCase() &&
              c['isAccepted'] == true) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  // =========================================================================
  // Android FCM gelen cagri
  // =========================================================================
  //
  // Santral -> Laravel -> FCM (data-only, HIGH). Uygulama kapali/arka plandaysa
  // mesaj FCM arka plan isolate'inde [pushIsle(arkaPlan: true)] ile gelir:
  // orada sadece tam ekran gelen cagri gosterilir ve cagri bilgisi
  // SharedPreferences'a yazilir (SIP o isolate'te kurulmaz). Ana isolate
  // hayattaysa callkit'in "incoming" olayiyla hemen santrale baglanir; degilse
  // kullanici "Cevapla"ya basinca uygulama acilir, [erkenBaslat] bekleyen
  // cagriyi okur, santrale baglanip "hazir" der, INVITE gelince otomatik cevaplar.

  void _androidTokenKur() {
    if (_fcmDinleniyor) return;
    _fcmDinleniyor = true;
    FirebaseMessaging.instance.getToken().then((String? t) {
      if (t != null) _tokenKaydet(t);
    }).catchError((_) {});
    FirebaseMessaging.instance.onTokenRefresh.listen((String t) => _tokenKaydet(t));
  }

  Future<void> _arkaPlanCagriGoster(Map<String, dynamic> m) async {
    final String uuid = m['uuid'] as String;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kBekleyen, jsonEncode(<String, dynamic>{
        ...m,
        'zaman': DateTime.now().millisecondsSinceEpoch,
      }));
    } catch (_) {}
    final String numara = m['numara'] as String;
    final String arayan = m['arayan'] as String;
    // Ekran hemen acilir; santral cagri bitti derse kapatilir (gec push).
    final Future<String?> durum = _durumSor(uuid);
    await FlutterCallkitIncoming.showCallkitIncoming(_callkitParams(
        uuid, arayan.isNotEmpty ? arayan : (numara.isNotEmpty ? numara : 'Gelen Arama'),
        numara, pushtan: true));
    durum.then((String? d) {
      if (d == 'bitti') _pushIptal(uuid, arkaPlan: true);
    });

    // Uygulama acilmadan "Reddet" basilirsa santral beklemesin: red bildir.
    final Completer<void> bitti = Completer<void>();
    final StreamSubscription<CallEvent?> abone =
        FlutterCallkitIncoming.onEvent.listen((CallEvent? e) async {
      if (e == null) return;
      final dynamic g = e.body;
      final String? id = g is Map ? g['id']?.toString() : null;
      if (id != null && id.toLowerCase() != uuid.toLowerCase()) return;
      if (e.event == Event.actionCallDecline) {
        final List<String>? k = await _kimlikOku();
        if (k != null) {
          _dahili = k[0];
          _dahiliSifre = k[1];
          await _api('hazir', <String, dynamic>{'uuid': uuid, 'durum': 'red'});
        }
        await _androidBekleyenSil();
        if (!bitti.isCompleted) bitti.complete();
      } else if (e.event == Event.actionCallAccept ||
          e.event == Event.actionCallTimeout ||
          e.event == Event.actionCallEnded) {
        if (!bitti.isCompleted) bitti.complete();
      }
    });
    await bitti.future.timeout(const Duration(seconds: 25), onTimeout: () {});
    await abone.cancel();
  }

  /// Android ana isolate: callkit olayindan (incoming/accept) bekleyen cagriyi baslat.
  Future<void> _androidCallkitOlayi(dynamic govde, {required bool kabul}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (govde is! Map) return;
    final dynamic extra = govde['extra'];
    if (extra is! Map || extra['kaynak'] != 'softphone_push') return;
    final String uuid = (govde['id'] ?? '').toString();
    if (uuid.isEmpty) return;
    Map<String, dynamic>? b = await _androidBekleyenOku();
    if (b == null || (b['uuid'] ?? '').toString().toLowerCase() != uuid.toLowerCase()) {
      b = <String, dynamic>{
        'uuid': uuid,
        'numara': (govde['handle'] ?? '').toString(),
        'arayan': (govde['nameCaller'] ?? '').toString(),
      };
    }
    await _pushGeldi(b, kabul: kabul);
  }

  Future<Map<String, dynamic>?> _androidBekleyenOku() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // diger isolate yazdi
      final String? j = prefs.getString(_kBekleyen);
      if (j == null) return null;
      final Map<String, dynamic> m = Map<String, dynamic>.from(jsonDecode(j) as Map);
      final int zaman = (m['zaman'] as num?)?.toInt() ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - zaman > 60000) {
        await prefs.remove(_kBekleyen);
        return null;
      }
      return m;
    } catch (_) {
      return null;
    }
  }

  /// FCM 'gonderim' (sunucu ms) 25 sn'den eskiyse push bayattir. Cok buyuk
  /// fark (>10 dk) cihaz saati yanlis demektir: bayat sayma, "durum" sorusu
  /// yakalar.
  static bool _pushBayatMi(dynamic gonderim) {
    final int? g = int.tryParse(gonderim?.toString() ?? '');
    if (g == null || g <= 0) return false;
    final int yas = DateTime.now().millisecondsSinceEpoch - g;
    return yas > 25000 && yas < 600000;
  }

  /// Santral: push cagrisi hala suruyor mu? bitti | hazir | red | null
  Future<String?> _durumSor(String uuid) async {
    String? d = _dahili;
    String? s = _dahiliSifre;
    if (d == null || s == null) {
      final List<String>? k = await _kimlikOku();
      if (k == null) return null;
      d = k[0];
      s = k[1];
    }
    try {
      final http.Response r = await http
          .post(
            Uri.parse('$kSoftphoneApi/durum'),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{'dahili': d, 'sifre': s, 'uuid': uuid}),
          )
          .timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) return null;
      final dynamic j = jsonDecode(r.body);
      return j is Map ? j['durum']?.toString() : null;
    } catch (_) {
      return null;
    }
  }

  /// Santral cagrinin bittigini bildirdi: henuz baglanmamis gelen cagri
  /// ekranini kapat. Baglanmis gorusmeye dokunmaz (onu SIP BYE bitirir).
  Future<void> _pushIptal(String uuid, {bool arkaPlan = false}) async {
    final String k = uuid.toLowerCase();
    if (arkaPlan) {
      // Arka plan isolate'i: bekleyen kayit bu cagriysa henuz baglanmadi.
      final Map<String, dynamic>? b = await _androidBekleyenOku();
      if (b != null && (b['uuid'] ?? '').toString().toLowerCase() == k) {
        await _androidBekleyenSil();
        await FlutterCallkitIncoming.endCall(uuid).catchError((_) {});
      }
      return;
    }
    final _PushCagri? p = _push;
    if (p != null && p.uuid.toLowerCase() == k) {
      if (p.bagli) return;
      _push = null;
      _pushZamanAsimi?.cancel();
      IosPush.pushTuketildi();
      _androidBekleyenSil();
      FlutterCallkitIncoming.endCall(p.uuid).catchError((_) {});
      if (pushBaglaniyor.value) {
        bitisNedeni.value = 'Arama sonlandı';
        _pushBaglantiBitti();
      }
      return;
    }
    // Bu cihazda bagli gorusme bu cagri ise dokunma.
    if (activeCall.value != null && _currentCallkitId?.toLowerCase() == k) return;
    final Map<String, dynamic>? b = await _androidBekleyenOku();
    if (b != null && (b['uuid'] ?? '').toString().toLowerCase() == k) {
      await _androidBekleyenSil();
    }
    await FlutterCallkitIncoming.endCall(uuid).catchError((_) {});
  }

  Future<void> _androidBekleyenSil() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kBekleyen);
    } catch (_) {}
  }
}
