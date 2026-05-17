import 'dart:async';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/randevular.dart';
import 'package:randevu_sistem/randevualma/randevual.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

class MusteriRandevulari extends StatefulWidget {
  final dynamic isletmebilgi;
  final MusteriDanisan md;
  final bool geriButonu;

  const MusteriRandevulari({
    Key? key,
    required this.isletmebilgi,
    required this.md,
    required this.geriButonu,
  }) : super(key: key);

  @override
  State<MusteriRandevulari> createState() => _MusteriRandevulariState();
}

class _MusteriRandevulariState extends State<MusteriRandevulari> {
  static const _tarihOptions = [
    'Tümü',
    'Bugün',
    'Yarın',
    'Bu ay',
    'Önümüzdeki ay',
    'Bu yıl',
  ];
  static const _durumOptions = [
    'Tümü',
    'Onay bekleyen',
    'Onaylı',
    'Reddedilen/İptal Edilen',
    'Müşteri tarafından iptal edilen',
  ];
  static const _olusturmaOptions = [
    'Tümü',
    'Salon',
    'Web',
    'Uygulama',
  ];

  String _selectedTarih = 'Tümü';
  String _selectedDurum = 'Tümü';
  String _selectedOlusturma = 'Tümü';

  RandevuDataSource? _ds;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ds = RandevuDataSource(
        kullanicirolu: 0,
        musteriMi: true,
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        durum: _selectedDurum,
        olusturma: _selectedOlusturma,
        salonid: '',
        tarih: _selectedTarih,
        context: context,
        musteriid: widget.md.id,
        personelid: '',
        cihazid: '',
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

  void _applyFilters() {
    if (_ds == null) return;
    _ds!.search('', _selectedDurum, _selectedOlusturma, _selectedTarih);
  }

  void _goToPage(int page) {
    if (_ds == null) return;
    _ds!.setPage(page, _selectedDurum, _selectedOlusturma, _selectedTarih);
  }

  int get _activeFilterCount {
    int n = 0;
    if (_selectedTarih != 'Tümü') n++;
    if (_selectedDurum != 'Tümü') n++;
    if (_selectedOlusturma != 'Tümü') n++;
    return n;
  }

  bool get _isLoading => !_initialized || (_ds?.isLoadingNotifier.value ?? false);
  List<Randevu> get _randevular => _ds?.randevu ?? const [];
  int get _currentPage => _ds?.currentPage ?? 1;
  int get _totalPages => _ds?.totalPages ?? 1;
  int get _totalRows => _ds?.totalRows ?? 0;

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
              _filterStrip(context),
              const SizedBox(height: 6),
              Expanded(child: _content(context)),
              if (_totalPages > 1) _pagination(context),
            ],
          ),
        ),
      ),
      floatingActionButton: _fab(context),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _topBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          if (widget.geriButonu)
            _circleIconBtn(
              context,
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 44),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Randevularım',
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
                      : (_randevular.isEmpty
                          ? 'Henüz randevun yok'
                          : '${_totalRows > 0 ? _totalRows : _randevular.length} randevu'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _circleIconBtn(
                context,
                icon: Icons.tune_rounded,
                onTap: _openFilterSheet,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
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

  // ── FILTER STRIP (yatay tarih chip'leri) ─────────────────────────────────
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
            label: v,
            selected: _selectedTarih == v,
            onTap: () {
              if (_selectedTarih == v) return;
              setState(() => _selectedTarih = v);
              _applyFilters();
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
    if (_isLoading && _randevular.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (_randevular.isEmpty) {
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _randevular.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) =>
            _randevuCard(context, _randevular[i]),
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
              Icons.calendar_today_rounded,
              size: 42,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Henüz randevu yok',
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
            _activeFilterCount > 0
                ? 'Seçili filtrelere uyan randevu bulunamadı. Filtreleri sıfırlamayı dene.'
                : 'İlk randevunu oluşturmak için aşağıdaki butona dokun.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_activeFilterCount > 0)
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedTarih = 'Tümü';
                  _selectedDurum = 'Tümü';
                  _selectedOlusturma = 'Tümü';
                });
                _applyFilters();
              },
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Filtreleri Sıfırla'),
            ),
          )
        else
          Center(
            child: FilledButton.icon(
              onPressed: _goToRandevuAl,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Randevu Oluştur'),
            ),
          ),
      ],
    );
  }

  // ── RANDEVU CARD ─────────────────────────────────────────────────────────
  Widget _randevuCard(BuildContext context, Randevu r) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final dt = _parseTarih(r.tarih);
    final status = _statusOf(r.durum);
    final hizmetler = _hizmetText(r.hizmetler);
    final personeller = _personelText(r.yardimci_personeller);

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
          onTap: () => _openDetailSheet(r),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SOL: tarih bloğu (gradient)
                Container(
                  width: 78,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        status.tint(scheme, ext).withValues(alpha: 0.16),
                        status.tint(scheme, ext).withValues(alpha: 0.06),
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
                          color: status.tint(scheme, ext),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dt == null ? '--' : dt.day.toString(),
                        style: TextStyle(
                          fontSize: 28,
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
                // SAĞ: bilgi bloğu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dt == null
                                  ? r.tarih
                                  : '${_pad(dt.hour)}:${_pad(dt.minute)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const Spacer(),
                            _statusBadge(context, status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hizmetler.isEmpty
                              ? 'Hizmet bilgisi yok'
                              : hizmetler,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: scheme.onSurface,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (personeller.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 13,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  personeller,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _statusBadge(BuildContext context, _RandevuStatus status) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final c = status.tint(scheme, ext);
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
            status.label,
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

  // ── FAB ──────────────────────────────────────────────────────────────────
  Widget _fab(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _goToRandevuAl,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }

  void _goToRandevuAl() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 400),
        child: RandevuAl(),
      ),
    ).then((_) => _applyFilters());
  }

  // ── FILTER BOTTOM SHEET ──────────────────────────────────────────────────
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        String tempTarih = _selectedTarih;
        String tempDurum = _selectedDurum;
        String tempOlusturma = _selectedOlusturma;
        final scheme = Theme.of(ctx).colorScheme;

        return StatefulBuilder(
          builder: (ctx, setSB) {
            Widget section(String title, List<String> options, String value,
                ValueChanged<String> onSel) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((opt) {
                      final selected = opt == value;
                      return _chip(
                        ctx,
                        label: opt,
                        selected: selected,
                        onTap: () => setSB(() => onSel(opt)),
                      );
                    }).toList(),
                  ),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Filtrele',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: scheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setSB(() {
                          tempTarih = 'Tümü';
                          tempDurum = 'Tümü';
                          tempOlusturma = 'Tümü';
                        }),
                        child: const Text('Sıfırla'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  section('Tarih', _tarihOptions, tempTarih,
                      (v) => tempTarih = v),
                  const SizedBox(height: 18),
                  section('Durum', _durumOptions, tempDurum,
                      (v) => tempDurum = v),
                  const SizedBox(height: 18),
                  section('Oluşturulduğu Yer', _olusturmaOptions,
                      tempOlusturma, (v) => tempOlusturma = v),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedTarih = tempTarih;
                          _selectedDurum = tempDurum;
                          _selectedOlusturma = tempOlusturma;
                        });
                        _applyFilters();
                      },
                      child: const Text('Sonuçları Göster'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── DETAY BOTTOM SHEET ───────────────────────────────────────────────────
  void _openDetailSheet(Randevu r) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final dt = _parseTarih(r.tarih);
    final status = _statusOf(r.durum);
    final hizmetler = _hizmetText(r.hizmetler);
    final personeller = _personelText(r.yardimci_personeller);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scroll) {
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
                const SizedBox(height: 18),
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
                            status.tint(scheme, ext).withValues(alpha: 0.20),
                            status.tint(scheme, ext).withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.event_rounded,
                        color: status.tint(scheme, ext),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dt == null
                                ? r.tarih
                                : '${dt.day} ${_ayUzun(dt.month)} ${dt.year}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dt == null
                                ? ''
                                : '${_gunAdiUzun(dt.weekday)} • ${_pad(dt.hour)}:${_pad(dt.minute)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(ctx, status),
                  ],
                ),
                const SizedBox(height: 22),
                _detailTile(ctx,
                    icon: Icons.spa_rounded,
                    label: 'Hizmet(ler)',
                    value: hizmetler.isEmpty ? 'Belirtilmemiş' : hizmetler),
                if (personeller.isNotEmpty)
                  _detailTile(ctx,
                      icon: Icons.person_outline_rounded,
                      label: 'Personel',
                      value: personeller),
                if (_safeText(r.musterinotu).isNotEmpty)
                  _detailTile(ctx,
                      icon: Icons.sticky_note_2_outlined,
                      label: 'Notum',
                      value: r.musterinotu),
                if (_safeText(r.personelnotu).isNotEmpty)
                  _detailTile(ctx,
                      icon: Icons.note_alt_outlined,
                      label: 'Salon Notu',
                      value: r.personelnotu),
                _detailTile(ctx,
                    icon: Icons.history_rounded,
                    label: 'Oluşturulma',
                    value: _safeText(r.olusturulma)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailTile(BuildContext context,
      {required IconData icon,
      required String label,
      required String value}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.04),
          Colors.white,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: scheme.primary),
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
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────
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
      'Oca','Şub','Mar','Nis','May','Haz',
      'Tem','Ağu','Eyl','Eki','Kas','Ara',
    ];
    return a[(m - 1).clamp(0, 11)];
  }

  static String _ayUzun(int m) {
    const a = [
      'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
      'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık',
    ];
    return a[(m - 1).clamp(0, 11)];
  }

  static String _safeText(String? s) {
    if (s == null) return '';
    final t = s.trim();
    if (t.isEmpty || t == 'null') return '';
    return t;
  }

  static String _hizmetText(dynamic hizmetler) {
    try {
      if (hizmetler is List) {
        final names = <String>[];
        for (final h in hizmetler) {
          if (h is Map) {
            // Backend payload: hizmetler[i]["hizmetler"]["hizmet_adi"]
            final nested = h['hizmetler'];
            if (nested is Map) {
              final n = nested['hizmet_adi'] ??
                  nested['ad'] ??
                  nested['name'];
              if (n != null && n.toString().trim().isNotEmpty) {
                names.add(n.toString());
                continue;
              }
            }
            final n = h['hizmet_adi'] ??
                h['ad'] ??
                h['name'] ??
                h['baslik'] ??
                h['title'];
            if (n != null && n.toString().trim().isNotEmpty) {
              names.add(n.toString());
            }
          } else if (h is String && h.trim().isNotEmpty) {
            names.add(h);
          }
        }
        return names.join(', ');
      }
      if (hizmetler is String) return _safeText(hizmetler);
    } catch (_) {}
    return '';
  }

  static String _personelText(String raw) {
    final t = _safeText(raw);
    if (t.isEmpty) return '';
    return t;
  }

  static _RandevuStatus _statusOf(String durum) {
    switch (durum) {
      case '1':
        return const _RandevuStatus.onayli();
      case '2':
        return const _RandevuStatus.reddedildi();
      case '3':
        return const _RandevuStatus.iptal();
      case '0':
      default:
        return const _RandevuStatus.bekliyor();
    }
  }
}

// ── STATUS ENUM-LIKE ──────────────────────────────────────────────────────────
class _RandevuStatus {
  final String label;
  final String key;
  const _RandevuStatus._(this.label, this.key);

  const _RandevuStatus.bekliyor() : this._('Onay Bekliyor', 'bekliyor');
  const _RandevuStatus.onayli() : this._('Onaylı', 'onayli');
  const _RandevuStatus.reddedildi() : this._('Reddedildi', 'red');
  const _RandevuStatus.iptal() : this._('İptal Edildi', 'iptal');

  Color tint(ColorScheme scheme, AppThemeExtension ext) {
    switch (key) {
      case 'onayli':
        return ext.successColor;
      case 'red':
        return scheme.error;
      case 'iptal':
        return scheme.onSurfaceVariant;
      case 'bekliyor':
      default:
        return ext.warningColor;
    }
  }
}
