// Danisan (musteri) grup dersi ONLINE REZERVASYON ekrani.
// Salonun rezervasyona uygun (dolu olmayan, gelecek) derslerini listeler; danisan
// bir derse rezervasyon yapar (hak zorunlu -> backend kontrol eder).
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/grup_dersi_api.dart';

const Color _mor = Color(0xFF5C008E);
const List<String> _gunAd = [
  '', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
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
  bool _degisti = false; // en az bir rezervasyon yapildi mi (geri donunce yenile)
  List<Map<String, dynamic>> _dersler = [];
  final Set<int> _islemde = {};

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final r = await grupDersleriUygun(widget.salonId);
      if (!mounted) return;
      setState(() {
        _dersler = r;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = 'Dersler yüklenemedi.';
        _yukleniyor = false;
      });
    }
  }

  String _gunEtiket(String tarih) {
    try {
      final d = DateTime.parse(tarih);
      final bugun = DateTime.now();
      final fark = DateTime(d.year, d.month, d.day)
          .difference(DateTime(bugun.year, bugun.month, bugun.day))
          .inDays;
      final gun = _gunAd[d.weekday];
      final tarihStr =
          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
      if (fark == 0) return 'Bugün • $gun $tarihStr';
      if (fark == 1) return 'Yarın • $gun $tarihStr';
      return '$gun • $tarihStr';
    } catch (_) {
      return tarih;
    }
  }

  Future<void> _rezervasyon(Map<String, dynamic> d) async {
    final oturumId = int.tryParse(d['id'].toString()) ?? 0;
    if (oturumId == 0) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rezervasyon'),
        content: Text(
            '${d['ders_tipi']} • ${_gunEtiket(d['tarih'].toString())} ${d['saat']}\n\n'
            'Bu derse rezervasyon yapmak istiyor musunuz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Vazgeç')),
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
        await _yukle(); // doluluk guncellensin
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
                : _dersler.isEmpty
                    ? _durumMesaji('Şu an rezervasyona uygun ders yok.',
                        Icons.event_busy_outlined)
                    : RefreshIndicator(
                        color: _mor,
                        onRefresh: _yukle,
                        child: _liste(),
                      ),
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
          Text(mesaj,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          if (tekrar) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: _yukle, child: const Text('Tekrar dene')),
          ],
        ],
      ),
    );
  }

  Widget _liste() {
    // Tarihe gore grupla
    final Map<String, List<Map<String, dynamic>>> gruplu = {};
    for (final d in _dersler) {
      final t = d['tarih'].toString();
      gruplu.putIfAbsent(t, () => []).add(d);
    }
    final tarihler = gruplu.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        for (final t in tarihler) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Text(_gunEtiket(t),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14, color: _mor)),
          ),
          for (final d in gruplu[t]!) _dersKart(d),
        ],
      ],
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
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
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
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12.5)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.groups_outlined,
                        size: 15, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('$doluluk/$kapasite dolu',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    Text(dolu ? 'Dolu' : '$bos yer kaldı',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: dolu
                                ? Colors.redAccent
                                : const Color(0xFF059669))),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: islemde
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(dolu ? 'Dolu' : 'Rezervasyon',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
