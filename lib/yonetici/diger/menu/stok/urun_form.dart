import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/tedarikci.dart';
import 'package:randevu_sistem/Models/urun_kategorisi.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/services/stok_api.dart';

import 'barkod_tarayici.dart';

/// Yeni ürün ekleme / mevcut ürünü düzenleme formu.
class UrunForm extends StatefulWidget {
  final String salonId;
  final List<UrunKategorisi> kategoriler;
  final List<Tedarikci> tedarikciler;
  final Urun? mevcut;
  final String? barkodOnDoldur;

  const UrunForm({
    Key? key,
    required this.salonId,
    required this.kategoriler,
    required this.tedarikciler,
    this.mevcut,
    this.barkodOnDoldur,
  }) : super(key: key);

  @override
  State<UrunForm> createState() => _UrunFormState();
}

class _UrunFormState extends State<UrunForm> {
  static const Color _mor = Color(0xFF6A1B9A);

  final _adCtl    = TextEditingController();
  final _barkodCtl = TextEditingController();
  final _skuCtl    = TextEditingController();
  final _fiyatCtl  = TextEditingController();
  final _alisCtl   = TextEditingController();
  final _kdvCtl    = TextEditingController();
  final _stokCtl   = TextEditingController(text: '0');
  final _dusukCtl  = TextEditingController();
  final _kritikCtl = TextEditingController();
  final _aciklamaCtl = TextEditingController();

  String _tip = 'satis';
  String _birim = 'adet';
  String? _kategoriId;
  String? _tedarikciId;
  bool _kaydediliyor = false;

  bool get _duzenleme => widget.mevcut != null;

  @override
  void initState() {
    super.initState();
    final u = widget.mevcut;
    if (u != null) {
      _adCtl.text       = u.urun_adi;
      _barkodCtl.text   = u.barkod;
      _skuCtl.text      = u.sku;
      _fiyatCtl.text    = u.fiyat;
      _alisCtl.text     = u.alis_fiyati;
      _kdvCtl.text      = u.kdv_orani;
      _stokCtl.text     = u.stok_adedi;
      _dusukCtl.text    = u.dusuk_stok_siniri;
      _kritikCtl.text   = u.kritik_stok_siniri;
      _aciklamaCtl.text = u.aciklama;
      _tip   = u.tip.isEmpty ? 'satis' : u.tip;
      _birim = u.birim.isEmpty ? 'adet' : u.birim;
      _kategoriId  = u.kategori_id.isEmpty ? null : u.kategori_id;
      _tedarikciId = u.tedarikci_id.isEmpty ? null : u.tedarikci_id;
    } else if (widget.barkodOnDoldur != null) {
      _barkodCtl.text = widget.barkodOnDoldur!;
    }
  }

  @override
  void dispose() {
    for (final c in [_adCtl, _barkodCtl, _skuCtl, _fiyatCtl, _alisCtl, _kdvCtl, _stokCtl, _dusukCtl, _kritikCtl, _aciklamaCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_adCtl.text.trim().isEmpty || _fiyatCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün adı ve satış fiyatı zorunlu')));
      return;
    }
    setState(() => _kaydediliyor = true);
    try {
      await StokApi.urunKaydet(widget.salonId, {
        'id': widget.mevcut?.id ?? '0',
        'urun_adi': _adCtl.text.trim(),
        'barkod': _barkodCtl.text.trim(),
        'sku': _skuCtl.text.trim(),
        'fiyat': _fiyatCtl.text.trim(),
        'alis_fiyati': _alisCtl.text.trim(),
        'kdv_orani': _kdvCtl.text.trim(),
        'birim': _birim,
        'tip': _tip,
        'kategori_id': _kategoriId ?? '',
        'tedarikci_id': _tedarikciId ?? '',
        'stok_adedi': _stokCtl.text.trim(),
        'dusuk_stok_siniri': _dusukCtl.text.trim(),
        'kritik_stok_siniri': _kritikCtl.text.trim(),
        'aciklama': _aciklamaCtl.text.trim(),
        'kullanici_tipi': 'isletme_yonetim',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_duzenleme ? 'Güncellendi' : 'Ürün eklendi'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  Future<void> _barkodTara() async {
    final kod = await BarkodTarayici.tekSeferTara(context);
    if (kod != null) _barkodCtl.text = kod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: Text(_duzenleme ? 'Ürün Düzenle' : 'Yeni Ürün', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _bolum('Temel Bilgiler', [
              _alan('Ürün Adı *', _adCtl),
              const SizedBox(height: 10),
              _segmentTip(),
              const SizedBox(height: 10),
              _dropdown<String?>('Kategori', _kategoriId,
                  <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(value: null, child: Text('— Seç —')),
                    ...widget.kategoriler.map((k) => DropdownMenuItem<String?>(value: k.id, child: Text(k.ad))),
                  ],
                  (v) => setState(() => _kategoriId = v)),
              const SizedBox(height: 10),
              _dropdown<String?>('Tedarikçi', _tedarikciId,
                  <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(value: null, child: Text('— Seç —')),
                    ...widget.tedarikciler.map((t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.ad))),
                  ],
                  (v) => setState(() => _tedarikciId = v)),
            ]),
            _bolum('Fiyatlar', [
              Row(children: [
                Expanded(child: _alan('Alış (₺)', _alisCtl, sayisal: true)),
                const SizedBox(width: 10),
                Expanded(child: _alan('Satış (₺) *', _fiyatCtl, sayisal: true)),
                const SizedBox(width: 10),
                Expanded(child: _alan('KDV %', _kdvCtl, sayisal: true)),
              ]),
            ]),
            _bolum('Stok', [
              Row(children: [
                Expanded(child: _dropdown<String>('Birim', _birim, _birimItems(), (v) => setState(() => _birim = v ?? 'adet'))),
                const SizedBox(width: 10),
                Expanded(child: _alan('Başlangıç Stoğu', _stokCtl, sayisal: true)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _alan('Düşük Stok Sınırı', _dusukCtl, sayisal: true)),
                const SizedBox(width: 10),
                Expanded(child: _alan('Kritik Stok Sınırı', _kritikCtl, sayisal: true)),
              ]),
            ]),
            _bolum('Tanımlayıcı', [
              Row(children: [
                Expanded(
                  child: _alan('Barkod', _barkodCtl),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(color: _mor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: IconButton(icon: const Icon(Icons.qr_code_scanner, color: _mor), onPressed: _barkodTara),
                ),
              ]),
              const SizedBox(height: 10),
              _alan('SKU (opsiyonel)', _skuCtl),
              const SizedBox(height: 10),
              _alan('Açıklama', _aciklamaCtl, satir: 3),
            ]),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _kaydediliyor ? null : _kaydet,
              icon: _kaydediliyor
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_duzenleme ? 'Güncelle' : 'Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _mor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET YARDIMCILARI
  // ============================================================

  Widget _bolum(String baslik, List<Widget> cocuklar) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: const TextStyle(fontWeight: FontWeight.w800, color: _mor, fontSize: 13, letterSpacing: 0.3)),
          const SizedBox(height: 10),
          ...cocuklar,
        ],
      ),
    );
  }

  Widget _alan(String etiket, TextEditingController c, {bool sayisal = false, int satir = 1}) {
    return TextField(
      controller: c,
      maxLines: satir,
      keyboardType: sayisal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: etiket,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _mor, width: 1.5)),
      ),
    );
  }

  Widget _dropdown<T>(String etiket, T? secili, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: etiket,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _mor, width: 1.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: secili,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _segmentTip() {
    Widget seg(String deger, String etiket) {
      final secili = _tip == deger;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tip = deger),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: secili ? _mor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(etiket, textAlign: TextAlign.center, style: TextStyle(color: secili ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        seg('satis', 'Satış'),
        seg('sarf',  'Sarf'),
        seg('karma', 'Karma'),
      ]),
    );
  }

  static List<DropdownMenuItem<String>> _birimItems() => const [
        DropdownMenuItem(value: 'adet',  child: Text('Adet')),
        DropdownMenuItem(value: 'gr',    child: Text('Gram (gr)')),
        DropdownMenuItem(value: 'kg',    child: Text('Kilogram (kg)')),
        DropdownMenuItem(value: 'ml',    child: Text('Mililitre (ml)')),
        DropdownMenuItem(value: 'lt',    child: Text('Litre (lt)')),
        DropdownMenuItem(value: 'paket', child: Text('Paket')),
      ];
}
