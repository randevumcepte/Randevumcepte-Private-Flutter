import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/depo.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';
import 'package:randevu_sistem/Models/tedarikci.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/services/birim_helper.dart';
import 'package:randevu_sistem/services/stok_api.dart';

import 'barkod_tarayici.dart';

class _AlisKalemi {
  Urun? urun;
  double miktar;
  double birimAlisFiyati;
  /// Bu parti için yeni satış fiyatı — null ise ürünün mevcut satış fiyatı değişmez.
  /// UI'dan setter ile atanır (constructor'da verilmez).
  double? yeniSatisFiyati;
  _AlisKalemi({this.urun, this.miktar = 1, this.birimAlisFiyati = 0});
}

/// Tedarikçiden mal kabul — toplu alış girişi.
class AlisGirisiSayfa extends StatefulWidget {
  final String salonId;
  final List<Urun> urunler;
  final List<Depo> depolar;
  final List<Tedarikci> tedarikciler;
  const AlisGirisiSayfa({
    Key? key,
    required this.salonId,
    required this.urunler,
    required this.depolar,
    required this.tedarikciler,
  }) : super(key: key);

  @override
  State<AlisGirisiSayfa> createState() => _AlisGirisiSayfaState();
}

class _AlisGirisiSayfaState extends State<AlisGirisiSayfa> {
  static const Color _mor = Color(0xFF6A1B9A);
  static const Color _yesil = Color(0xFF43A047);
  static const Color _kirmizi = Color(0xFFE53935);

  final List<_AlisKalemi> _kalemler = [];
  String? _tedarikciId;
  String? _depoId;
  final TextEditingController _aciklamaCtl = TextEditingController();
  bool _gondermeli = false;

  @override
  void initState() {
    super.initState();
    if (widget.depolar.isNotEmpty) {
      _depoId = widget.depolar.firstWhere((d) => d.varsayilan, orElse: () => widget.depolar.first).id;
    }
    _kalemler.add(_AlisKalemi());
  }

  @override
  void dispose() {
    _aciklamaCtl.dispose();
    super.dispose();
  }

  Future<void> _barkodEkle() async {
    final kod = await BarkodTarayici.tekSeferTara(context, baslik: 'Alış — Barkod Tara');
    if (kod == null) return;
    final urun = await StokApi.urunBarkodAra(widget.salonId, kod);
    if (urun != null) {
      setState(() => _kalemler.add(_AlisKalemi(urun: urun, miktar: 1, birimAlisFiyati: urun.alisFiyatiSayisal)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Barkod bulunamadı: $kod'), backgroundColor: _kirmizi));
    }
  }

  Future<void> _gonder() async {
    final dolu = _kalemler.where((k) => k.urun != null && k.miktar > 0).toList();
    if (dolu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kalem ekle')));
      return;
    }
    setState(() => _gondermeli = true);
    try {
      // 1) Parti satış fiyatı override edilenler için önce ürünü güncelle
      for (final k in dolu) {
        if (k.yeniSatisFiyati != null && k.yeniSatisFiyati! > 0 &&
            (k.yeniSatisFiyati! - k.urun!.fiyatSayisal).abs() > 0.001) {
          await StokApi.urunKaydet(widget.salonId, {
            'id': k.urun!.id,
            'urun_adi': k.urun!.urun_adi,
            'barkod': k.urun!.barkod,
            'sku': k.urun!.sku,
            'fiyat': k.yeniSatisFiyati,
            'alis_fiyati': k.birimAlisFiyati,
            'kdv_orani': k.urun!.kdv_orani,
            'birim': k.urun!.birim,
            'tip': k.urun!.tip,
            'kategori_id': k.urun!.kategori_id,
            'tedarikci_id': _tedarikciId ?? k.urun!.tedarikci_id,
            'stok_adedi': k.urun!.stok_adedi,
            'dusuk_stok_siniri': k.urun!.dusuk_stok_siniri,
            'kritik_stok_siniri': k.urun!.kritik_stok_siniri,
            'aciklama': k.urun!.aciklama,
            'kullanici_tipi': 'isletme_yonetim',
          });
        }
      }
      // 2) Alış girişini yap (stok hareketi olarak depoya işlenir)
      final r = await StokApi.alisGirisi(widget.salonId, {
        'tedarikci_id': _tedarikciId ?? '',
        'depo_id': _depoId ?? '',
        'aciklama': _aciklamaCtl.text,
        'kalemler': dolu.map((k) => {
              'urun_id': k.urun!.id,
              'miktar': k.miktar,
              'birim_alis_fiyati': k.birimAlisFiyati,
            }).toList(),
        'kullanici_tipi': 'isletme_yonetim',
      });
      if (!mounted) return;
      if (r['status'] == 'ok') {
        final fiyatGuncel = dolu.where((k) => k.yeniSatisFiyati != null && k.yeniSatisFiyati! > 0).length;
        final msg = fiyatGuncel > 0
            ? 'Alış kaydedildi (${r['kalem_sayisi']} kalem) — $fiyatGuncel ürünün satış fiyatı güncellendi'
            : 'Alış kaydedildi (${r['kalem_sayisi']} kalem)';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _yesil));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['mesaj']?.toString() ?? 'Hata'), backgroundColor: _kirmizi));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _kirmizi));
    } finally {
      if (mounted) setState(() => _gondermeli = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final toplam = _kalemler.fold<double>(0, (s, k) => s + (k.miktar * k.birimAlisFiyati));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: const Text('Alış Girişi', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner, color: _mor), onPressed: _barkodEkle),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _dropdown<String>('Tedarikçi', _tedarikciId,
                    [const DropdownMenuItem<String>(value: '', child: Text('— Seç —'))] +
                    widget.tedarikciler.map((t) => DropdownMenuItem<String>(value: t.id, child: Text(t.ad))).toList(),
                    (v) => setState(() => _tedarikciId = v == '' ? null : v)),
                const SizedBox(height: 8),
                _dropdown<String>('Depo', _depoId,
                    widget.depolar.map((d) => DropdownMenuItem<String>(value: d.id, child: Text(d.depo_adi))).toList(),
                    (v) => setState(() => _depoId = v)),
                const SizedBox(height: 8),
                TextField(
                  controller: _aciklamaCtl,
                  decoration: InputDecoration(
                    hintText: 'Açıklama / Fiş No',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _kalemler.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final k = _kalemler[i];
                final birim = k.urun?.birim ?? '';
                final birimEtiket = birim.isEmpty ? 'Miktar' : 'Miktar ($birim)';
                final birimFiyatEtiket = birim.isEmpty ? 'Birim ₺' : '₺ / $birim';
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _dropdown<String>('Ürün', k.urun?.id,
                          [const DropdownMenuItem<String>(value: '', child: Text('— Seç —'))] +
                          widget.urunler
                              .map((u) => DropdownMenuItem<String>(
                                    value: u.id,
                                    child: Text('${u.urun_adi}  ·  ${u.birim}', overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          (v) => setState(() {
                                if (v == null || v == '') {
                                  k.urun = null;
                                  return;
                                }
                                k.urun = widget.urunler.firstWhere((x) => x.id == v);
                                if (k.birimAlisFiyati == 0) k.birimAlisFiyati = k.urun!.alisFiyatiSayisal;
                                if (k.miktar == 0 || k.miktar == 1) {
                                  k.miktar = BirimHelper.varsayilanBaslangic(k.urun!.birim);
                                }
                              })),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: birim.isEmpty ? k.miktar.toString() : BirimHelper.sayi(k.miktar, birim),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: birimEtiket,
                                border: const OutlineInputBorder(),
                                suffixText: birim.isEmpty ? null : birim,
                                suffixStyle: const TextStyle(fontWeight: FontWeight.w700, color: _mor),
                              ),
                              onChanged: (v) => k.miktar = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextFormField(
                              initialValue: k.birimAlisFiyati == 0 ? '' : k.birimAlisFiyati.toString(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: birimFiyatEtiket, border: const OutlineInputBorder()),
                              onChanged: (v) {
                                setState(() => k.birimAlisFiyati = double.tryParse(v.replaceAll(',', '.')) ?? 0);
                              },
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.delete_outline, color: _kirmizi), onPressed: () => setState(() => _kalemler.removeAt(i))),
                        ],
                      ),
                      if (k.urun != null && k.miktar > 0 && k.birimAlisFiyati > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${BirimHelper.formatla(k.miktar, birim)} × ₺${k.birimAlisFiyati.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                              Text('₺${(k.miktar * k.birimAlisFiyati).toStringAsFixed(2)}', style: const TextStyle(color: _mor, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      // Satış fiyatı override — sadece satılan tipler için
                      if (k.urun != null && (k.urun!.tip == 'satis' || k.urun!.tip == 'karma'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.sell_outlined, color: _mor, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Mevcut satış: ₺${k.urun!.fiyat} / ${k.urun!.birim}',
                                      style: const TextStyle(color: _mor, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  initialValue: k.yeniSatisFiyati == null ? '' : k.yeniSatisFiyati.toString(),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    labelText: 'Yeni satış fiyatı (opsiyonel)',
                                    labelStyle: const TextStyle(fontSize: 11),
                                    helperText: 'Bu parti için satış fiyatı değişiyorsa girin — boş bırakırsanız aynı kalır',
                                    helperStyle: const TextStyle(fontSize: 10),
                                    prefixText: '₺ ',
                                    suffixText: ' / ${k.urun!.birim}',
                                    suffixStyle: const TextStyle(fontSize: 10),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                  onChanged: (v) {
                                    final n = double.tryParse(v.replaceAll(',', '.'));
                                    setState(() => k.yeniSatisFiyati = (n != null && n > 0) ? n : null);
                                  },
                                ),
                                // Yeni satış girilmişse kâr preview
                                if (k.yeniSatisFiyati != null && k.yeniSatisFiyati! > 0 && k.birimAlisFiyati > 0) ...[
                                  const SizedBox(height: 6),
                                  Builder(builder: (_) {
                                    final kar = k.yeniSatisFiyati! - k.birimAlisFiyati;
                                    final marj = (kar / k.yeniSatisFiyati!) * 100;
                                    final pozitif = kar >= 0;
                                    final renk = pozitif ? const Color(0xFF43A047) : const Color(0xFFE53935);
                                    return Row(
                                      children: [
                                        Icon(pozitif ? Icons.trending_up : Icons.trending_down, color: renk, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Birim kâr: ₺${kar.toStringAsFixed(2)} (%${marj.toStringAsFixed(0)})',
                                          style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _kalemler.add(_AlisKalemi())),
                        icon: const Icon(Icons.add),
                        label: const Text('Kalem Ekle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _mor,
                          side: const BorderSide(color: _mor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('Toplam Tutar', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
                    Text('₺${toplam.toStringAsFixed(2)}', style: const TextStyle(color: _mor, fontWeight: FontWeight.w800, fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _gondermeli ? null : _gonder,
                    icon: _gondermeli
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: const Text('Alışı Kaydet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _yesil,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>(String etiket, T? secili, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: etiket,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      child: DropdownButtonHideUnderline(
        child: AramaliDropdown<T>(value: secili, isExpanded: true, items: items, onChanged: onChanged),
      ),
    );
  }
}
