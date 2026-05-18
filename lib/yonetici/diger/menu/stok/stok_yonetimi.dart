import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Models/depo.dart';
import 'package:randevu_sistem/Models/tedarikci.dart';
import 'package:randevu_sistem/Models/urun_kategorisi.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/services/stok_api.dart';

import 'alis_girisi.dart';
import 'ayar_yonetimi.dart';
import 'barkod_tarayici.dart';
import 'hizli_satis.dart';
import 'sayim.dart';
import 'urun_detay.dart';
import 'urun_form.dart';

/// Stok Yönetimi v2 — modern ana ekran.
///
/// Özet kartları + arama + kategori chip'leri + filtre + premium ürün listesi.
class StokYonetimiSayfa extends StatefulWidget {
  final dynamic isletmebilgi;
  const StokYonetimiSayfa({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  State<StokYonetimiSayfa> createState() => _StokYonetimiSayfaState();
}

class _StokYonetimiSayfaState extends State<StokYonetimiSayfa> {
  static const Color _mor      = Color(0xFF6A1B9A);
  static const Color _morSoft  = Color(0xFFF3E8FA);
  static const Color _sari     = Color(0xFFF6A609);
  static const Color _kirmizi  = Color(0xFFE53935);
  static const Color _yesil    = Color(0xFF43A047);

  late String _salonId;
  final TextEditingController _aramaCtl = TextEditingController();

  List<Urun> _urunler = [];
  List<UrunKategorisi> _kategoriler = [];
  List<Depo> _depolar = [];
  List<Tedarikci> _tedarikciler = [];

  Map<String, dynamic> _ozet = {};
  String _seciliKategori = '';
  String _seciliTip = '';

  bool _yukleniyor = true;
  String _aramaSon = '';

  @override
  void initState() {
    super.initState();
    _salonId = widget.isletmebilgi['id'].toString();
    _yukle();
    _aramaCtl.addListener(() {
      if (_aramaCtl.text != _aramaSon) {
        _aramaSon = _aramaCtl.text;
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted && _aramaCtl.text == _aramaSon) _urunleriYukle();
        });
      }
    });
  }

  @override
  void dispose() {
    _aramaCtl.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final futures = await Future.wait([
        StokApi.ozet(_salonId),
        StokApi.kategoriListesi(_salonId),
        StokApi.depoListesi(_salonId),
        StokApi.tedarikciListesi(_salonId),
        StokApi.urunListesi(_salonId),
      ]);
      _ozet         = futures[0] as Map<String, dynamic>;
      _kategoriler  = (futures[1] as List).cast<UrunKategorisi>();
      _depolar      = (futures[2] as List).cast<Depo>();
      _tedarikciler = (futures[3] as List).cast<Tedarikci>();
      _urunler      = (futures[4] as List).cast<Urun>();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yüklenemedi: $e'), backgroundColor: _kirmizi),
        );
      }
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _urunleriYukle() async {
    try {
      final list = await StokApi.urunListesi(
        _salonId,
        arama: _aramaCtl.text.trim(),
        kategoriId: _seciliKategori,
        tip: _seciliTip,
      );
      final ozet = await StokApi.ozet(_salonId);
      if (mounted) {
        setState(() {
          _urunler = list;
          _ozet = ozet;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _barkodIleAra() async {
    final kod = await BarkodTarayici.tekSeferTara(context, baslik: 'Ürün Bul / Hızlı Ekle');
    if (kod == null || kod.isEmpty) return;
    final urun = await StokApi.urunBarkodAra(_salonId, kod);
    if (!mounted) return;
    if (urun != null) {
      _urunDetayinaGit(urun);
    } else {
      final ekle = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Yeni ürün?'),
          content: Text('"$kod" barkoduyla ürün bulunamadı. Yeni ürün ekle?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
            TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Ekle')),
          ],
        ),
      );
      if (ekle == true && mounted) {
        _urunFormunaGit(barkodOnDoldur: kod);
      }
    }
  }

  void _urunFormunaGit({Urun? mevcut, String? barkodOnDoldur}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => UrunForm(
        salonId: _salonId,
        kategoriler: _kategoriler,
        tedarikciler: _tedarikciler,
        mevcut: mevcut,
        barkodOnDoldur: barkodOnDoldur,
      ),
    )).then((_) => _urunleriYukle());
  }

  void _urunDetayinaGit(Urun u) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => UrunDetaySayfa(
        urun: u,
        salonId: _salonId,
        depolar: _depolar,
        kategoriler: _kategoriler,
        tedarikciler: _tedarikciler,
      ),
    )).then((_) => _urunleriYukle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: const Text('Stok Yönetimi', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner, color: _mor), tooltip: 'Barkod', onPressed: _barkodIleAra),
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.black54), onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => AyarYonetimi(salonId: _salonId),
            )).then((_) => _yukle());
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _yukle,
        child: _yukleniyor
            ? const Center(child: CircularProgressIndicator(color: _mor))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ozetKartlari(),
                    const SizedBox(height: 16),
                    _aksiyonButonlari(),
                    const SizedBox(height: 16),
                    _aramaVeFiltreler(),
                    const SizedBox(height: 10),
                    _kategoriChipleri(),
                    const SizedBox(height: 10),
                    if (_urunler.isEmpty)
                      _bosDurum()
                    else
                      ..._urunler.map((u) => _urunKarti(u)),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _mor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Ürün'),
        onPressed: () => _urunFormunaGit(),
      ),
    );
  }

  // ============================================================
  // ÖZET KARTLARI
  // ============================================================

  Widget _ozetKartlari() {
    final toplam   = _ozet['toplam_urun']?.toString() ?? '0';
    final dusuk    = _ozet['dusuk_stok']?.toString() ?? '0';
    final tukenen  = _ozet['tukenen']?.toString() ?? '0';
    final deger    = double.tryParse(_ozet['toplam_satis_degeri']?.toString() ?? '0') ?? 0;
    final bugun    = _ozet['bugun_satis_tutar']?.toString() ?? '0';
    final bugunNum = double.tryParse(bugun) ?? 0;
    final bool isTabletLandscape =
        MediaQuery.of(context).size.width >= 900 &&
            MediaQuery.of(context).orientation == Orientation.landscape;
    return Column(
      children: [
        if (isTabletLandscape)
          Row(children: [
            Expanded(child: _ozetKart('Toplam Ürün', toplam, Icons.inventory_2_outlined, _mor)),
            const SizedBox(width: 10),
            Expanded(child: _ozetKart('Düşük Stok', dusuk, Icons.warning_amber_rounded, _sari)),
            const SizedBox(width: 10),
            Expanded(child: _ozetKart('Tükenen', tukenen, Icons.remove_circle_outline, _kirmizi)),
            const SizedBox(width: 10),
            Expanded(child: _ozetKart('Stok Değeri', '₺${_tlFormat(deger)}', Icons.account_balance_wallet_outlined, _yesil)),
          ])
        else ...[
          Row(children: [
            Expanded(child: _ozetKart('Toplam Ürün', toplam, Icons.inventory_2_outlined, _mor)),
            const SizedBox(width: 10),
            Expanded(child: _ozetKart('Düşük Stok', dusuk, Icons.warning_amber_rounded, _sari)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _ozetKart('Tükenen', tukenen, Icons.remove_circle_outline, _kirmizi)),
            const SizedBox(width: 10),
            Expanded(child: _ozetKart('Stok Değeri', '₺${_tlFormat(deger)}', Icons.account_balance_wallet_outlined, _yesil)),
          ]),
        ],
        if (bugunNum > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_mor, Color(0xFF8E24AA)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.white),
                const SizedBox(width: 10),
                const Expanded(child: Text('Bugün satış', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                Text('₺${_tlFormat(bugunNum)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _ozetKart(String baslik, String deger, IconData ikon, Color renk) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border(top: BorderSide(color: renk, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(ikon, color: renk, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(baslik, style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.5), fontWeight: FontWeight.w600, letterSpacing: 0.3))),
          ]),
          const SizedBox(height: 8),
          Text(deger, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ============================================================
  // AKSİYON BUTONLARI
  // ============================================================

  Widget _aksiyonButonlari() {
    final children = <Widget>[
      _aksiyon('Hızlı Satış', Icons.shopping_cart_outlined, _yesil, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => HizliSatisSayfa(salonId: _salonId, urunler: _urunler),
        )).then((_) => _urunleriYukle());
      }),
      if (Yetki.varMi('urun.stok_giris'))
        _aksiyon('Alış Girişi', Icons.local_shipping_outlined, _mor, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AlisGirisiSayfa(salonId: _salonId, urunler: _urunler, depolar: _depolar, tedarikciler: _tedarikciler),
          )).then((_) => _urunleriYukle());
        }),
      if (Yetki.varMi('urun.stok_sayim'))
        _aksiyon('Sayım', Icons.assignment_turned_in_outlined, _sari, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => SayimSayfa(salonId: _salonId, urunler: _urunler, depolar: _depolar),
          )).then((_) => _urunleriYukle());
        }),
      _aksiyon('Düşük Stok', Icons.warning_amber, _kirmizi, () async {
        final list = await StokApi.dusukStokListesi(_salonId);
        if (!mounted) return;
        setState(() => _urunler = list);
      }),
    ];
    final bool isTabletLandscape =
        MediaQuery.of(context).size.width >= 900 &&
            MediaQuery.of(context).orientation == Orientation.landscape;
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      childAspectRatio: isTabletLandscape ? 1.6 : 1,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  Widget _aksiyon(String etiket, IconData ikon, Color renk, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: renk.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(ikon, color: renk, size: 22),
              ),
              const SizedBox(height: 6),
              Text(etiket, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ARAMA + FİLTRELER + KATEGORİ CHIP'LERİ
  // ============================================================

  Widget _aramaVeFiltreler() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _aramaCtl,
              decoration: const InputDecoration(
                hintText: 'Ürün adı, barkod veya SKU...',
                border: InputBorder.none,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: _seciliTip.isEmpty ? Colors.black45 : _mor),
            initialValue: _seciliTip,
            onSelected: (v) {
              setState(() => _seciliTip = v == 'tumu' ? '' : v);
              _urunleriYukle();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'tumu',  child: Text('Tüm Tipler')),
              PopupMenuItem(value: 'satis', child: Text('Satış Ürünleri')),
              PopupMenuItem(value: 'sarf',  child: Text('Sarf Malzemeler')),
              PopupMenuItem(value: 'karma', child: Text('Karma')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kategoriChipleri() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('Tümü', _seciliKategori.isEmpty, () { setState(() => _seciliKategori = ''); _urunleriYukle(); }),
          ..._kategoriler.map((k) {
            final renk = _hexToColor(k.renk) ?? _mor;
            return _chip(k.ad, _seciliKategori == k.id, () { setState(() => _seciliKategori = k.id); _urunleriYukle(); }, renk: renk);
          }),
        ],
      ),
    );
  }

  Widget _chip(String etiket, bool secili, VoidCallback onTap, {Color? renk}) {
    final c = renk ?? _mor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: secili ? c : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: secili ? c : Colors.black12),
            ),
            child: Text(etiket, style: TextStyle(color: secili ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ÜRÜN KARTI
  // ============================================================

  Widget _urunKarti(Urun u) {
    final durum = u.stokDurumu;
    final stokRenk = durum == 'kirmizi' ? _kirmizi : (durum == 'sari' ? _sari : _yesil);
    final stokBg   = stokRenk.withValues(alpha: 0.12);
    final tipChip = _tipChipi(u.tip);
    final katRenk = _hexToColor(u.kategori_renk) ?? Colors.black38;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _urunDetayinaGit(u),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _morSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: u.resim_url.isNotEmpty
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(u.resim_url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: _mor)))
                    : const Icon(Icons.inventory_2, color: _mor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(u.urun_adi, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        tipChip,
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (u.kategori_adi.isNotEmpty) ...[
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: katRenk, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(u.kategori_adi, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          const SizedBox(width: 8),
                        ],
                        if (u.barkod.isNotEmpty) Text(u.barkod, style: const TextStyle(fontSize: 11, color: Colors.black38)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: stokBg, borderRadius: BorderRadius.circular(8)),
                          child: Text('${_adetFormat(u.stokSayisal)} ${u.birim}', style: TextStyle(color: stokRenk, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        const Spacer(),
                        Text('₺${_tlFormat(u.fiyatSayisal)}', style: const TextStyle(fontWeight: FontWeight.w800, color: _mor, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipChipi(String tip) {
    Color bg, fg;
    String etiket;
    switch (tip) {
      case 'sarf':  bg = const Color(0xFFFCE4EC); fg = const Color(0xFFAD1457); etiket = 'SARF'; break;
      case 'karma': bg = _morSoft;                fg = _mor;                    etiket = 'KARMA'; break;
      default:      bg = const Color(0xFFE3F2FD); fg = const Color(0xFF1565C0); etiket = 'SATIŞ';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(etiket, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  Widget _bosDurum() {
    return Container(
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.only(top: 30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.black.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text('Henüz ürün yok', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Sağ alttan "Yeni Ürün" ile ekle', style: TextStyle(color: Colors.black.withValues(alpha: 0.5))),
        ],
      ),
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

  static Color? _hexToColor(String hex) {
    if (hex.isEmpty) return null;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    if (v == null) return null;
    return Color(v);
  }
}
