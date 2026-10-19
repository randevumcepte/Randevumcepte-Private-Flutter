// Cagri Merkezi — Telefonda Satis (Hizli Satis) sheet.
// Web'deki Hizli Satis popup paritesi: kalem (hizmet/urun/paket) + fiyat + odeme
// yontemi secilir -> CagriApi.hizliSatis GERCEK satis/adisyon olusturur (kasa).
// Kaydedilirse satis tutarini (double) dondurur; cagiran durum=7 isaretler.

import 'package:flutter/material.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';
import '../cagri_api.dart';

Future<double?> hizliSatisGoster(
  BuildContext context, {
  required String sube,
  required int musteriId,
  required String musteriAd,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _HizliSatisSheet(sube: sube, musteriId: musteriId, musteriAd: musteriAd),
  );
}

class _Kalem {
  final int id;
  final String ad;
  final double fiyat;
  _Kalem(this.id, this.ad, this.fiyat);
}

class _HizliSatisSheet extends StatefulWidget {
  final String sube;
  final int musteriId;
  final String musteriAd;
  const _HizliSatisSheet(
      {required this.sube, required this.musteriId, required this.musteriAd});

  @override
  State<_HizliSatisSheet> createState() => _HizliSatisSheetState();
}

class _HizliSatisSheetState extends State<_HizliSatisSheet> {
  bool _yukleniyor = true;
  bool _kaydediyor = false;
  String? _hata;

  final Map<String, List<_Kalem>> _kalemler = {
    'hizmet': [],
    'urun': [],
    'paket': [],
  };
  List<_Kalem> _odeme = [];

  String _tip = 'hizmet';
  int? _kalemId;
  int? _odemeId;
  final TextEditingController _fiyat = TextEditingController();
  final TextEditingController _adet = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _fiyat.dispose();
    _adet.dispose();
    super.dispose();
  }

  List<_Kalem> _parse(dynamic liste) {
    if (liste is! List) return [];
    return liste.map<_Kalem>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return _Kalem(
        int.tryParse('${m['id']}') ?? 0,
        (m['ad'] ?? '').toString(),
        double.tryParse('${m['fiyat']}'.replaceAll(',', '.')) ?? 0,
      );
    }).toList();
  }

  Future<void> _yukle() async {
    try {
      final j = await CagriApi.satisKalemler(widget.sube);
      if (!mounted) return;
      setState(() {
        _kalemler['hizmet'] = _parse(j['hizmetler']);
        _kalemler['urun'] = _parse(j['urunler']);
        _kalemler['paket'] = _parse(j['paketler']);
        _odeme = _parse(j['odeme_yontemleri']);
        if (_odeme.isNotEmpty) _odemeId = _odeme.first.id;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = 'Kalemler yüklenemedi: $e';
        _yukleniyor = false;
      });
    }
  }

  List<_Kalem> get _aktifKalemler => _kalemler[_tip] ?? [];

  void _kalemSec(int? id) {
    final k = _aktifKalemler.where((x) => x.id == id).toList();
    setState(() {
      _kalemId = id;
      if (k.isNotEmpty && k.first.fiyat > 0) {
        _fiyat.text = k.first.fiyat.toStringAsFixed(
            k.first.fiyat.truncateToDouble() == k.first.fiyat ? 0 : 2);
      }
    });
  }

  Future<void> _kaydet() async {
    final fiyat =
        double.tryParse(_fiyat.text.replaceAll(',', '.')) ?? 0;
    final adet = int.tryParse(_adet.text) ?? 1;
    if (_kalemId == null) {
      _uyar('Hizmet / ürün / paket seçin.');
      return;
    }
    if (fiyat <= 0) {
      _uyar('Fiyat girin.');
      return;
    }
    if (_odemeId == null) {
      _uyar('Ödeme yöntemi seçin.');
      return;
    }
    setState(() => _kaydediyor = true);
    try {
      final r = await CagriApi.hizliSatis(
        sube: widget.sube,
        musteriId: widget.musteriId,
        kalemTip: _tip,
        kalemId: _kalemId!,
        fiyat: fiyat,
        odemeYontemi: _odemeId!,
        adet: adet < 1 ? 1 : adet,
      );
      if (!mounted) return;
      final ok = r['success'] == true || r['basarili'] == true;
      if (ok) {
        Navigator.of(context).pop(fiyat * (adet < 1 ? 1 : adet));
      } else {
        setState(() => _kaydediyor = false);
        _uyar((r['message'] ?? 'Satış kaydedilemedi.').toString());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediyor = false);
      _uyar('Hata: $e');
    }
  }

  void _uyar(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.68,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scroll) => Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: ext.borderStrong,
                    borderRadius: BorderRadius.circular(99)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: cs.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Telefonda Satış',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                    ),
                    Flexible(
                      child: Text(widget.musteriAd,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _yukleniyor
                    ? const Center(child: CircularProgressIndicator())
                    : _hata != null
                        ? Center(
                            child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(_hata!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red))))
                        : ListView(
                            controller: scroll,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            children: [
                              // Kalem tipi
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                      value: 'hizmet', label: Text('Hizmet')),
                                  ButtonSegment(
                                      value: 'urun', label: Text('Ürün')),
                                  ButtonSegment(
                                      value: 'paket', label: Text('Paket')),
                                ],
                                selected: {_tip},
                                onSelectionChanged: (s) => setState(() {
                                  _tip = s.first;
                                  _kalemId = null;
                                  _fiyat.clear();
                                }),
                              ),
                              const SizedBox(height: 14),
                              // Kalem
                              AramaliDropdownFormField<int>(
                                value: _kalemId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: _tip == 'hizmet'
                                      ? 'Hizmet'
                                      : _tip == 'urun'
                                          ? 'Ürün'
                                          : 'Paket',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md)),
                                ),
                                items: _aktifKalemler
                                    .map((k) => DropdownMenuItem<int>(
                                        value: k.id, child: Text(k.ad)))
                                    .toList(),
                                onChanged: _kalemSec,
                                searchText: (id) => _aktifKalemler
                                    .firstWhere((x) => x.id == id,
                                        orElse: () => _Kalem(0, '', 0))
                                    .ad,
                              ),
                              const SizedBox(height: 12),
                              // Fiyat + Adet
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _fiyat,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Fiyat (₺)',
                                        prefixIcon:
                                            const Icon(Icons.payments_outlined),
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: _adet,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Adet',
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Odeme yontemi
                              AramaliDropdownFormField<int>(
                                value: _odemeId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Ödeme Yöntemi',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md)),
                                ),
                                items: _odeme
                                    .map((o) => DropdownMenuItem<int>(
                                        value: o.id, child: Text(o.ad)))
                                    .toList(),
                                onChanged: (v) => setState(() => _odemeId = v),
                              ),
                            ],
                          ),
              ),
              if (!_yukleniyor && _hata == null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _kaydediyor ? null : _kaydet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        icon: _kaydediyor
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.shopping_bag_outlined),
                        label: Text(_kaydediyor ? 'Kaydediliyor...' : 'Satışı Kaydet',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
