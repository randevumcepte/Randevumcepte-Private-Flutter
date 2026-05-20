import 'dart:async';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/datetimeformatting.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/seanstakibi.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

class SeanslarDashboard extends StatefulWidget {
  final dynamic isletmebilgi;
  final MusteriDanisan md;
  const SeanslarDashboard({
    super.key,
    required this.isletmebilgi,
    required this.md,
  });

  @override
  State<SeanslarDashboard> createState() => _SeanslarDashboardState();
}

class _SeanslarDashboardState extends State<SeanslarDashboard> {
  SeansDataSource? _ds;
  bool _initialized = false;

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _lastQuery = '';
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ds = SeansDataSource(
        rowsPerPage: 10,
        salonid: '',
        context: context,
        musteriid: widget.md.id.toString(),
        musteriMi: true,
      );
      _ds!.isLoadingNotifier.addListener(_onLoadChange);
      setState(() => _initialized = true);
    });
  }

  void _onLoadChange() {
    if (!mounted) return;
    setState(() {});
  }

  void _onSearchChanged() {
    final v = _searchCtrl.text;
    if (v.isEmpty || v.length >= 3) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 450), () {
        if (v != _lastQuery && _ds != null) {
          _lastQuery = v;
          _ds!.search(v);
        }
      });
    }
  }

  @override
  void dispose() {
    _ds?.isLoadingNotifier.removeListener(_onLoadChange);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _goToPage(int page) {
    if (_ds == null) return;
    _ds!.setPage(page);
  }

  bool get _isLoading => !_initialized || (_ds?.isLoadingNotifier.value ?? false);
  List<SeansTakip> get _items => _ds?.seanstakibi ?? const [];
  int get _currentPage => _ds?.currentPage ?? 1;
  int get _totalPages => _ds?.totalPages ?? 1;

  int get _totalToplam =>
      _items.fold(0, (a, e) => a + e.seansSayisi);
  int get _totalBekleyen =>
      _items.fold(0, (a, e) => a + e.bekleyenSeansSayisi);
  int get _totalGelinen =>
      _items.fold(0, (a, e) => a + e.gelinenSeansSayisi);
  int get _totalGelinmeyen =>
      _items.fold(0, (a, e) => a + e.gelinmeyenSeansSayisi);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.08),
                Colors.white,
              ),
              Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.04),
                Colors.white,
              ),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topBar(context),
              if (_searchOpen) _searchBar(context),
              if (_items.isNotEmpty) _statsRow(context),
              const SizedBox(height: 6),
              Expanded(child: _content(context)),
              if (_totalPages > 1) _pagination(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _topBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _circleIconBtn(
            context,
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seanslarım',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: scheme.onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isLoading
                      ? 'Yükleniyor...'
                      : (_items.isEmpty
                          ? 'Aktif paketin yok'
                          : '${_items.length} paket • $_totalToplam seans'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          _circleIconBtn(
            context,
            icon: _searchOpen
                ? Icons.close_rounded
                : Icons.search_rounded,
            onTap: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchCtrl.clear();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: scheme.primary, size: 20),
        ),
      ),
    );
  }

  // ── SEARCH ────────────────────────────────────────────────────────────────
  Widget _searchBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: TextStyle(
            fontSize: 14,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Paket veya hizmet ara...',
            hintStyle: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: scheme.primary,
            ),
            suffixIcon: _searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                    },
                  ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
      ),
    );
  }

  // ── STATS ─────────────────────────────────────────────────────────────────
  Widget _statsRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _statPill(
              context,
              icon: Icons.event_available_rounded,
              label: 'Bekleyen',
              value: _totalBekleyen,
              tint: ext.warningColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statPill(
              context,
              icon: Icons.check_circle_rounded,
              label: 'Gelinen',
              value: _totalGelinen,
              tint: ext.successColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statPill(
              context,
              icon: Icons.cancel_rounded,
              label: 'Gelmeyen',
              value: _totalGelinmeyen,
              tint: scheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color tint,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: tint.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tint, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: scheme.onSurface,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CONTENT ───────────────────────────────────────────────────────────────
  Widget _content(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (_items.isEmpty) {
      return _emptyState(context);
    }
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      onRefresh: () async {
        _goToPage(_currentPage);
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _paketCard(context, _items[i]),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.18),
                  scheme.tertiary.withValues(alpha: 0.18),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.spa_rounded,
              size: 42,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            _searchCtrl.text.isNotEmpty
                ? 'Sonuç bulunamadı'
                : 'Henüz seansın yok',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _searchCtrl.text.isNotEmpty
                ? 'Aramana uyan paket bulunamadı. Farklı kelime dene.'
                : 'Salondan paket aldığında, kalan seans haklarını burada görebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── PAKET CARD ────────────────────────────────────────────────────────────
  Widget _paketCard(BuildContext context, SeansTakip e) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;

    final total = e.seansSayisi;
    final tamamlanan = e.gelinenSeansSayisi;
    final progress = total == 0 ? 0.0 : (tamamlanan / total).clamp(0.0, 1.0);
    final tamamlandi = total > 0 && tamamlanan >= total;

    final paketAdi = e.paket.trim().isEmpty ? 'Paket' : e.paket;
    final hizmetSayisi = e.hizmetler.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSeansDetay(e),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary.withValues(alpha: 0.18),
                            scheme.tertiary.withValues(alpha: 0.18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.spa_rounded,
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
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: scheme.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hizmetSayisi > 0) ...[
                            const SizedBox(height: 3),
                            Text(
                              '$hizmetSayisi hizmet',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (tamamlandi)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: ext.successColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: ext.successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tamamlandı',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: ext.successColor,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurface.withValues(alpha: 0.4),
                        size: 22,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // PROGRESS
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor:
                              scheme.primary.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation(
                            tamamlandi
                                ? ext.successColor
                                : scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$tamamlanan / $total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface.withValues(alpha: 0.75),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // MINI STATS
                Row(
                  children: [
                    Expanded(
                      child: _miniStat(
                        context,
                        icon: Icons.event_available_rounded,
                        label: 'Bekleyen',
                        value: e.bekleyenSeansSayisi,
                        tint: ext.warningColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _miniStat(
                        context,
                        icon: Icons.check_rounded,
                        label: 'Gelinen',
                        value: e.gelinenSeansSayisi,
                        tint: ext.successColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _miniStat(
                        context,
                        icon: Icons.close_rounded,
                        label: 'Gelmeyen',
                        value: e.gelinmeyenSeansSayisi,
                        tint: scheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: tint,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── PAGINATION ────────────────────────────────────────────────────────────
  Widget _pagination(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(
            context,
            icon: Icons.chevron_left_rounded,
            enabled: _currentPage > 1 && !_isLoading,
            onTap: () => _goToPage(_currentPage - 1),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$_currentPage / $_totalPages',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _pageBtn(
            context,
            icon: Icons.chevron_right_rounded,
            enabled: _currentPage < _totalPages && !_isLoading,
            onTap: () => _goToPage(_currentPage + 1),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(
    BuildContext context, {
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  // ── DETAY BOTTOM SHEET ────────────────────────────────────────────────────
  void _openSeansDetay(SeansTakip e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final ext = ctx.appTheme;
        final paketAdi = e.paket.trim().isEmpty ? 'Paket' : e.paket;
        final total = e.seansSayisi;
        final tamamlanan = e.gelinenSeansSayisi;
        final progress = total == 0 ? 0.0 : (tamamlanan / total).clamp(0.0, 1.0);
        final tamamlandi = total > 0 && tamamlanan >= total;

        // Seansları hizmet adına göre grupla (orijinal sıralamayı koru)
        final groups = <String, List<dynamic>>{};
        final groupOrder = <String>[];
        for (final s in e.seanslar) {
          if (s is! Map) continue;
          final h = s['hizmet'];
          final hAd = (h is Map ? (h['hizmet_adi'] ?? '') : '').toString().trim();
          final key = hAd.isEmpty ? 'Hizmet' : hAd;
          if (!groups.containsKey(key)) {
            groups[key] = [];
            groupOrder.add(key);
          }
          groups[key]!.add(s);
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx2, scroll) {
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // HEADER
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary.withValues(alpha: 0.20),
                            scheme.tertiary.withValues(alpha: 0.16),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.spa_rounded,
                        color: scheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paketAdi,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seans Detayları',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // OVERALL PROGRESS
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      scheme.primary.withValues(alpha: 0.05),
                      Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.10),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Genel İlerleme',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withValues(alpha: 0.65),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$tamamlanan / $total',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor:
                              scheme.primary.withValues(alpha: 0.10),
                          valueColor: AlwaysStoppedAnimation(
                            tamamlandi ? ext.successColor : scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _miniStat(
                              ctx,
                              icon: Icons.event_available_rounded,
                              label: 'Bekleyen',
                              value: e.bekleyenSeansSayisi,
                              tint: ext.warningColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _miniStat(
                              ctx,
                              icon: Icons.check_rounded,
                              label: 'Gelinen',
                              value: e.gelinenSeansSayisi,
                              tint: ext.successColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _miniStat(
                              ctx,
                              icon: Icons.close_rounded,
                              label: 'Gelmeyen',
                              value: e.gelinmeyenSeansSayisi,
                              tint: scheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (e.seanslar.isEmpty)
                  _emptySeansBlock(ctx)
                else
                  ...groupOrder.expand((hAd) {
                    final list = groups[hAd]!;
                    return [
                      _hizmetGroupHeader(ctx, hAd, list.length),
                      const SizedBox(height: 8),
                      ...list.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _seansSatir(ctx, s as Map),
                          )),
                      const SizedBox(height: 8),
                    ];
                  }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _emptySeansBlock(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.error.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: scheme.error,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bu paket için henüz oluşturulmuş randevu bulunmamaktadır.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.error,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hizmetGroupHeader(BuildContext context, String hizmetAdi, int sayi) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hizmetAdi,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: scheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$sayi seans',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _seansSatir(BuildContext context, Map s) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;

    final seansNo = s['seans_no']?.toString() ?? '';
    final tarih = (s['seans_tarih'] ?? '').toString();
    final saat = (s['seans_saat'] ?? '').toString();
    final tarihSaat = tarihsaatdonustur(tarih, saat);
    final personel = (s['personel'] is Map)
        ? (s['personel']['personel_adi']?.toString() ?? '')
        : '';
    final oda = (s['oda'] is Map)
        ? (s['oda']['oda_adi']?.toString() ?? '')
        : '';
    final cihaz = (s['cihaz'] is Map)
        ? (s['cihaz']['cihaz_adi']?.toString() ?? '')
        : '';

    // Durum: geldi null = beklemede, 0 = gelmedi, 1 = geldi
    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    final geldi = s['geldi'];
    if (geldi == null) {
      statusColor = ext.warningColor;
      statusIcon = Icons.schedule_rounded;
      statusLabel = 'Beklemede';
    } else if (geldi == 0 || geldi == '0') {
      statusColor = scheme.error;
      statusIcon = Icons.close_rounded;
      statusLabel = 'Gelmedi';
    } else {
      statusColor = ext.successColor;
      statusIcon = Icons.check_rounded;
      statusLabel = 'Geldi';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
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
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  seansNo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tarihSaat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (personel.isNotEmpty || oda.isNotEmpty || cihaz.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (personel.isNotEmpty)
                  _infoPill(context,
                      icon: Icons.person_outline_rounded, text: personel),
                if (oda.isNotEmpty)
                  _infoPill(context,
                      icon: Icons.meeting_room_outlined, text: oda),
                if (cihaz.isNotEmpty)
                  _infoPill(context,
                      icon: Icons.precision_manufacturing_outlined,
                      text: cihaz),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoPill(BuildContext context,
      {required IconData icon, required String text}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.75),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
