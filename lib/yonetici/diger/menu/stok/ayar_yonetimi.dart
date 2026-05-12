import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/depo.dart';
import 'package:randevu_sistem/Models/tedarikci.dart';
import 'package:randevu_sistem/Models/urun_kategorisi.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/services/stok_api.dart';

/// Stok ayarları — tab'lı: Kategoriler / Depolar / Tedarikçiler / Transfer.
class AyarYonetimi extends StatefulWidget {
  final String salonId;
  const AyarYonetimi({Key? key, required this.salonId}) : super(key: key);

  @override
  State<AyarYonetimi> createState() => _AyarYonetimiState();
}

class _AyarYonetimiState extends State<AyarYonetimi> with SingleTickerProviderStateMixin {
  static const Color _mor = Color(0xFF6A1B9A);
  static const Color _kirmizi = Color(0xFFE53935);
  static const Color _yesil = Color(0xFF43A047);

  late TabController _tabCtl;

  List<UrunKategorisi> _kategoriler = [];
  List<Depo> _depolar = [];
  List<Tedarikci> _tedarikciler = [];
  List<Urun> _urunler = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
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
        StokApi.kategoriListesi(widget.salonId),
        StokApi.depoListesi(widget.salonId),
        StokApi.tedarikciListesi(widget.salonId),
        StokApi.urunListesi(widget.salonId),
      ]);
      _kategoriler  = (results[0] as List).cast<UrunKategorisi>();
      _depolar      = (results[1] as List).cast<Depo>();
      _tedarikciler = (results[2] as List).cast<Tedarikci>();
      _urunler      = (results[3] as List).cast<Urun>();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: const Text('Stok Ayarları', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabCtl,
          labelColor: _mor,
          unselectedLabelColor: Colors.black54,
          indicatorColor: _mor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Kategoriler'),
            Tab(text: 'Depolar'),
            Tab(text: 'Tedarikçiler'),
            Tab(text: 'Transfer'),
          ],
        ),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: _mor))
          : TabBarView(
              controller: _tabCtl,
              children: [
                _kategoriTab(),
                _depoTab(),
                _tedarikciTab(),
                _transferTab(),
              ],
            ),
    );
  }

  // ============================================================
  // KATEGORİ
  // ============================================================

  Widget _kategoriTab() {
    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ..._kategoriler.map((k) {
            final renk = _hexToColor(k.renk) ?? _mor;
            return _satirKart(
              ikon: Icon(Icons.circle, color: renk, size: 14),
              baslik: k.ad,
              onDuzenle: () => _kategoriDuzenle(k),
              onSil: () async {
                if (await _onay('Kategoriyi sil?')) {
                  await StokApi.kategoriSil(k.id);
                  _yukle();
                }
              },
            );
          }),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _kategoriDuzenle(null),
            icon: const Icon(Icons.add),
            label: const Text('Kategori Ekle'),
            style: OutlinedButton.styleFrom(foregroundColor: _mor, side: const BorderSide(color: _mor), padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _kategoriDuzenle(UrunKategorisi? k) async {
    final adCtl = TextEditingController(text: k?.ad ?? '');
    Color secilenRenk = _hexToColor(k?.renk ?? '') ?? _mor;
    final tamam = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          title: Text(k == null ? 'Yeni Kategori' : 'Kategori Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: adCtl, decoration: const InputDecoration(labelText: 'Ad')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _hazirRenkler.map((r) {
                  final secili = r.value == secilenRenk.value;
                  return InkWell(
                    onTap: () => setSt(() => secilenRenk = r),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: r, shape: BoxShape.circle, border: Border.all(color: secili ? Colors.black : Colors.transparent, width: 2)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text('Kaydet')),
          ],
        );
      }),
    );
    if (tamam == true) {
      await StokApi.kategoriKaydet(widget.salonId, {
        if (k != null) 'id': k.id,
        'ad': adCtl.text.trim(),
        'renk': '#${secilenRenk.value.toRadixString(16).substring(2)}',
      });
      _yukle();
    }
  }

  // ============================================================
  // DEPO
  // ============================================================

  Widget _depoTab() {
    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ..._depolar.map((d) => _satirKart(
                ikon: const Icon(Icons.warehouse_outlined, color: _mor),
                baslik: d.depo_adi,
                altYazi: d.varsayilan
                    ? '✓ Varsayılan — Toplam: ${d.toplam_stok}'
                    : 'Toplam: ${d.toplam_stok}',
                onDuzenle: () => _depoDuzenle(d),
                onSil: d.varsayilan ? null : () async {
                  if (await _onay('Depoyu sil?')) {
                    final r = await StokApi.depoSil(d.id);
                    if (r['mesaj'] != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['mesaj'].toString()), backgroundColor: _kirmizi));
                    }
                    _yukle();
                  }
                },
              )),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _depoDuzenle(null),
            icon: const Icon(Icons.add),
            label: const Text('Depo Ekle'),
            style: OutlinedButton.styleFrom(foregroundColor: _mor, side: const BorderSide(color: _mor), padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _depoDuzenle(Depo? d) async {
    final adCtl = TextEditingController(text: d?.depo_adi ?? '');
    final aciklamaCtl = TextEditingController(text: d?.aciklama ?? '');
    bool varsayilan = d?.varsayilan ?? false;
    final tamam = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          title: Text(d == null ? 'Yeni Depo' : 'Depo Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: adCtl, decoration: const InputDecoration(labelText: 'Depo Adı')),
              const SizedBox(height: 8),
              TextField(controller: aciklamaCtl, decoration: const InputDecoration(labelText: 'Açıklama')),
              const SizedBox(height: 8),
              SwitchListTile(
                value: varsayilan,
                title: const Text('Varsayılan depo'),
                onChanged: (v) => setSt(() => varsayilan = v),
                contentPadding: EdgeInsets.zero,
                activeColor: _mor,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text('Kaydet')),
          ],
        );
      }),
    );
    if (tamam == true) {
      await StokApi.depoKaydet(widget.salonId, {
        if (d != null) 'id': d.id,
        'depo_adi': adCtl.text.trim(),
        'aciklama': aciklamaCtl.text,
        'varsayilan': varsayilan ? 1 : 0,
      });
      _yukle();
    }
  }

  // ============================================================
  // TEDARİKÇİ
  // ============================================================

  Widget _tedarikciTab() {
    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ..._tedarikciler.map((t) => _satirKart(
                ikon: const Icon(Icons.local_shipping_outlined, color: _mor),
                baslik: t.ad,
                altYazi: t.telefon.isEmpty ? null : t.telefon,
                onDuzenle: () => _tedarikciDuzenle(t),
                onSil: () async {
                  if (await _onay('Tedarikçiyi sil?')) {
                    await StokApi.tedarikciSil(t.id);
                    _yukle();
                  }
                },
              )),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _tedarikciDuzenle(null),
            icon: const Icon(Icons.add),
            label: const Text('Tedarikçi Ekle'),
            style: OutlinedButton.styleFrom(foregroundColor: _mor, side: const BorderSide(color: _mor), padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _tedarikciDuzenle(Tedarikci? t) async {
    final adCtl = TextEditingController(text: t?.ad ?? '');
    final telCtl = TextEditingController(text: t?.telefon ?? '');
    final vergiCtl = TextEditingController(text: t?.vergi_no ?? '');
    final emailCtl = TextEditingController(text: t?.email ?? '');
    final adresCtl = TextEditingController(text: t?.adres ?? '');
    final tamam = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t == null ? 'Yeni Tedarikçi' : 'Tedarikçi Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: adCtl, decoration: const InputDecoration(labelText: 'Ad')),
              TextField(controller: telCtl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon')),
              TextField(controller: vergiCtl, decoration: const InputDecoration(labelText: 'Vergi No')),
              TextField(controller: emailCtl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta')),
              TextField(controller: adresCtl, maxLines: 2, decoration: const InputDecoration(labelText: 'Adres')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text('Kaydet')),
        ],
      ),
    );
    if (tamam == true) {
      await StokApi.tedarikciKaydet(widget.salonId, {
        if (t != null) 'id': t.id,
        'ad': adCtl.text.trim(),
        'telefon': telCtl.text,
        'vergi_no': vergiCtl.text,
        'email': emailCtl.text,
        'adres': adresCtl.text,
      });
      _yukle();
    }
  }

  // ============================================================
  // TRANSFER
  // ============================================================

  String? _trfUrunId;
  String? _trfKaynakDepo;
  String? _trfHedefDepo;
  final TextEditingController _trfMiktarCtl = TextEditingController();
  bool _trfGondermeli = false;

  Widget _transferTab() {
    if (_depolar.length < 2) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Transfer için en az 2 depo gerekli', textAlign: TextAlign.center)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _dropdown<String>('Ürün', _trfUrunId,
              _urunler.map((u) => DropdownMenuItem<String>(value: u.id, child: Text(u.urun_adi))).toList(),
              (v) => setState(() => _trfUrunId = v)),
          const SizedBox(height: 10),
          _dropdown<String>('Kaynak Depo', _trfKaynakDepo,
              _depolar.map((d) => DropdownMenuItem<String>(value: d.id, child: Text(d.depo_adi))).toList(),
              (v) => setState(() => _trfKaynakDepo = v)),
          const SizedBox(height: 10),
          _dropdown<String>('Hedef Depo', _trfHedefDepo,
              _depolar.map((d) => DropdownMenuItem<String>(value: d.id, child: Text(d.depo_adi))).toList(),
              (v) => setState(() => _trfHedefDepo = v)),
          const SizedBox(height: 10),
          TextField(
            controller: _trfMiktarCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Miktar',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _trfGondermeli ? null : () async {
                if (_trfUrunId == null || _trfKaynakDepo == null || _trfHedefDepo == null) return;
                final miktar = double.tryParse(_trfMiktarCtl.text.replaceAll(',', '.')) ?? 0;
                if (miktar <= 0) return;
                setState(() => _trfGondermeli = true);
                try {
                  final r = await StokApi.transfer(widget.salonId, {
                    'urun_id': _trfUrunId,
                    'kaynak_depo_id': _trfKaynakDepo,
                    'hedef_depo_id': _trfHedefDepo,
                    'miktar': miktar,
                    'kullanici_tipi': 'isletme_yonetim',
                  });
                  if (!mounted) return;
                  if (r['status'] == 'ok') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer tamam'), backgroundColor: _yesil));
                    _trfMiktarCtl.clear();
                    _yukle();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['mesaj']?.toString() ?? 'Hata'), backgroundColor: _kirmizi));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _kirmizi));
                } finally {
                  if (mounted) setState(() => _trfGondermeli = false);
                }
              },
              icon: _trfGondermeli
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.swap_horiz),
              label: const Text('Transfer Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _mor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // YARDIMCILAR
  // ============================================================

  Widget _satirKart({required Widget ikon, required String baslik, String? altYazi, VoidCallback? onDuzenle, VoidCallback? onSil}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          ikon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (altYazi != null) Text(altYazi, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          if (onDuzenle != null) IconButton(icon: const Icon(Icons.edit, color: _mor, size: 20), onPressed: onDuzenle),
          if (onSil != null)     IconButton(icon: const Icon(Icons.delete_outline, color: _kirmizi, size: 20), onPressed: onSil),
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
        child: DropdownButton<T>(value: secili, isExpanded: true, items: items, onChanged: onChanged),
      ),
    );
  }

  Future<bool> _onay(String soru) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(soru),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Evet')),
        ],
      ),
    );
    return ok ?? false;
  }

  static Color? _hexToColor(String hex) {
    if (hex.isEmpty) return null;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    if (v == null) return null;
    return Color(v);
  }

  static const List<Color> _hazirRenkler = [
    Color(0xFF6A1B9A), Color(0xFF1565C0), Color(0xFF2E7D32),
    Color(0xFFEF6C00), Color(0xFFC62828), Color(0xFF00838F),
    Color(0xFF558B2F), Color(0xFFAD1457), Color(0xFF5D4037),
  ];
}
