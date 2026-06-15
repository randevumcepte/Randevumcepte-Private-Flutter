import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/lazyload.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/tl_input_formatter.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/adisyonpaketler.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:randevu_sistem/theme/premium_components.dart';
import 'package:randevu_sistem/yonetici/adisyonlar/satislar/tahsilat.dart';

import '../ayarlar/paketler/paketduzenle.dart';
import '../ayarlar/paketler/paketekle.dart';

class PaketSatislari extends StatefulWidget {
  final Kullanici kullanici;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final String adisyonId;
  PaketSatislari({
    Key? key,
    required this.adisyonId,
    required this.kullanici,
    required this.isletmebilgi,
    required this.kullanicirolu,
  }) : super(key: key);
  @override
  _PaketSatislariState createState() => _PaketSatislariState();
}

class _PaketSatislariState extends State<PaketSatislari> {
  MusteriDanisan? selectedmusteri;
  Personel? selectedpaketsatici;
  late List<Personel> paketsatici;
  late PaketDataSource _paketDataGridSource;
  late String? seciliisletme;
  bool _isLoading = true;
  TextEditingController saticiController = TextEditingController();
  late dynamic isletme_bilgi;
  Timer? _debounce;
  bool firsttimetyping = true;
  String? lastQuery;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    initialize();
    _controller.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_controller.text.length == 0 || _controller.text.length >= 3) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (_controller.text != lastQuery && !firsttimetyping) {
          setState(() {
            firsttimetyping = false;
            lastQuery = _controller.text;
            _paketDataGridSource.search(_controller.text);
          });
        }
      });
    } else {
      if ((_controller.text == '' || _controller.text.length < 3) &&
          firsttimetyping) {
        setState(() {
          firsttimetyping = false;
        });
      }
    }
  }

  void onCheckboxChanged(int rowIndex, bool isChecked) {
    setState(() {
      _paketDataGridSource.anyChecked.value = isChecked;
    });
  }

  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    List<Personel> personelliste = await personellistegetir(seciliisletme!);
    widget.kullanici.yetkili_olunan_isletmeler.forEach((element) {
      log(element['salon_id'].toString());
      if (element['salon_id'].toString() == seciliisletme.toString()) {
        isletme_bilgi = element;
      }
    });
    urunlerigetir(seciliisletme!, '1', '').then((data) {
      setState(() {
        paketsatici = personelliste;
        _paketDataGridSource = PaketDataSource(
          rowsPerPage: 10,
          salonid: seciliisletme!,
          context: context,
          checkBoxChecked: onCheckboxChanged,
          isletmebilgi: widget.isletmebilgi,
        );
        _paketDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
        _isLoading = false;
      });
    });
  }

  void _onLoadingStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    if (!_isLoading) {
      try {
        _paketDataGridSource.isLoadingNotifier.removeListener(_onLoadingStateChanged);
      } catch (_) {}
    }
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    _paketDataGridSource.search(_controller.text);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
    final isDemo = widget.isletmebilgi["demo_hesabi"].toString() == "1";

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: scheme.surface,
        bottomNavigationBar: AnimatedBuilder(
          animation: _paketDataGridSource,
          builder: (context, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _paketDataGridSource.anyChecked,
              builder: (context, anyChecked, _) {
                if (anyChecked) return const SizedBox.shrink();
                final hasPagination =
                    _paketDataGridSource.paket.isNotEmpty &&
                        _paketDataGridSource.totalPages > 1;
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Row(
                      children: [
                        if (hasPagination)
                          Expanded(child: _buildPaginationPill(scheme))
                        else
                          const Spacer(),
                        const SizedBox(width: 10),
                        _buildYeniPaketInline(scheme),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        body: PremiumGradientBg(
          child: SafeArea(
            bottom: false,
            child: AnimatedBuilder(
              animation: _paketDataGridSource,
              builder: (context, _) {
                return Column(
                  children: [
                    _buildHeader(scheme, isDemo),
                    _buildSearchBar(scheme),
                    _buildSelectionBar(scheme),
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _paketDataGridSource.isLoadingNotifier,
                        builder: (context, loading, _) {
                          final hasData = _paketDataGridSource.paket.isNotEmpty;
                          if (!hasData) {
                            if (loading) {
                              return Center(
                                child: CircularProgressIndicator(color: scheme.primary),
                              );
                            }
                            return _buildEmptyState(scheme);
                          }
                          return RefreshIndicator(
                            color: scheme.primary,
                            onRefresh: _onRefresh,
                            child: _buildPaketList(scheme),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
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
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paket Yönetimi',
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
                  'Paketleri görüntüle, düzenle ve satışa al',
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
          controller: _controller,
          keyboardType: TextInputType.text,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Paket adı veya hizmet ara...',
            hintStyle: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.45),
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: scheme.primary, size: 22),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                    },
                  ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar(ColorScheme scheme) {
    return ValueListenableBuilder<bool>(
      valueListenable: _paketDataGridSource.anyChecked,
      builder: (context, anyChecked, _) {
        if (!anyChecked) return const SizedBox.shrink();
        final selected = _paketDataGridSource.selectedRows.value
            .where((e) => e)
            .length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, color: scheme.onPrimary, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$selected paket seçildi',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _paketDataGridSource.hepsiniSec(false);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Vazgeç',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _showSatisDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_rounded, color: scheme.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Satış Yap',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaketList(ColorScheme scheme) {
    final paketler = _paketDataGridSource.paket;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: paketler.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _buildPaketCard(scheme, paketler[index], index),
    );
  }

  Widget _buildPaketCard(ColorScheme scheme, Paket paket, int index) {
    final selectedList = _paketDataGridSource.selectedRows.value;
    final selected = index < selectedList.length ? selectedList[index] : false;

    final hizmetlerList = <Map<String, dynamic>>[];
    int totalSeans = 0;
    double totalFiyat = 0;
    for (final h in paket.hizmetler) {
      final hizmetAdi = h['hizmet']?['hizmet_adi']?.toString() ?? '';
      final seans = int.tryParse(h['seans']?.toString() ?? '0') ?? 0;
      final fiyat = double.tryParse(h['fiyat']?.toString() ?? '0') ?? 0;
      totalSeans += seans;
      totalFiyat += fiyat;
      if (hizmetAdi.isNotEmpty) {
        hizmetlerList.add({'ad': hizmetAdi, 'seans': seans});
      }
    }
    if (totalSeans == 0) totalSeans = int.tryParse(paket.miktar) ?? 0;
    if (totalFiyat == 0) totalFiyat = double.tryParse(paket.fiyat) ?? 0;

    final fiyatGosterim =
        totalFiyat == 0 ? '0' : backendToTl(totalFiyat.toString());
    final isAktif = paket.aktif == '1' || paket.aktif == 'true';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? scheme.primary.withValues(alpha: 0.55)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: selected ? 0.16 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showDetailsSheet(context, paket),
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                paket.paket_adi,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildAktifChip(isAktif),
                            const SizedBox(width: 6),
                            _buildSelectCheckbox(scheme, selected, index),
                          ],
                        ),
                        if (hizmetlerList.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final h in hizmetlerList.take(4))
                                _buildHizmetChip(
                                    scheme, h['ad'] as String, h['seans'] as int),
                              if (hizmetlerList.length > 4)
                                _buildMoreChip(scheme, hizmetlerList.length - 4),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatMini(
                              scheme,
                              icon: Icons.event_repeat_rounded,
                              value: '$totalSeans',
                              label: 'seans',
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 1,
                              height: 24,
                              color: scheme.outline.withValues(alpha: 0.20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₺',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        fiyatGosterim,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: scheme.primary,
                                          letterSpacing: -0.4,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildCardMenu(scheme, paket),
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

  Widget _buildAktifChip(bool active) {
    final color = active ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            active ? 'Aktif' : 'Pasif',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCheckbox(ColorScheme scheme, bool selected, int index) {
    return GestureDetector(
      onTap: () {
        final list = _paketDataGridSource.selectedRows.value;
        if (index >= list.length) return;
        list[index] = !list[index];
        _paketDataGridSource.anyChecked.value = list.any((e) => e);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.45),
            width: 1.6,
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: selected
            ? Icon(Icons.check_rounded, color: scheme.onPrimary, size: 16)
            : null,
      ),
    );
  }

  Widget _buildHizmetChip(ColorScheme scheme, String ad, int seans) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              ad,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
          if (seans > 0) ...[
            const SizedBox(width: 4),
            Text(
              '×$seans',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: scheme.tertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreChip(ColorScheme scheme, int more) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.outline.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '+$more',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  Widget _buildStatMini(
    ColorScheme scheme, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurface.withValues(alpha: 0.55)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildCardMenu(ColorScheme scheme, Paket paket) {
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: scheme.onSurface.withValues(alpha: 0.65),
        ),
        padding: EdgeInsets.zero,
        iconSize: 18,
        tooltip: 'İşlemler',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
        onSelected: (value) async {
          if (value == 'duzenle') {
            final result = await Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => PaketDuzenle(
                  paket: paket,
                  isletmebilgi: widget.isletmebilgi,
                ),
              ),
            );
            if (result == true && mounted) {
              setState(() => _paketDataGridSource.search(_controller.text));
            }
          } else if (value == 'sil') {
            await _paketDataGridSource.showDeleteConfirmationDialog(
              context,
              int.parse(paket.id),
              () {
                showProgressLoading(context);
                _paketDataGridSource.sil(context, int.parse(paket.id));
              },
            );
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'duzenle',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Düzenle',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'sil',
            child: Row(
              children: [
                Icon(Icons.delete_rounded, size: 16, color: Color(0xFFEF4444)),
                SizedBox(width: 8),
                Text(
                  'Sil',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    final hasQuery = _controller.text.isNotEmpty;
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
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
                hasQuery ? Icons.search_off_rounded : Icons.widgets_rounded,
                size: 44,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasQuery ? 'Sonuç bulunamadı' : 'Henüz paket eklenmedi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? '"${_controller.text}" için kayıt bulunamadı'
                  : 'Müşterilerine sunmak için ilk paketini oluştur',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 18),
              _buildGradientButton(
                scheme,
                icon: Icons.add_rounded,
                label: 'İlk Paketi Oluştur',
                onTap: _yeniPaketAc,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationPill(ColorScheme scheme) {
    final totalPages = _paketDataGridSource.totalPages;
    final currentPage = _paketDataGridSource.currentPage;
    final canPrev = currentPage > 1;
    final canNext = currentPage < totalPages;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageArrow(scheme, Icons.arrow_back_rounded, canPrev, () {
            setState(() => _paketDataGridSource.setPage(currentPage - 1));
          }),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$currentPage / $totalPages',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _pageArrow(scheme, Icons.arrow_forward_rounded, canNext, () {
            setState(() => _paketDataGridSource.setPage(currentPage + 1));
          }),
        ],
      ),
    );
  }

  Widget _pageArrow(
    ColorScheme scheme,
    IconData icon,
    bool enabled,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? scheme.primary : scheme.outline.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? scheme.onPrimary
              : scheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildYeniPaketInline(ColorScheme scheme) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: _yeniPaketAc,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: scheme.onPrimary, size: 18),
              const SizedBox(width: 5),
              Text(
                'Yeni Paket',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: scheme.onPrimary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _yeniPaketAc() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaketEkle(
          kullanicirolu: widget.kullanicirolu,
          kullanici: widget.kullanici,
          isletmebilgi: widget.isletmebilgi,
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() => _paketDataGridSource.search(_controller.text));
    }
  }

  void _showDetailsSheet(BuildContext outerContext, Paket paket) async {
    final hizmetlerList = <Map<String, dynamic>>[];
    int totalSeans = 0;
    double totalFiyat = 0;
    for (final element in paket.hizmetler) {
      final ad = element['hizmet']?['hizmet_adi']?.toString() ?? '';
      final s = int.tryParse(element['seans']?.toString() ?? '0') ?? 0;
      final f = double.tryParse(element['fiyat']?.toString() ?? '0') ?? 0;
      totalSeans += s;
      totalFiyat += f;
      if (ad.isNotEmpty) {
        hizmetlerList.add({'ad': ad, 'seans': s, 'fiyat': f});
      }
    }
    if (totalFiyat == 0) totalFiyat = double.tryParse(paket.fiyat) ?? 0;
    if (totalSeans == 0) totalSeans = int.tryParse(paket.miktar) ?? 0;
    final fiyatStr = totalFiyat == 0 ? '0' : backendToTl(totalFiyat.toString());
    final scheme = Theme.of(outerContext).colorScheme;

    final action = await showModalBottomSheet<String>(
      context: outerContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.45,
          expand: false,
          builder: (ctx, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outline.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [scheme.primary, scheme.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.30),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.widgets_rounded,
                                color: scheme.onPrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                paket.paket_adi,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _heroStat(
                                scheme,
                                label: 'Seans',
                                value: '$totalSeans',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: Colors.white.withValues(alpha: 0.30),
                            ),
                            Expanded(
                              child: _heroStat(
                                scheme,
                                label: 'Fiyat',
                                value: '₺$fiyatStr',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: Colors.white.withValues(alpha: 0.30),
                            ),
                            Expanded(
                              child: _heroStat(
                                scheme,
                                label: 'Hizmet',
                                value: '${hizmetlerList.length}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      children: [
                        Text(
                          'HİZMETLER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (hizmetlerList.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Bu pakete bağlı hizmet bulunmuyor',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ...hizmetlerList.map(
                          (h) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: scheme.primary
                                        .withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.spa_rounded,
                                    size: 15,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    h['ad'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${h['seans']} seans',
                                    style: TextStyle(
                                      color: scheme.onPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop('sil'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Color(0xFFEF4444),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Sil',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop('duzenle'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [scheme.primary, scheme.tertiary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary
                                        .withValues(alpha: 0.30),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                    color: scheme.onPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Düzenle',
                                    style: TextStyle(
                                      color: scheme.onPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    log('paket detay action: $action');
    if (!mounted) return;

    if (action == 'duzenle') {
      final result = await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => PaketDuzenle(
            paket: paket,
            isletmebilgi: widget.isletmebilgi,
          ),
        ),
      );
      if (result == true && mounted) {
        setState(() => _paketDataGridSource.search(_controller.text));
      }
    } else if (action == 'sil') {
      await _paketDataGridSource.showDeleteConfirmationDialog(
        context,
        int.parse(paket.id),
        () {
          showProgressLoading(context);
          _paketDataGridSource.sil(context, int.parse(paket.id));
        },
      );
    }
  }

  Widget _heroStat(
    ColorScheme scheme, {
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: scheme.onPrimary.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showSatisDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final List<Paket> selectedData = [];
    final List<TextEditingController> paketSeansController = [];
    final List<TextEditingController> paketFiyatController = [];
    String odemeYontemiId = '1';
    bool kaydediliyor = false;

    for (int i = 0;
        i < _paketDataGridSource.selectedRows.value.length;
        i++) {
      if (_paketDataGridSource.selectedRows.value[i]) {
        final secilenPaket = _paketDataGridSource.paket[i];
        selectedData.add(secilenPaket);
        int defaultSeans = 0;
        double defaultFiyat = 0;
        for (final h in secilenPaket.hizmetler) {
          defaultSeans += int.tryParse(h['seans']?.toString() ?? '0') ?? 0;
          defaultFiyat += double.tryParse(h['fiyat']?.toString() ?? '0') ?? 0;
        }
        if (defaultSeans == 0) {
          defaultSeans = int.tryParse(secilenPaket.miktar) ?? 0;
        }
        if (defaultFiyat == 0) {
          defaultFiyat = double.tryParse(secilenPaket.fiyat) ?? 0;
        }
        paketSeansController
            .add(TextEditingController(text: defaultSeans.toString()));
        paketFiyatController.add(
          TextEditingController(
            text: defaultFiyat == 0 ? '' : backendToTl(defaultFiyat.toString()),
          ),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setStateSB) {
              return DraggableScrollableSheet(
                initialChildSize: 0.85,
                maxChildSize: 0.95,
                minChildSize: 0.55,
                expand: false,
                builder: (ctx, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.outline.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [scheme.primary, scheme.tertiary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shopping_cart_rounded,
                                  color: scheme.onPrimary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Paket Satışı',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(ctx).pop(),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: scheme.outline
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            children: [
                              _sectionTitle(scheme, 'Müşteri', Icons.person_rounded),
                              const SizedBox(height: 8),
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.30),
                                  border: Border.all(
                                    color: scheme.outline
                                        .withValues(alpha: 0.20),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: LazyDropdown(
                                    salonId:
                                        widget.isletmebilgi['id'].toString(),
                                    selectedItem: selectedmusteri,
                                    onChanged: (value) {
                                      setStateSB(() {
                                        selectedmusteri = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _sectionTitle(scheme, 'Satıcı Personel',
                                  Icons.badge_rounded),
                              const SizedBox(height: 8),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.30),
                                  border: Border.all(
                                    color: scheme.outline
                                        .withValues(alpha: 0.20),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton2<Personel>(
                                    isExpanded: true,
                                    hint: Text(
                                      'Personel seçin',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                    items: paketsatici
                                        .map(
                                          (item) => DropdownMenuItem(
                                            value: item,
                                            child: Text(
                                              item.personel_adi,
                                              style: const TextStyle(
                                                  fontSize: 14),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    value: selectedpaketsatici,
                                    onChanged: (value) {
                                      setStateSB(() {
                                        selectedpaketsatici = value;
                                      });
                                    },
                                    buttonStyleData: const ButtonStyleData(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12),
                                      height: 48,
                                    ),
                                    dropdownStyleData: DropdownStyleData(
                                      maxHeight: 240,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    menuItemStyleData:
                                        const MenuItemStyleData(height: 40),
                                    dropdownSearchData: DropdownSearchData(
                                      searchController: saticiController,
                                      searchInnerWidgetHeight: 50,
                                      searchInnerWidget: Container(
                                        height: 50,
                                        padding: const EdgeInsets.all(8),
                                        child: TextFormField(
                                          expands: true,
                                          maxLines: null,
                                          controller: saticiController,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8),
                                            hintText: 'Ara..',
                                            hintStyle:
                                                const TextStyle(fontSize: 12),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      searchMatchFn: (item, searchValue) {
                                        final personelAdi = item
                                            .value?.personel_adi
                                            .toLowerCase();
                                        return personelAdi != null &&
                                            personelAdi.contains(
                                                searchValue.toLowerCase());
                                      },
                                    ),
                                    onMenuStateChange: (isOpen) {
                                      if (!isOpen) saticiController.clear();
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _sectionTitle(
                                  scheme, 'Seans ve Fiyat', Icons.tune_rounded),
                              const SizedBox(height: 8),
                              ...List.generate(selectedData.length, (index) {
                                final item = selectedData[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: scheme.primary
                                        .withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: scheme.primary
                                          .withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  scheme.primary,
                                                  scheme.tertiary
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item.paket_adi,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: scheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _satisInputField(
                                              scheme,
                                              label: 'Seans Sayısı',
                                              controller:
                                                  paketSeansController[index],
                                              keyboardType: TextInputType.number,
                                              onChanged: () => setStateSB(() {}),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _satisInputField(
                                              scheme,
                                              label: 'Fiyat (₺)',
                                              controller:
                                                  paketFiyatController[index],
                                              keyboardType: TextInputType.number,
                                              formatter:
                                                  TurkishLiraInputFormatter(),
                                              onChanged: () => setStateSB(() {}),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 18),
                              _sectionTitle(scheme, 'Ödeme Yöntemi',
                                  Icons.payments_rounded),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _odemeYontemiPill(
                                      scheme,
                                      value: '1',
                                      label: 'Nakit',
                                      icon: Icons.payments_rounded,
                                      selected: odemeYontemiId,
                                      onSelect: (v) => setStateSB(
                                          () => odemeYontemiId = v),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _odemeYontemiPill(
                                      scheme,
                                      value: '2',
                                      label: 'Kart',
                                      icon: Icons.credit_card_rounded,
                                      selected: odemeYontemiId,
                                      onSelect: (v) => setStateSB(
                                          () => odemeYontemiId = v),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _odemeYontemiPill(
                                      scheme,
                                      value: '3',
                                      label: 'Havale',
                                      icon: Icons.account_balance_rounded,
                                      selected: odemeYontemiId,
                                      onSelect: (v) => setStateSB(
                                          () => odemeYontemiId = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _toplamOzet(scheme, paketFiyatController),
                            ],
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: kaydediliyor
                                            ? null
                                            : () => Navigator.of(ctx).pop(),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          decoration: BoxDecoration(
                                            color: scheme.outline
                                                .withValues(alpha: 0.10),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Vazgeç',
                                              style: TextStyle(
                                                color: scheme.onSurface
                                                    .withValues(alpha: 0.7),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 2,
                                      child: GestureDetector(
                                        onTap: kaydediliyor
                                            ? null
                                            : () => _hizliSatVeTahsil(
                                                  ctx,
                                                  setStateSB,
                                                  selectedData,
                                                  paketSeansController,
                                                  paketFiyatController,
                                                  odemeYontemiId,
                                                  (v) => kaydediliyor = v,
                                                ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                scheme.primary,
                                                scheme.tertiary,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: scheme.primary
                                                    .withValues(alpha: 0.30),
                                                blurRadius: 14,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: kaydediliyor
                                              ? SizedBox(
                                                  height: 22,
                                                  child: Center(
                                                    child: SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: scheme.onPrimary,
                                                        strokeWidth: 2.5,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.flash_on_rounded,
                                                      color: scheme.onPrimary,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Sat ve Tahsil Et',
                                                      style: TextStyle(
                                                        color: scheme.onPrimary,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                TextButton(
                                  onPressed: kaydediliyor
                                      ? null
                                      : () => _submitSatis(
                                            ctx,
                                            selectedData,
                                            paketSeansController,
                                            paketFiyatController,
                                          ),
                                  child: Text(
                                    'Detaylı tahsilata git →',
                                    style: TextStyle(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.55),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _sectionTitle(ColorScheme scheme, String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _satisInputField(
    ColorScheme scheme, {
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    TurkishLiraInputFormatter? formatter,
    VoidCallback? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.65),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatter != null ? [formatter] : null,
            onChanged: onChanged == null ? null : (_) => onChanged(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _odemeYontemiPill(
    ColorScheme scheme, {
    required String value,
    required String label,
    required IconData icon,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : scheme.outline.withValues(alpha: 0.22),
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? scheme.onPrimary
                      : scheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toplamOzet(
    ColorScheme scheme,
    List<TextEditingController> paketFiyatController,
  ) {
    double toplamBackend = 0;
    for (final c in paketFiyatController) {
      toplamBackend += double.tryParse(tlToBackend(c.text)) ?? 0;
    }
    final toplamTl =
        toplamBackend == 0 ? '0,00' : backendToTl(toplamBackend.toString());
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: scheme.onPrimary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tahsil Edilecek',
                  style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        toplamTl,
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _hizliSatVeTahsil(
    BuildContext sheetCtx,
    StateSetter setStateSB,
    List<Paket> selectedData,
    List<TextEditingController> paketSeansController,
    List<TextEditingController> paketFiyatController,
    String odemeYontemiId,
    void Function(bool) setKaydediliyor,
  ) async {
    if (selectedmusteri == null || selectedpaketsatici == null) {
      _showUyari(sheetCtx,
          'Satış için müşteri ve satıcı seçimini yapmanız gerekmektedir!');
      return;
    }
    double toplamBackend = 0;
    for (final c in paketFiyatController) {
      toplamBackend += double.tryParse(tlToBackend(c.text)) ?? 0;
    }
    if (toplamBackend <= 0) {
      _showUyari(sheetCtx, 'Toplam tutar 0\'dan büyük olmalıdır.');
      return;
    }

    setStateSB(() => setKaydediliyor(true));

    String? olusanAdisyonId;
    final List<String> paketIdler = [];
    final List<AdisyonPaket> created = [];

    try {
      for (int i = 0; i < selectedData.length; i++) {
        final element = selectedData[i];
        final seansSayisi = paketSeansController[i].text.trim();
        final fiyatBackend = tlToBackend(paketFiyatController[i].text);
        final AdisyonPaket paket = AdisyonPaket(
          id: '',
          adisyon_id: olusanAdisyonId ?? '',
          paket_id: element.id,
          baslangic_tarihi: '',
          seans_araligi: '',
          fiyat: fiyatBackend,
          personel_id: selectedpaketsatici!.id,
          taksitli_tahsilat_id: '',
          senet_id: '',
          indirim_tutari: '',
          hediye: '',
          seans_baslangic_saati: '',
        );
        final eklenen = await adisyonpaketekle(
          paket,
          selectedmusteri?.id ?? '',
          context,
          seciliisletme!,
          '',
          false,
          '',
          seansSayisi: seansSayisi,
        );
        olusanAdisyonId = eklenen.adisyon_id;
        paketIdler.add(eklenen.id);
        created.add(eklenen);
      }

      final toplamTl = backendToTl(toplamBackend.toString());
      final prefs = await SharedPreferences.getInstance();
      final user = jsonDecode(prefs.getString('user')!);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final tahsilatBody = <String, dynamic>{
        'ad_soyad': selectedmusteri?.id ?? '',
        'sube': seciliisletme!,
        'adisyon_id': olusanAdisyonId ?? '',
        'vade_baslangic_tarihi': today,
        'taksit_tutar': '0',
        'vade': '1',
        'adisyon_hizmetleri': <dynamic>[],
        'adisyon_paketleri': created.map((e) => e.toJson()).toList(),
        'adisyon_urunleri': <dynamic>[],
        'senet_vadeleri': <dynamic>[],
        'taksit_vadeleri': <dynamic>[],
        'olusturan': user['id'],
        'musteri_indirimi': '0',
        'indirim_tutari': '0',
        'adisyon_hizmet_id': <String>[],
        'adisyon_urun_id': <String>[],
        'adisyon_paket_id': paketIdler,
        'odeme_yontemi': odemeYontemiId,
        'indirimli_toplam_tahsilat_tutari': toplamTl,
        'tahsilat_tarihi': today,
        'tahsilat_notlari': '',
        'senet_vade_id': <String>[],
        'taksit_vade_id': <String>[],
      };

      final response = await http.post(
        Uri.parse(
            'https://app.randevumcepte.com.tr/api/v1/tahsilatekle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(tahsilatBody),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        setStateSB(() => setKaydediliyor(false));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Tahsilat eklenirken hata: ${response.statusCode}'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      Navigator.of(sheetCtx).pop();
      if (!mounted) return;
      _paketDataGridSource.hepsiniSec(false);
      _paketDataGridSource.search(_controller.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF15803D),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Satış tamamlandı · ₺$toplamTl tahsil edildi',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      log('hızlı tahsil hatası: $e');
      if (!mounted) return;
      setStateSB(() => setKaydediliyor(false));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  void _showUyari(BuildContext ctx, String mesaj) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: const Text('UYARI',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(mesaj),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('TAMAM'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSatis(
    BuildContext sheetCtx,
    List<Paket> selectedData,
    List<TextEditingController> paketSeansController,
    List<TextEditingController> paketFiyatController,
  ) async {
    bool isvalid = true;
    if (selectedmusteri == null) isvalid = false;
    if (selectedpaketsatici == null) isvalid = false;
    if (!isvalid) {
      showDialog(
        context: sheetCtx,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'UYARI',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Satış için müşteri ve satıcı seçimini yapmanız gerekmektedir!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(sheetCtx).pop(),
              child: const Text('TAMAM'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(sheetCtx).pop();
    if (!mounted) return;
    showProgressLoading(context);

    String? olusanAdisyonId;
    bool basarili = true;
    for (int i = 0; i < selectedData.length; i++) {
      final element = selectedData[i];
      final seansSayisi = paketSeansController[i].text.trim();
      final fiyatStr = tlToBackend(paketFiyatController[i].text);
      final AdisyonPaket paket = AdisyonPaket(
        id: '',
        adisyon_id: olusanAdisyonId ?? '',
        paket_id: element.id,
        baslangic_tarihi: '',
        seans_araligi: '',
        fiyat: fiyatStr,
        personel_id: selectedpaketsatici!.id,
        taksitli_tahsilat_id: '',
        senet_id: '',
        indirim_tutari: '',
        hediye: '',
        seans_baslangic_saati: '',
      );
      try {
        final eklenen = await adisyonpaketekle(
          paket,
          selectedmusteri?.id ?? '',
          context,
          seciliisletme!,
          '',
          false,
          '',
          seansSayisi: seansSayisi,
        );
        olusanAdisyonId = eklenen.adisyon_id;
      } catch (_) {
        basarili = false;
        break;
      }
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (basarili) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (builder) => TahsilatEkrani(
            adisyonId: olusanAdisyonId ?? widget.adisyonId,
            kullanicirolu: widget.kullanicirolu,
            isletmebilgi: isletme_bilgi,
            musteridanisanid: selectedmusteri?.id ?? '',
          ),
        ),
      );
    }
  }
}
