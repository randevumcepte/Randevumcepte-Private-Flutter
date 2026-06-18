// Salon hatirlatma toast overlay — web paneldeki sag-alt hatirlatma kart
// sisteminin mobil karsiligi. 20 sn'de bir feed ceker, kapatilanlari hatirlar
// (sayac degisince yeniden cikar), tema rengi + emoji ile gosterir.
//
// Kullanim: ana ekranin Stack'ine en ust cocuk olarak ekleyin:
//   Stack(children: [ ...icerik..., HatirlatmaOverlay(sube: salonId, onAc: ...) ])

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hatirlatma_api.dart';
import 'hatirlatma_model.dart';

class HatirlatmaOverlay extends StatefulWidget {
  final String sube;

  /// Karta tiklaninca cagrilir. tip'e gore uygulama ici navigasyon host tarafindan
  /// yapilir. Null ise tiklama sadece karti kapatir.
  final void Function(Hatirlatma h)? onAc;

  /// Ayni anda gosterilecek azami kart sayisi.
  final int maxKart;

  const HatirlatmaOverlay({
    super.key,
    required this.sube,
    this.onAc,
    this.maxKart = 4,
  });

  @override
  State<HatirlatmaOverlay> createState() => _HatirlatmaOverlayState();
}

class _HatirlatmaOverlayState extends State<HatirlatmaOverlay> {
  Timer? _timer;
  List<Hatirlatma> _hepsi = [];
  Set<String> _kapatilan = {};
  bool _yuklendi = false;

  String get _prefKey => 'hatirlatma_kapatildi_${widget.sube}';

  @override
  void initState() {
    super.initState();
    _kapatilanlariYukle().then((_) => _cek());
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _cek());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _kapatilanlariYukle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final list = jsonDecode(raw);
        if (list is List) _kapatilan = list.map((e) => e.toString()).toSet();
      }
    } catch (_) {}
  }

  Future<void> _kapatilanlariKaydet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(_kapatilan.toList()));
    } catch (_) {}
  }

  Future<void> _cek() async {
    final list = await HatirlatmaApi.feed(widget.sube);
    if (!mounted) return;
    // Kapatilan anahtarlari mevcut feed ile siniri tut (sinirsiz buyumeyi onle).
    final gecerliAnahtarlar = list.map((h) => h.anahtar).toSet();
    final temizlenmis = _kapatilan.intersection(gecerliAnahtarlar);
    if (temizlenmis.length != _kapatilan.length) {
      _kapatilan = temizlenmis;
      _kapatilanlariKaydet();
    }
    setState(() {
      _hepsi = list;
      _yuklendi = true;
    });
  }

  void _kapat(Hatirlatma h) {
    setState(() => _kapatilan.add(h.anahtar));
    _kapatilanlariKaydet();
  }

  void _tikla(Hatirlatma h) {
    widget.onAc?.call(h);
    _kapat(h);
  }

  Color _tema(String tema) {
    switch (tema) {
      case 'kirmizi-uyari':
        return const Color(0xFFEF4444);
      case 'konfeti-parti':
        return const Color(0xFFEC4899);
      case 'altin-yagmur':
        return const Color(0xFFD97706);
      case 'mavi-cinglir':
        return const Color(0xFF3B82F6);
      case 'pasta-balon':
        return const Color(0xFFA855F7);
      case 'turuncu-kasa':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_yuklendi) return const SizedBox.shrink();
    final gosterilecek = _hepsi
        .where((h) => !_kapatilan.contains(h.anahtar))
        .take(widget.maxKart)
        .toList();
    if (gosterilecek.isEmpty) return const SizedBox.shrink();

    return Positioned(
      right: 10,
      bottom: 12,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 20 > 380
                ? 380
                : MediaQuery.of(context).size.width - 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: gosterilecek
                .map((h) => _ToastKart(
                      key: ValueKey(h.anahtar),
                      hatirlatma: h,
                      renk: _tema(h.tema),
                      onKapat: () => _kapat(h),
                      onTikla: () => _tikla(h),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ToastKart extends StatefulWidget {
  final Hatirlatma hatirlatma;
  final Color renk;
  final VoidCallback onKapat;
  final VoidCallback onTikla;

  const _ToastKart({
    super.key,
    required this.hatirlatma,
    required this.renk,
    required this.onKapat,
    required this.onTikla,
  });

  @override
  State<_ToastKart> createState() => _ToastKartState();
}

class _ToastKartState extends State<_ToastKart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _kayma;
  late final Animation<double> _solma;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _kayma = Tween<Offset>(begin: const Offset(1.15, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _solma = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hatirlatma;
    final renk = widget.renk;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kartRenk = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final metinRenk = isDark ? Colors.white : const Color(0xFF1F2937);
    final altRenk = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return FadeTransition(
      opacity: _solma,
      child: SlideTransition(
        position: _kayma,
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: kartRenk,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: renk, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTikla,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: renk.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(h.emoji.isNotEmpty ? h.emoji : '🔔',
                          style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  h.baslik,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: metinRenk,
                                  ),
                                ),
                              ),
                              if (h.sayac > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: renk,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text('${h.sayac}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(h.mesaj,
                              style: TextStyle(
                                  fontSize: 12.5, color: metinRenk, height: 1.25)),
                          if (h.altMesaj.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(h.altMesaj,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11.5, color: altRenk, height: 1.2)),
                          ],
                          if (h.ctaText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(h.ctaText,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: renk)),
                                Icon(Icons.arrow_forward_rounded,
                                    size: 14, color: renk),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: widget.onKapat,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close,
                            size: 16, color: altRenk),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
