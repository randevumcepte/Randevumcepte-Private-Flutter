import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// Reklam Raporu — web reklam-detay-modal paritesi.
/// Sekmeler: Tümü / İndirim Kullanan / İndirim Kullanmayan / Beklenenler.
class ReklamRaporu extends StatefulWidget {
  final dynamic isletmebilgi;
  final dynamic kampanyaId;
  const ReklamRaporu({Key? key, required this.isletmebilgi, required this.kampanyaId}) : super(key: key);

  @override
  State<ReklamRaporu> createState() => _ReklamRaporuState();
}

class _ReklamRaporuState extends State<ReklamRaporu> {
  static const Color _mor = Color(0xFF7B2FB8);

  String? _salonId;
  bool _yukleniyor = true;
  Map<String, dynamic> _ozet = {};

  // Sekme -> katilimDurumu: Tumu=1, Indirim Kullanan=2, Kullanmayan=3, Beklenen=4
  static const List<Map<String, dynamic>> _sekmeler = [
    {'ad': 'Tümü', 'tur': 1},
    {'ad': 'İndirim Kullanan', 'tur': 2},
    {'ad': 'İndirim Kullanmayan', 'tur': 3},
    {'ad': 'Beklenenler', 'tur': 4},
  ];

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    _salonId = await secilisalonid();
    if (_salonId != null) {
      final res = await kampanyaDetayGetir(_salonId!, widget.kampanyaId, katilimDurumu: 1);
      if (res != null && res['kampanya'] is Map) {
        _ozet = Map<String, dynamic>.from(res['kampanya'] as Map);
      }
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _sekmeler.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: _mor,
          title: const Text('Reklam Raporu'),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: _sekmeler.map((s) => Tab(text: s['ad'].toString())).toList(),
          ),
        ),
        body: _yukleniyor
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _ozetKartlari(),
                  Expanded(
                    child: TabBarView(
                      children: _sekmeler
                          .map((s) => _KatilimciListesi(
                                key: ValueKey(s['tur']),
                                salonId: _salonId!,
                                kampanyaId: widget.kampanyaId,
                                katilimDurumu: s['tur'] as int,
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _ozetKartlari() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ozetKart(Icons.assignment, 'Görev', '${_ozet['gorev_turu'] ?? '-'}'),
          _ozetKart(Icons.campaign, 'Kampanya', '${_ozet['paket_isim'] ?? '-'}'),
          _ozetKart(Icons.inventory_2, 'Hizmet/Ürün', '${(_ozet['hizmet_adi'] ?? '').toString().isEmpty ? '-' : _ozet['hizmet_adi']}'),
          _ozetKart(Icons.people, 'Katılımcı', '${_ozet['katilimci_sayisi'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _ozetKart(IconData ikon, String baslik, String deger) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: _mor.withOpacity(0.12), child: Icon(ikon, size: 18, color: _mor)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                Text(deger, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KatilimciListesi extends StatefulWidget {
  final String salonId;
  final dynamic kampanyaId;
  final int katilimDurumu;
  const _KatilimciListesi({Key? key, required this.salonId, required this.kampanyaId, required this.katilimDurumu}) : super(key: key);

  @override
  State<_KatilimciListesi> createState() => _KatilimciListesiState();
}

class _KatilimciListesiState extends State<_KatilimciListesi> with AutomaticKeepAliveClientMixin {
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _kayitlar = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final res = await kampanyaDetayGetir(widget.salonId, widget.kampanyaId, katilimDurumu: widget.katilimDurumu);
    if (res != null && res['data'] is List) {
      _kayitlar = (res['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  Color _durumRengi(String durum) {
    if (durum.contains('Katıldı')) return Colors.green;
    if (durum.contains('Katılmadı') || durum.contains('Ulaşılamadı')) return Colors.red;
    if (durum.contains('Aranıyor')) return Colors.blue;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_yukleniyor) return const Center(child: CircularProgressIndicator());
    if (_kayitlar.isEmpty) {
      return const Center(child: Text('Kayıt bulunmamaktadır', style: TextStyle(color: Colors.black45)));
    }
    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: _kayitlar.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final k = _kayitlar[i];
          final durum = (k['durum'] ?? '').toString();
          final kullanildi = (k['indirim_kodu_kullanildi'] ?? 0) == 1;
          return ListTile(
            title: Text((k['ad_soyad'] ?? '').toString()),
            subtitle: Text((k['telefon'] ?? '').toString()),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _durumRengi(durum).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(durum, style: TextStyle(color: _durumRengi(durum), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                if (kullanildi)
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text('🎟️ Kod kullanıldı', style: TextStyle(fontSize: 10, color: Colors.green)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
