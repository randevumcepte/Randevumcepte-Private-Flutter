import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';
import 'package:randevu_sistem/Models/personel.dart';

// Personel Detay sayfasi. Web'deki personeldetay.blade.php'in Flutter karsiligi.
// - Ust kisimda profil ve hak edis yuzdeleri
// - Ay / Yil secici (ay degisince prim yeniden hesaplaniyor)
// - 4 prim karti: Hizmet / Urun / Paket / Toplam Hakedis + Maas
// - Donemdeki adisyon detay listesi
//
// Renk paleti web ile ayni: --pyo-purple-1 #5C008E -> --pyo-purple-3 #9D5DC8
class PersonelDetay extends StatefulWidget {
  final Personel personel;
  final dynamic isletmebilgi;
  const PersonelDetay({super.key, required this.personel, required this.isletmebilgi});

  @override
  State<PersonelDetay> createState() => _PersonelDetayState();
}

class _PersonelDetayState extends State<PersonelDetay> {
  // Web'deki ay etiketleri ile birebir.
  static const _aylar = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  late int _seciliAy;   // 1..12
  late int _seciliYil;
  bool _loading = true;
  Map<String, dynamic>? _veri;
  String? _hata;

  // Web paleti (Color literal'leri burada toplandi)
  static const _p1 = Color(0xFF5C008E);
  static const _p2 = Color(0xFF7B2FB8);
  static const _p3 = Color(0xFF9D5DC8);
  static const _purpleBg = Color(0xFFF7F1FB);
  static const _border = Color(0xFFECE6F2);
  static const _text = Color(0xFF2D1B3F);
  static const _muted = Color(0xFF8A8295);

  static const _grad = LinearGradient(
    colors: [_p1, _p2, _p3],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _seciliAy = now.month;
    _seciliYil = now.year;
    _veriYukle();
  }

  Future<void> _veriYukle() async {
    setState(() {
      _loading = true;
      _hata = null;
    });
    try {
      // personelgetir bir donem salon_id dondurmuyordu -> model'de "null" olabiliyor.
      // Secili salonu (personel bu salonda listelendi) tercih et; backend de artik salon_id doner.
      final secili = await secilisalonid();
      final sId = (widget.personel.salon_id.isNotEmpty &&
              widget.personel.salon_id != 'null')
          ? widget.personel.salon_id
          : (secili ?? '');
      final data = await personelPrimHesaplaAyYil(
        personelid: widget.personel.id,
        salonid: sId,
        ay: _seciliAy.toString().padLeft(2, '0'),
        yil: _seciliYil.toString(),
      );
      if (!mounted) return;
      setState(() {
        _veri = data;
        _loading = false;
        if (data == null) _hata = 'Veri alinamadi.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hata = 'Hata: $e';
      });
    }
  }

  // "1.234,56" string'i (TR formatli) -> double
  double _parseTrNumber(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    var s = v.toString().trim();
    if (s.isEmpty) return 0.0;
    if (s.contains(',')) {
      // TR formati: "1.234,56" -> binlik '.' kaldir, ondalik ',' -> '.'
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if ('.'.allMatches(s).length > 1) {
      // Virgulsuz cok noktali "1.234.567" -> binlik ayraci, kaldir
      s = s.replaceAll('.', '');
    }
    // Virgulsuz tek nokta "1234.5" -> ondalik ayraci; nokta KALMALI
    // (backend float'i string olarak gelirse 10x/100x sismeyi onler)
    return double.tryParse(s) ?? 0.0;
  }

  // double -> "1.234,56 ₺"
  String _fmtTl(num v) {
    final raw = v.toStringAsFixed(2);
    final parts = raw.split('.');
    final tamKisim = parts[0];
    final frac = parts[1];
    final buf = StringBuffer();
    final reversed = tamKisim.split('').reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write('.');
      buf.write(reversed[i]);
    }
    final intFmt = buf.toString().split('').reversed.join('');
    return '$intFmt,$frac ₺';
  }

  String _personelInitial() {
    final ad = widget.personel.personel_adi.trim();
    if (ad.isEmpty) return '?';
    return ad.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: const IconThemeData(color: _text),
        title: const Text('Personel Detay', style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _p1),
            onPressed: _loading ? null : _veriYukle,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _p1,
        onRefresh: _veriYukle,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            _profilKarti(),
            const SizedBox(height: 14),
            _ayYilSecici(),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(color: _p1)),
              )
            else if (_hata != null)
              _hataKarti(_hata!)
            else ...[
              _primKartlari(),
              const SizedBox(height: 18),
              _adisyonListesi(),
            ],
          ],
        ),
      ),
    );
  }

  // === Profil karti (hero) ===
  Widget _profilKarti() {
    final per = widget.personel;
    final maas = _parseTrNumber(per.maas);
    return Container(
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _p1.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _personelInitial(),
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      per.personel_adi,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (per.unvan.isNotEmpty && per.unvan != 'null')
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          per.unvan,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                        ),
                      ),
                    if (per.cep_telefon.isNotEmpty && per.cep_telefon != 'null')
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.phone, color: Colors.white.withValues(alpha: 0.85), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              per.cep_telefon,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _miniBilgi('Maaş', _fmtTl(maas))),
              Expanded(child: _miniBilgi('Hizmet %', '%${per.hizmet_prim_yuzde}')),
              Expanded(child: _miniBilgi('Ürün %', '%${per.urun_prim_yuzde}')),
              Expanded(child: _miniBilgi('Paket %', '%${per.paket_prim_yuzde}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBilgi(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // === Ay/Yil secici ===
  Widget _ayYilSecici() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          const Icon(Icons.event, color: _p2, size: 18),
          const SizedBox(width: 8),
          const Text('Dönem',
              style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13.5)),
          const Spacer(),
          // Ay dropdown
          _drop<int>(
            value: _seciliAy,
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_aylar[i]))),
            onChanged: (v) {
              if (v == null || v == _seciliAy) return;
              setState(() => _seciliAy = v);
              _veriYukle();
            },
          ),
          const SizedBox(width: 8),
          // Yil dropdown - mevcut yil +/- 5
          _drop<int>(
            value: _seciliYil,
            items: List.generate(8, (i) {
              final y = DateTime.now().year - 5 + i;
              return DropdownMenuItem(value: y, child: Text(y.toString()));
            }),
            onChanged: (v) {
              if (v == null || v == _seciliYil) return;
              setState(() => _seciliYil = v);
              _veriYukle();
            },
          ),
        ],
      ),
    );
  }

  Widget _drop<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _purpleBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: AramaliDropdown<T>(
          value: value,
          isDense: true,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _p1, size: 18),
          style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // === Prim kartlari ===
  Widget _primKartlari() {
    final v = _veri ?? const {};
    final maas = _parseTrNumber(widget.personel.maas);
    final hizmetT = _parseTrNumber(v['hizmet_toplam_numeric'] ?? v['hizmet_toplam']);
    final hizmetH = _parseTrNumber(v['hizmet_hakedis_numeric'] ?? v['hizmet_hakedis']);
    final urunT = _parseTrNumber(v['urun_toplam_numeric'] ?? v['urun_toplam']);
    final urunH = _parseTrNumber(v['urun_hakedis_numeric'] ?? v['urun_hakedis']);
    final paketT = _parseTrNumber(v['paket_toplam_numeric'] ?? v['paket_toplam']);
    final paketH = _parseTrNumber(v['paket_hakedis_numeric'] ?? v['paket_hakedis']);
    final toplamHakedis = hizmetH + urunH + paketH;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _primKart(
              icon: Icons.cut,
              renk: const Color(0xFF46CBDA),
              baslik: 'Hizmet',
              satis: hizmetT,
              prim: hizmetH,
            )),
            const SizedBox(width: 10),
            Expanded(child: _primKart(
              icon: Icons.shopping_bag_outlined,
              renk: const Color(0xFF9200BC),
              baslik: 'Ürün',
              satis: urunT,
              prim: urunH,
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _primKart(
              icon: Icons.inventory_2_outlined,
              renk: const Color(0xFFEA43F2),
              baslik: 'Paket',
              satis: paketT,
              prim: paketH,
            )),
            const SizedBox(width: 10),
            Expanded(child: _toplamKart(toplamHakedis: toplamHakedis, maas: maas)),
          ],
        ),
      ],
    );
  }

  Widget _primKart({
    required IconData icon,
    required Color renk,
    required String baslik,
    required double satis,
    required double prim,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: renk.withValues(alpha: 0.08), blurRadius: 10)],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: renk, size: 17),
              ),
              const SizedBox(width: 10),
              Text(baslik,
                  style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Satış',
              style: TextStyle(color: _muted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(_fmtTl(satis),
              style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Prim Hakediş',
              style: TextStyle(color: _muted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(_fmtTl(prim),
              style: TextStyle(color: renk, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _toplamKart({required double toplamHakedis, required double maas}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.attach_money, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 10),
              const Text('Toplam',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Prim Hakediş',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(_fmtTl(toplamHakedis),
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Maaş',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(_fmtTl(maas),
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // === Adisyon listesi ===
  Widget _adisyonListesi() {
    final list = (_veri?['adisyonlar'] as List?) ?? const [];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: _p2, size: 18),
              const SizedBox(width: 8),
              const Text('Dönem Adisyonları',
                  style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _purpleBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${list.length} adet',
                    style: const TextStyle(color: _p1, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, color: _muted.withValues(alpha: 0.5), size: 36),
                    const SizedBox(height: 8),
                    Text('Bu dönemde adisyon bulunamadı',
                        style: TextStyle(color: _muted, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...list.map((a) => _adisyonSatiri(a as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _adisyonSatiri(Map<String, dynamic> a) {
    // adisyon_yukle()'in gerçek field isimleri (ApiController.php:1066-1092):
    //   acilis_tarihi, musteri, icerik / icerikKisaltilmis, hizmet_veren,
    //   toplam (str), odenen (str), kalan_tutar (str),
    //   hakedisTutar (numeric), hizmetHakedisTutar, urunHakedisTutar, paketHakedisTutar
    String s(dynamic v) => (v == null) ? '' : v.toString();
    final tarih = s(a['acilis_tarihi']);
    final musteri = s(a['musteri']);
    final hizmetVeren = s(a['hizmet_veren']);
    final icerik = s(a['icerikKisaltilmis']).isNotEmpty
        ? s(a['icerikKisaltilmis'])
        : s(a['icerik']);
    final toplam = s(a['toplam']);
    final odenen = s(a['odenen']);
    final kalan = s(a['kalan_tutar']);
    final hakedis = _fmtTl(_parseTrNumber(a['hakedisTutar']));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  musteri.isEmpty ? '—' : musteri,
                  style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hizmetVeren.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _purpleBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(hizmetVeren,
                      style: const TextStyle(color: _p1, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          if (tarih.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(tarih, style: TextStyle(color: _muted, fontSize: 11.5)),
            ),
          if (icerik.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(icerik, style: const TextStyle(color: _text, fontSize: 12.5)),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _adisyonTutar('Toplam', toplam, _text)),
              Expanded(child: _adisyonTutar('Ödenen', odenen, const Color(0xFF15803D))),
              Expanded(child: _adisyonTutar('Kalan', kalan, const Color(0xFF991B1B))),
              Expanded(child: _adisyonTutar('Hakediş', hakedis, _p1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adisyonTutar(String label, String val, Color renk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(color: _muted, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(val.isEmpty ? '—' : val,
            style: TextStyle(color: renk, fontSize: 12, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _hataKarti(String mesaj) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFF991B1B)),
          const SizedBox(width: 10),
          Expanded(child: Text(mesaj, style: const TextStyle(color: Color(0xFF991B1B)))),
        ],
      ),
    );
  }
}
