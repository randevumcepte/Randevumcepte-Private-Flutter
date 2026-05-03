import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../../../Models/seanstakibi.dart';

class SeansTakibi extends StatefulWidget {
  final dynamic isletmebilgi;
  const SeansTakibi({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  _SeansTakibiState createState() => _SeansTakibiState();
}

class _SeansTakibiState extends State<SeansTakibi> {
  static const Color _primary = Color(0xFF6A1B9A);

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _lastQuery = '';

  String? _salonId;
  bool _initializing = true;
  bool _loading = false;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  List<SeansTakip> _items = [];
  final Set<String> _expanded = {};

  String _kartKey(SeansTakip item) {
    if (item.tip != null && item.paketHizmetId != null) {
      return '${item.tip}_${item.paketHizmetId}';
    }
    final ornek = item.seanslar.isNotEmpty ? item.seanslar.first : null;
    if (ornek is Map) {
      if (ornek['adisyon_paket_id'] != null) {
        return 'paket_${ornek['adisyon_paket_id']}';
      }
      if (ornek['adisyon_hizmet_id'] != null) {
        return 'hizmet_${ornek['adisyon_hizmet_id']}';
      }
    }
    return 'a_${item.adisyon}_${item.paket}';
  }

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final salonId = await secilisalonid();
    if (!mounted) return;
    setState(() {
      _salonId = salonId;
      _initializing = false;
    });
    await _fetch(page: 1, search: '');
  }

  void _onSearchChanged() {
    final text = _searchController.text;
    if (text.isNotEmpty && text.length < 3) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (text == _lastQuery) return;
      _lastQuery = text;
      _expanded.clear();
      _fetch(page: 1, search: text);
    });
  }

  Future<void> _fetch({required int page, required String search}) async {
    if (_salonId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await seanslarigetir(
        _salonId!,
        page.toString(),
        search,
        '',
        context,
        false,
      );
      final List<dynamic> data = response['data'] ?? [];
      final items = data
          .map((e) => SeansTakip.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _currentPage = (response['current_page'] ?? page) as int;
        _lastPage = (response['last_page'] ?? 1) as int;
        _total = (response['total'] ?? items.length) as int;
        _loading = false;
      });
    } catch (e, st) {
      log('seanslarigetir hata: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Veriler yüklenirken bir sorun oluştu.';
      });
    }
  }

  Future<void> _refresh() => _fetch(page: _currentPage, search: _lastQuery);

  void _goPage(int page) {
    if (page < 1 || page > _lastPage || page == _currentPage) return;
    _expanded.clear();
    _fetch(page: page, search: _lastQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Seans Takibi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (widget.isletmebilgi != null &&
              widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
              ),
            ),
        ],
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchField(),
                Expanded(child: _buildBody()),
                _buildPaginationBar(),
              ],
            ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Müşteri / Paket adı ara...',
          prefixIcon: const Icon(Icons.search, color: _primary),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _primary.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: _primary, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refresh,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Kayıt bulunamadı.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildItemCard(_items[index]),
      ),
    );
  }

  Widget _buildItemCard(SeansTakip item) {
    final musteriAdi = (item.musteri is Map &&
            item.musteri['name'] != null)
        ? item.musteri['name'].toString()
        : '';
    final baslangicTarih = _ilkSeansTarihi(item.seanslar);
    final toplam = item.bekleyenSeansSayisi +
        item.gelinenSeansSayisi +
        item.gelinmeyenSeansSayisi;
    final cardKey = _kartKey(item);
    final isOpen = _expanded.contains(cardKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
            onTap: () => setState(() {
              if (isOpen) {
                _expanded.remove(cardKey);
              } else {
                _expanded.add(cardKey);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          musteriAdi,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.paket,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.event,
                                size: 13, color: Colors.black45),
                            const SizedBox(width: 4),
                            Text(
                              'Başlangıç: $baslangicTarih',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _statChip(
                    label: toplam.toString(),
                    icon: Icons.add,
                    bg: _primary,
                    fg: Colors.white),
                _statChip(
                    label: item.bekleyenSeansSayisi.toString(),
                    icon: Icons.calendar_month,
                    bg: const Color(0xFFFFC107),
                    fg: Colors.black87),
                _statChip(
                    label: item.gelinenSeansSayisi.toString(),
                    icon: Icons.check,
                    bg: const Color(0xFF2E7D32),
                    fg: Colors.white),
                _statChip(
                    label: item.gelinmeyenSeansSayisi.toString(),
                    icon: Icons.close,
                    bg: const Color(0xFFD32F2F),
                    fg: Colors.white),
              ],
            ),
          ),
          if (isOpen)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: _buildExpanded(item),
            ),
        ],
      ),
    );
  }

  Widget _statChip({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: fg),
        ],
      ),
    );
  }

  Widget _buildExpanded(SeansTakip item) {
    final groups = <String, _HizmetGroup>{};

    for (final h in item.hizmetler) {
      if (h is! Map) continue;
      final hizmetId = (h['id'] ?? '').toString();
      final hizmetAdi = (h['hizmet_adi'] ?? '').toString();
      if (hizmetId.isEmpty) continue;
      groups[hizmetId] = _HizmetGroup(adi: hizmetAdi, hizmetId: hizmetId);
    }

    for (final s in item.seanslar) {
      final hizmet = (s is Map) ? s['hizmet'] : null;
      final hizmetAdi = (hizmet is Map && hizmet['hizmet_adi'] != null)
          ? hizmet['hizmet_adi'].toString()
          : item.paket;
      final hizmetId = (hizmet is Map && hizmet['id'] != null)
          ? hizmet['id'].toString()
          : hizmetAdi;
      final group = groups.putIfAbsent(
        hizmetId,
        () => _HizmetGroup(adi: hizmetAdi, hizmetId: hizmetId),
      );
      group.seanslar.add(s);
    }

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'Bu pakette hizmet detayı bulunmamaktadır.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      );
    }

    final children = <Widget>[];
    groups.forEach((_, g) {
      g.seanslar.sort((a, b) {
        final na = (a is Map && a['seans_no'] is num)
            ? (a['seans_no'] as num).toInt()
            : 0;
        final nb = (b is Map && b['seans_no'] is num)
            ? (b['seans_no'] as num).toInt()
            : 0;
        return na.compareTo(nb);
      });
      children.add(_buildHizmetKart(item, g));
    });
    return Column(children: children);
  }

  Widget _buildHizmetKart(SeansTakip item, _HizmetGroup group) {
    int kullanildi = 0;
    int kullanilmadi = 0;
    for (final s in group.seanslar) {
      final geldi = (s is Map) ? s['geldi'] : null;
      final iptal = (s is Map) ? s['iptal'] : null;
      if (geldi == 1) {
        kullanildi++;
      } else if (geldi == 0 || iptal == 1 || iptal == true) {
        kullanilmadi++;
      }
    }
    final mevcut = group.seanslar.length;
    final toplam = item.seansSayisi > mevcut ? item.seansSayisi : mevcut;
    final kalan = toplam - kullanildi - kullanilmadi;
    final ekstra = toplam - mevcut;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.adi,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$toplam Seans',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...List.generate(group.seanslar.length, (i) {
                final s = group.seanslar[i];
                final geldi = (s is Map) ? s['geldi'] : null;
                final iptal = (s is Map) ? s['iptal'] : null;
                Color bg;
                IconData? icon;
                if (geldi == 1) {
                  bg = const Color(0xFF2E7D32);
                  icon = Icons.check;
                } else if (geldi == 0 || iptal == 1 || iptal == true) {
                  bg = const Color(0xFFD32F2F);
                  icon = Icons.close;
                } else {
                  bg = Colors.transparent;
                  icon = null;
                }
                return GestureDetector(
                  onTap: () => _seansDetayDialog(item, s),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      border: icon == null
                          ? Border.all(
                              color: Colors.grey.shade400, width: 1.5)
                          : null,
                    ),
                    child: icon == null
                        ? null
                        : Icon(icon, color: Colors.white, size: 14),
                  ),
                );
              }),
              ...List.generate(
                ekstra > 0 ? ekstra : 0,
                (_) => GestureDetector(
                  onTap: () => _yeniSeansEkleDialog(item, group),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.grey.shade400, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Kullanıldı', kullanildi.toString(),
                    const Color(0xFF2E7D32)),
                _divider(),
                _miniStat(
                    'Kalan', kalan.toString(), const Color(0xFFFFA000)),
                _divider(),
                _miniStat('Kullanılmadı', kullanilmadi.toString(),
                    const Color(0xFFD32F2F)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color)),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 26, color: const Color(0xFFE0E0E0));
  }

  Widget _buildPaginationBar() {
    final canPrev = _currentPage > 1 && !_loading;
    final canNext = _currentPage < _lastPage && !_loading;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Toplam: $_total',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: _primary,
                onPressed: canPrev ? () => _goPage(_currentPage - 1) : null,
              ),
              Text('$_currentPage / $_lastPage',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: _primary,
                onPressed: canNext ? () => _goPage(_currentPage + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _ilkSeansTarihi(List<dynamic> seanslar) {
    String? best;
    for (final s in seanslar) {
      if (s is! Map) continue;
      final t = s['seans_tarih'];
      if (t == null) continue;
      final str = t.toString();
      if (str.isEmpty) continue;
      if (best == null || str.compareTo(best) < 0) best = str;
    }
    if (best == null || best.isEmpty) return '—';
    final parts = best.split('-');
    if (parts.length == 3) {
      return '${parts[2].substring(0, 2)}.${parts[1]}.${parts[0]}';
    }
    return best;
  }

  Future<void> _seansDurumGuncelle(
    BuildContext dialogCtx,
    dynamic seans,
    dynamic geldi,
  ) async {
    final seansId = (seans is Map ? seans['id'] : null)?.toString();
    if (seansId == null || seansId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seans kaydı bulunamadı.')),
      );
      return;
    }
    Navigator.of(dialogCtx).pop();
    try {
      await seansGuncelleApi(seansId, geldi, context);
    } catch (e, st) {
      log('seans guncelle hatasi: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seans güncellenirken hata oluştu.')),
        );
      }
    }
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _yeniSeansEkle(
    BuildContext dialogCtx,
    SeansTakip item,
    _HizmetGroup group,
    int geldi,
  ) async {
    String? paketId = item.paketHizmetId;
    int? paketMi;
    if (item.tip == 'paket') {
      paketMi = 1;
    } else if (item.tip == 'hizmet') {
      paketMi = 0;
    }

    if (paketId == null || paketMi == null) {
      final ornek = group.seanslar.isNotEmpty ? group.seanslar.first : null;
      if (ornek is Map) {
        if (ornek['adisyon_paket_id'] != null) {
          paketId = ornek['adisyon_paket_id'].toString();
          paketMi = 1;
        } else if (ornek['adisyon_hizmet_id'] != null) {
          paketId = ornek['adisyon_hizmet_id'].toString();
          paketMi = 0;
        }
      }
      paketMi ??= item.paket.contains('(P)') ? 1 : 0;
    }

    if (paketId == null || group.hizmetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu seans için bağlı paket/hizmet bulunamadı.')),
      );
      return;
    }
    Navigator.of(dialogCtx).pop();
    try {
      await seansEkleApi(paketId, group.hizmetId, paketMi, geldi, context);
    } catch (e, st) {
      log('seans ekle hatasi: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seans eklenirken hata oluştu.')),
        );
      }
    }
    if (!mounted) return;
    await _refresh();
  }

  void _yeniSeansEkleDialog(SeansTakip item, _HizmetGroup group) {
    final musteriAdi = (item.musteri is Map && item.musteri['name'] != null)
        ? item.musteri['name'].toString()
        : '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        title: const Text(
          'Yeni Seans Kullanımı',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _seansDetayRow(Icons.person, musteriAdi),
            const SizedBox(height: 8),
            _seansDetayRow(Icons.local_offer, group.adi),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _yuvarlakButon(
                  label: 'Kullanıldı',
                  icon: Icons.check,
                  color: const Color(0xFF2E7D32),
                  onTap: () => _yeniSeansEkle(ctx, item, group, 1),
                ),
                const SizedBox(width: 6),
                _yuvarlakButon(
                  label: 'Kullanılmadı',
                  icon: Icons.close,
                  color: const Color(0xFFD32F2F),
                  onTap: () => _yeniSeansEkle(ctx, item, group, 0),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İPTAL'),
          ),
        ],
      ),
    );
  }

  void _seansDetayDialog(SeansTakip item, dynamic seans) {
    if (seans is! Map) return;
    final musteriAdi = (item.musteri is Map &&
            item.musteri['name'] != null)
        ? item.musteri['name'].toString()
        : '';
    final hizmet = seans['hizmet'];
    final hizmetAdi = (hizmet is Map && hizmet['hizmet_adi'] != null)
        ? hizmet['hizmet_adi'].toString()
        : item.paket;
    final tarih = (seans['seans_tarih'] ?? '').toString();
    final saat = (seans['seans_saat'] ?? '').toString();
    final tarihStr = tarih.isEmpty
        ? '--.--.----'
        : (tarih.split('-').length == 3
            ? '${tarih.split('-')[2].substring(0, 2)}.${tarih.split('-')[1]}.${tarih.split('-')[0]}'
            : tarih);
    final saatStr = saat.isEmpty ? '--:--' : saat;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        title: const Text(
          'Seans Düzenle',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _seansDetayRow(Icons.person, musteriAdi),
            const SizedBox(height: 8),
            _seansDetayRow(Icons.local_offer, hizmetAdi),
            const SizedBox(height: 8),
            _seansDetayRow(
                Icons.calendar_today_rounded, '$tarihStr | $saatStr'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _yuvarlakButon(
                    label: 'Kullanıldı',
                    icon: Icons.check,
                    color: const Color(0xFF2E7D32),
                    onTap: () => _seansDurumGuncelle(ctx, seans, 1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _yuvarlakButon(
                    label: 'Kullanılmadı',
                    icon: Icons.close,
                    color: const Color(0xFFD32F2F),
                    onTap: () => _seansDurumGuncelle(ctx, seans, 0),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _yuvarlakButon(
                    label: 'Beklemede',
                    icon: Icons.access_time,
                    color: const Color(0xFFFFA000),
                    onTap: () => _seansDurumGuncelle(ctx, seans, ''),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('KAPAT'),
          ),
        ],
      ),
    );
  }

  Widget _seansDetayRow(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF667EEA), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _yuvarlakButon({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 10)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _HizmetGroup {
  final String adi;
  final String hizmetId;
  final List<dynamic> seanslar = [];
  _HizmetGroup({required this.adi, required this.hizmetId});
}
