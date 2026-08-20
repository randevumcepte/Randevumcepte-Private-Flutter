import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// SESLI RANDEVU — sesli diyalog
/// Kullanici konusur -> sistem anlar -> eksik/belirsiz alanlari SESLI sorar ->
/// kullanici cevaplar -> sesli onaylatir -> randevu olusturur.
/// Randevu DAIMA giris yapan personel adina; hizmetler o personelinkiyle sinirli.
class SesliRandevuEkrani extends StatefulWidget {
  final String salonId;
  final String personelId;
  final dynamic isletmebilgi;
  const SesliRandevuEkrani({
    Key? key,
    required this.salonId,
    this.personelId = '',
    this.isletmebilgi,
  }) : super(key: key);

  @override
  State<SesliRandevuEkrani> createState() => _SesliRandevuEkraniState();
}

class _SesliRandevuEkraniState extends State<SesliRandevuEkrani> {
  static const Color mor = Color(0xFF7C3AED);
  static const List<String> _aylar = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  AudioPlayer _bip = AudioPlayer(); // isinmis player (duyulur); bozulursa yenilenir

  bool _hazir = false;
  bool _dinliyor = false;
  bool _mesgul = false; // akis calisiyor
  bool _iptal = false;

  // Dinleme (tek cumle) tamamlama
  Completer<String>? _dinleC;
  String _dinleSon = '';

  // TTS ses secimi — musteriye sunulan 2 secenek (varsayilan Ses 1)
  List<Map<String, String>> _sesler = []; // cihazdaki tum tr sesler
  List<Map<String, String>> _sunulan = []; // {etiket, name, locale} — 2 secenek
  String? _seciliSes;

  // Sunulacak sesler (isimle sabit; cihazda yoksa siraya gore yedek)
  static const String _ses1Name = 'tr-tr-x-tmc-network'; // erkek, akici (varsayilan)
  static const String _ses2Name = 'tr-tr-x-efu-network'; // alternatif (eski "Ses 5")

  // Cozumlenen alanlar
  int? _musteriId;
  String? _musteriAd;
  List<Map<String, dynamic>> _adaylar = [];
  String? _spokenAd; // kullanicinin soyledigi ham musteri adi (yeni musteri icin)
  int? _hizmetId;
  String? _hizmetAd;
  String _hizmetFiyat = '0';
  String _hizmetSure = '30';
  String? _tarih; // Y-m-d
  String? _saat; // H:i
  String? _vakit; // sabah | ogleden_sonra | aksam
  String _personelAd = 'Siz';

  String _sistemMesaji = 'Mikrofona dokunun ve randevuyu söyleyin.';
  final List<String> _konusma = [];

  @override
  void initState() {
    super.initState();
    _bipHazirla();
    _hazirla();
  }

  /// Bip player'ini isit (medya kanali + focus none). Hot reload'da bozulursa
  /// _bipCal icinde yeniden cagrilir.
  Future<void> _bipHazirla() async {
    try {
      _bip.audioCache = AudioCache(prefix: '');
      await _bip.setReleaseMode(ReleaseMode.stop);
      await _bip.setAudioContext(_sesBaglami());
    } catch (_) {}
  }

  /// Bip cali ses baglami: MEDYA kanali (TTS gibi DUYULUR) + ses ODAGI ISTEME
  /// (mikrofon acilinca bip kisilmasin). Hot restart'ta native ayar sifirlandigi
  /// icin her bip'ten ONCE de uygulanir (bkz. _bipCal).
  AudioContext _sesBaglami() => AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: const {},
        ),
      );

  Future<void> _hazirla() async {
    final ok = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') _dinlemeTamamla();
      },
      onError: (e) => _dinlemeTamamla(),
    );
    await _sesAyarla();
    if (mounted) _ss(() => _hazir = ok);
  }

  /// TTS'i mumkun oldugunca dogal/akici yapar: Google motoru + en iyi Turkce ses.
  Future<void> _sesAyarla() async {
    // 1) Google TTS motoru (Samsung varsayilanindan daha dogal)
    try {
      final engines = await _tts.getEngines;
      if (engines is List && engines.contains('com.google.android.tts')) {
        await _tts.setEngine('com.google.android.tts');
      }
    } catch (_) {}

    await _tts.setLanguage('tr-TR');

    // 2) Turkce sesleri topla (kullanici ekrandan secebilsin)
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        _sesler = voices
            .map((v) => Map<String, dynamic>.from(v as Map))
            .where((v) =>
                (v['locale'] ?? '').toString().toLowerCase().startsWith('tr'))
            .map((v) => {
                  'name': v['name'].toString(),
                  'locale': v['locale'].toString(),
                })
            .toList();
      }
    } catch (_) {}

    // 3) Hiz/ton
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.06);
    await _tts.awaitSpeakCompletion(true);

    // 4) Musteriye sunulacak 2 sesi belirle (isimle; yoksa siraya gore yedek)
    _sunulan = [];
    final s1 = _sesBul(_ses1Name) ?? (_sesler.isNotEmpty ? _sesler[0] : null);
    final s2 = _sesBul(_ses2Name) ??
        (_sesler.length > 4 ? _sesler[4] : (_sesler.length > 1 ? _sesler[1] : null));
    if (s1 != null) {
      _sunulan.add({'etiket': 'Ses 1', 'name': s1['name']!, 'locale': s1['locale']!});
    }
    if (s2 != null && s2['name'] != s1?['name']) {
      _sunulan.add({'etiket': 'Ses 2', 'name': s2['name']!, 'locale': s2['locale']!});
    }

    // 5) Varsayilan: kayitli secim (sunulanlar icindeyse) yoksa Ses 1
    final prefs = await SharedPreferences.getInstance();
    final kayitli = prefs.getString('sesli_randevu_ses');
    String? hedef;
    if (kayitli != null && _sunulan.any((s) => s['name'] == kayitli)) {
      hedef = kayitli;
    } else if (_sunulan.isNotEmpty) {
      hedef = _sunulan.first['name']; // Ses 1 (varsayilan)
    }
    if (hedef != null) {
      await _sesUygula(hedef, kaydet: false);
    }
    if (mounted) _ss(() {});
  }

  Map<String, String>? _sesBul(String name) {
    for (final s in _sesler) {
      if (s['name'] == name) return s;
    }
    return null;
  }

  /// Secilen sesi TTS'e uygular (ve istenirse kaydeder).
  Future<void> _sesUygula(String name, {bool kaydet = true}) async {
    final ses = _sesler.firstWhere((s) => s['name'] == name,
        orElse: () => {'name': name, 'locale': 'tr-TR'});
    try {
      await _tts.setVoice({'name': ses['name']!, 'locale': ses['locale']!});
    } catch (_) {}
    _seciliSes = name;
    if (kaydet) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sesli_randevu_ses', name);
    }
    if (mounted) _ss(() {});
  }

  /// Ses secildiginde ornek konusarak dinlet.
  Future<void> _sesDene(String name) async {
    await _sesUygula(name);
    await _konus('Merhaba, ben randevu asistanınız. Sesim böyle.');
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _bip.dispose();
    super.dispose();
  }

  /// mounted kontrollu setState — ekran kapandiktan sonra cagrilirsa cokmesin.
  void _ss(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  /* ------------------------------------------------------------------ */
  /* SES: konus / dinle                                                 */
  /* ------------------------------------------------------------------ */

  /// Dinleme baslamadan kisa sinyal: guclu titresim + kisa ses blip'i.
  /// (Bu cihaz Android'in kendi tanima bip'ini calmiyor.)
  Future<void> _bipCal() async {
    print('SESLIDBG bip cagrildi');
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('SESLIDBG haptic hata: $e');
    }
    // ISINMIS kalici player calar (duyulur). Hot reload'da native player
    // "disposed" olursa yakalayip YENIDEN olusturup tekrar dener.
    try {
      await _bip.play(AssetSource('images/bip6.wav'), volume: 1.0);
      print('SESLIDBG ses play() cagrildi');
    } catch (e) {
      print('SESLIDBG ses hata, player yenileniyor: $e');
      try {
        _bip = AudioPlayer();
        await _bipHazirla();
        await _bip.play(AssetSource('images/bip6.wav'), volume: 1.0);
      } catch (_) {}
    }
    // Bip mikrofon ACILMADAN once duyulsun; sonra durdurup dinlemeye gec.
    await Future.delayed(const Duration(milliseconds: 320));
    try {
      await _bip.stop();
    } catch (_) {}
  }

  Future<void> _konus(String metin) async {
    _ss(() {
      _sistemMesaji = metin;
      _konusma.add('🔊 $metin');
    });
    try {
      await _tts.stop();
      await _tts.speak(metin);
    } catch (_) {}
  }

  /// Tek cumle dinler; oturum kapaninca duyulan metni doner.
  /// pause = konusma bitince kac sn sessizlikten sonra KAPANSIN (kisa = hizli).
  Future<String> _dinle({int pause = 2, int listen = 15}) async {
    if (!_hazir) return '';
    _dinleC = Completer<String>();
    _dinleSon = '';
    _ss(() => _dinliyor = true);
    await _bipCal();
    try {
      await _speech.listen(
        onResult: (r) {
          _dinleSon = r.recognizedWords.trim();
          _ss(() {});
          if (r.finalResult) _dinlemeTamamla();
        },
        listenFor: Duration(seconds: listen),
        pauseFor: Duration(seconds: pause),
        listenOptions: stt.SpeechListenOptions(
          localeId: 'tr_TR',
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: false,
        ),
      );
    } catch (_) {
      _dinlemeTamamla();
    }
    final sonuc = await _dinleC!.future;
    print('SESLIDBG STT duydu: "$sonuc"');
    if (sonuc.isNotEmpty) {
      _ss(() => _konusma.add('🎤 $sonuc'));
    }
    // Kullanici herhangi bir anda "iptal / vazgec / kapat / dur" derse akisi durdur.
    if (_iptalKomutu(sonuc)) {
      _ss(() => _iptal = true);
      await _konus('Tamam, işlemi iptal ettim.');
      return '';
    }
    return sonuc;
  }

  void _dinlemeTamamla() {
    if (_dinleC != null && !_dinleC!.isCompleted) {
      _dinleC!.complete(_dinleSon.trim());
    }
    if (mounted) _ss(() => _dinliyor = false);
  }

  /* ------------------------------------------------------------------ */
  /* ANA AKIS                                                           */
  /* ------------------------------------------------------------------ */

  Future<void> _basla() async {
    if (_mesgul) {
      // Devam eden dinlemeyi durdur
      await _speech.stop();
      _dinlemeTamamla();
      return;
    }
    _sifirla();
    _ss(() => _mesgul = true);
    try {
      // EN BASTA: takvim acik mi + hizmet var mi? Yoksa konuşma isteme.
      _ss(() => _sistemMesaji = 'Kontrol ediliyor...');
      final durum = await sesliRandevuTakvimDurumu(widget.personelId);
      if (durum['acik'] != true) {
        await _konus(
            'Randevu takviminiz açık değil. Çalışma saatleriniz tanımlı olmadan randevu oluşturamıyorum.');
        return;
      }
      if (durum['hizmet_var'] != true) {
        await _konus(
            'Size tanımlı hizmet bulunmuyor. Lütfen önce hizmetlerinizi tanımlayın.');
        return;
      }
      await _konus('Randevunuzu oluşturun.');
      final komut = await _dinle(pause: 3, listen: 20);
      if (_iptal) return;
      if (komut.trim().isEmpty) {
        await _konus('Sizi duyamadım. Tekrar deneyin.');
        return;
      }
      await _uygula(komut);
      if (_iptal) return;
      // Once HIZMET: personelde yoksa musteriyi sormadan hemen uyar ve dur.
      await _hizmetCoz();
      if (_iptal || _hizmetId == null) return;
      await _musteriCoz();
      if (_iptal || _musteriId == null) return;
      // Tarih/saat/vakit tercihine gore EN YAKIN BOS slotu bul, sesli onaylat, olustur.
      await _musaitlikVeOnay();
    } finally {
      if (mounted) _ss(() => _mesgul = false);
    }
  }

  void _sifirla() {
    _iptal = false;
    _musteriId = null;
    _musteriAd = null;
    _adaylar = [];
    _spokenAd = null;
    _hizmetId = null;
    _hizmetAd = null;
    _tarih = null;
    _saat = null;
    _vakit = null;
    _konusma.clear();
  }

  /// Bir komut/cevap metnini backend'e cozdurup alanlari doldurur.
  Future<Map<String, dynamic>> _uygula(String metin) async {
    _ss(() => _sistemMesaji = 'Anlıyorum...');
    final r = await sesliRandevuCoz(widget.salonId, metin,
        personelId: widget.personelId);
    if (r['basarili'] != true) return r;

    // Tarih / saat
    if (r['tarih'] != null && (r['tarih'] as String).isNotEmpty) {
      _tarih = r['tarih'];
    }
    if (r['saat'] != null && (r['saat'] as String).isNotEmpty) {
      _saat = r['saat'];
    }
    if (r['vakit'] != null && (r['vakit'] as String).isNotEmpty) {
      _vakit = r['vakit'].toString();
    }
    // Hizmet
    final hizmetler = (r['hizmetler'] as List?) ?? [];
    if (hizmetler.isNotEmpty) {
      final h = hizmetler.first;
      _hizmetId = h['hizmet_id'] is int
          ? h['hizmet_id']
          : int.tryParse('${h['hizmet_id']}');
      _hizmetAd = h['hizmet_adi']?.toString();
      _hizmetFiyat = '${h['fiyat'] ?? 0}';
      _hizmetSure = '${h['sure_dk'] ?? 30}';
    }
    // Personel (sabit = siz)
    final p = r['personel'] as Map?;
    if (p != null && p['personel_adi'] != null) {
      _personelAd = p['personel_adi'].toString();
    }
    // Musteri
    final m = (r['musteri'] as Map?) ?? {};
    final adaylar = ((m['adaylar'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    print('SESLIDBG musteri: user_id=${m['user_id']} adaylar=${adaylar.map((a) => a['name']).toList()}');
    if (m['user_id'] != null) {
      _musteriId = m['user_id'] is int
          ? m['user_id']
          : int.tryParse('${m['user_id']}');
      if (adaylar.isNotEmpty) _musteriAd = adaylar.first['name']?.toString();
    } else {
      _adaylar = adaylar;
      // Komuttan/cevaptan cikan ISIM TAHMINI'ni sakla -> "Müşteri kim?" yerine
      // soylenen ismi kullan (kullanici komutta ismi soyledi, tekrar sormayalim).
      final adT = (m['ad_tahmini'] ?? '').toString().trim();
      if (adT.isNotEmpty) _spokenAd = _isimTemizle(adT);
    }
    _ss(() {});
    return r;
  }

  /* ------------------------------------------------------------------ */
  /* ALAN COZUCULER (sesli soru-cevap)                                  */
  /* ------------------------------------------------------------------ */

  Future<void> _musteriCoz() async {
    int deneme = 0;
    while (_musteriId == null && !_iptal && deneme < 3) {
      deneme++;

      // ISIM AL — aday listesi bossa (ilk komuttan gelmediyse ya da onceki tur
      // net sonuc vermediyse). Yeni musteri SADECE "yeni" deyince acilir.
      if (_adaylar.isEmpty) {
        final String soru;
        if (_spokenAd != null && _spokenAd!.isNotEmpty) {
          // Komutta isim soylendi ama net anlasilmadi -> sadece adini iste.
          soru =
              'Müşteri adını tam anlayamadım. Lütfen sadece müşterinin adını söyleyin. Yeni müşteri için "yeni" deyin.';
        } else if (deneme == 1) {
          soru = 'Müşteri kim?';
        } else {
          soru = 'Adı tekrar söyleyin, yeni müşteri için "yeni" deyin.';
        }
        await _konus(soru);
        final c = await _dinle();
        if (_iptal) return;
        if (c.trim().isEmpty) continue;
        if (_yeniMi(c)) {
          await _yeniMusteriOlustur(_spokenAd);
          return;
        }
        _spokenAd = _isimTemizle(c);
        await _uygula(c); // user_id veya adaylar doldurur
        if (_iptal) return;
        if (_musteriId != null) return;
        if (_adaylar.isEmpty) continue; // hala bulunamadi -> tekrar sor
      }

      // ADAY(LAR) SUN
      if (_adaylar.isNotEmpty) {
        final adlar = _adaylar
            .take(3)
            .map((a) => a['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        await _konus(
            'Şunlardan biri mi: ${adlar.join(", ")}? Değilse yeni müşteri için "yeni" deyin.');
        final c = await _dinle();
        if (_iptal) return;
        if (_yeniMi(c)) {
          await _yeniMusteriOlustur(_spokenAd);
          return;
        }
        final sec = _adayEslesirGuclu(c);
        if (sec != null) {
          _musteriSec(sec);
          return;
        }
        // Net secilmedi -> cevabi YENI isim varsayip tekrar ara (yanlis duymayi duzelt)
        _ss(() => _adaylar = []);
        if (c.trim().isNotEmpty) {
          _spokenAd = _isimTemizle(c);
          await _uygula(c);
          if (_iptal) return;
          if (_musteriId != null) return;
        }
      }
    }
    if (_musteriId == null && !_iptal) {
      await _konus('Müşteriyi belirleyemedim. Yeni müşteri için "yeni" diyerek tekrar deneyin.');
    }
  }

  /// Portfoyde bulunamayan musteriyi ISIM + TELEFON alarak olusturur (canli endpoint).
  /// Once ismi ONAYLATIR (STT yanlis duymus olabilir), sonra telefon ister.
  Future<void> _yeniMusteriOlustur(String? on) async {
    String ad = _isimTemizle(on ?? '');
    // 1) Ismi net al + onayla (en fazla 3 tur)
    for (int i = 0; i < 3 && !_iptal; i++) {
      if (ad.length >= 2) {
        await _konus('Yeni müşteri $ad. Doğruysa "evet" deyin, değilse adı söyleyin.');
      } else {
        await _konus('Yeni müşterinin adını söyleyin.');
      }
      final c = await _dinle();
      if (_iptal) return;
      if (c.trim().isEmpty) continue;
      if (ad.length >= 2 && _olumlu(c)) break;
      final yeniAd = _isimTemizle(c);
      if (yeniAd.length >= 2) ad = yeniAd;
    }
    if (ad.length < 2) {
      await _konus('İsmi alamadım, işlemi iptal ediyorum.');
      _ss(() => _iptal = true);
      return;
    }
    // 2) Telefon al
    await _konus('$ad için telefon numarasını söyleyin.');
    String? tel;
    for (int i = 0; i < 2 && tel == null && !_iptal; i++) {
      final t = await _dinle(pause: 3, listen: 12);
      if (_iptal) return;
      tel = _telefonAyikla(t);
      if (tel == null && i == 0) {
        await _konus('Numarayı anlayamadım. On bir haneli numarayı tekrar söyleyin.');
      }
    }
    if (tel == null) {
      await _konus('Telefon numarasını alamadım. İşlemi iptal ediyorum.');
      _ss(() => _iptal = true);
      return;
    }
    // 3) Kaydet
    await _konus('$ad, ${_telSozlu(tel)} numarasıyla kaydediliyor.');
    final r = await sesliYeniMusteri(
      salonId: widget.salonId,
      name: ad,
      telefon: tel,
    );
    if (r['ok'] == true && r['userId'] != null) {
      _ss(() {
        _musteriId = int.tryParse(r['userId'].toString());
        _musteriAd = ad;
      });
      await _konus('$ad kaydedildi.');
    } else if (r['exists'] == true) {
      await _konus(
          'Bu telefon numarası zaten kayıtlı. Lütfen müşteriyi uygulamadan seçin.');
    } else {
      await _konus('Müşteri oluşturulamadı. ${r['hata'] ?? ''}');
    }
  }

  void _musteriSec(Map<String, dynamic> aday) {
    _ss(() {
      _musteriId = aday['user_id'] is int
          ? aday['user_id']
          : int.tryParse('${aday['user_id']}');
      _musteriAd = aday['name']?.toString();
    });
  }

  /// Aday, cevapla GUCLU eslesiyor mu? Adayin TUM kelimeleri cevapta gecmeli VE
  /// yalniz TEK aday tam eslesmeli. Boylece "Anıl Orbey" derken yanlislikla
  /// "Anıl Kaya" secilmez (tek kelime ortakligi yeterli sayilmaz).
  Map<String, dynamic>? _adayEslesirGuclu(String cevap) {
    final cw = _fold(cevap)
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toSet();
    Map<String, dynamic>? tekTam;
    int tamSayisi = 0;
    for (final a in _adaylar) {
      final adKelime = _fold(a['name']?.toString() ?? '')
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 2)
          .toList();
      if (adKelime.isEmpty) continue;
      if (adKelime.every((w) => cw.contains(w))) {
        tamSayisi++;
        tekTam = a;
      }
    }
    return tamSayisi == 1 ? tekTam : null;
  }

  /// "yeni müşteri / hayır / değil / yok / başka" gibi RED/YENI ifadesi mi?
  bool _yeniMi(String cevap) {
    final c = _fold(cevap);
    for (final k in ['yeni', 'hayir', 'degil', 'yok', 'baska', 'hicbiri', 'olmadi']) {
      if (c.contains(k)) return true;
    }
    return false;
  }

  /// Olumlu onay mi? ("evet / doğru / tamam / olur / aynen")
  bool _olumlu(String cevap) {
    final c = _fold(cevap);
    for (final k in ['evet', 'dogru', 'tamam', 'olur', 'aynen', 'kesinlikle']) {
      if (c.contains(k)) return true;
    }
    return false;
  }

  /// Kullanicinin akisi durdurma komutu mu? ("iptal / vazgeç / kapat / dur")
  bool _iptalKomutu(String cevap) {
    final c = _fold(cevap);
    for (final k in ['iptal', 'vazgec', 'vaz gec', 'bosver', 'bos ver',
        'istemiyorum', 'kapat', 'durdur']) {
      if (c.contains(k)) return true;
    }
    return c.trim() == 'dur';
  }

  /// Soylenen isimden dolgu kelimeleri temizler, her kelimenin ilk harfini buyutur.
  String _isimTemizle(String s) {
    const at = {
      'musteri', 'musterim', 'musteriye', 'musteriya', 'adina', 'adi', 'isim',
      'ismi', 'isimli', 'bey', 'hanim', 'hanima', 'beye', 'icin', 'lutfen',
      'randevu', 'randevusu', 'olustur', 'olusturun', 'ver', 'verin', 've',
      'de', 'da', 'ile', 'saat', 'saatte', 'gel', 'gelsin'
    };
    final kelimeler = s
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) {
          final f = _fold(w);
          return f.length >= 2 &&
              !at.contains(f) &&
              !RegExp(r'\d').hasMatch(w); // rakam iceren token (12de, 14:00) atla
        })
        .toList();
    return kelimeler
        .map((w) => w.isEmpty
            ? w
            : (w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '')))
        .join(' ')
        .trim();
  }

  /// STT metninden 11 haneli TR cep telefonu cikarir (05XXXXXXXXX) ya da null.
  String? _telefonAyikla(String s) {
    const rakam = {
      'sifir': '0', 'bir': '1', 'iki': '2', 'uc': '3', 'dort': '4',
      'bes': '5', 'alti': '6', 'yedi': '7', 'sekiz': '8', 'dokuz': '9'
    };
    final sb = StringBuffer();
    for (final w in _fold(s).split(RegExp(r'\s+'))) {
      sb.write(rakam.containsKey(w) ? rakam[w] : w);
    }
    var d = sb.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length == 12 && d.startsWith('90')) d = d.substring(2);
    if (d.length == 10 && d.startsWith('5')) d = '0$d';
    if (d.length == 11 && d.startsWith('05')) return d;
    return null;
  }

  /// Telefonu okunakli soyler: "0 5 3 1 ...".
  String _telSozlu(String tel) => tel.split('').join(' ');

  Future<void> _hizmetCoz() async {
    int deneme = 0;
    while (_hizmetId == null && !_iptal && deneme < 3) {
      deneme++;
      // Personelde bu hizmet yok -> kibar uyar + BASKA bir hizmet iste, dinle.
      await _konus(
          'Bu personele kayıtlı böyle bir hizmet bulunmamaktadır. Lütfen başka bir hizmet söyleyin.');
      final c = await _dinle();
      if (c.isEmpty) continue;
      await _uygula(c);
    }
    if (_hizmetId == null && !_iptal) {
      await _konus('Hizmet bulunamadı, işlemi iptal ediyorum.');
      _ss(() => _iptal = true);
    }
  }

  Future<void> _tarihCozSes() async {
    int deneme = 0;
    while (_tarih == null && !_iptal && deneme < 3) {
      deneme++;
      await _konus('Hangi gün?');
      final c = await _dinle();
      if (c.isEmpty) continue;
      await _uygula(c);
    }
  }

  Future<void> _saatCozSes() async {
    int deneme = 0;
    while (_saat == null && !_iptal && deneme < 3) {
      deneme++;
      await _konus('Saat kaçta?');
      final c = await _dinle();
      if (c.isEmpty) continue;
      await _uygula(c);
    }
  }

  /* ------------------------------------------------------------------ */
  /* ONAY + OLUSTUR                                                     */
  /* ------------------------------------------------------------------ */

  bool _olumluMu(String cl) =>
      cl.contains('evet') ||
      cl.contains('onay') ||
      cl.contains('tamam') ||
      cl.contains('olur') ||
      cl.contains('olustur') ||
      cl.contains('kaydet') ||
      cl.contains('yine');

  /// Tarih/saat/vakit tercihine gore EN YAKIN BOS slotu bulur, sesli onaylatir, olusturur.
  Future<void> _musaitlikVeOnay() async {
    _ss(() => _sistemMesaji = 'Uygun saat aranıyor...');
    final m = await sesliRandevuMusaitlik(
      widget.salonId,
      widget.personelId,
      _hizmetId.toString(),
      tarih: _tarih ?? '',
      saat: _saat ?? '',
      vakit: _vakit ?? '',
    );
    if (m['bulundu'] != true) {
      if (m['calisma_yok'] == true) {
        await _konus(
            'Randevu takviminiz açık değil. Çalışma saatleriniz tanımlı olmadan randevu oluşturamıyorum.');
      } else {
        await _konus(
            'Belirttiğiniz tarihlerde müsait bir saat bulamadım. Çalışma saatlerinizin tanımlı ve o günlerin açık olduğundan emin olun.');
      }
      return;
    }
    final istenenSaat = (_saat ?? '').trim(); // kullanicinin ISTEDIGI saat (overwrite oncesi)
    final bTarih = m['tarih'].toString();
    final bSaat = m['saat'].toString();
    final tamIstek = m['tam_istek'] == true;
    _ss(() {
      _tarih = bTarih;
      _saat = bSaat;
    });

    final kim = _musteriAd ?? 'müşteri';
    final zaman = '${_tarihSozlu(bTarih)} saat ${_saatSozlu(bSaat)}';

    // Onay iste — her durumda "farkli saat soyleyebilirsiniz" ipucuyla.
    String c;
    if (tamIstek) {
      await _konus(
          '$kim, $zaman, $_hizmetAd. Onaylıyor musunuz? Farklı bir saat isterseniz söyleyin.');
      c = await _dinle(pause: 2, listen: 8);
    } else if (istenenSaat.isNotEmpty) {
      await _konus(
          'Vermek istediğiniz saatte başka bir müşterimizin randevusu bulunuyor. Şu an en yakın müsait saat $zaman. $kim için bu saate oluşturayım mı? Farklı bir saat isterseniz söyleyin.');
      c = await _dinle(pause: 2, listen: 8);
    } else {
      await _konus(
          '$kim için en yakın müsait saat $zaman. Bu saate oluşturayım mı? Farklı bir saat isterseniz söyleyin.');
      c = await _dinle(pause: 2, listen: 8);
    }
    if (_iptal) return;

    if (_olumluMu(_fold(c))) {
      await _randevuYaz(false); // onaylandi -> olustur
      return;
    }

    // ONAY YOK: once cevapta yeni saat/gun var mi ("hayir saat 3 olsun") DENE.
    if (await _tercihDuzeltDeneVeTekrar(c)) return;

    // Cevapta belirgin saat/gun yoktu -> ACIKCA sor.
    await _konus('Peki, hangi saate ya da güne almak istersiniz? Vazgeçmek için iptal deyin.');
    final d = await _dinle(pause: 2, listen: 10);
    if (_iptal) return;
    if (d.trim().isNotEmpty && await _tercihDuzeltDeneVeTekrar(d)) return;

    await _konus('İptal ettim, randevu oluşturulmadı.');
  }

  /// Metinde YENI saat/tarih/vakit varsa gunceller ve musaitligi BASTAN
  /// degerlendirir (musteri/hizmet KORUNUR). Degisiklik olduysa true doner.
  Future<bool> _tercihDuzeltDeneVeTekrar(String metin) async {
    // Metni cozdur ama SADECE tarih/saat/vakit'i al (musteri/hizmet DOKUNMA).
    final r = await sesliRandevuCoz(widget.salonId, metin,
        personelId: widget.personelId);
    final yTarih = (r['tarih'] ?? '').toString();
    final ySaat = (r['saat'] ?? '').toString();
    final yVakit = (r['vakit'] ?? '').toString();
    if (yTarih.isEmpty && ySaat.isEmpty && yVakit.isEmpty) {
      return false; // metinde yeni saat/gun yok -> duzeltme degil
    }
    _ss(() {
      if (yTarih.isNotEmpty) _tarih = yTarih;
      if (ySaat.isNotEmpty) {
        _saat = ySaat;
        _vakit = null; // NET saat verildi -> vakti ezer
      } else if (yVakit.isNotEmpty) {
        _vakit = yVakit;
        _saat = null; // VAKIT verildi -> eski net saati temizle ki vakit gecerli olsun
      }
    });
    await _musaitlikVeOnay(); // yeni tercihle bastan
    return true;
  }

  Future<void> _onayVeOlustur() async {
    // 1) Onay-ONCESI cakisma kontrolu (OLUSTURMADAN)
    _ss(() => _sistemMesaji = 'Çakışma kontrol ediliyor...');
    final chk = await sesliRandevuOlustur(
      salonid: widget.salonId,
      userId: _musteriId.toString(),
      tarih: _tarih!,
      saat: _saat!,
      hizmetId: _hizmetId.toString(),
      personelId: widget.personelId,
      fiyat: _hizmetFiyat,
      sureDk: _hizmetSure,
      sadeceKontrol: '1',
    );
    final cakismaVar = chk['cakismavar'] == '1' || chk['cakismavar'] == 1;

    final ozet =
        '${_musteriAd ?? "müşteri"}, ${_tarihSozlu(_tarih)} saat ${_saatSozlu(_saat)}, $_hizmetAd';

    // 2) Onay — cakisma bilgisiyle birlikte (tek seferde)
    bool onay;
    if (cakismaVar) {
      await _konus('$ozet.');
      onay = await _cakismaOnay((chk['cakisanunsurlar'] ?? '').toString());
    } else {
      await _konus('$ozet. Onaylıyor musunuz?');
      final c = await _dinle(pause: 2, listen: 8);
      final cl = _fold(c);
      onay = cl.contains('evet') ||
          cl.contains('onay') ||
          cl.contains('tamam') ||
          cl.contains('olur') ||
          cl.contains('olustur') ||
          cl.contains('kaydet');
    }
    if (!onay) {
      await _konus('İptal ettim, randevu oluşturulmadı.');
      return;
    }

    // 3) Olustur (cakisma varsa "yine de" moduyla)
    await _randevuYaz(cakismaVar);
  }

  /// Cakisma onayi: cakisan randevulari POPUP'ta gosterir + SESLI sorar.
  /// Karar hem butonla hem sesle verilebilir. true = yine de olustur.
  Future<bool> _cakismaOnay(String detay) async {
    final temizDetay = detay
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    final c = Completer<bool>();

    if (mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Çakışma Uyarısı'),
          content: SingleChildScrollView(
            child: Text(temizDetay.isEmpty
                ? 'Bu randevu başka bir randevu ile çakışıyor.'
                : 'Bu randevu şunlarla çakışıyor:\n\n$temizDetay'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (!c.isCompleted) {
                  Navigator.of(ctx).pop();
                  c.complete(false);
                }
              },
              child: const Text('VAZGEÇ'),
            ),
            TextButton(
              onPressed: () {
                if (!c.isCompleted) {
                  Navigator.of(ctx).pop();
                  c.complete(true);
                }
              },
              child: const Text('YİNE DE OLUŞTUR'),
            ),
          ],
        ),
      );
    }

    // Sesli sor + dinle (karar butonla verilmediyse sesle ver)
    await _konus(
        'Bu randevu başka randevularla çakışıyor. Ekrandaki listeye bakın. Yine de oluşturmak ister misiniz?');
    final cevap = await _dinle(pause: 2, listen: 8);
    final cl = _fold(cevap);
    if (!c.isCompleted) {
      final evet = cl.contains('evet') ||
          cl.contains('olustur') ||
          cl.contains('yine') ||
          cl.contains('olur');
      final hayir =
          cl.contains('hayir') || cl.contains('iptal') || cl.contains('vazgec');
      if (evet || hayir) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        c.complete(evet);
      }
      // net degilse: popup butonu bekler
    }
    return c.future;
  }

  /// Randevuyu yazar. Cakisma onaylandiysa (cakismaVar) "yine de olustur" moduyla.
  Future<void> _randevuYaz(bool cakismaVar) async {
    _ss(() => _sistemMesaji = 'Randevu oluşturuluyor...');
    try {
      final r = await sesliRandevuOlustur(
        salonid: widget.salonId,
        userId: _musteriId.toString(),
        tarih: _tarih!,
        saat: _saat!,
        hizmetId: _hizmetId.toString(),
        personelId: widget.personelId,
        fiyat: _hizmetFiyat,
        sureDk: _hizmetSure,
        cakisanrandevuekle: cakismaVar ? '1' : '',
      );

      // Olusturma reddedildi (cakisma VEYA calisma saati disi) -> GERCEK nedeni soyle.
      if (!cakismaVar && (r['cakismavar'] == '1' || r['cakismavar'] == 1)) {
        final neden = (r['cakisanunsurlar'] ?? '')
            .toString()
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll(r'\n', ' ')
            .replaceAll('\n', ' ')
            .trim();
        await _konus(neden.isNotEmpty
            ? 'Randevu oluşturulamadı. $neden'
            : 'Maalesef o saat müsait değil. Lütfen tekrar deneyin.');
        return;
      }
      if (r['hata'] != null) {
        await _konus('Randevu oluşturulamadı.');
        return;
      }

      await _konus('Randevu oluşturuldu.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Randevu oluşturuldu ✓')),
        );
      }
    } catch (e) {
      await _konus('Randevu oluşturulurken hata oldu.');
    }
  }

  /* ------------------------------------------------------------------ */
  /* YARDIMCILAR                                                        */
  /* ------------------------------------------------------------------ */

  String _fold(String s) {
    s = s
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
    return s.trim();
  }

  String _tarihSozlu(String? ymd) {
    if (ymd == null) return '';
    final p = ymd.split('-');
    if (p.length != 3) return ymd;
    final ay = int.tryParse(p[1]) ?? 0;
    final gun = int.tryParse(p[2]) ?? 0;
    if (ay < 1 || ay > 12) return ymd;
    return '$gun ${_aylar[ay]}';
  }

  String _saatSozlu(String? s) => (s ?? '').replaceAll(':', ' ');

  /* ------------------------------------------------------------------ */
  /* UI                                                                 */
  /* ------------------------------------------------------------------ */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5FB),
      appBar: AppBar(
        backgroundColor: mor,
        foregroundColor: Colors.white,
        title: const Text('Sesli Randevu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sistemKart(),
            const SizedBox(height: 20),
            _mikrofon(),
            const SizedBox(height: 16),
            _sesSecici(),
            const SizedBox(height: 16),
            _ozetKart(),
            if (_konusma.isNotEmpty) ...[
              const SizedBox(height: 16),
              _konusmaKart(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sistemKart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C008E), Color(0xFF7B2FB8), Color(0xFF9D5DC8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _sistemMesaji,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mikrofon() {
    final aktif = _dinliyor;
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _basla,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: aktif ? Colors.redAccent : mor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (aktif ? Colors.redAccent : mor).withOpacity(0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                aktif ? Icons.hearing : (_mesgul ? Icons.stop : Icons.mic),
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            aktif
                ? 'Dinliyorum...'
                : (_mesgul ? 'Sürüyor... (durdurmak için dokun)' : 'Başlamak için dokun'),
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _sesSecici() {
    if (_sunulan.length < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Asistan sesi (dokunup dinle)',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sunulan.map((s) {
              final name = s['name']!;
              final secili = name == _seciliSes;
              return ChoiceChip(
                label: Text(s['etiket']!),
                selected: secili,
                selectedColor: mor.withOpacity(0.18),
                labelStyle: TextStyle(
                  color: secili ? mor : Colors.black87,
                  fontWeight: secili ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => _sesDene(name),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _ozetKart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Randevu',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _satir('Personel', _personelAd, true),
          _satir('Müşteri', _musteriAd, _musteriId != null),
          _satir('Hizmet', _hizmetAd, _hizmetId != null),
          _satir('Tarih', _tarihSozlu(_tarih), _tarih != null),
          _satir('Saat', _saat, _saat != null),
        ],
      ),
    );
  }

  Widget _satir(String etiket, String? deger, bool tamam) {
    final dolu = deger != null && deger.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(tamam && dolu ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: tamam && dolu ? const Color(0xFF16A34A) : Colors.grey),
          const SizedBox(width: 10),
          SizedBox(
              width: 78,
              child: Text(etiket, style: const TextStyle(color: Colors.black54))),
          Expanded(
            child: Text(dolu ? deger : '—',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: dolu ? Colors.black : Colors.black38)),
          ),
        ],
      ),
    );
  }

  Widget _konusmaKart() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _konusma
            .map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(m, style: const TextStyle(fontSize: 13)),
                ))
            .toList(),
      ),
    );
  }
}
