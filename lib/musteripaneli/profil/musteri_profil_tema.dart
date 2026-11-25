import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:randevu_sistem/theme/musteri_palet.dart';

// Müşteri profil ekranlarının parçaları: işletme/personel profiliyle (profil_tema.dart) aynı ölçüler,
// renkler işletmenin Görünüm temasından (MusteriPalet).

const musteriProfilKirmizi = Color(0xFFDC2626);

/// Üstten alta açılan degrade + yumuşak açık bölgeler
class MPZemin extends StatelessWidget {
  const MPZemin({super.key});

  @override
  Widget build(BuildContext context) {
    final p = MusteriPalet.of(context);
    Color kar(double a) => Color.alphaBlend(p.ana.withValues(alpha: a), p.koyuMod ? p.zemin : Colors.white);
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: p.koyuMod ? [kar(0.14), kar(0.05), p.zemin] : [kar(0.15), kar(0.07), kar(0.035)],
            stops: const [0, 0.35, 1],
          ),
        ),
        child: CustomPaint(painter: _ZeminBoya(p.ana, p.koyuMod)),
      ),
    );
  }
}

class _ZeminBoya extends CustomPainter {
  final Color ana;
  final bool koyu;
  const _ZeminBoya(this.ana, this.koyu);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final k = koyu ? 0.08 : 1.0;
    c.drawCircle(Offset(w * 0.92, 40), w * 0.42, Paint()..color = Colors.white.withValues(alpha: 0.35 * k));
    c.drawCircle(Offset(w * 0.6, 260), w * 0.36, Paint()..color = Colors.white.withValues(alpha: 0.18 * k));
    c.drawCircle(Offset(-w * 0.1, 120), w * 0.3, Paint()..color = ana.withValues(alpha: 0.08));
  }

  @override
  bool shouldRepaint(covariant _ZeminBoya o) => o.ana != ana || o.koyu != koyu;
}

class MPDaireDugme extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final VoidCallback onTap;
  const MPDaireDugme({super.key, required this.ikon, required this.etiket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = MusteriPalet.of(context);
    return Semantics(
      button: true,
      label: etiket,
      child: Material(
        color: p.kart,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: p.ana.withValues(alpha: p.koyuMod ? 0 : 0.10), blurRadius: 14, offset: const Offset(0, 5)),
            ]),
            child: Icon(ikon, color: p.baslik, size: 24),
          ),
        ),
      ),
    );
  }
}

class MPKart extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const MPKart({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = MusteriPalet.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.kart,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: p.ana.withValues(alpha: p.koyuMod ? 0 : 0.06), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Soluk tema dairesi içinde dolgu ikon
class MPIkon extends StatelessWidget {
  final IconData ikon;
  final double boyut;
  final Color? renk;
  const MPIkon(this.ikon, {super.key, this.boyut = 54, this.renk});

  @override
  Widget build(BuildContext context) {
    final r = renk ?? MusteriPalet.of(context).ana;
    return Container(
      width: boyut,
      height: boyut,
      decoration: BoxDecoration(color: r.withValues(alpha: 0.11), shape: BoxShape.circle),
      child: Icon(ikon, color: r, size: boyut * 0.5),
    );
  }
}

/// Menü satırı: ikon + başlık + açıklama + (rozet) + ok
class MPSatir extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String alt;
  final String? rozet;
  final Color? renk;
  final VoidCallback onTap;
  const MPSatir({super.key, required this.ikon, required this.baslik, required this.alt, required this.onTap, this.rozet, this.renk});

  @override
  Widget build(BuildContext context) {
    final p = MusteriPalet.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: MPKart(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        onTap: onTap,
        child: Row(children: [
          MPIkon(ikon, renk: renk),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(baslik,
                    maxLines: 1, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.baslik, letterSpacing: -0.2)),
              ),
              const SizedBox(height: 2),
              Text(alt, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, height: 1.3, color: p.metin)),
            ]),
          ),
          if (rozet != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: p.ana.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(12)),
              child: Text(rozet!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.baslik)),
            ),
          ],
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: renk ?? p.ana, size: 28),
        ]),
      ),
    );
  }
}

/// Alt sayfa iskeleti: aynı zemin, geri düğmesi, ortada başlık
class MPAltSayfa extends StatelessWidget {
  final String baslik;
  final Widget govde;
  final Widget? altDugme;
  const MPAltSayfa({super.key, required this.baslik, required this.govde, this.altDugme});

  @override
  Widget build(BuildContext context) {
    final p = MusteriPalet.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.koyuMod ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: p.zemin,
        bottomNavigationBar: altDugme == null
            ? null
            : SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 12), child: altDugme)),
        body: Stack(children: [
          const MPZemin(),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Row(children: [
                  MPDaireDugme(ikon: Icons.arrow_back_rounded, etiket: 'Geri', onTap: () => Navigator.pop(context)),
                  Expanded(
                    child: Text(baslik,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.baslik, letterSpacing: -0.3)),
                  ),
                  const SizedBox(width: 48),
                ]),
              ),
              Expanded(child: govde),
            ]),
          ),
        ]),
      ),
    );
  }
}

class MPBos extends StatelessWidget {
  final IconData ikon;
  final String metin;
  const MPBos(this.ikon, this.metin, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(children: [
          MPIkon(ikon, boyut: 70),
          const SizedBox(height: 14),
          Text(metin, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, height: 1.4, color: MusteriPalet.of(context).metin)),
        ]),
      );
}

void mpMesaj(BuildContext context, String m, {bool hata = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating, backgroundColor: hata ? Colors.red.shade700 : const Color(0xFF1F2937), content: Text(m)));
}
