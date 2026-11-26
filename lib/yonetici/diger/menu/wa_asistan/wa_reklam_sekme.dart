// Diğer > WhatsApp Asistanı > Reklamlarım
// Web paneldeki "Reklamlarım" sekmesinin mobil karşılığı: kampanya listesi (durum, indirim, 30 günlük
// gönderim/açılma/randevu), yeni kampanya / düzenle (hizmet seçimi, zorunlu indirim, tarih, afiş, yayın),
// yayına al / durdur, sil. Backend: /api/v1/wa-asistan/reklamlar | reklam | reklam/{id}/sil.
// Sekme her işletmede görünür; özellik kapalıysa içinde uyarı çıkar (asistan özellik açılınca gönderir).

import 'dart:io';

import 'package:randevu_sistem/dil/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'wa_asistan_api.dart';
import 'wa_asistan_page.dart';
import 'wa_reklam_detay.dart';
import 'wa_widgets.dart';

// Web'deki RK_SABLONLAR ile aynı
const _sablonlar = [
  (e: '🎉', i: 20, b: 'İlk ziyarete %20 indirim', m: 'İlk randevunuzda tüm hizmetlerde %20 indirim.\nYalnızca yeni müşterilerimize özel.', k: 'Yeni müşteri kazanın'),
  (e: '📅', i: 15, b: 'Hafta içi indirimi', m: 'Pazartesi–Perşembe randevularında %15 indirim.\nBoş saatlerinizi doldurmanın en kolay yolu.', k: 'Sakin günleri doldurun'),
  (e: '🎁', i: 10, b: 'İki hizmet bir arada', m: 'İki hizmeti birlikte alana özel paket fiyat.\nAyrı ayrı almaktan çok daha avantajlı.', k: 'Sepeti büyütün'),
  (e: '👭', i: 10, b: 'Arkadaşını getir', m: 'Arkadaşınızla birlikte gelin, ikinize de %10 indirim.', k: 'Tavsiye ile büyüyün'),
];

// Form şablon ikonları (sırayla _sablonlar)
/// Form giris alanlarinda yazilan metin (biraz kucuk)
const _girdiYazi = TextStyle(fontSize: 13.5, color: Color(0xFF111827));
const _formSablonIkon = [Icons.card_giftcard_outlined, Icons.calendar_month_outlined, Icons.star_rounded, Icons.sell_outlined]; // form listesi

/// Üst kartın arka planındaki açık mor dalga
/// Banner arka plan efektleri (ornek gorseldeki gibi belirgin): sag ustte acik mor genis alan,
/// altta katmanli dalgalar, megafonun arkasinda yumusak isik.
class _DalgaPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // 1) Sag ust: acik mor genis bolge (kivrimli sinirla)
    final sagUst = Path()
      ..moveTo(w * 0.48, 0)
      ..cubicTo(w * 0.62, h * 0.30, w * 0.80, h * 0.10, w * 0.86, h * 0.48)
      ..cubicTo(w * 0.90, h * 0.70, w * 0.96, h * 0.80, w, h * 0.78)
      ..lineTo(w, 0)
      ..close();
    c.drawPath(
        sagUst,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0.06)],
          ).createShader(Rect.fromLTWH(w * 0.45, 0, w * 0.55, h)));
    // Sinir cizgisi: efekt net secilsin
    c.drawPath(
        Path()
          ..moveTo(w * 0.48, 0)
          ..cubicTo(w * 0.62, h * 0.30, w * 0.80, h * 0.10, w * 0.86, h * 0.48)
          ..cubicTo(w * 0.90, h * 0.70, w * 0.96, h * 0.80, w, h * 0.78),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withValues(alpha: 0.30));
    // 2) Alt dalgalar (iki katman)
    c.drawPath(
        Path()
          ..moveTo(0, h * 0.70)
          ..cubicTo(w * 0.22, h * 0.52, w * 0.42, h * 0.92, w * 0.66, h * 0.74)
          ..cubicTo(w * 0.82, h * 0.62, w * 0.92, h * 0.80, w, h * 0.72)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: 0.13));
    c.drawPath(
        Path()
          ..moveTo(0, h * 0.86)
          ..cubicTo(w * 0.28, h * 0.74, w * 0.52, h * 1.02, w * 0.78, h * 0.86)
          ..cubicTo(w * 0.90, h * 0.80, w * 0.96, h * 0.90, w, h * 0.88)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = const Color(0xFF3B0A8C).withValues(alpha: 0.22));
    // 3) Megafonun arkasinda yumusak isik
    c.drawCircle(
        Offset(w * 0.16, h * 0.48),
        h * 0.46,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: Offset(w * 0.16, h * 0.48), radius: h * 0.46)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _morDegrade = LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)], begin: Alignment.centerLeft, end: Alignment.centerRight);

/// Görseldeki geniş mor degrade düğme
Widget _degradeButon(
        {required String yazi,
        required IconData ikon,
        VoidCallback? onTap,
        bool yukleniyor = false,
        double radius = 18,
        double? yukseklik,
        double yaziBoyut = 16.5,
        Gradient gradient = _morDegrade}) =>
    Container(
      height: yukseklik,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: yukleniyor ? null : onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: yukseklik == null ? 16 : 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              yukleniyor
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(ikon, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(yazi, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: yaziBoyut)),
            ]),
          ),
        ),
      ),
    );

String _bugun() => isoGun(DateTime.now());

/// yayinda | bekliyor | kapali | bitti (web rkDurum)
String _durum(Map<String, dynamic> x) {
  final b = _bugun();
  if (sayiDeger(x['aktif']) == 0) return 'kapali';
  final bit = '${x['bitis'] ?? ''}';
  final bas = '${x['baslangic'] ?? ''}';
  if (bit.length >= 10 && bit.substring(0, 10).compareTo(b) < 0) return 'bitti';
  if (bas.length >= 10 && bas.substring(0, 10).compareTo(b) > 0) return 'bekliyor';
  return 'yayinda';
}

/// Filtre grubu: yayinda | bekliyor | bitti (durdurulan da "Bitti" sayılır)
String _grup(Map<String, dynamic> x) {
  final d = _durum(x);
  return d == 'kapali' ? 'bitti' : d;
}

/// Sayfadaki dönem seçimi -> reklam-kazanc ?gun=
int _donemGun(String d) {
  final n = DateTime.now();
  return switch (d) {
    '7g' => 7,
    '30g' => 30,
    '90g' => 90,
    'bu_ay' => n.day,
    'gecen_ay' => DateTime(n.year, n.month, n.day).difference(DateTime(n.year, n.month - 1, 1)).inDays + 1,
    _ => 30,
  };
}

/// "₺18.450" (binlik ayraçlı)
String _para(dynamic x) => '₺${sayi(x)}';

String _trTarih(dynamic s) {
  final t = '${s ?? ''}';
  if (t.length < 10) return t;
  final p = t.substring(0, 10).split('-');
  return '${p[2]}.${p[1]}.${p[0]}';
}

/// WaReklam::tl ile aynı biçim
String _tl(num x) {
  final tam = x == x.roundToDouble();
  final s = tam ? sayi(x) : x.toStringAsFixed(2).replaceAll('.', ',');
  return '$s TL';
}

/// WaReklam::indirimEtiket: "%15" | "250 TL" | ""
String _indirimEtiket(dynamic tur, dynamic deger) {
  final d = sayiDeger(deger);
  if (d <= 0) return '';
  if ('$tur' == 'yuzde') return '%${d == d.roundToDouble() ? d.round() : virgul(d)}';
  if ('$tur' == 'tutar') return _tl(d);
  return '';
}


class WaReklamSekme extends StatefulWidget {
  final WaDurum d;
  const WaReklamSekme({super.key, required this.d});
  @override
  State<WaReklamSekme> createState() => _WaReklamSekmeState();
}

class _WaReklamSekmeState extends State<WaReklamSekme> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _liste;
  String? _hata;
  bool _ozellikAcik = true;
  List<int> _populer = [];
  String _filtre = 'tumu';
  final _isleniyor = <int>{};

  // Kazanç (reklam-kazanc): null = yüklenemedi -> kazanç alanları gizlenir
  Map<String, dynamic>? _kazanc;
  late String _sonDonem;

  // Örnek (demo) veri: yalnız bellekte, sunucuya yazılmaz
  bool _demo = false;

  void _demoAc() {
    final v = waReklamDemo();
    setState(() {
      _demo = true;
      _filtre = 'tumu';
      _liste = haritaListe(v['liste']);
      _kazanc = harita(v['kazanc']);
    });
  }

  void _demoKapat() {
    setState(() {
      _demo = false;
      _filtre = 'tumu';
      _liste = null;
      _kazanc = null;
    });
    _yukle();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sonDonem = widget.d.donem;
    widget.d.addListener(_durumDegisti);
    _yukle();
  }

  @override
  void dispose() {
    widget.d.removeListener(_durumDegisti);
    super.dispose();
  }

  void _durumDegisti() {
    if (widget.d.donem == _sonDonem) return;
    _sonDonem = widget.d.donem;
    _kazancYukle();
  }

  Future<void> _kazancYukle() async {
    if (_demo) return;
    final r = await WaApi.al(widget.d.sube, '/reklam-kazanc', {'gun': '${_donemGun(widget.d.donem)}'});
    if (!mounted) return;
    setState(() => _kazanc = okMu(r) ? r : null);
  }

  Future<void> _yukle() async {
    if (_demo) return;
    final kz = _kazancYukle();
    final r = await WaApi.al(widget.d.sube, '/reklamlar');
    await kz;
    if (!mounted || _demo) return;
    setState(() {
      if (okMu(r)) {
        _hata = null;
        _liste = haritaListe(r['liste']);
        _ozellikAcik = r['acik'] == true || '${r['acik']}' == '1';
        _populer = liste(r['populer']).map((e) => sayiDeger(e).toInt()).toList();
      } else {
        _hata = '${r['hata'] ?? 'Yüklenemedi.'}';
        _liste ??= [];
      }
    });
  }

  Future<List<Map<String, dynamic>>?> _formAc([Map<String, dynamic>? x]) async {
    if (_demo) {
      _demoUyari();
      return null;
    }
    final yeni = await Navigator.of(context).push<List<Map<String, dynamic>>>(MaterialPageRoute(
      builder: (_) => WaReklamForm(d: widget.d, reklam: x, populer: _populer),
    ));
    if (yeni != null && mounted) {
      setState(() => _liste = yeni);
      _kazancYukle();
    }
    return yeni;
  }

  Future<void> _yayinDegistir(Map<String, dynamic> x) async {
    if (_demo) return _demoUyari();
    final aktif = sayiDeger(x['aktif']) != 0;
    if (!aktif && '${x['indirim_tur'] ?? ''}'.isEmpty) {
      waToast(context, 'Yayına almadan önce kampanya indirimini girin.');
      _formAc(x);
      return;
    }
    final id = sayiDeger(x['id']).toInt();
    setState(() => _isleniyor.add(id));
    final alan = <String, String>{
      'id': '$id',
      'baslik': '${x['baslik'] ?? ''}',
      'metin': '${x['metin'] ?? ''}',
      'baslangic': _kes10(x['baslangic']),
      'bitis': _kes10(x['bitis']),
      'aktif': aktif ? '0' : '1',
      'indirim_tur': '${x['indirim_tur'] ?? ''}',
      'indirim_deger': x['indirim_deger'] == null ? '' : '${x['indirim_deger']}',
    };
    final hz = liste(x['hizmetler']);
    for (var i = 0; i < hz.length; i++) {
      alan['hizmetler[$i]'] = '${hz[i]}';
    }
    final r = await WaApi.gonderForm(widget.d.sube, '/reklam', alan);
    if (!mounted) return;
    setState(() {
      _isleniyor.remove(id);
      if (okMu(r)) _liste = haritaListe(r['liste']);
    });
    waToast(context, okMu(r) ? (aktif ? 'Kampanya durduruldu.' : 'Kampanya yayında.') : '${r['hata'] ?? 'Kaydedilemedi.'}');
  }

  Future<void> _sil(Map<String, dynamic> x) async {
    if (_demo) return _demoUyari();
    if (!await waOnay(context, '"${x['baslik']}" kampanyası silinsin mi?', evet: 'Sil')) return;
    final r = await WaApi.gonder(widget.d.sube, '/reklam/${sayiDeger(x['id']).toInt()}/sil');
    if (!mounted) return;
    if (okMu(r)) setState(() => _liste = haritaListe(r['liste']));
    waToast(context, okMu(r) ? 'Silindi.' : '${r['hata'] ?? 'Silinemedi.'}');
  }

  Future<void> _sayfaAc(Map<String, dynamic> x) async {
    final link = '${x['link'] ?? ''}';
    if (link.isEmpty) return;
    try {
      await launchUrl(Uri.parse(link.startsWith('http') ? link : '${WaApi.host}$link'), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = _liste;
    return Stack(children: [
      RefreshIndicator(
        onRefresh: _yukle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (_demo) _demoSerit(),
            _hero(),
            if (l != null && (l.isNotEmpty || _kazanc != null)) _filtreler(l),
            if (_kazanc != null) _kpiSerit() else if (l != null && l.isNotEmpty) _ozet(l),
            if (_hata != null && !_demo) WaBilgi(_hata!, renk: const Color(0xFFDC2626)),
            if (l == null)
              const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
            else if (l.isEmpty)
              _bos()
            else
              ...l.where((x) => _filtre == 'tumu' || _grup(x) == _filtre).map(_kart),
          ],
        ),
      ),
      Positioned(
        left: 16,
        right: 16,
        bottom: 14,
        child: _degradeButon(
          yazi: 'Yeni kampanya',
          ikon: Icons.add_rounded,
          onTap: () => _formAc(),
          radius: 16,
          yukseklik: 52,
          yaziBoyut: 16,
          gradient: const LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF8B5CF6)], begin: Alignment.centerLeft, end: Alignment.centerRight),
        ),
      ),
    ]);
  }

  Widget _hero() {
    Widget adim(String m) => Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(m, maxLines: 1, softWrap: false, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.2)),
          ]),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Mor degrade bant (genis dikdortgen)
        SizedBox(
          height: 156,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: CustomPaint(
              painter: _DalgaPainter(),
              child: Stack(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 14, 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    // 3B megafon
                    SizedBox(width: 92, height: 92, child: Image.asset('images/wa_reklam_megafon.png', fit: BoxFit.contain)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Sag ustteki (i) ile cakismasin diye basliga sag bosluk
                        const Padding(
                          padding: EdgeInsets.only(right: 26),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('Kampanyalarınızı\nasistan anlatsın',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, height: 1.18)),
                          ),
                        ),
                        const SizedBox(height: 7),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            adim('1. Kampanyayı bir kez girin'),
                            adim('2. Müşteri ilgili hizmeti sorar'),
                            adim('3. Asistan afişle birlikte gönderir'),
                          ]),
                        ),
                      ]),
                    ),
                  ]),
                ),
                // Sag ust (i): "Nasil calisir?" bilgilendirmesi
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _nasilCalisir,
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // Bilgilendirme penceresi: icerik uzun olabilir -> kaydirilabilir, ekranin %85'ini gecmez (tasma olmasin)
  void _nasilCalisir() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (c) {
          Widget adim(String no, String baslik, String metin) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFEFE9FD), shape: BoxShape.circle),
                    child: Text(no, style: const TextStyle(color: Color(0xFF6D28D9), fontWeight: FontWeight.w800, fontSize: 13.5)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF1F1633))),
                      const SizedBox(height: 2),
                      Text(metin, style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.grey.shade700)),
                    ]),
                  ),
                ]),
              );
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.85),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const Row(children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF6D28D9), size: 22),
                    SizedBox(width: 8),
                    Text('Nasıl çalışır?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  ]),
                  const SizedBox(height: 16),
                  if (!_ozellikAcik)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCD9A8)),
                      ),
                      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFEA580C)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reklam özelliği bu işletmede kapalı. Kampanyalarınızı hazırlayabilirsiniz; özellik açılınca asistan göndermeye başlar.',
                            style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ]),
                    ),
                  adim('1', 'Kampanyayı bir kez girin', 'Başlık, açıklama, ilgili hizmetler, indirim ve isterseniz afiş.'),
                  adim('2', 'Müşteri ilgili hizmeti sorar', 'Müşteri WhatsApp\'tan bu hizmetlerden birini sorduğunda asistan kampanyayı afiş ve kampanya sayfası bağlantısıyla gönderir.'),
                  adim('3', 'Müşteri "evet" derse randevu açılır', 'Asistan randevuyu oluşturur; indirim randevu fiyatına otomatik işlenir.'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF5F2FC), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      'Kampanya her sohbette en fazla bir kez gider, ilgisiz hizmette gönderilmez, "kampanya istemiyorum" diyene bir daha gitmez. '
                      'Gönderim, açılma ve randevu sayılarını kartlarda görürsünüz.',
                      style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey.shade800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6D28D9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: () => Navigator.of(c).pop(),
                      child: const Text('Anladım', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      );

  // Bos durum: yalniz kisa bilgi. Hazir sablonlar "Yeni kampanya" formunda ("Hazır şablon").
  Widget _bos() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDE7F6)),
        ),
        child: Column(children: [
          const Icon(Icons.campaign_rounded, size: 34, color: Color(0xFF6D28D9)),
          const SizedBox(height: 6),
          const Text('Henüz kampanyanız yok', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          const Text('"Yeni kampanya" ile oluşturun; hazır şablonlar da orada.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: waMorKoyu,
              side: const BorderSide(color: waMorKoyu),
              visualDensity: VisualDensity.compact,
              shape: const StadiumBorder(),
            ),
            onPressed: _demoAc,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Örnekle göster', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  Widget _ozet(List<Map<String, dynamic>> l) {
    var y = 0, g = 0, t = 0, r = 0;
    for (final x in l) {
      if (_durum(x) == 'yayinda') y++;
      g += sayiDeger(x['gosterim']).toInt();
      t += sayiDeger(x['tiklama']).toInt();
      r += sayiDeger(x['randevu']).toInt();
    }
    Widget kpi(IconData i, Color c, String deger, String ad) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Icon(i, size: 18, color: c),
              const SizedBox(height: 4),
              Text(deger, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text(ad, textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        kpi(Icons.podcasts_rounded, const Color(0xFF16A34A), '$y / ${l.length}', 'Yayında'),
        kpi(Icons.send_rounded, waMor, sayi(g), 'Gönderildi\n30 gün'),
        kpi(Icons.visibility_rounded, const Color(0xFF0284C7), g > 0 ? '${sayi(t)} · %${(t * 100 / g).round()}' : sayi(t), 'Afişi açtı'),
        kpi(Icons.event_available_rounded, const Color(0xFFDB2777), sayi(r), 'Randevuya\ndönüştü'),
      ]),
    );
  }

  /// Filtre çipleri (Tümü / Yayında / Bekleyen / Bitti); kazanç alttaki KPI şeridinde
  Widget _filtreler(List<Map<String, dynamic>> l) {
    final say = <String, int>{'tumu': l.length, 'yayinda': 0, 'bekliyor': 0, 'bitti': 0};
    for (final x in l) {
      final g = _grup(x);
      say[g] = (say[g] ?? 0) + 1;
    }
    if (_filtre != 'tumu' && (say[_filtre] ?? 0) == 0) _filtre = 'tumu';
    const adlar = [('tumu', 'Tümü'), ('yayinda', 'Yayında'), ('bekliyor', 'Bekleyen'), ('bitti', 'Bitti')];
    Widget cip((String, String) f) {
      final secili = _filtre == f.$1;
      final bos = (say[f.$1] ?? 0) == 0 && f.$1 != 'tumu';
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Material(
          color: secili ? waMorKoyu : Colors.white,
          shape: StadiumBorder(side: BorderSide(color: secili ? waMorKoyu : const Color(0xFFE4DDF5))),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: bos ? null : () => setState(() => _filtre = f.$1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: f.$2),
                  TextSpan(
                      text: ' ${say[f.$1]}',
                      style: TextStyle(color: secili ? Colors.white70 : Colors.grey.shade500, fontWeight: FontWeight.w700)),
                ]),
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: secili ? Colors.white : (bos ? Colors.grey.shade400 : const Color(0xFF3B2A63))),
              ),
            ),
          ),
        ),
      );
    }

    if (l.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 34,
        child: ListView(scrollDirection: Axis.horizontal, children: adlar.map(cip).toList()),
      ),
    );
  }

  /// Kazanç KPI şeridi: Ulaşılan · Randevu · Gelen · Kazanç (dönem seçimine göre)
  Widget _kpiSerit() {
    final o = harita(_kazanc?['ozet']);
    Widget kutu(String ad, String deger, Color renk, Color zemin, {String? alt}) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
            decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(deger, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: renk)),
              ),
              const SizedBox(height: 1),
              Text(ad, maxLines: 1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: renk.withValues(alpha: 0.8))),
              if (alt != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(alt, maxLines: 1, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        kutu('Ulaşılan', sayi(o['ulasilan']), const Color(0xFF6D28D9), const Color(0xFFF1EBFE)),
        kutu('Randevu', sayi(o['randevu']), const Color(0xFFDB2777), const Color(0xFFFDEDF5)),
        kutu('Gelen', sayi(o['gelen']), const Color(0xFF0D9488), const Color(0xFFE6F7F5)),
        kutu('Kazanç', _para(o['kazanc']), const Color(0xFF15803D), const Color(0xFFE8F8EE),
            alt: sayiDeger(o['indirim']) > 0 ? 'İndirim ${_para(o['indirim'])}' : null),
      ]),
    );
  }

  void _demoUyari() => waToast(context, 'Örnek veride işlem yapılamaz');

  Future<void> _detayAc(Map<String, dynamic> x) async {
    final id = sayiDeger(x['id']).toInt();
    final demoKz = _demo ? _kazanc : null;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WaReklamDetay(
        d: widget.d,
        reklam: x,
        demoVeri: demoKz == null ? null : waReklamDemoTek(demoKz, id),
        onDuzenle: _demo
            ? null
            : (r) async {
                final yeni = await _formAc(r);
                if (yeni == null) return null;
                final b = yeni.where((e) => sayiDeger(e['id']).toInt() == id);
                return b.isEmpty ? null : b.first;
              },
      ),
    ));
  }

  /// Örnek veri uyarı şeridi
  Widget _demoSerit() => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: Row(children: [
          const Icon(Icons.science_outlined, size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Örnek veri — kaydedilmez, gönderilmez',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB45309), visualDensity: VisualDensity.compact),
            onPressed: _demoKapat,
            child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  Widget _kart(Map<String, dynamic> x) {
    final d = waReklamDurum(x);
    final id = sayiDeger(x['id']).toInt();
    final aktif = sayiDeger(x['aktif']) != 0;
    final gorsel = '${x['gorsel'] ?? ''}';
    final renk = waReklamDurumRenk[d]!;
    final kz = harita(harita(_kazanc?['reklamlar'])['$id']);
    final rdv = sayiDeger(kz['randevu']), kazandi = sayiDeger(kz['kazanc']);
    final pasif = d == 'kapali' || d == 'bitti';

    return Opacity(
      opacity: pasif ? 0.8 : 1,
      child: WaKart(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _detayAc(x),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: gorsel.isNotEmpty
                        ? Image.network(gorsel.startsWith('http') ? gorsel : '${WaApi.host}$gorsel',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: waAcikMor, child: const Icon(Icons.campaign_rounded, size: 28, color: waMor)))
                        : Container(color: waAcikMor, child: const Icon(Icons.campaign_rounded, size: 28, color: waMor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(waReklamKod(id), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text('● ${waReklamDurumAd[d]}', style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                    ]),
                    const SizedBox(height: 3),
                    Text('${x['baslik']}',
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('${waReklamTarihAraligi(x)} · ${waReklamKalan(x)}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
                      ),
                    ]),
                    if (rdv > 0 || kazandi > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: '${sayi(rdv)} randevu · '),
                            TextSpan(
                                text: '${_para(kazandi)} kazandırdı',
                                style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w700)),
                          ]),
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Spacer(),
                      if (_isleniyor.contains(id))
                        const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: waMorKoyu,
                          side: const BorderSide(color: waMorKoyu),
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.only(left: 14, right: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => _detayAc(x),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Detay', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          Icon(Icons.chevron_right_rounded, size: 18),
                        ]),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'İşlemler',
                        icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade700),
                        onSelected: (v) {
                          if (_demo) return _demoUyari();
                          switch (v) {
                            case 'duzenle':
                              _formAc(x);
                            case 'yayin':
                              _yayinDegistir(x);
                            case 'sayfa':
                              _sayfaAc(x);
                            case 'sil':
                              _sil(x);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'duzenle', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Düzenle'), dense: true)),
                          PopupMenuItem(
                              value: 'yayin',
                              child: ListTile(
                                  leading: Icon(aktif ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                  title: Text(aktif ? 'Durdur' : 'Yayına al'),
                                  dense: true)),
                          const PopupMenuItem(
                              value: 'sayfa',
                              child: ListTile(leading: Icon(Icons.open_in_new_rounded), title: Text('Müşterinin gördüğü sayfa'), dense: true)),
                          const PopupMenuItem(
                              value: 'sil',
                              child: ListTile(
                                  leading: Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                                  title: Text('Sil', style: TextStyle(color: Color(0xFFDC2626))),
                                  dense: true)),
                        ],
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
}

String _kes10(dynamic s) {
  final t = '${s ?? ''}';
  return t.length >= 10 ? t.substring(0, 10) : '';
}

// ================================================================ FORM
class WaReklamForm extends StatefulWidget {
  final WaDurum d;
  final Map<String, dynamic>? reklam;
  final List<int> populer;
  const WaReklamForm({super.key, required this.d, this.reklam, this.populer = const []});
  @override
  State<WaReklamForm> createState() => _WaReklamFormState();
}

class _WaReklamFormState extends State<WaReklamForm> {
  late final int? _id;
  final _baslik = TextEditingController();
  final _metin = TextEditingController();
  final _indDeger = TextEditingController();
  final _ara = TextEditingController();
  String _indTur = 'yuzde';
  String _bas = '';
  String _bit = '';
  bool _aktif = true;
  final _secili = <int>[];
  String? _dosya; // yeni secilen afis
  String? _mevcutGorsel;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    final x = widget.reklam ?? const {};
    _id = x['id'] == null ? null : sayiDeger(x['id']).toInt();
    _baslik.text = '${x['baslik'] ?? ''}';
    _metin.text = '${x['metin'] ?? ''}';
    _indTur = '${x['indirim_tur'] ?? ''}' == 'tutar' ? 'tutar' : 'yuzde';
    final dv = sayiDeger(x['indirim_deger']);
    _indDeger.text = dv > 0 ? (dv == dv.roundToDouble() ? '${dv.round()}' : '$dv') : '';
    _bas = _kes10(x['baslangic']);
    _bit = _kes10(x['bitis']);
    _aktif = x.isEmpty || sayiDeger(x['aktif'] ?? 1) != 0;
    _secili.addAll(liste(x['hizmetler']).map((e) => sayiDeger(e).toInt()));
    final g = '${x['gorsel'] ?? ''}';
    _mevcutGorsel = g.isEmpty ? null : (g.startsWith('http') ? g : '${WaApi.host}$g');
    for (final c in [_baslik, _metin, _indDeger, _ara]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_baslik, _metin, _indDeger, _ara]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<int, Map<String, dynamic>> get _hizmetMap => {for (final h in widget.d.hizmetler) sayiDeger(h['id']).toInt(): h};

  void _sablonUygula(int i) {
    final s = _sablonlar[i];
    setState(() {
      _baslik.text = s.b;
      _metin.text = s.m;
      _indTur = 'yuzde';
      _indDeger.text = '${s.i}';
    });
  }

  Future<void> _tarihSec(bool baslangic) async {
    final simdi = DateTime.now();
    final mevcut = DateTime.tryParse(baslangic ? _bas : _bit) ?? simdi;
    final t = await showDatePicker(
      context: context,
      initialDate: mevcut,
      firstDate: DateTime(simdi.year - 1),
      lastDate: DateTime(simdi.year + 3),
      locale: const Locale('tr', 'TR'),
    );
    if (t == null) return;
    setState(() => baslangic ? _bas = isoGun(t) : _bit = isoGun(t));
  }

  void _sureSec(String v) {
    final d = DateTime.now();
    setState(() {
      if (_bas.isEmpty && v != '0') _bas = isoGun(d);
      if (v == '0') {
        _bit = '';
      } else if (v == 'ay') {
        _bit = isoGun(DateTime(d.year, d.month + 1, 0));
      } else {
        _bit = isoGun(d.add(Duration(days: int.parse(v))));
      }
    });
  }

  Future<void> _gorselSec() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (f == null) return;
      final boyut = await File(f.path).length();
      if (boyut > 4 * 1024 * 1024) {
        if (mounted) waToast(context, 'Görsel 4 MB\'tan büyük olamaz.');
        return;
      }
      setState(() => _dosya = f.path);
    } catch (_) {
      if (mounted) waToast(context, 'Görsel seçilemedi. Galeri izni verildiğinden emin olun.');
    }
  }

  Future<void> _kaydet() async {
    final d = num.tryParse(_indDeger.text.replaceAll(',', '.')) ?? 0;
    if (d <= 0) return waToast(context, 'Kampanya indirimini yazın (zorunlu).');
    if (_indTur == 'yuzde' && d > 100) return waToast(context, 'Yüzde indirim en fazla 100 olabilir.');
    if (_baslik.text.trim().isEmpty) return waToast(context, 'Kampanyaya bir başlık yazın.');
    if (_secili.isEmpty) return waToast(context, 'Kampanyanın ilgili olduğu en az bir hizmet seçin.');
    if (_bas.isNotEmpty && _bit.isNotEmpty && _bit.compareTo(_bas) < 0) return waToast(context, 'Bitiş tarihi başlangıçtan önce olamaz.');
    final alan = <String, String>{
      if (_id != null) 'id': '$_id',
      'baslik': _baslik.text.trim(),
      'metin': _metin.text.trim(),
      'baslangic': _bas,
      'bitis': _bit,
      'aktif': _aktif ? '1' : '0',
      'indirim_tur': _indTur,
      'indirim_deger': '$d',
    };
    for (var i = 0; i < _secili.length; i++) {
      alan['hizmetler[$i]'] = '${_secili[i]}';
    }
    setState(() => _kaydediliyor = true);
    final r = await WaApi.gonderForm(widget.d.sube, '/reklam', alan, dosyaYolu: _dosya);
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
    if (!okMu(r)) return waToast(context, '${r['hata'] ?? 'Kaydedilemedi.'}');
    waToast(context, 'Kampanya kaydedildi.');
    Navigator.of(context).pop(haritaListe(r['liste']));
  }

  // Musteriye giden mesaj (WaReklam::mesaj ile ayni sablon)
  String _mesaj() {
    final b = StringBuffer('🎁 *${_baslik.text.trim().isEmpty ? 'Kampanya başlığı' : _baslik.text.trim()}*\n');
    final ek = <String>[];
    for (final s in _metin.text.split(RegExp(r'\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty)) {
      ek.add('✨ $s');
    }
    final ind = _indirimEtiket(_indTur, num.tryParse(_indDeger.text.replaceAll(',', '.')));
    if (ind.isNotEmpty) ek.add('🏷️ Kampanya indirimi: *$ind*');
    final adlar = _secili.map((i) => '${_hizmetMap[i]?['ad'] ?? '#$i'}').toList();
    if (adlar.isNotEmpty) ek.add('💆 ${adlar.take(4).join(', ')}');
    if (_bit.length == 10) {
      final p = _bit.split('-');
      ek.add('📅 Son gün: *${int.parse(p[2])} ${aylarUzun[int.parse(p[1]) - 1]}*');
    }
    if (ek.isNotEmpty) b.write('\n${ek.join('\n')}\n');
    b.write('\n👉 Detaylar ve afiş:\napp.randevumcepte.com.tr/k/…\n\nKampanyadan yararlanmak için *"evet"* yazmanız yeterli, randevunuzu hemen oluşturalım 🙂'
        '\n\n_Kampanya mesajı istemezseniz "kampanya istemiyorum" yazın._');
    return b.toString();
  }

  /// *kalin* ve _italik_ WhatsApp bicimi
  List<TextSpan> _waBicim(String m) {
    final out = <TextSpan>[];
    final re = RegExp(r'\*([^*\n]+)\*|_([^_\n]+)_');
    var i = 0;
    for (final x in re.allMatches(m)) {
      if (x.start > i) out.add(TextSpan(text: m.substring(i, x.start)));
      if (x.group(1) != null) {
        out.add(TextSpan(text: x.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else {
        out.add(TextSpan(text: x.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      i = x.end;
    }
    if (i < m.length) out.add(TextSpan(text: m.substring(i)));
    return out;
  }

  // Ornek gorseldeki gibi: mor->pembe degrade, dalga efektleri, 3B hedef tahtasi
  Widget _sablonBaslik() => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 104,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFFC026D3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: CustomPaint(
          painter: _DalgaPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
            child: Row(children: [
              SizedBox(width: 88, height: 88, child: Image.asset('images/wa_reklam_hedef.png', fit: BoxFit.contain)),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hazır şablon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('dokununca doldurur, sonra düzenlersiniz', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      );

  // Ince sablon satiri (form alanlari yukari ciksin)
  Widget _sablonSatir(int i) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDE7F6)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _sablonUygula(i),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(children: [
                Icon(_formSablonIkon[i], color: const Color(0xFF6D28D9), size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(_sablonlar[i].b, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF111827)))),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF4C1D95), size: 20),
              ]),
            ),
          ),
        ),
      );

  Widget _etiketBaslik(String m, [String? alt]) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(m, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827))),
          if (alt != null) ...[const SizedBox(width: 6), Flexible(child: Text(alt, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)))],
        ]),
      );

  InputDecoration _dek(String ipucu, {String? sonEk, IconData? ikon}) => InputDecoration(
        hintText: ipucu,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        suffixText: sonEk,
        prefixIcon: ikon == null ? null : Padding(padding: const EdgeInsets.only(left: 12, right: 8), child: Icon(ikon, color: const Color(0xFF6D28D9), size: 19)),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE4DDF5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE4DDF5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.4)),
      );

  Widget _hizmetSecim() {
    final q = _ara.text.trim().toLowerCase();
    final pop = (widget.populer.isNotEmpty ? widget.populer : widget.d.hizmetler.take(12).map((h) => sayiDeger(h['id']).toInt()).toList());
    final tumu = widget.d.hizmetler;
    List<Map<String, dynamic>> gorunen;
    if (q.isEmpty) {
      final m = _hizmetMap;
      gorunen = pop.where((i) => m.containsKey(i)).map((i) => m[i]!).toList();
    } else {
      gorunen = tumu.where((h) => '${h['ad']}'.toLowerCase().contains(q)).toList();
    }
    gorunen = gorunen.where((h) => !_secili.contains(sayiDeger(h['id']).toInt())).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _etiketBaslik('Hangi hizmet sorulunca gönderilsin?', _secili.isEmpty ? null : '${_secili.length} seçili'),
      if (_secili.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _secili
                .map((i) => InputChip(
                      label: Text('${_hizmetMap[i]?['ad'] ?? '#$i'}'),
                      selected: true,
                      selectedColor: waMor.withValues(alpha: 0.15),
                      onDeleted: () => setState(() => _secili.remove(i)),
                      showCheckmark: false,
                    ))
                .toList(),
          ),
        ),
      TextField(controller: _ara, style: _girdiYazi, decoration: _dek('Hizmet ara (ör. manikür, protez)', ikon: Icons.sell_outlined)),
      const SizedBox(height: 6),
      if (q.isNotEmpty && gorunen.isEmpty) Text('Bu adla hizmet bulunamadı.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 8,
        children: gorunen
            .take(40)
            .map((h) => Material(
                  color: const Color(0xFFEFEAFB),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => setState(() {
                      _secili.add(sayiDeger(h['id']).toInt());
                      _ara.clear();
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add_rounded, size: 20, color: Color(0xFF6D28D9)),
                        const SizedBox(width: 6),
                        Text('${h['ad']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
                      ]),
                    ),
                  ),
                ))
            .toList(),
      ),
    ]);
  }

  Widget _indirimAlan() {
    final d = num.tryParse(_indDeger.text.replaceAll(',', '.')) ?? 0;
    Widget ornek;
    if (d <= 0) {
      ornek = const Text('İndirim miktarını yazın.', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12.5));
    } else if (_indTur == 'yuzde' && d > 100) {
      ornek = const Text('Yüzde 100\'den büyük olamaz.', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12.5));
    } else {
      final satirlar = <Widget>[];
      for (final i in _secili.take(5)) {
        final h = _hizmetMap[i];
        final lf = sayiDeger(h?['fiyat']);
        if (lf <= 0) {
          satirlar.add(Text('${h?['ad'] ?? '#$i'}: liste fiyatı yok', style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)));
          continue;
        }
        final yeni = _indTur == 'yuzde' ? lf - (lf * d).round() / 100 : (lf - d < 0 ? 0 : lf - d);
        satirlar.add(Text.rich(TextSpan(style: const TextStyle(fontSize: 12.5), children: [
          TextSpan(text: '${h?['ad']}: '),
          TextSpan(text: _tl(lf), style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
          const TextSpan(text: ' → '),
          TextSpan(text: _tl(yeni), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
        ])));
      }
      if (_secili.length > 5) satirlar.add(const Text('…'));
      if (satirlar.isEmpty) satirlar.add(const WaAlt('Hizmet seçince indirimli fiyatı burada görürsünüz.'));
      if (_indTur == 'tutar') satirlar.add(const Padding(padding: EdgeInsets.only(top: 4), child: WaAlt('Tutar indirimi randevu başına bir kez düşülür.')));
      ornek = Column(crossAxisAlignment: CrossAxisAlignment.start, children: satirlar);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _etiketBaslik('Kampanya indirimi *', 'zorunlu · asistanın açtığı randevuya otomatik işlenir'),
      Row(children: [
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'yuzde', label: Text('% Yüzde')), ButtonSegment(value: 'tutar', label: Text('₺ Tutar'))],
          selected: {_indTur},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _indTur = s.first),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _indDeger,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: _girdiYazi,
            decoration: _dek(_indTur == 'yuzde' ? 'ör. 15' : 'ör. 250', sonEk: _indTur == 'yuzde' ? '%' : 'TL'),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
        child: ornek,
      ),
    ]);
  }

  Widget _tarihler() {
    Widget kutu(String deger, String ipucu, bool baslangic) => Expanded(
          child: InkWell(
            onTap: () => _tarihSec(baslangic),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: waMor),
                const SizedBox(width: 8),
                Expanded(child: Text(deger.isEmpty ? ipucu : _trTarih(deger), style: TextStyle(color: deger.isEmpty ? Colors.grey : null))),
                if (deger.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => baslangic ? _bas = '' : _bit = ''),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
              ]),
            ),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _etiketBaslik('Yayın tarihleri', 'boş bırakılırsa süresiz'),
      Row(children: [kutu(_bas, 'Başlangıç', true), const SizedBox(width: 10), kutu(_bit, 'Bitiş', false)]),
      const SizedBox(height: 6),
      Wrap(spacing: 6, children: [
        for (final s in const [('7', '1 hafta'), ('ay', 'Ay sonuna kadar'), ('30', '30 gün'), ('0', 'Süresiz')])
          ActionChip(label: Text(s.$2), onPressed: () => _sureSec(s.$1)),
      ]),
    ]);
  }

  Widget _gorselAlan() {
    final Widget? onizle = _dosya != null
        ? Image.file(File(_dosya!), fit: BoxFit.cover)
        : (_mevcutGorsel != null ? Image.network(_mevcutGorsel!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()) : null);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _etiketBaslik('Afiş görseli', 'JPG/PNG, en fazla 4 MB'),
      InkWell(
        onTap: _gorselSec,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: waAcikMor, borderRadius: BorderRadius.circular(12), border: Border.all(color: waMor.withValues(alpha: 0.3))),
          child: onizle != null
              ? Stack(fit: StackFit.expand, children: [
                  onizle,
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Değiştir', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ])
              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.cloud_upload_outlined, size: 34, color: waMor),
                  SizedBox(height: 6),
                  Text('Galeriden görsel seçmek için dokunun'),
                ]),
        ),
      ),
    ]);
  }

  Widget _onizleme() {
    final Widget? img = _dosya != null
        ? Image.file(File(_dosya!), fit: BoxFit.cover)
        : (_mevcutGorsel != null ? Image.network(_mevcutGorsel!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()) : null);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFE5DDD5), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Asistan, ilgili hizmet sorulunca gönderir', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Colors.black54)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFDCF8C6), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (img != null) ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(height: 150, child: img)),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                child: Text.rich(TextSpan(style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.35), children: _waBicim(_mesaj()))),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        const Text('Bağlantı her müşteri için ayrı oluşur; kimin açtığı ve randevuya dönüştüğü sayılır.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black54)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yeni = _id == null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5FB),
        surfaceTintColor: const Color(0xFFF7F5FB),
        elevation: 0,
        title: Text(yeni ? 'Yeni kampanya' : 'Kampanyayı düzenle', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: _degradeButon(
            yazi: yeni ? 'Kampanyayı kaydet' : 'Değişiklikleri kaydet',
            ikon: Icons.check_rounded,
            onTap: _kaydet,
            yukleniyor: _kaydediliyor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
        children: [
          if (yeni) ...[
            _sablonBaslik(),
            for (var i = 0; i < _sablonlar.length; i++) _sablonSatir(i),
            const SizedBox(height: 8),
          ],
          _etiketBaslik('Başlık', '${_baslik.text.length}/120'),
          TextField(controller: _baslik, maxLength: 120, style: _girdiYazi, decoration: _dek('Örn. Kasım\'a özel protez tırnak + manikür 950 TL', ikon: Icons.sell_outlined).copyWith(counterText: '')),
          const SizedBox(height: 10),
          _etiketBaslik('Açıklama', '${_metin.text.length}/700 · her satır mesajda ayrı madde olur'),
          TextField(
            controller: _metin,
            maxLength: 700,
            minLines: 3,
            maxLines: 6,
            style: _girdiYazi,
            decoration: _dek('Örn. 1.200 TL yerine 950 TL. Ay sonuna kadar geçerli.', ikon: Icons.description_outlined).copyWith(counterText: ''),
          ),
          const SizedBox(height: 14),
          _hizmetSecim(),
          const SizedBox(height: 14),
          _indirimAlan(),
          const SizedBox(height: 14),
          _tarihler(),
          const SizedBox(height: 14),
          _gorselAlan(),
          const SizedBox(height: 14),
          WaKart(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _aktif,
              activeThumbColor: waMor,
              onChanged: (v) => setState(() => _aktif = v),
              title: const Text('Yayında', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Kapalıyken asistan bu kampanyayı göndermez.'),
            ),
          ),
          _etiketBaslik('Müşteri ne görecek?'),
          _onizleme(),
        ],
      ),
    );
  }
}
