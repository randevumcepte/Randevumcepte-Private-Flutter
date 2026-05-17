import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Models/adisyonlar.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/satisturleri.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

class MusteriPaneliAdiayonlari extends StatefulWidget {
  final MusteriDanisan kullanici;
  final dynamic isletmebilgi;

  const MusteriPaneliAdiayonlari({
    Key? key,
    required this.kullanici,
    required this.isletmebilgi,
  }) : super(key: key);

  @override
  State<MusteriPaneliAdiayonlari> createState() =>
      _MusteriPaneliAdiayonlariState();
}

class _MusteriPaneliAdiayonlariState extends State<MusteriPaneliAdiayonlari> {
  final List<SatisTuru> _turler = [
    SatisTuru(id: '', satisturu: 'Tümü'),
    SatisTuru(id: '1', satisturu: 'Hizmet'),
    SatisTuru(id: '2', satisturu: 'Paket'),
    SatisTuru(id: '3', satisturu: 'Ürün'),
  ];

  late SatisTuru _selectedTur = _turler[0];

  SatisDataSource? _ds;
  bool _initialized = false;

  final String _tarih1 = '1970-09-01';
  final String _tarih2 = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ds = SatisDataSource(
        musteriMi: true,
        personelMi: false,
        kullanicirolu: 0,
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        salonid: widget.isletmebilgi['id'].toString(),
        context: context,
        tarih1: _tarih1,
        tarih2: _tarih2,
        musteriid: widget.kullanici.id,
        personelid: '',
        userid: '',
        tur: _selectedTur.id,
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
    _ds?.search(_tarih1, _tarih2, widget.kullanici.id, _selectedTur.id, true);
  }

  void _goToPage(int page) {
    _ds?.setPage(page, _tarih1, _tarih2, widget.kullanici.id, _selectedTur.id);
  }

  bool get _isLoading =>
      !_initialized || (_ds?.isLoadingNotifier.value ?? false);
  List<Adisyon> get _items => _ds?.adisyon ?? const [];
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
              const SizedBox(height: 10),
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
                  'Satın Aldıklarım',
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
                          : '$_totalRows kayıt'),
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

  Widget _filterStrip(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _turler.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final v = _turler[i];
          return _chip(
            context,
            label: v.satisturu,
            selected: _selectedTur.id == v.id,
            onTap: () {
              if (_selectedTur.id == v.id) return;
              setState(() => _selectedTur = v);
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
        itemBuilder: (context, i) => _satisCard(context, _items[i]),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _selectedTur.id.isNotEmpty;
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
              Icons.receipt_long_rounded,
              size: 42,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            filtered
                ? '${_selectedTur.satisturu} satışı yok'
                : 'Henüz kaydın yok',
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
                ? 'Bu kategoride henüz alışveriş yok.'
                : 'Satın aldıkların burada listelenecek.',
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

  ({IconData icon, String label}) _turBilgi(String turStr) {
    switch (turStr) {
      case '1':
      case 'Hizmet':
        return (icon: Icons.spa_rounded, label: 'Hizmet');
      case '2':
      case 'Paket':
        return (icon: Icons.card_giftcard_rounded, label: 'Paket');
      case '3':
      case 'Ürün':
        return (icon: Icons.shopping_bag_rounded, label: 'Ürün');
      default:
        return (icon: Icons.receipt_long_rounded, label: 'Satış');
    }
  }

  Widget _satisCard(BuildContext context, Adisyon a) {
    final scheme = Theme.of(context).colorScheme;
    final dt = _parseTarih(a.acilis_tarihi);
    final turInfo = _turBilgi(a.satis_turu);
    final satirlar = _temizSatirlar(a.icerik);

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
                Container(
                  width: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.primary.withValues(alpha: 0.16),
                        scheme.primary.withValues(alpha: 0.06),
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
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              turInfo.icon,
                              size: 14,
                              color: scheme.primary.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              turInfo.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            if (dt != null)
                              Text(
                                '${_pad(dt.hour)}:${_pad(dt.minute)}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          satirlar.isEmpty ? 'Bilgi yok' : satirlar.first,
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
                        if (satirlar.length > 1) ...[
                          const SizedBox(height: 4),
                          Text(
                            '+${satirlar.length - 1} kalem daha',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: scheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        final dt = _parseTarih(a.acilis_tarihi);
        final turInfo = _turBilgi(a.satis_turu);
        final satirlar = _temizSatirlar(a.icerik);

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
                      turInfo.icon,
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
                          '${turInfo.label} #${a.id}',
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
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'İÇERİK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${satirlar.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (satirlar.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Bilgi yok',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontSize: 13,
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < satirlar.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      scheme.primary.withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  satirlar[i],
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i < satirlar.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: scheme.primary.withValues(alpha: 0.08),
                          ),
                      ],
                    ],
                  ),
                ),
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

  // ── HELPERS ──────────────────────────────────────────────────────────────
  static List<String> _temizSatirlar(String s) {
    if (s.trim().isEmpty) return const [];
    return s
        .split(RegExp(r'[\n\r]+'))
        .map(_temizSatir)
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String _temizSatir(String s) {
    var t = s.trim();
    // Backend formati: "{ad} (Ü|H|P)  Personel Adi  400,00 ₺"
    // Etiketten itibaren personel+fiyat — satir sonuna kadar sil
    t = t.replaceAll(RegExp(r'\s*\([HÜPKhüpk]\).*$'), '');
    t = t.replaceAll(
      RegExp(r'\([^)]*(₺|TL|tl|tutar|fiyat|fıyat)[^)]*\)',
          caseSensitive: false),
      '',
    );
    t = t.replaceAll(RegExp(r'[\d.,]+\s*₺'), '');
    t = t.replaceAll(RegExp(r'₺\s*[\d.,]+'), '');
    t = t.replaceAll(RegExp(r'[\d.,]+\s*TL', caseSensitive: false), '');
    return t.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
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
