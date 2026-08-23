import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';

/// SESLI RANDEVU — sesli diyalog
/// Kullanici konusur -> sistem anlar -> eksik/belirsiz alanlari SESLI sorar ->
/// kullanici cevaplar -> sesli onaylatir -> randevu olusturur.
/// Randevu DAIMA giris yapan personel adina; hizmetler o personelinkiyle sinirli.
class SesliRandevuEkrani extends StatefulWidget {
  final String salonId;
  final String personelId;
  final dynamic isletmebilgi;
  final String baslangicKomut; // doluysa: ekran acilir acilmaz bu komutla basla
  final bool patronYetki; // true = hesap sahibi/yonetici -> isletme sorularini da yanit
  const SesliRandevuEkrani({
    Key? key,
    required this.salonId,
    this.personelId = '',
    this.isletmebilgi,
    this.baslangicKomut = '',
    this.patronYetki = false,
  }) : super(key: key);

  @override
  State<SesliRandevuEkrani> createState() => _SesliRandevuEkraniState();
}

class _SesliRandevuEkraniState extends State<SesliRandevuEkrani>
    with SingleTickerProviderStateMixin {
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

  // Siri kuresi: surekli yavas donus (_pulse) + gercek ses seviyesi
  late final AnimationController _pulse;
  double _ses = 0; // STT ham ses seviyesi
  double _sesN = 0; // yumusatilmis 0..1 (kure sese gore titresir)
  String _kullaniciAd = ''; // giris yapan kullanicinin ilk adi (selam icin)
  // Isletme (patron) sorusu cevabi -> alt panelde Randevu Ozeti yerine gosterilir.
  String? _isCevap;
  Map<String, dynamic>? _isKart;

  // Dinleme (tek cumle) tamamlama
  Completer<String>? _dinleC;
  String _dinleSon = '';
  bool _konusmaBasladi = false; // _dinle: kullanici konusmaya basladi mi
  bool _dinlemeBekle = false; // _dinle: konusma baslamadan gelen erken 'done'lari yok say

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
  // Randevunun ACILACAGI personel. Bos = giris yapan personel (widget.personelId).
  // Komutta baska personel adi gecerse backend onu doner -> burada guncellenir
  // (her personel herkese randevu acabilir). Takvim/musaitlik/olustur bunu kullanir.
  String _hedefPersonelId = '';
  String get _aktifPersonelId =>
      _hedefPersonelId.isNotEmpty ? _hedefPersonelId : widget.personelId;
  // Akisin herhangi bir adiminda kullanici BASKA bir alani duzeltirse true olur ->
  // _randevuAkisi dongusu bastan degerlendirir (eksik/degisen alani yeniden cozer).
  bool _yenidenDegerlendir = false;

  String _sistemMesaji = 'Mikrofona dokunun ve randevuyu söyleyin.';
  final List<String> _konusma = [];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..repeat();
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

  /// Giris yapan kullanicinin ilk adini prefs 'user'dan al (selam icin).
  Future<void> _kullaniciAdiYukle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('user');
      if (s != null && s.isNotEmpty) {
        final u = jsonDecode(s);
        final name = (u is Map ? (u['name'] ?? '') : '').toString().trim();
        if (name.isNotEmpty) {
          _kullaniciAd = name.split(RegExp(r'\s+')).first;
        }
      }
    } catch (_) {}
  }

  Future<void> _hazirla() async {
    await _kullaniciAdiYukle();
    final ok = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          // Kullanici HENUZ konusmaya baslamadiysa ve bilerek bekliyorsak
          // (gec baslama), cihazin baslangic sessizliginde firlattigi erken
          // kapanmayi YOK SAY -> "dinliyor ama kesildi" olmasin. Watchdog
          // yine de sonsuz takilmayi onler.
          if (_dinlemeBekle && !_konusmaBasladi) return;
          _dinlemeTamamla();
        }
      },
      onError: (e) => _dinlemeTamamla(),
    );
    await _sesAyarla();
    if (mounted) _ss(() => _hazir = ok);
    // Ekran acilir acilmaz otomatik basla: isimle selam + "randevu bilgilerini
    // soyler misiniz". Komutla gelindiyse (detayli) direkt onu isler.
    if (ok) {
      final k = widget.baslangicKomut.trim();
      _basla(ilkKomut: k.isEmpty ? null : k);
    }
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
    _pulse.dispose();
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
    _bipKisa(); // asistan KONUSMAYA BASLARKEN bip (bekletmez)
    try {
      await _tts.stop();
      await _tts.speak(_seslendirmeMetni(metin)); // BUYUK harfleri harf harf okumasin
    } catch (_) {}
  }

  /// Turkce kucuk harf (Dart'in toLowerCase'i Turkce degil: I->i yapar, biz ı).
  String _trKucuk(String s) =>
      s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

  /// TTS icin metni hazirlar: TAMAMI BUYUK harf olan kelimeleri (LAZER, AYŞE
  /// gibi DB'den gelen ad/hizmet adlari) bas harfi buyuk forma cevirir. Aksi
  /// halde motor bunlari kisaltma sanip HARF HARF okuyor. Ekrandaki yazi
  /// degismez; sadece OKUNUS duzelir.
  String _seslendirmeMetni(String s) {
    return s.replaceAllMapped(RegExp(r'[A-ZÇĞİÖŞÜ]{2,}'), (m) {
      final w = m.group(0)!;
      return w.substring(0, 1) + _trKucuk(w.substring(1));
    });
  }

  /// Kisa "konusma basliyor" bip'i — bekletmeden calar (asistan konusurken).
  void _bipKisa() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    try {
      _bip.play(AssetSource('images/bip6.wav'), volume: 0.7);
    } catch (_) {}
  }

  /// Tek cumle dinler; oturum kapaninca duyulan metni doner.
  /// Davranis: kullanici KONUSMAYA BASLAYANA KADAR bekler (2-3 sn gec baslamak
  /// sorun degil), konusma bitince kisa bir sessizlikte kapanir. STT hic cevap
  /// vermezse watchdog ile zorla kapatir -> sonsuz "dinliyor" takilmasi olmaz.
  /// pause = konusma bittikten sonra kac sn sessizlikte KAPANSIN.
  Future<String> _dinle({int pause = 2, int listen = 20}) async {
    if (!_hazir) return '';
    _dinleC = Completer<String>();
    _dinleSon = '';
    _konusmaBasladi = false;
    _dinlemeBekle = true; // konusma baslamadan gelen erken 'done'lari yok say
    _ss(() => _dinliyor = true);
    await _bipCal();

    Timer? sessizlikT; // konusma bitince kapatan sayac (cumle sonu)
    Timer? watchdogT; // hic cevap gelmezse zorla kapat (anti-hang)
    final int sessizlikMs = pause.clamp(1, 5) * 1000 + 400;

    void kapat() {
      sessizlikT?.cancel();
      watchdogT?.cancel();
      _dinlemeBekle = false;
      try {
        _speech.stop();
      } catch (_) {}
      _dinlemeTamamla();
    }

    // Konusma BASLADIKTAN sonra yeni kelime gelmezse (cumle bitti) kapat.
    void sessizligiZamanla() {
      sessizlikT?.cancel();
      sessizlikT = Timer(Duration(milliseconds: sessizlikMs), () {
        if (_konusmaBasladi) kapat();
      });
    }

    // Guvenlik agi: hic konusma olmasa bile listen suresi dolunca kapat.
    watchdogT = Timer(Duration(seconds: listen + 3), kapat);

    try {
      await _speech.listen(
        onResult: (r) {
          final t = r.recognizedWords.trim();
          if (t.isNotEmpty) {
            _dinleSon = t;
            _konusmaBasladi = true;
            _ss(() {});
            if (r.finalResult) {
              kapat();
              return;
            }
            sessizligiZamanla(); // her yeni kelimede cumle-bitti sayacini sifirla
          }
        },
        // pauseFor/listenFor'u GENIS tut: baslangictaki 2-3 sn sessizlik
        // dinlemeyi KESMESIN. Konusma bitince kapatmayi kendi kisa sessizlik
        // sayacimiz yapar (hizli).
        listenFor: Duration(seconds: listen + 3),
        pauseFor: Duration(seconds: listen + 3),
        onSoundLevelChange: (level) {
          // Ham seviyeyi 0..1'e getir + yumusat -> kure sese gore titresir.
          _ses = level;
          final hedef = (level.clamp(0.0, 10.0)) / 10.0;
          _sesN = _sesN + (hedef - _sesN) * 0.4;
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'tr_TR',
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: false,
        ),
      );
    } catch (_) {
      kapat();
    }
    final sonuc = await _dinleC!.future;
    sessizlikT?.cancel();
    watchdogT?.cancel();
    _dinlemeBekle = false;
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

  /// Hakaret/kufur iceriyor mu? (backend kufur seti + kullanici eklemeleri)
  bool _kufurMu(String metin) {
    final norm = ' ${_fold(metin)} ';
    const kelimeler = [
      'amk', 'aq', 'amina', 'amina koyayim', 'amcik', 'orospu', 'pic', 'siktir',
      'sikeyim', 'sikerim', 'sikik', 'sicayim', 'yarrak', 'yarak', 'gavat',
      'kahpe', 'ibne', 'serefsiz', 'pezevenk', 'gerizekali', 'geri zekali',
      'salak', 'aptal', 'embesil', 'denyo', 'yavsak', 'surtuk', 'godos',
      // kullanici istegi + es anlamlilar
      'allah belani versin', 'belani versin', 'cezani versin',
      'allah cezani versin', 'gebertirim', 'geberesin', 'geber', 'defol',
      'cehennem ol', 'lanet olsun', 'kahrol', 'kahrolasi', 'namussuz',
      'haysiyetsiz', 'onursuz', 'alcak', 'terbiyesiz', 'dangalak', 'ahmak',
      'sersem', 'hayvan herif', 'esek herif', 'adi herif', 'mal herif',
      'aptal herif', 'salak herif',
    ];
    for (final k in kelimeler) {
      if (norm.contains(' $k ')) return true;
    }
    return false;
  }

  String _kufurCevabi() =>
      'Efendim, sizi saygıya davet ediyorum. Böyle konuşmaya devam ederseniz görüşmeyi kapatmak zorunda kalacağım.';

  /// Mesaj bir BILGI/DANISMA sorusu mu? (hizmet adi gecse bile randevu DEGIL ->
  /// isletme/kalip asistanina gitmeli). Randevu KOMUTLARI bu isaretleri icermez.
  bool _bilgiSorusuMu(String metin) {
    final c = _fold(metin);
    const isaret = [
      'nedir', 'ne demek', 'ne ise', 'nasil', 'ne kadar', 'ne kadar surer',
      'kac seans', 'kac gun', 'kac saat', 'faydas', 'zarar', 'agri',
      'biraz daha', 'daha fazla', 'bilgi', 'hakkinda', 'ile ilgili', 'ilgili',
      'anlat', 'bahset', 'detay', 'acikla', 'aciklar', 'ogren', 'merak',
      'verir misin', 'verebilir', 'soyler misin', 'peki', 'baska ne',
      'yapilir mi', 'olur mu', 'gerekli mi', 'nasil bir', 'ne yaptir',
      'fiyat', 'ucret', 'kac para', 'kac tl', 'kac lira', 'kaca',
    ];
    for (final k in isaret) {
      if (c.contains(k)) return true;
    }
    return false;
  }

  /// Saat / tarih / hava gibi GERCEK bilgi sorulari (bedava). Cevap doner ya da null.
  Future<String?> _bilgiCevap(String metin) async {
    final c = _fold(metin);
    // SAAT (yerel, offline)
    if (c.contains('saat kac') ||
        (c.contains('saat') && c.contains('kac'))) {
      final n = DateTime.now();
      // SONA NOKTA YOK: "53." -> TTS "elli ucuncu" okuyor.
      return 'Şu an saat ${n.hour.toString().padLeft(2, '0')} ${n.minute.toString().padLeft(2, '0')}';
    }
    // TARIH / GUN (yerel, offline)
    if (c.contains('gunlerden ne') ||
        c.contains('bugun gun') ||
        c.contains('tarih ne') ||
        c.contains('hangi gun') ||
        c.contains('ayin kaci') ||
        c.contains('bugun ayin')) {
      final n = DateTime.now();
      const gunler = ['', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma',
          'Cumartesi', 'Pazar'];
      return 'Bugün ${gunler[n.weekday]}, ${n.day} ${_aylar[n.month]} ${n.year}';
    }
    // HAVA (wttr.in — ucretsiz, anahtarsiz; salonun sehriyle)
    if (c.contains('hava') || c.contains('yagmur') || c.contains('sicaklik') ||
        c.contains('derece') || c.contains('kar yag')) {
      final sehir = _sehirBul();
      if (sehir.isEmpty) {
        return 'Konumunuzu bilmediğim için hava durumunu veremiyorum, ama randevu oluşturabilirim.';
      }
      final h = await _havaGetir(sehir);
      return h ?? 'Hava durumuna şu an ulaşamadım, ama randevu oluşturabilirim.';
    }
    return null;
  }

  /// isletmebilgi'den sehir cikar (sehir/il/city; yoksa adresin son parcasi).
  String _sehirBul() {
    try {
      final b = widget.isletmebilgi;
      if (b is Map) {
        for (final k in ['sehir', 'il', 'city']) {
          final v = (b[k] ?? '').toString().trim();
          if (v.isNotEmpty) return v;
        }
        final adres = (b['adres'] ?? '').toString();
        if (adres.contains('/')) return adres.split('/').last.trim();
      }
    } catch (_) {}
    return '';
  }

  /// wttr.in'den kisa hava metni ("Güneşli +25°C"). Ulasilamazsa null.
  Future<String?> _havaGetir(String sehir) async {
    try {
      final uri = Uri.parse(
          'https://wttr.in/${Uri.encodeComponent(sehir)}?format=%C+%t&lang=tr&m');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        var t = res.body.trim();
        if (t.isNotEmpty && t.length < 60 && !t.toLowerCase().contains('unknown')) {
          // Sesli okuma icin temizle: "+" ve "°C" TTS'te bozuk okunuyor -> "derece".
          t = t
              .replaceAll('+', '')
              .replaceAll('°C', ' derece')
              .replaceAll('°', ' derece')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          return '$sehir için hava: $t';
        }
      }
    } catch (_) {}
    return null;
  }

  /// Randevu disi SOHBET kaliplari. Uygun cevabi doner; randevu komutuysa null.
  /// Kullanici tesekkur/veda ederse (kapat/iptal demeden) gorusmeyi kibarca
  /// bitirmek icin. Net randevu belirtisi varsa (randevu/tarih/sayi) tesekkur sayma.
  bool _tesekkurMu(String metin) {
    final c = _fold(metin);
    if (c.contains('randevu') ||
        c.contains('bugun') ||
        c.contains('yarin') ||
        c.contains('obur') ||
        RegExp(r'\d').hasMatch(c)) {
      return false;
    }
    const ks = [
      'tesekkur',
      'tesekurler',
      'sagol',
      'sag ol',
      'sagolun',
      'eyvallah',
      'minnettar',
      'ellerine saglik',
      'ellerinize saglik',
      'allah razi olsun',
      'var ol',
      'yeter bu kadar',
      'kendine iyi bak',
      'gorusuruz',
      'hosca kal',
      'hoscakal',
      'iyi gunler dilerim',
    ];
    return ks.any((k) => c.contains(k));
  }

  String? _sohbetCevap(String metin) {
    final c = _fold(metin);
    // Net randevu belirtisi varsa sohbet sayma -> komut olarak isle.
    if (c.contains('randevu') ||
        c.contains('bugun') ||
        c.contains('yarin') ||
        c.contains('obur') ||
        RegExp(r'\d').hasMatch(c)) {
      return null;
    }
    bool has(List<String> ks) => ks.any((k) => c.contains(k));

    if (has(['sen kimsin', 'kimsin', 'adin ne', 'adiniz ne', 'sen nesin',
        'kimsiniz', 'kim oldugun'])) {
      return 'Ben salonunuzun sesli randevu asistanıyım. Sesli komutla hızlıca randevu oluşturmanız için buradayım. Bir randevu oluşturmak ister misiniz?';
    }
    if (has(['ne yapabilir', 'ne yapar', 'ne ise yara', 'gorevin',
        'neler yapabilir', 'ne yapiyorsun', 'ne is yapar'])) {
      return 'Sesli komutla randevu oluşturabilirim. Örneğin, yarın saat ikide Ayşe Hanıma cilt bakımı diyebilirsiniz.';
    }
    if (has(['kim yaptin', 'kim yazdi', 'seni kim', 'kim gelistir', 'uretici',
        'kim uretti'])) {
      return 'Beni salonunuzun yazılım ekibi randevular için hazırladı. Hadi bir randevu oluşturalım mı?';
    }
    if (has(['nasilsin', 'naber', 'ne haber', 'iyi misin', 'keyifler',
        'nabersin', 'napiyorsun'])) {
      return 'Teşekkür ederim, gayet iyiyim. Sizin için bir randevu oluşturayım mı?';
    }
    // Not: tesekkur/veda artik _tesekkurMu ile ana donguce yakalanip gorusme
    // kibarca kapatiliyor; burada tekrar ele almiyoruz.
    if (has(['seni seviyorum', 'harikasin', 'supersin', 'muhtesemsin',
        'cok iyisin', 'bravo', 'helal olsun'])) {
      return 'Çok naziksiniz! Hadi size güzel bir randevu oluşturalım mı?';
    }
    if (has(['selam', 'merhaba', 'gunaydin', 'iyi gunler', 'iyi aksamlar',
        'iyi geceler', 'hosgeldin', 'alo'])) {
      return 'Merhaba! Size nasıl yardımcı olabilirim? Bir randevu oluşturmak ister misiniz?';
    }
    if (has(['mac', 'skor', 'futbol', 'fenerbahce', 'galatasaray', 'besiktas',
        'trabzon'])) {
      return 'Spor konusunda bilgim yok, ama size randevu oluşturabilirim.';
    }
    if (has(['dolar', 'euro', 'borsa', 'altin fiyat', 'doviz', 'haberler'])) {
      return 'Bu konuda bilgim yok, ama randevu oluşturmak için buradayım.';
    }
    if (has(['sarki', 'muzik', 'fikra', 'saka yap', 'espri', 'sarki soyle'])) {
      return 'Şarkı ve espri konusunda pek iyi değilim ama randevu ayarlamada ustayım. Ne zamana randevu istersiniz?';
    }
    if (has(['yemek tarif', 'nasil yapilir', 'film oner', 'kitap oner',
        'tarif ver'])) {
      return 'Bu konuda bilgim yok, ama size randevu oluşturabilirim.';
    }
    if (has(['kac yasinda', 'yasin kac', 'nerelisin', 'evli misin', 'robot musun',
        'insan misin', 'gercek misin'])) {
      return 'Ben bir randevu asistanıyım. Sorduğunuz için teşekkürler! Bir randevu oluşturalım mı?';
    }
    return null;
  }

  void _dinlemeTamamla() {
    if (_dinleC != null && !_dinleC!.isCompleted) {
      _dinleC!.complete(_dinleSon.trim());
    }
    _ses = 0;
    _sesN = 0;
    if (mounted) _ss(() => _dinliyor = false);
  }

  /* ------------------------------------------------------------------ */
  /* ANA AKIS                                                           */
  /* ------------------------------------------------------------------ */

  /// Ana asistan dongusu: konus -> SINIFLANDIR -> yonlendir. Tek ekran hepsini
  /// yonetir. Sahip: randevu + isletme sorulari; personel: sadece randevu.
  Future<void> _basla({String? ilkKomut}) async {
    if (_mesgul) {
      await _speech.stop();
      _dinlemeTamamla();
      return;
    }
    _sifirla();
    _ss(() {
      _mesgul = true;
      _isCevap = null;
      _isKart = null;
    });
    try {
      final selam =
          _kullaniciAd.isNotEmpty ? 'Merhaba ${_kullaniciAd}.' : 'Merhaba.';
      int kufurSay = 0;
      bool ilk = true;
      int bosSay = 0;
      while (!_iptal && mounted) {
        // KOMUT AL
        final String c;
        if (ilk &&
            ilkKomut != null &&
            ilkKomut.trim().isNotEmpty &&
            !_genelBaslatma(ilkKomut)) {
          c = ilkKomut.trim();
          _ss(() => _konusma.add('🎤 $c'));
        } else {
          // Sadece ilk turda selam+yonlendirme konus; sonraki turlarda
          // "Buyurun." tekrari kotu duruyor -> sessizce dinlemeye gec (bip yeterli).
          if (ilk) {
            await _konus(widget.patronYetki
                ? '$selam Randevu oluşturabilir ya da işletmenizi sorabilirsiniz.'
                : '$selam Randevu bilgilerini söyler misiniz?');
          }
          // Baslangic sessizligi KESMEZ (genis pauseFor). Konusma bitince ~2.4 sn'de
          // kapanir -> hizli ama kesmez. (pause 1 kesiyordu, 3 yavasti.)
          c = await _dinle(pause: 2, listen: 15);
        }
        ilk = false;
        if (_iptal) return;
        if (c.trim().isEmpty) {
          if (++bosSay >= 2) return;
          await _konus('Sizi duyamadım.');
          continue;
        }
        bosSay = 0;

        // 1) KUFUR -> nazik uyari (2. kez kapat)
        if (_kufurMu(c)) {
          kufurSay++;
          if (kufurSay >= 2) {
            await _konus('Bu şekilde devam edemeyeceğim. Görüşmeyi kapatıyorum.');
            return;
          }
          await _konus(_kufurCevabi());
          continue;
        }
        // 1b) TESEKKUR -> nazik kapanis (kapat/iptal demeye gerek yok)
        if (_tesekkurMu(c)) {
          await _konus(
              'Ben teşekkür ediyorum. Başka bir isteğiniz yoksa konuşmayı kapatıyorum.');
          return;
        }
        // 2) SAAT / TARIH / HAVA (bedava)
        final bilgi = await _bilgiCevap(c);
        if (bilgi != null) {
          _ss(() {
            _isCevap = bilgi;
            _isKart = null;
          });
          await _konus(bilgi);
          continue;
        }
        // 2c) BILGI/DANISMA sorusu (sahip/yonetici): mesaj bir bilgi sorusuysa
        //     (nedir/nasil/bilgi/hakkinda/ilgili/fiyat... VE "randevu" GECMIYORSA),
        //     hizmet adi gecse bile randevuya GITME -> isletme/kalip asistanina git.
        //     "dip boyasi ile ilgili bilgi ver" randevu ACMAZ, bilgi verir.
        //     Randevu komutlari (bilgi kelimesi icermeyen) bu guard'a TAKILMAZ -> normal
        //     randevu akisi bozulmadan calisir. (Additive/guard'li; mevcut akisa dokunmaz.)
        if (widget.patronYetki &&
            !c.toLowerCase().contains('randevu') &&
            _bilgiSorusuMu(c)) {
          await _isSorusu(c);
          continue;
        }
        // 3) RANDEVU mu? -> coz + randevu alt-akisi
        // SADECE yeni bir randevu sinyali (randevu/tarih/saat/rakam) varsa dolu
        // alanlari sifirla. Sadece isim gibi kisa bir ifade geldiyse dolu
        // hizmet/tarih/saat KORUNUR -> "bu hizmet yok deyip alanlari sildi"
        // bug'i olmaz. (Alanlar zaten her randevu turu sonunda temizleniyor,
        // bkz. _randevuAkisi finally -> stale sizinti yok.)
        if (_yeniRandevuSinyali(c) ||
            (_hizmetId == null && _tarih == null && _saat == null)) {
          _randevuAlanlariSifirla();
        }
        await _uygula(c);
        if (_iptal) return;
        final randevuMu = c.toLowerCase().contains('randevu') ||
            _hizmetId != null ||
            _musteriId != null ||
            _adaylar.isNotEmpty;
        if (randevuMu) {
          _ss(() {
            _isCevap = null; // alt panel Randevu Ozeti'ne donsun
            _isKart = null;
          });
          await _randevuAkisi();
          if (_iptal) return;
          continue;
        }
        // 4) ISLETME sorusu (sahip) ya da sohbet/yonlendirme (personel)
        if (widget.patronYetki) {
          await _isSorusu(c);
        } else {
          final sohbet = _sohbetCevap(c);
          final m = sohbet ??
              'Bu konuda bilgim yok, ama size randevu oluşturabilirim.';
          _ss(() {
            _isCevap = m;
            _isKart = null;
          });
          await _konus(m);
        }
      }
    } finally {
      if (mounted) _ss(() => _mesgul = false);
    }
  }

  /// Randevu alt-akisi: takvim/hizmet kontrolu + hizmet/musteri/musaitlik/olustur.
  /// YETKILI kullanici (randevu.tum_personel_gor) icin: randevu KIME diye sorar.
  /// Komuttan personel zaten cozulduyse (hedef dolu) sormaz. "bana/kendime" -> giris
  /// yapan personel. Yetkisiz kullanicida hic calismaz (hep kendi takvimi).
  Future<void> _hedefPersoneliSec() async {
    if (!Yetki.varMi('randevu.tum_personel_gor')) return; // yetkisiz -> hep kendine
    if (_hedefPersonelId.isNotEmpty) return; // komuttan zaten cozuldu
    for (int i = 0; i < 3 && !_iptal; i++) {
      await _konus(i == 0
          ? 'Hangi personele randevu oluşturayım? Kendiniz için "bana" diyebilirsiniz.'
          : 'Personel adını tekrar söyleyin, kendiniz için "bana" deyin.');
      final c = await _dinle();
      if (_iptal) return;
      if (c.trim().isEmpty) continue;
      final f = _fold(c);
      if (f == 'ben' ||
          f.contains('bana') ||
          f.contains('kendim') ||
          f.contains('kendi takvim') ||
          f.contains('benim takvim')) {
        _hedefPersonelId = widget.personelId; // giris yapan personel
        return;
      }
      // Personel adini backend ile coz (tumPersonel:true -> baska personel serbest).
      final r = await sesliRandevuCoz(widget.salonId, c,
          personelId: widget.personelId, tumPersonel: true);
      final p = r['personel'] as Map?;
      // sabit=true => isim eslesMEdi, backend giris yapana dustu -> KABUL ETME.
      final sabitP = p != null && p['sabit'] == true;
      final pid = (p != null ? (p['personel_id'] ?? '') : '').toString();
      if (!sabitP && pid.isNotEmpty && pid != '0') {
        _hedefPersonelId = pid;
        _personelAd = (p!['personel_adi'] ?? '').toString();
        if (_personelAd.isNotEmpty) {
          await _konus('$_personelAd için randevu oluşturuyorum.');
        }
        return;
      }
      await _konus('Bu isimde bir personel bulamadım.');
    }
    // Cozulemedi -> guvenli varsayilan: giris yapan personel.
    if (_hedefPersonelId.isEmpty) _hedefPersonelId = widget.personelId;
  }

  bool _alanGec(String f, List<String> ks) => ks.any((k) => f.contains(k));

  /// AKISIN HERHANGI BIR ADIMINDA capraz alan duzeltmesi. Kullanici mevcut sorunun
  /// disinda BASKA bir alani ACIKCA anip duzeltmek isterse (or. hizmet sorulurken
  /// "personeli degistir", saat sorulurken "hizmet sac boyama olsun") yakalar; ilgili
  /// alani gunceller/sifirlar ve _yenidenDegerlendir=true yapar -> _randevuAkisi bastan
  /// cozer. SADECE ilgili alan ACIKCA anildiginda tetiklenir (normal cevabi kacirmaz).
  Future<bool> _araDuzeltmeUygula(String c) async {
    final f = _fold(c);
    final istPersonel = _alanGec(f, ['personel', 'eleman', 'calisan']);
    final istMusteri = _alanGec(f, ['musteri', 'isim', 'kisi']);
    final istHizmet = _alanGec(f, ['hizmet', 'islem']);
    final istSaat = _alanGec(f, ['saat', 'kacta']);
    final istTarih = _alanGec(f, ['tarih', 'hangi gun']);
    if (!(istPersonel || istMusteri || istHizmet || istSaat || istTarih)) {
      return false; // alan ACIKCA anilmadi -> bu mevcut sorunun cevabi, duzeltme degil
    }
    final r = await sesliRandevuCoz(widget.salonId, c,
        personelId: _aktifPersonelId,
        tumPersonel: Yetki.varMi('randevu.tum_personel_gor'));
    bool degisti = false;

    if (istPersonel && Yetki.varMi('randevu.tum_personel_gor')) {
      final p = r['personel'] as Map?;
      final sabitP = p != null && p['sabit'] == true;
      final pid = (p != null ? (p['personel_id'] ?? '') : '').toString();
      if (p != null && !sabitP && pid.isNotEmpty && pid != '0') {
        _hedefPersonelId = pid;
        _personelAd = (p['personel_adi'] ?? '').toString();
      } else {
        _hedefPersonelId = ''; // yeni ad yok -> tekrar sorulacak
      }
      _hizmetId = null;
      _hizmetAd = null; // personel degisti -> hizmet yeniden cozulsun
      degisti = true;
    }
    if (istHizmet) {
      final hizmetler = (r['hizmetler'] as List?) ?? [];
      if (hizmetler.isNotEmpty) {
        final h = hizmetler.first;
        _hizmetId =
            h['hizmet_id'] is int ? h['hizmet_id'] : int.tryParse('${h['hizmet_id']}');
        _hizmetAd = h['hizmet_adi']?.toString();
        _hizmetFiyat = '${h['fiyat'] ?? 0}';
        _hizmetSure = '${h['sure_dk'] ?? 30}';
      } else {
        _hizmetId = null;
        _hizmetAd = null; // yeni ad yok -> tekrar sor
      }
      degisti = true;
    }
    if (istMusteri) {
      final m = (r['musteri'] as Map?) ?? {};
      if (m['user_id'] != null) {
        _musteriId =
            m['user_id'] is int ? m['user_id'] : int.tryParse('${m['user_id']}');
        final ad = (m['adaylar'] as List?) ?? [];
        if (ad.isNotEmpty) _musteriAd = ad.first['name']?.toString();
      } else {
        _musteriId = null;
        _musteriAd = null;
        _adaylar = [];
        _spokenAd = null;
        final adT = (m['ad_tahmini'] ?? '').toString().trim();
        if (adT.isNotEmpty) _spokenAd = _isimTemizle(adT);
      }
      degisti = true;
    }
    if (istSaat) {
      final ys = (r['saat'] ?? '').toString();
      final yv = (r['vakit'] ?? '').toString();
      if (ys.isNotEmpty) {
        _saat = ys;
        _vakit = null;
      } else if (yv.isNotEmpty) {
        _vakit = yv;
        _saat = null;
      } else {
        _saat = null;
        _vakit = null;
      }
      degisti = true;
    }
    if (istTarih) {
      final yt = (r['tarih'] ?? '').toString();
      _tarih = yt.isNotEmpty ? yt : null;
      degisti = true;
    }
    if (degisti) {
      _yenidenDegerlendir = true;
      await _konus('Tamam, güncelliyorum.');
    }
    return degisti;
  }

  Future<void> _randevuAkisi() async {
    try {
      // SLOT-DOLDURMA + ARA DUZELTME dongusu: eksik alanlari sirayla cozer; kullanici
      // HERHANGI bir adimda baska alani duzeltirse (_araDuzeltmeUygula ile) _yenidenDegerlendir
      // set edilir ve dongu BASTAN doner -> degisen/eksik alani yeniden cozer. Boylece
      // "hizmet sorulurken personeli degistir", "saat sorulurken hizmeti degistir" calisir.
      while (!_iptal && mounted) {
        _yenidenDegerlendir = false;

        // 1) PERSONEL (yetkili + secilmemis) -> "Hangi personele?"
        await _hedefPersoneliSec();
        if (_iptal) return;
        if (_yenidenDegerlendir) continue;
        // Hedef giris yapandan FARKLIYSA: giris yapan icin cozulmus hizmeti sifirla.
        if (_hedefPersonelId.isNotEmpty &&
            _hedefPersonelId != widget.personelId &&
            _hizmetId != null) {
          _hizmetId = null;
          _hizmetAd = null;
        }

        // 2) TAKVIM DURUMU (hedef personel icin). Baska personele aciliyorsa uyari
        // metinleri o personele gore (diger sekmeden gelen iyilestirme korundu).
        _ss(() => _sistemMesaji = 'Kontrol ediliyor...');
        final durum = await sesliRandevuTakvimDurumu(_aktifPersonelId);
        final baskaP =
            _hedefPersonelId.isNotEmpty && _hedefPersonelId != widget.personelId;
        final pAd = (_personelAd.isNotEmpty && _personelAd != 'Siz')
            ? _personelAd
            : 'Bu personel';
        if (durum['acik'] != true) {
          await _konus(baskaP
              ? '$pAd adlı personelin randevu takvimi kapalı (takvimi "Görünür" ve çalışma saatleri tanımlı olmalı). Bu personele randevu oluşturamıyorum.'
              : 'Randevu takviminiz açık değil. Çalışma saatleriniz tanımlı olmadan randevu oluşturamıyorum.');
          return;
        }
        if (durum['hizmet_var'] != true) {
          await _konus(baskaP
              ? '$pAd adlı personele tanımlı hizmet bulunmuyor. Bu personele randevu oluşturamıyorum.'
              : 'Size tanımlı hizmet bulunmuyor. Lütfen önce hizmetlerinizi tanımlayın.');
          return;
        }

        // 3) HIZMET
        if (_hizmetId == null) {
          await _hizmetCoz();
          if (_iptal) return;
          if (_yenidenDegerlendir) continue;
          if (_hizmetId == null) return;
        }
        // 4) MUSTERI
        if (_musteriId == null) {
          await _musteriCoz();
          if (_iptal) return;
          if (_yenidenDegerlendir) continue;
          if (_musteriId == null) return;
        }
        // 5) TARIH / SAAT (opsiyonel; net degilse musaitlik en yakini bulur)
        await _tarihCozSes();
        if (_iptal) return;
        if (_yenidenDegerlendir) continue;
        await _saatCozSes();
        if (_iptal) return;
        if (_yenidenDegerlendir) continue;

        break; // tum alanlar hazir
      }
      if (_iptal) return;
      await _musaitlikVeOnay();
    } finally {
      // Bu randevu turu bitti (olustu / iptal / vazgecildi) -> alanlari temizle
      // ki bir sonraki komuta stale hizmet/tarih/saat SIZMASIN. Boylece ana
      // dongudeki kosullu sifirlama (bkz. _yeniRandevuSinyali) guvenle calisir.
      _randevuAlanlariSifirla();
    }
  }

  /// Sadece randevu alanlarini temizle (yeni komut icin); _mesgul/_iptal'e dokunma.
  void _randevuAlanlariSifirla() {
    _musteriId = null;
    _musteriAd = null;
    _adaylar = [];
    _spokenAd = null;
    _hizmetId = null;
    _hizmetAd = null;
    _tarih = null;
    _saat = null;
    _vakit = null;
    _hedefPersonelId = ''; // hedef personel de sifirlansin -> sonraki komut giris yapana doner
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
    _hedefPersonelId = '';
    _konusma.clear();
  }

  /// Bir komut/cevap metnini backend'e cozdurup alanlari doldurur.
  Future<Map<String, dynamic>> _uygula(String metin) async {
    _ss(() => _sistemMesaji = 'Anlıyorum...');
    final r = await sesliRandevuCoz(widget.salonId, metin,
        personelId: _aktifPersonelId,
        // Baskasina randevu SADECE 'tum personel takvimi' yetkisi olanlara. Yetki
        // yoksa backend cumledeki baska personeli yoksayar -> kendi takvimine yazar.
        tumPersonel: Yetki.varMi('randevu.tum_personel_gor'));
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
    // Personel: SADECE komutta ACIKCA gecen personeli hedef yap. Backend, cumlede
    // isim gecmezse giris yapani 'sabit=true' ile doner -> ONU hedef YAPMA; boylece
    // yetkiliye "Hangi personele?" diye sorulabilir (aksi halde hedef hep Ferdi kalir
    // ve secim adimi hic calismaz). sabit=false = kullanici komutta personeli soyledi.
    final p = r['personel'] as Map?;
    if (p != null && p['personel_adi'] != null) {
      _personelAd = p['personel_adi'].toString();
    }
    final sabitP = p != null && p['sabit'] == true;
    if (p != null && !sabitP && p['personel_id'] != null) {
      final pid = p['personel_id'].toString();
      if (pid.isNotEmpty && pid != '0') _hedefPersonelId = pid;
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
          soru = (_hizmetAd ?? '').isNotEmpty
              ? '${_hizmetAd} için müşteri kim?'
              : 'Müşteri kim?';
        } else {
          soru = 'Adı tekrar söyleyin, yeni müşteri için "yeni" deyin.';
        }
        await _konus(soru);
        final c = await _dinle();
        if (_iptal) return;
        if (c.trim().isEmpty) continue;
        if (await _araDuzeltmeUygula(c)) return; // baska alan duzeltmesi -> bastan degerlendir
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
        if (await _araDuzeltmeUygula(c)) return; // baska alan duzeltmesi -> bastan degerlendir
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
      // Ad soylendi ama portfoyde bulunamadi -> dolu randevuyu (hizmet/tarih/
      // saat) KORUYARAK yeni musteri olarak kaydetmeyi teklif et. (Eskiden ana
      // donguye dusup dolu alanlari sifirliyor, sonra "bu hizmet yok" diyordu.)
      final ad = _spokenAd ?? '';
      if (ad.length >= 2) {
        await _konus('$ad adında kayıtlı müşteri bulamadım. Yeni müşteri olarak kaydedeyim mi?');
        final c = await _dinle();
        if (_iptal) return;
        if (_olumlu(c) || _yeniMi(c)) {
          await _yeniMusteriOlustur(ad);
          return;
        }
      }
      await _konus('Müşteriyi belirleyemedim. İsterseniz baştan söyleyebilirsiniz.');
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

  /// "randevu oluştur / almak istiyorum" gibi DETAYSIZ baslatma ifadesi mi?
  /// (Detay yoksa "bilgim yok" deme; isimle selam verip detay iste.)
  bool _genelBaslatma(String s) {
    const at = {
      'randevu', 'randevusu', 'olustur', 'olusturmak', 'olusturalim',
      'olusturabilir', 'istiyorum', 'isterim', 'almak', 'alabilir', 'vermek',
      'ver', 'al', 'bir', 'lutfen', 'bana', 'asistan', 'merhaba', 'selam',
      'olabilir', 'mi', 'miyim', 'acmak', 'ac'
    };
    final kalan = _fold(s)
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2 && !at.contains(w))
        .toList();
    return kalan.isEmpty;
  }

  /// Metin GERCEKTEN yeni bir randevu komutu mu? ("randevu" kelimesi, tarih/gun,
  /// vakit ya da rakam iceriyorsa evet). Sadece isim gibi kisa cevaplarda false
  /// -> devam eden randevunun dolu alanlari (hizmet/tarih/saat) silinmez.
  bool _yeniRandevuSinyali(String s) {
    final c = _fold(s);
    if (c.contains('randevu')) return true;
    if (RegExp(r'\d').hasMatch(c)) return true;
    const zaman = [
      'bugun', 'yarin', 'obur', 'sabah', 'ogle', 'oglen', 'aksam', 'gece',
      'pazartesi', 'sali', 'carsamba', 'persembe', 'cuma', 'cumartesi', 'pazar',
      'hafta', 'gun'
    ];
    return zaman.any((k) => c.contains(k));
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
      // ILK soru NAZIK "hangi hizmet?" olsun: kullanici hizmeti hic soylemeden
      // ("randevu olusturmak istiyorum") gelmis olabilir; ona "boyle hizmet yok"
      // demek yanlis. Ancak SONRAKI denemelerde (soyledi ama eslesmedi) uyar.
      final kime = (_musteriAd ?? '').isNotEmpty ? _musteriAd! : '';
      final soru = deneme == 1
          ? (kime.isNotEmpty
              ? '$kime için hangi hizmet?'
              : 'Hangi hizmet için randevu oluşturalım?')
          : 'Bu personele kayıtlı böyle bir hizmet bulamadım. Lütfen başka bir hizmet söyleyin.';
      await _konus(soru);
      final c = await _dinle();
      if (c.isEmpty) continue;
      if (await _araDuzeltmeUygula(c)) return; // baska alan duzeltmesi -> bastan degerlendir
      await _uygula(c);
    }
    if (_hizmetId == null && !_iptal) {
      await _konus('Hizmeti anlayamadım, işlemi iptal ediyorum.');
      _ss(() => _iptal = true);
    }
  }

  /// TARIH eksikse konusarak sorar. Zaten duyulduysa (veya vakit verildiyse
  /// -> "yarin sabah") hic sormaz. 2 denede net alinamazsa ZORLAMAZ; sonrasinda
  /// _musaitlikVeOnay en yakin uygun gunu bulur (akis kesilmez).
  Future<void> _tarihCozSes() async {
    if (_tarih != null || _iptal) return;
    int deneme = 0;
    while (_tarih == null && !_iptal && deneme < 2) {
      deneme++;
      await _konus(deneme == 1
          ? 'Randevu hangi gün olsun?'
          : 'Anlayamadım. Bugün, yarın ya da bir tarih söyleyin.');
      final c = await _dinle();
      if (_iptal) return;
      if (c.isEmpty) continue;
      if (await _araDuzeltmeUygula(c)) return; // baska alan duzeltmesi -> bastan degerlendir
      await _uygula(c);
    }
  }

  /// SAAT eksikse bir kez sorar. Kullanici net saat verirse onu kullaniriz;
  /// "en uygun/farketmez/sen ayarla" derse ya da net anlasilmazsa saat bos
  /// kalir -> _musaitlikVeOnay en yakin uygun saati bulup onaylatir. Vakit
  /// (sabah/aksam) zaten verildiyse hic sormaz.
  Future<void> _saatCozSes() async {
    if (_saat != null || _vakit != null || _iptal) return;
    await _konus('Saat kaçta olsun? İsterseniz en uygun saati ben ayarlayabilirim.');
    final c = await _dinle();
    if (_iptal || c.isEmpty) return;
    final cl = _fold(c);
    // "sen ayarla / en yakin / farketmez / ne uygunsa" -> saati musaitlik bulsun.
    const birak = ['farketmez', 'fark etmez', 'sen ayarla', 'sen bil', 'en yakin',
        'ne uygunsa', 'uygun olan', 'musaitse', 'onemli degil', 'sen sec'];
    if (birak.any((k) => cl.contains(k))) return;
    if (await _araDuzeltmeUygula(c)) return; // baska alan duzeltmesi -> bastan degerlendir
    await _uygula(c); // saat/vakit doldurmayi dene; olmazsa musaitlik devreye girer
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
      _aktifPersonelId,
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
    // Randevu BASKA bir personele aciliyorsa onayda belirt (kendisi ise ekleme).
    final baskaPersonel =
        _hedefPersonelId.isNotEmpty && _hedefPersonelId != widget.personelId;
    final personelOn = baskaPersonel ? '$_personelAd personeline, ' : '';

    // Onay iste — her durumda "farkli saat soyleyebilirsiniz" ipucuyla.
    String c;
    if (tamIstek) {
      await _konus(
          '$personelOn$kim, $zaman, $_hizmetAd. Onaylıyor musunuz? Düzeltmek istediğiniz olursa söyleyin; örneğin saat, tarih, müşteri ya da hizmet.');
      c = await _dinle(pause: 2, listen: 8);
    } else if (istenenSaat.isNotEmpty) {
      await _konus(
          'Vermek istediğiniz saatte başka bir müşterimizin randevusu bulunuyor. Şu an en yakın müsait saat $zaman. $personelOn$kim için bu saate oluşturayım mı? Düzeltmek istediğiniz olursa söyleyin; örneğin saat, tarih, müşteri ya da hizmet.');
      c = await _dinle(pause: 2, listen: 8);
    } else {
      await _konus(
          '$personelOn$kim için en yakın müsait saat $zaman. Bu saate oluşturayım mı? Düzeltmek istediğiniz olursa söyleyin; örneğin saat, tarih, müşteri ya da hizmet.');
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

  /// GENEL DUZELTME: onayda kullanici HERHANGI bir alani duzeltmek isterse
  /// (saat/tarih/musteri/hizmet/personel) yakalar, gunceller ve BASTAN onaylatir.
  ///  - Yeni deger cumlede varsa dogrudan uygular ("saat 3 olsun", "musteri Fatma",
  ///    "hizmet sac kesimi", "Didem'e olsun").
  ///  - Sadece "X yanlis/degistir/guncelle" derse o alani YENIDEN SORAR.
  /// Bir sey degistiyse true (ve tekrar onaylatir), yoksa false.
  Future<bool> _tercihDuzeltDeneVeTekrar(String metin) async {
    final f = _fold(metin);
    final r = await sesliRandevuCoz(widget.salonId, metin,
        personelId: _aktifPersonelId,
        tumPersonel: Yetki.varMi('randevu.tum_personel_gor'));
    bool degisti = false;

    // SAAT / TARIH / VAKIT (yeni deger)
    final yTarih = (r['tarih'] ?? '').toString();
    final ySaat = (r['saat'] ?? '').toString();
    final yVakit = (r['vakit'] ?? '').toString();
    if (yTarih.isNotEmpty) { _tarih = yTarih; degisti = true; }
    if (ySaat.isNotEmpty) {
      _saat = ySaat; _vakit = null; degisti = true;
    } else if (yVakit.isNotEmpty) {
      _vakit = yVakit; _saat = null; degisti = true;
    }

    // PERSONEL (yetkili + komutta ACIKCA baska personel -> sabit=false)
    final p = r['personel'] as Map?;
    final sabitP = p != null && p['sabit'] == true;
    if (p != null && !sabitP) {
      final pid = (p['personel_id'] ?? '').toString();
      if (pid.isNotEmpty && pid != '0' && pid != _aktifPersonelId) {
        _hedefPersonelId = pid;
        _personelAd = (p['personel_adi'] ?? '').toString();
        _hizmetId = null; _hizmetAd = null; // yeni personelde hizmeti yeniden coz
        degisti = true;
      }
    }

    // HIZMET (yeni hizmet adi)
    final hizmetler = (r['hizmetler'] as List?) ?? [];
    if (hizmetler.isNotEmpty) {
      final h = hizmetler.first;
      final hid = h['hizmet_id'] is int ? h['hizmet_id'] : int.tryParse('${h['hizmet_id']}');
      if (hid != null && hid != _hizmetId) {
        _hizmetId = hid;
        _hizmetAd = h['hizmet_adi']?.toString();
        _hizmetFiyat = '${h['fiyat'] ?? 0}';
        _hizmetSure = '${h['sure_dk'] ?? 30}';
        degisti = true;
      }
    }

    // MUSTERI (yeni NET musteri)
    final m = (r['musteri'] as Map?) ?? {};
    if (m['user_id'] != null) {
      final uid = m['user_id'] is int ? m['user_id'] : int.tryParse('${m['user_id']}');
      if (uid != null && uid != _musteriId) {
        _musteriId = uid;
        final adaylar = (m['adaylar'] as List?) ?? [];
        if (adaylar.isNotEmpty) _musteriAd = adaylar.first['name']?.toString();
        degisti = true;
      }
    }

    // YENI deger yok ama ACIK "X yanlis/degistir" -> o alani YENIDEN SOR
    if (!degisti) {
      final duzKelime = _alanGec(f,
          ['yanlis', 'degil', 'degistir', 'guncelle', 'duzelt', 'olmadi', 'hatali', 'yenile']);
      if (_alanGec(f, ['musteri', 'isim', 'kisi']) && (duzKelime || _alanGec(f, ['musteri']))) {
        _musteriId = null; _musteriAd = null; _adaylar = []; _spokenAd = null;
        await _musteriCoz();
        if (_iptal) return true;
        degisti = _musteriId != null;
      } else if (_alanGec(f, ['hizmet', 'islem']) && duzKelime) {
        _hizmetId = null; _hizmetAd = null;
        await _hizmetCoz();
        if (_iptal) return true;
        degisti = _hizmetId != null;
      } else if (_alanGec(f, ['saat', 'kacta', 'vakit'])) {
        _saat = null; _vakit = null;
        await _saatCozSes();
        if (_iptal) return true;
        degisti = true;
      } else if (_alanGec(f, ['tarih', 'gun', 'hangi gun'])) {
        _tarih = null;
        await _tarihCozSes();
        if (_iptal) return true;
        degisti = true;
      } else if (_alanGec(f, ['personel', 'eleman', 'calisan']) &&
          Yetki.varMi('randevu.tum_personel_gor')) {
        _hedefPersonelId = ''; _hizmetId = null; _hizmetAd = null;
        await _hedefPersoneliSec();
        if (_iptal) return true;
        degisti = true;
      }
    }

    if (!degisti) return false;
    // Personel/hizmet degistiyse hizmet bos kalmis olabilir -> once onu coz.
    if (_hizmetId == null) {
      await _hizmetCoz();
      if (_iptal || _hizmetId == null) return true;
    }
    await _musaitlikVeOnay(); // guncel bilgilerle BASTAN onaylat
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
      personelId: _aktifPersonelId,
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
        personelId: _aktifPersonelId,
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

      // Kutlama: klik/di-ding sesi + titresim + eglenceli popup
      await _bipCal();
      await _konus('Randevu oluşturuldu.');
      await _basariPopupGoster(); // Tamam'a basilana kadar bekler
      // Tamam -> _randevuAkisi doner -> ana dongu sessizce dinlemeye doner (basa don).
    } catch (e) {
      await _konus('Randevu oluşturulurken hata oldu.');
    }
  }

  /// Basari kutlamasi: ortada eglenceli emojili popup (marka moru) + Tamam.
  Future<void> _basariPopupGoster() async {
    if (!mounted) return;
    final ozet = [
      _musteriAd ?? 'Müşteri',
      '${_tarihSozlu(_tarih)} · ${_saatSozlu(_saat)}',
      if ((_hizmetAd ?? '').isNotEmpty) _hizmetAd!,
    ].join('\n');
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 62)),
              const SizedBox(height: 8),
              const Text('Randevu Oluşturuldu!',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: mor)),
              const SizedBox(height: 10),
              Text(ozet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.45)),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tamam',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  /* ------------------------------------------------------------------ */
  /* ISLETME (PATRON) SORUSU + KART CIZIMI (Patron Asistan'dan tasindi)  */
  /* ------------------------------------------------------------------ */

  static const Color _kMor = Color(0xFF5C008E);
  static const Color _kMor2 = Color(0xFF7B2FB8);

  /// Isletme sorusu: backend'e sor, cevabi + karti ALT PANELDE goster + sesli oku.
  Future<void> _isSorusu(String metin) async {
    _ss(() {
      _sistemMesaji = 'Bakıyorum…';
      _isCevap = '…';
      _isKart = null;
    });
    final yanit = await patronAsistanSor(widget.salonId, metin);
    final cevap = (yanit['cevap'] ?? 'Bir sorun oldu.').toString();
    final kart =
        yanit['kart'] is Map ? Map<String, dynamic>.from(yanit['kart']) : null;
    if (!mounted) return;
    _ss(() {
      _isCevap = cevap;
      _isKart = kart;
      _sistemMesaji = cevap;
    });
    await _konus(cevap);
  }

  String _tl(dynamic n) {
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0;
    final tam = d.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < tam.length; i++) {
      if (i > 0 && (tam.length - i) % 3 == 0) buf.write('.');
      buf.write(tam[i]);
    }
    return '${buf.toString()} ₺';
  }

  Widget _kartSatir(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              child: Text(etiket,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
          Text(deger,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kMor)),
        ],
      ),
    );
  }

  Widget _bilancoGrup(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 11, bottom: 3),
      child: Text(t,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _kMor2,
              letterSpacing: .4)),
    );
  }

  Widget _dokumSatir(Map<String, dynamic> m) {
    final vurgu = m['vurgu'] == true;
    final karVar = m.containsKey('kar');
    final karPoz = m['kar'] == true;
    final renk = karVar
        ? (karPoz ? const Color(0xFF2E9E5B) : const Color(0xFFD9534F))
        : (vurgu ? _kMor : const Color(0xFF3a2a5c));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(m['etiket'].toString(),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: vurgu ? FontWeight.w700 : FontWeight.w500,
                    color: const Color(0xFF555555))),
          ),
          const SizedBox(width: 10),
          Text(m['deger'].toString(),
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: renk)),
        ],
      ),
    );
  }

  Widget _bilancoSatir(Map<String, dynamic> m) {
    final kar = m['kar'] == true;
    final renk = kar ? const Color(0xFF2E9E5B) : const Color(0xFFD9534F);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text((m['ay'] ?? '').toString(),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3a2a5c))),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: renk.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9)),
                child: Text('${kar ? "Kâr" : "Zarar"} ${m['net']}',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: renk)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Gelir: ${m['gelir']}    Gider: ${m['gider']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6A5A8C))),
        ],
      ),
    );
  }

  Widget _karsSatir(Map<String, dynamic> m, String buAd, String onAd) {
    final iyi = m['iyi'] == true;
    final yon = (m['yon'] ?? 'flat').toString();
    final yuzde = m['yuzde'] ?? 0;
    final renk = yon == 'flat'
        ? const Color(0xFF9E9E9E)
        : (iyi ? const Color(0xFF2E9E5B) : const Color(0xFFD9534F));
    final ok = yon == 'up' ? '▲' : (yon == 'down' ? '▼' : '—');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(m['etiket'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3a2a5c))),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: renk.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9)),
                child: Text('$ok %$yuzde',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: renk)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('$onAd: ${m['onceki']}    →    $buAd: ${m['bu']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6A5A8C))),
        ],
      ),
    );
  }

  /// Patron Asistan kart cizimi (kasa/ciro/hizmet/urun/personel/musteri/ozet/
  /// bugun/karsilastirma/bilanco). PDF paylas butonu haric.
  Widget _kart(Map<String, dynamic> k) {
    final tip = (k['tip'] ?? '').toString();
    final List<Widget> satirlar = [];

    if (tip == 'kasa') {
      if (k['toplam'] != null) satirlar.add(_kartSatir('Toplam', _tl(k['toplam'])));
      final s = (k['satirlar'] as List?) ?? [];
      for (final r in s) {
        final m = Map<String, dynamic>.from(r as Map);
        satirlar.add(_kartSatir(m['etiket'].toString(), _tl(m['tutar'])));
      }
    } else if (tip == 'personel_sirali' || tip == 'hizmet' || tip == 'urun') {
      final s = (k['satirlar'] as List?) ?? [];
      for (final r in s.take(5)) {
        final m = Map<String, dynamic>.from(r as Map);
        final ad = (m['ad'] ?? m['personel_adi'] ?? m['hizmet_adi'] ?? m['urun_adi'] ?? '').toString();
        satirlar.add(_kartSatir(ad, _tl(m['ciro'] ?? 0)));
      }
    } else if (tip == 'personel_tek') {
      satirlar.add(_kartSatir('Ciro', _tl(k['ciro'] ?? 0)));
      satirlar.add(_kartSatir('İşlem', '${k['islem'] ?? 0}'));
      satirlar.add(_kartSatir('Sıralama', '${k['sira'] ?? '-'}.'));
    } else if (tip == 'musteri') {
      satirlar.add(_kartSatir('Aktif müşteri', '${k['toplam_aktif'] ?? 0}'));
      satirlar.add(_kartSatir('Yeni / Tekrar', '${k['yeni'] ?? 0} / ${k['tekrar'] ?? 0}'));
    } else if (tip == 'ozet') {
      satirlar.add(_kartSatir('Toplam tahsilat', _tl(k['toplam_gelir'] ?? 0)));
      satirlar.add(_kartSatir('Randevu / Adisyon', '${k['toplam_randevu'] ?? 0} / ${k['toplam_adisyon'] ?? 0}'));
      satirlar.add(_kartSatir('Nakit / Kart', '${_tl(k['nakit'] ?? 0)} / ${_tl(k['kart'] ?? 0)}'));
    } else if (tip == 'bugun') {
      final s = (k['liste'] as List?) ?? [];
      for (final r in s.take(6)) {
        final m = Map<String, dynamic>.from(r as Map);
        satirlar.add(_kartSatir(
            '${m['saat'] ?? ''} ${m['musteri'] ?? ''}'.trim(), (m['personel'] ?? '').toString()));
      }
      if (s.isEmpty) satirlar.add(_kartSatir('Randevu', 'yok'));
    } else if (tip == 'karsilastirma') {
      final s = (k['satirlar'] as List?) ?? [];
      final buAd = (k['bu_ad'] ?? 'bu').toString();
      final onAd = (k['onceki_ad'] ?? 'önceki').toString();
      for (final r in s) {
        satirlar.add(_karsSatir(Map<String, dynamic>.from(r as Map), buAd, onAd));
      }
    } else if (tip == 'bilanco') {
      final dokum = (k['dokum'] as List?) ?? [];
      for (final r in dokum) {
        final m = Map<String, dynamic>.from(r as Map);
        if (m['grup'] != null) {
          satirlar.add(_bilancoGrup(m['grup'].toString()));
        } else {
          satirlar.add(_dokumSatir(m));
        }
      }
      final s = (k['satirlar'] as List?) ?? [];
      if (s.isNotEmpty) {
        satirlar.add(_bilancoGrup('AYLIK TREND'));
        for (final r in s) {
          satirlar.add(_bilancoSatir(Map<String, dynamic>.from(r as Map)));
        }
      }
    }

    if (satirlar.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFECE7F6)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text((k['baslik'] ?? '').toString().toUpperCase(),
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: _kMor2,
                  letterSpacing: .3)),
          const SizedBox(height: 6),
          ...satirlar,
        ],
      ),
    );
  }

  /// Alt panel: isletme (patron) sorusunun cevabi + kart.
  Widget _isCevapKart() {
    final cevap = _isCevap ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEBF7)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, size: 19, color: Color(0xFF8B5CF6)),
              SizedBox(width: 8),
              Text('Asistan',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF221F35))),
            ],
          ),
          const SizedBox(height: 8),
          Text(cevap,
              style: const TextStyle(
                  fontSize: 15, height: 1.4, color: Color(0xFF2B2740))),
          if (_isKart != null) _kart(_isKart!),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F5FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF221F35),
        title: const Text('Sesli Asistan',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          if (_sunulan.length >= 2)
            IconButton(
              tooltip: 'Asistan sesi',
              icon: const Icon(Icons.record_voice_over_rounded),
              color: const Color(0xFF8B5CF6),
              onPressed: _sesSecPaneliAc,
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 22),
            _mikrofon(),
            const SizedBox(height: 30),
            // ALT PANEL DINAMIK: isletme cevabi varsa onu, yoksa Randevu Ozeti.
            _isCevap != null ? _isCevapKart() : _ozetKart(),
          ],
        ),
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
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 200,
              height: 200,
              child: Center(child: _orb(size: 168, aktif: aktif)),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              aktif
                  ? (_dinleSon.isNotEmpty ? _dinleSon : 'Dinliyorum…')
                  : (_mesgul ? _sistemMesaji : 'Başlamak için dokun'),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF6B6880),
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Siri tarzi iridescent kure. aktif = dinliyor (sese gore BELIRGIN titresir).
  Widget _orb({required double size, required bool aktif}) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (c, _) {
        final olcek = aktif ? (1.0 + _sesN * 0.16) : 1.0;
        // Konusurken hafif tremble: ses seviyesine gore genlik (olculu).
        final ph = _pulse.value * 2 * pi;
        final genlik = aktif ? _sesN * 3.0 : 0.0;
        final dx = sin(ph * 57) * genlik;
        final dy = cos(ph * 63) * genlik;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: olcek,
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter:
                    _SiriOrbPainter(_pulse.value, aktif ? _sesN : 0.0, aktif),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Sag ust ikondan acilan ses secme paneli (alt sheet). Dokun -> dinle -> sec.
  void _sesSecPaneliAc() {
    if (_sunulan.length < 2) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE0DCEC),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.record_voice_over_rounded,
                      size: 20, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 8),
                  Text('Asistan sesi',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF221F35))),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Dokunup dinleyin, beğendiğinizi seçin.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8A8699))),
              const SizedBox(height: 14),
              ..._sunulan.map((s) {
                final name = s['name']!;
                final secili = name == _seciliSes;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      _sesDene(name);
                      setSheet(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: secili
                            ? const LinearGradient(colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFF6366F1)
                              ])
                            : null,
                        color: secili ? null : const Color(0xFFF3F1FA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              secili
                                  ? Icons.check_circle_rounded
                                  : Icons.volume_up_rounded,
                              size: 20,
                              color: secili
                                  ? Colors.white
                                  : const Color(0xFF8B5CF6)),
                          const SizedBox(width: 10),
                          Text(s['etiket']!,
                              style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: secili
                                      ? Colors.white
                                      : const Color(0xFF4A4660))),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ozetKart() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEBF7)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.event_available_rounded,
                  size: 19, color: Color(0xFF8B5CF6)),
              SizedBox(width: 8),
              Text('Randevu Özeti',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF221F35))),
            ],
          ),
          const SizedBox(height: 8),
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
    final ok = tamam && dolu;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: ok
                  ? const Color(0xFF22C55E).withOpacity(0.12)
                  : const Color(0xFFF1F0F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ok ? Icons.check_rounded : Icons.circle_outlined,
              size: 15,
              color: ok ? const Color(0xFF16A34A) : const Color(0xFFBDBACB),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
              width: 74,
              child: Text(etiket,
                  style:
                      const TextStyle(color: Color(0xFF8A8699), fontSize: 14))),
          Expanded(
            child: Text(dolu ? deger : '—',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: dolu
                        ? const Color(0xFF221F35)
                        : const Color(0xFFC3C0D0))),
          ),
        ],
      ),
    );
  }
}

/// Patron Asistan'daki ile ayni Siri tarzi iridescent kure (donen bloblar,
/// dis tepki halkalari, sese gore titresen cekirdek).
class _SiriOrbPainter extends CustomPainter {
  final double t;
  final double level;
  final bool aktif;
  _SiriOrbPainter(this.t, this.level, this.aktif);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final ang = t * 2 * pi;

    // Dis tepki halkalari (dinlerken, sese gore genisler/parlar).
    if (aktif) {
      for (int i = 0; i < 3; i++) {
        final f = 1 - i * 0.28;
        final rr = r * (0.86 + i * 0.16) + level * r * 0.40;
        final op = ((0.30 * f) * (0.5 + level)).clamp(0.0, 0.6);
        canvas.drawCircle(
          c,
          rr,
          Paint()
            ..color = const Color(0xFF3AD8FF).withOpacity(op)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }

    // Kureyi daireye kirp.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));

    // Koyu zemin.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader =
            const RadialGradient(colors: [Color(0xFF2A0B4A), Color(0xFF0E0022)])
                .createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Donen iridescent bloblar (additive karisim).
    final blobs = <List<dynamic>>[
      [const Color(0xFF00D2FF), 0.0],
      [const Color(0xFF7C4DFF), 2.1],
      [const Color(0xFFFF4DA6), 4.2],
      [const Color(0xFF00E5A8), 5.6],
    ];
    final kayma = r * (0.34 + level * 0.24);
    for (final b in blobs) {
      final col = b[0] as Color;
      final ph = b[1] as double;
      final bc = Offset(
        c.dx + cos(ang + ph) * kayma,
        c.dy + sin(ang * 1.3 + ph) * kayma,
      );
      canvas.drawCircle(
        bc,
        r * 0.85,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
                  colors: [col.withOpacity(0.85), col.withOpacity(0.0)])
              .createShader(Rect.fromCircle(center: bc, radius: r * 0.85)),
      );
    }

    // Merkez parlak cekirdek (sese gore buyur).
    final cr = r * (0.42 + level * 0.34);
    canvas.drawCircle(
      c,
      cr,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: [
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.0)
        ]).createShader(Rect.fromCircle(center: c, radius: cr)),
    );

    canvas.restore();

    // Cam kenar cizgisi.
    canvas.drawCircle(
      c,
      r - 0.6,
      Paint()
        ..color = Colors.white.withOpacity(0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(covariant _SiriOrbPainter old) =>
      old.t != t || old.level != level || old.aktif != aktif;
}
