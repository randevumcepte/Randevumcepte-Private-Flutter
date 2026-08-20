import 'dart:async';
import 'package:flutter/material.dart';
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

class _PatronAsistanEkraniState extends State<PatronAsistanEkrani> {
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
  String? _sonSoru; // son gonderilen soru (debounce)
  DateTime? _sonSoruZamani;

  @override
  void initState() {
    super.initState();
    _mesajlar.add(_PatronAsistanMesaj(false,
        'Merhaba! İşletmen hakkında ne öğrenmek istersin? Yaz ya da mikrofona bas. (sürüm 6)'));
    _hazirla();
  }

  Future<void> _hazirla() async {
    final ok = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _dinliyor = false);
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
    setState(() => _dinliyor = true);
    try {
      await _speech.listen(
        onResult: (r) {
          final t = r.recognizedWords.trim();
          if (t.isNotEmpty) _metinC.text = t;
          // final sonuc bazi motorlarda BIRDEN FAZLA gelir -> sadece ilkinde gonder,
          // ve tanimayi durdur ki ikinci kez ateslemesin.
          if (r.finalResult && !_sttGonderildi) {
            _sttGonderildi = true;
            _speech.stop();
            if (mounted) setState(() => _dinliyor = false);
            if (t.isNotEmpty) _sor(t);
          }
        },
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 4),
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
          _oneriler(),
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
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: oneri
            .map((o) => Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                  child: ActionChip(
                    label: Text(o, style: const TextStyle(fontSize: 12, color: Color(0xFF5c4a7a))),
                    backgroundColor: const Color(0xFFF0EBF8),
                    side: const BorderSide(color: Color(0xFFE7E2F0)),
                    onPressed: _mesgul ? null : () => _sor(o),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _altBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _mic,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: _dinliyor ? const Color(0xFFE53935) : const Color(0xFFF0EBF8),
                child: Icon(Icons.mic, color: _dinliyor ? Colors.white : _mor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _metinC,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _gonder(),
                decoration: InputDecoration(
                  hintText: _dinliyor ? 'Dinliyorum…' : 'Sorunu yaz veya söyle...',
                  filled: true,
                  fillColor: const Color(0xFFF3F1F8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _gonder,
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: _mor2,
                child: Icon(Icons.send, color: Colors.white, size: 20),
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
          if (m.kart != null) _kart(m.kart!),
          if (m.aksiyon != null && !m.aksiyonKapandi) _onayButonlari(m),
        ],
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
        ],
      ),
    );
  }
}
