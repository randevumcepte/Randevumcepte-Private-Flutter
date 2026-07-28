// Açılış (tanıtım) ekranının animasyonunu TELEFON BOYUTUNDA hızlıca görmek için
// KENDİ KENDİNE YETEN önizleme. Uygulamanın backend/login grafiğini import ETMEZ;
// sadece flutter + palette_generator + theme/logo_renk.dart'a bağlıdır. Böylece
// proje başka yerde derlenmese bile animasyon görülebilir.
//
// Çalıştırmak için:
//   flutter run -d chrome --web-port 8090 -t "lib/Login Sayfası/tanitim_onizleme.dart"
//
// NOT: Görsel + renk mantığı tanitim.dart ile aynıdır; burada butonlar statiktir.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:randevu_sistem/theme/logo_renk.dart';

void main() {
  runApp(const _OnizlemeApp());
}

class _OnizlemeApp extends StatelessWidget {
  const _OnizlemeApp();

  @override
  Widget build(BuildContext context) {
    const Size telefonBoyut = Size(390, 844);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tanıtım Önizleme',
      home: Scaffold(
        backgroundColor: const Color(0xFF201033),
        body: Center(
          // Telefon çerçevesi pencereye her zaman tam sığsın (küçülerek).
          child: FittedBox(
            fit: BoxFit.contain,
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B12),
                borderRadius: BorderRadius.circular(46),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black54, blurRadius: 50, spreadRadius: 6),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: SizedBox(
                  width: telefonBoyut.width,
                  height: telefonBoyut.height,
                  child: const MediaQuery(
                    data: MediaQueryData(
                      size: telefonBoyut,
                      devicePixelRatio: 3.0,
                      padding: EdgeInsets.only(top: 47, bottom: 24),
                    ),
                    child: _TanitimOnizlemeEkrani(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// tanitim.dart'taki animasyonlu sahnenin bağımsız kopyası (sadece görsel).
class _TanitimOnizlemeEkrani extends StatefulWidget {
  const _TanitimOnizlemeEkrani();

  @override
  State<_TanitimOnizlemeEkrani> createState() => _TanitimOnizlemeEkraniState();
}

class _TanitimOnizlemeEkraniState extends State<_TanitimOnizlemeEkrani>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _rayCtrl;
  late final AnimationController _lineCtrl;
  late final AnimationController _orbCtrl;
  late final AnimationController _logoInCtrl;
  late final AnimationController _logoFloatCtrl;

  LogoPalet _palet = LogoPalet.varsayilan;

  // Önizlemede farklı logoların renklere yansımasını görmek için demo listesi.
  final List<Map<String, String>> _demoLogolar = const [
    {'logo': 'images/aleyna.png', 'ad': 'Aleyna Güzellik Salonu'},
    {'logo': 'images/randevumcepte.png', 'ad': 'RandevumCepte'},
    {'logo': 'images/giza.png', 'ad': 'Giza'},
    {'logo': 'images/aronshine.png', 'ad': 'Aron Shine'},
    {'logo': 'images/aydangurece.png', 'ad': 'Aydan Gürece'},
  ];
  int _logoIndex = 0;

  String get _aktifLogo => _demoLogolar[_logoIndex]['logo']!;
  String get _salonAdi => _demoLogolar[_logoIndex]['ad']!;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2100))
      ..repeat(reverse: true);
    _rayCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 45))
      ..repeat();
    _lineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
    _logoInCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
    _logoFloatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _renkleriYukle();
  }

  Future<void> _renkleriYukle() async {
    final palet = await LogoPalet.logodanUret(AssetImage(_aktifLogo));
    if (!mounted) return;
    setState(() => _palet = palet);
  }

  void _sonrakiLogo() {
    setState(() {
      _logoIndex = (_logoIndex + 1) % _demoLogolar.length;
      _palet = LogoPalet.varsayilan; // yeni renkler gelene kadar geçici
    });
    _renkleriYukle();
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.28),
            radius: 1.15,
            colors: [
              Colors.white,
              Color.alphaBlend(_palet.birincil.withOpacity(0.06), Colors.white),
              Color.alphaBlend(_palet.birincil.withOpacity(0.14), Colors.white),
              Color.alphaBlend(_palet.birincil.withOpacity(0.22), Colors.white),
            ],
            stops: const [0.0, 0.4, 0.72, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: ClipRect(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
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
                      AnimatedBuilder(
                        animation: Listenable.merge([_logoInCtrl, _logoFloatCtrl]),
                        builder: (context, child) {
                          final entrance =
                              Curves.easeOutCubic.transform(_logoInCtrl.value);
                          final floatY =
                              -12 * Curves.easeInOut.transform(_logoFloatCtrl.value);
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
                          child: SizedBox(
                            width: 300,
                            height: 190,
                            child: Image.asset(_aktifLogo, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      // Önizleme: logoyu değiştir (renkler otomatik güncellenir)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: _palet.koyu.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _sonrakiLogo,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.palette_outlined,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text('Logo değiştir',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _palet.koyu,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Kullanıcı Girişi',
                                style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(width: 2.0, color: _palet.koyu),
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Randevu Al',
                                style: TextStyle(color: _palet.koyu, fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

    const rayCount = 24;
    const rInner = 22.0;
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

    final p = pulse.value;
    final scale = 1 + 0.12 * p;
    final ring1r = 116.0 * scale;
    final ring2r = 150.0 * scale;

    canvas.drawCircle(
      center,
      ring2r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ikincil.withOpacity(0.18 + 0.16 * p),
    );
    canvas.drawCircle(
      center,
      ring1r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = lila.withOpacity(0.16 * p)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
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
