import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'ikram_rapor.dart';
import 'kampanya_ayarlari.dart';

/// İkram Hizmet ("bir hizmeti N kez alana M ikram") — Çarkıfelek'ten bağımsız
/// yönetim sayfası ("Mor Işıltıda İkram Kampanyaları" tasarımı). Web /isletmeyonetim/ikramhizmet
/// ile aynı API ve kurallar (backend iç adı "damga kartı": /carkAdmin/damga-karti*).
/// Müşteri ikramını ne zaman kullanacağına kendisi karar verir; kullanım
/// tahsilat ekranında personel tarafından müşteri isteyince işlenir.
class IkramHizmetPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const IkramHizmetPage({super.key, required this.isletmebilgi, required this.kullanicirolu});

  @override
  State<IkramHizmetPage> createState() => _IkramHizmetPageState();
}

/// Tutar: 24750.5 -> "24.751"
String ikramTl(num? v) {
  final s = (v ?? 0).round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0 && s[i - 1] != '-') b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

String ikramTarih(String? t) {
  final d = DateTime.tryParse(t ?? '');
  if (d == null) return '';
  String iki(int x) => x.toString().padLeft(2, '0');
  return '${iki(d.day)}.${iki(d.month)}.${d.year}';
}

class _IkramHizmetPageState extends State<IkramHizmetPage> {
  static const _koyu = Color(0xFF2E1065);
  static const _mor = Color(0xFF7C3AED);
  static const _morKoyu = Color(0xFF5B21B6);
  static const _soluk = Color(0xFF6B5A8E);

  late final String _salonId;
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _kurallar = [];
  List<Map<String, dynamic>> _hizmetler = [];
  List<Map<String, dynamic>> _musteriler = [];
  Map<String, dynamic> _ozet = {};
  int _donem = 30;
  int _sablon = 5; // Kampanya Türü: 5+1 | 3+1
  String _filtre = 'tumu'; // tumu | aktif | pasif

  @override
  void initState() {
    super.initState();
    _salonId = widget.isletmebilgi['id'].toString();
    _yukle();
  }

  List<Map<String, dynamic>> _liste(dynamic v) =>
      ((v as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<void> _yukle() async {
    final r = await ikramHizmetYonetimGetir(_salonId, donem: _donem);
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (r != null) {
        _kurallar = _liste(r['kurallar']);
        _hizmetler = _liste(r['hizmetler']);
        _musteriler = _liste(r['musteriler']);
        _ozet = r['ozet'] is Map ? Map<String, dynamic>.from(r['ozet'] as Map) : {};
      }
    });
  }

  void _bilgi(String mesaj, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: hata ? Colors.red : _morKoyu,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ---------------------------------------------------------------- yardımcılar

  bool _aktifMi(Map<String, dynamic> k) => ((k['aktif'] as num?)?.toInt() ?? 0) == 1;

  /// aktif | pasif | bitti | baslayacak
  String _durum(Map<String, dynamic> k) {
    final simdi = DateTime.now();
    final bugun = DateTime(simdi.year, simdi.month, simdi.day);
    final bit = DateTime.tryParse((k['bitis_tarihi'] ?? '').toString());
    final bas = DateTime.tryParse((k['baslangic'] ?? '').toString());
    if (bit != null && bit.isBefore(bugun)) return 'bitti';
    if (!_aktifMi(k)) return 'pasif';
    if (bas != null && DateTime(bas.year, bas.month, bas.day).isAfter(bugun)) return 'baslayacak';
    return 'aktif';
  }

  double _kazanc(Map<String, dynamic> k) {
    final m = _ozet['kampanyalar'];
    if (m is Map) {
      final v = m[k['id'].toString()];
      if (v is Map) return (v['kazanc'] as num?)?.toDouble() ?? 0;
    }
    return 0;
  }

  /// Hizmet adına göre kampanya görseli (tasarımdaki üç fotoğraf)
  String _foto(String hizmet) {
    final h = hizmet.toLowerCase();
    const tirnak = ['tırnak', 'tirnak', 'oje', 'manikür', 'manikur', 'pedikür', 'pedikur', 'nail', 'jel', 'protez', 'kalıcı'];
    const cilt = ['cilt', 'yüz', 'yuz', 'bakım', 'bakim', 'hydra', 'facial', 'peeling', 'kirpik', 'kaş', 'kas', 'dudak', 'makyaj', 'liner', 'lazer', 'epilasyon', 'ağda', 'agda'];
    if (tirnak.any(h.contains)) return 'images/ikram_foto_tirnak.png';
    if (cilt.any(h.contains)) return 'images/ikram_foto_cilt.png';
    return 'images/ikram_foto_spa.png';
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final alt = MediaQuery.of(context).padding.bottom;
    final gorunen = _kurallar.where((k) {
      if (_filtre == 'aktif') return _durum(k) == 'aktif' || _durum(k) == 'baslayacak';
      if (_filtre == 'pasif') return _durum(k) == 'pasif' || _durum(k) == 'bitti';
      return true;
    }).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9DAF8), Color(0xFFF5EDFC), Color(0xFFEFE3FA)],
          ),
        ),
        child: Stack(children: [
          Positioned(left: 0, bottom: 0, child: IgnorePointer(child: Opacity(opacity: 0.85, child: Image.asset('images/kampanya_yaprak_sol.png', width: 70)))),
          Positioned(right: 0, bottom: 10, child: IgnorePointer(child: Opacity(opacity: 0.85, child: Image.asset('images/kampanya_yaprak_sag.png', width: 64)))),
          SafeArea(
            bottom: false,
            child: Column(children: [
              _ustBar(),
              Expanded(
                child: _yukleniyor
                    ? const Center(child: CircularProgressIndicator(color: _mor))
                    : RefreshIndicator(
                        color: _mor,
                        onRefresh: _yukle,
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 110 + alt),
                          children: [
                            _hero(),
                            const SizedBox(height: 14),
                            _turKarti(),
                            const SizedBox(height: 18),
                            _listeBaslik(),
                            const SizedBox(height: 10),
                            if (gorunen.isEmpty)
                              _bos(_kurallar.isEmpty
                                  ? 'Henüz kampanya yok.\nYukarıdan bir tür seçip "Yeni Kampanya" ile başlayın.'
                                  : 'Bu filtrede kampanya yok.')
                            else
                              ...gorunen.map(_kampanyaKart),
                          ],
                        ),
                      ),
              ),
            ]),
          ),
          if (!_yukleniyor) Positioned(left: 16, right: 16, bottom: 12 + alt, child: _altBar()),
        ]),
      ),
    );
  }

  Widget _daireDugme(Widget child, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.75),
            border: Border.all(color: Colors.white),
            boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      );

  Widget _ustBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(children: [
          _daireDugme(const Icon(Icons.arrow_back_rounded, color: _koyu, size: 24), () => Navigator.pop(context)),
          const Expanded(
            child: Text('İkram Hizmet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: _koyu, letterSpacing: -0.3)),
          ),
          _daireDugme(const Text('i', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _koyu)), _bilgiGoster),
        ]),
      );

  // ---------------------------------------------------------------- üst kart

  Widget _hero() {
    final toplam = (_ozet['toplam'] as num?) ?? 0;
    final artis = (_ozet['artis_yuzde'] as num?)?.toDouble();
    final oran = (_ozet['kullanim_orani'] as num?)?.toInt();
    return SizedBox(
      height: 232,
      child: Stack(clipBehavior: Clip.none, children: [
        // Sağda hediye kutusu (kartın arkasından taşar)
        Positioned(
          right: -16,
          top: 0,
          bottom: 6,
          width: 175,
          child: ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.transparent, Colors.black],
              stops: [0, 0.22],
            ).createShader(r),
            blendMode: BlendMode.dstIn,
            child: Image.asset('images/ikram_hediye_kutu.png', fit: BoxFit.cover, alignment: Alignment.centerLeft),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          right: 96,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6), Color(0xFF3B0764)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: _morKoyu.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Toplam Kazancınız',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 6),
              _donemSecici(),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(ikramTl(toplam),
                      style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.05)),
                  const SizedBox(width: 6),
                  const Text('TL', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(height: 6),
              if (artis != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: artis >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(artis >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 14, color: artis >= 0 ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D)),
                    const SizedBox(width: 3),
                    Text('%${artis.abs().toStringAsFixed(artis.abs() < 10 && artis % 1 != 0 ? 1 : 0)} ${artis >= 0 ? 'artış' : 'azalış'}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: artis >= 0 ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D))),
                  ]),
                )
              else
                Text('Önceki dönemle kıyas yok', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
              const Spacer(),
              IntrinsicHeight(
                child: Row(children: [
                  _istat(Icons.people_alt_rounded, '${(_ozet['kullanim'] as num?)?.toInt() ?? 0}', 'Kampanya\nKullanımı'),
                  _dikCizgi(),
                  _istat(Icons.savings_rounded, '${ikramTl(_ozet['ek_kazanc'] as num?)} TL', 'Ek\nKazanç'),
                  _dikCizgi(),
                  _istat(Icons.star_rounded, oran == null ? '—' : '%$oran', 'Kullanım\nOranı'),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _donemSecici() {
    const secenekler = {7: 'Son 7 Gün', 30: 'Son 30 Gün', 90: 'Son 90 Gün', 365: 'Son 1 Yıl'};
    return PopupMenuButton<int>(
      onSelected: (v) {
        setState(() => _donem = v);
        _yukle();
      },
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => secenekler.entries
          .map((e) => PopupMenuItem<int>(
                value: e.key,
                child: Text(e.value,
                    style: TextStyle(color: _koyu, fontWeight: e.key == _donem ? FontWeight.w800 : FontWeight.w500)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(secenekler[_donem] ?? 'Son $_donem Gün',
              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
        ]),
      ),
    );
  }

  Widget _istat(IconData ikon, String deger, String etiket) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(ikon, color: Colors.white.withValues(alpha: 0.85), size: 18),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(deger, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          ),
          Text(etiket, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 9.5, height: 1.15)),
        ]),
      );

  Widget _dikCizgi() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white.withValues(alpha: 0.22),
      );

  // ---------------------------------------------------------------- kartlar

  Widget _cam({required Widget child, EdgeInsets padding = const EdgeInsets.all(14), Border? kenar}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(24),
            border: kenar ?? Border.all(color: Colors.white, width: 1.2),
            boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _yeniKampanyaDugme() => GestureDetector(
        onTap: () => _kuralDuzenle(null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _morKoyu.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 16),
            SizedBox(width: 3),
            Text('Yeni Kampanya', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _turKarti() => _cam(
        child: Column(children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [Color(0xFFF3E8FF), Color(0xFFDDD0FB)]),
                boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: _morKoyu, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kampanya Türü', maxLines: 1, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _koyu)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Yeni bir kampanya oluşturun.', style: TextStyle(fontSize: 11, color: _soluk)),
                ),
              ]),
            ),
            _yeniKampanyaDugme(),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _sablonKart(5, 'images/ikram_etiket_5.png')),
            const SizedBox(width: 10),
            Expanded(child: _sablonKart(3, 'images/ikram_etiket_3.png')),
          ]),
        ]),
      );

  Widget _sablonKart(int adet, String gorsel) {
    final secili = _sablon == adet;
    return GestureDetector(
      onTap: () => setState(() => _sablon = adet),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(4, 8, 6, 8),
        decoration: BoxDecoration(
          color: secili ? const Color(0xFFF6F0FF) : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: secili ? _mor : const Color(0xFFE9DDF8), width: secili ? 1.6 : 1),
        ),
        child: Row(children: [
          Image.asset(gorsel, width: 46),
          const SizedBox(width: 4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('$adet+1 İkram', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _koyu)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('$adet hizmet alana\n1 hizmet hediye',
                    style: const TextStyle(fontSize: 10.5, height: 1.25, color: _morKoyu)),
              ),
            ]),
          ),
          Icon(secili ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              size: 18, color: secili ? _morKoyu : const Color(0xFFB9A5DD)),
        ]),
      ),
    );
  }

  Widget _listeBaslik() {
    const etiket = {'tumu': 'Tümü', 'aktif': 'Aktif', 'pasif': 'Pasif'};
    return Row(children: [
      const Icon(Icons.playlist_add_check_rounded, color: _morKoyu, size: 28),
      const SizedBox(width: 8),
      const Expanded(
        child: Text('Aktif Kampanyalarım', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _koyu)),
      ),
      PopupMenuButton<String>(
        onSelected: (v) => setState(() => _filtre = v),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        itemBuilder: (_) => etiket.entries
            .map((e) => PopupMenuItem<String>(value: e.key, child: Text(e.value, style: const TextStyle(color: _koyu))))
            .toList(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD8C8F3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(etiket[_filtre]!, style: const TextStyle(color: _koyu, fontSize: 13, fontWeight: FontWeight.w600)),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _koyu, size: 20),
          ]),
        ),
      ),
    ]);
  }

  Widget _kampanyaKart(Map<String, dynamic> k) {
    final adet = (k['gereken_adet'] as num?)?.toInt() ?? 0;
    final hediye = (k['ucretsiz_adet'] as num?)?.toInt() ?? 1;
    final hizmet = (k['hizmet_adi'] ?? 'Hizmet').toString();
    final durum = _durum(k);
    final bas = ikramTarih(k['baslangic']?.toString());
    final bit = ikramTarih(k['bitis_tarihi']?.toString());
    final tarih = bas.isEmpty ? 'Açılınca başlar' : '$bas – ${bit.isEmpty ? 'Süresiz' : bit}';
    final (renk, zemin, yazi) = switch (durum) {
      'aktif' => (const Color(0xFF15803D), const Color(0xFFDCFCE7), 'Aktif'),
      'baslayacak' => (const Color(0xFF1D4ED8), const Color(0xFFDBEAFE), 'Başlayacak'),
      'bitti' => (const Color(0xFF6B7280), const Color(0xFFF3F4F6), 'Bitti'),
      _ => (const Color(0xFF6B7280), const Color(0xFFF3F4F6), 'Pasif'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFDFBFF),
              border: Border(left: BorderSide(color: _mor, width: 4)),
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Opacity(
              opacity: durum == 'pasif' || durum == 'bitti' ? 0.6 : 1,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Fotoğraf + rozet
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: Stack(children: [
                      Positioned.fill(child: Image.asset(_foto(hizmet), fit: BoxFit.cover)),
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                            borderRadius: BorderRadius.only(bottomRight: Radius.circular(14), topLeft: Radius.circular(16)),
                          ),
                          child: Text('$adet+$hediye',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Text('$adet+$hediye $hizmet Kampanyası',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _koyu, height: 1.2)),
                      ),
                      _menu(k),
                    ]),
                    Text('$adet $hizmet alanlara\n$hediye $hizmet hediye!',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: _soluk, height: 1.3)),
                    const SizedBox(height: 6),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.calendar_month_rounded, size: 14, color: _mor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(tarih,
                                    style: const TextStyle(fontSize: 10.5, color: _soluk, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.circle, size: 7, color: renk),
                              const SizedBox(width: 4),
                              Text(yazi, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: renk)),
                            ]),
                          ),
                        ]),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1E9FD),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.bar_chart_rounded, color: _mor, size: 20),
                          const SizedBox(width: 4),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${ikramTl(_kazanc(k))} TL',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _koyu)),
                            const Text('Kazanç', style: TextStyle(fontSize: 10, color: _soluk)),
                          ]),
                        ]),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(Map<String, dynamic> k) {
    final aktif = _aktifMi(k);
    return SizedBox(
      width: 30,
      height: 26,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_vert_rounded, color: _koyu, size: 22),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (v) {
          if (v == 'duzenle') _kuralDuzenle(k);
          if (v == 'durum') _aktifDegistir(k);
          if (v == 'sil') _kuralSil(k);
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'duzenle', child: Row(children: [Icon(Icons.edit_rounded, color: _mor, size: 20), SizedBox(width: 10), Text('Düzenle')])),
          PopupMenuItem(
            value: 'durum',
            child: Row(children: [
              Icon(aktif ? Icons.pause_circle_rounded : Icons.play_circle_rounded, color: _mor, size: 20),
              const SizedBox(width: 10),
              Text(aktif ? 'Kapat' : 'Aç'),
            ]),
          ),
          const PopupMenuItem(value: 'sil', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), SizedBox(width: 10), Text('Sil')])),
        ],
      ),
    );
  }

  Widget _bos(String yazi) => Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        alignment: Alignment.center,
        child: Text(yazi, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _soluk, height: 1.4)),
      );

  Widget _altBar() => _cam(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFF3E8FF), Color(0xFFDDD0FB)]),
              boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.18), blurRadius: 10)],
            ),
            child: const Icon(Icons.trending_up_rounded, color: _morKoyu, size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Bu Ay Toplam Kazanç', style: TextStyle(fontSize: 12, color: _koyu, fontWeight: FontWeight.w600)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('${ikramTl(_ozet['bu_ay'] as num?)} TL',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _koyu, letterSpacing: -0.5)),
              ),
            ]),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IkramRaporSayfasi(
                  salonId: _salonId,
                  ilkDonem: _donem,
                  kurallar: _kurallar,
                  musteriler: _musteriler,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Detaylı Rapor', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
              ]),
            ),
          ),
        ]),
      );

  // ---------------------------------------------------------------- işlemler

  void _bilgiGoster() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('İkram Hizmet nasıl çalışır?', style: TextStyle(fontWeight: FontWeight.w800, color: _koyu)),
        content: const SingleChildScrollView(
          child: Text(
            '• Bir hizmeti belirlediğiniz sayıda ücretli alan müşteri o hizmetten ikram kazanır (ör. 5+1).\n'
            '• Sayım "Geldi" işaretli randevulara göre yapılır; paket seansları sayılmaz.\n'
            '• Müşteri ikramlarını uygulamasında görür ve ne zaman kullanacağına kendisi karar verir; '
            'kullanmak istediğinde tahsilat ekranından işlenir.\n\n'
            'Rakamlar:\n'
            '• Toplam Kazanç: seçilen dönemde kampanyadaki hizmetlerin satış tutarı (kampanya tarihleri içinde).\n'
            '• Ek Kazanç: aynı müşterinin kampanya içindeki 2. ve sonraki alımları — kampanyanın geri getirdiği satış.\n'
            '• Kampanya Kullanımı: dönemde kullanılan ikram sayısı.\n'
            '• Kullanım Oranı: kazanılan ikramların ne kadarının kullanıldığı.',
            style: TextStyle(fontSize: 13, height: 1.45, color: _koyu),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam', style: TextStyle(color: _mor)))],
      ),
    );
  }

  Future<void> _kuralDuzenle(Map<String, dynamic>? mevcut) async {
    final kaydedildi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KampanyaAyarlariSayfasi(
          salonId: _salonId,
          mevcut: mevcut,
          hizmetler: _hizmetler,
          varsayilanAdet: mevcut == null ? _sablon : null,
        ),
      ),
    );
    if (kaydedildi == true && mounted) {
      _yukle();
      _bilgi('Kampanya kaydedildi');
    }
  }

  /// ⋮ > Kapat / Aç: kuralın diğer alanları aynen gönderilir, yalnız aktif değişir.
  Future<void> _aktifDegistir(Map<String, dynamic> k) async {
    final aktif = _aktifMi(k);
    final bas = DateTime.tryParse((k['baslangic'] ?? '').toString());
    String ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final r = await carkAdminDamgaKartiKaydet(_salonId, {
      'id': k['id'],
      'hizmet_id': k['hizmet_id'],
      'gereken_adet': k['gereken_adet'],
      'ucretsiz_adet': k['ucretsiz_adet'],
      'aktif': aktif ? 0 : 1,
      'gecerlilik_deger': k['gecerlilik_deger'] ?? 0,
      'gecerlilik_birim': k['gecerlilik_birim'] ?? 'ay',
      'baslangic_tarihi': bas != null ? ymd(bas) : '',
      'bitis_tarihi': k['bitis_tarihi'] ?? '',
    });
    if (!mounted) return;
    if (r != null && r['basarili'] == true) {
      _yukle();
      _bilgi(aktif ? 'Kampanya kapatıldı' : 'Kampanya açıldı');
    } else {
      _bilgi(r?['mesaj']?.toString() ?? 'Değiştirilemedi', hata: true);
    }
  }

  Future<void> _kuralSil(Map<String, dynamic> k) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kampanyayı Sil'),
        content: Text('"${k['hizmet_adi']}" kampanyası silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await carkAdminDamgaKartiSil(_salonId, (k['id'] as num).toInt());
    if (!mounted) return;
    if (r != null && r['basarili'] == true) {
      _yukle();
      _bilgi('Kampanya silindi');
    } else {
      _bilgi(r?['mesaj']?.toString() ?? 'Silinemedi', hata: true);
    }
  }
}
