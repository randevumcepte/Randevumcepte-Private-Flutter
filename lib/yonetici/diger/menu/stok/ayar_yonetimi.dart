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
  static const Color _sari = Color(0xFFF6A609);

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
    // Profesyonel POS hesabı — Mindbody/Phorest/Boulevard standardı
    double toplamMaliyet = 0;
    int eksikFiyat = 0;
    int yapilabilirHizmet = 99999; // En dar boğaz malzemenin verdiği limit
    for (final r in _receteler) {
      final m = r['urun'] is Map ? Map<String, dynamic>.from(r['urun']) : <String, dynamic>{};
      final miktar = double.tryParse(r['miktar']?.toString() ?? '0') ?? 0;
      final alis = double.tryParse(m['alis_fiyati']?.toString() ?? '0') ?? 0;
      final stok = double.tryParse(m['stok_adedi']?.toString() ?? '0') ?? 0;
      if (alis > 0) {
        toplamMaliyet += miktar * alis;
      } else {
        eksikFiyat++;
      }
      if (miktar > 0) {
        final yapabilir = (stok / miktar).floor();
        if (yapabilir < yapilabilirHizmet) yapilabilirHizmet = yapabilir;
      }
    }
    if (_receteler.isEmpty) yapilabilirHizmet = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // === MALİYET KARNESİ (Boulevard / Phorest tarzı) ===
        _maliyetKarnesi(toplamMaliyet, eksikFiyat, yapilabilirHizmet),
        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Text(
                '${_receteler.length} MALZEME',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.black.withValues(alpha: 0.5)),
              ),
              const Spacer(),
              if (eksikFiyat > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _kirmizi.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('$eksikFiyat malzeme fiyatsız', style: const TextStyle(color: _kirmizi, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ..._receteler.map((r) {
          final m = r['urun'] is Map ? Map<String, dynamic>.from(r['urun']) : <String, dynamic>{};
          final urunAdi = m['urun_adi']?.toString() ?? '—';
          final birim = m['birim']?.toString() ?? 'adet';
          final tip = m['tip']?.toString() ?? 'sarf';
          final miktar = double.tryParse(r['miktar']?.toString() ?? '0') ?? 0;
          final alis = double.tryParse(m['alis_fiyati']?.toString() ?? '0') ?? 0;
          final stok = double.tryParse(m['stok_adedi']?.toString() ?? '0') ?? 0;
          final maliyet = miktar * alis;
          final rid = r['id'].toString();
          final yetersizStok = stok < miktar;
          final fiyatYok = alis <= 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fiyatYok ? _kirmizi.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Row(
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
                          Text(urunAdi, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: _morSoft, borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  '${_miktarFmt(miktar)} $birim',
                                  style: const TextStyle(color: _mor, fontWeight: FontWeight.w700, fontSize: 11),
                                ),
                              ),
                              if (yetersizStok) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: _kirmizi.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text('STOK YETERSİZ', style: const TextStyle(color: _kirmizi, fontWeight: FontWeight.w800, fontSize: 9)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (fiyatYok)
                          GestureDetector(
                            onTap: () => _receteMiktarDuzenle(r),
                            child: const Text('Fiyat gir →', style: TextStyle(color: _kirmizi, fontSize: 11, fontWeight: FontWeight.w700)),
                          )
                        else
                          Text('₺${maliyet.toStringAsFixed(2)}', style: const TextStyle(color: _mor, fontWeight: FontWeight.w800, fontSize: 15)),
                        if (!fiyatYok)
                          Text('${miktar.toStringAsFixed(miktar == miktar.roundToDouble() ? 0 : 1)} × ₺${alis.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black54),
                      onSelected: (v) async {
                        if (v == 'edit') {
                          _receteMiktarDuzenle(r);
                        } else if (v == 'del') {
                          if (await _onay('"$urunAdi" reçeteden çıkarılsın mı?')) {
                            await StokApi.receteSil(rid);
                            _receteleriYukle();
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, color: _mor, size: 18), SizedBox(width: 8), Text('Miktar/Fiyat Düzenle')])),
                        PopupMenuItem(value: 'del',  child: Row(children: [Icon(Icons.delete_outline, color: _kirmizi, size: 18), SizedBox(width: 8), Text('Çıkar')])),
                      ],
                    ),
                  ],
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

  /// Profesyonel maliyet karnesi — toplam malzeme maliyeti + kâr/marj + stok yeterlilik.
  ///
  /// Mindbody / Phorest / Boulevard standardı:
  /// 1. Toplam Maliyet (büyük): tüm malzemelerin (miktar × alış) toplamı
  /// 2. Eğer hizmet fiyatı tanımlıysa: kâr ve marj % gösterimi
  /// 3. Stok yeterlilik: "Mevcut stokla X hizmet daha yapılabilir"
  Widget _maliyetKarnesi(double toplamMaliyet, int eksikFiyat, int yapilabilirHizmet) {
    // Hizmet satış fiyatını _hizmetler'den al (varsa)
    double hizmetFiyati = 0;
    if (_seciliHizmetId != null) {
      final h = _hizmetler.firstWhere(
        (x) => x['id']?.toString() == _seciliHizmetId,
        orElse: () => <String, dynamic>{},
      );
      hizmetFiyati = double.tryParse(h['fiyat']?.toString() ?? h['baslangic_fiyat']?.toString() ?? '0') ?? 0;
    }
    final kar = hizmetFiyati - toplamMaliyet;
    final marj = (toplamMaliyet > 0 && hizmetFiyati > 0) ? (kar / hizmetFiyati) * 100 : 0;
    final karPozitif = kar >= 0;
    final stokRenk = yapilabilirHizmet > 10 ? _yesil : (yapilabilirHizmet > 0 ? _sari : _kirmizi);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_mor, Color(0xFF8E24AA)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _mor.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // === Üst: Toplam maliyet (büyük) ===
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.calculate_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MALZEME MALİYETİ', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      '₺${toplamMaliyet.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26),
                    ),
                    if (eksikFiyat > 0)
                      Text('+ $eksikFiyat malzeme fiyatsız (dahil değil)', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          // === Orta: Kâr / Marj (hizmet fiyatı varsa) ===
          if (hizmetFiyati > 0) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _karneAlt(
                    'HİZMET FİYATI',
                    '₺${hizmetFiyati.toStringAsFixed(2)}',
                    Colors.white,
                  ),
                ),
                Expanded(
                  child: _karneAlt(
                    karPozitif ? 'BRÜT KÂR' : 'ZARAR',
                    '${karPozitif ? '' : '-'}₺${kar.abs().toStringAsFixed(2)}',
                    karPozitif ? const Color(0xFF80FFC8) : const Color(0xFFFFB4B4),
                  ),
                ),
                Expanded(
                  child: _karneAlt(
                    'MARJ',
                    '%${marj.toStringAsFixed(0)}',
                    marj >= 50 ? const Color(0xFF80FFC8) : (marj >= 0 ? const Color(0xFFFFE082) : const Color(0xFFFFB4B4)),
                  ),
                ),
              ],
            ),
          ],
          // === Alt: Stok yeterlilik ===
          if (_receteler.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: stokRenk, shape: BoxShape.circle, boxShadow: [BoxShadow(color: stokRenk.withValues(alpha: 0.5), blurRadius: 6)]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        children: [
                          const TextSpan(text: 'Mevcut stokla '),
                          TextSpan(text: '$yapilabilirHizmet hizmet', style: const TextStyle(fontWeight: FontWeight.w800)),
                          const TextSpan(text: ' daha yapılabilir'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _karneAlt(String etiket, String deger, Color deger_renk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiket, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(deger, style: TextStyle(color: deger_renk, fontWeight: FontWeight.w800, fontSize: 16)),
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
    // Alış fiyatı — ürünün mevcut alış fiyatını al; kullanıcı buradan değiştirebilir
    double alisFiyati = urun.alisFiyatiSayisal;
    final alisCtl = TextEditingController(text: alisFiyati == 0 ? '' : alisFiyati.toString());

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
                      const SizedBox(height: 22),

                      // === Birim alış fiyatı + Canlı maliyet (PROFESYONEL POS) ===
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: alisFiyati <= 0 ? _kirmizi.withValues(alpha: 0.06) : const Color(0xFFF0FAF3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: alisFiyati <= 0 ? _kirmizi.withValues(alpha: 0.3) : _yesil.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(alisFiyati <= 0 ? Icons.warning_amber_rounded : Icons.payments_outlined, color: alisFiyati <= 0 ? _kirmizi : _yesil, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  alisFiyati <= 0 ? 'ALIŞ FİYATI TANIMLANMAMIŞ' : 'BİRİM ALIŞ FİYATI',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: alisFiyati <= 0 ? _kirmizi : _yesil),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: alisCtl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      prefixText: '₺ ',
                                      prefixStyle: const TextStyle(fontWeight: FontWeight.w800, color: _mor),
                                      suffixText: ' / $birim',
                                      suffixStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                                      hintText: '0.00',
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    ),
                                    onChanged: (v) {
                                      setSt(() => alisFiyati = double.tryParse(v.replaceAll(',', '.')) ?? 0);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (alisFiyati <= 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Maliyet hesaplaması için fiyat gir. Bu fiyat ürün ayarlarına da kaydedilecek.',
                                  style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.6)),
                                ),
                              ),
                            // Canlı maliyet preview
                            if (alisFiyati > 0 && miktar > 0) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.functions, color: _yesil, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${BirimHelper.formatla(miktar, birim)} × ₺${alisFiyati.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text('= ₺${(miktar * alisFiyati).toStringAsFixed(2)}', style: const TextStyle(color: _yesil, fontWeight: FontWeight.w800, fontSize: 15)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

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
      // Eğer alış fiyatı bottom sheet'te değiştirildiyse (veya ilk kez girildiyse),
      // ürünün alış fiyatını güncelle — maliyet hesabı tutarlı kalsın.
      final yeniAlis = double.tryParse(alisCtl.text.replaceAll(',', '.')) ?? 0;
      if (yeniAlis > 0 && (yeniAlis - urun.alisFiyatiSayisal).abs() > 0.001) {
        await StokApi.urunKaydet(widget.salonId, {
          'id': urun.id,
          'urun_adi': urun.urun_adi,
          'barkod': urun.barkod,
          'sku': urun.sku,
          'fiyat': urun.fiyat,
          'alis_fiyati': yeniAlis,
          'kdv_orani': urun.kdv_orani,
          'birim': urun.birim,
          'tip': urun.tip,
          'kategori_id': urun.kategori_id,
          'tedarikci_id': urun.tedarikci_id,
          'stok_adedi': urun.stok_adedi,
          'dusuk_stok_siniri': urun.dusuk_stok_siniri,
          'kritik_stok_siniri': urun.kritik_stok_siniri,
          'aciklama': urun.aciklama,
          'kullanici_tipi': 'isletme_yonetim',
        });
      }
      await StokApi.receteKaydet(widget.salonId, {
        'hizmet_id': _seciliHizmetId,
        'hizmet_tipi': 'islem',
        'urun_id': urun.id,
        'miktar': miktar,
      });
      // Hem reçete listesini hem ürün cache'ini yenile (alış fiyatı değişmiş olabilir)
      await _yukle();
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
