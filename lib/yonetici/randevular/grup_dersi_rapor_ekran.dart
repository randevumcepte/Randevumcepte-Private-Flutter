// Grup dersi raporu (isletme) — ozet + egitmen/ders bazli. /api/v1/grup-dersi-rapor.
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/grup_dersi_api.dart';

const Color _mor = Color(0xFF5C008E);

class GrupDersiRaporEkran extends StatefulWidget {
  final String salonId;
  const GrupDersiRaporEkran({Key? key, required this.salonId}) : super(key: key);

  @override
  State<GrupDersiRaporEkran> createState() => _GrupDersiRaporEkranState();
}

class _GrupDersiRaporEkranState extends State<GrupDersiRaporEkran> {
  bool _yukleniyor = true;
  String? _hata;
  Map<String, dynamic> _ozet = {};
  List _egitmen = [];
  List _ders = [];
  DateTime _t1 = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _t2 = DateTime.now();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  String _ik(int n) => n.toString().padLeft(2, '0');
  String _f(DateTime d) => '${d.year}-${_ik(d.month)}-${_ik(d.day)}';

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final r = await grupDersiRapor(widget.salonId, _f(_t1), _f(_t2));
      setState(() {
        _ozet = Map<String, dynamic>.from(r['ozet'] ?? {});
        _egitmen = (r['egitmen'] as List?) ?? [];
        _ders = (r['ders'] as List?) ?? [];
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() { _hata = e.toString(); _yukleniyor = false; });
    }
  }

  Future<void> _tarihSec(bool bas) async {
    final d = await showDatePicker(
      context: context,
      initialDate: bas ? _t1 : _t2,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) { setState(() { if (bas) _t1 = d; else _t2 = d; }); _yukle(); }
  }

  int _i(dynamic v) => int.tryParse(v.toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _mor,
        elevation: 1,
        iconTheme: const IconThemeData(color: _mor),
        title: const Text('Grup Dersi Raporu', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _tarihCubugu(),
          Expanded(
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : _hata != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Yüklenemedi:\n$_hata', textAlign: TextAlign.center)))
                    : RefreshIndicator(
                        onRefresh: _yukle,
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            _tiles(),
                            const SizedBox(height: 8),
                            _tabloKart('Eğitmen Bazlı', _egitmen, egitmen: true),
                            _tabloKart('Ders Bazlı', _ders, egitmen: false),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tarihCubugu() {
    return Container(
      color: const Color(0xFFF3ECFA),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(child: _tarihKutu('Başlangıç', _f(_t1), () => _tarihSec(true))),
          const SizedBox(width: 8),
          Expanded(child: _tarihKutu('Bitiş', _f(_t2), () => _tarihSec(false))),
        ],
      ),
    );
  }

  Widget _tarihKutu(String l, String v, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l, style: const TextStyle(fontSize: 10, color: _mor, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Row(children: [const Icon(Icons.calendar_today, size: 14, color: _mor), const SizedBox(width: 6), Text(v)]),
            ],
          ),
        ),
      );

  Widget _tiles() {
    final o = _ozet;
    final tiles = [
      _tile('%${_i(o['doluluk'])}', 'Ortalama Doluluk', accent: true),
      _tile('${_i(o['oturum'])}', 'Toplam Ders'),
      _tile('${_i(o['katilim'])}', 'Toplam Katılım'),
      _tile('${_i(o['gelen'])}', 'Gelen'),
      _tile('${_i(o['gelmedi'])}', 'Gelmedi (%${_i(o['noshow'])})'),
      _tile('${_i(o['bekleme'])}', 'Bekleme'),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: tiles);
  }

  Widget _tile(String v, String l, {bool accent = false}) {
    final w = (MediaQuery.of(context).size.width - 24 - 20) / 3;
    return Container(
      width: w < 90 ? 90 : w,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: accent ? const LinearGradient(colors: [_mor, Color(0xFF7B2FB8)]) : null,
        color: accent ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE8F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent ? Colors.white : _mor)),
          const SizedBox(height: 4),
          Text(l, style: TextStyle(fontSize: 11.5, color: accent ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _tabloKart(String baslik, List veri, {required bool egitmen}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFECE8F4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _mor)),
          const SizedBox(height: 8),
          if (veri.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('Bu aralıkta ders yok.', style: TextStyle(color: Colors.grey))))
          else
            ...veri.map((e) {
              final m = Map<String, dynamic>.from(e);
              final ad = (egitmen ? m['personel'] : m['ders_tipi']).toString();
              final doluluk = _i(m['doluluk']);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(ad, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Text('%$doluluk', style: const TextStyle(fontWeight: FontWeight.bold, color: _mor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (doluluk.clamp(0, 100)) / 100,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFF3ECFA),
                        valueColor: const AlwaysStoppedAnimation(_mor),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      egitmen
                          ? '${_i(m['oturum'])} ders · ${_i(m['katilim'])} katılım · ${_i(m['gelen'])} geldi · ${_i(m['gelmedi'])} gelmedi'
                          : '${_i(m['oturum'])} oturum · ${_i(m['katilim'])} katılım · ${_i(m['gelen'])} geldi',
                      style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
