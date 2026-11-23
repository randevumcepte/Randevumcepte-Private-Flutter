import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ikram_hizmet.dart' show ikramTl, ikramTarih;
import 'ikram_rapor.dart';
import 'kampanya_ayarlari.dart';

/// İkram Hizmet > Kampanya Detayı ("Güzellik Salonu Kampanya Detayı" tasarımı).
/// Veri: /carkAdmin/damga-karti-detay (performans, katılan müşteriler, kazanç detayı).
/// Değişiklik yapılırsa `true` ile kapanır (liste yenilensin).
class KampanyaDetaySayfasi extends StatefulWidget {
  final String salonId;
  final Map<String, dynamic> kural;
  final List<Map<String, dynamic>> hizmetler;
  final List<Map<String, dynamic>> tumKurallar;
  final List<Map<String, dynamic>> tumMusteriler;
  final int ilkDonem;

  const KampanyaDetaySayfasi({
    super.key,
    required this.salonId,
    required this.kural,
    required this.hizmetler,
    required this.tumKurallar,
    required this.tumMusteriler,
    this.ilkDonem = 30,
  });

  @override
  State<KampanyaDetaySayfasi> createState() => _KampanyaDetaySayfasiState();
}

class _KampanyaDetaySayfasiState extends State<KampanyaDetaySayfasi> {
  static const _koyu = Color(0xFF2E1065);
  static const _mor = Color(0xFF7C3AED);
  static const _morKoyu = Color(0xFF5B21B6);
  static const _soluk = Color(0xFF6B5A8E);

  late Map<String, dynamic> _kural;
  Map<String, dynamic> _perf = {};
  List<Map<String, dynamic>> _musteriler = [];
  Map<String, dynamic> _kazanc = {};
  bool _yukleniyor = true;
  bool _degisti = false;
  late int _donem;
  int _sekme = 0; // 0 müşteriler, 1 kazanç
  String _arama = '';
  String _filtre = 'tumu'; // tumu | hak_var | kullandi | katildi

  @override
  void initState() {
    super.initState();
    _kural = Map<String, dynamic>.from(widget.kural);
    _donem = widget.ilkDonem;
    _yukle();
  }

  List<Map<String, dynamic>> _liste(dynamic v) =>
      ((v as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<void> _yukle() async {
    final r = await ikramKampanyaDetay(widget.salonId, (_kural['id'] as num).toInt(), donem: _donem);
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (r != null && r['basarili'] == true) {
        if (r['kural'] is Map) _kural = {..._kural, ...Map<String, dynamic>.from(r['kural'] as Map)};
        _perf = r['performans'] is Map ? Map<String, dynamic>.from(r['performans'] as Map) : {};
        _musteriler = _liste(r['musteriler']);
        _kazanc = r['kazanc_detay'] is Map ? Map<String, dynamic>.from(r['kazanc_detay'] as Map) : {};
      }
    });
  }

  void _mesaj(String m, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: hata ? Colors.red : _morKoyu,
      behavior: SnackBarBehavior.floating,
    ));
  }

  int get _adet => (_kural['gereken_adet'] as num?)?.toInt() ?? 0;
  int get _hediye => (_kural['ucretsiz_adet'] as num?)?.toInt() ?? 1;
  String get _hizmet => (_kural['hizmet_adi'] ?? 'Hizmet').toString();

  /// aktif | pasif | bitti | baslayacak
  String get _durum {
    final s = DateTime.now();
    final bugun = DateTime(s.year, s.month, s.day);
    final bit = DateTime.tryParse((_kural['bitis_tarihi'] ?? '').toString());
    final bas = DateTime.tryParse((_kural['baslangic'] ?? '').toString());
    if (bit != null && bit.isBefore(bugun)) return 'bitti';
    if (((_kural['aktif'] as num?)?.toInt() ?? 0) != 1) return 'pasif';
    if (bas != null && DateTime(bas.year, bas.month, bas.day).isAfter(bugun)) return 'baslayacak';
    return 'aktif';
  }

  String _tarihSaat(String? t) {
    final d = DateTime.tryParse(t ?? '');
    if (d == null) return '';
    String iki(int x) => x.toString().padLeft(2, '0');
    final saat = (d.hour == 0 && d.minute == 0) ? '' : ' • ${iki(d.hour)}:${iki(d.minute)}';
    return '${iki(d.day)}.${iki(d.month)}.${d.year}$saat';
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final alt = MediaQuery.of(context).padding.bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _degisti);
      },
      child: Scaffold(
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
                  child: RefreshIndicator(
                    color: _mor,
                    onRefresh: _yukle,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 24 + alt),
                      children: [
                        _hero(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            const SizedBox(height: 12),
                            _bilgilerKarti(),
                            const SizedBox(height: 12),
                            _performansKarti(),
                            const SizedBox(height: 12),
                            _sekmeler(),
                            const SizedBox(height: 12),
                            _ozetKarti(),
                            const SizedBox(height: 16),
                            _raporDugmesi(),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- üst

  Widget _ustBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, _degisti),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.75),
                border: Border.all(color: Colors.white),
                boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _koyu, size: 24),
            ),
          ),
          const Expanded(
            child: Text('Kampanya Detayı',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: _koyu, letterSpacing: -0.3)),
          ),
          SizedBox(
            width: 46,
            child: Center(
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (v) {
                  if (v == 'duzenle') _duzenle();
                  if (v == 'durum') _aktifDegistir();
                  if (v == 'sil') _sil();
                },
                itemBuilder: (_) {
                  final aktif = ((_kural['aktif'] as num?)?.toInt() ?? 0) == 1;
                  return [
                    const PopupMenuItem(value: 'duzenle', child: Row(children: [Icon(Icons.edit_rounded, color: _mor, size: 20), SizedBox(width: 10), Text('Düzenle')])),
                    PopupMenuItem(
                      value: 'durum',
                      child: Row(children: [
                        Icon(aktif ? Icons.pause_circle_rounded : Icons.play_circle_rounded, color: _mor, size: 20),
                        const SizedBox(width: 10),
                        Text(aktif ? 'Kampanyayı Kapat' : 'Kampanyayı Aç'),
                      ]),
                    ),
                    const PopupMenuItem(value: 'sil', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), SizedBox(width: 10), Text('Sil')])),
                  ];
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.7),
                    border: Border.all(color: const Color(0xFFE4D7F7)),
                    boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.more_vert_rounded, color: _morKoyu, size: 20),
                ),
              ),
            ),
          ),
        ]),
      );

  /// Üst bölüm: tasarımdaki ölçüler ekran genişliğine oranlanır (tasarım 941 px genişlik).
  /// Sağda kampanya fotoğrafı (işletmenin yüklediği ya da hizmete uygun hazır görsel), solda
  /// sağ kenarı fotoğrafa yumuşakça geçen mor panel.
  Widget _hero() {
    final g = (_kural['gorsel'] ?? '').toString();
    final hazir = Image.asset(ikramHazirGorsel(_hizmet), fit: BoxFit.cover);
    final foto = g.isEmpty
        ? hazir
        : Image.network('https://app.randevumcepte.com.tr$g', fit: BoxFit.cover, errorBuilder: (_, __, ___) => hazir);
    final (chipYazi, chipRenk) = switch (_durum) {
      'aktif' => ('Aktif Kampanya', Colors.white),
      'baslayacak' => ('Yakında Başlıyor', const Color(0xFFBFDBFE)),
      'bitti' => ('Kampanya Bitti', const Color(0xFFE5E7EB)),
      _ => ('Pasif Kampanya', const Color(0xFFE5E7EB)),
    };
    return LayoutBuilder(builder: (c, k) {
      final w = k.maxWidth;
      double x(num px) => w * px / 941;
      final h = x(404);
      return SizedBox(
        width: w,
        height: h,
        child: Stack(children: [
          // Fotoğraf: sağ %55, sol ve alt kenarı zemine erir
          Positioned(
            left: x(400),
            right: 0,
            top: 0,
            bottom: 0,
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Colors.black],
                stops: [0, 0.22],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.black, Colors.transparent],
                  stops: [0, 0.86, 1],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: SizedBox.expand(child: foto),
              ),
            ),
          ),
          // Mor panel (sağ kenarı yarı saydam: fotoğraf hafifçe görünür)
          Positioned(
            left: x(28),
            top: x(6),
            width: x(490 - 28),
            height: x(394),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(x(56)),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF4C1D95),
                    const Color(0xFF5B21B6).withValues(alpha: 0.96),
                    const Color(0xFF6D28D9).withValues(alpha: 0.72),
                  ],
                  stops: const [0, 0.65, 1],
                ),
                boxShadow: [BoxShadow(color: _morKoyu.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(x(56)),
                child: Stack(children: [
                  // Üstte hafif ışık parıltısı
                  Positioned(
                    right: -x(60),
                    top: -x(120),
                    child: Container(
                      width: x(300),
                      height: x(300),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.18), Colors.transparent]),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(x(34), x(24), x(18), x(14)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        height: x(44),
                        padding: EdgeInsets.symmetric(horizontal: x(16)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(x(21)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.star_rounded, color: chipRenk, size: x(26)),
                          SizedBox(width: x(8)),
                          Text(chipYazi, style: TextStyle(color: chipRenk, fontSize: x(21), fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      SizedBox(
                        height: x(134),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('$_adet + $_hediye',
                              style: TextStyle(color: Colors.white, fontSize: x(170), fontWeight: FontWeight.w900, height: 1, letterSpacing: -3)),
                        ),
                      ),
                      SizedBox(
                        height: x(98),
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('$_hizmet\nKampanyası',
                              maxLines: 2,
                              style: TextStyle(color: Colors.white, fontSize: x(44), fontWeight: FontWeight.w800, height: 1.1)),
                        ),
                      ),
                      SizedBox(height: x(8)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('$_adet hizmet alan müşterilerimize\n$_hediye hizmet hediye!',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: x(25), height: 1.28)),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      );
    });
  }

  // ---------------------------------------------------------------- kartlar

  Widget _cam({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _kartBaslik(IconData ikon, String yazi, {Widget? sag}) => Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFF3E8FF), Color(0xFFDDD0FB)]),
            boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.16), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Icon(ikon, color: _morKoyu, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(yazi, maxLines: 1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _koyu)),
          ),
        ),
        if (sag != null) const SizedBox(width: 6),
        if (sag != null) sag,
      ]);

  BoxDecoration get _icKutu => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE4FA)),
      );

  Widget _dikCizgi() => Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 6), color: const Color(0xFFE6DAF8));

  Widget _bilgi(IconData ikon, String etiket, String deger, {double degerBoyut = 22}) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(children: [
            Icon(ikon, color: _mor, size: 22),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(etiket, maxLines: 1, style: const TextStyle(fontSize: 11.5, color: _morKoyu, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(deger, style: TextStyle(fontSize: degerBoyut, fontWeight: FontWeight.w800, color: _koyu)),
            ),
          ]),
        ),
      );

  Widget _bilgilerKarti() {
    final bas = ikramTarih(_kural['baslangic']?.toString());
    final bit = ikramTarih(_kural['bitis_tarihi']?.toString());
    final tarih = bas.isEmpty ? 'Açılınca başlar' : '$bas – ${bit.isEmpty ? 'Süresiz' : bit}';
    return _cam(
      child: Column(children: [
        _kartBaslik(Icons.card_giftcard_rounded, 'Kampanya Bilgileri'),
        const SizedBox(height: 10),
        Container(
          decoration: _icKutu,
          child: IntrinsicHeight(
            child: Row(children: [
              _bilgi(Icons.sell_outlined, 'Hizmet Adedi', '$_adet'),
              _dikCizgi(),
              _bilgi(Icons.card_giftcard_rounded, 'Hediye Hizmet', '$_hediye'),
              _dikCizgi(),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  child: Column(children: [
                    const Icon(Icons.calendar_month_rounded, color: _mor, size: 22),
                    const SizedBox(height: 4),
                    const Text('Geçerlilik Tarihi', style: TextStyle(fontSize: 11.5, color: _morKoyu, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(tarih, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _koyu)),
                    ),
                    if ((_kural['gecerlilik'] ?? '').toString().isNotEmpty)
                      Text('Hak ${_kural['gecerlilik']} geçerli', style: const TextStyle(fontSize: 10, color: _soluk)),
                  ]),
                ),
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
                child: Text(e.value, style: TextStyle(color: _koyu, fontWeight: e.key == _donem ? FontWeight.w800 : FontWeight.w500)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1E9FD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCCBF6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(secenekler[_donem] ?? 'Son $_donem Gün', style: const TextStyle(color: _koyu, fontSize: 12, fontWeight: FontWeight.w600)),
          const Icon(Icons.keyboard_arrow_down_rounded, color: _koyu, size: 18),
        ]),
      ),
    );
  }

  Widget _performansKarti() {
    final oran = (_perf['kullanim_orani'] as num?)?.toInt();
    return _cam(
      child: Column(children: [
        _kartBaslik(Icons.bar_chart_rounded, 'Kampanya Performansı', sag: _donemSecici()),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: _icKutu,
              child: IntrinsicHeight(
                child: Row(children: [
                  _bilgi(Icons.people_alt_rounded, 'Katılan Müşteri',
                      _yukleniyor ? '…' : '${(_perf['donem_katilan'] as num?)?.toInt() ?? 0}', degerBoyut: 24),
                  _dikCizgi(),
                  _bilgi(Icons.volunteer_activism_rounded, 'Elde Edilen Kazanç',
                      _yukleniyor ? '…' : '${ikramTl(_perf['donem_kazanc'] as num?)} TL', degerBoyut: 20),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CustomPaint(
                  painter: _HalkaBoyaci(oran == null ? 0 : oran / 100),
                  child: Center(
                    child: Text(oran == null ? '—' : '%$oran',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _koyu)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text('Kullanım Oranı', style: TextStyle(fontSize: 11.5, color: _morKoyu, fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
      ]),
    );
  }

  // ---------------------------------------------------------------- sekmeler

  Widget _sekmeDugme(int i, IconData ikon, String yazi) {
    final secili = _sekme == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sekme = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          decoration: BoxDecoration(
            gradient: secili ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]) : null,
            color: secili ? null : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            boxShadow: secili ? [BoxShadow(color: _morKoyu.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(ikon, color: secili ? Colors.white : _morKoyu, size: 20),
              const SizedBox(width: 8),
              Text(yazi, style: TextStyle(color: secili ? Colors.white : _koyu, fontSize: 13.5, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sekmeler() => _cam(
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          Row(children: [
            _sekmeDugme(0, Icons.people_alt_rounded, 'Katılan Müşteriler (${_musteriler.length})'),
            const SizedBox(width: 6),
            _sekmeDugme(1, Icons.bar_chart_rounded, 'Kazanç Detayları'),
          ]),
          const SizedBox(height: 10),
          if (_yukleniyor)
            const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _mor))
          else if (_sekme == 0)
            _musteriSekmesi()
          else
            _kazancSekmesi(),
        ]),
      );

  Widget _musteriSekmesi() {
    const filtreler = {'tumu': 'Tümünü Gör', 'hak_var': 'Hakkı Olanlar', 'kullandi': 'Kullananlar', 'katildi': 'Devam Edenler'};
    final q = _arama.trim().toLowerCase();
    final liste = _musteriler.where((m) {
      if (_filtre != 'tumu' && m['durum'] != _filtre) return false;
      return q.isEmpty ||
          (m['ad'] ?? '').toString().toLowerCase().contains(q) ||
          (m['telefon'] ?? '').toString().contains(q);
    }).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                onChanged: (v) => setState(() => _arama = v),
                decoration: InputDecoration(
                  hintText: 'Müşteri ara...',
                  hintStyle: const TextStyle(color: _soluk, fontSize: 13.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: _morKoyu),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE2D4F8))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _mor)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _filtre = v),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (_) => filtreler.entries
                .map((e) => PopupMenuItem<String>(value: e.key, child: Text(e.value, style: const TextStyle(color: _koyu))))
                .toList(),
            child: Container(
              height: 44,
              padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2D4F8)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(filtreler[_filtre]!, style: const TextStyle(color: _koyu, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const Icon(Icons.keyboard_arrow_down_rounded, color: _koyu, size: 20),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      if (liste.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          child: Text(
            _musteriler.isEmpty
                ? 'Henüz kampanyaya katılan müşteri yok.\nBu hizmeti alan ve "Geldi" işaretlenen müşteriler burada görünür.'
                : 'Bu filtrede müşteri yok.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: _soluk, height: 1.4),
          ),
        )
      else
        ...liste.map(_musteriSatir),
    ]);
  }

  Widget _avatar(Map<String, dynamic> m, double r) {
    final ad = (m['ad'] ?? '').toString().trim();
    final parcalar = ad.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final bas = parcalar.isEmpty ? '?' : parcalar.take(2).map((p) => p.characters.first.toUpperCase()).join();
    final yedek = CircleAvatar(
      radius: r,
      backgroundColor: const Color(0xFFEDE3FD),
      child: Text(bas, style: TextStyle(color: _morKoyu, fontWeight: FontWeight.w800, fontSize: r * 0.7)),
    );
    final resim = (m['resim'] ?? '').toString();
    if (resim.isEmpty) return yedek;
    final url = resim.startsWith('http') ? resim : 'https://app.randevumcepte.com.tr${resim.startsWith('/') ? '' : '/'}$resim';
    return ClipOval(
      child: Image.network(url, width: r * 2, height: r * 2, fit: BoxFit.cover, errorBuilder: (_, __, ___) => yedek),
    );
  }

  (String, Color, Color) _durumEtiket(String d) => switch (d) {
        'hak_var' => ('İkram Hakkı Var', const Color(0xFF5B21B6), const Color(0xFFEDE9FE)),
        'kullandi' => ('İkram Kullandı', const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
        _ => ('Kampanyaya Katıldı', const Color(0xFF15803D), const Color(0xFFDCFCE7)),
      };

  Widget _musteriSatir(Map<String, dynamic> m) {
    final (yazi, renk, zemin) = _durumEtiket((m['durum'] ?? '').toString());
    return GestureDetector(
      onTap: () => _musteriDetay(m),
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEFE6FB)),
        ),
        child: Row(children: [
          _avatar(m, 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((m['ad'] ?? '').toString(),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _koyu)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.calendar_month_rounded, size: 13, color: _soluk),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(_tarihSaat(m['son_ziyaret']?.toString()), style: const TextStyle(fontSize: 11.5, color: _soluk)),
                  ),
                ),
              ]),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(14)),
            child: Text(yazi, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: renk)),
          ),
          const Icon(Icons.chevron_right_rounded, color: _koyu),
        ]),
      ),
    );
  }

  void _musteriDetay(Map<String, dynamic> m) {
    int n(String a) => (m[a] as num?)?.toInt() ?? 0;
    final tel = (m['telefon'] ?? '').toString();
    final (yazi, renk, zemin) = _durumEtiket((m['durum'] ?? '').toString());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _avatar(m, 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((m['ad'] ?? '').toString(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _koyu)),
                  if (tel.isNotEmpty) Text(tel, style: const TextStyle(color: _soluk)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(14)),
                child: Text(yazi, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: renk)),
              ),
            ]),
            const SizedBox(height: 16),
            Text('İlerleme: ${n('ilerleme')} / $_adet', style: const TextStyle(fontWeight: FontWeight.w700, color: _koyu)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(math.min(_adet, 20), (i) {
                final dolu = i < n('ilerleme');
                return Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dolu ? _mor : const Color(0xFFF1E9FD),
                    border: Border.all(color: dolu ? _mor : const Color(0xFFDCCBF6)),
                  ),
                  child: dolu ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                );
              }),
            ),
            const SizedBox(height: 14),
            Row(children: [
              _mini('Ücretli alım', '${n('ucretli')}'),
              _mini('Kazanılan', '${n('kazanilan')}'),
              _mini('Kullanılan', '${n('kullanilan')}'),
              _mini('Bekleyen', '${n('hak')}'),
            ]),
            const SizedBox(height: 10),
            Text('İlk ziyaret: ${ikramTarih(m['ilk_ziyaret']?.toString())}   •   Son: ${_tarihSaat(m['son_ziyaret']?.toString())}',
                style: const TextStyle(fontSize: 12, color: _soluk)),
            if ((m['son_kullanma'] ?? '').toString().isNotEmpty)
              Text('En yakın son kullanma: ${ikramTarih(m['son_kullanma']?.toString())}',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900)),
            if (n('suresi_dolan') > 0)
              Text('${n('suresi_dolan')} ikramın süresi doldu', style: const TextStyle(fontSize: 12, color: Colors.red)),
            if (tel.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:$tel')),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Müşteriyi Ara'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _mini(String etiket, String deger) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFF6F0FF), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(deger, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _koyu)),
            Text(etiket, style: const TextStyle(fontSize: 10.5, color: _soluk)),
          ]),
        ),
      );

  Widget _kazancSekmesi() {
    final aylik = _liste(_kazanc['aylik']);
    final kullanimlar = _liste(_kazanc['kullanimlar']);
    final enBuyuk = aylik.fold<double>(0, (a, e) => math.max(a, (e['tutar'] as num?)?.toDouble() ?? 0));
    const aylar = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    Widget kutu(String etiket, String deger, Color renk) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text(deger, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: renk))),
              const SizedBox(height: 2),
              Text(etiket, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: _soluk)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          kutu('Toplam Satış\n(kampanya boyunca)', '${ikramTl(_perf['kazanc'] as num?)} TL', _koyu),
          kutu('Verilen İkram\n(${(_perf['kullanilan'] as num?)?.toInt() ?? 0} adet)', '${ikramTl(_kazanc['ikram_tutari'] as num?)} TL', const Color(0xFFB45309)),
          kutu('Net Kazanç\n ', '${ikramTl(_kazanc['net'] as num?)} TL', const Color(0xFF15803D)),
        ]),
        const SizedBox(height: 14),
        const Text('Aylık Satış', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _koyu)),
        const SizedBox(height: 8),
        if (aylik.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Kampanya süresince bu hizmetten satış yok.', style: TextStyle(fontSize: 12.5, color: _soluk)),
          )
        else
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: aylik.map((a) {
                final t = (a['tutar'] as num?)?.toDouble() ?? 0;
                final ay = int.tryParse(a['ay'].toString().split('-').last) ?? 1;
                return Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(ikramTl(t), style: const TextStyle(fontSize: 9.5, color: _soluk, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: enBuyuk > 0 ? math.max(4, 100 * t / enBuyuk) : 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFA855F7), Color(0xFF5B21B6)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(aylar[(ay - 1).clamp(0, 11)], style: const TextStyle(fontSize: 10.5, color: _koyu)),
                  ]),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 14),
        const Text('Kullanılan İkramlar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _koyu)),
        const SizedBox(height: 6),
        if (kullanimlar.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Henüz ikram kullanılmadı.', style: TextStyle(fontSize: 12.5, color: _soluk)),
          )
        else
          ...kullanimlar.map((u) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.card_giftcard_rounded, color: _mor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text((u['ad'] ?? '').toString(),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: _koyu)),
                  ),
                  Text(_tarihSaat(u['tarih']?.toString()), style: const TextStyle(fontSize: 11, color: _soluk)),
                  const SizedBox(width: 8),
                  Text('${ikramTl(u['tutar'] as num?)} TL', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                ]),
              )),
        const SizedBox(height: 4),
      ]),
    );
  }

  // ---------------------------------------------------------------- alt

  Widget _ozetKarti() {
    final katilan = (_perf['katilan'] as num?)?.toInt() ?? 0;
    final kazanc = ikramTl(_perf['kazanc'] as num?);
    return _cam(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(children: [
        const Icon(Icons.campaign_rounded, color: _morKoyu, size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Kampanya Özeti', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _koyu)),
            const SizedBox(height: 3),
            Text.rich(
              TextSpan(style: const TextStyle(fontSize: 12, color: _morKoyu, height: 1.35), children: [
                const TextSpan(text: 'Bu kampanya sayesinde toplam '),
                TextSpan(text: '$katilan', style: const TextStyle(fontWeight: FontWeight.w800, color: _koyu)),
                const TextSpan(text: ' müşteri kampanyadan yararlandı ve '),
                TextSpan(text: '$kazanc TL', style: const TextStyle(fontWeight: FontWeight.w800, color: _koyu)),
                const TextSpan(text: ' kazanç sağlandı.'),
              ]),
            ),
          ]),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.insights_rounded, color: _mor, size: 38),
      ]),
    );
  }

  Widget _raporDugmesi() => Center(
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IkramRaporSayfasi(
                salonId: widget.salonId,
                ilkDonem: _donem,
                kurallar: widget.tumKurallar,
                musteriler: widget.tumMusteriler,
              ),
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6), Color(0xFF4C1D95)]),
              boxShadow: [BoxShadow(color: _morKoyu.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: const Row(children: [
              Spacer(),
              Icon(Icons.bar_chart_rounded, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text('Raporu Görüntüle', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              Spacer(),
              Icon(Icons.chevron_right_rounded, color: Colors.white),
            ]),
          ),
        ),
      );

  // ---------------------------------------------------------------- işlemler

  Future<void> _duzenle() async {
    final kaydedildi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KampanyaAyarlariSayfasi(salonId: widget.salonId, mevcut: _kural, hizmetler: widget.hizmetler),
      ),
    );
    if (kaydedildi == true && mounted) {
      _degisti = true;
      _mesaj('Kampanya kaydedildi');
      _yukle();
    }
  }

  Future<void> _aktifDegistir() async {
    final aktif = ((_kural['aktif'] as num?)?.toInt() ?? 0) == 1;
    final bas = DateTime.tryParse((_kural['baslangic'] ?? '').toString());
    String ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final r = await carkAdminDamgaKartiKaydet(widget.salonId, {
      'id': _kural['id'],
      'hizmet_id': _kural['hizmet_id'],
      'gereken_adet': _kural['gereken_adet'],
      'ucretsiz_adet': _kural['ucretsiz_adet'],
      'aktif': aktif ? 0 : 1,
      'gecerlilik_deger': _kural['gecerlilik_deger'] ?? 0,
      'gecerlilik_birim': _kural['gecerlilik_birim'] ?? 'ay',
      'baslangic_tarihi': bas != null ? ymd(bas) : '',
      'bitis_tarihi': _kural['bitis_tarihi'] ?? '',
    });
    if (!mounted) return;
    if (r != null && r['basarili'] == true) {
      _degisti = true;
      setState(() => _kural['aktif'] = aktif ? 0 : 1);
      _mesaj(aktif ? 'Kampanya kapatıldı' : 'Kampanya açıldı');
      _yukle();
    } else {
      _mesaj(r?['mesaj']?.toString() ?? 'Değiştirilemedi', hata: true);
    }
  }

  Future<void> _sil() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kampanyayı Sil'),
        content: Text('"$_hizmet" kampanyası silinsin mi?'),
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
    final r = await carkAdminDamgaKartiSil(widget.salonId, (_kural['id'] as num).toInt());
    if (!mounted) return;
    if (r != null && r['basarili'] == true) {
      _mesaj('Kampanya silindi');
      Navigator.pop(context, true);
    } else {
      _mesaj(r?['mesaj']?.toString() ?? 'Silinemedi', hata: true);
    }
  }
}

/// Kullanım oranı halkası (mor, yuvarlak uçlu)
class _HalkaBoyaci extends CustomPainter {
  final double oran;
  _HalkaBoyaci(this.oran);

  @override
  void paint(Canvas canvas, Size size) {
    final merkez = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;
    final zemin = Paint()
      ..color = const Color(0xFFEDE3FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(merkez, r, zemin);
    if (oran <= 0) return;
    final yay = Paint()
      ..shader = const SweepGradient(colors: [Color(0xFFA855F7), Color(0xFF5B21B6)]).createShader(Rect.fromCircle(center: merkez, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    canvas.drawArc(Rect.fromCircle(center: merkez, radius: r), -math.pi / 2, 2 * math.pi * oran.clamp(0, 1), false, yay);
  }

  @override
  bool shouldRepaint(covariant _HalkaBoyaci eski) => eski.oran != oran;
}
