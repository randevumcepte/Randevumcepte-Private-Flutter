import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/adisyonlar.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

class MusteriALinanPaketlerDashboard extends StatefulWidget {
  final MusteriDanisan kullanici;
  final dynamic isletmebilgi;
  final int kullanicirolu;

  MusteriALinanPaketlerDashboard({
    Key? key,
    required this.kullanici,
    required this.isletmebilgi,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  _MusteriAlinanPaketlerState createState() => _MusteriAlinanPaketlerState();
}

class _MusteriAlinanPaketlerState extends State<MusteriALinanPaketlerDashboard> {
  bool _isLoading = true;
  late SatisDataSource _satisDataGridSource;

  final TextEditingController tarih1 =
      TextEditingController(text: "1970-09-01");
  final TextEditingController tarih2 = TextEditingController(
      text: DateFormat("yyyy-MM-dd").format(DateTime.now()));

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    setState(() {
      _satisDataGridSource = SatisDataSource(
        musteriMi: true,
        personelMi: false,
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        salonid: widget.isletmebilgi['id'].toString(),
        context: context,
        tarih1: tarih1.text,
        tarih2: tarih2.text,
        musteriid: widget.kullanici.id,
        kullanicirolu: widget.kullanicirolu,
        personelid: "",
        userid: '',
        tur: "2",
      );
      _satisDataGridSource.isLoadingNotifier
          .addListener(_onLoadingStateChanged);
      _isLoading = false;
    });
  }

  void _onLoadingStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _satisDataGridSource.isLoadingNotifier.removeListener(_onLoadingStateChanged);
    super.dispose();
  }

  Future<void> _refresh() async {
    _satisDataGridSource.search(tarih1.text, tarih2.text, '', '2', false);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paketler = _isLoading ? <Adisyon>[] : _satisDataGridSource.adisyon;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Aldığım Paketler',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.10),
                Colors.white,
              ),
              Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.06),
                Colors.white,
              ),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: scheme.primary))
              : RefreshIndicator(
                  color: scheme.primary,
                  backgroundColor: Colors.white,
                  strokeWidth: 3,
                  onRefresh: _refresh,
                  child: paketler.isEmpty
                      ? _emptyState(context)
                      : ListView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          children: [
                            _summaryCard(context, paketler),
                            const SizedBox(height: 14),
                            ...paketler.map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _paketCard(context, p),
                                )),
                            _buildPaginationControls(context),
                            const SizedBox(height: 12),
                          ],
                        ),
                ),
        ),
      ),
    );
  }

  // ── SUMMARY CARD ─────────────────────────────────────────────────────────
  Widget _summaryCard(BuildContext context, List<Adisyon> paketler) {
    final scheme = Theme.of(context).colorScheme;
    double toplam = 0, odenen = 0, kalan = 0;
    for (final p in paketler) {
      toplam += double.tryParse(p.toplam_numeric) ?? 0;
      odenen += double.tryParse(p.odenen_numeric) ?? 0;
      kalan += double.tryParse(p.kalan_tutar_numeric) ?? 0;
    }
    final yuzde = toplam <= 0 ? 0.0 : (odenen / toplam).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.6) ?? scheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.tinted(scheme.primary, strength: 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${paketler.length} Paket',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '%${(yuzde * 100).toStringAsFixed(0)} ödendi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  label: 'Toplam',
                  value: _formatTL(toplam),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.20),
              ),
              Expanded(
                child: _summaryStat(
                  label: 'Ödenen',
                  value: _formatTL(odenen),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.20),
              ),
              Expanded(
                child: _summaryStat(
                  label: 'Kalan',
                  value: _formatTL(kalan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: yuzde,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── PAKET CARD ───────────────────────────────────────────────────────────
  Widget _paketCard(BuildContext context, Adisyon p) {
    final scheme = Theme.of(context).colorScheme;
    final toplamN = double.tryParse(p.toplam_numeric) ?? 0;
    final odenenN = double.tryParse(p.odenen_numeric) ?? 0;
    final kalanN = double.tryParse(p.kalan_tutar_numeric) ?? 0;
    final yuzde = toplamN <= 0 ? 0.0 : (odenenN / toplamN).clamp(0.0, 1.0);
    final tamamen = kalanN <= 0;

    final paketAdi = p.icerikKisaltilmis.isNotEmpty
        ? p.icerikKisaltilmis
        : (p.icerik.isNotEmpty ? p.icerik : 'Paket');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft(scheme.primary),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.16),
                      scheme.tertiary.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paketAdi,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTarih(p.acilis_tarihi),
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(context, tamamen: tamamen),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _moneyStat(
                  context,
                  label: 'Toplam',
                  value: p.toplam,
                  color: scheme.primary,
                  bg: scheme.primary.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _moneyStat(
                  context,
                  label: 'Ödenen',
                  value: p.odenen,
                  color: Theme.of(context)
                      .extension<AppThemeExtension>()
                      ?.successColor ??
                      Colors.green.shade600,
                  bg: (Theme.of(context)
                              .extension<AppThemeExtension>()
                              ?.successColor ??
                          Colors.green.shade600)
                      .withValues(alpha: 0.10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _moneyStat(
                  context,
                  label: 'Kalan',
                  value: p.kalan_tutar,
                  color: tamamen
                      ? scheme.onSurface.withValues(alpha: 0.45)
                      : Colors.red.shade500,
                  bg: tamamen
                      ? scheme.onSurface.withValues(alpha: 0.06)
                      : Colors.red.shade500.withValues(alpha: 0.10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: yuzde,
                    minHeight: 6,
                    backgroundColor:
                        scheme.primary.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      tamamen
                          ? (Theme.of(context)
                                  .extension<AppThemeExtension>()
                                  ?.successColor ??
                              Colors.green.shade600)
                          : scheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '%${(yuzde * 100).toStringAsFixed(0)}',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context, {required bool tamamen}) {
    final scheme = Theme.of(context).colorScheme;
    final success = Theme.of(context)
            .extension<AppThemeExtension>()
            ?.successColor ??
        Colors.green.shade600;
    final color = tamamen ? success : scheme.tertiary;
    final label = tamamen ? 'Tamamlandı' : 'Devam Ediyor';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.14),
                  scheme.tertiary.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: scheme.primary,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Henüz paketin yok',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Satın aldığın paketler burada listelenecek.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ── PAGINATION ───────────────────────────────────────────────────────────
  Widget _buildPaginationControls(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalPages = _satisDataGridSource.totalPages.ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    final current = _satisDataGridSource.currentPage;
    final canPrev = current > 1;
    final canNext = current < totalPages;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageButton(
            context,
            icon: Icons.chevron_left_rounded,
            enabled: canPrev,
            onTap: () {
              setState(() {
                _satisDataGridSource.setPage(
                    current - 1, tarih1.text, tarih2.text, '', '2');
              });
            },
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: AppShadows.soft(scheme.primary),
            ),
            child: Text(
              '$current / $totalPages',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _pageButton(
            context,
            icon: Icons.chevron_right_rounded,
            enabled: canNext,
            onTap: () {
              setState(() {
                _satisDataGridSource.setPage(
                    current + 1, tarih1.text, tarih2.text, '', '2');
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _pageButton(
    BuildContext context, {
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: enabled
                ? scheme.primary
                : scheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            boxShadow: enabled ? AppShadows.tinted(scheme.primary) : null,
          ),
          child: Icon(
            icon,
            color: enabled
                ? Colors.white
                : scheme.primary.withValues(alpha: 0.4),
            size: 22,
          ),
        ),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────
  String _formatTL(double v) {
    final isInt = v.truncateToDouble() == v;
    final str = isInt
        ? v.toInt().toString()
        : v.toStringAsFixed(2).replaceAll('.', ',');
    final parts = str.split(',');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
      buf.write(intPart[i]);
    }
    final formatted = parts.length > 1 ? '${buf.toString()},${parts[1]}' : buf.toString();
    return '$formatted ₺';
  }

  String _formatTarih(String raw) {
    if (raw.isEmpty || raw == 'null') return '';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd.MM.yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
