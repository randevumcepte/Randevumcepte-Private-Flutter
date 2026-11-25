import 'dart:math' as math;

import 'package:randevu_sistem/dil/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:randevu_sistem/theme/musteri_palet.dart';

/// Müşteri okunmamış bildirim sayısı (ana sayfa yükler, alt menü rozeti dinler)
final ValueNotifier<int> musteriOkunmamisBildirim = ValueNotifier<int>(0);

class MusteriAltMenuOge {
  final IconData ikon;
  final IconData seciliIkon;
  final String yazi;
  final bool secili;
  final bool rozet;
  final VoidCallback onTap;
  const MusteriAltMenuOge({
    required this.ikon,
    required this.seciliIkon,
    required this.yazi,
    this.secili = false,
    this.rozet = false,
    required this.onTap,
  });
}

/// Müşteri alt menüsü (tasarım 852 px genişlik): hap, ortada + düğmeli daire, kenarlarda orkide.
/// Renkler salonun Görünüm temasından gelir (MusteriPalet). Tam 4 öge alır.
class MusteriAltMenu extends StatelessWidget {
  final List<MusteriAltMenuOge> ogeler;
  final VoidCallback onOrta;

  /// Ana sayfada içerik menünün arkasından geçer; diğer sekmelerde zemin dolu kalır
  final bool saydam;
  const MusteriAltMenu({
    super.key,
    required this.ogeler,
    required this.onOrta,
    this.saydam = false,
  });

  static const _merkezler = [123, 269, 591, 735];

  @override
  Widget build(BuildContext context) {
    final p = MusteriPalet.of(context);
    final alt = MediaQuery.of(context).padding.bottom;
    final w = math.min(MediaQuery.of(context).size.width, 600.0);
    double x(num px) => w * px / 852;
    final zemin = Color.alphaBlend(p.ana.withValues(alpha: p.koyuMod ? 0.10 : 0.14), p.zemin);
    Widget cicek(String ad, {num? sol, num? sag, required num ust, required num en}) => Positioned(
          left: sol == null ? null : x(sol),
          right: sag == null ? null : x(sag),
          top: x(ust),
          width: x(en),
          child: IgnorePointer(
            child: Opacity(
              opacity: p.koyuMod ? 0.7 : 1,
              child: ColorFiltered(colorFilter: p.gorselFiltre, child: Image.asset('images/$ad.png', fit: BoxFit.fitWidth)),
            ),
          ),
        );

    return Container(
      height: x(184) + alt,
      padding: EdgeInsets.only(bottom: alt),
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        color: saydam ? null : zemin,
        // Ana sayfada üst kenar erir; sistem çubuğu payı her durumda dolu kalır
        gradient: saydam
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [zemin.withValues(alpha: 0), zemin, zemin],
                stops: const [0, 0.42, 1],
              )
            : null,
      ),
      child: SizedBox(
        width: w,
        height: x(184),
        child: Stack(clipBehavior: Clip.none, children: [
          cicek('musteri_menu_cicek_sol', sol: 0, ust: -34, en: 112),
          cicek('musteri_menu_cicek_sag', sag: 0, ust: 14, en: 82),
          Positioned.fill(child: CustomPaint(painter: _HapBoyaci(p))),
          for (var i = 0; i < ogeler.length && i < 4; i++)
            Positioned(
              left: x(_merkezler[i] - 73),
              top: x(44),
              width: x(146),
              height: x(122),
              child: _oge(ogeler[i], x, p),
            ),
          Positioned(
            left: x(427 - 70),
            top: x(86 - 70),
            width: x(140),
            height: x(140),
            child: Semantics(
              button: true,
              label: 'Hızlı İşlemler',
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onOrta),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _oge(MusteriAltMenuOge o, double Function(num) x, MusteriPalet p) {
    final renk = o.secili ? p.ana : p.baslik.withValues(alpha: p.koyuMod ? 0.85 : 0.88);
    return Semantics(
      button: true,
      selected: o.secili,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: o.onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: x(84),
            height: x(54),
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              Icon(o.secili ? o.seciliIkon : o.ikon, color: renk, size: x(52)),
              if (o.rozet)
                Positioned(
                  left: x(44),
                  top: -x(8),
                  child: ValueListenableBuilder<int>(
                    valueListenable: musteriOkunmamisBildirim,
                    builder: (_, n, __) => n <= 0 ? const SizedBox.shrink() : MusteriRozet(n, x(32)),
                  ),
                ),
            ]),
          ),
          SizedBox(height: x(6)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(o.yazi,
                maxLines: 1,
                style: GoogleFonts.figtree(
                    letterSpacing: 0,
                    fontSize: x(20),
                    height: 1.2,
                    fontWeight: o.secili ? FontWeight.w700 : FontWeight.w500,
                    color: renk)),
          ),
        ]),
      ),
    );
  }
}

/// Hap + orta kabartı + ışıklı daire + artı (852x184 tasarım koordinatı)
class _HapBoyaci extends CustomPainter {
  final MusteriPalet p;
  _HapBoyaci(this.p);

  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    canvas.scale(s.width / 852, s.height / 184);

    // Hap (x 30-826, y 40-170) ve ortadaki yumuşak kabartı tek şekil
    const sol = 30.0, sag = 826.0, ust = 40.0, alt = 170.0, r = 65.0;
    const m = Offset(427, 86);
    final yol = Path()
      ..moveTo(sol + r, ust)
      ..lineTo(m.dx - 102, ust)
      ..cubicTo(m.dx - 78, ust, m.dx - 76, ust - 8, m.dx - 62, ust - 16)
      ..cubicTo(m.dx - 46, ust - 30, m.dx - 24, ust - 33, m.dx, ust - 33)
      ..cubicTo(m.dx + 24, ust - 33, m.dx + 46, ust - 30, m.dx + 62, ust - 16)
      ..cubicTo(m.dx + 76, ust - 8, m.dx + 78, ust, m.dx + 102, ust)
      ..lineTo(sag - r, ust)
      ..arcToPoint(const Offset(sag, ust + r), radius: const Radius.circular(r))
      ..arcToPoint(const Offset(sag - r, alt), radius: const Radius.circular(r))
      ..lineTo(m.dx + 74, alt)
      ..cubicTo(m.dx + 44, alt, m.dx + 34, alt + 9, m.dx, alt + 9)
      ..cubicTo(m.dx - 34, alt + 9, m.dx - 44, alt, m.dx - 74, alt)
      ..lineTo(sol + r, alt)
      ..arcToPoint(const Offset(sol, alt - r), radius: const Radius.circular(r))
      ..arcToPoint(const Offset(sol + r, ust), radius: const Radius.circular(r))
      ..close();
    final kutu = yol.getBounds();

    canvas.drawPath(
        yol.shift(const Offset(0, 6)),
        Paint()
          ..color = p.ana.withValues(alpha: p.koyuMod ? 0.10 : 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    canvas.drawPath(
        yol,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.kart, Color.alphaBlend(p.ana.withValues(alpha: 0.055), p.kart)],
          ).createShader(kutu));
    // Üstte cam parlaması, kenarda ince çizgi
    canvas.drawPath(
        yol,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              p.koyuMod ? Colors.white.withValues(alpha: 0.22) : Colors.white,
              p.ana.withValues(alpha: p.koyuMod ? 0.20 : 0.14),
            ],
          ).createShader(kutu));

    // Orta daire
    const cap = 59.0;
    canvas.drawCircle(
        m + const Offset(0, 5),
        cap,
        Paint()
          ..color = p.dugmeAna.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    final daire = Rect.fromCircle(center: m, radius: cap);
    canvas.drawCircle(
        m,
        cap,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.1),
            colors: [p.anaKoyu, Color.lerp(p.anaKoyu, p.dugmeAna, 0.55)!, Color.lerp(p.dugmeAna, Colors.white, 0.22)!],
            stops: const [0, 0.66, 1],
          ).createShader(daire));
    canvas.drawCircle(
        m,
        cap - 1.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.75)],
          ).createShader(daire));

    // Artı
    final kalem = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(m - const Offset(23, 0), m + const Offset(23, 0), kalem);
    canvas.drawLine(m - const Offset(0, 23), m + const Offset(0, 23), kalem);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HapBoyaci e) => e.p.ana != p.ana || e.p.koyuMod != p.koyuMod || e.p.kart != p.kart;
}

/// Kırmızı bildirim rozeti (99 üstü "99+")
class MusteriRozet extends StatelessWidget {
  final int sayi;
  final double boyut;
  const MusteriRozet(this.sayi, this.boyut, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: boyut,
        constraints: BoxConstraints(minWidth: boyut),
        padding: EdgeInsets.symmetric(horizontal: boyut * 0.2),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFF5132B), borderRadius: BorderRadius.circular(boyut / 2)),
        child: Text(sayi > 99 ? '99+' : '$sayi',
            style: TextStyle(color: Colors.white, fontSize: boyut * 0.58, height: 1, fontWeight: FontWeight.w600)),
      );
}
