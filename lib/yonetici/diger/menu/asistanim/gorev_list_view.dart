import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/e_asistan.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

enum GorevTipi { bugun, yarin }

class GorevListView extends StatefulWidget {
  final dynamic isletmebilgi;
  final GorevTipi tipi;

  const GorevListView({
    super.key,
    required this.isletmebilgi,
    required this.tipi,
  });

  @override
  State<GorevListView> createState() => _GorevListViewState();
}

class _GorevListViewState extends State<GorevListView> {
  EAsistanDataSource? _ds;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final salonId = await secilisalonid();
    if (!mounted || salonId == null) return;

    final hedef = widget.tipi == GorevTipi.bugun
        ? DateTime.now()
        : DateTime.now().add(const Duration(days: 1));

    final ds = EAsistanDataSource(
      isletmebilgi: widget.isletmebilgi,
      rowsPerPage: 10,
      salonid: salonId,
      context: context,
      bugunyarin: hedef.toString(),
    );
    ds.isLoadingNotifier.addListener(_onLoadingChanged);

    setState(() {
      _ds = ds;
      _isLoading = false;
    });
  }

  void _onLoadingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ds?.isLoadingNotifier.removeListener(_onLoadingChanged);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_ds == null) return;
    await _ds!.fetchData(_ds!.currentPage.toString(), _ds!.bugunyarin, false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading || _ds == null) {
      return Center(child: CircularProgressIndicator(color: scheme.primary));
    }

    final list = _ds!.asistan;
    final loading = _ds!.isLoadingNotifier.value;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: scheme.primary,
            backgroundColor: Colors.white,
            strokeWidth: 3,
            onRefresh: _refresh,
            child: (loading && list.isEmpty)
                ? Center(
                    child: CircularProgressIndicator(color: scheme.primary))
                : list.isEmpty
                    ? _emptyState(scheme)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                        itemCount: list.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _gorevKart(list[i]),
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 6),
        _pagination(scheme),
        const SizedBox(height: 6),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Kart
  // ────────────────────────────────────────────────────────────────────────
  Widget _gorevKart(EAsistan e) {
    final scheme = Theme.of(context).colorScheme;
    final aramaDt = _parseDate(e.arama_saati);
    final saatLabel = _formatSaat(aramaDt, e.arama_saati);
    final showCancel = aramaDt != null && aramaDt.isAfter(DateTime.now());

    final reached = e.durum == 'Ulaşıldı';
    final statusColor = reached
        ? const Color(0xFF16A34A)
        : (e.durum.trim().isEmpty
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626));
    final statusText = e.durum.trim().isEmpty ? 'Bekliyor' : e.durum;
    final statusIcon = reached
        ? Icons.check_circle_rounded
        : (e.durum.trim().isEmpty
            ? Icons.schedule_rounded
            : Icons.cancel_rounded);

    return PremiumGlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showGorevPopup(e, showCancel: showCancel),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(e.baslik),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.baslik.isEmpty ? '—' : e.baslik,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(statusIcon, statusText, statusColor),
                  ],
                ),
                if (e.mesaj.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 14,
                          color: scheme.primary.withValues(alpha: 0.75)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          e.mesaj,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.70),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (saatLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 13,
                          color: scheme.onSurface.withValues(alpha: 0.50)),
                      const SizedBox(width: 5),
                      Text(
                        saatLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      if (e.sonuc.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.flag_outlined,
                            size: 13,
                            color: scheme.onSurface.withValues(alpha: 0.50)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            e.sonuc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          _trailingButton(e, showCancel),
        ],
      ),
    );
  }

  Widget _trailingButton(EAsistan e, bool showCancel) {
    final scheme = Theme.of(context).colorScheme;
    if (showCancel) {
      return InkWell(
        onTap: () => _confirmCancel(e),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded,
              size: 18, color: Color(0xFFDC2626)),
        ),
      );
    }
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.chevron_right_rounded,
          size: 20, color: scheme.primary.withValues(alpha: 0.55)),
    );
  }

  Widget _avatar(String name) {
    final scheme = Theme.of(context).colorScheme;
    final initials = _initials(name);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.20),
            scheme.tertiary.withValues(alpha: 0.20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: scheme.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Empty state
  // ────────────────────────────────────────────────────────────────────────
  Widget _emptyState(ColorScheme scheme) {
    final isBugun = widget.tipi == GorevTipi.bugun;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isBugun ? Icons.task_alt_rounded : Icons.event_available_rounded,
              size: 44,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            isBugun ? 'Bugün için göreviniz yok' : 'Yarın için göreviniz yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Yeni görevler oluştuğunda burada listelenecek.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Pagination
  // ────────────────────────────────────────────────────────────────────────
  Widget _pagination(ColorScheme scheme) {
    final totalPages = _ds!.totalPages;
    final page = _ds!.currentPage;
    final canPrev = page > 1;
    final canNext = page < totalPages;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          _pageBtn(
            scheme: scheme,
            icon: Icons.arrow_back_rounded,
            enabled: canPrev,
            onTap: () => setState(() => _ds!.setPage(page - 1)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Sayfa $page / $totalPages',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _pageBtn(
            scheme: scheme,
            icon: Icons.arrow_forward_rounded,
            enabled: canNext,
            onTap: () => setState(() => _ds!.setPage(page + 1)),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({
    required ColorScheme scheme,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: scheme.primary
                    .withValues(alpha: enabled ? 0.14 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? scheme.primary
                : scheme.primary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Premium popup (detay)
  // ────────────────────────────────────────────────────────────────────────
  void _showGorevPopup(EAsistan e, {required bool showCancel}) {
    final scheme = Theme.of(context).colorScheme;
    final aramaDt = _parseDate(e.arama_saati);
    final saatLabel = _formatSaat(aramaDt, e.arama_saati);
    final tarihLabel = aramaDt != null ? _formatTarih(aramaDt) : '';

    final reached = e.durum == 'Ulaşıldı';
    final statusColor = reached
        ? const Color(0xFF16A34A)
        : (e.durum.trim().isEmpty
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626));
    final statusText = e.durum.trim().isEmpty ? 'Bekliyor' : e.durum;
    final statusIcon = reached
        ? Icons.check_circle_rounded
        : (e.durum.trim().isEmpty
            ? Icons.schedule_rounded
            : Icons.cancel_rounded);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.14),
                      scheme.tertiary.withValues(alpha: 0.14),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    _avatar(e.baslik),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.baslik.isEmpty ? '—' : e.baslik,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _statusBadge(statusIcon, statusText, statusColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Detail rows
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (e.mesaj.isNotEmpty)
                      _detayRow(
                        icon: Icons.assignment_outlined,
                        label: 'Görev',
                        value: e.mesaj,
                      ),
                    if (tarihLabel.isNotEmpty || saatLabel.isNotEmpty)
                      _detayRow(
                        icon: Icons.event_outlined,
                        label: 'Arama Zamanı',
                        value: [tarihLabel, saatLabel]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                      ),
                    if (e.sonuc.isNotEmpty)
                      _detayRow(
                        icon: Icons.flag_outlined,
                        label: 'Sonuç',
                        value: e.sonuc,
                      ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                child: Row(
                  children: [
                    if (showCancel)
                      Expanded(
                        child: _cancelButton(
                          scheme: scheme,
                          onTap: () {
                            Navigator.pop(ctx);
                            _confirmCancel(e);
                          },
                        ),
                      ),
                    if (showCancel) const SizedBox(width: 10),
                    Expanded(
                      child: PremiumGradientPill(
                        icon: Icons.close_rounded,
                        label: 'Kapat',
                        onTap: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detayRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cancelButton({
    required ColorScheme scheme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.cancel_rounded, size: 16, color: Color(0xFFDC2626)),
              SizedBox(width: 6),
              Text(
                'İptal Et',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // İptal onayı
  // ────────────────────────────────────────────────────────────────────────
  void _confirmCancel(EAsistan e) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Görevi İptal Et',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Bu görev silinsin mi? Bu işlem geri alınamaz.',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _cancelButton(
                      scheme: scheme,
                      onTap: () {
                        Navigator.pop(ctx);
                        _ds?.goreviptali(context, e.id);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PremiumGradientPill(
                      icon: Icons.close_rounded,
                      label: 'Vazgeç',
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Yardımcılar
  // ────────────────────────────────────────────────────────────────────────
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  String _formatSaat(DateTime? dt, String raw) {
    if (dt == null) return raw;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static const _aylarTr = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  String _formatTarih(DateTime dt) {
    return '${dt.day} ${_aylarTr[dt.month - 1]} ${dt.year}';
  }
}
