import 'package:flutter/material.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/paket_hizmetleri.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

class BirHizmetDaha extends StatefulWidget {
  final List<PaketHizmetleri> secilihizmetler;
  final PaketHizmetleri? duzenlenecek;
  final dynamic isletmebilgi;

  const BirHizmetDaha({
    Key? key,
    required this.secilihizmetler,
    this.duzenlenecek,
    required this.isletmebilgi,
  }) : super(key: key);

  @override
  _BirHizmetDahaState createState() => _BirHizmetDahaState();
}

class _BirHizmetDahaState extends State<BirHizmetDaha> {
  List<IsletmeHizmet> isletmehizmetliste = [];
  Set<String> selectedHizmetIds = {};
  Map<String, PaketHizmetleri> existingHizmetler = {};
  bool _isloading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    initialize();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    final seciliisletme = await secilisalonid();
    final liste = await isletmehizmetleri(seciliisletme!);
    if (!mounted) return;
    setState(() {
      isletmehizmetliste = _dedupeHizmetler(liste);
      for (final h in widget.secilihizmetler) {
        if (h.hizmet_id.isEmpty) continue;
        selectedHizmetIds.add(h.hizmet_id);
        existingHizmetler[h.hizmet_id] = h;
      }
      _isloading = false;
    });
  }

  // Backend bazen ayni hizmeti birden fazla salon_hizmetler satiri olarak
  // donduruyor — gorsel kopyalari engellemek icin inner hizmet.id'ye gore
  // tekille; ayrica ayni id+ad ile gizli kopyalari da temizle.
  List<IsletmeHizmet> _dedupeHizmetler(List<IsletmeHizmet> liste) {
    final seenIds = <String>{};
    final seenAd = <String>{};
    final result = <IsletmeHizmet>[];
    for (final h in liste) {
      final innerId = h.hizmet?['id']?.toString() ?? '';
      final adi = (h.hizmet?['hizmet_adi']?.toString() ?? '').trim();
      final key = innerId.isNotEmpty ? 'id:$innerId' : 'ad:${adi.toLowerCase()}';
      if (key.isEmpty || key == 'id:' || key == 'ad:') continue;
      if (seenIds.contains(key)) continue;
      // Ayni isimde ama farkli inner id varsa da (yeni eklenen kopya hizmet)
      // tekille — isletmenin gercekten ayni adli iki farkli hizmeti olmasi
      // beklenmiyor.
      final adKey = adi.isNotEmpty ? adi.toLowerCase() : '';
      if (adKey.isNotEmpty && seenAd.contains(adKey)) continue;
      seenIds.add(key);
      if (adKey.isNotEmpty) seenAd.add(adKey);
      result.add(h);
    }
    return result;
  }

  void _toggleHizmet(String id) {
    setState(() {
      if (selectedHizmetIds.contains(id)) {
        selectedHizmetIds.remove(id);
      } else {
        selectedHizmetIds.add(id);
      }
    });
  }

  void _hepsiniSec(List<IsletmeHizmet> filtered) {
    setState(() {
      for (final item in filtered) {
        selectedHizmetIds.add(item.hizmet['id'].toString());
      }
    });
  }

  void _hepsiniKaldir() {
    setState(() => selectedHizmetIds.clear());
  }

  void _kaydet() {
    final List<PaketHizmetleri> result = [];
    final Set<String> eklenenIdler = {};
    for (final item in isletmehizmetliste) {
      final id = item.hizmet['id'].toString();
      if (id.isEmpty || id == 'null') continue;
      if (!selectedHizmetIds.contains(id)) continue;
      if (!eklenenIdler.add(id)) continue;
      final existing = existingHizmetler[id];
      result.add(PaketHizmetleri(
        seans: existing?.seans ?? '0',
        fiyat: existing?.fiyat ?? '0',
        hizmet: item.hizmet,
        hizmet_id: id,
      ));
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    if (_isloading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final isDemo = widget.isletmebilgi['demo_hesabi'].toString() == '1';
    final filtered = isletmehizmetliste.where((item) {
      final hizmetAdi =
          item.hizmet['hizmet_adi']?.toString().toLowerCase() ?? '';
      return _searchQuery.isEmpty || hizmetAdi.contains(_searchQuery);
    }).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: scheme.surface,
        body: PremiumGradientBg(
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(scheme, isDemo),
                _buildSearchBar(scheme),
                _buildToolbar(scheme, filtered),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(scheme)
                      : _buildHizmetList(scheme, filtered),
                ),
                _buildBottomSave(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme, bool isDemo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          PremiumCircleAction(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hizmet Seç',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pakete dahil olacak hizmetleri işaretle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          if (isDemo)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: SizedBox(
                width: 96,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: _searchController,
          keyboardType: TextInputType.text,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Hizmet ara...',
            hintStyle: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.45),
              fontSize: 14,
            ),
            prefixIcon:
                Icon(Icons.search_rounded, color: scheme.primary, size: 22),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(
    ColorScheme scheme,
    List<IsletmeHizmet> filtered,
  ) {
    final allSelected = filtered.isNotEmpty &&
        filtered.every(
            (item) => selectedHizmetIds.contains(item.hizmet['id'].toString()));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 13, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${selectedHizmetIds.length} seçili',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (selectedHizmetIds.isNotEmpty)
            TextButton.icon(
              onPressed: _hepsiniKaldir,
              icon: Icon(Icons.clear_all_rounded,
                  size: 14, color: scheme.onSurface.withValues(alpha: 0.55)),
              label: Text(
                'Tümünü kaldır',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (filtered.isNotEmpty && !allSelected)
            TextButton.icon(
              onPressed: () => _hepsiniSec(filtered),
              icon: Icon(Icons.done_all_rounded,
                  size: 14, color: scheme.primary),
              label: Text(
                'Tümünü seç',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHizmetList(
    ColorScheme scheme,
    List<IsletmeHizmet> filtered,
  ) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final id = item.hizmet['id'].toString();
        final ad = item.hizmet['hizmet_adi']?.toString() ?? '';
        final isSelected = selectedHizmetIds.contains(id);
        return _buildHizmetTile(scheme, id, ad, isSelected);
      },
    );
  }

  Widget _buildHizmetTile(
    ColorScheme scheme,
    String id,
    String ad,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _toggleHizmet(id),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.55)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary
                    .withValues(alpha: isSelected ? 0.14 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? scheme.primary
                        : scheme.outline.withValues(alpha: 0.45),
                    width: 1.6,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded,
                        color: scheme.onPrimary, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.spa_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ad,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    final hasQuery = _searchController.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.16),
                    scheme.tertiary.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasQuery ? Icons.search_off_rounded : Icons.spa_rounded,
                size: 40,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'Sonuç bulunamadı' : 'Tanımlı hizmet yok',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? '"${_searchController.text}" için eşleşen hizmet bulunamadı'
                  : 'Önce işletme hizmetleri tanımlanmalı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSave(ColorScheme scheme) {
    final hasSelection = selectedHizmetIds.isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: hasSelection
                ? LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: hasSelection ? null : scheme.outline.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            boxShadow: hasSelection
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: hasSelection ? _kaydet : null,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      color: hasSelection
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasSelection
                          ? 'Kaydet (${selectedHizmetIds.length})'
                          : 'Hizmet seç',
                      style: TextStyle(
                        color: hasSelection
                            ? scheme.onPrimary
                            : scheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.2,
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
