import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/adisyonlar.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

class MusteriALinanUrunlerDashboard extends StatefulWidget {
  final MusteriDanisan kullanici;
  final dynamic isletmebilgi;
  final dynamic kullanicirolu;

  const MusteriALinanUrunlerDashboard({
    Key? key,
    required this.kullanici,
    required this.isletmebilgi,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  State<MusteriALinanUrunlerDashboard> createState() =>
      _MusteriALinanUrunlerDashboardState();
}

class _MusteriALinanUrunlerDashboardState
    extends State<MusteriALinanUrunlerDashboard> {
  static const List<_TarihFiltre> _tarihOptions = [
    _TarihFiltre(label: 'Tümü', from: '1970-09-01'),
    _TarihFiltre(label: 'Bu ay', kind: _TarihKind.buAy),
    _TarihFiltre(label: 'Geçen ay', kind: _TarihKind.gecenAy),
    _TarihFiltre(label: 'Bu yıl', kind: _TarihKind.buYil),
    _TarihFiltre(label: 'Son 1 yıl', kind: _TarihKind.son1Yil),
  ];

  _TarihFiltre _selectedTarih = _tarihOptions[0];

  SatisDataSource? _ds;
  bool _initialized = false;

  String get _tarih1 {
    final r = _selectedTarih.range();
    return r.$1;
  }

  String get _tarih2 {
    final r = _selectedTarih.range();
    return r.$2;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ds = SatisDataSource(
        kullanicirolu: widget.kullanicirolu is int
            ? widget.kullanicirolu
            : int.tryParse(widget.kullanicirolu.toString()) ?? 0,
        personelMi: false,
        musteriMi: true,
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        salonid: widget.isletmebilgi['id'].toString(),
        context: context,
        tarih1: _tarih1,
        tarih2: _tarih2,
        musteriid: widget.kullanici.id,
        personelid: '',
        userid: '',
        tur: '3',
      );
      _ds!.isLoadingNotifier.addListener(_onLoadChange);
      setState(() => _initialized = true);
    });
  }

  void _onLoadChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _ds?.isLoadingNotifier.removeListener(_onLoadChange);
    super.dispose();
  }

  void _applyFilter() {
    _ds?.search(_tarih1, _tarih2, widget.kullanici.id, '3', true);
  }

  void _goToPage(int page) {
    _ds?.setPage(page, _tarih1, _tarih2, widget.kullanici.id, '3');
  }

  bool get _isLoading => !_initialized || (_ds?.isLoadingNotifier.value ?? false);
  List<Adisyon> get _items => _ds?.adisyon ?? const [];
  int get _currentPage => _ds?.currentPage ?? 1;
  int get _totalPages => _ds?.totalPages ?? 1;

  ({double toplam, double odenen, double kalan}) get _pageTotals {
    double t = 0, o = 0, k = 0;
    for (final a in _items) {
      t += double.tryParse(a.toplam_numeric) ?? 0;
      o += double.tryParse(a.odenen_numeric) ?? 0;
      k += double.tryParse(a.kalan_tutar_numeric) ?? 0;
    }
    return (toplam: t, odenen: o, kalan: k);
  }

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
              _heroSummary(context),
              const SizedBox(height: 12),
              _filterStrip(context),
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
                  'Aldığım Ürünler',
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
                          ? 'Kayıt bulunamadı'
                          : '${_ds?.totalRows ?? _items.length} satış kaydı'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
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

  // ── HERO SUMMARY ─────────────────────────────────────────────────────────
  Widget _heroSummary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = _pageTotals;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.5),
                scheme.primary,
              ),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.30),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sayfa özeti',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedTarih.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _heroStat(
                    context,
                    label: 'Toplam',
                    value: _fmt(totals.toplam),
                    color: Colors.white,
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _heroStat(
                    context,
                    label: 'Ödenen',
                    value: _fmt(totals.odenen),
                    color: Colors.white,
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _heroStat(
                    context,
                    label: 'Kalan',
                    value: _fmt(totals.kalan),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value ₺',
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── FILTER STRIP ─────────────────────────────────────────────────────────
  Widget _filterStrip(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tarihOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final v = _tarihOptions[i];
          return _chip(
            context,
            label: v.label,
            selected: _selectedTarih.label == v.label,
            onTap: () {
              if (_selectedTarih.label == v.label) return;
              setState(() => _selectedTarih = v);
              _applyFilter();
            },
          );
        },
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : scheme.primary.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : scheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }

  // ── CONTENT ──────────────────────────────────────────────────────────────
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _urunCard(context, _items[i]),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _selectedTarih.label != 'Tümü';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
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
              Icons.shopping_bag_outlined,
              size: 42,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            filtered ? 'Bu aralıkta ürün yok' : 'Henüz ürün almamışsın',
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
            filtered
                ? 'Seçtiğin tarih aralığında satın aldığın ürün bulunmuyor.'
                : 'Satın aldığın ürünler burada listelenecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (filtered)
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() => _selectedTarih = _tarihOptions[0]);
                _applyFilter();
              },
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Filtreyi Sıfırla'),
            ),
          ),
      ],
    );
  }

  // ── URUN CARD ────────────────────────────────────────────────────────────
  Widget _urunCard(BuildContext context, Adisyon a) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final dt = _parseTarih(a.acilis_tarihi);
    final kalan = double.tryParse(a.kalan_tutar_numeric) ?? 0;
    final hasBorc = kalan > 0.0001;
    final accent = hasBorc ? ext.warningColor : ext.successColor;

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
          onTap: () => _openDetailSheet(a),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SOL: tarih bloğu
                Container(
                  width: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        accent.withValues(alpha: 0.18),
                        accent.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dt == null ? '--' : _gunAdi(dt.weekday),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dt == null ? '--' : dt.day.toString(),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: scheme.onSurface,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dt == null ? '' : _ayKisa(dt.month),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.7),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // SAĞ: bilgi
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _temizIcerik(a.icerik),
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: scheme.onSurface,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _statusBadge(
                              context,
                              hasBorc: hasBorc,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _moneyChip(
                                context,
                                label: 'Toplam',
                                value: a.toplam,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _moneyChip(
                                context,
                                label: 'Ödenen',
                                value: a.odenen,
                                color: ext.successColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _moneyChip(
                                context,
                                label: 'Kalan',
                                value: a.kalan_tutar,
                                color: hasBorc
                                    ? ext.warningColor
                                    : scheme.onSurface
                                        .withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, {required bool hasBorc}) {
    final ext = context.appTheme;
    final c = hasBorc ? ext.warningColor : ext.successColor;
    final label = hasBorc ? 'Borçlu' : 'Ödendi';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: c,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyChip(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.85),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value ₺',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── PAGINATION ───────────────────────────────────────────────────────────
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  // ── DETAY BOTTOM SHEET ───────────────────────────────────────────────────
  void _openDetailSheet(Adisyon a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final ext = context.appTheme;
        final dt = _parseTarih(a.acilis_tarihi);
        final kalan = double.tryParse(a.kalan_tutar_numeric) ?? 0;
        final hasBorc = kalan > 0.0001;

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
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
                          'Satış #${a.id}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dt == null
                              ? a.acilis_tarihi
                              : '${_gunAdiUzun(dt.weekday)}, ${dt.day} ${_ayUzun(dt.month)} ${dt.year} • ${_pad(dt.hour)}:${_pad(dt.minute)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(context, hasBorc: hasBorc),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ürünler',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _temizIcerik(a.icerik),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _detailMoney(
                      context,
                      label: 'Toplam',
                      value: a.toplam,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _detailMoney(
                      context,
                      label: 'Ödenen',
                      value: a.odenen,
                      color: ext.successColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _detailMoney(
                      context,
                      label: 'Kalan',
                      value: a.kalan_tutar,
                      color: hasBorc
                          ? ext.warningColor
                          : scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              if (a.son_tahsilat_tarihi.isNotEmpty &&
                  a.son_tahsilat_tarihi != 'null') ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Son tahsilat: ${a.son_tahsilat_tarihi}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailMoney(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.85),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value ₺',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────
  static String _temizIcerik(String s) {
    return s.replaceAll('\n', ' • ').trim();
  }

  static String _fmt(double v) {
    final f = NumberFormat('#,##0.##', 'tr_TR');
    return f.format(v);
  }

  static DateTime? _parseTarih(String s) {
    try {
      final clean = s.trim().replaceAll('T', ' ');
      final parts = clean.split(' ');
      if (parts.length >= 2) {
        return DateTime.parse('${parts[0]} ${parts[1]}');
      }
      return DateTime.parse(parts[0]);
    } catch (_) {
      return null;
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _gunAdi(int weekday) {
    const g = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return g[(weekday - 1).clamp(0, 6)];
  }

  static String _gunAdiUzun(int weekday) {
    const g = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return g[(weekday - 1).clamp(0, 6)];
  }

  static String _ayKisa(int m) {
    const a = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return a[(m - 1).clamp(0, 11)];
  }

  static String _ayUzun(int m) {
    const a = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return a[(m - 1).clamp(0, 11)];
  }
}

enum _TarihKind { sabit, buAy, gecenAy, buYil, son1Yil }

class _TarihFiltre {
  final String label;
  final _TarihKind kind;
  final String from;

  const _TarihFiltre({
    required this.label,
    this.kind = _TarihKind.sabit,
    this.from = '1970-09-01',
  });

  (String, String) range() {
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');
    switch (kind) {
      case _TarihKind.sabit:
        return (from, fmt.format(now));
      case _TarihKind.buAy:
        return (fmt.format(DateTime(now.year, now.month, 1)), fmt.format(now));
      case _TarihKind.gecenAy:
        final ilk = DateTime(now.year, now.month - 1, 1);
        final son = DateTime(now.year, now.month, 0);
        return (fmt.format(ilk), fmt.format(son));
      case _TarihKind.buYil:
        return (fmt.format(DateTime(now.year, 1, 1)), fmt.format(now));
      case _TarihKind.son1Yil:
        final ilk = DateTime(now.year - 1, now.month, now.day);
        return (fmt.format(ilk), fmt.format(now));
    }
  }
}
