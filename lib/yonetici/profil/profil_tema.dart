import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Profil ekranları ortak tasarım: lavanta zemin, beyaz yuvarlak kartlar, mor dolgu ikonlar.
class PT {
  static const Color mor = Color(0xFF6A1FD0);
  static const Color lila = Color(0xFFEDE3FC);
  static const Color koyu = Color(0xFF1C1236);
  static const Color gri = Color(0xFF5F5875);
  static const Color cizgi = Color(0xFFE6DFF3);
  static const Color zemin = Color(0xFFF5F1FD);
  static const Color yesil = Color(0xFF16A34A);

  static Color durumRenk(String d) =>
      d == 'molada' ? const Color(0xFFF59E0B) : d == 'izinli' ? const Color(0xFF94A3B8) : const Color(0xFF22C55E);
  static Color durumKoyu(String d) =>
      d == 'molada' ? const Color(0xFFB45309) : d == 'izinli' ? const Color(0xFF475569) : const Color(0xFF15803D);
}

/// Lavanta degrade + sağ üstte yumuşak açık bölgeler
class PTZemin extends StatelessWidget {
  const PTZemin({super.key});
  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE9DDFB), Color(0xFFF3EEFD), Color(0xFFF8F6FE)],
              stops: [0, 0.35, 1],
            ),
          ),
          child: CustomPaint(painter: _ZeminBoya()),
        ),
      );
}

class _ZeminBoya extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    c.drawCircle(Offset(w * 0.92, 40), w * 0.42, Paint()..color = Colors.white.withValues(alpha: 0.35));
    c.drawCircle(Offset(w * 0.6, 260), w * 0.36, Paint()..color = Colors.white.withValues(alpha: 0.18));
    c.drawCircle(Offset(-w * 0.1, 120), w * 0.3, Paint()..color = const Color(0xFFD9C6F7).withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PTDaireDugme extends StatelessWidget {
  final IconData ikon;
  final VoidCallback onTap;
  const PTDaireDugme({super.key, required this.ikon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: PT.mor.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 5)),
            ]),
            child: Icon(ikon, color: PT.koyu, size: 24),
          ),
        ),
      );
}

class PTKart extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const PTKart({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: PT.mor.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 5))],
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

/// Lila daire içinde mor dolgu ikon
class PTIkon extends StatelessWidget {
  final IconData ikon;
  final double boyut;
  final Color? renk;
  const PTIkon(this.ikon, {super.key, this.boyut = 54, this.renk});
  @override
  Widget build(BuildContext context) => Container(
        width: boyut,
        height: boyut,
        decoration: BoxDecoration(color: (renk ?? PT.mor).withValues(alpha: 0.11), shape: BoxShape.circle),
        child: Icon(ikon, color: renk ?? PT.mor, size: boyut * 0.5),
      );
}

/// Menü satırı: ikon + başlık + açıklama + (rozet) + ok
class PTSatir extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String alt;
  final String? rozet;
  final Color? rozetRenk;
  final VoidCallback onTap;
  const PTSatir({super.key, required this.ikon, required this.baslik, required this.alt, required this.onTap, this.rozet, this.rozetRenk});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: PTKart(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          onTap: onTap,
          child: Row(children: [
            PTIkon(ikon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(baslik, maxLines: 1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PT.koyu, letterSpacing: -0.2)),
                ),
                const SizedBox(height: 2),
                Text(alt, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, height: 1.3, color: PT.gri)),
              ]),
            ),
            if (rozet != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (rozetRenk ?? PT.mor).withValues(alpha: rozetRenk == null ? 0.09 : 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(rozet!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: rozetRenk ?? PT.koyu)),
              ),
            ],
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: PT.mor, size: 28),
          ]),
        ),
      );
}

/// Alt sayfa iskeleti: aynı zemin, geri düğmesi, ortada başlık
class PTAltSayfa extends StatelessWidget {
  final String baslik;
  final Widget govde;
  final Widget? sagDugme;
  final Widget? altDugme;
  const PTAltSayfa({super.key, required this.baslik, required this.govde, this.sagDugme, this.altDugme});
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: PT.zemin,
          bottomNavigationBar: altDugme == null
              ? null
              : SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 12), child: altDugme)),
          body: Stack(children: [
            const PTZemin(),
            SafeArea(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Row(children: [
                    PTDaireDugme(ikon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                    Expanded(
                      child: Text(baslik,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PT.koyu, letterSpacing: -0.3)),
                    ),
                    sagDugme ?? const SizedBox(width: 48),
                  ]),
                ),
                Expanded(child: govde),
              ]),
            ),
          ]),
        ),
      );
}

class PTBos extends StatelessWidget {
  final IconData ikon;
  final String metin;
  const PTBos(this.ikon, this.metin, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(children: [
          PTIkon(ikon, boyut: 70),
          const SizedBox(height: 14),
          Text(metin, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, height: 1.4, color: PT.gri)),
        ]),
      );
}

Widget ptAnaDugme(String metin, IconData ikon, VoidCallback? onTap, {bool yukleniyor = false}) => SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: PT.mor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: yukleniyor ? null : onTap,
        icon: yukleniyor
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
            : Icon(ikon, size: 20),
        label: Text(metin, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
      ),
    );

void ptMesaj(BuildContext context, String m, {bool hata = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, backgroundColor: hata ? Colors.red.shade700 : PT.koyu, content: Text(m)));
}
