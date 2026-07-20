import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/theme/logo_renk.dart';

import 'package:randevu_sistem/randevualma/randevual.dart';
import 'login_page.dart';

/// Açılış / tanıtım ekranı.
/// Arka plandaki sabit video yerine, salonun kendi logosunu (images/eymlife.png)
/// kullanan otomatik animasyonlu bir sahne gösterilir: beyaz zemin + efekt çizgiler +
/// dönen ışınlar + nabız gibi atan halkalar + süzülen ışık topları + ortada logo.
class OnBoardingPage extends StatefulWidget {
  @override
  _OnBoardingPageState createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage>
    with TickerProviderStateMixin {
  // Animasyon kontrolcüleri
  late final AnimationController _pulseCtrl; // halka nabzı
  late final AnimationController _rayCtrl; // dönen ışın çizgileri
  late final AnimationController _lineCtrl; // süzülen diyagonal çizgiler
  late final AnimationController _orbCtrl; // ışık toplarının süzülmesi
  late final AnimationController _logoInCtrl; // logo giriş animasyonu
  late final AnimationController _logoFloatCtrl; // logo süzülmesi

  bool _onlineRandevuAktif = false;
  bool _lisansAktif = true; // lisans bittiyse 'Randevu Al' gizlenir
  // Beyaz etiket kurulumda jenerik "RandevumCepte" yazip sonra isletme adina
  // atlamamak icin bos baslar; en son bilinen ad SharedPreferences'tan aninda
  // yazilir, ag cevabi gelince guncellenir ve yeniden onbellege alinir.
  String _salonAdi = '';
  static const String _salonAdiCacheKey = 'tanitim_salon_adi';

  // Logo yolu — beyaz etiket build'de salon logosuna göre bu tek satır değişir.
  // Palet ve ekrandaki logo aynı görselden gelir.
  static const String _logoYolu = 'images/eymlife.png';
  LogoPalet _palet = LogoPalet.varsayilan; // logodan türetilen renkler

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);

    _rayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();

    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _logoInCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _logoFloatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _loadCachedSalonAdi();
    _loadOnlineRandevuAyari();
    _renkleriYukle();
  }

  /// Logodan renk paletini çıkar; animasyon salon renklerine boyanır.
  Future<void> _renkleriYukle() async {
    final palet = await LogoPalet.logodanUret(const AssetImage(_logoYolu));
    if (!mounted) return;
    setState(() => _palet = palet);
  }

  /// Ag cevabini beklemeden en son bilinen isletme adini goster (yanip sonme olmasin).
  Future<void> _loadCachedSalonAdi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ad = (prefs.getString(_salonAdiCacheKey) ?? '').trim();
      if (!mounted || ad.isEmpty) return;
      setState(() => _salonAdi = ad);
    } catch (_) {}
  }

  Future<void> _loadOnlineRandevuAyari() async {
    try {
      final bundle = await appBundleAl();
      final ayar = await salonAyarlariByBundle(bundle);
      if (!mounted) return;
      final ad = (ayar['salon_adi'] ?? '').toString().trim();
      if (ad.isNotEmpty) {
        // Bir sonraki acilista aninda gosterebilmek icin onbellege al.
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_salonAdiCacheKey, ad);
        } catch (_) {}
        if (!mounted) return;
      }
      setState(() {
        _onlineRandevuAktif = musteriOnlineRandevuAktifMi(ayar);
        // Lisans bittiyse (lisans_aktif != 1) randevu al butonu gizlenir.
        final la = ayar is Map ? ayar['lisans_aktif'] : null;
        _lisansAktif = la == null || la == 1 || la.toString() == '1';
        if (ad.isNotEmpty) _salonAdi = ad;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _onlineRandevuAktif = false);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rayCtrl.dispose();
    _lineCtrl.dispose();
    _orbCtrl.dispose();
    _logoInCtrl.dispose();
    _logoFloatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // direkt çıkışı engelle
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          bool? confirmExit = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Uygulamadan çık'),
              content: const Text('Çıkmak istediğinize emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Hayır'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Evet'),
                ),
              ],
            ),
          );
          if (confirmExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.28),
              radius: 1.15,
              colors: [
                Colors.white,
                Color.alphaBlend(
                    _palet.birincil.withOpacity(0.06), Colors.white),
                Color.alphaBlend(
                    _palet.birincil.withOpacity(0.14), Colors.white),
                Color.alphaBlend(
                    _palet.birincil.withOpacity(0.22), Colors.white),
              ],
              stops: const [0.0, 0.4, 0.72, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                // ===== Üst: Animasyonlu logo sahnesi =====
                Expanded(
                  child: ClipRect(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Efekt çizgiler + ışınlar + halkalar + ışık topları
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _EfektSahnePainter(
                              ray: _rayCtrl,
                              line: _lineCtrl,
                              pulse: _pulseCtrl,
                              orb: _orbCtrl,
                              birincil: _palet.birincil,
                              ikincil: _palet.ikincil,
                            ),
                          ),
                        ),
                        // Ortada salon logosu (giriş + süzülme animasyonu)
                        AnimatedBuilder(
                          animation:
                              Listenable.merge([_logoInCtrl, _logoFloatCtrl]),
                          builder: (context, child) {
                            final entrance =
                                Curves.easeOutCubic.transform(_logoInCtrl.value);
                            final floatY = -12 *
                                Curves.easeInOut.transform(_logoFloatCtrl.value);
                            return Opacity(
                              opacity: entrance,
                              child: Transform.translate(
                                offset: Offset(0, floatY),
                                child: Transform.scale(
                                  scale: 0.85 + 0.15 * entrance,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            // Sabit yükseklik yerine ortak sahne kutusu: geniş
                            // (yatay) logolar genişliği, kare/dikey logolar
                            // yüksekliği doldurur; hepsi tutarlı biçimde oturur.
                            child: SizedBox(
                              width: 300,
                              height: 190,
                              child: Image.asset(
                                _logoYolu,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== Alt: Salon adı + açıklama + butonlar =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _salonAdi,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            color: _palet.koyu,
                            fontSize: 32.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Randevularınızı kolayca oluşturun ve takip edin.\nSize özel kampanyalardan haberdar olun, tüm güzellik işlemlerinizi tek uygulamadan yönetin.',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(
                                      randevuSayfasinaYonlendir: false,
                                      seciliHizmetler: [],
                                      tarih: '',
                                      saat: '',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _palet.koyu,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                minimumSize: const Size(0, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Kullanıcı Girişi',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          if (_onlineRandevuAktif && _lisansAktif) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RandevuAl(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(width: 2.0, color: _palet.koyu),
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Randevu Al',
                                  style: TextStyle(
                                    color: _palet.koyu,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Beyaz zemin üzerinde: süzülen diyagonal çizgiler, merkezden yayılan dönen
/// ışınlar, nabız gibi atan iki halka ve bulanık ışık topları çizer.
class _EfektSahnePainter extends CustomPainter {
  final Animation<double> ray;
  final Animation<double> line;
  final Animation<double> pulse;
  final Animation<double> orb;
  final Color birincil;
  final Color ikincil;

  _EfektSahnePainter({
    required this.ray,
    required this.line,
    required this.pulse,
    required this.orb,
    required this.birincil,
    required this.ikincil,
  }) : super(repaint: Listenable.merge([ray, line, pulse, orb]));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final lila = Color.lerp(birincil, Colors.white, 0.25) ?? birincil;

    // 1) Süzülen ince diyagonal çizgiler
    const spacing = 28.0;
    final lineOffset = line.value * spacing;
    final linePaint = Paint()
      ..color = birincil.withOpacity(0.07)
      ..strokeWidth = 1.0;
    final diag = size.width + size.height;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(118 * math.pi / 180);
    for (double x = -diag; x < diag; x += spacing) {
      final xx = x + lineOffset;
      canvas.drawLine(Offset(xx, -diag), Offset(xx, diag), linePaint);
    }
    canvas.restore();

    // 2) Merkezden yayılan, yavaşça dönen ışın çizgileri
    const rayCount = 24;
    const rInner = 22.0;
    // Işınlar köşelere kadar ulaşsın (merkez-köşe mesafesi) — köşelerde beyaz kalmasın.
    final rOuter =
        math.sqrt(center.dx * center.dx + center.dy * center.dy) * 1.02;
    final rayPaint = Paint()
      ..color = birincil.withOpacity(0.08)
      ..strokeWidth = 1.4;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(ray.value * 2 * math.pi);
    for (int i = 0; i < rayCount; i++) {
      final a = (i / rayCount) * 2 * math.pi;
      final c = math.cos(a);
      final s = math.sin(a);
      canvas.drawLine(
        Offset(c * rInner, s * rInner),
        Offset(c * rOuter, s * rOuter),
        rayPaint,
      );
    }
    canvas.restore();

    // 3) Bulanık ışık topları (süzülür)
    final oy = math.sin(orb.value * 2 * math.pi) * 16;
    const orbBlur = MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(
      Offset(size.width * 0.20, size.height * 0.24 + oy),
      58,
      Paint()
        ..color = ikincil.withOpacity(0.22)
        ..maskFilter = orbBlur,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.72 - oy),
      46,
      Paint()
        ..color = birincil.withOpacity(0.20)
        ..maskFilter = orbBlur,
    );

    // 4) Nabız gibi atan halkalar
    final p = pulse.value; // 0..1
    final scale = 1 + 0.12 * p;
    final ring1r = 116.0 * scale;
    final ring2r = 150.0 * scale;

    // Dış halka (ikincil)
    canvas.drawCircle(
      center,
      ring2r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ikincil.withOpacity(0.18 + 0.16 * p),
    );
    // İç halkanın hafif ışıması
    canvas.drawCircle(
      center,
      ring1r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = lila.withOpacity(0.16 * p)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // İç halka (birincil)
    canvas.drawCircle(
      center,
      ring1r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = birincil.withOpacity(0.30 + 0.25 * p),
    );
  }

  @override
  bool shouldRepaint(covariant _EfektSahnePainter oldDelegate) =>
      oldDelegate.birincil != birincil || oldDelegate.ikincil != ikincil;
}
