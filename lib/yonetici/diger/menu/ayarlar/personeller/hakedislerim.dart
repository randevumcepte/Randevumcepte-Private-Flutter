import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// Personelin KENDİ hakediş / maaş / prim / ödeme geçmişini gördüğü read-only ekran.
/// Web prim_hakedis_panel'in personel-self karşılığı. Yönetici ödeme ekleme yok.
/// Veriler mevcut API'lerden: primHakedisToplu (hakediş kırılımı) + primOdemeListesi
/// (dönem içi ödemeler + bonus/kesinti hareketleri).
class Hakedislerim extends StatefulWidget {
  final dynamic isletmebilgi;
  final String personelId;
  final String personelAdi;
  const Hakedislerim({
    super.key,
    required this.isletmebilgi,
    required this.personelId,
    this.personelAdi = '',
  });

  @override
  State<Hakedislerim> createState() => _HakedislerimState();
}

class _HakedislerimState extends State<Hakedislerim> {
  static const _aylar = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];
  static const _mor = Color(0xFF5C008E);

  late int _ay;
  late int _yil;
  String? _salonid;
  bool _yukleniyor = true;
  String? _hata;

  // Hakediş kırılımı
  double _maas = 0, _hizmetP = 0, _urunP = 0, _paketP = 0, _bonus = 0, _kesinti = 0;
  // Ödenenler (dönem içi)
  double _odenenMaas = 0, _odenenPrim = 0, _odenenDiger = 0;
  // Geçmiş
  List<Map<String, dynamic>> _odemeler = [];
  List<Map<String, dynamic>> _hareketler = [];

  double get _primToplam => _hizmetP + _urunP + _paketP;
  double get _netHakedis => _maas + _primToplam + _bonus - _kesinti;
  double get _odenenToplam => _odenenMaas + _odenenPrim + _odenenDiger;
  double get _kalan {
    final k = _netHakedis - _odenenToplam;
    return k < 0 ? 0 : k;
  }

  String get _durum {
    if (_odenenToplam <= 0) return 'Bekliyor';
    if (_odenenToplam + 0.01 < _netHakedis) return 'Kısmi';
    if (_odenenToplam > _netHakedis + 0.01) return 'Fazla';
    return 'Ödendi';
  }

  Color get _durumRenk {
    switch (_durum) {
      case 'Ödendi':
        return const Color(0xFF2E7D32);
      case 'Kısmi':
        return const Color(0xFFF59E0B);
      case 'Fazla':
        return const Color(0xFF1E88E5);
      default:
        return const Color(0xFF9AA3B2);
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ay = now.month;
    _yil = now.year;
    _init();
  }

  Future<void> _init() async {
    _salonid = widget.isletmebilgi?['id']?.toString() ?? await secilisalonid();
    await _yukle();
  }

  Future<void> _yukle() async {
    if (_salonid == null || widget.personelId.isEmpty) {
      setState(() {
        _yukleniyor = false;
        _hata = 'Personel/salon bilgisi alınamadı.';
      });
      return;
    }
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final ayStr = _ay.toString().padLeft(2, '0');
      final donem = '$_yil-$ayStr';

      // 1) Hakediş kırılımı — tüm personel döner, kendi satırımızı buluruz.
      final toplu = await primHakedisToplu(
          salonid: _salonid!, ay: ayStr, yil: _yil.toString());
      Map<String, dynamic>? benim;
      if (toplu['basarili'] == true) {
        final list = (toplu['personeller'] as List?) ?? const [];
        for (final m in list) {
          final map = Map<String, dynamic>.from(m as Map);
          final id = (map['id'] ?? map['personel_id']).toString();
          if (id == widget.personelId) {
            benim = map;
            break;
          }
        }
      }

      _maas = _sayi(benim?['maas']);
      _hizmetP = _sayi(benim?['hizmet_hakedis']);
      _urunP = _sayi(benim?['urun_hakedis']);
      _paketP = _sayi(benim?['paket_hakedis']);
      _bonus = _sayi(benim?['bonus']);
      _kesinti = _sayi(benim?['kesinti']);
      _odenenMaas = _sayi(benim?['odenen_maas']);
      _odenenPrim = _sayi(benim?['odenen_prim']);
      _odenenDiger = _sayi(benim?['odenen_diger']);

      // 2) Dönem içi ödeme + bonus/kesinti geçmişi
      final liste = await primOdemeListesi(
          salonid: _salonid!, personelid: widget.personelId, donem: donem);
      _odemeler = [];
      _hareketler = [];
      if (liste != null) {
        for (final o in (liste['odemeler'] as List?) ?? const []) {
          _odemeler.add(Map<String, dynamic>.from(o as Map));
        }
        for (final h in (liste['hareketler'] as List?) ?? const []) {
          _hareketler.add(Map<String, dynamic>.from(h as Map));
        }
        // Ödenen toplamları liste toplamlarıyla doğrula (varsa)
        final t = liste['toplamlar'];
        if (t is Map) {
          _odenenMaas = _sayi(t['maas']);
          _odenenPrim = _sayi(t['prim']);
          _odenenDiger = _sayi(t['diger']);
        }
      }
    } catch (e) {
      _hata = 'Veri alınırken hata: $e';
    }
    if (!mounted) return;
    setState(() => _yukleniyor = false);
  }

  void _ayDegis(int delta) {
    var ay = _ay + delta;
    var yil = _yil;
    if (ay < 1) {
      ay = 12;
      yil--;
    } else if (ay > 12) {
      ay = 1;
      yil++;
    }
    setState(() {
      _ay = ay;
      _yil = yil;
    });
    _yukle();
  }

  // ── Yardımcılar ──────────────────────────────────────────
  double _sayi(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    var s = v.toString().trim();
    if (s.isEmpty) return 0;
    if (s.contains(',')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(s) ?? 0;
  }

  String _tl(double v) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(2);
    final parts = s.split('.');
    final buf = StringBuffer();
    final ip = parts[0];
    for (int i = 0; i < ip.length; i++) {
      if (i > 0 && (ip.length - i) % 3 == 0) buf.write('.');
      buf.write(ip[i]);
    }
    return '${neg ? '-' : ''}${buf.toString()},${parts[1]} ₺';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Hakedişlerim',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _ayBar(),
          Expanded(
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : _hata != null
                    ? _hataView()
                    : RefreshIndicator(
                        onRefresh: _yukle,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          children: [
                            _netKart(),
                            const SizedBox(height: 12),
                            _kirilimKart(),
                            const SizedBox(height: 12),
                            _odemeDurumKart(),
                            const SizedBox(height: 12),
                            _gecmisOdemeler(),
                            if (_hareketler.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _hareketlerKart(),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _ayBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _ayDegis(-1),
          ),
          Expanded(
            child: Center(
              child: Text('${_aylar[_ay - 1]} $_yil',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _ayDegis(1),
          ),
        ],
      ),
    );
  }

  Widget _hataView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(_hata!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _yukle, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );

  Widget _kart({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _mor.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _netKart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF5C008E), Color(0xFF7B2FB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Net Hakediş',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_durum,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_tl(_netHakedis),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            children: [
              _netAlt('Ödenen', _tl(_odenenToplam)),
              const SizedBox(width: 20),
              _netAlt('Kalan', _tl(_kalan)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _netAlt(String l, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 2),
          Text(v,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _satir(String l, double v, {Color? renk, bool kalin = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(l,
                  style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.black87,
                      fontWeight: kalin ? FontWeight.w700 : FontWeight.w500)),
            ),
            Text(_tl(v),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: renk ?? Colors.black87)),
          ],
        ),
      );

  Widget _kirilimKart() {
    return _kart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hakediş Kırılımı',
              style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w700)),
          const Divider(height: 18),
          _satir('Maaş', _maas),
          _satir('Hizmet Primi', _hizmetP),
          _satir('Ürün Primi', _urunP),
          _satir('Paket Primi', _paketP),
          if (_bonus != 0) _satir('Bonus', _bonus, renk: const Color(0xFF2E7D32)),
          if (_kesinti != 0) _satir('Kesinti', -_kesinti, renk: const Color(0xFFD32F2F)),
          const Divider(height: 18),
          _satir('Net Hakediş', _netHakedis, kalin: true, renk: _mor),
        ],
      ),
    );
  }

  Widget _odemeDurumKart() {
    return _kart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ödeme Durumu',
              style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w700)),
          const Divider(height: 18),
          _satir('Ödenen Maaş', _odenenMaas),
          _satir('Ödenen Prim', _odenenPrim),
          if (_odenenDiger != 0) _satir('Diğer / Avans', _odenenDiger),
          const Divider(height: 18),
          _satir('Toplam Ödenen', _odenenToplam, kalin: true),
          _satir('Kalan', _kalan, kalin: true, renk: _kalan > 0 ? const Color(0xFFF59E0B) : const Color(0xFF2E7D32)),
        ],
      ),
    );
  }

  Widget _gecmisOdemeler() {
    return _kart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Geçmiş Ödemeler',
                  style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${_odemeler.length} kayıt',
                  style: const TextStyle(fontSize: 11, color: Colors.black38)),
            ],
          ),
          const Divider(height: 18),
          if (_odemeler.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Bu dönemde ödeme kaydı yok.',
                  style: TextStyle(color: Colors.black45, fontSize: 13)),
            )
          else
            ..._odemeler.map((o) {
              final tip = (o['odeme_tipi'] ?? '').toString();
              final tipAd = tip == 'maas'
                  ? 'Maaş'
                  : tip == 'prim'
                      ? 'Prim'
                      : tip == 'diger'
                          ? 'Diğer / Avans'
                          : (tip.isEmpty ? 'Ödeme' : tip);
              final tarih = (o['odeme_tarihi'] ?? '').toString();
              final yontem = (o['odeme_yontemi'] ?? '').toString();
              final aciklama = (o['aciklama'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _mor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.payments_outlined, color: _mor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tipAd,
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w700)),
                          Text(
                            [
                              _trTarih(tarih),
                              if (yontem.isNotEmpty && yontem != 'null') yontem,
                            ].join(' · '),
                            style: const TextStyle(
                                fontSize: 11.5, color: Colors.black54),
                          ),
                          if (aciklama.isNotEmpty && aciklama != 'null')
                            Text(aciklama,
                                style: const TextStyle(
                                    fontSize: 11.5, color: Colors.black45)),
                        ],
                      ),
                    ),
                    Text(_tl(_sayi(o['tutar'])),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _hareketlerKart() {
    return _kart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bonus / Kesinti',
              style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w700)),
          const Divider(height: 18),
          ..._hareketler.map((h) {
            final bonus = (h['tip'] ?? '').toString() == 'bonus';
            final tutar = _sayi(h['tutar']);
            final tarih = (h['tarih'] ?? '').toString();
            final aciklama = (h['aciklama'] ?? '').toString();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(bonus ? Icons.add_circle_outline : Icons.remove_circle_outline,
                      size: 18,
                      color: bonus ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bonus ? 'Bonus' : 'Kesinti',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(
                          [
                            _trTarih(tarih),
                            if (aciklama.isNotEmpty && aciklama != 'null') aciklama,
                          ].join(' · '),
                          style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Text('${bonus ? '+' : '-'}${_tl(tutar)}',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: bonus ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _trTarih(String iso) {
    // 'YYYY-MM-DD' -> 'DD.MM.YYYY'
    if (iso.length >= 10 && iso[4] == '-') {
      return '${iso.substring(8, 10)}.${iso.substring(5, 7)}.${iso.substring(0, 4)}';
    }
    return iso;
  }
}
