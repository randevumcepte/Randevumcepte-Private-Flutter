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
    // Alış/satış değiştiğinde canlı kâr göstergesi için rebuild tetikle
    _alisCtl.addListener(() => setState(() {}));
    _fiyatCtl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_adCtl, _barkodCtl, _skuCtl, _fiyatCtl, _alisCtl, _kdvCtl, _stokCtl, _dusukCtl, _kritikCtl, _aciklamaCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_adCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün adı zorunlu')));
      return;
    }
    if (_alisCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alış fiyatı zorunlu — maliyet hesabı için gerekli')));
      return;
    }
    // Satış fiyatı sadece satılan tiplerde zorunlu
    if (_tip != 'sarf' && _fiyatCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Satış fiyatı zorunlu (bu ürün satılıyor)')));
      return;
    }
    // Sarf ürünlerde satış fiyatı = alış fiyatı (gelir hesabına yansımaz, sadece muhasebe için)
    if (_tip == 'sarf' && _fiyatCtl.text.trim().isEmpty) {
      _fiyatCtl.text = _alisCtl.text;
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
            _bolum(
              _tip == 'sarf' ? 'Maliyet (Alış)' : 'Fiyatlar',
              [
                // Alış her zaman zorunlu — maliyet için
                Row(children: [
                  Expanded(
                    flex: _tip == 'sarf' ? 2 : 1,
                    child: _alan('Alış Fiyatı (₺) *', _alisCtl, sayisal: true),
                  ),
                  if (_tip != 'sarf') ...[
                    const SizedBox(width: 10),
                    Expanded(child: _alan('Satış (₺) *', _fiyatCtl, sayisal: true)),
                  ],
                  const SizedBox(width: 10),
                  Expanded(child: _alan('KDV %', _kdvCtl, sayisal: true)),
                ]),
                const SizedBox(height: 10),
                // Tip'e göre bilgilendirme bandı
                _fiyatBilgilendirmeBandi(),
                // Karma/Satış ürünleri için anlık kâr göstergesi
                if (_tip != 'sarf') _karPreview(),
              ],
            ),
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

  /// Tip'e göre kullanıcıya açıklayıcı bilgilendirme bandı.
  Widget _fiyatBilgilendirmeBandi() {
    String mesaj;
    IconData ikon;
    Color renk;
    switch (_tip) {
      case 'sarf':
        mesaj = 'Sarf ürünleri müşteriye satılmaz, hizmette tüketilir. Sadece alış fiyatı maliyet olarak yansır.';
        ikon = Icons.science_outlined;
        renk = const Color(0xFFAD1457);
        break;
      case 'karma':
        mesaj = 'Hem satışa hem sarfa konabilir. Satılınca satış fiyatından, sarf edilince alış fiyatından düşülür.';
        ikon = Icons.swap_horiz;
        renk = _mor;
        break;
      default:
        mesaj = 'Müşteriye satış için. Alış fiyatının 2-3 katı tipik kâr marjıdır.';
        ikon = Icons.point_of_sale_outlined;
        renk = const Color(0xFF1565C0);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: renk.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: renk, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(mesaj, style: TextStyle(color: renk, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4))),
        ],
      ),
    );
  }

  /// Canlı kâr/marj göstergesi — alış+satış girildiğinde gösterilir.
  Widget _karPreview() {
    final alis = double.tryParse(_alisCtl.text.replaceAll(',', '.')) ?? 0;
    final satis = double.tryParse(_fiyatCtl.text.replaceAll(',', '.')) ?? 0;
    if (alis <= 0 || satis <= 0) return const SizedBox.shrink();
    final kar = satis - alis;
    final marj = (kar / satis) * 100;
    final yesil = const Color(0xFF43A047);
    final kirmizi = const Color(0xFFE53935);
    final pozitif = kar >= 0;
    final marjRenk = marj >= 50 ? yesil : (marj >= 20 ? const Color(0xFFF6A609) : kirmizi);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: pozitif ? [yesil, const Color(0xFF66BB6A)] : [kirmizi, const Color(0xFFEF5350)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: (pozitif ? yesil : kirmizi).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(pozitif ? Icons.trending_up : Icons.trending_down, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BİRİM BAŞINA KÂR', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text('₺${kar.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text('%${marj.toStringAsFixed(0)}', style: TextStyle(color: marjRenk, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

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
