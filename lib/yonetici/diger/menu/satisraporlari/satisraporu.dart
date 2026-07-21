import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/personel.dart';
import '../musteriler/musteridetaylar.dart';

const _kGreen = Color(0xFF10B981);
const _kAmber = Color(0xFFF59E0B);

class SalesReportsPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;

  const SalesReportsPage({
    super.key,
    required this.isletmebilgi,
    required this.kullanicirolu,
  });

  @override
  State<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends State<SalesReportsPage>
    with TickerProviderStateMixin {
  static const _tabs = ['Hizmet', 'Ürün', 'Paket', 'Personel'];

  late final TabController _tabController;
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final NumberFormat _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '');

  late final DateTimeRange _defaultRange;

  final Map<String, DateTimeRange> _ranges = {};
  final Map<String, Personel?> _staff = {};
  final Map<String, List<dynamic>> _data = {};
  final Map<String, _Totals> _totals = {};
  final Map<String, bool> _loaded = {};
  final Map<String, bool> _loading = {};
  final Map<String, String> _search = {};
  final Map<String, Set<int>> _expanded = {};

  List<Personel>? _personeller;
  bool _personellerLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _defaultRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    for (final t in _tabs) {
      _ranges[t] = _defaultRange;
      _staff[t] = null;
      _search[t] = '';
      _expanded[t] = <int>{};
      _totals[t] = _Totals.zero;
    }
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTab(_tabs[0]);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = _tabs[_tabController.index];
    if (_loaded[tab] != true && _loading[tab] != true) {
      _loadTab(tab);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  double _asD(dynamic v) => v is num ? v.toDouble() : 0.0;

  Future<void> _loadTab(String tab, {bool force = false}) async {
    if (_loading[tab] == true) return;
    if (!force && _loaded[tab] == true) return;

    setState(() {
      _loading[tab] = true;
      if (force) _loaded[tab] = false;
    });

    // Seçili şube (Seans Takibi vb. ekranlarla tutarlı). isletmebilgi['id']
    // çok şubeli hesapta seçili şubeden farklı olabiliyor -> rapor boş geliyordu.
    final salonId = (await secilisalonid()) ?? widget.isletmebilgi['id'].toString();
    final start = DateFormat('yyyy-MM-dd').format(_ranges[tab]!.start);
    final end = DateFormat('yyyy-MM-dd').format(_ranges[tab]!.end);
    final personelId = _staff[tab]?.id ?? '';

    List<dynamic> data = const [];
    try {
      switch (tab) {
        case 'Hizmet':
          data = await hizmetRaporlari(salonId, start, end, personelId);
          break;
        case 'Ürün':
          data = await urunRaporlari(salonId, start, end, personelId);
          break;
        case 'Paket':
          data = await paketRaporlari(salonId, start, end, personelId);
          break;
        case 'Personel':
          data = await personelRaporlari(salonId, start, end);
          break;
      }
    } catch (_) {
      data = const [];
    }

    double tutar = 0, kazanc = 0, alacak = 0;
    if (tab != 'Personel') {
      for (final it in data) {
        tutar += _asD(it['toplamTutarNumeric']);
        kazanc += _asD(it['toplamKazancNumeric']);
        alacak += _asD(it['borcNumeric']);
      }
    }

    if (!mounted) return;
    setState(() {
      _data[tab] = data;
      _totals[tab] = _Totals(tutar, kazanc, alacak);
      _expanded[tab] = <int>{};
      _loaded[tab] = true;
      _loading[tab] = false;
    });
  }

  Future<void> _ensurePersoneller() async {
    if (_personeller != null || _personellerLoading) return;
    _personellerLoading = true;
    try {
      _personeller = await personellistegetir(
        (await secilisalonid()) ?? widget.isletmebilgi['id'].toString(),
      );
    } catch (_) {
      _personeller = <Personel>[];
    }
    _personellerLoading = false;
    if (mounted) setState(() {});
  }

  bool _isDefaultRange(DateTimeRange r) =>
      r.start == _defaultRange.start && r.end == _defaultRange.end;

  bool _tabHasFilter(String tab) {
    final r = _ranges[tab];
    if (r == null) return false;
    final dateChanged = !_isDefaultRange(r);
    final staffSet = _staff[tab] != null;
    return dateChanged || staffSet;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text(
          'Satış Raporları',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          indicatorColor: scheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          // Eşit genişlikli sekmelerde "Personel"(+aktif nokta) sığmayıp 0.31px
          // taşıyordu; iç boşluğu küçültünce içeriğe yer açılır, taşma biter.
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: _tabs.map((t) {
            final active = _tabHasFilter(t);
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t),
                  if (active) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map(_buildTabBody).toList(),
      ),
    );
  }

  Widget _buildTabBody(String tab) {
    final loaded = _loaded[tab] == true;
    if (!loaded) {
      return _buildSkeleton(tab);
    }

    final data = _data[tab] ?? const [];
    final query = _search[tab] ?? '';
    final filtered = _filterByQuery(tab, data, query);

    return RefreshIndicator(
      onRefresh: () => _loadTab(tab, force: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (tab != 'Personel')
            SliverToBoxAdapter(child: _buildHero(tab)),
          SliverToBoxAdapter(child: _buildQuickChips(tab)),
          SliverToBoxAdapter(child: _buildSearchRow(tab)),
          SliverToBoxAdapter(child: _buildListHeader(tab, filtered.length)),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(tab, query),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _buildItemCard(tab, filtered[i], i),
              ),
            ),
        ],
      ),
    );
  }

  List<dynamic> _filterByQuery(String tab, List<dynamic> data, String query) {
    if (query.isEmpty) return data;
    final q = query.toLowerCase();
    final key = switch (tab) {
      'Ürün' => 'urun_adi',
      'Paket' => 'paket_adi',
      'Personel' => 'personel_adi',
      _ => 'hizmet_adi',
    };
    return data.where((it) {
      final name = (it[key] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  // ---------- Hero ----------

  Widget _buildHero(String tab) {
    final scheme = Theme.of(context).colorScheme;
    final t = _totals[tab] ?? _Totals.zero;
    final dr = _ranges[tab]!;
    final dateLabel = _quickLabelOf(dr) ??
        '${_dateFormat.format(dr.start)} – ${_dateFormat.format(dr.end)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.55) ?? scheme.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _heroIcon(tab),
                color: Colors.white.withValues(alpha: 0.92),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '$tab Geliri',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _tl.format(t.tutar),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '₺',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _heroMini(
                  'Kazanç',
                  _tl.format(t.kazanc),
                  Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroMini(
                  'Alacak',
                  _tl.format(t.alacak),
                  Icons.schedule_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMini(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.88)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$value ₺',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Quick chips ----------

  Widget _buildQuickChips(String tab) {
    final options = _quickRanges();
    final current = _ranges[tab]!;
    final isCustom = _quickLabelOf(current) == null;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
              child: _chip(
                label: o.label,
                icon: o.icon,
                selected: !isCustom &&
                    current.start == o.range.start &&
                    current.end == o.range.end,
                onTap: () {
                  setState(() {
                    _ranges[tab] = o.range;
                  });
                  _loadTab(tab, force: true);
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
            child: _chip(
              label: isCustom ? _dateRangeShort(current) : 'Özel',
              icon: Icons.date_range_rounded,
              selected: isCustom,
              onTap: () => _openCustomDatePicker(tab),
            ),
          ),
        ],
      ),
    );
  }

  String _dateRangeShort(DateTimeRange r) {
    final f = DateFormat('d MMM', 'tr_TR');
    return '${f.format(r.start)} – ${f.format(r.end)}';
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary
          : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Search + staff button ----------

  Widget _buildSearchRow(String tab) {
    final scheme = Theme.of(context).colorScheme;
    final hint = tab == 'Personel'
        ? 'Personel ara…'
        : '${tab.toLowerCase()} ara…';
    final controller = TextEditingController(text: _search[tab] ?? '');
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: controller,
                onChanged: (v) {
                  _search[tab] = v;
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 13.5,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  suffixIcon: (_search[tab] ?? '').isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _search[tab] = '';
                            setState(() {});
                          },
                        ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          if (tab != 'Personel') ...[
            const SizedBox(width: 8),
            _staffButton(tab),
          ],
        ],
      ),
    );
  }

  Widget _staffButton(String tab) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _staff[tab];
    final active = selected != null;
    return Material(
      color: active
          ? scheme.primary
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openStaffFilter(tab),
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: active ? 10 : 14),
          child: Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 18,
                color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              if (active) ...[
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    selected.personel_adi,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() {
                      _staff[tab] = null;
                    });
                    _loadTab(tab, force: true);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------- List header ----------

  Widget _buildListHeader(String tab, int count) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 10),
      child: Row(
        children: [
          Text(
            tab == 'Personel' ? 'Personel Detayları' : '$tab Detayları',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Item card ----------

  Widget _buildItemCard(String tab, dynamic item, int index) {
    if (tab == 'Personel') return _buildStaffCard(item, index);

    final scheme = Theme.of(context).colorScheme;
    final isExpanded = _expanded[tab]!.contains(index);

    final nameKey = switch (tab) {
      'Ürün' => 'urun_adi',
      'Paket' => 'paket_adi',
      _ => 'hizmet_adi',
    };
    final name = (item[nameKey] ?? '').toString();
    final adet = (item['adet'] ?? '0').toString();
    final tutar = (item['toplam_tutar'] ?? '0').toString();
    final kazanc = (item['toplamKazanc'] ?? '0').toString();
    final borc = (item['borc'] ?? '0').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expanded[tab]!.remove(index);
              } else {
                _expanded[tab]!.add(index);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _itemIcon(tab),
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
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$tutar ₺  ·  $adet adet',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 180),
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: !isExpanded
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: [
                              Divider(
                                height: 1,
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _metric(
                                      'Kazanç',
                                      '$kazanc ₺',
                                      Icons.trending_up_rounded,
                                      _kGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _metric(
                                      'Alacak',
                                      '$borc ₺',
                                      Icons.schedule_rounded,
                                      _kAmber,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showCustomerList(tab, item),
                                  icon: const Icon(
                                    Icons.people_alt_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Müşteri Listesi'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: scheme.primary,
                                    side: BorderSide(
                                      color: scheme.primary
                                          .withValues(alpha: 0.4),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
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

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Staff card ----------

  Widget _buildStaffCard(dynamic item, int index) {
    final scheme = Theme.of(context).colorScheme;
    final isExpanded = _expanded['Personel']!.contains(index);
    final name = (item['personel_adi'] ?? 'Belirtilmemiş').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final stats = <Map<String, String>>[
      {'label': 'Hizmet Geliri', 'value': '${item['hizmet_geliri']} ₺'},
      {'label': 'Hizmet Primi', 'value': '${item['hizmet_primi']} ₺'},
      {'label': 'Ürün Geliri', 'value': '${item['urun_geliri']} ₺'},
      {'label': 'Ürün Primi', 'value': '${item['urun_primi']} ₺'},
      {'label': 'Paket Geliri', 'value': '${item['paket_geliri']} ₺'},
      {'label': 'Paket Primi', 'value': '${item['paket_primi']} ₺'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expanded['Personel']!.remove(index);
              } else {
                _expanded['Personel']!.add(index);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 180),
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: !isExpanded
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: [
                              Divider(
                                height: 1,
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      MediaQuery.of(context).size.width > 600
                                          ? 3
                                          : 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 2.4,
                                ),
                                itemCount: stats.length,
                                itemBuilder: (ctx, i) {
                                  final s = stats[i];
                                  return Container(
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 8, 10, 8),
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest
                                          .withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          s['label']!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: scheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          s['value']!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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

  // ---------- Empty state ----------

  Widget _buildEmptyState(String tab, String query) {
    final scheme = Theme.of(context).colorScheme;
    final isSearch = query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.bar_chart_rounded,
                size: 36,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'Sonuç bulunamadı' : 'Kayıt yok',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearch
                  ? '"$query" için kayıt bulunamadı'
                  : 'Seçili tarih aralığında ${tab.toLowerCase()} satışı yok',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Skeleton ----------

  Widget _buildSkeleton(String tab) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (tab != 'Personel') ...[
          const _SkeletonBox(height: 168, radius: 22),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              const _SkeletonBox(height: 32, radius: 16, width: 70),
              if (i < 3) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 14),
        const _SkeletonBox(height: 44, radius: 14),
        const SizedBox(height: 22),
        for (int i = 0; i < 5; i++) ...[
          const _SkeletonBox(height: 66, radius: 16),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ---------- Modals ----------

  void _openStaffFilter(String tab) async {
    await _ensurePersoneller();
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        'Personel Seç',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (_staff[tab] != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _staff[tab] = null;
                            });
                            _loadTab(tab, force: true);
                          },
                          child: const Text('Temizle'),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    children: [
                      _staffTile(
                        label: 'Tüm Personeller',
                        icon: Icons.people_outline_rounded,
                        selected: _staff[tab] == null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _staff[tab] = null;
                          });
                          _loadTab(tab, force: true);
                        },
                      ),
                      if (_personeller != null)
                        ...(_personeller!.map(
                          (p) => _staffTile(
                            label: p.personel_adi,
                            avatar: p.personel_adi.isNotEmpty
                                ? p.personel_adi[0].toUpperCase()
                                : '?',
                            selected: _staff[tab]?.id == p.id,
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _staff[tab] = p;
                              });
                              _loadTab(tab, force: true);
                            },
                          ),
                        )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _staffTile({
    required String label,
    IconData? icon,
    String? avatar,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: icon != null
                    ? Icon(icon, color: scheme.primary, size: 18)
                    : Text(
                        avatar ?? '?',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openCustomDatePicker(String tab) async {
    final scheme = Theme.of(context).colorScheme;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _ranges[tab],
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      saveText: 'UYGULA',
      helpText: 'Tarih Aralığı',
      cancelText: 'İPTAL',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: scheme.primary,
                  onPrimary: scheme.onPrimary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _ranges[tab] = picked;
      });
      _loadTab(tab, force: true);
    }
  }

  void _showCustomerList(String tab, dynamic item) {
    final scheme = Theme.of(context).colorScheme;
    final salonId = widget.isletmebilgi['id'].toString();
    final tarih1 = DateFormat('yyyy-MM-dd').format(_ranges[tab]!.start);
    final tarih2 = DateFormat('yyyy-MM-dd').format(_ranges[tab]!.end);
    final personelId = _staff[tab]?.id ?? '';

    final nameKey = switch (tab) {
      'Ürün' => 'urun_adi',
      'Paket' => 'paket_adi',
      _ => 'hizmet_adi',
    };
    final title = (item[nameKey] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (sctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _CustomerListSheet(
                tab: tab,
                title: title,
                salonId: salonId,
                tarih1: tarih1,
                tarih2: tarih2,
                personelId: personelId,
                itemId: item[switch (tab) {
                      'Ürün' => 'urun_id',
                      'Paket' => 'paket_id',
                      _ => 'hizmet_id',
                    }]
                    .toString(),
                isletmebilgi: widget.isletmebilgi,
                kullanicirolu: widget.kullanicirolu,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }

  // ---------- Helpers ----------

  IconData _heroIcon(String tab) => switch (tab) {
        'Ürün' => Icons.shopping_bag_rounded,
        'Paket' => Icons.card_giftcard_rounded,
        'Personel' => Icons.groups_rounded,
        _ => Icons.medical_services_rounded,
      };

  IconData _itemIcon(String tab) => switch (tab) {
        'Ürün' => Icons.shopping_basket_rounded,
        'Paket' => Icons.all_inclusive_rounded,
        _ => Icons.spa_rounded,
      };

  List<_QuickRange> _quickRanges() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return [
      _QuickRange(
        'Bugün',
        Icons.today_rounded,
        DateTimeRange(start: today, end: endOfToday),
      ),
      _QuickRange(
        'Dün',
        Icons.history_rounded,
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 1),
          end: DateTime(now.year, now.month, now.day - 1, 23, 59, 59),
        ),
      ),
      _QuickRange(
        'Bu Ay',
        Icons.calendar_month_rounded,
        _defaultRange,
      ),
      _QuickRange(
        'Geçen Ay',
        Icons.calendar_today_rounded,
        DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0, 23, 59, 59),
        ),
      ),
      _QuickRange(
        'Bu Yıl',
        Icons.event_note_rounded,
        DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        ),
      ),
    ];
  }

  String? _quickLabelOf(DateTimeRange r) {
    for (final o in _quickRanges()) {
      if (o.range.start == r.start && o.range.end == r.end) return o.label;
    }
    return null;
  }
}

class _Totals {
  final double tutar;
  final double kazanc;
  final double alacak;
  const _Totals(this.tutar, this.kazanc, this.alacak);
  static const _Totals zero = _Totals(0, 0, 0);
}

class _QuickRange {
  final String label;
  final IconData icon;
  final DateTimeRange range;
  _QuickRange(this.label, this.icon, this.range);
}

class _SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;
  const _SkeletonBox({
    required this.height,
    this.width,
    required this.radius,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final hi = scheme.surfaceContainerHighest.withValues(alpha: 0.8);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        final v = _ctrl.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + v * 2, 0),
              end: Alignment(1 + v * 2, 0),
              colors: [base, hi, base],
            ),
          ),
        );
      },
    );
  }
}

class _CustomerListSheet extends StatefulWidget {
  final String tab;
  final String title;
  final String salonId;
  final String tarih1;
  final String tarih2;
  final String personelId;
  final String itemId;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final ScrollController scrollController;

  const _CustomerListSheet({
    required this.tab,
    required this.title,
    required this.salonId,
    required this.tarih1,
    required this.tarih2,
    required this.personelId,
    required this.itemId,
    required this.isletmebilgi,
    required this.kullanicirolu,
    required this.scrollController,
  });

  @override
  State<_CustomerListSheet> createState() => _CustomerListSheetState();
}

class _CustomerListSheetState extends State<_CustomerListSheet> {
  List<dynamic>? _data;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      List<dynamic> r = const [];
      switch (widget.tab) {
        case 'Hizmet':
          r = await hizmetMusteriListesiGetir(
            widget.salonId,
            widget.itemId,
            widget.tarih1,
            widget.tarih2,
            widget.personelId,
          );
          break;
        case 'Ürün':
          r = await urunMusteriListesiGetir(
            widget.salonId,
            widget.itemId,
            widget.tarih1,
            widget.tarih2,
            widget.personelId,
          );
          break;
        case 'Paket':
          r = await paketMusteriListesiGetir(
            widget.salonId,
            widget.itemId,
            widget.tarih1,
            widget.tarih2,
            widget.personelId,
          );
          break;
      }
      if (mounted) {
        setState(() {
          _data = r;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _data = const [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final all = _data ?? const [];
    final filtered = _query.isEmpty
        ? all
        : all.where((m) {
            final n = (m['name'] ?? '').toString().toLowerCase();
            final p = (m['cep_telefon'] ?? '').toString().toLowerCase();
            final q = _query.toLowerCase();
            return n.contains(q) || p.contains(q);
          }).toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Müşteri Listesi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (!_loading) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${all.length} müşteri',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (!_loading && all.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Müşteri ara…',
                  hintStyle: TextStyle(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: 5,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _SkeletonBox(height: 64, radius: 14),
                  ),
                )
              : filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              all.isEmpty
                                  ? Icons.people_outline_rounded
                                  : Icons.search_off_rounded,
                              size: 48,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              all.isEmpty
                                  ? 'Müşteri bulunamadı'
                                  : 'Sonuç bulunamadı',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              all.isEmpty
                                  ? 'Bu ${widget.tab.toLowerCase()} için müşteri kaydı yok'
                                  : '"$_query" ile eşleşen müşteri yok',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) =>
                          _buildCustomerCard(ctx, filtered[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(BuildContext context, dynamic musteri) {
    final scheme = Theme.of(context).colorScheme;
    final name = (musteri['name'] ?? 'Müşteri').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final phoneRaw = musteri['cep_telefon']?.toString();
    final phone = (phoneRaw == null || phoneRaw.isEmpty) ? phoneRaw : Yetki.telefonGoster(phoneRaw);
    final email = musteri['email']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            MusteriDanisan md = MusteriDanisan.fromJson(musteri);
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => MusteriDetaylari(
                  md: md,
                  isletmebilgi: widget.isletmebilgi,
                  kullanicirolu: widget.kullanicirolu,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (phone == null || phone.isEmpty)
                                  ? 'Telefon yok'
                                  : phone,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant,
                                fontStyle: (phone == null || phone.isEmpty)
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (email != null && email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.email_rounded,
                              size: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                email,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: scheme.onSurfaceVariant,
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
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
