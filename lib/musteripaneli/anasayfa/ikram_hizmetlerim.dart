import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ikram/kampanya_ayarlari.dart' show ikramHazirGorsel;

/// Müşteri: Kampanyalarım (ikram hizmet / "N alana M ikram").
/// Tasarım "Mor Işıltıda Güzellik Kampanyaları" (941 px genişlik) ölçüleri ekran
/// genişliğine oranlanır. Salonun toplam katılımcı/kazanç bilgisi ve diğer
/// müşteriler gösterilmez (KVKK); o bölümlerde müşterinin kendi ikramları yer alır.
/// Veri: /api/v1/musteri/ikram-hizmetleri (tahsilat ekranıyla aynı sayım).
class IkramHizmetlerimPage extends StatefulWidget {
  final MusteriDanisan md;
  final String? salonId;
  /// Açılışta seçili gelecek kampanya (yoksa ilk kampanya)
  final int? kuralId;
  const IkramHizmetlerimPage({Key? key, required this.md, this.salonId, this.kuralId}) : super(key: key);

  @override
  State<IkramHizmetlerimPage> createState() => _IkramHizmetlerimPageState();
}

class _IkramHizmetlerimPageState extends State<IkramHizmetlerimPage> {
  static const _mor = Color(0xFF6D28D9);
  static const _morKoyu = Color(0xFF4C1D95);
  static const _baslik = Color(0xFF2E0A7A);
  static const _koyu = Color(0xFF1E1250);
  static const _soluk = Color(0xFF6B5B95);

  bool _yukleniyor = true;
  List<Map<String, dynamic>> _kartlar = [];
  int _secili = 0;
  bool _detayAcik = true;
  bool _ilkYukleme = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final sid = widget.salonId ?? '';
    final r = sid.isEmpty ? null : await musteriIkramHizmetleri(sid, widget.md.id.toString());
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (r != null && r['basarili'] == true) {
        _kartlar = ((r['kartlar'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (_ilkYukleme && widget.kuralId != null) {
          _secili = _kartlar.indexWhere((k) => _n(k, 'kural_id') == widget.kuralId);
        }
        _ilkYukleme = false;
        if (_secili < 0 || _secili >= _kartlar.length) _secili = 0;
      }
    });
  }

  double _x(num px) => MediaQuery.of(context).size.width * px / 941;

  String _tarih(dynamic t) {
    final d = DateTime.tryParse((t ?? '').toString());
    if (d == null) return '';
    String iki(int x) => x.toString().padLeft(2, '0');
    return '${iki(d.day)}.${iki(d.month)}.${d.year}';
  }

  int _n(Map<String, dynamic> k, String a) => int.tryParse((k[a] ?? 0).toString()) ?? 0;

  DateTime get _bugun {
    final s = DateTime.now();
    return DateTime(s.year, s.month, s.day);
  }

  /// Kampanya hâlâ ikram kazandırıyor mu (aktif ve bitiş tarihi geçmemiş)
  bool _kampanyaAcik(Map<String, dynamic> k) {
    if (_n(k, 'aktif') != 1) return false;
    final bit = DateTime.tryParse((k['kampanya_bitis'] ?? '').toString());
    return bit == null || !bit.isBefore(_bugun);
  }

  @override
  Widget build(BuildContext context) {
    final k = _kartlar.isEmpty ? null : _kartlar[_secili];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2E5FD),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4EAFE), Color(0xFFF2E5FD), Color(0xFFEEDFFC)],
            ),
          ),
          child: _yukleniyor
              ? Stack(children: [
                  _ust(null),
                  const Center(child: CircularProgressIndicator(color: _mor)),
                ])
              : RefreshIndicator(
                  color: _mor,
                  onRefresh: _yukle,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + _x(50)),
                    children: k == null
                        ? [
                            _ust(null),
                            Padding(
                              padding: EdgeInsets.all(_x(60)),
                              child: Text('Bu salonda şu an ikram kampanyası yok.',
                                  textAlign: TextAlign.center, style: TextStyle(fontSize: _x(26), color: _soluk)),
                            ),
                          ]
                        : [
                            _ust(k),
                            if (_kartlar.length > 1) _kampanyaSecici(),
                            SizedBox(height: _x(22)),
                            _gecerlilikKarti(k),
                            SizedBox(height: _x(25)),
                            _ilerlemeKarti(k),
                            SizedBox(height: _x(25)),
                            _detayKarti(k),
                            SizedBox(height: _x(36)),
                            _gecmisBolumu(k),
                            SizedBox(height: _x(28)),
                            _bant(),
                          ],
                  ),
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- üst bölüm

  Widget _yuvarlakDugme(IconData ikon, VoidCallback onTap, {double boyut = 40}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: _x(78),
          height: _x(78),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.78),
            boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.14), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Icon(ikon, color: _baslik, size: _x(boyut)),
        ),
      );

  /// Başlık + kampanya kartı. Fotoğraf sağ üstten başlar (başlığın arkasına uzanır),
  /// mor panel sağa doğru fotoğrafa erir.
  Widget _ust(Map<String, dynamic>? k) {
    final ust = MediaQuery.of(context).padding.top;
    final baslik = Positioned(
      left: _x(47),
      right: _x(48),
      top: ust + _x(30),
      child: Row(children: [
        _yuvarlakDugme(Icons.arrow_back_rounded, () => Navigator.of(context).maybePop()),
        Expanded(
          child: Center(
            child: Text('Kampanyalarım',
                style: TextStyle(fontSize: _x(46), fontWeight: FontWeight.w800, color: _baslik, letterSpacing: -0.3)),
          ),
        ),
        _yuvarlakDugme(Icons.info_outline_rounded, _bilgiAc, boyut: 38),
      ]),
    );
    if (k == null) return SizedBox(height: ust + _x(140), child: Stack(children: [baslik]));

    final hizmet = (k['hizmet_adi'] ?? '').toString();
    final g = (k['gorsel'] ?? '').toString();
    final hazir = Image.asset(ikramHazirGorsel(hizmet), fit: BoxFit.cover);
    final foto = g.isEmpty
        ? hazir
        : Image.network('https://app.randevumcepte.com.tr$g', fit: BoxFit.cover, errorBuilder: (_, __, ___) => hazir);
    final gereken = _n(k, 'gereken_adet');
    final hediye = _n(k, 'ucretsiz_adet');
    final acik = _kampanyaAcik(k);

    return SizedBox(
      height: ust + _x(478),
      child: Stack(children: [
        // Fotoğraf: sağda, üstten panelin altına kadar; sol ve alt kenarı zemine erir
        Positioned(
          left: _x(420),
          right: 0,
          top: 0,
          height: ust + _x(476),
          child: ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.transparent, Colors.black],
              stops: [0, 0.3],
            ).createShader(r),
            blendMode: BlendMode.dstIn,
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.9, 1],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: SizedBox.expand(child: foto),
            ),
          ),
        ),
        // Mor panel
        Positioned(
          left: _x(40),
          top: ust + _x(125),
          width: _x(600),
          height: _x(350),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(_x(48))),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF4B0F98),
                  const Color(0xFF5B1AA6).withValues(alpha: 0.98),
                  const Color(0xFF7C3AED).withValues(alpha: 0.6),
                  const Color(0xFFA78BFA).withValues(alpha: 0.2),
                  const Color(0xFFC4B5FD).withValues(alpha: 0),
                ],
                stops: const [0, 0.55, 0.72, 0.87, 1],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(_x(48))),
              child: Padding(
                padding: EdgeInsets.fromLTRB(_x(38), _x(16), _x(150), _x(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    height: _x(52),
                    padding: EdgeInsets.symmetric(horizontal: _x(22)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(_x(26)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.redeem_rounded, color: Colors.white, size: _x(30)),
                      SizedBox(width: _x(12)),
                      Text(acik ? 'Aktif Kampanya' : 'Kampanya Sona Erdi',
                          style: TextStyle(color: Colors.white, fontSize: _x(22), fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  SizedBox(height: _x(8)),
                  SizedBox(
                    height: _x(120),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Color(0xFFF3E8FF), Color(0xFFD8B4FE)],
                        ).createShader(r),
                        child: Text('$gereken+$hediye',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _x(150),
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -2,
                              shadows: [Shadow(color: const Color(0xFFE9D5FF).withValues(alpha: 0.7), blurRadius: 24)],
                            )),
                      ),
                    ),
                  ),
                  SizedBox(height: _x(8)),
                  SizedBox(
                    height: _x(82),
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('$hizmet\nKampanyası',
                          maxLines: 2,
                          style: TextStyle(color: Colors.white, fontSize: _x(34), fontWeight: FontWeight.w600, height: 1.15)),
                    ),
                  ),
                  SizedBox(height: _x(14)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('$gereken hizmet al, $hediye hizmet hediye!',
                        style: TextStyle(color: Colors.white, fontSize: _x(22), fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
            ),
          ),
        ),
        baslik,
      ]),
    );
  }

  Widget _kampanyaSecici() => Padding(
        padding: EdgeInsets.only(top: _x(18)),
        child: SizedBox(
          height: _x(56),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: _x(40)),
            itemCount: _kartlar.length,
            separatorBuilder: (_, __) => SizedBox(width: _x(12)),
            itemBuilder: (_, i) {
              final secili = i == _secili;
              final k = _kartlar[i];
              return GestureDetector(
                onTap: () => setState(() => _secili = i),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: _x(24)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: secili ? const LinearGradient(colors: [Color(0xFF8B3FE6), Color(0xFF6D28D9)]) : null,
                    color: secili ? null : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(_x(28)),
                    border: secili ? null : Border.all(color: const Color(0xFFE2D4F8)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text((k['hizmet_adi'] ?? '').toString(),
                        style: TextStyle(
                            fontSize: _x(22), fontWeight: FontWeight.w600, color: secili ? Colors.white : _baslik)),
                    if (_n(k, 'hak') > 0) ...[
                      SizedBox(width: _x(8)),
                      Icon(Icons.redeem_rounded, size: _x(24), color: secili ? Colors.white : _mor),
                    ],
                  ]),
                ),
              );
            },
          ),
        ),
      );

  // ---------------------------------------------------------------- kartlar

  Widget _kart({required Widget child, EdgeInsets? padding}) => Padding(
        padding: EdgeInsets.symmetric(horizontal: _x(40)),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(_x(42)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
            boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.08), blurRadius: 22, offset: const Offset(0, 8))],
          ),
          child: child,
        ),
      );

  Widget _gecerlilikKarti(Map<String, dynamic> k) {
    final bas = _tarih(k['kampanya_baslangic']);
    final bitD = DateTime.tryParse((k['kampanya_bitis'] ?? '').toString());
    final bit = _tarih(k['kampanya_bitis']);
    final tarih = bas.isEmpty ? (bit.isEmpty ? 'Süresiz' : '$bit tarihine kadar') : '$bas – ${bit.isEmpty ? 'Süresiz' : bit}';
    final String kalan;
    if (bitD == null) {
      kalan = 'Süresiz';
    } else {
      final g = DateTime(bitD.year, bitD.month, bitD.day).difference(_bugun).inDays;
      kalan = g < 0 ? 'Bitti' : (g == 0 ? 'Son Gün' : '$g Gün');
    }
    return _kart(
      child: SizedBox(
        height: _x(110),
        child: Row(children: [
          SizedBox(width: _x(40)),
          Icon(Icons.calendar_month_rounded, color: _mor, size: _x(58)),
          SizedBox(width: _x(30)),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Kampanya Geçerlilik Tarihi',
                    style: TextStyle(fontSize: _x(23), fontWeight: FontWeight.w600, color: const Color(0xFF5B21B6))),
              ),
              SizedBox(height: _x(4)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(tarih, style: TextStyle(fontSize: _x(28), fontWeight: FontWeight.w700, color: _koyu)),
              ),
            ]),
          ),
          Container(width: 1, height: _x(58), color: const Color(0xFFDCCBF6)),
          SizedBox(width: _x(62)),
          Container(
            width: _x(214),
            height: _x(80),
            padding: EdgeInsets.symmetric(horizontal: _x(18)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF9A47EA), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(_x(34)),
              boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5))],
            ),
            child: Row(children: [
              Icon(Icons.access_time_rounded, color: Colors.white, size: _x(44)),
              SizedBox(width: _x(14)),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Kalan Süre', style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: _x(21))),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(kalan, style: TextStyle(color: Colors.white, fontSize: _x(30), fontWeight: FontWeight.w700, height: 1.1)),
                  ),
                ]),
              ),
            ]),
          ),
          SizedBox(width: _x(36)),
        ]),
      ),
    );
  }

  Widget _ilerlemeKarti(Map<String, dynamic> k) {
    final gereken = math.max(1, _n(k, 'gereken_adet'));
    final hediye = _n(k, 'ucretsiz_adet');
    final hak = _n(k, 'hak');
    // Hak kullanılana kadar kart dolu (5/5) görünür; sonraki alımlar "Yeni kartınız" olarak ayrı yazılır
    final yeniKart = _n(k, 'ilerleme');
    final ilerleme = hak > 0 ? gereken : yeniKart.clamp(0, gereken);
    final acik = _kampanyaAcik(k);

    Widget nokta(bool dolu) => Container(
          width: _x(42),
          height: _x(42),
          margin: EdgeInsets.only(right: _x(28)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: dolu ? const LinearGradient(colors: [Color(0xFF8B3FE6), Color(0xFF5B21B6)]) : null,
            color: dolu ? null : Colors.white.withValues(alpha: 0.45),
            border: dolu ? null : Border.all(color: const Color(0xFFD9C6F7), width: 1.5),
          ),
          child: dolu ? Icon(Icons.check_rounded, color: Colors.white, size: _x(26)) : null,
        );

    return _kart(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_x(42)),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _x(198)),
          child: Stack(children: [
            Positioned(
              right: -_x(10),
              top: _x(6),
              width: _x(258),
              height: _x(192),
              child: Image.asset('images/ikram_m_hediye.png', fit: BoxFit.contain),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(_x(43), _x(10), _x(250), _x(10)),
              child: Row(children: [
                SizedBox(
                  width: _x(178),
                  height: _x(178),
                  child: CustomPaint(
                    painter: _Halka(ilerleme / gereken, _x(16)),
                    child: Center(
                      child: Text('$ilerleme/$gereken',
                          style: TextStyle(fontSize: _x(54), fontWeight: FontWeight.w800, color: const Color(0xFF7A1530))),
                    ),
                  ),
                ),
                SizedBox(width: _x(47)),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Kampanya İlerlemeniz',
                          style: TextStyle(fontSize: _x(29), fontWeight: FontWeight.w700, color: _baslik)),
                    ),
                    SizedBox(height: _x(6)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(acik ? '$gereken hizmet al, $hediye hizmet kazan!' : 'Bu kampanya sona erdi',
                          style: TextStyle(fontSize: _x(22), fontWeight: FontWeight.w500, color: const Color(0xFF5B21B6))),
                    ),
                    SizedBox(height: _x(26)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(children: [for (var i = 0; i < gereken; i++) nokta(i < ilerleme)]),
                    ),
                    if (hak > 0) ...[
                      SizedBox(height: _x(18)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: _x(18), vertical: _x(8)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(_x(24)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.redeem_rounded, color: const Color(0xFF15803D), size: _x(26)),
                          SizedBox(width: _x(8)),
                          Text('$hak ücretsiz hakkınız var',
                              style: TextStyle(fontSize: _x(21), fontWeight: FontWeight.w700, color: const Color(0xFF15803D))),
                        ]),
                      ),
                      if (acik && yeniKart > 0) ...[
                        SizedBox(height: _x(8)),
                        Text('Yeni kartınız: $yeniKart/$gereken',
                            style: TextStyle(fontSize: _x(20), fontWeight: FontWeight.w500, color: const Color(0xFF5B21B6))),
                      ],
                    ],
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  /// Kampanya Detayları: müşterinin kendi ikram sayıları (salonun toplamları gösterilmez)
  Widget _detayKarti(Map<String, dynamic> k) {
    final gereken = math.max(1, _n(k, 'gereken_adet'));
    final ilerleme = _n(k, 'ilerleme');
    final hak = _n(k, 'hak');
    final gecerliler = ((k['gecerli_ikramlar'] as List?) ?? const []).map((e) => e.toString()).toList();
    final dolan = _n(k, 'suresi_dolan');
    final gecerlilik = (k['gecerlilik'] ?? '').toString();

    Widget sutun(IconData ikon, String etiket, String deger, {Color renk = const Color(0xFF1A0B5C)}) => Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: _x(22)),
            child: Column(children: [
              Icon(ikon, color: _mor, size: _x(40)),
              SizedBox(height: _x(8)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(etiket, style: TextStyle(fontSize: _x(23), color: const Color(0xFF4C1D95), fontWeight: FontWeight.w500)),
              ),
              SizedBox(height: _x(4)),
              Text(deger, style: TextStyle(fontSize: _x(38), fontWeight: FontWeight.w800, color: renk, height: 1.1)),
            ]),
          ),
        );
    Widget cizgi() => Container(width: 1, height: _x(110), color: const Color(0xFFDCCBF6));
    Widget not(IconData ikon, String yazi, Color renk) => Padding(
          padding: EdgeInsets.only(top: _x(10)),
          child: Row(children: [
            Icon(ikon, size: _x(26), color: renk),
            SizedBox(width: _x(10)),
            Expanded(child: Text(yazi, style: TextStyle(fontSize: _x(21), color: renk, fontWeight: FontWeight.w500))),
          ]),
        );

    return _kart(
      child: Column(children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _detayAcik = !_detayAcik),
          child: SizedBox(
            height: _x(76),
            child: Row(children: [
              SizedBox(width: _x(42)),
              Icon(Icons.bar_chart_rounded, color: _mor, size: _x(50)),
              SizedBox(width: _x(18)),
              Expanded(
                child: Text('Kampanya Detayları',
                    style: TextStyle(fontSize: _x(29), fontWeight: FontWeight.w700, color: _baslik)),
              ),
              AnimatedRotation(
                turns: _detayAcik ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_up_rounded, color: _baslik, size: _x(44)),
              ),
              SizedBox(width: _x(30)),
            ]),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _detayAcik ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          secondChild: SizedBox(width: double.infinity, height: _x(8)),
          firstChild: Column(children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(_x(40)),
                border: Border.all(color: Colors.white),
              ),
              child: Row(children: [
                sutun(Icons.redeem_rounded, 'Kazanılan İkram', '${_n(k, 'kazanilan')}'),
                cizgi(),
                sutun(Icons.task_alt_rounded, 'Kullanılan İkram', '${_n(k, 'kullanilan')}'),
                cizgi(),
                sutun(Icons.star_border_rounded, 'Kalan İkram', '$hak', renk: _mor),
              ]),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(_x(42), _x(6), _x(36), _x(22)),
              child: Column(children: [
                if (_kampanyaAcik(k))
                  not(
                      Icons.trending_up_rounded,
                      hak > 0
                          ? 'Kartınız doldu: $hak ücretsiz hakkınızı kullanabilirsiniz.'
                          : 'Ücretsiz hakkınıza ${gereken - ilerleme} ücretli alım kaldı.',
                      _morKoyu),
                ...gecerliler.map((t) => not(Icons.hourglass_bottom_rounded, '1 ikram · ${_tarih(t)} tarihine kadar kullanılabilir',
                    const Color(0xFF92400E))),
                if (gecerliler.isEmpty && gecerlilik.isNotEmpty)
                  not(Icons.hourglass_bottom_rounded, 'Kazandığınız ikram $gecerlilik geçerlidir.', _soluk),
                if (dolan > 0) not(Icons.timer_off_rounded, '$dolan ikramın kullanım süresi doldu.', const Color(0xFFDC2626)),
                not(Icons.info_outline_rounded, 'Paket seanslarınız bu kampanyaya sayılmaz.', _soluk),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  // ---------------------------------------------------------------- ikram geçmişi

  (String, String, IconData, Color) _ikramDurum(Map<String, dynamic> ik) {
    final durum = (ik['durum'] ?? '').toString();
    final bitis = (ik['bitis'] ?? '').toString();
    if (durum == 'kullanildi') {
      return ('Kullanıldı', _tarih(ik['kullanim_tarihi']), Icons.check_rounded, const Color(0xFF059669));
    }
    if (durum == 'gecerli') {
      return ('Kullanılabilir', bitis.isNotEmpty ? 'Son: ${_tarih(bitis)}' : 'Süresiz', Icons.redeem_rounded, _mor);
    }
    return ('Süresi Doldu', _tarih(bitis), Icons.close_rounded, const Color(0xFFDC2626));
  }

  Widget _gecmisBolumu(Map<String, dynamic> k) {
    final ikramlar = ((k['ikramlar'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final gereken = math.max(1, _n(k, 'gereken_adet'));
    final kalan = gereken - _n(k, 'ilerleme');

    Widget kartcik(Map<String, dynamic> ik) {
      final (baslik, tarih, ikon, renk) = _ikramDurum(ik);
      return Container(
        width: _x(197),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(_x(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
          boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: _x(100),
            height: _x(92),
            child: Stack(children: [
              Container(
                width: _x(90),
                height: _x(90),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF3E8FF), Color(0xFFD9C2FA)],
                  ),
                ),
                child: Icon(Icons.card_giftcard_rounded, color: _mor, size: _x(44)),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: _x(36),
                  height: _x(36),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: renk,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(ikon, color: Colors.white, size: _x(22)),
                ),
              ),
            ]),
          ),
          SizedBox(height: _x(14)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(baslik, style: TextStyle(fontSize: _x(22), fontWeight: FontWeight.w700, color: _koyu)),
          ),
          SizedBox(height: _x(4)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(tarih, style: TextStyle(fontSize: _x(21), color: _soluk)),
          ),
        ]),
      );
    }

    return Column(children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: _x(40)),
        child: Row(children: [
          SizedBox(width: _x(20)),
          Icon(Icons.history_rounded, color: _mor, size: _x(48)),
          SizedBox(width: _x(18)),
          Expanded(
            child: Text('İkram Geçmişim', style: TextStyle(fontSize: _x(29), fontWeight: FontWeight.w700, color: _baslik)),
          ),
          if (ikramlar.isNotEmpty)
            GestureDetector(
              onTap: () => _gecmisAc(k, ikramlar),
              child: Container(
                height: _x(57),
                padding: EdgeInsets.only(left: _x(26), right: _x(14)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(_x(29)),
                  boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Tümünü Gör', style: TextStyle(fontSize: _x(22), fontWeight: FontWeight.w700, color: _morKoyu)),
                  SizedBox(width: _x(8)),
                  Icon(Icons.chevron_right_rounded, color: _morKoyu, size: _x(36)),
                ]),
              ),
            ),
        ]),
      ),
      SizedBox(height: _x(14)),
      if (ikramlar.isEmpty)
        _kart(
          padding: EdgeInsets.symmetric(horizontal: _x(36), vertical: _x(30)),
          child: Row(children: [
            Icon(Icons.card_giftcard_rounded, color: _mor, size: _x(48)),
            SizedBox(width: _x(22)),
            Expanded(
              child: Text(
                _kampanyaAcik(k)
                    ? 'Henüz ikram kazanmadınız. İlk ikramınıza $kalan ücretli alım kaldı.'
                    : 'Bu kampanyadan ikram kazanmadınız.',
                style: TextStyle(fontSize: _x(23), color: _morKoyu, height: 1.35),
              ),
            ),
          ]),
        )
      else
        SizedBox(
          height: _x(190),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: _x(46), vertical: _x(2)),
            itemCount: ikramlar.length,
            separatorBuilder: (_, __) => SizedBox(width: _x(10)),
            itemBuilder: (_, i) => kartcik(ikramlar[i]),
          ),
        ),
    ]);
  }

  void _gecmisAc(Map<String, dynamic> k, List<Map<String, dynamic>> ikramlar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.75),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              Text('${k['hizmet_adi'] ?? ''} · İkram Geçmişim',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _baslik)),
              const SizedBox(height: 10),
              ...ikramlar.map((ik) {
                final (baslik, _, ikon, renk) = _ikramDurum(ik);
                final bitis = (ik['bitis'] ?? '').toString();
                final tutar = double.tryParse((ik['tutar'] ?? 0).toString()) ?? 0;
                final aciklama = switch ((ik['durum'] ?? '').toString()) {
                  'kullanildi' => '${_tarih(ik['kullanim_tarihi'])} tarihinde kullanıldı'
                      '${tutar > 0 ? ' · ${tutar.toStringAsFixed(tutar == tutar.roundToDouble() ? 0 : 2)} ₺ kazanç' : ''}',
                  'gecerli' => bitis.isNotEmpty ? '${_tarih(bitis)} tarihine kadar kullanılabilir' : 'Süresiz, dilediğiniz zaman kullanılabilir',
                  _ => '${_tarih(bitis)} tarihinde süresi doldu',
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(children: [
                    CircleAvatar(radius: 16, backgroundColor: renk.withValues(alpha: 0.12), child: Icon(ikon, size: 18, color: renk)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${_tarih(ik['kazanma'])} tarihinde kazanıldı',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
                        Text(aciklama, style: const TextStyle(fontSize: 13, color: _koyu)),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: renk.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(baslik, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: renk)),
                    ),
                  ]),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bant() => Padding(
        padding: EdgeInsets.symmetric(horizontal: _x(40)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_x(50)),
          child: Image.asset('images/ikram_m_bant.png', width: _x(863), height: _x(100), fit: BoxFit.fill),
        ),
      );

  void _bilgiAc() {
    Widget satir(IconData ikon, String yazi) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 17, backgroundColor: _mor.withValues(alpha: 0.1), child: Icon(ikon, size: 18, color: _mor)),
            const SizedBox(width: 12),
            Expanded(child: Text(yazi, style: const TextStyle(fontSize: 13.5, color: Color(0xFF374151), height: 1.4))),
          ]),
        );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('İkram kampanyası nasıl işler?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _baslik)),
            const SizedBox(height: 8),
            satir(Icons.event_available_rounded, 'Yalnızca kampanyadaki hizmeti ücretli aldığınızda sayılır; paket seansları ve diğer hizmetler sayılmaz.'),
            satir(Icons.card_giftcard_rounded,
                'Kazandığınız ikramı dilediğiniz bir seansınızda kullanırsınız; ödeme sırasında salona söylemeniz yeterli.'),
            satir(Icons.savings_rounded,
                'İstemezseniz ikramınız saklı kalır; kullanım süresi varsa o tarihe kadar dilediğiniz seansta kullanabilirsiniz.'),
          ]),
        ),
      ),
    );
  }
}

/// İlerleme halkası: leylak zemin üstünde yuvarlak uçlu mor yay (saat 12'den başlar)
class _Halka extends CustomPainter {
  final double oran;
  final double kalinlik;
  _Halka(this.oran, this.kalinlik);

  @override
  void paint(Canvas canvas, Size size) {
    final m = size.center(Offset.zero);
    final r = size.shortestSide / 2 - kalinlik / 2 - 2;
    final rect = Rect.fromCircle(center: m, radius: r);
    canvas.drawCircle(
        m,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kalinlik
          ..color = const Color(0xFFEADCFB));
    canvas.drawCircle(m, r - kalinlik / 2, Paint()..color = Colors.white.withValues(alpha: 0.35));
    if (oran <= 0) return;
    canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * oran.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kalinlik
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: 3 * math.pi / 2,
            colors: [Color(0xFF7C3AED), Color(0xFF5B21B6), Color(0xFF7C3AED)],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _Halka e) => e.oran != oran || e.kalinlik != kalinlik;
}
