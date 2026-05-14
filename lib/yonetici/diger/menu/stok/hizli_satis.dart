import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/services/birim_helper.dart';
import 'package:randevu_sistem/services/stok_api.dart';

import 'barkod_tarayici.dart';

class HizliSatisSayfa extends StatefulWidget {
  final String salonId;
  final List<Urun> urunler;
  const HizliSatisSayfa({Key? key, required this.salonId, required this.urunler}) : super(key: key);

  @override
  State<HizliSatisSayfa> createState() => _HizliSatisSayfaState();
}

class _SepetKalem {
  final Urun urun;
  double miktar;
  double birimFiyat;
  _SepetKalem({required this.urun, required this.miktar, required this.birimFiyat});
  double get tutar => miktar * birimFiyat;
}

class _HizliSatisSayfaState extends State<HizliSatisSayfa> {
  static const Color _mor = Color(0xFF6A1B9A);
  static const Color _yesil = Color(0xFF43A047);
  static const Color _kirmizi = Color(0xFFE53935);

  final TextEditingController _aramaCtl = TextEditingController();
  final List<_SepetKalem> _sepet = [];
  bool _gondermeli = false;

  @override
  void dispose() {
    _aramaCtl.dispose();
    super.dispose();
  }

  void _ekle(Urun u) {
    final mevcut = _sepet.indexWhere((k) => k.urun.id == u.id);
    setState(() {
      if (mevcut >= 0) {
        _sepet[mevcut].miktar += 1;
      } else {
        _sepet.add(_SepetKalem(urun: u, miktar: 1, birimFiyat: u.fiyatSayisal));
      }
    });
  }

  Future<void> _barkodTara() async {
    final kod = await BarkodTarayici.tekSeferTara(context, baslik: 'Sat — Barkod Tara');
    if (kod == null || kod.isEmpty) return;
    final urun = await StokApi.urunBarkodAra(widget.salonId, kod);
    if (urun != null) {
      _ekle(urun);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Barkod bulunamadı: $kod'), backgroundColor: _kirmizi));
    }
  }

  Future<void> _surekliTara() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => BarkodTarayici(
        baslik: 'Sürekli Sat — Tara',
        surekli: true,
        onKod: (kod) async {
          final urun = await StokApi.urunBarkodAra(widget.salonId, kod);
          if (urun != null && mounted) _ekle(urun);
        },
      ),
    ));
  }

  Future<void> _gonder() async {
    if (_sepet.isEmpty) return;
    setState(() => _gondermeli = true);
    try {
      final r = await StokApi.hizliSatis(widget.salonId, _sepet.map((k) => {
        'urun_id': k.urun.id,
        'miktar': k.miktar,
        'birim_fiyat': k.birimFiyat,
      }).toList(), meta: {'kullanici_tipi': 'isletme_yonetim'});
      if (!mounted) return;
      if (r['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Satış tamam — Toplam ₺${r['toplam_tutar']}'), backgroundColor: _yesil));
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
    final filtreli = _aramaCtl.text.isEmpty
        ? widget.urunler.take(20).toList()
        : widget.urunler.where((u) => u.urun_adi.toLowerCase().contains(_aramaCtl.text.toLowerCase()) || u.barkod.contains(_aramaCtl.text)).toList();
    final toplam = _sepet.fold<double>(0, (s, k) => s + k.tutar);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: const Text('Hızlı Satış', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner, color: _mor), onPressed: _barkodTara, tooltip: 'Tek tara'),
          IconButton(icon: const Icon(Icons.barcode_reader, color: _mor), onPressed: _surekliTara, tooltip: 'Sürekli tara'),
        ],
      ),
      body: Column(
        children: [
          // Arama
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _aramaCtl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Ürün ara veya barkod...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          // Ürün listesi
          if (filtreli.isNotEmpty)
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filtreli.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final u = filtreli[i];
                  return InkWell(
                    onTap: () => _ekle(u),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(u.urun_adi, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('₺${u.fiyat}', style: const TextStyle(color: _mor, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          // Sepet
          Expanded(
            child: _sepet.isEmpty
                ? const Center(child: Text('Sepet boş', style: TextStyle(color: Colors.black45)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _sepet.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final k = _sepet[i];
                      final birim = k.urun.birim;
                      final artis = BirimHelper.stepperArtis(birim);
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(k.urun.urun_adi, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text('₺${k.birimFiyat.toStringAsFixed(2)} / $birim', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: _kirmizi),
                              onPressed: () => setState(() {
                                k.miktar -= artis;
                                if (k.miktar <= 0) _sepet.removeAt(i);
                              }),
                            ),
                            Column(
                              children: [
                                Text(BirimHelper.sayi(k.miktar, birim), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                Text(birim, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: _yesil),
                              onPressed: () => setState(() => k.miktar += artis),
                            ),
                            Text('₺${k.tutar.toStringAsFixed(2)}', style: const TextStyle(color: _mor, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Alt kısım: toplam + onay
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
                    const Expanded(child: Text('Toplam', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54))),
                    Text('₺${toplam.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: _mor)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_sepet.isEmpty || _gondermeli) ? null : _gonder,
                    icon: _gondermeli
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: const Text('Satışı Tamamla'),
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
}
