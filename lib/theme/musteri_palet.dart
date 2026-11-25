import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:randevu_sistem/theme/theme_provider.dart';

/// Müşteri ekranlarının renkleri: işletmenin Ayarlar > Görünüm'de seçtiği temadan türetilir.
/// Zeminler beyaza yakın tutulur, tema rengi vurgu olarak kullanılır.
class MusteriPalet {
  final bool koyuMod;
  final Color ana; // ikon, bağlantı, vurgu
  final Color dugmeAna; // düğme/kart degradesi (beyaz yazı okunur)
  final Color anaKoyu;
  final Color baslik;
  final Color metin; // ikincil yazı
  final Color zemin;
  final Color kart;
  final Color kartKenar;
  final Color yumusak; // rozet/pasif nokta zemini
  final ColorFilter gorselFiltre; // mor kesilmiş görselleri temanın tonuna çevirir

  const MusteriPalet._({
    required this.koyuMod,
    required this.ana,
    required this.dugmeAna,
    required this.anaKoyu,
    required this.baslik,
    required this.metin,
    required this.zemin,
    required this.kart,
    required this.kartKenar,
    required this.yumusak,
    required this.gorselFiltre,
  });

  List<Color> get dugme => [dugmeAna, anaKoyu];

  factory MusteriPalet.of(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final tohum = Provider.of<ThemeProvider>(context, listen: false).config.effectiveSeedColor;
    final koyuMod = s.brightness == Brightness.dark;
    // Tema birincil rengi biraz tohum rengiyle canlandırılır; beyaz yazı okunacak kadar koyu tutulur
    var ana = Color.lerp(s.primary, tohum, 0.35)!;
    if (!koyuMod) {
      for (var i = 0; i < 12 && ana.computeLuminance() > 0.22; i++) {
        ana = Color.lerp(ana, Colors.black, 0.08)!;
      }
    }
    Color kar(Color ust, double a, Color alt) => Color.alphaBlend(ust.withValues(alpha: a), alt);
    final dugmeAna = koyuMod ? Color.lerp(tohum, Colors.black, 0.35)! : ana;

    return MusteriPalet._(
      koyuMod: koyuMod,
      ana: ana,
      dugmeAna: dugmeAna,
      anaKoyu: Color.lerp(dugmeAna, Colors.black, 0.28)!,
      baslik: koyuMod ? s.onSurface : Color.lerp(ana, Colors.black, 0.62)!,
      metin: koyuMod ? s.onSurface.withValues(alpha: 0.72) : Color.lerp(ana, const Color(0xFF374151), 0.65)!,
      zemin: koyuMod ? s.surface : kar(ana, 0.045, Colors.white),
      kart: koyuMod ? kar(Colors.white, 0.07, s.surface) : Colors.white,
      kartKenar: koyuMod ? Colors.white.withValues(alpha: 0.10) : kar(ana, 0.10, Colors.white),
      yumusak: kar(ana, 0.16, koyuMod ? s.surface : Colors.white),
      gorselFiltre: _tonFiltre(ana),
    );
  }

  /// Mor (≈266°) görsellerin tonunu hedef renge döndürür; gri/siyah temalarda rengi soldurur.
  static ColorFilter _tonFiltre(Color hedef) {
    final h = HSLColor.fromColor(hedef);
    // HSL doygunluğu koyu renkte yanıltır; kanal farkına bakılır (siyah/gri/antrasit)
    final k = [hedef.r, hedef.g, hedef.b];
    final gri = k.reduce(math.max) - k.reduce(math.min) < 0.14;
    final aci = gri ? 0.0 : (h.hue - 266) * math.pi / 180;
    final c = math.cos(aci), s = math.sin(aci);
    // Ton döndürme (parlaklık korunur)
    final t = [
      [0.213 + c * 0.787 - s * 0.213, 0.715 - c * 0.715 - s * 0.715, 0.072 - c * 0.072 + s * 0.928],
      [0.213 - c * 0.213 + s * 0.143, 0.715 + c * 0.285 + s * 0.140, 0.072 - c * 0.072 - s * 0.283],
      [0.213 - c * 0.213 - s * 0.787, 0.715 - c * 0.715 + s * 0.715, 0.072 + c * 0.928 + s * 0.072],
    ];
    final d = gri ? 0.15 : (0.55 + h.saturation * 0.45).clamp(0.0, 1.0); // doygunluk
    const l = [0.213, 0.715, 0.072];
    final m = List.generate(3, (i) => List.generate(3, (j) => d * t[i][j] + (1 - d) * l[j]));
    return ColorFilter.matrix(<double>[
      m[0][0], m[0][1], m[0][2], 0, 0, //
      m[1][0], m[1][1], m[1][2], 0, 0, //
      m[2][0], m[2][1], m[2][2], 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }
}
