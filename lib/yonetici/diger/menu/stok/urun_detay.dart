import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/depo.dart';
import 'package:randevu_sistem/Models/stok_hareketi.dart';
import 'package:randevu_sistem/Models/tedarikci.dart';
import 'package:randevu_sistem/Models/urun_kategorisi.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/services/birim_helper.dart';
import 'package:randevu_sistem/services/stok_api.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

import 'urun_form.dart';

/// Ürün detay ekranı — Tab'lı: Bilgiler / Hareketler / Depolar / Raporlar.
class UrunDetaySayfa extends StatefulWidget {
  final Urun urun;
  final String salonId;
  final List<Depo> depolar;
  final List<UrunKategorisi> kategoriler;
  final List<Tedarikci> tedarikciler;

  const UrunDetaySayfa({
    Key? key,
    required this.urun,
    required this.salonId,
    required this.depolar,
    required this.kategoriler,
    required this.tedarikciler,
  }) : super(key: key);

  @override
  State<UrunDetaySayfa> createState() => _UrunDetaySayfaState();
}

class _UrunDetaySayfaState extends State<UrunDetaySayfa> with SingleTickerProviderStateMixin {
  static const Color _mor      = Color(0xFF6A1B9A);
  static const Color _morSoft  = Color(0xFFF3E8FA);
  static const Color _sari     = Color(0xFFF6A609);
  static const Color _kirmizi  = Color(0xFFE53935);
  static const Color _yesil    = Color(0xFF43A047);

  late TabController _tabCtl;
  late Urun _urun;
  Map<String, dynamic> _detay = {};
  List<StokHareketi> _hareketler = [];
  List<dynamic> _satisRaporu = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _urun = widget.urun;
    _tabCtl = TabController(length: 4, vsync: this);
    _yukle();
  }

  @override
  void dispose() {
    _tabCtl.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final results = await Future.wait([
        StokApi.urunDetay(_urun.id),
        StokApi.hareketListesi(widget.salonId, urunId: _urun.id, limit: 200),
        StokApi.urunSatisRaporu(_urun.id),
      ]);
      _detay = results[0] as Map<String, dynamic>;
      _hareketler = (results[1] as List).cast<StokHareketi>();
      _satisRaporu = results[2] as List<dynamic>;
      if (_detay.isNotEmpty) {
        _urun = Urun.fromJson(_detay);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _duzenle() async {
    final sonuc = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => UrunForm(
        salonId: widget.salonId,
        kategoriler: widget.kategoriler,
        tedarikciler: widget.tedarikciler,
        mevcut: _urun,
      ),
    ));
    if (sonuc == true) _yukle();
  }

  Future<void> _sil() async {
    final tamam = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sil'),
        content: Text('${_urun.urun_adi} ürünü pasif yapılacak. Onaylıyor musun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Sil')),
        ],
      ),
    );
    if (tamam == true) {
      await StokApi.urunSil(_urun.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _manuelHareket() async {
    String tip = 'fire';
    final miktarCtl = TextEditingController();
    final aciklamaCtl = TextEditingController();
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          title: const Text('Manuel Hareket'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AramaliDropdownFormField<String>(
                  value: tip,
                  items: const [
                    DropdownMenuItem(value: 'fire',   child: Text('Fire (Çöp/Bozuk)')),
                    DropdownMenuItem(value: 'manuel', child: Text('Manuel Düzeltme')),
                    DropdownMenuItem(value: 'iade',   child: Text('İade (Stoğa Geri)')),
                  ],
                  onChanged: (v) => setSt(() => tip = v ?? 'fire'),
                  decoration: const InputDecoration(labelText: 'Hareket Tipi'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: miktarCtl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Miktar (mutlak değer)',
                    suffixText: _urun.birim,
                    suffixStyle: const TextStyle(fontWeight: FontWeight.w700, color: _mor),
                    helperText: 'Stoğa girer (iade) veya stoktan düşer (fire) — birim: ${BirimHelper.uzunAd(_urun.birim)}',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(controller: aciklamaCtl, decoration: const InputDecoration(labelText: 'Açıklama')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text('Kaydet')),
          ],
        );
      }),
    );
    if (sonuc == true) {
      final miktar = double.tryParse(miktarCtl.text.replaceAll(',', '.')) ?? 0;
      if (miktar <= 0) return;
      await StokApi.manuelHareket(widget.salonId, {
        'urun_id': _urun.id,
        'miktar': miktar,
        'hareket_tipi': tip,
        'aciklama': aciklamaCtl.text,
        'kullanici_tipi': 'isletme_yonetim',
      });
      _yukle();
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
        title: Text(_urun.urun_adi, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: _mor), onPressed: _duzenle),
          IconButton(icon: const Icon(Icons.delete_outline, color: _kirmizi), onPressed: _sil),
        ],
        bottom: TabBar(
          controller: _tabCtl,
          labelColor: _mor,
          unselectedLabelColor: Colors.black54,
          indicatorColor: _mor,
          tabs: const [
            Tab(text: 'Bilgiler'),
            Tab(text: 'Hareketler'),
            Tab(text: 'Depolar'),
            Tab(text: 'Rapor'),
          ],
        ),
      ),
      floatingActionButton: _tabCtl.index == 1
          ? FloatingActionButton.extended(
              backgroundColor: _mor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Manuel Hareket'),
              onPressed: _manuelHareket,
            )
          : null,
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: _mor))
          : TabBarView(
              controller: _tabCtl,
              children: [
                _bilgilerTab(),
                _hareketlerTab(),
                _depolarTab(),
                _raporTab(),
              ],
            ),
    );
  }

  // ============================================================
  // TAB 1: BİLGİLER
  // ============================================================

  Widget _bilgilerTab() {
    final stokRenk = _urun.stokDurumu == 'kirmizi' ? _kirmizi : (_urun.stokDurumu == 'sari' ? _sari : _yesil);
    final mar = _urun.alisFiyatiSayisal > 0 ? ((_urun.fiyatSayisal - _urun.alisFiyatiSayisal) / _urun.alisFiyatiSayisal) * 100 : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst karne
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_mor, Color(0xFF8E24AA)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Anlık Stok', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text('${_adetFormat(_urun.stokSayisal)} ${_urun.birim}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                      child: Text(_urun.tip.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  children: [
                    Expanded(child: _kucukBilgi('Satış', '₺${_tlFormat(_urun.fiyatSayisal)}', Colors.white)),
                    if (_urun.alisFiyatiSayisal > 0) Expanded(child: _kucukBilgi('Alış', '₺${_tlFormat(_urun.alisFiyatiSayisal)}', Colors.white)),
                    if (mar != null) Expanded(child: _kucukBilgi('Marj', '%${mar.toStringAsFixed(0)}', mar >= 0 ? Colors.white : Colors.amberAccent)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Detay grid
          _kartGrubu([
            _satir(Icons.qr_code, 'Barkod', _urun.barkod.isEmpty ? '—' : _urun.barkod),
            _satir(Icons.tag, 'SKU', _urun.sku.isEmpty ? '—' : _urun.sku),
            _satir(Icons.category_outlined, 'Kategori', _urun.kategori_adi.isEmpty ? '—' : _urun.kategori_adi),
            _satir(Icons.local_shipping_outlined, 'Tedarikçi', _urun.tedarikci_adi.isEmpty ? '—' : _urun.tedarikci_adi),
            _satir(Icons.straighten, 'Birim', _urun.birim),
            if (_urun.kdv_orani.isNotEmpty) _satir(Icons.percent, 'KDV', '%${_urun.kdv_orani}'),
            _satir(Icons.warning_amber, 'Düşük Stok Sınırı', _urun.dusuk_stok_siniri.isEmpty ? '—' : _urun.dusuk_stok_siniri),
            _satir(Icons.priority_high, 'Kritik Stok Sınırı', _urun.kritik_stok_siniri.isEmpty ? '—' : _urun.kritik_stok_siniri),
          ]),

          if (_urun.aciklama.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Açıklama', style: TextStyle(color: _mor, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text(_urun.aciklama),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          // Stok durumu uyarısı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: stokRenk.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: stokRenk.withValues(alpha: 0.3))),
            child: Row(
              children: [
                Icon(_urun.stokDurumu == 'kirmizi' ? Icons.error : (_urun.stokDurumu == 'sari' ? Icons.warning : Icons.check_circle), color: stokRenk),
                const SizedBox(width: 10),
                Expanded(child: Text(_urun.stokDurumu == 'kirmizi' ? 'Stok kritik seviyede veya tükendi' : (_urun.stokDurumu == 'sari' ? 'Stok düşük seviyede' : 'Stok yeterli'), style: TextStyle(color: stokRenk, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kucukBilgi(String etiket, String deger, Color renk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiket, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 2),
        Text(deger, style: TextStyle(color: renk, fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }

  Widget _kartGrubu(List<Widget> satirlar) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: List.generate(satirlar.length * 2 - 1, (i) {
          if (i.isEven) return satirlar[i ~/ 2];
          return const Divider(height: 1);
        }),
      ),
    );
  }

  Widget _satir(IconData ikon, String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(ikon, color: _mor, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(etiket, style: const TextStyle(color: Colors.black54))),
          Text(deger, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 2: HAREKETLER
  // ============================================================

  Widget _hareketlerTab() {
    if (_hareketler.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Hareket yok', style: TextStyle(color: Colors.black54))));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _hareketler.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final h = _hareketler[i];
        final art = h.miktarSayisal > 0;
        final renk = art ? _yesil : _kirmizi;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(art ? Icons.add : Icons.remove, color: renk),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.tipEtiket, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(h.tarih, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    if (h.aciklama.isNotEmpty) Text(h.aciklama, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${art ? '+' : ''}${BirimHelper.sayi(h.miktarSayisal, _urun.birim)}', style: TextStyle(color: renk, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(_urun.birim, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // TAB 3: DEPOLAR
  // ============================================================

  Widget _depolarTab() {
    final depoStoklari = (_detay['depo_stoklari'] as List<dynamic>?) ?? [];
    final mapStok = <String, double>{};
    for (final d in depoStoklari) {
      final id = d['depo_id'].toString();
      mapStok[id] = double.tryParse(d['stok'].toString()) ?? 0;
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: widget.depolar.map((d) {
        final stok = mapStok[d.id] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _morSoft, shape: BoxShape.circle),
                child: const Icon(Icons.warehouse_outlined, color: _mor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.depo_adi, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (d.varsayilan) const Text('Varsayılan depo', style: TextStyle(fontSize: 11, color: _yesil)),
                  ],
                ),
              ),
              Text('${_adetFormat(stok)} ${_urun.birim}', style: const TextStyle(fontWeight: FontWeight.w800, color: _mor)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // TAB 4: RAPOR
  // ============================================================

  Widget _raporTab() {
    if (_satisRaporu.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Son 30 günde satış yok', style: TextStyle(color: Colors.black54))));
    }
    double maks = 0;
    for (final s in _satisRaporu) {
      final t = double.tryParse(s['tutar']?.toString() ?? '0') ?? 0;
      if (t > maks) maks = t;
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: _satisRaporu.map((s) {
        final gun   = s['gun']?.toString() ?? '';
        final adet  = double.tryParse(s['adet']?.toString() ?? '0') ?? 0;
        final tutar = double.tryParse(s['tutar']?.toString() ?? '0') ?? 0;
        final oran  = maks > 0 ? (tutar / maks) : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(gun, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text('${_adetFormat(adet)} ${_urun.birim}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(width: 10),
                  Text('₺${_tlFormat(tutar)}', style: const TextStyle(fontWeight: FontWeight.w800, color: _mor)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: oran.toDouble(), backgroundColor: _morSoft, valueColor: const AlwaysStoppedAnimation(_mor), minHeight: 6),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // YARDIMCILAR
  // ============================================================

  static String _tlFormat(double n) {
    final s = n.toStringAsFixed(2);
    final parts = s.split('.');
    final tam = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$tam,${parts[1]}';
  }

  static String _adetFormat(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(3);
  }
}
