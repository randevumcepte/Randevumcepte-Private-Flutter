import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/personeldetay.dart';

// Prim & Hak Ediş sayfasi. Web'deki prim_hakedis_panel.blade.php'in mobile karsiligi.
// Her personel icin secilen donemde:
//   - Sabit maas
//   - Hizmet/Urun/Paket primi toplami (hakedis)
//   - Net (maas + prim toplami)
//
// N personel x 1 prim istegi paralel cekiliyor — N genelde 5-30 oldugu icin OK.
class PrimHakedis extends StatefulWidget {
  final dynamic isletmebilgi;
  const PrimHakedis({super.key, required this.isletmebilgi});

  @override
  State<PrimHakedis> createState() => _PrimHakedisState();
}

class _PrimHakedisState extends State<PrimHakedis> {
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

  static const _aylar = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  String? _salonid;
  late int _seciliAy;
  late int _seciliYil;
  bool _yukleniyor = true;
  String? _hata;
  List<Personel> _personeller = [];
  // personel_id -> prim verisi (ayrica null = istegi basarisiz)
  Map<String, Map<String, dynamic>?> _primler = {};
  // personel_id -> donem icindeki odeme + bonus/kesinti toplamlari
  // {maas, prim, diger, bonus, kesinti} her biri double
  Map<String, Map<String, double>> _odenenler = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _seciliAy = now.month;
    _seciliYil = now.year;
    _init();
  }

  Future<void> _init() async {
    _salonid = await secilisalonid();
    if (!mounted) return;
    if (_salonid == null) {
      setState(() {
        _yukleniyor = false;
        _hata = 'Salon bilgisi alinamadi';
      });
      return;
    }
    try {
      await _primleriHesapla();
    } catch (e) {
      _hata = 'Hata: $e';
    }
    if (!mounted) return;
    setState(() => _yukleniyor = false);
  }

  // TEK HTTP istegi ile tum personellerin prim+odeme verisi.
  // Onceden N personel icin 2N+1 istek atiliyordu — buyuk performans iyilesmesi.
  Future<void> _primleriHesapla() async {
    if (_salonid == null) return;
    final ay = _seciliAy.toString().padLeft(2, '0');
    final yil = _seciliYil.toString();
    final data = await primHakedisToplu(salonid: _salonid!, ay: ay, yil: yil);
    if (data == null || data['basarili'] != true) {
      _personeller = [];
      _primler = {};
      _odenenler = {};
      return;
    }
    final list = (data['personeller'] as List?) ?? const [];
    _personeller = list.map((m) {
      final map = Map<String, dynamic>.from(m as Map);
      return Personel.fromJson(map);
    }).toList();
    _primler = {};
    _odenenler = {};
    for (final m in list) {
      final map = Map<String, dynamic>.from(m as Map);
      final id = map['personel_id'].toString();
      _primler[id] = {
        'hizmet_toplam_numeric':  map['hizmet_toplam'],
        'urun_toplam_numeric':    map['urun_toplam'],
        'paket_toplam_numeric':   map['paket_toplam'],
        'hizmet_hakedis_numeric': map['hizmet_hakedis'],
        'urun_hakedis_numeric':   map['urun_hakedis'],
        'paket_hakedis_numeric':  map['paket_hakedis'],
      };
      _odenenler[id] = {
        'maas':    _parseTrNumber(map['odenen_maas']),
        'prim':    _parseTrNumber(map['odenen_prim']),
        'diger':   _parseTrNumber(map['odenen_diger']),
        'bonus':   _parseTrNumber(map['bonus']),
        'kesinti': _parseTrNumber(map['kesinti']),
      };
    }
  }

  // === Bir personel icin: maas/prim ham + odenmis + kalan tutarlar ===
  ({
    double maasHam,
    double primHam,
    double odenenMaas,
    double odenenPrim,
    double odenenDiger,
    double bonus,
    double kesinti,
    double kalanMaas,
    double kalanPrim,
    double netHakedis,    // maas + primHam + bonus - kesinti
    double odenenToplam,  // maas + prim + diger
    double bekleyen,      // netHakedis - odenenToplam (0'in altina dusmez)
  }) _kalanlar(Personel p) {
    final maasHam = _parseTrNumber(p.maas);
    final d = _primler[p.id];
    final hizmetH = _parseTrNumber(d?['hizmet_hakedis_numeric'] ?? d?['hizmet_hakedis']);
    final urunH = _parseTrNumber(d?['urun_hakedis_numeric'] ?? d?['urun_hakedis']);
    final paketH = _parseTrNumber(d?['paket_hakedis_numeric'] ?? d?['paket_hakedis']);
    final primHam = hizmetH + urunH + paketH;
    final o = _odenenler[p.id] ?? const {};
    final odenenMaas = o['maas'] ?? 0.0;
    final odenenPrim = o['prim'] ?? 0.0;
    final odenenDiger = o['diger'] ?? 0.0;
    final bonus = o['bonus'] ?? 0.0;
    final kesinti = o['kesinti'] ?? 0.0;
    final kalanMaas = (maasHam - odenenMaas).clamp(0.0, double.infinity);
    final kalanPrim = (primHam - odenenPrim).clamp(0.0, double.infinity);
    final netHakedis = maasHam + primHam + bonus - kesinti;
    final odenenToplam = odenenMaas + odenenPrim + odenenDiger;
    final bekleyen = (netHakedis - odenenToplam).clamp(0.0, double.infinity);
    return (
      maasHam: maasHam,
      primHam: primHam,
      odenenMaas: odenenMaas,
      odenenPrim: odenenPrim,
      odenenDiger: odenenDiger,
      bonus: bonus,
      kesinti: kesinti,
      kalanMaas: kalanMaas,
      kalanPrim: kalanPrim,
      netHakedis: netHakedis,
      odenenToplam: odenenToplam,
      bekleyen: bekleyen,
    );
  }

  Future<void> _donemDegistir(int? yeniAy, int? yeniYil) async {
    if (yeniAy == null && yeniYil == null) return;
    setState(() {
      _yukleniyor = true;
      if (yeniAy != null) _seciliAy = yeniAy;
      if (yeniYil != null) _seciliYil = yeniYil;
    });
    await _primleriHesapla();
    if (!mounted) return;
    setState(() => _yukleniyor = false);
  }

  Future<void> _refresh() async {
    setState(() => _yukleniyor = true);
    await _primleriHesapla();
    if (!mounted) return;
    setState(() => _yukleniyor = false);
  }

  // === Yardimcilar ===
  double _parseTrNumber(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s) ?? 0.0;
  }

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

  // === Toplamlar — KALAN mantığında (web ile aynı) ===
  ({double kalanMaas, double kalanPrim, double netBekleyen}) _toplamlar() {
    double kalanMaas = 0, kalanPrim = 0, netBekleyen = 0;
    for (final p in _personeller) {
      final k = _kalanlar(p);
      kalanMaas += k.kalanMaas;
      kalanPrim += k.kalanPrim;
      netBekleyen += k.bekleyen;
    }
    return (kalanMaas: kalanMaas, kalanPrim: kalanPrim, netBekleyen: netBekleyen);
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
        title: const Text('Prim & Hak Ediş', style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _p1),
            onPressed: _yukleniyor ? null : _refresh,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _p1,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            _hero(),
            const SizedBox(height: 14),
            _donemSecici(),
            const SizedBox(height: 14),
            if (_yukleniyor)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(color: _p1)),
              )
            else if (_hata != null)
              _hataKarti(_hata!)
            else ...[
              _toplamKartlari(),
              const SizedBox(height: 14),
              if (_personeller.isEmpty)
                _bosKart()
              else
                ..._personeller.map(_personelKarti),
            ],
          ],
        ),
      ),
    );
  }

  // === Hero ===
  Widget _hero() {
    return Container(
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prim & Hak Ediş',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 3),
                Text('Personel maaşları ve dönem hakedişleri',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === Donem secici ===
  Widget _donemSecici() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          const Icon(Icons.event, color: _p2, size: 18),
          const SizedBox(width: 8),
          const Text('Dönem',
              style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13.5)),
          const Spacer(),
          _drop<int>(
            value: _seciliAy,
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_aylar[i]))),
            onChanged: (v) => _donemDegistir(v, null),
          ),
          const SizedBox(width: 8),
          _drop<int>(
            value: _seciliYil,
            items: List.generate(8, (i) {
              final y = DateTime.now().year - 5 + i;
              return DropdownMenuItem(value: y, child: Text(y.toString()));
            }),
            onChanged: (v) => _donemDegistir(null, v),
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
        child: DropdownButton<T>(
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

  // === Toplam kartlari ===
  Widget _toplamKartlari() {
    final t = _toplamlar();
    return Row(
      children: [
        Expanded(child: _toplamKart(
          icon: Icons.account_balance_wallet_outlined,
          renk: const Color(0xFF3B82F6),
          label: 'KALAN MAAŞ',
          tutar: t.kalanMaas,
        )),
        const SizedBox(width: 8),
        Expanded(child: _toplamKart(
          icon: Icons.trending_up,
          renk: _p2,
          label: 'KALAN PRİM',
          tutar: t.kalanPrim,
        )),
        const SizedBox(width: 8),
        Expanded(child: _toplamKart(
          icon: Icons.payments,
          renk: const Color(0xFF10B981),
          label: 'BEKLEYEN ÖDEME',
          tutar: t.netBekleyen,
          vurgu: true,
        )),
      ],
    );
  }

  Widget _toplamKart({
    required IconData icon,
    required Color renk,
    required String label,
    required double tutar,
    bool vurgu = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: vurgu
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: vurgu ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: vurgu ? null : Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: (vurgu ? renk : _p1).withValues(alpha: vurgu ? 0.22 : 0.05),
            blurRadius: vurgu ? 12 : 8,
            offset: vurgu ? const Offset(0, 4) : Offset.zero,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: vurgu ? Colors.white : renk, size: 16),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                color: vurgu ? Colors.white.withValues(alpha: 0.85) : _muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              )),
          const SizedBox(height: 3),
          Text(
            _fmtTl(tutar),
            style: TextStyle(
              color: vurgu ? Colors.white : _text,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // === Personel karti ===
  Widget _personelKarti(Personel p) {
    final initial = p.personel_adi.trim().isEmpty
        ? '?'
        : p.personel_adi.trim().substring(0, 1).toUpperCase();
    final d = _primler[p.id];
    final yukleniyor = d == null && !_yukleniyor;
    final k = _kalanlar(p);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _p1.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
        child: Column(
          children: [
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _detayAc(p),
                    child: Container(
                      width: 42, height: 42,
                      decoration: const BoxDecoration(color: _purpleBg, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(initial,
                          style: const TextStyle(color: _p1, fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: InkWell(
                    onTap: () => _detayAc(p),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.personel_adi,
                            style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                        if (p.unvan.isNotEmpty && p.unvan != 'null')
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(p.unvan, style: TextStyle(color: _muted, fontSize: 11.5)),
                          ),
                      ],
                    ),
                  ),
                ),
                if (yukleniyor)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _p1),
                    ),
                  )
                else
                  // "Bekleyen" tutar (= net - ödenmis); tüm ödenmiş ise 0
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: k.bekleyen > 0
                          ? const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF34D399)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF94A3B8), Color(0xFFCBD5E1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          k.bekleyen > 0 ? Icons.schedule : Icons.check_circle,
                          color: Colors.white, size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          k.bekleyen > 0 ? _fmtTl(k.bekleyen) : 'Ödendi',
                          style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                _kartMenu(p),
              ],
            ),
            if (!yukleniyor) ...[
              const SizedBox(height: 10),
              Container(height: 1, color: _border),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Row(
                  children: [
                    Expanded(child: _kalanSatir('Maaş', k.kalanMaas, k.maasHam, _text)),
                    Expanded(child: _kalanSatir('Prim', k.kalanPrim, k.primHam, _p1)),
                    Expanded(child: _ufakSatir('Bonus', _fmtTl(k.bonus),
                        k.bonus > 0 ? const Color(0xFF15803D) : _muted)),
                    Expanded(child: _ufakSatir('Kesinti', _fmtTl(k.kesinti),
                        k.kesinti > 0 ? const Color(0xFF991B1B) : _muted)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Aksiyon butonlari: Ödeme Yap (ana) + Bonus / Kesinti (kucuk)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _aksiyonBtn(
                        icon: k.bekleyen > 0 ? Icons.payments_outlined : Icons.check_circle,
                        label: k.bekleyen > 0 ? 'Ödeme Yap' : 'Ödendi',
                        gradient: k.bekleyen > 0
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                              )
                            : null,
                        bg: k.bekleyen > 0 ? null : const Color(0xFFF3F4F6),
                        fg: k.bekleyen > 0 ? null : const Color(0xFF6B7280),
                        onTap: () => _odemeYapSheet(p),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _aksiyonBtn(
                        icon: Icons.add_circle_outline,
                        label: 'Bonus',
                        bg: const Color(0xFFFEF3C7),
                        fg: const Color(0xFFB45309),
                        onTap: () => _hareketSheet(p, tip: 'bonus'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _aksiyonBtn(
                        icon: Icons.remove_circle_outline,
                        label: 'Kesinti',
                        bg: const Color(0xFFFEE2E2),
                        fg: const Color(0xFF991B1B),
                        onTap: () => _hareketSheet(p, tip: 'kesinti'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _detayAc(Personel p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonelDetay(personel: p, isletmebilgi: widget.isletmebilgi),
      ),
    );
  }

  Widget _aksiyonBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    LinearGradient? gradient,
    Color? bg,
    Color? fg,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? bg : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: gradient != null
                ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.22), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: gradient != null ? Colors.white : fg, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: gradient != null ? Colors.white : fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartMenu(Personel p) {
    return PopupMenuButton<String>(
      tooltip: 'İşlemler',
      icon: const Icon(Icons.more_vert, color: _muted, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        switch (v) {
          case 'odemeleri_gor': _odemeListesiSheet(p); break;
          case 'detay': _detayAc(p); break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'odemeleri_gor',
          child: Row(children: const [
            Icon(Icons.history, size: 16, color: _p2),
            SizedBox(width: 10),
            Text('Ödeme Geçmişi', style: TextStyle(fontSize: 13.5)),
          ]),
        ),
        PopupMenuItem<String>(
          value: 'detay',
          child: Row(children: const [
            Icon(Icons.visibility_outlined, size: 16, color: _p2),
            SizedBox(width: 10),
            Text('Detaylar', style: TextStyle(fontSize: 13.5)),
          ]),
        ),
      ],
    );
  }

  Widget _ufakSatir(String label, String val, Color renk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(val,
            style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  // Kalan / Ham gosterim: ust satirda kalan tutar, alt satirda kucuk olarak "/ ham"
  Widget _kalanSatir(String label, double kalan, double ham, Color renk) {
    final tamOdendi = kalan <= 0.001 && ham > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(
          tamOdendi ? '0,00 ₺' : _fmtTl(kalan),
          style: TextStyle(
            color: tamOdendi ? const Color(0xFF15803D) : renk,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        if (ham > 0 && (kalan < ham - 0.001))
          Text(
            '/ ${_fmtTl(ham)}',
            style: TextStyle(color: _muted, fontSize: 9),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Ödeme Yap Sheet — kalan tutarlar otomatik, tip seçince auto-fill
  // ═══════════════════════════════════════════════════════════════
  Future<void> _odemeYapSheet(Personel p) async {
    final donem = '${_seciliYil.toString()}-${_seciliAy.toString().padLeft(2, '0')}';
    final k = _kalanlar(p);
    // Default tip: kalan maas varsa maas, yoksa kalan prim varsa prim, yoksa diger
    String tip;
    if (k.kalanMaas > 0) {
      tip = 'maas';
    } else if (k.kalanPrim > 0) {
      tip = 'prim';
    } else {
      tip = 'diger';
    }
    final tutarCtrl = TextEditingController();
    final aciklamaCtrl = TextEditingController();
    DateTime odemeTarihi = DateTime.now();
    String yontem = 'Nakit';
    bool kaydediliyor = false;

    // Tip'e gore default tutari ata
    double defaultTutar(String t) {
      if (t == 'maas') return k.kalanMaas;
      if (t == 'prim') return k.kalanPrim;
      return 0.0;
    }
    String fmtForField(double v) {
      if (v <= 0) return '';
      return v.toStringAsFixed(2).replaceAll('.', ',');
    }
    // Acilista default ata
    tutarCtrl.text = fmtForField(defaultTutar(tip));

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            void seciliTip(String yeni) {
              setSt(() {
                tip = yeni;
                // Her tip degisikliginde tutari otomatik doldur (kullanici elle override edebilir)
                tutarCtrl.text = fmtForField(defaultTutar(yeni));
                tutarCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: tutarCtrl.text.length),
                );
              });
            }

            // Aktif tip icin "kalan" gosterimi
            final kalanGoster = tip == 'maas'
                ? k.kalanMaas
                : tip == 'prim'
                    ? k.kalanPrim
                    : 0.0;
            final hamGoster = tip == 'maas'
                ? k.maasHam
                : tip == 'prim'
                    ? k.primHam
                    : 0.0;
            final odenenGoster = tip == 'maas'
                ? k.odenenMaas
                : tip == 'prim'
                    ? k.odenenPrim
                    : k.odenenDiger;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _sheetHandle(),
                    _sheetHeader(
                      icon: Icons.payments,
                      title: 'Ödeme Yap',
                      subtitle: '${p.personel_adi} · $donem',
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // === Üst özet (Hak Ediş / Ödenen / Kalan) ===
                          _ozetBar(hamGoster, odenenGoster, kalanGoster, tip),
                          const SizedBox(height: 14),
                          // === Tip seçimi (üzerinde kalan tutar yazılı) ===
                          _sheetLabel('Ödeme Tipi'),
                          Row(
                            children: [
                              Expanded(child: _tipBtnV2(
                                'maas', 'Maaş', Icons.account_balance_wallet,
                                kalan: k.kalanMaas, secili: tip, onTap: seciliTip,
                              )),
                              const SizedBox(width: 6),
                              Expanded(child: _tipBtnV2(
                                'prim', 'Prim', Icons.trending_up,
                                kalan: k.kalanPrim, secili: tip, onTap: seciliTip,
                              )),
                              const SizedBox(width: 6),
                              Expanded(child: _tipBtnV2(
                                'diger', 'Avans', Icons.savings_outlined,
                                kalan: k.odenenDiger, kalanLabel: 'Verildi',
                                secili: tip, onTap: seciliTip,
                              )),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // === Tutar ===
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _sheetLabel('Tutar (₺)'),
                              if (tip != 'diger' && kalanGoster > 0)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: InkWell(
                                    onTap: () {
                                      setSt(() {
                                        tutarCtrl.text = fmtForField(kalanGoster);
                                        tutarCtrl.selection = TextSelection.fromPosition(
                                            TextPosition(offset: tutarCtrl.text.length));
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _purpleBg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('Tümünü Öde (${_fmtTl(kalanGoster)})',
                                          style: const TextStyle(
                                              color: _p1, fontWeight: FontWeight.w700, fontSize: 11)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          _sheetField(
                            controller: tutarCtrl,
                            hint: '0,00',
                            keyboard: const TextInputType.numberWithOptions(decimal: true),
                            autofocus: false,
                          ),
                          const SizedBox(height: 14),
                          _sheetLabel('Ödeme Tarihi'),
                          _sheetTarihAlani(
                            tarih: odemeTarihi,
                            onChanged: (d) => setSt(() => odemeTarihi = d),
                          ),
                          const SizedBox(height: 14),
                          _sheetLabel('Ödeme Yöntemi'),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: ['Nakit', 'Kart', 'Havale', 'Diğer'].map((y) {
                              final sel = yontem == y;
                              return InkWell(
                                onTap: () => setSt(() => yontem = y),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: sel ? _grad : null,
                                    color: sel ? null : _purpleBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(y,
                                      style: TextStyle(
                                        color: sel ? Colors.white : _p1,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      )),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          _sheetLabel('Açıklama (opsiyonel)'),
                          _sheetField(
                            controller: aciklamaCtrl,
                            hint: 'Not ekle...',
                            keyboard: TextInputType.text,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 18),
                          _sheetKaydetBtn(
                            label: 'Ödemeyi Kaydet',
                            yukleniyor: kaydediliyor,
                            onTap: () async {
                              final tutar = _parseTrNumber(tutarCtrl.text);
                              if (tutar <= 0) {
                                _snack('Tutar 0\'dan büyük olmalı', basari: false);
                                return;
                              }
                              setSt(() => kaydediliyor = true);
                              final result = await primOde(
                                salonid: _salonid!,
                                personelid: p.id,
                                donem: donem,
                                tutar: tutar,
                                odemeTipi: tip,
                                odemeTarihi: _fmtDate(odemeTarihi),
                                odemeYontemi: yontem,
                                aciklama: aciklamaCtrl.text,
                              );
                              setSt(() => kaydediliyor = false);
                              if (result['basarili'] == true) {
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              } else {
                                _snack('Hata: ${result['mesaj'] ?? 'Bilinmeyen'}', basari: false);
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    tutarCtrl.dispose();
    aciklamaCtrl.dispose();
    if (result == true && mounted) {
      _snack('Ödeme kaydedildi', basari: true);
      await _refresh();
    }
  }

  // Sheet üstünde 3 kutucuk: Hak Ediş / Ödenen / Kalan
  Widget _ozetBar(double ham, double odenen, double kalan, String tip) {
    String ustLabel;
    if (tip == 'maas') {
      ustLabel = 'Maaş';
    } else if (tip == 'prim') {
      ustLabel = 'Prim Hak Ediş';
    } else {
      ustLabel = 'Avans';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _purpleBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ustLabel.toUpperCase(),
                    style: TextStyle(
                        color: _muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text(_fmtTl(ham),
                    style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w800),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: _border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ÖDENEN',
                      style: TextStyle(
                          color: _muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(_fmtTl(odenen),
                      style: const TextStyle(
                          color: Color(0xFF15803D), fontSize: 13, fontWeight: FontWeight.w800),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 28, color: _border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KALAN',
                      style: TextStyle(
                          color: _muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(
                    tip == 'diger' ? '—' : _fmtTl(kalan),
                    style: TextStyle(
                      color: tip == 'diger'
                          ? _muted
                          : (kalan <= 0.001 ? const Color(0xFF15803D) : const Color(0xFFB45309)),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Geliştirilmiş tip butonu: üstte kalan tutar gösterir
  Widget _tipBtnV2(
    String v,
    String label,
    IconData icon, {
    required double kalan,
    String? kalanLabel,
    required String secili,
    required ValueChanged<String> onTap,
  }) {
    final sel = v == secili;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onTap(v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          gradient: sel ? _grad : null,
          color: sel ? null : const Color(0xFFFCFAFE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? Colors.transparent : _border),
        ),
        child: Column(
          children: [
            Icon(icon, color: sel ? Colors.white : _p2, size: 16),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  color: sel ? Colors.white : _text,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                )),
            const SizedBox(height: 2),
            Text(
              kalanLabel != null
                  ? '${_fmtTl(kalan)} $kalanLabel'
                  : _fmtTl(kalan),
              style: TextStyle(
                color: sel ? Colors.white.withValues(alpha: 0.85) : _muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Bonus / Kesinti Sheet
  // ═══════════════════════════════════════════════════════════════
  Future<void> _hareketSheet(Personel p, {required String tip}) async {
    final tutarCtrl = TextEditingController();
    final aciklamaCtrl = TextEditingController();
    DateTime tarih = DateTime.now();
    bool kaydediliyor = false;
    final isBonus = tip == 'bonus';
    final accent = isBonus ? const Color(0xFFF59E0B) : const Color(0xFFDC2626);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  _sheetHeader(
                    icon: isBonus ? Icons.add_circle_outline : Icons.remove_circle_outline,
                    title: isBonus ? 'Bonus Ekle' : 'Kesinti Ekle',
                    subtitle: p.personel_adi,
                    accent: accent,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetLabel('Tutar (₺)'),
                        _sheetField(
                          controller: tutarCtrl,
                          hint: '0,00',
                          keyboard: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: true,
                        ),
                        const SizedBox(height: 14),
                        _sheetLabel('Tarih'),
                        _sheetTarihAlani(
                          tarih: tarih,
                          onChanged: (d) => setSt(() => tarih = d),
                        ),
                        const SizedBox(height: 14),
                        _sheetLabel('Açıklama (opsiyonel)'),
                        _sheetField(
                          controller: aciklamaCtrl,
                          hint: isBonus ? 'Performans bonusu, hediye...' : 'Geç kalma, eksiklik...',
                          keyboard: TextInputType.text,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 18),
                        _sheetKaydetBtn(
                          label: isBonus ? 'Bonus Ekle' : 'Kesinti Ekle',
                          yukleniyor: kaydediliyor,
                          overrideColor: accent,
                          onTap: () async {
                            final tutar = _parseTrNumber(tutarCtrl.text);
                            if (tutar <= 0) {
                              _snack('Tutar 0\'dan büyük olmalı', basari: false);
                              return;
                            }
                            setSt(() => kaydediliyor = true);
                            final result = await primHareketEkle(
                              salonid: _salonid!,
                              personelid: p.id,
                              tip: tip,
                              tutar: tutar,
                              tarih: _fmtDate(tarih),
                              aciklama: aciklamaCtrl.text,
                            );
                            setSt(() => kaydediliyor = false);
                            if (result['basarili'] == true) {
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } else {
                              _snack('Hata: ${result['mesaj'] ?? 'Bilinmeyen'}', basari: false);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    tutarCtrl.dispose();
    aciklamaCtrl.dispose();
    if (result == true && mounted) {
      _snack(isBonus ? 'Bonus eklendi' : 'Kesinti eklendi', basari: true);
      await _refresh();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Ödeme Listesi Sheet (dönem ödemeleri + hareketleri görüntüle/sil)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _odemeListesiSheet(Personel p) async {
    final donem = '${_seciliYil.toString()}-${_seciliAy.toString().padLeft(2, '0')}';
    Map<String, dynamic>? data;
    bool yukleniyor = true;

    Future<void> yukle(StateSetter setSt) async {
      setSt(() => yukleniyor = true);
      data = await primOdemeListesi(salonid: _salonid!, personelid: p.id, donem: donem);
      setSt(() => yukleniyor = false);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            if (data == null && yukleniyor) {
              Future.microtask(() => yukle(setSt));
            }
            final odemeler = (data?['odemeler'] as List?) ?? const [];
            final hareketler = (data?['hareketler'] as List?) ?? const [];
            final toplamlar = (data?['toplamlar'] as Map?) ?? const {};
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollCtrl) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    _sheetHandle(),
                    _sheetHeader(
                      icon: Icons.history,
                      title: 'Ödeme Geçmişi',
                      subtitle: '${p.personel_adi} · $donem',
                    ),
                    if (yukleniyor)
                      const Expanded(child: Center(child: CircularProgressIndicator(color: _p1)))
                    else
                      Expanded(
                        child: ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                          children: [
                            // Donem ozeti
                            Row(
                              children: [
                                Expanded(child: _ozetMini('Maaş', _fmtTl(_parseTrNumber(toplamlar['maas'])), _text)),
                                Expanded(child: _ozetMini('Prim', _fmtTl(_parseTrNumber(toplamlar['prim'])), _p1)),
                                Expanded(child: _ozetMini('Avans', _fmtTl(_parseTrNumber(toplamlar['diger'])), const Color(0xFFB45309))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(child: _ozetMini('Bonus', _fmtTl(_parseTrNumber(toplamlar['bonus'])), const Color(0xFF15803D))),
                                Expanded(child: _ozetMini('Kesinti', _fmtTl(_parseTrNumber(toplamlar['kesinti'])), const Color(0xFF991B1B))),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Odemeler listesi
                            const Text('Ödemeler',
                                style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 8),
                            if (odemeler.isEmpty)
                              _kucukBos('Bu dönemde ödeme yok')
                            else
                              ...odemeler.map((o) => _odemeSatiri(
                                    o as Map<String, dynamic>,
                                    onSil: () async {
                                      final ok = await primOdemeSil(
                                        salonid: _salonid!,
                                        odemeId: (o['id'] as num).toInt(),
                                      );
                                      if (!mounted) return;
                                      if (ok) {
                                        _snack('Ödeme silindi', basari: true);
                                        await yukle(setSt);
                                        await _refresh();
                                      } else {
                                        _snack('Silinemedi', basari: false);
                                      }
                                    },
                                  )),
                            const SizedBox(height: 14),
                            // Bonus/Kesinti listesi
                            const Text('Bonus & Kesinti',
                                style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 8),
                            if (hareketler.isEmpty)
                              _kucukBos('Bu dönemde bonus/kesinti yok')
                            else
                              ...hareketler.map((h) => _hareketSatiri(
                                    h as Map<String, dynamic>,
                                    onSil: () async {
                                      final ok = await primHareketSil(
                                        salonid: _salonid!,
                                        hareketId: (h['id'] as num).toInt(),
                                      );
                                      if (!mounted) return;
                                      if (ok) {
                                        _snack('Kayıt silindi', basari: true);
                                        await yukle(setSt);
                                        await _refresh();
                                      } else {
                                        _snack('Silinemedi', basari: false);
                                      }
                                    },
                                  )),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════ Sheet yardımcıları ═══════════════
  Widget _sheetHandle() => Container(
        margin: const EdgeInsets.only(top: 10),
        width: 38, height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _sheetHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Color accent = _p1,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 16)),
                Text(subtitle, style: TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: _muted, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _sheetLabel(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(s,
            style: TextStyle(
              color: _muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            )),
      );

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool autofocus = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      autofocus: autofocus,
      maxLines: maxLines,
      cursorColor: _p1,
      style: const TextStyle(color: _text, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB8AEC7), fontSize: 13.5),
        filled: true,
        fillColor: const Color(0xFFFCFAFE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _p2, width: 1.6),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _sheetTarihAlani({required DateTime tarih, required ValueChanged<DateTime> onChanged}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          initialDate: tarih,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: _p1, onPrimary: Colors.white),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: _p1, size: 16),
            const SizedBox(width: 8),
            Text(_fmtDate(tarih),
                style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13.5)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _p1, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _sheetKaydetBtn({
    required String label,
    required bool yukleniyor,
    required VoidCallback onTap,
    Color? overrideColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: overrideColor == null
            ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)])
            : LinearGradient(colors: [overrideColor, overrideColor.withValues(alpha: 0.85)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (overrideColor ?? const Color(0xFF10B981)).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: yukleniyor ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: yukleniyor
                  ? const [
                      SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ]
                  : [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(label,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ozetMini(String label, String val, Color renk) {
    return Container(
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: _purpleBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(val,
              style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _odemeSatiri(Map<String, dynamic> o, {required VoidCallback onSil}) {
    final tip = (o['odeme_tipi'] ?? 'diger').toString();
    final tipMap = {'maas': ('Maaş', _p1), 'prim': ('Prim', const Color(0xFF10B981)), 'diger': ('Avans', const Color(0xFFB45309))};
    final tipBilgi = tipMap[tip] ?? ('Ödeme', _p2);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tipBilgi.$2.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(tipBilgi.$1,
                style: TextStyle(color: tipBilgi.$2, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fmtTl(_parseTrNumber(o['tutar'])),
                    style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13)),
                Text(
                  '${o['odeme_tarihi'] ?? '—'} · ${o['odeme_yontemi'] ?? '—'}',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
                if ((o['aciklama'] ?? '').toString().isNotEmpty)
                  Text(o['aciklama'].toString(),
                      style: TextStyle(color: _muted, fontSize: 11, fontStyle: FontStyle.italic),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
            onPressed: onSil,
            tooltip: 'Sil',
          ),
        ],
      ),
    );
  }

  Widget _hareketSatiri(Map<String, dynamic> h, {required VoidCallback onSil}) {
    final isBonus = h['tip'] == 'bonus';
    final accent = isBonus ? const Color(0xFF15803D) : const Color(0xFF991B1B);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: isBonus ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isBonus ? Icons.add_circle : Icons.remove_circle,
            color: accent, size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isBonus ? '+' : '-'} ${_fmtTl(_parseTrNumber(h['tutar']))}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(h['tarih']?.toString() ?? '—',
                    style: TextStyle(color: _muted, fontSize: 11)),
                if ((h['aciklama'] ?? '').toString().isNotEmpty)
                  Text(h['aciklama'].toString(),
                      style: TextStyle(color: _muted, fontSize: 11, fontStyle: FontStyle.italic),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
            onPressed: onSil,
            tooltip: 'Sil',
          ),
        ],
      ),
    );
  }

  Widget _kucukBos(String mesaj) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _purpleBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(mesaj, style: TextStyle(color: _muted, fontSize: 12)),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _snack(String msg, {required bool basari}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: basari ? const Color(0xFF15803D) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _bosKart() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, color: _muted.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 10),
          const Text('Aktif personel bulunamadı',
              style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
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
