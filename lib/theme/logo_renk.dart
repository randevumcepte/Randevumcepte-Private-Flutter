import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Salon logosundan otomatik türetilen renk paleti.
/// Tanıtım (açılış) ekranı bu renklerle boyanır; logo okunamazsa [varsayilan]
/// (mor) palete düşer.
class LogoPalet {
  final Color birincil; // canlı ana renk (ışın/iç halka/logo gölge)
  final Color ikincil; // ikinci renk (dış halka/ışık topu)
  final Color koyu; // okunaklı koyu ton (başlık/buton)
  final Color zeminTonu; // arka planın en açık ucundaki hafif ton

  const LogoPalet({
    required this.birincil,
    required this.ikincil,
    required this.koyu,
    required this.zeminTonu,
  });

  /// Logo okunamazsa kullanılan varsayılan mor palet.
  static const LogoPalet varsayilan = LogoPalet(
    birincil: Color(0xFF7C2FB8),
    ikincil: Color(0xFFD946EF),
    koyu: Color(0xFF5C008E),
    zeminTonu: Color(0xFFEFE6F8),
  );

  /// Verilen görselden (salon logosu) renk paleti üretir.
  static Future<LogoPalet> logodanUret(ImageProvider gorsel) async {
    try {
      final pg = await PaletteGenerator.fromImageProvider(
        gorsel,
        size: const Size(220, 220),
        maximumColorCount: 16,
      );

      final Color? ham = pg.vibrantColor?.color ??
          pg.dominantColor?.color ??
          pg.darkVibrantColor?.color ??
          pg.lightVibrantColor?.color;
      if (ham == null) return varsayilan;

      final birincil = _canliVaryant(ham);

      final Color? ikinciHam = pg.lightVibrantColor?.color ??
          pg.mutedColor?.color ??
          pg.darkVibrantColor?.color;
      final ikincil = _canliVaryant(
        (ikinciHam != null && _yeterinceFarkli(ikinciHam, ham))
            ? ikinciHam
            : _tonKaydir(ham, 40),
      );

      final koyu = _koyuOkunakli(ham);
      final zeminTonu =
          Color.alphaBlend(birincil.withOpacity(0.12), Colors.white);

      return LogoPalet(
        birincil: birincil,
        ikincil: ikincil,
        koyu: koyu,
        zeminTonu: zeminTonu,
      );
    } catch (_) {
      return varsayilan;
    }
  }

  /// Rengi canlı tutar ama beyaz zeminde kaybolmayacak/çok koyu olmayacak
  /// aralığa çeker.
  static Color _canliVaryant(Color c) {
    final h = HSLColor.fromColor(c);
    final s = h.saturation < 0.35 ? 0.55 : h.saturation;
    final l = h.lightness.clamp(0.42, 0.62);
    return h.withSaturation(s).withLightness(l).toColor();
  }

  /// Başlık ve butonlar için beyaz üstünde okunaklı koyu ton.
  static Color _koyuOkunakli(Color c) {
    final h = HSLColor.fromColor(c);
    final s = h.saturation < 0.4 ? 0.6 : h.saturation;
    return h.withSaturation(s).withLightness(0.32).toColor();
  }

  static Color _tonKaydir(Color c, double derece) {
    final h = HSLColor.fromColor(c);
    final yeniTon = (h.hue + derece) % 360;
    return h.withHue(yeniTon).toColor();
  }

  /// İki rengin ton (hue) farkı yeterince açık mı (ikinci renk ayırt edilsin).
  static bool _yeterinceFarkli(Color a, Color b) {
    final ha = HSLColor.fromColor(a).hue;
    final hb = HSLColor.fromColor(b).hue;
    final fark = (ha - hb).abs();
    final donusFark = fark > 180 ? 360 - fark : fark;
    return donusFark > 25;
  }
}
