// Danisan (musteri) grup derslerim ekrani — dahil oldugu dersleri gorur, gecmis
// derslerde kendisi "Geldim" isaretleyebilir (paketten dusum tetiklenir).
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/grup_dersi_api.dart';

const Color _mor = Color(0xFF5C008E);
const List<String> _gunAd = ['', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

class GrupDerslerimEkran extends StatefulWidget {
  final String userId; // musteri (danisan) id
  const GrupDerslerimEkran({Key? key, required this.userId}) : super(key: key);

  @override
  State<GrupDerslerimEkran> createState() => _GrupDerslerimEkranState();
}

class _GrupDerslerimEkranState extends State<GrupDerslerimEkran> {
  bool _yukleniyor = true;
  String? _hata;
  List<Map<String, dynamic>> _dersler = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final r = await danisanGrupDerslerim(widget.userId);
      setState(() { _dersler = r; _yukleniyor = false; });
    } catch (e) {
      setState(() { _hata = e.toString(); _yukleniyor = false; });
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _geldim(Map<String, dynamic> d) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Katıldım'),
        content: Text('${d['ders_tipi']} (${d['tarih']} ${d['saat']}) dersine katıldığınızı bildiriyorsunuz. Onaylıyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Evet, katıldım')),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await danisanDersGeldim(widget.userId, int.parse(d['katilimci_id'].toString()));
      _snack('Katılımınız kaydedildi ✨');
      await _yukle();
    } catch (e) {
      _snack('Hata: $e');
    }
  }

  String _durumEtiket(String d) {
    switch (d) {
      case 'geldi': return 'Katıldınız';
      case 'gelmedi': return 'Gelmediniz';
      case 'bekleme': return 'Bekleme listesi';
      default: return 'Rezerve';
    }
  }

  Color _durumRenk(String d) {
    switch (d) {
      case 'geldi': return const Color(0xFF059669);
      case 'gelmedi': return const Color(0xFFEF4444);
      case 'bekleme': return const Color(0xFFF59E0B);
      default: return _mor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _mor,
        elevation: 1,
        iconTheme: const IconThemeData(color: _mor),
        title: const Text('Grup Derslerim', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w700)),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Yüklenemedi:\n$_hata', textAlign: TextAlign.center)))
              : _dersler.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Kayıtlı olduğunuz grup dersi bulunmuyor.', style: TextStyle(color: Colors.grey))))
                  : RefreshIndicator(
                      onRefresh: _yukle,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _dersler.length,
                        itemBuilder: (_, i) => _kart(_dersler[i]),
                      ),
                    ),
    );
  }

  Widget _kart(Map<String, dynamic> d) {
    final durum = (d['durum'] ?? 'rezerve').toString();
    final gecmis = d['gecmis'] == true;
    final geldimGoster = d['geldim_isaretleyebilir'] == true;
    int iso = 1;
    try { iso = DateTime.parse(d['tarih'].toString()).weekday; } catch (_) {}
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE8F4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(d['ders_tipi'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _mor))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _durumRenk(durum).withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                child: Text(_durumEtiket(durum), style: TextStyle(color: _durumRenk(durum), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('📅 ${d['tarih']} ${_gunAd[iso]}  🕒 ${d['saat']} - ${d['saat_bitis']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          if ((d['personel'] ?? '').toString().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 2), child: Text('👤 ${d['personel']}', style: const TextStyle(color: Colors.black54, fontSize: 13))),
          if ((d['salon_adi'] ?? '').toString().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 2), child: Text('📍 ${d['salon_adi']}', style: const TextStyle(color: Colors.black45, fontSize: 12.5))),
          if (geldimGoster)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Katıldım'),
                  onPressed: () => _geldim(d),
                ),
              ),
            )
          else if (gecmis && durum == 'rezerve')
            const Padding(padding: EdgeInsets.only(top: 8), child: Text('Katılım işaretlenmedi', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }
}
