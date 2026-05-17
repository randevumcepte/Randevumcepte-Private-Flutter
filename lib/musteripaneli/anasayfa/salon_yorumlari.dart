import 'package:flutter/material.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/salonyorumlarozet.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

const List<String> _trAylar = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];

String _trTarih(DateTime d) {
  final ay = _trAylar[d.month - 1];
  return '${d.day} $ay ${d.year}';
}

class SalonYorumlariSayfasi extends StatefulWidget {
  const SalonYorumlariSayfasi({super.key});

  @override
  State<SalonYorumlariSayfasi> createState() => _SalonYorumlariSayfasiState();
}

class _SalonYorumlariSayfasiState extends State<SalonYorumlariSayfasi> {
  SalonYorumlarOzet? _ozet;
  bool _loading = true;
  String? _hata;
  int _puanFiltre = 0; // 0 = tümü

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _loading = true;
      _hata = null;
    });
    try {
      final r = await salonYorumlariGetir();
      if (!mounted) return;
      setState(() {
        _ozet = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async => _yukle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;

    return Scaffold(
      backgroundColor: ext.surfaceMuted,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Müşteri Yorumları',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? _hataBolumu(context)
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      const SizedBox(height: 14),
                      _ozetKart(context),
                      const SizedBox(height: 18),
                      _filtreSatiri(context),
                      const SizedBox(height: 12),
                      ..._yorumlariOlustur(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _hataBolumu(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: scheme.onSurface.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(
              'Yorumlar yüklenemedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _yukle,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ozetKart(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ozet = _ozet!;
    final ortStr = ozet.ortalama.toStringAsFixed(1).replaceAll('.', ',');
    final maxD = ozet.dagilim.values.fold<int>(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.soft(scheme.primary),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      ortStr,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _yildizSatiri(ozet.ortalama, size: 16, gap: 3),
                    const SizedBox(height: 6),
                    Text(
                      '${ozet.toplamPuan} puan · ${ozet.toplamYorum} yorum',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int s = 5; s >= 1; s--)
                        _dagilimSatiri(context, s, ozet.dagilim[s] ?? 0, maxD),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dagilimSatiri(BuildContext context, int yildiz, int sayi, int max) {
    final scheme = Theme.of(context).colorScheme;
    final orani = max > 0 ? sayi / max : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$yildiz',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB400)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 7,
                color: scheme.onSurface.withValues(alpha: 0.06),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: orani.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFB400), Color(0xFFFF8A00)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '$sayi',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtreSatiri(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filtreChip(context, 'Tümü', 0),
          for (int s = 5; s >= 1; s--)
            _filtreChip(context, '$s', s, ikon: true),
        ],
      ),
    );
  }

  Widget _filtreChip(BuildContext context, String label, int deger,
      {bool ikon = false}) {
    final scheme = Theme.of(context).colorScheme;
    final aktif = _puanFiltre == deger;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: aktif ? scheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () => setState(() => _puanFiltre = deger),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: aktif
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.10),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: aktif ? Colors.white : scheme.onSurface,
                  ),
                ),
                if (ikon) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: aktif ? Colors.white : const Color(0xFFFFB400),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _yorumlariOlustur(BuildContext context) {
    final ozet = _ozet!;
    final List<SalonYorumItem> liste = _puanFiltre == 0
        ? ozet.yorumlar
        : ozet.yorumlar.where((y) => y.puan == _puanFiltre).toList();

    if (liste.isEmpty) {
      return [_bosListe(context)];
    }
    return [
      for (final y in liste)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _yorumKart(context, y),
        ),
    ];
  }

  Widget _bosListe(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined,
              size: 56, color: scheme.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            _puanFiltre == 0 ? 'Henüz yorum yok' : 'Bu filtreyle eşleşen yorum yok',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _yorumKart(BuildContext context, SalonYorumItem y) {
    final scheme = Theme.of(context).colorScheme;
    final harf = y.kullaniciAdi.isNotEmpty
        ? y.kullaniciAdi.substring(0, 1).toUpperCase()
        : '?';
    final tarih = y.tarih != null ? _trTarih(y.tarih!) : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft(scheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      Color.lerp(scheme.primary, scheme.tertiary, 0.55) ??
                          scheme.primary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  harf,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      y.kullaniciAdi,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tarih.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          tarih,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (y.puan > 0) _yildizSatiri(y.puan.toDouble(), size: 13, gap: 1.5),
            ],
          ),
          if (y.yorum.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              y.yorum,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _yildizSatiri(double puan, {double size = 14, double gap = 2}) {
    final tam = puan.floor();
    final yarim = (puan - tam) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++) ...[
          if (i > 1) SizedBox(width: gap),
          Icon(
            i <= tam
                ? Icons.star_rounded
                : (i == tam + 1 && yarim
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
            size: size,
            color: const Color(0xFFFFB400),
          ),
        ],
      ],
    );
  }
}
