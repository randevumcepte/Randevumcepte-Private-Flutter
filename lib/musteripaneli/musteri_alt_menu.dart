import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Müşteri alt menüsü: zemin (orkide, hap, nilüfer) tasarımdan kesilmiş görseldir (852 px genişlik),
/// ikon/yazı/rozet üstüne oturur. Ölçüler ekran genişliğine oranlanır. Tam 4 öge alır.
class MusteriAltMenu extends StatelessWidget {
  final List<MusteriAltMenuOge> ogeler;
  final VoidCallback onOrta;
  /// Ana sayfada içerik menünün arkasından geçer (görselin üst kenarı saydamlaşır)
  final bool saydam;
  const MusteriAltMenu({super.key, required this.ogeler, required this.onOrta, this.saydam = false});

  static const _merkezler = [123, 269, 591, 735];

  @override
  Widget build(BuildContext context) {
    final w = math.min(MediaQuery.of(context).size.width, 600.0);
    double x(num px) => w * px / 852;
    return Container(
      decoration: BoxDecoration(
        color: saydam ? null : const Color(0xFFE9CFFD),
        // Sistem çubuğu payı her durumda dolu kalır
        gradient: saydam
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00E9CFFD), Color(0xFFE9CFFD), Color(0xFFE9CFFD)],
                stops: [0, 0.35, 1])
            : null,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      alignment: Alignment.bottomCenter,
      height: x(184) + MediaQuery.of(context).padding.bottom,
      child: SizedBox(
        width: w,
        height: x(184),
        child: Stack(children: [
          Positioned.fill(child: Image.asset('images/musteri_altmenu.png', fit: BoxFit.fill)),
          for (var i = 0; i < ogeler.length && i < 4; i++)
            Positioned(
              left: x(_merkezler[i] - 73),
              top: x(44),
              width: x(146),
              height: x(122),
              child: _oge(ogeler[i], x),
            ),
          Positioned(
            left: x(362),
            top: x(20),
            width: x(130),
            height: x(130),
            child: Semantics(
              button: true,
              label: 'Randevu Al',
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onOrta),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _oge(MusteriAltMenuOge o, double Function(num) x) {
    final renk = o.secili ? const Color(0xFF6D1FD6) : const Color(0xFF4C1D95);
    return GestureDetector(
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
                right: x(2),
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
              style: GoogleFonts.figtree(letterSpacing: 0, fontSize: x(20), height: 1.2, fontWeight: o.secili ? FontWeight.w700 : FontWeight.w500, color: renk)),
        ),
      ]),
    );
  }
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
