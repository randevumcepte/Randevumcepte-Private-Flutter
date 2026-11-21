// WhatsApp Asistanı — ortak görsel bileşenler (web sayfasındaki SVG çizimlerin karşılıkları).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'wa_asistan_api.dart';

const waYesil = Color(0xFF25D366);
const waMor = Color(0xFF7C3AED);
const waMorKoyu = Color(0xFF6D28D9);
const waAcikMor = Color(0xFFF1EDF8);

// ---------------------------------------------------------------- kart
class WaKart extends StatelessWidget {
  final Widget child;
  final String? baslik;
  final IconData? ikon;
  final Color? ikonRenk;
  final Widget? sag;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? renk;
  final Color? kenar;

  const WaKart({
    super.key,
    required this.child,
    this.baslik,
    this.ikon,
    this.ikonRenk,
    this.sag,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.renk,
    this.kenar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: renk ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: kenar != null ? Border.all(color: kenar!) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (baslik != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                if (ikon != null) ...[Icon(ikon, size: 18, color: ikonRenk ?? waMor), const SizedBox(width: 8)],
                Expanded(child: Text(baslik!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                if (sag != null) sag!,
              ]),
            ),
          child,
        ],
      ),
    );
  }
}

class WaBos extends StatelessWidget {
  final String metin;
  const WaBos(this.metin, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Text(metin, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5, height: 1.45)),
      );
}

class WaBilgi extends StatelessWidget {
  final String metin;
  final Color renk;
  const WaBilgi(this.metin, {super.key, this.renk = const Color(0xFF2563EB)});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: renk.withValues(alpha: 0.25)),
        ),
        child: Text(metin, style: const TextStyle(fontSize: 13.2, height: 1.45)),
      );
}

class WaAlt extends StatelessWidget {
  final String metin;
  const WaAlt(this.metin, {super.key});
  @override
  Widget build(BuildContext context) =>
      Text(metin, style: TextStyle(fontSize: 12.2, color: Colors.grey.shade600, height: 1.4));
}

void waToast(BuildContext context, String m) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)));
}

Future<bool> waOnay(BuildContext context, String metin, {String evet = 'Evet'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(metin),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(evet)),
      ],
    ),
  );
  return r == true;
}

// ---------------------------------------------------------------- durum hapı (web hapSinif)
class WaHap extends StatelessWidget {
  final String metin;
  final String? sinif; // y=yeşil, m=mavi/mor, s=sarı, k=kırmızı, g=gri
  const WaHap(this.metin, {super.key, this.sinif});

  static String sinifBul(String s) {
    if (RegExp(r'Dönüş bekliyor|dönmedi|Yanlış numara').hasMatch(s)) return 'k';
    if (s.contains('cevapladı')) return 'y';
    if (RegExp(r'Randevu alındı|Randevu Alındı|Oluşturuldu|teyit|değişti').hasMatch(s)) return 'y';
    if (s.contains('Fiyat')) return 'm';
    if (RegExp(r'aktarıldı|Personelde').hasMatch(s)) return 's';
    if (RegExp(r'iptal|durduruldu|Bot').hasMatch(s)) return 'k';
    return 'g';
  }

  @override
  Widget build(BuildContext context) {
    final c = switch (sinif ?? sinifBul(metin)) {
      'y' => const Color(0xFF16A34A),
      'm' => const Color(0xFF2563EB),
      's' => const Color(0xFFD97706),
      'k' => const Color(0xFFDC2626),
      _ => const Color(0xFF64748B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(20)),
      child: Text(metin, style: TextStyle(color: c, fontSize: 11.2, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

// ---------------------------------------------------------------- avatar (sistem fotoğrafı > WhatsApp fotoğrafı > baş harfler)
const _avatarRenk = [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF97316), Color(0xFF0EA5E9), Color(0xFF16A34A), Color(0xFF8B5CF6), Color(0xFFE11D48), Color(0xFF0891B2)];

class WaAvatar extends StatelessWidget {
  final String? ad;
  final int? id;
  final String? foto;
  final String sube;
  final double boyut;
  const WaAvatar({super.key, this.ad, this.id, this.foto, required this.sube, this.boyut = 44});

  @override
  Widget build(BuildContext context) {
    final s = (ad ?? '?').trim().isEmpty ? '?' : ad!.trim();
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0xFFFFFFFF;
    }
    final p = s.split(RegExp(r'\s+'));
    final bas = ((p.first.isNotEmpty ? p.first[0] : '?') + (p.length > 1 && p.last.isNotEmpty ? p.last[0] : ''))
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .toUpperCase();
    String? src;
    Map<String, String>? hdr;
    if (foto != null && foto!.isNotEmpty) {
      src = foto!.startsWith('http') ? foto : '${WaApi.host}${foto!.startsWith('/') ? '' : '/'}$foto';
    } else if (id != null) {
      src = WaApi.avatarUrl(sube, id!);
      hdr = WaApi.sonHeaders;
    }
    final harf = Center(
      child: Text(bas, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: boyut * 0.36)),
    );
    return ClipOval(
      child: Container(
        width: boyut,
        height: boyut,
        color: _avatarRenk[h % _avatarRenk.length],
        child: src == null
            ? harf
            // gösterildiği boyutta çöz (tam çözünürlüklü fotoğraf listede kasma yapar)
            : Image.network(src, headers: hdr, fit: BoxFit.cover, cacheWidth: (boyut * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, __, ___) => harf),
      ),
    );
  }
}

// ---------------------------------------------------------------- trend
class WaTrend extends StatelessWidget {
  final num? v;
  final bool tersIyi;
  final bool puan;
  final Color? acikZemin;
  const WaTrend(this.v, {super.key, this.tersIyi = false, this.puan = false, this.acikZemin});
  @override
  Widget build(BuildContext context) {
    if (v == null) return const SizedBox.shrink();
    final iyi = tersIyi ? v! <= 0 : v! >= 0;
    final c = iyi ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final t = '${v! >= 0 ? '↑' : '↓'} ${puan ? '${v! >= 0 ? '+' : ''}$v puan' : '%${v!.abs()}'}';
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: acikZemin ?? c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: acikZemin != null ? Colors.white : c)),
    );
  }
}

// ---------------------------------------------------------------- mini grafik (sparkline)
class WaSpark extends StatelessWidget {
  final List<dynamic>? degerler;
  final Color renk;
  final double yukseklik;
  const WaSpark(this.degerler, this.renk, {super.key, this.yukseklik = 38});
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: yukseklik, width: double.infinity, child: CustomPaint(painter: _SparkPainter(degerler ?? const [], renk)));
}

class _SparkPainter extends CustomPainter {
  final List<dynamic> ham;
  final Color renk;
  _SparkPainter(this.ham, this.renk);

  @override
  void paint(Canvas canvas, Size size) {
    var v = ham.map((x) => x == null ? null : sayiDeger(x).toDouble()).toList();
    // Uzun seride 3 günlük hareketli ortalama (web ile aynı)
    if (v.length > 14) {
      final k = List<double?>.from(v);
      v = List.generate(k.length, (i) {
        final p = [if (i > 0) k[i - 1], k[i], if (i < k.length - 1) k[i + 1]].whereType<double>().toList();
        return p.isEmpty ? null : p.reduce((a, b) => a + b) / p.length;
      });
    }
    final dolu = v.whereType<double>().toList();
    final cizgi = Paint()
      ..color = renk
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    if (dolu.length < 2) {
      canvas.drawLine(Offset(0, size.height - 4), Offset(size.width, size.height - 4), cizgi..color = renk.withValues(alpha: 0.25));
      return;
    }
    final mx = dolu.reduce(math.max), mn = dolu.reduce(math.min), ar = (mx - mn) == 0 ? 1 : (mx - mn);
    final n = v.length;
    double? son;
    final nok = <Offset>[];
    for (var i = 0; i < n; i++) {
      final x = v[i] ?? son ?? mn;
      son = x;
      nok.add(Offset(i / (n - 1) * size.width, size.height - 4 - (x - mn) / ar * (size.height - 10)));
    }
    final yol = Path()..moveTo(nok.first.dx, nok.first.dy);
    for (final p in nok.skip(1)) {
      yol.lineTo(p.dx, p.dy);
    }
    final alan = Path.from(yol)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        alan,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [renk.withValues(alpha: 0.22), renk.withValues(alpha: 0)])
              .createShader(Offset.zero & size));
    canvas.drawPath(yol, cizgi);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter o) => o.ham != ham || o.renk != renk;
}

// ---------------------------------------------------------------- halka (yüzde)
class WaHalka extends StatelessWidget {
  final num yuzde;
  final Color renk;
  final String ic;
  final String? alt;
  final double boyut;
  final Color zemin;
  final Color yaziRenk;
  const WaHalka({super.key, required this.yuzde, required this.renk, required this.ic, this.alt, this.boyut = 110, this.zemin = waAcikMor, this.yaziRenk = const Color(0xFF1F1A2E)});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: boyut,
        height: boyut,
        child: CustomPaint(
          painter: _HalkaPainter(yuzde.toDouble().clamp(0, 100), renk, zemin),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(ic, style: TextStyle(fontSize: boyut * 0.2, fontWeight: FontWeight.w800, color: yaziRenk)),
              if (alt != null) Text(alt!, style: TextStyle(fontSize: boyut * 0.095, color: yaziRenk.withValues(alpha: 0.65))),
            ]),
          ),
        ),
      );
}

class _HalkaPainter extends CustomPainter {
  final double y;
  final Color renk, zemin;
  _HalkaPainter(this.y, this.renk, this.zemin);
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width * 0.1;
    final r = Rect.fromLTWH(k / 2, k / 2, size.width - k, size.height - k);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()..color = zemin..style = PaintingStyle.stroke..strokeWidth = k);
    if (y > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * y / 100, false,
          Paint()..color = renk..style = PaintingStyle.stroke..strokeWidth = k..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _HalkaPainter o) => o.y != y || o.renk != renk;
}

// ---------------------------------------------------------------- pasta (donut)
class WaDonut extends StatelessWidget {
  final List<(double, Color)> parcalar;
  final String ortaD, ortaE;
  final double boyut;
  const WaDonut({super.key, required this.parcalar, required this.ortaD, required this.ortaE, this.boyut = 130});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: boyut,
        height: boyut,
        child: CustomPaint(
          painter: _DonutPainter(parcalar),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(ortaD, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Text(ortaE, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ]),
          ),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> p;
  _DonutPainter(this.p);
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width * 0.13;
    final r = Rect.fromLTWH(k / 2, k / 2, size.width - k, size.height - k);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()..color = waAcikMor..style = PaintingStyle.stroke..strokeWidth = k);
    final top = p.fold<double>(0, (a, x) => a + x.$1);
    if (top <= 0) return;
    var bas = -math.pi / 2;
    for (final x in p) {
      final u = x.$1 / top * math.pi * 2;
      if (u > 0) {
        canvas.drawArc(r, bas, math.max(0, u - 0.03), false, Paint()..color = x.$2..style = PaintingStyle.stroke..strokeWidth = k);
      }
      bas += u;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter o) => true;
}

// ---------------------------------------------------------------- performans grafiği (çubuk: mesaj, çizgi: randevu)
class WaPerformansGrafik extends StatefulWidget {
  final List<String> etiket;
  final List<num> randevu, mesaj;
  final String birim;
  const WaPerformansGrafik({super.key, required this.etiket, required this.randevu, required this.mesaj, required this.birim});
  @override
  State<WaPerformansGrafik> createState() => _WaPerformansGrafikState();
}

class _WaPerformansGrafikState extends State<WaPerformansGrafik> {
  int? _secili;

  @override
  void didUpdateWidget(covariant WaPerformansGrafik old) {
    super.didUpdateWidget(old);
    if (old.etiket.length != widget.etiket.length) _secili = null;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.etiket.length;
    if (n == 0) return const WaBos('Veri yok.');
    final i = _secili ?? n - 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: waAcikMor, borderRadius: BorderRadius.circular(10)),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '${etiketYaz(widget.etiket[i], widget.birim, uzun: true)}   ', style: const TextStyle(fontWeight: FontWeight.w700)),
          const TextSpan(text: '● ', style: TextStyle(color: waMorKoyu)),
          TextSpan(text: '${sayi(widget.randevu[i])} randevu   '),
          const TextSpan(text: '● ', style: TextStyle(color: Color(0xFFC4B5FD))),
          TextSpan(text: '${sayi(widget.mesaj[i])} mesaj'),
        ]), style: const TextStyle(fontSize: 12.5)),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 210,
        child: LayoutBuilder(builder: (context, c) {
          void sec(Offset p) {
            const sol = 34.0, sag = 8.0;
            final bw = (c.maxWidth - sol - sag) / n;
            final x = ((p.dx - sol) / bw).floor().clamp(0, n - 1);
            setState(() => _secili = x);
          }

          return GestureDetector(
            onTapDown: (d) => sec(d.localPosition),
            onHorizontalDragUpdate: (d) => sec(d.localPosition),
            child: CustomPaint(
              size: Size(c.maxWidth, 210),
              painter: _GrafikPainter(widget.etiket, widget.randevu, widget.mesaj, widget.birim, i),
            ),
          );
        }),
      ),
    ]);
  }
}

class _GrafikPainter extends CustomPainter {
  final List<String> etiket;
  final List<num> randevu, mesaj;
  final String birim;
  final int secili;
  _GrafikPainter(this.etiket, this.randevu, this.mesaj, this.birim, this.secili);

  // 4 eşit, yuvarlak adım (1, 2, 2.5, 5 x 10^k) — web ile aynı
  double _ust(List<num> d) {
    final mx = math.max(1, d.isEmpty ? 1 : d.reduce(math.max)).toDouble();
    final ham = mx / 4;
    final us = math.pow(10, (math.log(ham) / math.ln10).floor()).toDouble();
    var a = us;
    for (final k in [1, 2, 2.5, 5, 10]) {
      a = k * us;
      if (a >= ham) break;
    }
    return math.max(1, a.ceilToDouble()) * 4;
  }

  void _yaz(Canvas c, String t, Offset o, {double fs = 10.5, Color renk = const Color(0xFF8A82A3), TextAlign hiza = TextAlign.center}) {
    final tp = TextPainter(text: TextSpan(text: t, style: TextStyle(fontSize: fs, color: renk)), textDirection: TextDirection.ltr)..layout();
    final dx = hiza == TextAlign.right ? o.dx - tp.width : (hiza == TextAlign.center ? o.dx - tp.width / 2 : o.dx);
    tp.paint(c, Offset(dx, o.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const sol = 34.0, sag = 8.0, ust = 8.0, alt = 22.0;
    final n = etiket.length, gw = size.width - sol - sag, gh = size.height - ust - alt;
    final om = _ust(mesaj), or = _ust(randevu);
    final bw = gw / n;
    for (var i = 0; i <= 4; i++) {
      final y = ust + gh - i / 4 * gh;
      canvas.drawLine(Offset(sol, y), Offset(size.width - sag, y), Paint()..color = const Color(0xFFEFEAF7));
      _yaz(canvas, sayi(om * i / 4), Offset(sol - 5, y), hiza: TextAlign.right);
    }
    double yv(num v) => ust + gh - v / om * gh;
    double yr(num v) => ust + gh - v / or * gh;
    for (var i = 0; i < n; i++) {
      final x = sol + i * bw + bw * 0.18, w = math.max(2.0, bw * 0.64), y = yv(mesaj[i]);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, ust + gh - y), Radius.circular(math.min(4, w / 2))),
          Paint()..color = i == secili ? waMorKoyu : const Color(0xFFD8C8F7));
    }
    final yol = Path();
    for (var i = 0; i < n; i++) {
      final p = Offset(sol + i * bw + bw / 2, yr(randevu[i]));
      i == 0 ? yol.moveTo(p.dx, p.dy) : yol.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(yol, Paint()..color = waMorKoyu..style = PaintingStyle.stroke..strokeWidth = 2.4..strokeJoin = StrokeJoin.round);
    final her = (n / 4).ceil();
    for (var i = 0; i < n; i++) {
      final cx = sol + i * bw + bw / 2;
      if (n <= 31 || i == secili) {
        final s = i == secili;
        canvas.drawCircle(Offset(cx, yr(randevu[i])), s ? 5 : 2.6, Paint()..color = s ? Colors.white : waMorKoyu);
        if (s) canvas.drawCircle(Offset(cx, yr(randevu[i])), 5, Paint()..color = waMorKoyu..style = PaintingStyle.stroke..strokeWidth = 2);
      }
      if (i % her == 0 || (i == n - 1 && i % her >= her / 2)) {
        _yaz(canvas, etiketYaz(etiket[i], birim), Offset(cx, size.height - 8), fs: 10.5, renk: const Color(0xFF6B6483));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GrafikPainter o) => true;
}

// ---------------------------------------------------------------- yatay çubuk satırı
class WaCubuk extends StatelessWidget {
  final double oran; // 0..1
  final Color renk;
  final double yukseklik;
  const WaCubuk(this.oran, this.renk, {super.key, this.yukseklik = 8});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(children: [
          Container(height: yukseklik, color: waAcikMor),
          FractionallySizedBox(widthFactor: oran.clamp(0, 1).toDouble(), child: Container(height: yukseklik, color: renk)),
        ]),
      );
}
