import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';
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
  static const Color _morSoft = Color(0xFFF3E8FA);
  static const Color _kirmizi = Color(0xFFE53935);
  static const Color _yesil = Color(0xFF43A047);

  late TabController _tabCtl;

  List<UrunKategorisi> _kategoriler = [];
  List<Depo> _depolar = [];
  List<Tedarikci> _tedarikciler = [];
  List<Urun> _urunler = [];
  bool _yukleniyor = true;

  // 'urun.tedarikci_yonet' yetkisi yoksa Tedarikciler tab'i gizlenir;
  // TabController length de buna gore ayarlanir.
  late final bool _tedarikciGoster;

  @override
  void initState() {
    super.initState();
    _tedarikciGoster = Yetki.varMi('urun.tedarikci_yonet');
    _tabCtl = TabController(length: _tedarikciGoster ? 4 : 3, vsync: this);
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
          tabs: [
            const Tab(text: 'Kategoriler'),
            const Tab(text: 'Depolar'),
            if (_tedarikciGoster) const Tab(text: 'Tedarikçiler'),
            const Tab(text: 'Transfer'),
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
                if (_tedarikciGoster) _tedarikciTab(),
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
    final yeni = k == null;

    final ok = await _premiumDuzenleBottomSheet(
      baslik: yeni ? 'Yeni Kategori' : 'Kategori Düzenle',
      altBaslik: yeni ? 'Ürünleri gruplamak için kategori oluştur' : k.ad,
      ikon: Icons.local_offer_outlined,
      kaydetEtiket: yeni ? 'Kategori Ekle' : 'Değişiklikleri Kaydet',
      zorunluAlanKontrol: () => adCtl.text.trim().isEmpty ? 'Kategori adı zorunludur' : null,
      bolumler: [
        _BolumKayit('Kategori Bilgileri', Icons.label_important_outline, [
          _AlanKayit('Kategori Adı', adCtl, zorunlu: true, ipucu: 'örn. Şampuanlar, Boyalar...'),
        ]),
        _BolumKayit(
          'Renk Seç',
          Icons.palette_outlined,
          const [],
          ekstra: StatefulBuilder(builder: (ctx, setSt) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _hazirRenkler.map((r) {
                final secili = r.toARGB32() == secilenRenk.toARGB32();
                return InkWell(
                  onTap: () => setSt(() => secilenRenk = r),
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: r,
                      shape: BoxShape.circle,
                      border: Border.all(color: secili ? Colors.white : Colors.transparent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: secili ? r.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.08),
                          blurRadius: secili ? 10 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: secili ? const Icon(Icons.check, color: Colors.white, size: 22) : null,
                  ),
                );
              }).toList(),
            );
          }),
        ),
      ],
    );

    if (ok == true) {
      await StokApi.kategoriKaydet(widget.salonId, {
        if (k != null) 'id': k.id,
        'ad': adCtl.text.trim(),
        'renk': '#${secilenRenk.toARGB32().toRadixString(16).substring(2)}',
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
    final yeni = d == null;

    final ok = await _premiumDuzenleBottomSheet(
      baslik: yeni ? 'Yeni Depo' : 'Depo Düzenle',
      altBaslik: yeni ? 'Stoku tutacağın fiziksel lokasyon' : d.depo_adi,
      ikon: Icons.warehouse_outlined,
      kaydetEtiket: yeni ? 'Depo Ekle' : 'Değişiklikleri Kaydet',
      zorunluAlanKontrol: () => adCtl.text.trim().isEmpty ? 'Depo adı zorunludur' : null,
      bolumler: [
        _BolumKayit('Depo Bilgileri', Icons.info_outline, [
          _AlanKayit('Depo Adı', adCtl, zorunlu: true, ipucu: 'örn. Ana Depo, Salon Rafı'),
          _AlanKayit('Açıklama', aciklamaCtl, satir: 2, ipucu: 'Konum, açıklama vb. (opsiyonel)'),
        ]),
        _BolumKayit(
          'Ayarlar',
          Icons.tune,
          const [],
          ekstra: StatefulBuilder(builder: (ctx, setSt) {
            return Container(
              decoration: BoxDecoration(color: _morSoft, borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SwitchListTile(
                value: varsayilan,
                title: const Text('Varsayılan depo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Yeni ürünler bu depoda kaydedilir', style: TextStyle(fontSize: 11)),
                onChanged: (v) => setSt(() => varsayilan = v),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: _mor,
                dense: true,
              ),
            );
          }),
        ),
      ],
    );

    if (ok == true) {
      await StokApi.depoKaydet(widget.salonId, {
        if (d != null) 'id': d.id,
        'depo_adi': adCtl.text.trim(),
        'aciklama': aciklamaCtl.text.trim(),
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
    final yeni = t == null;

    final ok = await _premiumDuzenleBottomSheet(
      baslik: yeni ? 'Yeni Tedarikçi' : 'Tedarikçi Düzenle',
      altBaslik: yeni ? 'Bilgileri eksiksiz girmen tavsiye edilir' : t.ad,
      ikon: Icons.local_shipping_outlined,
      bolumler: [
        _BolumKayit('Temel Bilgiler', Icons.business_outlined, [
          _AlanKayit('Tedarikçi Adı', adCtl, zorunlu: true, ipucu: 'örn. ABC Kozmetik'),
        ]),
        _BolumKayit('İletişim', Icons.contact_mail_outlined, [
          _AlanKayit('Telefon', telCtl, klavye: TextInputType.phone, ipucu: '0532 123 45 67'),
          _AlanKayit('E-posta', emailCtl, klavye: TextInputType.emailAddress, ipucu: 'siparis@firma.com'),
        ]),
        _BolumKayit('Resmi Bilgiler', Icons.receipt_long_outlined, [
          _AlanKayit('Vergi No', vergiCtl, klavye: TextInputType.number, ipucu: '10 haneli'),
          _AlanKayit('Adres', adresCtl, satir: 3, ipucu: 'Tam adres'),
        ]),
      ],
      kaydetEtiket: yeni ? 'Tedarikçi Ekle' : 'Değişiklikleri Kaydet',
      zorunluAlanKontrol: () {
        if (adCtl.text.trim().isEmpty) return 'Tedarikçi adı zorunludur';
        return null;
      },
    );

    if (ok == true) {
      await StokApi.tedarikciKaydet(widget.salonId, {
        if (t != null) 'id': t.id,
        'ad': adCtl.text.trim(),
        'telefon': telCtl.text.trim(),
        'vergi_no': vergiCtl.text.trim(),
        'email': emailCtl.text.trim(),
        'adres': adresCtl.text.trim(),
      });
      _yukle();
    }
  }

  // ============================================================
  // ORTAK PREMIUM DÜZENLEME BOTTOM SHEET
  // ============================================================
  // Kategori, depo, tedarikçi gibi 'düzenle/ekle' diyaloglarının
  // tutarlı modern görünümü için ortak helper.

  Future<bool?> _premiumDuzenleBottomSheet({
    required String baslik,
    String? altBaslik,
    required IconData ikon,
    required List<_BolumKayit> bolumler,
    required String kaydetEtiket,
    String? Function()? zorunluAlanKontrol,
  }) {
    String? hata;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtl) => Container(
              decoration: const BoxDecoration(color: Color(0xFFF7F7FB), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(
                children: [
                  // === Header ===
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [_mor, Color(0xFF8E24AA)]),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Container(width: 38, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                              child: Icon(ikon, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(baslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                                  if (altBaslik != null && altBaslik.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(altBaslik, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx, false)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // === Hata bandı ===
                  if (hata != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: _kirmizi.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: _kirmizi, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(hata!, style: const TextStyle(color: _kirmizi, fontWeight: FontWeight.w600, fontSize: 13))),
                        ],
                      ),
                    ),
                  // === Form alanları (bölümler) ===
                  Expanded(
                    child: ListView(
                      controller: scrollCtl,
                      padding: const EdgeInsets.all(16),
                      children: bolumler.map((b) => _bolumKarti(b)).toList(),
                    ),
                  ),
                  // === Footer ===
                  Container(
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))]),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Colors.black26), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Vazgeç', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (zorunluAlanKontrol != null) {
                                final h = zorunluAlanKontrol();
                                if (h != null) {
                                  setSt(() => hata = h);
                                  return;
                                }
                              }
                              Navigator.pop(ctx, true);
                            },
                            icon: const Icon(Icons.check),
                            label: Text(kaydetEtiket),
                            style: ElevatedButton.styleFrom(backgroundColor: _mor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _bolumKarti(_BolumKayit b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(b.ikon, color: _mor, size: 16),
              const SizedBox(width: 8),
              Text(
                b.baslik.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: _mor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...b.alanlar.expand((a) sync* {
            yield _alanKart(a);
            yield const SizedBox(height: 10);
          }),
          if (b.ekstra != null) b.ekstra!,
        ],
      ),
    );
  }

  Widget _alanKart(_AlanKayit a) {
    return TextField(
      controller: a.ctl,
      keyboardType: a.klavye ?? TextInputType.text,
      maxLines: a.satir,
      decoration: InputDecoration(
        labelText: a.zorunlu ? '${a.label} *' : a.label,
        labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13),
        hintText: a.ipucu,
        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _mor, width: 1.5)),
      ),
    );
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
        child: AramaliDropdown<T>(value: secili, isExpanded: true, items: items, onChanged: onChanged),
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

/// Premium düzenleme bottom sheet'i için form bölümü tanımı.
class _BolumKayit {
  final String baslik;
  final IconData ikon;
  final List<_AlanKayit> alanlar;
  /// Standart form alanlarının altına eklenecek özel widget (renk seçici, switch vb.).
  final Widget? ekstra;
  const _BolumKayit(this.baslik, this.ikon, this.alanlar, {this.ekstra});
}

/// Premium düzenleme bottom sheet'i için tek bir input alanı.
class _AlanKayit {
  final String label;
  final TextEditingController ctl;
  final bool zorunlu;
  final String? ipucu;
  final TextInputType? klavye;
  final int satir;
  const _AlanKayit(
    this.label,
    this.ctl, {
    this.zorunlu = false,
    this.ipucu,
    this.klavye,
    this.satir = 1,
  });
}
