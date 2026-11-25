import 'dart:math' as math;

import 'package:randevu_sistem/dil/material.dart';

import 'package:randevu_sistem/musteripaneli/anasayfa/yavas_dongu.dart';

/// Ana sayfa çark kartındaki 3B çark: gövde, göbek ve ok tasarımdan kesilmiş görseldir (240x250),
/// dilimler çarkın eğik yüzüne oturan elips içinde yavaşça döner, çerçeve ışıkları yanıp söner.
class DonenCark extends StatefulWidget {
  /// Gövdenin rengini temaya çevirir; dilimler canlı kalır
  final ColorFilter filtre;
  const DonenCark({super.key, required this.filtre});

  @override
  State<DonenCark> createState() => _DonenCarkState();
}

class _DonenCarkState extends State<DonenCark> with YavasDongu {
  @override
  Duration get donguSuresi => const Duration(seconds: 30);

  @override
  Widget build(BuildContext context) {
    Widget gorsel(String ad) => Positioned.fill(
          child: ColorFiltered(colorFilter: widget.filtre, child: Image.asset('images/$ad.png', fit: BoxFit.fill)),
        );
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 240 / 250,
        child: Stack(children: [
          gorsel('musteri_cark3d'),
          Positioned.fill(child: CustomPaint(painter: _DilimBoyaci(dongu))),
          gorsel('musteri_cark_gobek'),
          gorsel('musteri_cark_ok'),
          Positioned.fill(child: CustomPaint(painter: _IsikBoyaci(dongu))),
        ]),
      ),
    );
  }
}

class _DilimBoyaci extends CustomPainter {
  final ValueNotifier<double> t;
  _DilimBoyaci(this.t) : super(repaint: t);

  // Yüz elipsi (240x250 görsel koordinatı): birim çember -> elips simetrik matrisi
  static const _mx = 130.84, _my = 121.54;
  static const _a = 88.24, _b = 11.37, _d = 99.13;
  // Göbek perspektif yüzünden yüz merkezinin sağındadır; dilimler oradan açılır
  static const _gx = 182.4 - 40 - _mx, _gy = 707.4 - 588 - _my;

  static const _renkler = [
    Color(0xFFF6B443),
    Color(0xFFFF2CCB),
    Color(0xFFFF9FE0),
    Color(0xFF8B1FF6),
    Color(0xFFFFAE5C),
    Color(0xFF2468F2),
    Color(0xFFDE74FA),
    Color(0xFFF91FC4),
    Color(0xFFF6B443),
    Color(0xFF6A43F0),
    Color(0xFFE99BFC),
    Color(0xFF2468F2),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    canvas.scale(s.width / 240, s.height / 250);
    canvas.translate(_mx, _my);

    // Göbek merkezi birim çemberde
    const det = _a * _d - _b * _b;
    const ux = (_d * _gx - _b * _gy) / det, uy = (_a * _gy - _b * _gx) / det;
    final k = math.sqrt(ux * ux + uy * uy);
    final yon = math.atan2(uy, ux);
    final kok = math.sqrt(1 - k * k);
    Offset elips(double x, double y) => Offset(_a * x + _b * y, _b * x + _d * y);
    // Çemberi koruyan izdüşüm: merkez göbeğe kayar, doğrular doğru kalır
    Offset nokta(double aci, double r) {
      final x = r * math.cos(aci - yon), y = r * math.sin(aci - yon), p = 1 + k * x;
      final X = (x + k) / p, Y = y * kok / p;
      return elips(X * math.cos(yon) - Y * math.sin(yon), X * math.sin(yon) + Y * math.cos(yon));
    }

    final sinir = Path()..addPolygon([for (var i = 0; i < 96; i++) nokta(i * math.pi / 48, 1)], true);
    canvas.save();
    canvas.clipPath(sinir);
    final don = t.value * 2 * math.pi;
    final n = _renkler.length, dilim = 2 * math.pi / n;
    final kutu = sinir.getBounds();
    final merkez = nokta(0, 0);
    for (var i = 0; i < n; i++) {
      final bas = don + i * dilim;
      final yol = Path()..moveTo(merkez.dx, merkez.dy);
      for (var j = 0; j <= 8; j++) {
        final q = nokta(bas + dilim * j / 8, 1.02);
        yol.lineTo(q.dx, q.dy);
      }
      yol.close();
      final renk = _renkler[i];
      canvas.drawPath(
        yol,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(merkez.dx / (kutu.width / 2), merkez.dy / (kutu.height / 2)),
            radius: 0.62,
            colors: [Color.lerp(renk, Colors.black, 0.22)!, renk, Color.lerp(renk, Colors.white, 0.10)!],
            stops: const [0.2, 0.62, 1],
          ).createShader(kutu),
      );
      // Dilim ortasında küçük parıltı
      final o = nokta(bas + dilim / 2, 0.76);
      final w = nokta(bas + dilim / 2, 0.83) - o;
      final yan = Offset(-w.dy, w.dx);
      canvas.drawPath(
        Path()
          ..moveTo(o.dx + w.dx, o.dy + w.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx + yan.dx, o.dy + yan.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx - w.dx, o.dy - w.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx - yan.dx, o.dy - yan.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx + w.dx, o.dy + w.dy)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
    final cizgi = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..strokeWidth = 1.3;
    for (var i = 0; i < n; i++) {
      canvas.drawLine(merkez, nokta(don + i * dilim, 1.02), cizgi);
    }
    // Sabit cam parlaması (dönmez; derinlik hissi)
    canvas.drawRect(
      kutu,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0), Colors.black.withValues(alpha: 0.12)],
          stops: const [0, 0.45, 1],
        ).createShader(kutu),
    );
    canvas.restore();
    canvas.drawPath(
        sinir,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = Colors.white.withValues(alpha: 0.95));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DilimBoyaci e) => false;
}

/// Çerçevedeki ampuller: sırayla hafifçe parlar
class _IsikBoyaci extends CustomPainter {
  final ValueNotifier<double> t;
  _IsikBoyaci(this.t) : super(repaint: t);

  // Tasarımdaki ampul yerleri (240x250 görsel koordinatı)
  static const _ampuller = [
    (73.0, 22.5), (49.0, 45.5), (37.3, 78.3), (38.5, 118.8), (55.3, 163.8), (78.5, 191.3), (126.0, 222.5), //
    (164.8, 226.3), (194.8, 216.3), (215.5, 195.0), (226.0, 165.0), (226.5, 130.0), (219.3, 100.5), (186.8, 50.8), (162.3, 32.5),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    canvas.scale(s.width / 240, s.height / 250);
    for (var i = 0; i < _ampuller.length; i++) {
      final (x, y) = _ampuller[i];
      // Tam tur sayısı tam sayı: döngü dikişsiz
      final g = 0.5 + 0.5 * math.sin(t.value * 2 * math.pi * 12 + i * math.pi);
      final m = Offset(x, y);
      canvas.drawCircle(
        m,
        9,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: 0.85 * g),
            const Color(0xFFFFF1C9).withValues(alpha: 0.45 * g),
            const Color(0x00FFF1C9),
          ], stops: const [
            0,
            0.35,
            1
          ]).createShader(Rect.fromCircle(center: m, radius: 9)),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IsikBoyaci e) => false;
}
