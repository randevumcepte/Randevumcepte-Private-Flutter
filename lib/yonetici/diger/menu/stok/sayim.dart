import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/depo.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/services/stok_api.dart';

import 'barkod_tarayici.dart';

/// Sayım Modu — depo bazlı, manuel input + sürekli barkod tarama desteği.
class SayimSayfa extends StatefulWidget {
  final String salonId;
  final List<Urun> urunler;
  final List<Depo> depolar;
  const SayimSayfa({Key? key, required this.salonId, required this.urunler, required this.depolar}) : super(key: key);

  @override
  State<SayimSayfa> createState() => _SayimSayfaState();
}

class _SayimSayfaState extends State<SayimSayfa> {
  static const Color _mor = Color(0xFF6A1B9A);
  static const Color _yesil = Color(0xFF43A047);
  static const Color _kirmizi = Color(0xFFE53935);
  static const Color _sari = Color(0xFFF6A609);

  late String _depoId;
  final Map<String, double> _sayilan = {};
  bool _gondermeli = false;

  @override
  void initState() {
    super.initState();
    _depoId = widget.depolar.isNotEmpty
        ? (widget.depolar.firstWhere((d) => d.varsayilan, orElse: () => widget.depolar.first).id)
        : '';
    for (final u in widget.urunler) {
      _sayilan[u.id] = u.stokSayisal;
    }
  }

  void _arttir(String urunId, double miktar) {
    setState(() {
      _sayilan[urunId] = (_sayilan[urunId] ?? 0) + miktar;
    });
  }

  Future<void> _surekliTara() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => BarkodTarayici(
        baslik: 'Sayım — Sürekli Tara',
        surekli: true,
        onKod: (kod) async {
          final urun = await StokApi.urunBarkodAra(widget.salonId, kod);
          if (urun != null && mounted) _arttir(urun.id, 1);
        },
      ),
    ));
  }

  Future<void> _gonder() async {
    final farkliKalemler = <Map<String, dynamic>>[];
    for (final u in widget.urunler) {
      final sayilan = _sayilan[u.id] ?? 0;
      if ((sayilan - u.stokSayisal).abs() < 0.0001) continue;
      farkliKalemler.add({
        'urun_id': u.id,
        'depo_id': _depoId,
        'sayilan_miktar': sayilan,
      });
    }
    if (farkliKalemler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hiçbir üründe fark yok')));
      return;
    }
    final tamam = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sayımı Uygula'),
        content: Text('${farkliKalemler.length} üründe fark var. Düzeltme hareketleri oluşturulsun mu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Uygula')),
        ],
      ),
    );
    if (tamam != true) return;
    setState(() => _gondermeli = true);
    try {
      final r = await StokApi.sayimUygula(widget.salonId, farkliKalemler, meta: {'kullanici_tipi': 'isletme_yonetim'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r['sayilan_kalem']} kalemde düzeltme yapıldı'), backgroundColor: _yesil));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _kirmizi));
    } finally {
      if (mounted) setState(() => _gondermeli = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: const Text('Sayım Modu', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.barcode_reader, color: _mor), onPressed: _surekliTara, tooltip: 'Sürekli tara'),
        ],
      ),
      body: Column(
        children: [
          // Depo seçimi
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _depoId,
                isExpanded: true,
                items: widget.depolar.map((d) => DropdownMenuItem(value: d.id, child: Text('Depo: ${d.depo_adi}'))).toList(),
                onChanged: (v) => setState(() => _depoId = v ?? _depoId),
              ),
            ),
          ),

          // Liste
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.urunler.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final u = widget.urunler[i];
                final sayilan = _sayilan[u.id] ?? 0;
                final fark = sayilan - u.stokSayisal;
                final farkVar = fark.abs() > 0.0001;
                final renk = !farkVar ? Colors.black54 : (fark > 0 ? _yesil : _sari);

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.urun_adi, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('Sistem: ${u.stok_adedi} ${u.birim}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                            if (farkVar) Text('Fark: ${fark > 0 ? '+' : ''}${fark.toStringAsFixed(fark == fark.roundToDouble() ? 0 : 2)}', style: TextStyle(fontSize: 11, color: renk, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: _kirmizi), onPressed: () => _arttir(u.id, -1)),
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          initialValue: sayilan.toString(),
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                          onChanged: (v) {
                            final n = double.tryParse(v.replaceAll(',', '.'));
                            if (n != null) _sayilan[u.id] = n;
                          },
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.add_circle_outline, color: _yesil), onPressed: () => _arttir(u.id, 1)),
                    ],
                  ),
                );
              },
            ),
          ),

          // Alt
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _gondermeli ? null : _gonder,
                icon: _gondermeli
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Sayımı Uygula'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
