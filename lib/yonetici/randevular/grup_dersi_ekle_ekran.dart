// Grup dersi olustur / duzenle ekrani (tek seferlik ders veya mevcut oturum duzenleme).
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/grup_dersi_api.dart';
import 'package:randevu_sistem/Models/grup_dersi.dart';

const Color _mor = Color(0xFF5C008E);

class GrupDersiEkleEkran extends StatefulWidget {
  final String salonId;
  final Map isletmebilgi;
  final GrupDersOturum? duzenlenecek; // null ise yeni
  final DateTime? onSecilenTarih;     // takvimden gelen tarih (yeni icin)
  const GrupDersiEkleEkran({
    Key? key,
    required this.salonId,
    required this.isletmebilgi,
    this.duzenlenecek,
    this.onSecilenTarih,
  }) : super(key: key);

  @override
  State<GrupDersiEkleEkran> createState() => _GrupDersiEkleEkranState();
}

class _GrupDersiEkleEkranState extends State<GrupDersiEkleEkran> {
  bool _yukleniyor = true;
  bool _kaydediyor = false;
  List<GrupDersSecenek> _personeller = [];
  List<GrupDersSecenek> _hizmetler = [];

  final _dersTipiC = TextEditingController();
  final _kapasiteC = TextEditingController(text: '3');
  String? _personelId;
  String? _hizmetId;
  DateTime _tarih = DateTime.now();
  TimeOfDay _saat = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _bitis = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    final d = widget.duzenlenecek;
    if (d != null) {
      _dersTipiC.text = d.dersTipi;
      _kapasiteC.text = d.kapasite.toString();
      _personelId = d.personelId;
      _hizmetId = d.hizmetId;
      _tarih = DateTime.tryParse(d.tarih) ?? DateTime.now();
      _saat = _parseSaat(d.saat, const TimeOfDay(hour: 9, minute: 0));
      _bitis = _parseSaat(d.saatBitis, const TimeOfDay(hour: 10, minute: 0));
    } else if (widget.onSecilenTarih != null) {
      _tarih = widget.onSecilenTarih!;
    }
    _yukle();
  }

  TimeOfDay _parseSaat(String s, TimeOfDay def) {
    try {
      final p = s.split(':');
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    } catch (_) {
      return def;
    }
  }

  Future<void> _yukle() async {
    try {
      final r = await dersProgramiListe(widget.salonId);
      setState(() {
        _personeller = (r['personeller'] as List).cast<GrupDersSecenek>();
        _hizmetler = (r['hizmetler'] as List).cast<GrupDersSecenek>();
        _yukleniyor = false;
      });
    } catch (_) {
      setState(() => _yukleniyor = false);
    }
  }

  String _ikiHane(int n) => n.toString().padLeft(2, '0');
  String _saatStr(TimeOfDay t) => '${_ikiHane(t.hour)}:${_ikiHane(t.minute)}';
  String _tarihStr(DateTime d) => '${d.year}-${_ikiHane(d.month)}-${_ikiHane(d.day)}';

  Future<void> _kaydet() async {
    if (_dersTipiC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ders tipi girin (örn. Reformer)')));
      return;
    }
    setState(() => _kaydediyor = true);
    try {
      await dersOturumKaydet(
        salonId: widget.salonId,
        oturumId: widget.duzenlenecek?.id,
        dersTipi: _dersTipiC.text.trim(),
        personelId: _personelId,
        hizmetId: _hizmetId,
        tarih: _tarihStr(_tarih),
        saat: _saatStr(_saat),
        saatBitis: _saatStr(_bitis),
        kapasite: int.tryParse(_kapasiteC.text) ?? 1,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _kaydediyor = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _mor,
        title: Text(widget.duzenlenecek == null ? 'Grup Dersi Ekle' : 'Grup Dersi Düzenle'),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Kapasiteli grup dersi. Hizmet seçerseniz "Geldi"de paketten seans düşer ve ders online rezervasyona açılır.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black54)),
                ),
                _label('Ders Tipi'),
                TextField(controller: _dersTipiC, decoration: _dec('Reformer / Mat / Crossfit / Birebir')),
                const SizedBox(height: 12),
                _label('Eğitmen'),
                DropdownButtonFormField<String>(
                  value: _personelId,
                  isExpanded: true,
                  decoration: _dec('— Seçiniz —'),
                  items: _personeller.map((p) => DropdownMenuItem(value: p.id, child: Text(p.ad))).toList(),
                  onChanged: (v) => setState(() => _personelId = v),
                ),
                const SizedBox(height: 12),
                _label('Hizmet (paket düşümü için)'),
                DropdownButtonFormField<String>(
                  value: _hizmetId,
                  isExpanded: true,
                  decoration: _dec('— Hizmet bağlama (paket düşmez) —'),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('— Hizmet bağlama (paket düşmez) —')),
                    ..._hizmetler.map((h) => DropdownMenuItem(value: h.id, child: Text(h.ad))),
                  ],
                  onChanged: (v) => setState(() => _hizmetId = v),
                ),
                const SizedBox(height: 12),
                _label('Tarih'),
                _secimKutu(_tarihStr(_tarih), Icons.calendar_today, () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _tarih,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _tarih = d);
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Başlangıç'),
                        _secimKutu(_saatStr(_saat), Icons.access_time, () async {
                          final t = await showTimePicker(context: context, initialTime: _saat);
                          if (t != null) setState(() => _saat = t);
                        }),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Bitiş'),
                        _secimKutu(_saatStr(_bitis), Icons.access_time, () async {
                          final t = await showTimePicker(context: context, initialTime: _bitis);
                          if (t != null) setState(() => _bitis = t);
                        }),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _label('Kapasite (kişi)'),
                TextField(controller: _kapasiteC, keyboardType: TextInputType.number, decoration: _dec('3')),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _mor),
                    icon: _kaydediyor
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: const Text('Kaydet'),
                    onPressed: _kaydediyor ? null : _kaydet,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: const OutlineInputBorder(),
        isDense: true,
      );

  Widget _secimKutu(String metin, IconData ikon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD7DDE3)), borderRadius: BorderRadius.circular(4)),
          child: Row(children: [Icon(ikon, size: 18, color: _mor), const SizedBox(width: 8), Text(metin)]),
        ),
      );
}
