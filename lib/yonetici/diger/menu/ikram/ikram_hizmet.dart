import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'ikram_rapor.dart';
import 'kampanya_ayarlari.dart';
import 'kampanya_detay.dart';

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

  /// Kampanya kartı görseli: işletmenin yüklediği fotoğraf, yoksa hizmete uygun hazır görsel.
  Widget _foto(Map<String, dynamic> k, String hizmet) {
    final hazir = Image.asset(ikramHazirGorsel(hizmet), fit: BoxFit.cover);
    final g = (k['gorsel'] ?? '').toString();
    if (g.isEmpty) return hazir;
    return Image.network('https://app.randevumcepte.com.tr$g', fit: BoxFit.cover, errorBuilder: (_, __, ___) => hazir);
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
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 110 + alt),
                          children: [
                            _hero(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                const SizedBox(height: 8),
                                _turKarti(),
                                const SizedBox(height: 18),
                                _listeBaslik(),
                                const SizedBox(height: 10),
                                if (gorunen.isEmpty)
                                  _bos(_kurallar.isEmpty
                                      ? 'Henüz kampanya yok.\n"Yeni Kampanya" ile ilk kampanyanızı oluşturun.'
                                      : 'Bu filtrede kampanya yok.')
                                else
                                  ...gorunen.map(_kampanyaKart),
                              ]),
                            ),
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
          // Bilgi: küçük, ince çizgili ikon (başlık ortada kalsın diye geri düğmesi genişliğinde alan)
          SizedBox(
            width: 46,
            child: Center(
              child: GestureDetector(
                onTap: _bilgiGoster,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.7),
                    border: Border.all(color: const Color(0xFFE4D7F7)),
                    boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: _morKoyu, size: 19),
                ),
              ),
            ),
          ),
        ]),
      );

  // ---------------------------------------------------------------- üst kart

  /// Tasarımın üst kartı birebir görsel (kart + hediye kutusu + etiketler/ikonlar).
  /// Görseldeki değişen yazılar (dönem, tutar, artış, üç rakam) silindi; canlı değerler
  /// aynı konumlara oturtulur. Ölçüler görselin pikselleri (941 x 382) üzerinden oranlanır.
  Widget _hero() {
    final toplam = (_ozet['toplam'] as num?) ?? 0;
    final artis = (_ozet['artis_yuzde'] as num?)?.toDouble();
    final oran = (_ozet['kullanim_orani'] as num?)?.toInt();
    return LayoutBuilder(builder: (c, k) {
      final w = k.maxWidth;
      final h = w * 382 / 941;
      double x(num px) => w * px / 941;
      double y(num px) => h * (px - 118) / 382; // tasarım y koordinatı (kesim 118'den başlar)
      // Alt üç sütun: ikon + rakam + etiket (görseldeki küçük yazılar silindi, burada büyük yazılır)
      Widget rakam(num sol, num sag, IconData ikon, String deger, String etiket) => Positioned(
            left: x(sol),
            top: y(370),
            width: x(sag - sol),
            height: y(494) - y(370),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(children: [
                Icon(ikon, color: Colors.white.withValues(alpha: 0.9), size: w * 0.042),
                SizedBox(width: x(10)),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(deger, style: TextStyle(color: Colors.white, fontSize: w * 0.044, fontWeight: FontWeight.w800, height: 1.1)),
                  ),
                ),
              ]),
              SizedBox(height: x(4)),
              Text(etiket,
                  maxLines: 2,
                  style: TextStyle(color: Colors.white, fontSize: w * 0.029, fontWeight: FontWeight.w600, height: 1.15)),
            ]),
          );
      return SizedBox(
        width: w,
        height: h,
        child: Stack(children: [
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.04, 0.96, 1],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: Image.asset('images/ikram_hero_tam.png', fit: BoxFit.fill),
            ),
          ),
          // Dönem seçici (görseldeki hapın içine)
          Positioned(
            left: x(405),
            top: y(155),
            width: x(572 - 405),
            height: y(198) - y(155),
            child: _donemSecici(w),
          ),
          // Toplam tutar
          Positioned(
            left: x(86),
            top: y(206),
            width: x(478 - 86),
            height: y(298) - y(206),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(ikramTl(toplam),
                    style: TextStyle(color: Colors.white, fontSize: w * 0.105, fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1)),
                SizedBox(width: w * 0.015),
                Text('TL', style: TextStyle(color: Colors.white, fontSize: w * 0.064, fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
          // Artış hapı
          Positioned(
            left: x(86),
            top: y(307),
            height: y(350) - y(307),
            child: artis == null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Önceki dönemle kıyas yok',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: w * 0.026)),
                  )
                : Container(
                    padding: EdgeInsets.symmetric(horizontal: x(18)),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: artis >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(artis >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: w * 0.03, color: artis >= 0 ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D)),
                      SizedBox(width: x(6)),
                      Text('%${artis.abs().toStringAsFixed(artis.abs() < 10 && artis % 1 != 0 ? 1 : 0)} ${artis >= 0 ? 'artış' : 'azalış'}',
                          style: TextStyle(
                              fontSize: w * 0.027,
                              fontWeight: FontWeight.w700,
                              color: artis >= 0 ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D))),
                    ]),
                  ),
          ),
          // Alt üç sütun
          rakam(104, 270, Icons.people_alt_rounded, '${(_ozet['kullanim'] as num?)?.toInt() ?? 0}', 'Kampanya\nKullanımı'),
          rakam(292, 446, Icons.savings_rounded, '${ikramTl(_ozet['ek_kazanc'] as num?)} TL', 'Ek\nKazanç'),
          rakam(466, 606, Icons.star_rounded, oran == null ? '—' : '%$oran', 'Kullanım\nOranı'),
        ]),
      );
    });
  }

  Widget _donemSecici(double w) {
    const secenekler = {7: 'Son 7 Gün', 30: 'Son 30 Gün', 90: 'Son 90 Gün', 365: 'Son 1 Yıl'};
    return PopupMenuButton<int>(
      padding: EdgeInsets.zero,
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
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(secenekler[_donem] ?? 'Son $_donem Gün',
                style: TextStyle(color: Colors.white, fontSize: w * 0.022, fontWeight: FontWeight.w500)),
          ),
        ),
        Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: w * 0.035),
      ]),
    );
  }

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
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF7C3AED), Color(0xFF5B21B6)]),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: _morKoyu.withValues(alpha: 0.32), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          alignment: Alignment.center,
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 12, backgroundColor: Colors.white, child: Icon(Icons.add_rounded, color: _morKoyu, size: 18)),
            SizedBox(width: 10),
            Text('Yeni Kampanya', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  /// Kampanya oluşturma kartı: başlık + tam genişlikte "Yeni Kampanya" düğmesi.
  Widget _turKarti() => _cam(
        child: Column(children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [Color(0xFFF3E8FF), Color(0xFFDDD0FB)]),
                boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: _morKoyu, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kampanya Oluştur', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _koyu)),
                SizedBox(height: 2),
                Text('Hizmeti belirlediğiniz adette alan müşteriye hediye hizmet verin.',
                    style: TextStyle(fontSize: 11.5, height: 1.3, color: _soluk)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          _yeniKampanyaDugme(),
        ]),
      );

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
    return GestureDetector(
      onTap: () => _detayAc(k),
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
                      Positioned.fill(child: _foto(k, hizmet)),
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
    ));
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

  Future<void> _detayAc(Map<String, dynamic> k) async {
    final degisti = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KampanyaDetaySayfasi(
          salonId: _salonId,
          kural: k,
          hizmetler: _hizmetler,
          tumKurallar: _kurallar,
          tumMusteriler: _musteriler,
          ilkDonem: _donem,
        ),
      ),
    );
    if (degisti == true && mounted) _yukle();
  }

  Future<void> _kuralDuzenle(Map<String, dynamic>? mevcut) async {
    final kaydedildi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KampanyaAyarlariSayfasi(
          salonId: _salonId,
          mevcut: mevcut,
          hizmetler: _hizmetler,
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
