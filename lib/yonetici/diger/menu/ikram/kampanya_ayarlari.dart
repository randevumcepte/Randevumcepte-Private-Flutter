import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// Kampanya kartı hazır görseli (işletme fotoğraf yüklemediyse), hizmet adına göre.
/// Sıra önemli: "Ayak protez tırnak" ayak, "Kaş ve Kirpik Lifting" kirpik, "Saç bakımı" saç olur.
/// Hiçbirine uymayan hizmette nötr spa görseli: yanlış görsel gösterilmez.
String ikramHazirGorsel(String hizmet) {
  // "İ".toLowerCase() noktalı i (i + U+0307) verir; aramada sorun çıkmasın diye nokta atılır
  final h = hizmet.toLowerCase().replaceAll('̇', '');
  bool var_(List<String> l) => l.any(h.contains);
  if (var_(['pedikür', 'pedikur'])) return 'images/ikram_k_pedikur.jpg';
  if (var_(['ayak', 'topuk', 'nasır', 'nasir', 'batık', 'batik', 'mantar'])) return 'images/ikram_foto_ayak.png';
  if (var_(['kalıcı makyaj', 'kalici makyaj', 'dudak', 'liner', 'microblading', 'pudra kaş', 'pudra kas'])) {
    return 'images/ikram_k_dudak.jpg';
  }
  if (var_(['kirpik', 'lash'])) return 'images/ikram_k_kirpik.jpg';
  if (var_(['kaş', 'brow'])) return 'images/ikram_k_kas.jpg';
  if (var_(['lazer', 'epilasyon', 'ağda', 'agda', 'iğneli', 'igneli', 'bıyık', 'biyik', 'tüy alma'])) return 'images/ikram_k_lazer.jpg';
  if (var_(['tırnak', 'tirnak', 'oje', 'manikür', 'manikur', 'nail', 'jel', 'protez', 'french', 'inci tozu', 'kedi gözü', 'kedi gozu', 'şablon', 'sablon'])) {
    return 'images/ikram_k_tirnak.jpg';
  }
  if (var_(['saç', 'sac ', 'fön', 'boya', 'kesim', 'keratin', 'perma', 'röfle', 'rofle', 'balyaj', 'ombre', 'topuz', 'maşa', 'brezilya', 'gelin başı'])) {
    return 'images/ikram_k_sac.jpg';
  }
  if (var_(['cilt', 'yüz', 'yuz', 'hydra', 'facial', 'peeling', 'leke', 'akne', 'bakım', 'bakim', 'dermapen', 'mezoterapi'])) {
    return 'images/ikram_k_cilt.jpg';
  }
  if (var_(['masaj', 'spa', 'taş', 'aroma', 'refleks', 'sauna', 'hamam', 'kese'])) return 'images/ikram_k_masaj.jpg';
  return 'images/ikram_foto_spa.png';
}

/// İkram Hizmet kampanya ekle/düzenle ("Kampanya Ayarları" tasarımı).
/// Tür: X + 1 (hediye hizmet) | İndirim (%). Kayıt: /carkAdmin/damga-karti (web ile aynı kural).
/// Kaydedilince `true` ile kapanır.
class KampanyaAyarlariSayfasi extends StatefulWidget {
  final String salonId;
  final Map<String, dynamic>? mevcut;
  final List<Map<String, dynamic>> hizmetler;
  /// Yeni kampanyada şablondan gelen alım adedi (5+1, 3+1...)
  final int? varsayilanAdet;

  const KampanyaAyarlariSayfasi({super.key, required this.salonId, this.mevcut, required this.hizmetler, this.varsayilanAdet});

  @override
  State<KampanyaAyarlariSayfasi> createState() => _KampanyaAyarlariSayfasiState();
}

class _KampanyaAyarlariSayfasiState extends State<KampanyaAyarlariSayfasi> {
  static const _koyu = Color(0xFF2E1065);
  static const _mor = Color(0xFF7C3AED);
  static const _morKoyu = Color(0xFF5B21B6);
  static const _soluk = Color(0xFF6B5A8E);

  int? _hizmetId;
  late int _adet;
  late int _hediye;
  DateTime? _bas;
  DateTime? _bit;
  late int _sureDeger;
  late String _sureBirim;
  late bool _aktif;
  bool _kaydediyor = false;
  String? _mevcutGorsel; // sunucudaki: /public/kampanya_gorselleri/...
  String? _yeniGorsel; // galeriden seçilen yerel dosya
  bool _gorselKaldir = false;

  late final List<Map<String, dynamic>> _hizmetler;

  @override
  void initState() {
    super.initState();
    final m = widget.mevcut;
    int n(String a, int v) => (m?[a] as num?)?.toInt() ?? v;
    _hizmetId = (m?['hizmet_id'] as num?)?.toInt();
    _adet = n('gereken_adet', widget.varsayilanAdet ?? 5);
    _hediye = n('ucretsiz_adet', 1);
    _bas = DateTime.tryParse((m?['baslangic'] ?? '').toString());
    _bit = DateTime.tryParse((m?['bitis_tarihi'] ?? '').toString());
    _sureDeger = n('gecerlilik_deger', 0);
    _sureBirim = m?['gecerlilik_birim'] == 'gun' ? 'gun' : 'ay';
    _aktif = n('aktif', 1) == 1;
    final g = (m?['gorsel'] ?? '').toString();
    _mevcutGorsel = g.isEmpty ? null : g;
    // Kuraldaki hizmet artık aktif listede değilse de seçili görünsün
    _hizmetler = List<Map<String, dynamic>>.from(widget.hizmetler);
    if (_hizmetId != null && !_hizmetler.any((h) => (h['id'] as num).toInt() == _hizmetId)) {
      _hizmetler.insert(0, {'id': _hizmetId, 'hizmet_adi': m?['hizmet_adi'] ?? 'Hizmet #$_hizmetId'});
    }
  }

  DateTime get _bugun {
    final s = DateTime.now();
    return DateTime(s.year, s.month, s.day);
  }

  String _tarih(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _hizmetAdi {
    for (final h in _hizmetler) {
      if ((h['id'] as num).toInt() == _hizmetId) return (h['hizmet_adi'] ?? '').toString();
    }
    return 'Hizmet seçin';
  }

  void _mesaj(String m, {bool hata = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: hata ? Colors.red.shade600 : _morKoyu,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final alt = MediaQuery.of(context).padding.bottom;
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
          // Köşe yaprakları (dekor)
          Positioned(left: 0, bottom: 0, child: IgnorePointer(child: Opacity(opacity: 0.9, child: Image.asset('images/kampanya_yaprak_sol.png', width: 92)))),
          Positioned(right: 0, bottom: 40, child: IgnorePointer(child: Opacity(opacity: 0.9, child: Image.asset('images/kampanya_yaprak_sag.png', width: 78)))),
          SafeArea(
            bottom: false,
            child: Column(children: [
              _ustBar(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 24 + alt),
                  children: [
                    _hero(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(children: [
                        const SizedBox(height: 10),
                        _detayKarti(),
                        const SizedBox(height: 12),
                        _gorselKarti(),
                        const SizedBox(height: 12),
                        _gecerlilikKarti(),
                        const SizedBox(height: 12),
                        _aktifKarti(),
                        const SizedBox(height: 18),
                        _kaydetDugmesi(),
                      ]),
                    ),
                  ],
                ),
              ),
            ]),
          ),
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
            child: Text('Kampanya Ayarları',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _koyu, letterSpacing: -0.3)),
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

  // ---------------------------------------------------------------- hero

  /// Tasarımın üst bölümü birebir görsel (kart + fotoğraf + başlık). Görseldeki alt yazı
  /// silindi; yerine hediye adedine göre değişen yazı aynı konuma oturtulur.
  /// Ölçüler tasarım görselinin pikselleri (941 x 362) üzerinden oranlanır.
  Widget _hero() {
    return LayoutBuilder(builder: (c, k) {
      final w = k.maxWidth;
      final h = w * 362 / 941;
      return SizedBox(
        width: w,
        height: h,
        child: Stack(children: [
          // Üst/alt kenar sayfa zeminine erir (görselin kendi zemini çizgi gibi görünmesin)
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.06, 0.93, 1],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: Image.asset('images/kampanya_hero_tam.png', fit: BoxFit.fill),
            ),
          ),
          Positioned(
            left: w * 95 / 941,
            top: h * 256 / 362,
            child: Text(
              'Belirlediğin adetlerde\n$_hediye hizmet hediye et.',
              style: TextStyle(color: Colors.white, fontSize: w * 0.0262, height: 1.3, fontWeight: FontWeight.w500),
            ),
          ),
        ]),
      );
    });
  }

  // ---------------------------------------------------------------- kartlar

  Widget _kart({required Widget child, EdgeInsets padding = const EdgeInsets.fromLTRB(14, 14, 14, 14)}) {
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

  Widget _kartBaslik(IconData ikon, String baslik, String alt) => Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF3E8FF), Color(0xFFDDD0FB)],
            ),
            boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Icon(ikon, color: _morKoyu, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(baslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _koyu)),
            const SizedBox(height: 1),
            Text(alt, style: const TextStyle(fontSize: 12, color: _soluk)),
          ]),
        ),
      ]);

  // Kampanya Detayları
  Widget _detayKarti() {
    return _kart(
      child: Column(children: [
        _kartBaslik(Icons.tune_rounded, 'Kampanya Detayları', 'Kampanyanın koşullarını belirleyin.'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDE4FA)),
          ),
          child: Column(children: [
            _detaySatir(
              Icons.spa_rounded,
              'Hizmet',
              'Kampanyanın geçerli olduğu hizmet.',
              _secimKutusu(_hizmetAdi, _hizmetSec, genis: true),
            ),
            _ayrac(),
            _detaySatir(
              Icons.bar_chart_rounded,
              'Hizmet Adedi',
              'Müşterinin alması gereken hizmet adedini girin.',
              _sayac(_adet, (v) => setState(() => _adet = v), min: 1, max: 100),
            ),
            _ayrac(),
            _detaySatir(
              Icons.card_giftcard_rounded,
              'Hediye Hizmet',
              'Müşteriye verilecek hediye hizmeti seçin.',
              _secimKutusu('$_hediye Hizmet', () async {
                final v = await _listeSec('Hediye hizmet adedi',
                    List.generate(10, (i) => i + 1), _hediye, (v) => '$v Hizmet');
                if (v != null) setState(() => _hediye = v);
              }),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _ayrac() => const Divider(height: 1, thickness: 1, color: Color(0xFFEDE4FA), indent: 12, endIndent: 12);

  Widget _detaySatir(IconData ikon, String baslik, String alt, Widget sag) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF3ECFE)),
            child: Icon(ikon, color: _mor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(baslik, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _koyu)),
              Text(alt, style: const TextStyle(fontSize: 11, height: 1.25, color: _soluk)),
            ]),
          ),
          const SizedBox(width: 8),
          sag,
        ]),
      );

  Widget _sayac(int deger, ValueChanged<int> degis, {required int min, required int max, int adim = 1, String onEk = ''}) {
    Widget dugme(IconData i, bool aktif, VoidCallback f) => GestureDetector(
          onTap: aktif ? f : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aktif ? const Color(0xFFEDE3FD) : const Color(0xFFF5F0FC),
            ),
            child: Icon(i, size: 20, color: aktif ? _morKoyu : const Color(0xFFC4B5E0)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE6DAF8)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        dugme(Icons.remove_rounded, deger > min, () => degis((deger - adim).clamp(min, max))),
        SizedBox(
          width: 40,
          child: Text('$onEk$deger',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _koyu)),
        ),
        dugme(Icons.add_rounded, deger < max, () => degis((deger + adim).clamp(min, max))),
      ]),
    );
  }

  Widget _secimKutusu(String yazi, VoidCallback onTap, {bool genis = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(maxWidth: genis ? 150 : 128, minWidth: 110),
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1E9FD),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE2D4F8)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: Text(yazi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _koyu)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _koyu, size: 22),
          ]),
        ),
      );

  // Kampanya Görseli: işletmenin kendi fotoğrafı; yoksa hizmet adına göre hazır görsel
  Widget _gorselKarti() {
    final ad = _hizmetId == null ? '' : _hizmetAdi;
    Widget onizleme;
    String aciklama;
    if (_yeniGorsel != null) {
      onizleme = Image.file(File(_yeniGorsel!), fit: BoxFit.cover);
      aciklama = 'Seçtiğiniz fotoğraf kaydedince yüklenecek.';
    } else if (_mevcutGorsel != null && !_gorselKaldir) {
      onizleme = Image.network('https://app.randevumcepte.com.tr$_mevcutGorsel', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(ikramHazirGorsel(ad), fit: BoxFit.cover));
      aciklama = 'Kendi fotoğrafınız kullanılıyor.';
    } else {
      onizleme = Image.asset(ikramHazirGorsel(ad), fit: BoxFit.cover);
      aciklama = 'Otomatik: hizmete uygun hazır görsel. Kendi fotoğrafınızı da yükleyebilirsiniz.';
    }
    final kendi = _yeniGorsel != null || (_mevcutGorsel != null && !_gorselKaldir);
    return _kart(
      child: Column(children: [
        _kartBaslik(Icons.image_rounded, 'Kampanya Görseli', 'Kampanya kartında görünecek fotoğraf.'),
        const SizedBox(height: 12),
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 92,
              height: 92,
              // Kampanya kartındaki gibi köşede "N+1" etiketi
              child: Stack(children: [
                Positioned.fill(child: onizleme),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(14), topLeft: Radius.circular(16)),
                    ),
                    child: Text('$_adet+$_hediye',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(aciklama, style: const TextStyle(fontSize: 12, height: 1.35, color: _soluk)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _kucukDugme(Icons.photo_library_rounded, kendi ? 'Değiştir' : 'Fotoğraf Seç', _gorselSec, dolu: true),
                if (kendi)
                  _kucukDugme(Icons.close_rounded, 'Kaldır', () => setState(() {
                        _yeniGorsel = null;
                        _gorselKaldir = true;
                      })),
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _kucukDugme(IconData ikon, String yazi, VoidCallback onTap, {bool dolu = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: dolu ? _mor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dolu ? _mor : const Color(0xFFE2D4F8)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ikon, size: 16, color: dolu ? Colors.white : _morKoyu),
            const SizedBox(width: 5),
            Text(yazi, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: dolu ? Colors.white : _morKoyu)),
          ]),
        ),
      );

  Future<void> _gorselSec() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1400, imageQuality: 85);
      if (f != null && mounted) {
        setState(() {
          _yeniGorsel = f.path;
          _gorselKaldir = false;
        });
      }
    } catch (_) {
      _mesaj('Fotoğraf seçilemedi', hata: true);
    }
  }

  // Geçerlilik Süresi
  Widget _gecerlilikKarti() {
    // Başlangıç seçilmediyse kampanya kaydedildiği gün başlar
    final aralik = '${_tarih(_bas ?? _bugun)}  -  ${_bit != null ? _tarih(_bit!) : 'Süresiz'}';
    return _kart(
      child: Column(children: [
        _kartBaslik(Icons.calendar_month_rounded, 'Geçerlilik Süresi', 'Kampanyanın ne kadar süreyle geçerli olacağını belirleyin.'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _tarihSec,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE2D4F8)),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_month_rounded, color: _mor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(aralik, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _koyu)),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: _koyu),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const SizedBox(width: 6),
          const Icon(Icons.hourglass_bottom_rounded, color: _soluk, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Kazanılan hakkın kullanım süresi',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _koyu)),
          ),
          _secimKutusu(_sureYazi(_sureDeger, _sureBirim), _sureSec),
        ]),
      ]),
    );
  }

  String _sureYazi(int d, String b) => d <= 0 ? 'Süresiz' : '$d ${b == 'gun' ? 'gün' : 'ay'}';

  // Kampanyayı Aktif Et
  Widget _aktifKarti() => _kart(
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        child: Row(children: [
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: _aktif,
              activeThumbColor: Colors.white,
              activeTrackColor: _mor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFD9CCEE),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              onChanged: (v) => setState(() => _aktif = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Kampanyayı Aktif Et', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _koyu)),
              Text(
                _aktif ? 'Kampanya hemen aktif olsun.' : 'Kampanya kapalı; ziyaretler sayılmaya devam eder, hak kullandırılmaz.',
                style: const TextStyle(fontSize: 11.5, color: _soluk),
              ),
            ]),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.7)),
            child: const Icon(Icons.auto_awesome_rounded, color: _mor, size: 22),
          ),
        ]),
      );

  Widget _kaydetDugmesi() => Center(
        child: GestureDetector(
          onTap: _kaydediyor ? null : _kaydet,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF7C3AED), Color(0xFF5B21B6)]),
              boxShadow: [BoxShadow(color: _morKoyu.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            alignment: Alignment.center,
            child: _kaydediyor
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Row(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(radius: 15, backgroundColor: Colors.white, child: Icon(Icons.check_rounded, color: _morKoyu, size: 20)),
                    SizedBox(width: 12),
                    Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  ]),
          ),
        ),
      );

  // ---------------------------------------------------------------- seçiciler

  Future<T?> _listeSec<T>(String baslik, List<T> secenekler, T mevcut, String Function(T) yazi) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(baslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _koyu)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: secenekler
                  .map((s) => ListTile(
                        title: Text(yazi(s), style: const TextStyle(color: _koyu, fontWeight: FontWeight.w600)),
                        trailing: s == mevcut ? const Icon(Icons.check_circle_rounded, color: _mor) : null,
                        onTap: () => Navigator.pop(c, s),
                      ))
                  .toList(),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _hizmetSec() async {
    final aramaCtrl = TextEditingController();
    final secilen = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => StatefulBuilder(builder: (c, setSt) {
        final q = aramaCtrl.text.trim().toLowerCase();
        final liste = _hizmetler
            .where((h) => q.isEmpty || (h['hizmet_adi'] ?? '').toString().toLowerCase().contains(q))
            .toList();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(c).size.height * 0.7,
            child: Column(children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Hizmet seçin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _koyu)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: aramaCtrl,
                  onChanged: (_) => setSt(() {}),
                  decoration: InputDecoration(
                    hintText: 'Hizmet ara',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF5F0FC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              Expanded(
                child: liste.isEmpty
                    ? const Center(child: Text('Hizmet bulunamadı', style: TextStyle(color: _soluk)))
                    : ListView.builder(
                        itemCount: liste.length,
                        itemBuilder: (_, i) {
                          final id = (liste[i]['id'] as num).toInt();
                          return ListTile(
                            title: Text((liste[i]['hizmet_adi'] ?? '').toString(),
                                style: const TextStyle(color: _koyu, fontWeight: FontWeight.w600)),
                            trailing: id == _hizmetId ? const Icon(Icons.check_circle_rounded, color: _mor) : null,
                            onTap: () => Navigator.pop(c, id),
                          );
                        },
                      ),
              ),
            ]),
          ),
        );
      }),
    );
    if (secilen != null) setState(() => _hizmetId = secilen);
  }

  Future<void> _tarihSec() async {
    final secim = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('Kampanya tarihleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _koyu)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Yalnız bu aralıkta gelinen ziyaretler sayılır. Kazanılan hak kampanya bitince de kullanılabilir.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _soluk)),
          ),
          ListTile(
            leading: const Icon(Icons.date_range_rounded, color: _mor),
            title: const Text('Tarih aralığı seç', style: TextStyle(fontWeight: FontWeight.w700, color: _koyu)),
            onTap: () => Navigator.pop(c, 'aralik'),
          ),
          ListTile(
            leading: const Icon(Icons.all_inclusive_rounded, color: _mor),
            title: const Text('Bitiş tarihi olmasın (süresiz)', style: TextStyle(fontWeight: FontWeight.w700, color: _koyu)),
            onTap: () => Navigator.pop(c, 'suresiz'),
          ),
        ]),
      ),
    );
    if (!mounted || secim == null) return;
    if (secim == 'suresiz') {
      setState(() => _bit = null);
      return;
    }
    // Başlangıç geçmişe alınamaz (geçmiş randevulara ikram dağıtılmaz); mevcut başlangıç korunabilir
    final ilk = _bas != null && _bas!.isBefore(_bugun) ? DateTime(_bas!.year, _bas!.month, _bas!.day) : _bugun;
    final basVars = _bas != null && !_bas!.isBefore(ilk) ? _bas! : _bugun;
    final aralik = await showDateRangePicker(
      context: context,
      firstDate: ilk,
      lastDate: DateTime(_bugun.year + 5),
      initialDateRange: DateTimeRange(
        start: DateTime(basVars.year, basVars.month, basVars.day),
        end: _bit != null && !_bit!.isBefore(basVars) ? _bit! : DateTime(basVars.year, basVars.month, basVars.day).add(const Duration(days: 30)),
      ),
      helpText: 'Kampanya tarihleri',
      saveText: 'Tamam',
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(colorScheme: Theme.of(c).colorScheme.copyWith(primary: _mor)),
        child: child!,
      ),
    );
    if (aralik != null) setState(() {
      _bas = aralik.start;
      _bit = aralik.end;
    });
  }

  Future<void> _sureSec() async {
    final secenekler = <String>['0|ay', '15|gun', '30|gun', '2|ay', '3|ay', '6|ay', '12|ay'];
    final mevcut = _sureDeger <= 0 ? '0|ay' : '$_sureDeger|$_sureBirim';
    if (!secenekler.contains(mevcut)) secenekler.insert(1, mevcut);
    final v = await _listeSec<String>('Kazanılan hakkın kullanım süresi', secenekler, mevcut, (s) {
      final p = s.split('|');
      return _sureYazi(int.parse(p[0]), p[1]);
    });
    if (v == null) return;
    final p = v.split('|');
    setState(() {
      _sureDeger = int.parse(p[0]);
      _sureBirim = p[1];
    });
  }

  void _bilgiGoster() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kampanya nasıl çalışır?', style: TextStyle(fontWeight: FontWeight.w800, color: _koyu)),
        content: const SingleChildScrollView(
          child: Text(
            '• X + 1: Müşteri seçtiğiniz hizmeti belirlediğiniz adet kadar ücretli alınca hediye hizmet kazanır.\n'
            '• Yüzde indirim kampanyaları için Kampanyalar bölümünü kullanın.\n\n'
            '• Sayım "Geldi" işaretli ücretli randevulara göre yapılır; paket/seanslı satış ve telafi seansları sayılmaz.\n'
            '• Yalnız kampanya tarihleri içindeki ziyaretler sayılır; geçmiş randevulara dağıtılmaz.\n'
            '• Müşteri kazandığını uygulamasında görür, ne zaman kullanacağına kendisi karar verir. '
            'Kullanmak istediğinde tahsilat ekranından işlenir.\n'
            '• Kullanım süresi seçerseniz hak, kazanıldığı günden itibaren o süre içinde kullanılmazsa düşer.\n'
            '• Kampanyayı kapatıp açmak müşterilerin ilerlemesini silmez.',
            style: TextStyle(fontSize: 13, height: 1.45, color: _koyu),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam', style: TextStyle(color: _mor))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- kayıt

  Future<void> _kaydet() async {
    if (_hizmetId == null) {
      _mesaj('Lütfen kampanyanın hizmetini seçin', hata: true);
      return;
    }
    setState(() => _kaydediyor = true);
    final veri = <String, dynamic>{
      if (widget.mevcut != null) 'id': widget.mevcut!['id'],
      'hizmet_id': _hizmetId,
      'tur': 'ikram',
      'gereken_adet': _adet,
      'ucretsiz_adet': _hediye,
      'aktif': _aktif ? 1 : 0,
      'gecerlilik_deger': _sureDeger,
      'gecerlilik_birim': _sureBirim,
      'baslangic_tarihi': _bas != null ? _ymd(_bas!) : '',
      'bitis_tarihi': _bit != null ? _ymd(_bit!) : '',
    };
    var r = await carkAdminDamgaKartiKaydet(widget.salonId, veri);
    if (!mounted) return;
    // Sayılmış ziyareti olan kuralda adet/hizmet/tarih değişiyor: etkisini gösterip onay al
    if (r != null && r['onay_gerekli'] == true) {
      final mesaj = r['mesaj']?.toString() ?? '';
      final evet = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Müşteriler etkilenecek', style: TextStyle(fontWeight: FontWeight.w800, color: _koyu)),
          content: Text(mesaj),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
            ElevatedButton(
              onPressed: () => Navigator.pop(d, true),
              style: ElevatedButton.styleFrom(backgroundColor: _mor, foregroundColor: Colors.white),
              child: const Text('Evet, kaydet'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (evet != true) {
        setState(() => _kaydediyor = false);
        return;
      }
      r = await carkAdminDamgaKartiKaydet(widget.salonId, {...veri, 'onay': 1});
      if (!mounted) return;
    }
    if (r != null && r['basarili'] == true) {
      // Görsel: kural kaydedildikten sonra (yeni kuralda id yanıttan gelir)
      final id = (r['id'] as num?)?.toInt() ?? (widget.mevcut?['id'] as num?)?.toInt();
      if (id != null && (_yeniGorsel != null || (_gorselKaldir && _mevcutGorsel != null))) {
        final g = await ikramKampanyaGorsel(widget.salonId, id, dosyaYolu: _yeniGorsel, sil: _yeniGorsel == null);
        if (!mounted) return;
        if (g == null || g['basarili'] != true) {
          _mesaj('Kampanya kaydedildi ama görsel yüklenemedi: ${g?['mesaj'] ?? 'bağlantı hatası'}', hata: true);
        }
      }
      if (!mounted) return;
      setState(() => _kaydediyor = false);
      Navigator.pop(context, true);
      return;
    }
    setState(() => _kaydediyor = false);
    _mesaj(r?['mesaj']?.toString() ?? 'Kaydedilemedi', hata: true);
  }
}
