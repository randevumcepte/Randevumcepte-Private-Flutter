import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// PATRON ASISTANI — sesli/yazili serbest soru sorup dogal cevap alan ekran.
///
/// Akis: cihazda STT ile konusma metne cevrilir (ya da elle yazilir) -> sunucudaki
/// /api/v1/patron-asistan-sor cagrilir (rakam gercek veriden hesaplanir) -> cevap
/// kart olarak gosterilir ve flutter_tts ile DOGAL sesle okunur.
///
/// Yetki: bu ekrana yalnizca Hesap Sahibi + Yonetici erisir (giris noktasi
/// Yetki.varMi('rapor.ciro_kar_gor') ile gizlenir). Sunucu da ayni kontrolu yapar.
class PatronAsistanEkrani extends StatefulWidget {
  final String salonId;
  const PatronAsistanEkrani({Key? key, required this.salonId}) : super(key: key);

  @override
  State<PatronAsistanEkrani> createState() => _PatronAsistanEkraniState();
}

class _PatronAsistanMesaj {
  final bool soru; // true = kullanici sorusu, false = asistan cevabi
  final String metin;
  final Map<String, dynamic>? kart;
  final Map<String, dynamic>? aksiyon; // varsa Onayla/Vazgec butonlari cikar (kampanya)
  bool aksiyonKapandi; // onay/vazgec sonrasi butonlar gizlensin
  _PatronAsistanMesaj(this.soru, this.metin, {this.kart, this.aksiyon})
      : aksiyonKapandi = false;
}

class _PatronAsistanEkraniState extends State<PatronAsistanEkrani>
    with SingleTickerProviderStateMixin {
  static const Color _mor = Color(0xFF5C008E);
  static const Color _mor2 = Color(0xFF7B2FB8);

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _metinC = TextEditingController();
  final ScrollController _scrollC = ScrollController();

  final List<_PatronAsistanMesaj> _mesajlar = [];
  bool _hazir = false;
  bool _dinliyor = false;
  bool _mesgul = false;
  bool _sesli = true; // cevabi sesli oku
  bool _sttGonderildi = false; // bu dinleme oturumunda soru gonderildi mi (cift tetik engeli)
  String _sonTaninan = ''; // STT'nin son tanidigi metin (finalResult atmayan motorlar icin oto-gonderim yedegi)
  String? _sonSoru; // son gonderilen soru (debounce)
  DateTime? _sonSoruZamani;
  late final AnimationController _donC; // Siri kuresi: surekli yavas donus
  double _ses = 0;   // STT ham ses seviyesi
  double _sesN = 0;  // yumusatilmis 0..1 ses (kure titresimi)

  @override
  void initState() {
    super.initState();
    _donC = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
    _mesajlar.add(_PatronAsistanMesaj(false,
        'Merhaba! İşletmeniz hakkında ne öğrenmek istersiniz? Mikrofona dokunup konuşun, bitince otomatik algılarım. (sürüm 18)'));
    _hazirla();
  }

  Future<void> _hazirla() async {
    final ok = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _dinliyor = false);
          // OTO-GONDERIM: bazi STT motorlari finalResult ATMAZ. Dinleme bitince
          // taninan metin varsa ve henuz gonderilmediyse KENDILIGINDEN sor.
          if (!_sttGonderildi && _sonTaninan.trim().isNotEmpty) {
            _sttGonderildi = true;
            final t = _sonTaninan.trim();
            _sonTaninan = '';
            _sor(t);
          }
        }
      },
      onError: (e) {
        if (mounted) setState(() => _dinliyor = false);
      },
    );
    await _sesAyarla();
    if (mounted) setState(() => _hazir = ok);
  }

  /// TTS'i dogal/akici + ERKEK ses yapar: Google motoru + Turkce erkek sesi.
  Future<void> _sesAyarla() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is List && engines.contains('com.google.android.tts')) {
        await _tts.setEngine('com.google.android.tts');
      }
    } catch (_) {}
    try {
      await _tts.setLanguage('tr-TR');
      await _erkekSesSec(); // erkek Turkce ses (sesli randevu ile ayni)
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  /// Erkek Turkce sesi sec: tr-tr-x-tmc (erkek/akici). Yoksa herhangi tr sesine dus.
  Future<void> _erkekSesSec() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      final tr = voices
          .map((v) => Map<String, dynamic>.from(v as Map))
          .where((v) => (v['locale'] ?? '').toString().toLowerCase().startsWith('tr'))
          .toList();
      if (tr.isEmpty) return;

      Map<String, dynamic>? hedef;
      // 1) Tam isim: tr-tr-x-tmc-network (erkek, network - en dogal)
      for (final v in tr) {
        if (v['name'].toString() == 'tr-tr-x-tmc-network') { hedef = v; break; }
      }
      // 2) 'tmc' iceren herhangi biri (network yoksa local)
      if (hedef == null) {
        for (final v in tr) {
          if (v['name'].toString().contains('tmc')) { hedef = v; break; }
        }
      }
      // 3) Yedek: ilk Turkce ses
      hedef ??= tr.first;
      await _tts.setVoice({'name': hedef['name'].toString(), 'locale': hedef['locale'].toString()});
    } catch (_) {}
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _donC.dispose();
    _metinC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  void _kaydir() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.animateTo(_scrollC.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _konus(String metin) async {
    if (!_sesli) return;
    try {
      await _tts.stop();
      await _tts.speak(metin);
    } catch (_) {}
  }

  /// Mikrofon: tek cumle dinle -> metne cevir -> otomatik sor.
  Future<void> _mic() async {
    if (!_hazir) return;
    if (_dinliyor) {
      await _speech.stop();
      if (mounted) setState(() => _dinliyor = false);
      return;
    }
    await _tts.stop();
    _sttGonderildi = false; // yeni oturum
    _sonTaninan = '';
    _ses = 0; _sesN = 0;
    setState(() => _dinliyor = true);
    try {
      await _speech.listen(
        onSoundLevelChange: (level) {
          // Ham seviyeyi 0..1'e getir + yumusat -> kure sese gore titresir.
          _ses = level;
          final hedef = (level.clamp(0.0, 10.0)) / 10.0;
          _sesN = _sesN + (hedef - _sesN) * 0.35;
          if (mounted && _dinliyor) setState(() {});
        },
        onResult: (r) {
          final t = r.recognizedWords.trim();
          if (t.isNotEmpty) {
            _metinC.text = t;
            _sonTaninan = t; // oto-gonderim yedegi (onStatus done'da kullanilir)
          }
          // final sonuc bazi motorlarda BIRDEN FAZLA gelir -> sadece ilkinde gonder,
          // ve tanimayi durdur ki ikinci kez ateslemesin.
          if (r.finalResult && !_sttGonderildi) {
            _sttGonderildi = true;
            _sonTaninan = '';
            _speech.stop();
            if (mounted) setState(() => _dinliyor = false);
            if (t.isNotEmpty) _sor(t);
          }
        },
        // pauseFor KOYMUYORUZ: sabit sessizlik sayaci yerine motorun KENDI dogal
        // "konusma bitti" (ses aktivite) algisi finalResult'i tetiklesin -> sen sustugunda
        // kendiliginden algilar, ortada kesmez. listenFor sadece gorunmez guvenlik tavani
        // (motor hic bitirmezse mikrofon sonsuza acik kalmasin).
        listenFor: const Duration(seconds: 60),
        listenOptions: stt.SpeechListenOptions(
          localeId: 'tr_TR',
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: false,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _dinliyor = false);
    }
  }

  Future<void> _gonder() async {
    final t = _metinC.text.trim();
    if (t.isEmpty) return;
    // Mikrofon dinlemedeyken SEND'e basilirsa: STT'nin bekleyen FINAL sonucunu
    // bastir (yoksa biri buradan biri STT'den = CIFT gonderim). Tek yol kalsin.
    _sttGonderildi = true;
    _speech.stop();
    if (_dinliyor && mounted) setState(() => _dinliyor = false);
    _sor(t);
  }

  Future<void> _sor(String metin) async {
    if (_mesgul) return;
    // Debounce: ayni soru cok kisa surede tekrar gelirse (cift tetikleme) yoksay.
    final simdi = DateTime.now();
    if (_sonSoru == metin &&
        _sonSoruZamani != null &&
        simdi.difference(_sonSoruZamani!).inSeconds < 6) {
      return;
    }
    _sonSoru = metin;
    _sonSoruZamani = simdi;
    _metinC.clear();
    setState(() {
      _mesajlar.add(_PatronAsistanMesaj(true, metin));
      _mesajlar.add(_PatronAsistanMesaj(false, '…'));
      _mesgul = true;
    });
    _kaydir();

    final yanit = await patronAsistanSor(widget.salonId, metin);
    final cevap = (yanit['cevap'] ?? 'Bir sorun oldu.').toString();
    final kart = yanit['kart'] is Map ? Map<String, dynamic>.from(yanit['kart']) : null;
    final aksiyon = yanit['aksiyon'] is Map ? Map<String, dynamic>.from(yanit['aksiyon']) : null;
    final seslendir = yanit['seslendir'] == true;

    setState(() {
      _mesajlar.removeLast(); // '…' baloncugunu kaldir
      _mesajlar.add(_PatronAsistanMesaj(false, cevap, kart: kart, aksiyon: aksiyon));
      _mesgul = false;
    });
    _kaydir();
    if (seslendir) _konus(cevap);
  }

  /// Onaylanan kampanyayi uygula (kupon + SMS gonder).
  Future<void> _uygula(_PatronAsistanMesaj m) async {
    if (m.aksiyon == null || m.aksiyonKapandi || _mesgul) return;
    setState(() {
      m.aksiyonKapandi = true;
      _mesajlar.add(_PatronAsistanMesaj(false, 'Uygulanıyor, lütfen bekleyin…'));
      _mesgul = true;
    });
    _kaydir();
    final yanit = await patronAsistanUygula(widget.salonId, m.aksiyon!);
    final cevap = (yanit['cevap'] ?? 'İşlem tamamlanamadı.').toString();
    setState(() {
      _mesajlar.removeLast();
      _mesajlar.add(_PatronAsistanMesaj(false, cevap));
      _mesgul = false;
    });
    _kaydir();
    if (yanit['seslendir'] == true) _konus(cevap);
  }

  /// Kampanyadan vazgec (gonderme).
  void _vazgec(_PatronAsistanMesaj m) {
    if (m.aksiyonKapandi) return;
    setState(() {
      m.aksiyonKapandi = true;
      _mesajlar.add(_PatronAsistanMesaj(false, 'Tamam, kampanyayı göndermedim.'));
    });
    _kaydir();
  }

  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      appBar: AppBar(
        backgroundColor: _mor,
        elevation: 0,
        title: const Text('Patron Asistanı', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: _sesli ? 'Sesli okuma açık' : 'Sesli okuma kapalı',
            icon: Icon(_sesli ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => _sesli = !_sesli);
              if (!_sesli) _tts.stop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollC,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
              itemCount: _mesajlar.length,
              itemBuilder: (c, i) => _baloncuk(_mesajlar[i]),
            ),
          ),
          _dinliyor ? _dinlemePaneli() : _oneriler(),
          _altBar(),
        ],
      ),
    );
  }

  Widget _oneriler() {
    final oneri = <String>[
      'Bugün kasa ne durumda?',
      'Bu ay ciro ne kadar?',
      'Bu hafta en çok kim sattı?',
      'Bugün kaç randevu var?',
    ];
    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 2),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: oneri.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (c, i) {
          final o = oneri[i];
          return Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _mesgul ? null : () => _sor(o),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE6DDF4)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0F5C008E), blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 13, color: _mor2),
                    const SizedBox(width: 6),
                    Text(o,
                        style: const TextStyle(
                            fontSize: 12.5, color: Color(0xFF4A3B6B), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _altBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, -3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _micDugme(),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 50),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FB),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: _dinliyor ? _mor2.withOpacity(.55) : const Color(0xFFEAE4F5),
                    width: _dinliyor ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 18),
                    Expanded(
                      child: TextField(
                        controller: _metinC,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _gonder(),
                        style: const TextStyle(fontSize: 14.5, color: Color(0xFF2a2340)),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          hintText: _dinliyor ? 'Dinliyorum, sizi duyuyorum…' : 'Sorunu yaz ya da mikrofona bas',
                          hintStyle: TextStyle(
                              color: _dinliyor ? _mor2 : const Color(0xFF9B90B3), fontSize: 13.5),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    // Gonder butonu SADECE metin yazilinca gorunur. Sesli girdide
                    // otomatik gonderim var -> mikrofonda gondere basmaya gerek yok.
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _metinC,
                      builder: (c, val, _) {
                        if (val.text.trim().isEmpty) return const SizedBox(width: 8);
                        return Padding(
                          padding: const EdgeInsets.all(5),
                          child: GestureDetector(
                            onTap: _gonder,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [_mor, _mor2]),
                              ),
                              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Alt bardaki KALITELI MOR mikrofon dugmesi. Dokun -> ortadaki kure acilir (dinle),
  /// tekrar dokun -> durdur.
  Widget _micDugme() {
    return GestureDetector(
      onTap: _mic,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _dinliyor
                ? const [Color(0xFF7B2FB8), Color(0xFF9D5DC8)]
                : const [_mor, _mor2],
          ),
          boxShadow: [
            BoxShadow(
              color: _mor.withOpacity(0.38),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          _dinliyor ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  /// Siri tarzi iridescent kure. size = cap; aktif = dinliyor (sese gore titresir).
  Widget _orb({required double size, required bool aktif}) {
    return AnimatedBuilder(
      animation: _donC,
      builder: (c, _) {
        final olcek = aktif ? (1.0 + _sesN * 0.14) : 1.0;
        return Transform.scale(
          scale: olcek,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _SiriOrbPainter(_donC.value, aktif ? _sesN : 0.0, aktif),
            ),
          ),
        );
      },
    );
  }

  /// Dinleme paneli: buyuk Siri kuresi + canli metin ("Sizi dinliyorum...").
  Widget _dinlemePaneli() {
    return GestureDetector(
      onTap: _mic, // kureye dokununca durdur
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _orb(size: 92, aktif: true),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _sonTaninan.isNotEmpty ? _sonTaninan : 'Sizi dinliyorum, konuşabilirsiniz…',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6A5A8C), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _baloncuk(_PatronAsistanMesaj m) {
    if (m.soru) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFECE7F6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(2),
            ),
          ),
          child: Text(m.metin, style: const TextStyle(fontSize: 14, color: Color(0xFF3a2a5c))),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 6, right: 30),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE7E2F0)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Text(m.metin, style: const TextStyle(fontSize: 14.5, color: Color(0xFF2a2340))),
          ),
          // Uzun cevaplarda (degerlendirme/karne vb.) kopyalama.
          if (m.metin.trim().length > 40 && m.metin != '…') _kopyaButonu(m.metin),
          if (m.kart != null) _kart(m.kart!),
          if (m.aksiyon != null && !m.aksiyonKapandi) _onayButonlari(m),
        ],
      ),
    );
  }

  /// Asistan cevabinin altinda kucuk "Kopyala" butonu (degerlendirme vb. icin).
  Widget _kopyaButonu(String metin) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10, top: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _kopyala(metin),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy_rounded, size: 14, color: Color(0xFF8B7BA8)),
              SizedBox(width: 4),
              Text('Kopyala',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8B7BA8), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  void _kopyala(String metin) {
    Clipboard.setData(ClipboardData(text: metin));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kopyalandı'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _onayButonlari(_PatronAsistanMesaj m) {
    // Wrap -> sigmazsa Vazgec alt satira iner, asla tasmaz. Etiket kisa (detay mesajda).
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8, top: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton.icon(
            onPressed: _mesgul ? null : () => _uygula(m),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Onayla ve Gönder', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _mor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          OutlinedButton(
            onPressed: _mesgul ? null : () => _vazgec(m),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7a6a95),
              side: const BorderSide(color: Color(0xFFD9CFEA)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Vazgeç', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
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

  /// Bilanco kartinin altindaki "PDF paylas" butonu.
  Widget _bilancoPaylasSatiri(Map<String, dynamic> k) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: () => _bilancoPdfPaylas(k),
          icon: const Icon(Icons.ios_share_rounded, size: 17),
          label: const Text('PDF olarak paylaş', style: TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _mor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }

  /// Bilancoyu logolu + salon isimli sik bir PDF yapip native paylas menusune verir.
  Future<void> _bilancoPdfPaylas(Map<String, dynamic> k) async {
    try {
      final base = await PdfGoogleFonts.robotoRegular();
      final bold = await PdfGoogleFonts.robotoBold();
      final doc = pw.Document(theme: pw.ThemeData.withFont(base: base, bold: bold));

      final logoBytes = (await rootBundle.load('images/salooncadde.png')).buffer.asUint8List();
      final logo = pw.MemoryImage(logoBytes);

      final salon = (k['salon_adi'] ?? '').toString();
      final baslik = (k['baslik'] ?? 'Bilanço').toString();
      final satirlar = (k['satirlar'] as List?) ?? [];
      final toplam = k['toplam'] is Map ? Map<String, dynamic>.from(k['toplam'] as Map) : null;

      final mor = const PdfColor.fromInt(0xFF5C008E);
      final mor2 = const PdfColor.fromInt(0xFF7B2FB8);
      final yesil = PdfColors.green700;
      final kirmizi = PdfColors.red700;

      final s = DateTime.now();
      final tarih =
          '${s.day.toString().padLeft(2, '0')}.${s.month.toString().padLeft(2, '0')}.${s.year}';

      pw.Widget hucre(String t,
          {bool bolt = false, PdfColor? renk, pw.TextAlign hiza = pw.TextAlign.left, double size = 10}) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: pw.Text(t,
              textAlign: hiza,
              style: pw.TextStyle(
                  fontSize: size,
                  fontWeight: bolt ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: renk ?? PdfColors.grey800)),
        );
      }

      pw.TableRow satirYap(Map<String, dynamic> m, {bool toplamMi = false}) {
        final kar = m['kar'] == true;
        return pw.TableRow(
          decoration: toplamMi ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F0FA)) : null,
          children: [
            hucre((m['ay'] ?? '').toString(), bolt: toplamMi),
            hucre((m['gelir'] ?? '').toString(), hiza: pw.TextAlign.right, bolt: toplamMi),
            hucre((m['gider'] ?? '').toString(), hiza: pw.TextAlign.right, bolt: toplamMi),
            hucre((m['net'] ?? '').toString(), hiza: pw.TextAlign.right, bolt: true, renk: kar ? yesil : kirmizi),
          ],
        );
      }

      // Gelir/gider dokumu (gruplu etiket-deger satirlari).
      final dokum = (k['dokum'] as List?) ?? [];
      List<pw.Widget> dokumWidgetlari() {
        final w = <pw.Widget>[];
        for (final r in dokum) {
          final m = Map<String, dynamic>.from(r as Map);
          if (m['grup'] != null) {
            w.add(pw.Padding(
              padding: const pw.EdgeInsets.only(top: 9, bottom: 3),
              child: pw.Text(m['grup'].toString(),
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: mor2)),
            ));
          } else {
            final vurgu = m['vurgu'] == true;
            final karVar = m.containsKey('kar');
            final karPoz = m['kar'] == true;
            final renk = karVar ? (karPoz ? yesil : kirmizi) : (vurgu ? mor : PdfColors.grey800);
            w.add(pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text((m['etiket'] ?? '').toString(),
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: vurgu ? pw.FontWeight.bold : pw.FontWeight.normal,
                        color: PdfColors.grey800)),
                pw.Text((m['deger'] ?? '').toString(),
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: renk)),
              ]),
            ));
          }
        }
        return w;
      }

      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(colors: [mor, mor2]),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 46,
                    height: 46,
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                        color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)),
                    child: pw.Image(logo),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(salon.isNotEmpty ? salon : 'İşletme',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(baslik, style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
                    ]),
                  ),
                  pw.Text(tarih, style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            ...dokumWidgetlari(),
            if (satirlar.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text('AYLIK TREND',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: mor2)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.symmetric(
                    inside: const pw.BorderSide(color: PdfColor.fromInt(0xFFE7E2F0), width: .5)),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2),
                  1: const pw.FlexColumnWidth(1.6),
                  2: const pw.FlexColumnWidth(1.6),
                  3: const pw.FlexColumnWidth(1.7),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEDE7F6)),
                    children: [
                      hucre('Ay', bolt: true, renk: mor),
                      hucre('Gelir', bolt: true, renk: mor, hiza: pw.TextAlign.right),
                      hucre('Gider', bolt: true, renk: mor, hiza: pw.TextAlign.right),
                      hucre('Net Kâr', bolt: true, renk: mor, hiza: pw.TextAlign.right),
                    ],
                  ),
                  ...satirlar.map((r) => satirYap(Map<String, dynamic>.from(r as Map))),
                  if (toplam != null) satirYap(toplam, toplamMi: true),
                ],
              ),
            ],
            pw.SizedBox(height: 24),
            pw.Divider(color: const PdfColor.fromInt(0xFFE7E2F0)),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Randevumcepte Patron Asistanı ile hazırlandı',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.Text(tarih, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
      ));

      final ad = salon.isNotEmpty ? salon.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_') : 'rapor';
      await Printing.sharePdf(bytes: await doc.save(), filename: 'bilanco_$ad.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF oluşturulamadı: $e')),
      );
    }
  }

  /// Gelir tablosu grup basligi (GELIR / GIDER / SONUC ...).
  Widget _bilancoGrup(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 11, bottom: 3),
      child: Text(t,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: _mor2, letterSpacing: .4)),
    );
  }

  /// Dokum satiri: etiket ..... deger (net kar yesil/kirmizi, vurgu kalin).
  Widget _dokumSatir(Map<String, dynamic> m) {
    final vurgu = m['vurgu'] == true;
    final karVar = m.containsKey('kar');
    final karPoz = m['kar'] == true;
    final renk = karVar
        ? (karPoz ? const Color(0xFF2E9E5B) : const Color(0xFFD9534F))
        : (vurgu ? _mor : const Color(0xFF3a2a5c));
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
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: renk)),
        ],
      ),
    );
  }

  /// Bilanco satiri: ay + Kar/Zarar rozeti + "Gelir X · Gider Y". toplam=kalin.
  Widget _bilancoSatir(Map<String, dynamic> m, {bool toplam = false}) {
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
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: toplam ? FontWeight.w800 : FontWeight.w700,
                        color: const Color(0xFF3a2a5c))),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: renk.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                child: Text('${kar ? "Kâr" : "Zarar"} ${m['net']}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: renk)),
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

  /// Karsilastirma satiri: etiket + yuzde rozeti (yesil/kirmizi) + "onceki -> bu".
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
              // Uzun urun/hizmet adlari tasmasin: esnek alan + en fazla 2 satir + ...
              Expanded(
                child: Text(m['etiket'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF3a2a5c))),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: renk.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text('$ok %$yuzde',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: renk)),
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

  Widget _satir(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(etiket, style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),),
          Text(deger, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _mor)),
        ],
      ),
    );
  }

  Widget _kart(Map<String, dynamic> k) {
    final tip = (k['tip'] ?? '').toString();
    final List<Widget> satirlar = [];

    if (tip == 'kasa') {
      if (k['toplam'] != null) satirlar.add(_satir('Toplam', _tl(k['toplam'])));
      final s = (k['satirlar'] as List?) ?? [];
      for (final r in s) {
        final m = Map<String, dynamic>.from(r as Map);
        satirlar.add(_satir(m['etiket'].toString(), _tl(m['tutar'])));
      }
    } else if (tip == 'personel_sirali' || tip == 'hizmet' || tip == 'urun') {
      final s = (k['satirlar'] as List?) ?? [];
      for (final r in s.take(5)) {
        final m = Map<String, dynamic>.from(r as Map);
        final ad = (m['ad'] ?? m['personel_adi'] ?? m['hizmet_adi'] ?? m['urun_adi'] ?? '').toString();
        satirlar.add(_satir(ad, _tl(m['ciro'] ?? 0)));
      }
    } else if (tip == 'personel_tek') {
      satirlar.add(_satir('Ciro', _tl(k['ciro'] ?? 0)));
      satirlar.add(_satir('İşlem', '${k['islem'] ?? 0}'));
      satirlar.add(_satir('Sıralama', '${k['sira'] ?? '-'}.'));
    } else if (tip == 'musteri') {
      satirlar.add(_satir('Aktif müşteri', '${k['toplam_aktif'] ?? 0}'));
      satirlar.add(_satir('Yeni / Tekrar', '${k['yeni'] ?? 0} / ${k['tekrar'] ?? 0}'));
    } else if (tip == 'ozet') {
      satirlar.add(_satir('Toplam tahsilat', _tl(k['toplam_gelir'] ?? 0)));
      satirlar.add(_satir('Randevu / Adisyon', '${k['toplam_randevu'] ?? 0} / ${k['toplam_adisyon'] ?? 0}'));
      satirlar.add(_satir('Nakit / Kart', '${_tl(k['nakit'] ?? 0)} / ${_tl(k['kart'] ?? 0)}'));
    } else if (tip == 'bugun') {
      final s = (k['liste'] as List?) ?? [];
      for (final r in s.take(6)) {
        final m = Map<String, dynamic>.from(r as Map);
        satirlar.add(_satir(
            '${m['saat'] ?? ''} ${m['musteri'] ?? ''}'.trim(), (m['personel'] ?? '').toString()));
      }
      if (s.isEmpty) satirlar.add(_satir('Randevu', 'yok'));
    } else if (tip == 'karsilastirma') {
      final s = (k['satirlar'] as List?) ?? [];
      final buAd = (k['bu_ad'] ?? 'bu').toString();
      final onAd = (k['onceki_ad'] ?? 'önceki').toString();
      for (final r in s) {
        final m = Map<String, dynamic>.from(r as Map);
        satirlar.add(_karsSatir(m, buAd, onAd));
      }
    } else if (tip == 'bilanco') {
      // Gelir/gider dokumu (gruplu).
      final dokum = (k['dokum'] as List?) ?? [];
      for (final r in dokum) {
        final m = Map<String, dynamic>.from(r as Map);
        if (m['grup'] != null) {
          satirlar.add(_bilancoGrup(m['grup'].toString()));
        } else {
          satirlar.add(_dokumSatir(m));
        }
      }
      // Aylik trend.
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
      margin: const EdgeInsets.only(bottom: 12, right: 20),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFECE7F6)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text((k['baslik'] ?? '').toString().toUpperCase(),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _mor2, letterSpacing: .3)),
          const SizedBox(height: 6),
          ...satirlar,
          if (tip == 'bilanco') _bilancoPaylasSatiri(k),
        ],
      ),
    );
  }
}

/// Siri tarzi iridescent kure cizeri. t=donus(0..1), level=ses(0..1), aktif=dinliyor.
/// Koyu zemin + donen mavi/mor/pembe/yesil bloblar (additive) + parlak cekirdek;
/// dinlerken dis tepki halkalari sese gore genisler.
class _SiriOrbPainter extends CustomPainter {
  final double t;
  final double level;
  final bool aktif;
  _SiriOrbPainter(this.t, this.level, this.aktif);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final ang = t * 2 * math.pi;

    // Dis tepki halkalari (dinlerken, sese gore genisler/parlar).
    if (aktif) {
      for (int i = 0; i < 3; i++) {
        final f = 1 - i * 0.28;
        final rr = r * (0.86 + i * 0.16) + level * r * 0.22;
        final op = ((0.22 * f) * (0.4 + level)).clamp(0.0, 0.5);
        canvas.drawCircle(
          c, rr,
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
      c, r,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFF2A0B4A), Color(0xFF0E0022)])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Donen iridescent bloblar (additive karisim).
    final blobs = <List<dynamic>>[
      [const Color(0xFF00D2FF), 0.0],
      [const Color(0xFF7C4DFF), 2.1],
      [const Color(0xFFFF4DA6), 4.2],
      [const Color(0xFF00E5A8), 5.6],
    ];
    final kayma = r * (0.34 + level * 0.12);
    for (final b in blobs) {
      final col = b[0] as Color;
      final ph = b[1] as double;
      final bc = Offset(
        c.dx + math.cos(ang + ph) * kayma,
        c.dy + math.sin(ang * 1.3 + ph) * kayma,
      );
      canvas.drawCircle(
        bc, r * 0.85,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(colors: [col.withOpacity(0.85), col.withOpacity(0.0)])
              .createShader(Rect.fromCircle(center: bc, radius: r * 0.85)),
      );
    }

    // Merkez parlak cekirdek (sese gore buyur).
    final cr = r * (0.42 + level * 0.18);
    canvas.drawCircle(
      c, cr,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
                colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.0)])
            .createShader(Rect.fromCircle(center: c, radius: cr)),
    );

    canvas.restore();

    // Cam kenar cizgisi.
    canvas.drawCircle(
      c, r - 0.6,
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
