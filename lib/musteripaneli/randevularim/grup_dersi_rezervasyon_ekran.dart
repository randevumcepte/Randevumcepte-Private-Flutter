// Danisan (musteri) grup dersi ONLINE REZERVASYON ekrani.
// Ust kisimda 1 aylik yatay tarih secici (randevu alma gibi); secilen gunun
// rezervasyona uygun derslerini altta listeler. Rezervasyon hak/paket ZORUNLU DEGIL.
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/grup_dersi_api.dart';

const Color _mor = Color(0xFF5C008E);
const List<String> _gunKisa = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const List<String> _gunAd = [
  '', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
];
const List<String> _ayAd = [
  '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
];

class GrupDersiRezervasyonEkran extends StatefulWidget {
  final String userId;
  final String salonId;
  const GrupDersiRezervasyonEkran(
      {Key? key, required this.userId, required this.salonId})
      : super(key: key);

  @override
  State<GrupDersiRezervasyonEkran> createState() =>
      _GrupDersiRezervasyonEkranState();
}

class _GrupDersiRezervasyonEkranState extends State<GrupDersiRezervasyonEkran> {
  bool _yukleniyor = true;
  String? _hata;
  bool _degisti = false;
  List<Map<String, dynamic>> _dersler = [];
  final Set<int> _islemde = {};

  late DateTime _bugun;
  late DateTime _seciliGun;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _bugun = DateTime(n.year, n.month, n.day);
    _seciliGun = _bugun;
    _yukle();
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final r = await grupDersleriUygun(widget.salonId);
      if (!mounted) return;
      // Ilk ders olan gunu otomatik sec (bugun bos olabilir).
      DateTime? ilkDersGun;
      for (final d in r) {
        final t = DateTime.tryParse(d['tarih'].toString());
        if (t != null) {
          final g = DateTime(t.year, t.month, t.day);
          if (ilkDersGun == null || g.isBefore(ilkDersGun)) ilkDersGun = g;
        }
      }
      setState(() {
        _dersler = r;
        _yukleniyor = false;
        if (ilkDersGun != null && !_gunDersVar(_seciliGun)) {
          _seciliGun = ilkDersGun;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hata = 'Dersler yüklenemedi.';
        _yukleniyor = false;
      });
    }
  }

  bool _gunDersVar(DateTime g) => _dersler.any((d) => d['tarih'].toString() == _ymd(g));

  List<Map<String, dynamic>> _seciliGunDersleri() {
    final t = _ymd(_seciliGun);
    final l = _dersler.where((d) => d['tarih'].toString() == t).toList();
    l.sort((a, b) => a['saat'].toString().compareTo(b['saat'].toString()));
    return l;
  }

  Future<void> _rezervasyon(Map<String, dynamic> d) async {
    final oturumId = int.tryParse(d['id'].toString()) ?? 0;
    if (oturumId == 0) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rezervasyon'),
        content: Text('${d['ders_tipi']} • ${_gunAd[_seciliGun.weekday]} '
            '${_seciliGun.day} ${_ayAd[_seciliGun.month]} ${d['saat']}\n\n'
            'Bu derse rezervasyon yapmak istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Evet, rezervasyon yap',
                  style: TextStyle(color: _mor, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (onay != true) return;
    setState(() => _islemde.add(oturumId));
    try {
      final res = await grupDersiRezervasyonYap(
          widget.salonId, oturumId, int.parse(widget.userId));
      if (!mounted) return;
      final ok = res['durum'] == 'ok';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Rezervasyonunuz alındı.'
            : (res['mesaj']?.toString() ?? 'Rezervasyon yapılamadı.')),
        backgroundColor: ok ? const Color(0xFF059669) : Colors.redAccent,
      ));
      if (ok) {
        _degisti = true;
        await _yukle();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('İşlem başarısız.'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _islemde.remove(oturumId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _degisti);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F4FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _mor,
          elevation: 0.5,
          title: const Text('Ders Rezervasyonu',
              style: TextStyle(color: _mor, fontWeight: FontWeight.w800)),
        ),
        body: _yukleniyor
            ? const Center(child: CircularProgressIndicator(color: _mor))
            : _hata != null
                ? _durumMesaji(_hata!, Icons.error_outline, tekrar: true)
                : Column(
                    children: [
                      _tarihStrip(),
                      const Divider(height: 1),
                      Expanded(child: _gunListesi()),
                    ],
                  ),
      ),
    );
  }

  // ── 1 aylik yatay tarih secici ──
  Widget _tarihStrip() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_ayAd[_seciliGun.month]} ${_seciliGun.year}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: _mor, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 66,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 30,
              itemBuilder: (c, i) {
                final g = _bugun.add(Duration(days: i));
                final secili = _ymd(g) == _ymd(_seciliGun);
                final dersVar = _gunDersVar(g);
                return GestureDetector(
                  onTap: () => setState(() => _seciliGun = g),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: secili ? _mor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: secili ? _mor : const Color(0xFFE5E0EF)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_gunKisa[g.weekday],
                            style: TextStyle(
                                fontSize: 11,
                                color: secili ? Colors.white70 : Colors.grey.shade500)),
                        const SizedBox(height: 3),
                        Text('${g.day}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: secili ? Colors.white : const Color(0xFF2C3E50))),
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dersVar
                                ? (secili ? Colors.white : const Color(0xFF059669))
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _gunListesi() {
    final gunun = _seciliGunDersleri();
    if (gunun.isEmpty) {
      return _durumMesaji('Bu gün için rezervasyona uygun ders yok.',
          Icons.event_busy_outlined);
    }
    return RefreshIndicator(
      color: _mor,
      onRefresh: _yukle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [for (final d in gunun) _dersKart(d)],
      ),
    );
  }

  Widget _durumMesaji(String mesaj, IconData ikon, {bool tekrar = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(mesaj, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          if (tekrar) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: _yukle, child: const Text('Tekrar dene')),
          ],
        ],
      ),
    );
  }

  Widget _dersKart(Map<String, dynamic> d) {
    final kapasite = int.tryParse(d['kapasite'].toString()) ?? 0;
    final doluluk = int.tryParse(d['doluluk'].toString()) ?? 0;
    final bos = int.tryParse(d['bos'].toString()) ?? (kapasite - doluluk);
    final oturumId = int.tryParse(d['id'].toString()) ?? 0;
    final dolu = bos <= 0;
    final islemde = _islemde.contains(oturumId);
    final egitmen = (d['egitmen'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE7F4)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _mor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text('${d['saat']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: _mor, fontSize: 13)),
                if ((d['saat_bitis'] ?? '').toString().isNotEmpty)
                  Text('${d['saat_bitis']}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${d['ders_tipi']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5)),
                if (egitmen.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(egitmen,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.groups_outlined, size: 15, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('$doluluk/$kapasite dolu',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    Text(dolu ? 'Dolu' : '$bos yer kaldı',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: dolu ? Colors.redAccent : const Color(0xFF059669))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: (dolu || islemde) ? null : () => _rezervasyon(d),
              style: ElevatedButton.styleFrom(
                backgroundColor: _mor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: islemde
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(dolu ? 'Dolu' : 'Rezervasyon',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
