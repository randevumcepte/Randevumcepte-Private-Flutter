import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/depo.dart';
import 'package:randevu_sistem/Models/tedarikci.dart';
import 'package:randevu_sistem/Models/urun_kategorisi.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/services/birim_helper.dart';
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
  List<Map<String, dynamic>> _hizmetler = [];
  List<Map<String, dynamic>> _receteler = [];
  String? _seciliHizmetId;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _tabCtl = TabController(length: 5, vsync: this);
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
        StokApi.hizmetListesi(widget.salonId),
      ]);
      _kategoriler  = (results[0] as List).cast<UrunKategorisi>();
      _depolar      = (results[1] as List).cast<Depo>();
      _tedarikciler = (results[2] as List).cast<Tedarikci>();
      _urunler      = (results[3] as List).cast<Urun>();
      _hizmetler    = (results[4] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _receteleriYukle() async {
    if (_seciliHizmetId == null) {
      setState(() => _receteler = []);
      return;
    }
    try {
      final list = await StokApi.receteListesi(widget.salonId, hizmetId: _seciliHizmetId, hizmetTipi: 'islem');
      if (mounted) setState(() => _receteler = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
            Tab(text: 'Sarf Reçeteleri'),
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
                _receteTab(),
              ],
            ),
    );
  }

  // ============================================================
  // SARF REÇETELERİ
  // ============================================================

  Widget _receteTab() {
    if (_hizmetler.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.spa_outlined, size: 64, color: Colors.black.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              const Text('Henüz hizmet tanımlı değil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text('Önce sistem hizmetlerini ekle', textAlign: TextAlign.center, style: TextStyle(color: Colors.black.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
    }

    final seciliHizmet = _seciliHizmetId == null
        ? null
        : _hizmetler.firstWhere(
            (h) => h['id']?.toString() == _seciliHizmetId,
            orElse: () => <String, dynamic>{},
          );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // === Bilgilendirme kartı ===
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_mor, Color(0xFF8E24AA)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Otomatik Sarf Düşümü', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    SizedBox(height: 4),
                    Text(
                      'Bir hizmete reçete tanımlarsın → o hizmet adisyona eklendiğinde malzemeler stoktan otomatik düşer.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // === Hizmet seçici kart ===
        _hizmetSeciciKart(seciliHizmet),
        const SizedBox(height: 12),

        // === Reçete listesi veya boş durum ===
        if (_seciliHizmetId == null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Icon(Icons.arrow_upward, color: _mor.withValues(alpha: 0.5), size: 28),
                const SizedBox(height: 8),
                Text('Önce yukarıdan bir hizmet seç', textAlign: TextAlign.center, style: TextStyle(color: Colors.black.withValues(alpha: 0.5))),
              ],
            ),
          )
        else
          _receteIcerikleri(),
      ],
    );
  }

  Widget _hizmetSeciciKart(Map<String, dynamic>? seciliHizmet) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _hizmetSecBottomSheet,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _seciliHizmetId == null ? Colors.black12 : _mor.withValues(alpha: 0.3), width: _seciliHizmetId == null ? 1 : 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: _morSoft, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.spa_outlined, color: _mor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HİZMET', style: TextStyle(fontSize: 10, color: Colors.black45, letterSpacing: 0.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      seciliHizmet == null || seciliHizmet.isEmpty
                          ? 'Hizmet seçmek için dokun'
                          : (seciliHizmet['hizmet_adi']?.toString() ?? '—'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: seciliHizmet == null || seciliHizmet.isEmpty ? Colors.black54 : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(_seciliHizmetId == null ? Icons.touch_app_outlined : Icons.swap_horiz, color: _mor),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _hizmetSecBottomSheet() async {
    final aramaCtl = TextEditingController();
    String arama = '';
    final secilen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        final filtre = arama.isEmpty
            ? _hizmetler
            : _hizmetler.where((h) => (h['hizmet_adi']?.toString().toLowerCase() ?? '').contains(arama.toLowerCase())).toList();
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtl) => Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_mor, Color(0xFF8E24AA)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(width: 38, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                      Row(
                        children: [
                          const Icon(Icons.spa_outlined, color: Colors.white),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Hizmet Seç', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17))),
                          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: aramaCtl,
                        onChanged: (v) => setSt(() => arama = v),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Hizmet ara...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                          prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtre.isEmpty
                      ? Center(child: Text('Sonuç bulunamadı', style: TextStyle(color: Colors.black.withValues(alpha: 0.5))))
                      : ListView.separated(
                          controller: scrollCtl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtre.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final h = filtre[i];
                            final id = h['id']?.toString();
                            final ad = h['hizmet_adi']?.toString() ?? '—';
                            final secili = _seciliHizmetId == id;
                            return ListTile(
                              leading: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: secili ? _mor : _morSoft, shape: BoxShape.circle),
                                child: Icon(Icons.spa_outlined, color: secili ? Colors.white : _mor, size: 18),
                              ),
                              title: Text(ad, style: TextStyle(fontWeight: FontWeight.w700, color: secili ? _mor : Colors.black87)),
                              trailing: secili ? const Icon(Icons.check_circle, color: _mor) : null,
                              onTap: () => Navigator.pop(ctx, id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      }),
    );
    if (secilen != null) {
      setState(() => _seciliHizmetId = secilen);
      await _receteleriYukle();
    }
  }

  Widget _receteIcerikleri() {
    if (_receteler.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: _morSoft, shape: BoxShape.circle),
              child: const Icon(Icons.science_outlined, color: _mor, size: 32),
            ),
            const SizedBox(height: 12),
            const Text('Henüz reçete yok', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Bu hizmet için ilk malzemeyi ekleyerek\nbaşlayabilirsin',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.5), height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _receteUrunSec,
                icon: const Icon(Icons.add),
                label: const Text('İlk Malzemeyi Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'BU HİZMETE BAĞLI ${_receteler.length} MALZEME',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        ..._receteler.map((r) {
          final urunAdi = r['urun'] is Map ? (r['urun']['urun_adi']?.toString() ?? '—') : '—';
          final birim = r['urun'] is Map ? (r['urun']['birim']?.toString() ?? 'adet') : '';
          final tip = r['urun'] is Map ? (r['urun']['tip']?.toString() ?? 'sarf') : 'sarf';
          final miktar = double.tryParse(r['miktar']?.toString() ?? '0') ?? 0;
          final rid = r['id'].toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: tip == 'karma' ? _morSoft : const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    tip == 'karma' ? Icons.swap_horiz : Icons.local_florist_outlined,
                    color: tip == 'karma' ? _mor : const Color(0xFFAD1457),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(urunAdi, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _morSoft, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              'Her hizmette ${_miktarFmt(miktar)} $birim',
                              style: const TextStyle(color: _mor, fontWeight: FontWeight.w700, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: _mor),
                  tooltip: 'Miktarı düzenle',
                  onPressed: () => _receteMiktarDuzenle(r),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: _kirmizi),
                  tooltip: 'Çıkar',
                  onPressed: () async {
                    if (await _onay('"$urunAdi" reçeteden çıkarılsın mı?')) {
                      await StokApi.receteSil(rid);
                      _receteleriYukle();
                    }
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _receteUrunSec,
          icon: const Icon(Icons.add),
          label: const Text('Yeni Malzeme Ekle'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _mor,
            side: const BorderSide(color: _mor, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _receteUrunSec() async {
    if (_seciliHizmetId == null) return;
    final mevcutIdler = _receteler
        .map((r) => (r['urun_id'] ?? (r['urun'] is Map ? r['urun']['id'] : null))?.toString())
        .whereType<String>()
        .toSet();
    final sarfOnerilen = _urunler.where((u) => (u.tip == 'sarf' || u.tip == 'karma') && !mevcutIdler.contains(u.id)).toList();
    final digerleri = _urunler.where((u) => u.tip != 'sarf' && u.tip != 'karma' && !mevcutIdler.contains(u.id)).toList();

    final aramaCtl = TextEditingController();
    String arama = '';

    final secilen = await showModalBottomSheet<Urun>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        List<Urun> filtre(List<Urun> liste) => arama.isEmpty
            ? liste
            : liste.where((u) => u.urun_adi.toLowerCase().contains(arama.toLowerCase()) || u.barkod.contains(arama)).toList();
        final s = filtre(sarfOnerilen);
        final d = filtre(digerleri);
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtl) => Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_mor, Color(0xFF8E24AA)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(width: 38, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                      Row(
                        children: [
                          const Icon(Icons.science_outlined, color: Colors.white),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Malzeme Seç', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17))),
                          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: aramaCtl,
                        onChanged: (v) => setSt(() => arama = v),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ürün ara...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                          prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: (s.isEmpty && d.isEmpty)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.black.withValues(alpha: 0.2)),
                                const SizedBox(height: 10),
                                Text(
                                  arama.isEmpty ? 'Eklenebilecek başka ürün yok' : 'Sonuç bulunamadı',
                                  style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          controller: scrollCtl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            if (s.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text('ÖNERİLEN (SARF / KARMA)', style: TextStyle(fontSize: 10, color: Colors.black.withValues(alpha: 0.5), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              ),
                              ...s.map((u) => _urunSecimSatiri(ctx, u)),
                            ],
                            if (d.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                                child: Text('DİĞER ÜRÜNLER', style: TextStyle(fontSize: 10, color: Colors.black.withValues(alpha: 0.5), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              ),
                              ...d.map((u) => _urunSecimSatiri(ctx, u)),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (secilen != null) {
      await _receteMiktarGir(secilen);
    }
  }

  Widget _urunSecimSatiri(BuildContext ctx, Urun u) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: u.tip == 'karma' ? _morSoft : (u.tip == 'sarf' ? const Color(0xFFFCE4EC) : const Color(0xFFE3F2FD)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          u.tip == 'karma' ? Icons.swap_horiz : (u.tip == 'sarf' ? Icons.local_florist_outlined : Icons.inventory_2_outlined),
          color: u.tip == 'karma' ? _mor : (u.tip == 'sarf' ? const Color(0xFFAD1457) : const Color(0xFF1565C0)),
          size: 18,
        ),
      ),
      title: Text(u.urun_adi, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text('${u.birim} · stok: ${u.stok_adedi}', style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.add_circle_outline, color: _mor),
      onTap: () => Navigator.pop(ctx, u),
    );
  }

  Future<void> _receteMiktarGir(Urun urun, {double? mevcutMiktar}) async {
    final birim = urun.birim;
    final stepperArtis = BirimHelper.stepperArtis(birim);
    final hizliSecimler = BirimHelper.hizliSecim(birim);
    double miktar = mevcutMiktar ?? BirimHelper.varsayilanBaslangic(birim);
    final miktarCtl = TextEditingController(text: BirimHelper.sayi(miktar, birim));

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        void degistir(double yeniMiktar) {
          if (yeniMiktar < 0) yeniMiktar = 0;
          setSt(() {
            miktar = yeniMiktar;
            miktarCtl.text = BirimHelper.sayi(yeniMiktar, birim);
          });
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // === Header ===
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.science_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(urun.urun_adi, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(
                                  'Mevcut stok: ${BirimHelper.formatla(urun.stokSayisal, birim)}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
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
                // === Gövde ===
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Açıklama satırı (birime göre dinamik)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: _morSoft, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Text(BirimHelper.ikon(birim), style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bu hizmet için kaç ${BirimHelper.uzunAd(birim).toLowerCase()} ($birim) kullanılır?',
                                    style: const TextStyle(color: _mor, fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _birimOrnekMetni(birim),
                                    style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // === Büyük Stepper ===
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _miktarBtn(Icons.remove, () => degistir(miktar - stepperArtis), '-${BirimHelper.sayi(stepperArtis, birim)}'),
                          const SizedBox(width: 12),
                          Container(
                            width: 170,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(color: _morSoft, borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: TextField(
                                    controller: miktarCtl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _mor),
                                    decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
                                    onChanged: (v) => miktar = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(birim, style: const TextStyle(fontSize: 14, color: _mor, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _miktarBtn(Icons.add, () => degistir(miktar + stepperArtis), '+${BirimHelper.sayi(stepperArtis, birim)}'),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // === Hızlı seçim chip'leri (birime göre akıllı) ===
                      Text(
                        'HIZLI SEÇİM',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.black.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: hizliSecimler
                            .map((v) => _hizliMiktarChip(
                                  BirimHelper.formatla(v.toDouble(), birim),
                                  miktar == v.toDouble(),
                                  () => degistir(v.toDouble()),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // === Aksiyon butonları ===
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Colors.black26),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Vazgeç', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                miktar = double.tryParse(miktarCtl.text.replaceAll(',', '.')) ?? 0;
                                if (miktar <= 0) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Miktar 0'dan büyük olmalı")));
                                  return;
                                }
                                Navigator.pop(ctx, true);
                              },
                              icon: const Icon(Icons.check),
                              label: Text(mevcutMiktar != null ? 'Güncelle' : 'Reçeteye Ekle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (ok == true && miktar > 0) {
      await StokApi.receteKaydet(widget.salonId, {
        'hizmet_id': _seciliHizmetId,
        'hizmet_tipi': 'islem',
        'urun_id': urun.id,
        'miktar': miktar,
      });
      _receteleriYukle();
    }
  }

  /// Birim için gerçek dünya örneği (kullanıcıya yardım metni)
  static String _birimOrnekMetni(String birim) {
    switch (BirimHelper.tip(birim)) {
      case 'kucuk':
        return birim == 'gr'
            ? 'Örn. 30 gr saç boyası, 50 gr krem'
            : 'Örn. 50 ml oksidan, 100 ml şampuan';
      case 'buyuk':
        return birim == 'kg' ? 'Örn. 0,5 kg toz, 1 kg malzeme' : 'Örn. 0,25 lt, 1 lt sıvı';
      default:
        return birim == 'paket' ? 'Örn. 1 paket peçete' : 'Örn. 1 adet eldiven, 2 adet havlu';
    }
  }

  Future<void> _receteMiktarDuzenle(Map<String, dynamic> r) async {
    final urunMap = r['urun'] is Map ? Map<String, dynamic>.from(r['urun']) : <String, dynamic>{};
    final urunId = (urunMap['id'] ?? r['urun_id'])?.toString();
    if (urunId == null) return;
    final urun = Urun(
      id: urunId,
      urun_adi: urunMap['urun_adi']?.toString() ?? '—',
      barkod: urunMap['barkod']?.toString() ?? '',
      fiyat: urunMap['fiyat']?.toString() ?? '0',
      aktif: '1',
      stok_adedi: urunMap['stok_adedi']?.toString() ?? '0',
      dusuk_stok_siniri: '',
      birim: urunMap['birim']?.toString() ?? 'adet',
      tip: urunMap['tip']?.toString() ?? 'sarf',
    );
    await StokApi.receteSil(r['id'].toString());
    await _receteMiktarGir(urun);
  }

  Widget _miktarBtn(IconData ikon, VoidCallback onTap, [String? altMetin]) {
    return Material(
      color: _morSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ikon, color: _mor, size: 22),
              if (altMetin != null) ...[
                const SizedBox(height: 2),
                Text(altMetin, style: const TextStyle(color: _mor, fontWeight: FontWeight.w700, fontSize: 10)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _hizliMiktarChip(String etiket, bool secili, VoidCallback onTap) {
    return Material(
      color: secili ? _mor : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: secili ? _mor : _mor.withValues(alpha: 0.3)),
          ),
          child: Text(
            etiket,
            style: TextStyle(color: secili ? Colors.white : _mor, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }

  static String _miktarFmt(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
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
