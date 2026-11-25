import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:randevu_sistem/musteripaneli/anasayfa/yavas_dongu.dart';
import 'package:randevu_sistem/marka.dart';
import 'package:randevu_sistem/theme/musteri_palet.dart';

/// Müşteri ana sayfası üst efekti: ipeksi ışık dalgaları, ortada salon logosu ve etrafında dönen
/// ışık halkaları. Renkler salonun temasından gelir (cinsiyetsiz, kişi görseli yok).
class MarkaIsikEfekti extends StatefulWidget {
  /// Logonun merkezi ve yarıçapı (widget koordinatında)
  final Offset merkez;
  final double yaricap;
  const MarkaIsikEfekti({super.key, required this.merkez, required this.yaricap});

  @override
  State<MarkaIsikEfekti> createState() => _MarkaIsikEfektiState();
}

class _MarkaIsikEfektiState extends State<MarkaIsikEfekti> with YavasDongu {
  @override
  Duration get donguSuresi => const Duration(seconds: 18);

  @override
  Widget build(BuildContext context) {
    final p = MusteriPalet.of(context);
    final r = widget.yaricap;
    return RepaintBoundary(
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _IsikBoyaci(dongu, p, widget.merkez, r))),
        Positioned(
          left: widget.merkez.dx - r * 0.62,
          top: widget.merkez.dy - r * 0.62,
          width: r * 1.24,
          height: r * 1.24,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: r * 0.05),
              boxShadow: [BoxShadow(color: p.ana.withValues(alpha: 0.28), blurRadius: r * 0.34, offset: Offset(0, r * 0.1))],
            ),
            child: ClipOval(child: Image.asset(Marka.logo, fit: BoxFit.contain)),
          ),
        ),
      ]),
    );
  }
}

class _IsikBoyaci extends CustomPainter {
  final ValueNotifier<double> t;
  final MusteriPalet p;
  final Offset m;
  final double r;
  _IsikBoyaci(this.t, this.p, this.m, this.r) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size s) {
    final a = t.value * 2 * math.pi;
    final isik = p.koyuMod ? p.ana : Colors.white;

    // Zemin: temanın çok açık tonu
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(p.ana.withValues(alpha: p.koyuMod ? 0.10 : 0.07), p.zemin),
            Color.alphaBlend(p.ana.withValues(alpha: p.koyuMod ? 0.26 : 0.20), p.zemin),
            p.zemin,
          ],
          stops: const [0, 0.62, 1],
        ).createShader(Offset.zero & s),
    );

    // İpeksi dalgalar
    for (var i = 0; i < 4; i++) {
      final y0 = s.height * (0.42 + i * 0.14);
      final yol = Path()..moveTo(0, y0);
      for (var x = 0.0; x <= s.width + 8; x += 8) {
        final k = x / s.width;
        yol.lineTo(
            x, y0 + math.sin(k * 2 * math.pi * (0.8 + i * 0.12) + a + i * 1.3) * s.height * 0.055 - k * s.height * (0.20 - i * 0.03));
      }
      yol
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close();
      canvas.drawPath(
        yol,
        Paint()
          ..shader = LinearGradient(colors: [
            isik.withValues(alpha: 0.05),
            p.ana.withValues(alpha: 0.05 + i * 0.012),
            isik.withValues(alpha: p.koyuMod ? 0.05 : 0.20),
          ]).createShader(Offset.zero & s),
      );
    }

    // Logo arkası parıltı
    canvas.drawCircle(
      m,
      r * 1.9,
      Paint()
        ..shader = RadialGradient(colors: [isik.withValues(alpha: p.koyuMod ? 0.22 : 0.85), isik.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: m, radius: r * 1.9)),
    );

    // Dönen ışık halkaları
    for (var i = 0; i < 3; i++) {
      final yr = r * (0.80 + i * 0.22);
      final rect = Rect.fromCircle(center: m, radius: yr);
      canvas.drawCircle(
          m,
          yr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = p.ana.withValues(alpha: 0.12));
      final bas = a * (i.isEven ? 1 : -1) * (1 + i * 0.0) + i * 2.1;
      canvas.save();
      canvas.translate(m.dx, m.dy);
      canvas.rotate(bas);
      canvas.translate(-m.dx, -m.dy);
      canvas.drawArc(
        rect,
        0,
        math.pi * 1.15,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r * (0.035 - i * 0.007)
          ..shader = SweepGradient(
            colors: [p.ana.withValues(alpha: 0), p.ana.withValues(alpha: 0.75 - i * 0.18), p.ana.withValues(alpha: 0)],
            stops: const [0, 0.5, 0.58],
          ).createShader(rect),
      );
      // Halkadaki ışık noktası
      final ucA = math.pi * 1.12;
      final uc = m + Offset(math.cos(ucA), math.sin(ucA)) * yr;
      canvas.drawCircle(uc, r * 0.035, Paint()..color = p.ana.withValues(alpha: 0.8 - i * 0.2));
      canvas.restore();
    }

    // Süzülen parçacıklar (sabit tohum: her karede aynı yerleşim)
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final x = rnd.nextDouble() * s.width;
      final hiz = 1 + rnd.nextInt(2); // tam tur sayısı: döngü dikişsiz
      final y = ((rnd.nextDouble() - t.value * hiz) % 1.0) * s.height;
      final boy = 0.8 + rnd.nextDouble() * 2.0;
      final yan = 0.5 + 0.5 * math.sin(a * 3 + i * 1.7);
      canvas.drawCircle(
        Offset(x, y),
        boy,
        Paint()..color = (i % 3 == 0 ? p.ana : isik).withValues(alpha: (i % 3 == 0 ? 0.30 : 0.85) * (0.25 + 0.75 * yan)),
      );
    }

    // Alt kenar sayfa zeminine erir
    final alt = Rect.fromLTWH(0, s.height * 0.86, s.width, s.height * 0.14 + 1);
    canvas.drawRect(
      alt,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.zemin.withValues(alpha: 0), p.zemin],
        ).createShader(alt),
    );
  }

  @override
  bool shouldRepaint(covariant _IsikBoyaci e) => e.p.ana != p.ana || e.p.koyuMod != p.koyuMod || e.m != m || e.r != r;
}
