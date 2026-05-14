import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

/// Anket / Reputation Booster sonuc sayfasi.
/// Backend: /api/v1/anketOzet + /api/v1/anketGonderimleri
class AnketSonuclariPage extends StatefulWidget {
  final dynamic isletmebilgi;

  const AnketSonuclariPage({super.key, required this.isletmebilgi});

  @override
  State<AnketSonuclariPage> createState() => _AnketSonuclariPageState();
}

class _AnketSonuclariPageState extends State<AnketSonuclariPage> {
  Map<String, dynamic>? _ozet;
  List<Map<String, dynamic>>? _kayitlar;
  bool _loadingOzet = true;
  bool _loadingListe = true;
  int _gunFilter = 30; // 7 / 30 / 90 / 365

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final salonId = widget.isletmebilgi['id'].toString();
    setState(() {
      _loadingOzet = true;
      _loadingListe = true;
    });
    final results = await Future.wait([
      anketOzet(salonId, gun: _gunFilter),
      anketGonderimleri(salonId, limit: 30),
    ]);
    if (!mounted) return;
    setState(() {
      _ozet = results[0] as Map<String, dynamic>?;
      _kayitlar = results[1] as List<Map<String, dynamic>>?;
      _loadingOzet = false;
      _loadingListe = false;
    });
  }

  void _changeGunFilter(int gun) {
    setState(() => _gunFilter = gun);
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.36), Colors.white),
              Color.alphaBlend(
                  scheme.tertiary.withValues(alpha: 0.08), Colors.white),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _yukle,
            color: scheme.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: false,
                  floating: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text(
                    'Anket Sonuçları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: _gunFilterRow(context),
                  ),
                ),
                SliverToBoxAdapter(child: _ozetKart(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: _listeBaslik(context)),
                ),
                _listeBodySliver(context),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gunFilterRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const opts = [
      [7, '7 Gün'],
      [30, '30 Gün'],
      [90, '3 Ay'],
      [365, '1 Yıl'],
    ];
    return Row(
      children: opts.map((o) {
        final selected = _gunFilter == o[0];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => _changeGunFilter(o[0] as int),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    o[1] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? scheme.onPrimary : scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _ozetKart(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _loadingOzet
            ? _loadingBlok()
            : _ozet == null
                ? _hataBlok('Özet alınamadı')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.poll_outlined,
                              size: 18, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Genel Özet',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _metricKutu(
                              context,
                              etiket: 'Cevap Oranı',
                              deger:
                                  '%${(_ozet!['cevapOrani'] as num).toStringAsFixed(0)}',
                              tint: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _metricKutu(
                              context,
                              etiket: 'Cevap / Gönderim',
                              deger:
                                  '${_ozet!['toplamCevap']} / ${_ozet!['toplamGonderim']}',
                              tint: scheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _metricKutu(
                              context,
                              etiket: 'Ort. NPS',
                              deger: _ozet!['ortNps'] != null
                                  ? '${(_ozet!['ortNps'] as num).toStringAsFixed(1)} / 10'
                                  : '—',
                              tint: ext.successColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _metricKutu(
                              context,
                              etiket: 'Ort. CSAT',
                              deger: _ozet!['ortCsat'] != null
                                  ? '${(_ozet!['ortCsat'] as num).toStringAsFixed(2)} / 5'
                                  : '—',
                              tint: ext.warningColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Promoter / Passive / Detractor segment bar
                      _promoterBar(context),
                      const SizedBox(height: 12),
                      // Son 7 gun mini trend
                      Text(
                        'Son 7 Gün Cevap Sayısı',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(height: 50, child: _trendBars(context)),
                    ],
                  ),
      ),
    );
  }

  Widget _metricKutu(BuildContext context,
      {required String etiket, required String deger, required Color tint}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiket,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            deger,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: tint,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _promoterBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final p = (_ozet!['promoter'] as num).toInt();
    final pa = (_ozet!['passive'] as num).toInt();
    final d = (_ozet!['detractor'] as num).toInt();
    final total = p + pa + d;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: scheme.onSurface.withValues(alpha: 0.45)),
            const SizedBox(width: 6),
            Text(
              'Henüz NPS skoru gelen cevap yok.',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      );
    }
    final pPct = p / total;
    final paPct = pa / total;
    final dPct = d / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NPS Dağılımı',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.55),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                    flex: (pPct * 100).round(),
                    child: Container(color: ext.successColor)),
                Expanded(
                    flex: (paPct * 100).round(),
                    child: Container(color: ext.warningColor)),
                Expanded(
                    flex: (dPct * 100).round(),
                    child: Container(color: scheme.error)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _lejandNokta(ext.successColor, 'Tavsiye', p),
            const SizedBox(width: 12),
            _lejandNokta(ext.warningColor, 'Nötr', pa),
            const SizedBox(width: 12),
            _lejandNokta(scheme.error, 'Şikayet', d),
          ],
        ),
      ],
    );
  }

  Widget _lejandNokta(Color renk, String etiket, int sayi) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: renk, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$etiket ($sayi)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  Widget _trendBars(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = (_ozet!['trend'] as List).cast<int>();
    if (list.isEmpty) return const SizedBox.shrink();
    final maks = list.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(list.length, (i) {
        final v = list[i];
        final oran = maks > 0 ? v / maks : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FractionallySizedBox(
              heightFactor: (oran).clamp(0.06, 1.0),
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.65),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _listeBaslik(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.list_alt_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            'Son Cevaplar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listeBodySliver(BuildContext context) {
    if (_loadingListe) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        sliver: SliverToBoxAdapter(child: _loadingBlok()),
      );
    }
    if (_kayitlar == null) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        sliver: SliverToBoxAdapter(child: _hataBlok('Kayıtlar alınamadı')),
      );
    }
    if (_kayitlar!.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        sliver: SliverToBoxAdapter(
            child: _empty('Bu dönemde cevaplanmış anket yok')),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _kayitKart(context, _kayitlar![i]),
          childCount: _kayitlar!.length,
        ),
      ),
    );
  }

  Widget _kayitKart(BuildContext context, Map<String, dynamic> k) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final ad = (k['ad_soyad'] ?? 'İsimsiz').toString();
    final tel = (k['telefon'] ?? '').toString();
    final nps = k['nps_skoru'] as int?;
    final csat = k['csat_skoru'] as num?;
    final yorum = (k['genel_yorum'] ?? '').toString();
    final cevapZ = k['cevap_zamani'] as String?;
    final formattedDate = _formatTarih(cevapZ);

    final tonRenk = nps == null
        ? scheme.primary
        : (nps >= 9
            ? ext.successColor
            : (nps >= 7 ? ext.warningColor : scheme.error));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tonRenk.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    ad.isNotEmpty ? ad.substring(0, 1).toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tonRenk,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tel.isNotEmpty)
                      Text(
                        tel,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
              if (nps != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tonRenk.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$nps / 10',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tonRenk,
                    ),
                  ),
                ),
            ],
          ),
          if (csat != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.star_rounded,
                    size: 14, color: ext.warningColor),
                const SizedBox(width: 4),
                Text(
                  'CSAT: ${csat.toStringAsFixed(2)} / 5',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ],
          if (yorum.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"$yorum"',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (formattedDate.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTarih(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('d MMM yyyy • HH:mm', 'tr').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Widget _loadingBlok() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(scheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yükleniyor...',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hataBlok(String mesaj) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mesaj,
              style: TextStyle(
                fontSize: 12,
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String mesaj) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 32, color: scheme.onSurface.withValues(alpha: 0.30)),
            const SizedBox(height: 8),
            Text(
              mesaj,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
