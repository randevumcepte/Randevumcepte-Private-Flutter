// Ders Programi (haftalik sablon) ekrani — sablon tanimla + "Programi Yayinla".
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/grup_dersi_api.dart';
import 'package:randevu_sistem/Models/grup_dersi.dart';

const Color _mor = Color(0xFF5C008E);
const List<String> _gunAd = ['', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

class DersProgramiEkran extends StatefulWidget {
  final String salonId;
  final Map isletmebilgi;
  const DersProgramiEkran({Key? key, required this.salonId, required this.isletmebilgi}) : super(key: key);

  @override
  State<DersProgramiEkran> createState() => _DersProgramiEkranState();
}

class _DersProgramiEkranState extends State<DersProgramiEkran> {
  bool _yukleniyor = true;
  List<GrupDersSecenek> _personeller = [];
  List<GrupDersSecenek> _hizmetler = [];
  List<GrupDersSablon> _sablon = [];
  DateTime _baslangic = DateTime.now();
  int _hafta = 4;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final r = await dersProgramiListe(widget.salonId);
      setState(() {
        _personeller = (r['personeller'] as List).cast<GrupDersSecenek>();
        _hizmetler = (r['hizmetler'] as List).cast<GrupDersSecenek>();
        _sablon = (r['sablon'] as List).cast<GrupDersSablon>();
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() => _yukleniyor = false);
      _snack('Yüklenemedi: $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _ik(int n) => n.toString().padLeft(2, '0');

  Future<void> _yayinla() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Programı Yayınla'),
        content: Text('${_baslangic.year}-${_ik(_baslangic.month)}-${_ik(_baslangic.day)} tarihinden itibaren $_hafta hafta boyunca ders oturumları takvime oluşturulacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yayınla')),
        ],
      ),
    );
    if (onay != true) return;
    try {
      final r = await dersProgramiYayinla(widget.salonId, '${_baslangic.year}-${_ik(_baslangic.month)}-${_ik(_baslangic.day)}', _hafta);
      _snack('${r['olusan']} yeni ders oluşturuldu (${r['atlanan']} zaten vardı).');
    } catch (e) {
      _snack('Hata: $e');
    }
  }

  Future<void> _sablonDuzenle({GrupDersSablon? mevcut, int? gun}) async {
    final sonuc = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SablonSheet(
        salonId: widget.salonId,
        personeller: _personeller,
        hizmetler: _hizmetler,
        mevcut: mevcut,
        varsayilanGun: gun ?? 1,
      ),
    );
    if (sonuc == true) await _yukle();
  }

  Future<void> _sablonSil(GrupDersSablon s) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: const Text('Bu program satırı silinecek; katılımcısı olmayan gelecek dersler de kaldırılacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await dersSablonSil(widget.salonId, s.id);
      await _yukle();
    } catch (e) {
      _snack('Hata: $e');
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
        title: const Text('Ders Programı', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w700)),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _yayinlaCubugu(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: List.generate(7, (i) => _gunBolumu(i + 1)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _yayinlaCubugu() {
    return Container(
      color: const Color(0xFFF3ECFA),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _baslangic,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _baslangic = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 15, color: _mor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('${_baslangic.year}-${_ik(_baslangic.month)}-${_ik(_baslangic.day)}',
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 104,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _hafta,
                isExpanded: true,
                isDense: true,
                items: List.generate(12, (i) => i + 1)
                    .map((h) => DropdownMenuItem(value: h, child: Text('$h hafta')))
                    .toList(),
                onChanged: (v) => setState(() => _hafta = v ?? 4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _mor,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.rocket_launch, size: 17),
            label: const Text('Yayınla'),
            onPressed: _yayinla,
          ),
        ],
      ),
    );
  }

  Widget _gunBolumu(int gun) {
    final dersler = _sablon.where((s) => s.haftaGunu == gun).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFECE8F4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFF3ECFA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFECE8F4))),
            ),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: _mor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(_gunAd[gun], style: const TextStyle(color: _mor, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ...dersler.map((s) => _dersSatiri(s)),
                InkWell(
                  onTap: () => _sablonDuzenle(gun: gun),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFB7CCE0), style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
                    child: const Text('＋ Ders Ekle', textAlign: TextAlign.center, style: TextStyle(color: _mor, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dersSatiri(GrupDersSablon s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFFAF5FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFECE8F4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(s.dersTipi, style: const TextStyle(fontWeight: FontWeight.bold, color: _mor))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _mor, borderRadius: BorderRadius.circular(999)),
                child: Text('${s.kapasite} kişi', style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('🕒 ${s.saat} - ${s.saatBitis}', style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          Text('👤 ${s.personel.isEmpty ? "—" : s.personel}', style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          Text(s.hizmetId == null ? 'paket bağlı değil' : 'paket düşer',
              style: TextStyle(fontSize: 11, color: s.hizmetId == null ? Colors.grey : const Color(0xFF2471A3))),
          Row(
            children: [
              TextButton.icon(onPressed: () => _sablonDuzenle(mevcut: s), icon: const Icon(Icons.edit, size: 16), label: const Text('Düzenle')),
              TextButton.icon(onPressed: () => _sablonSil(s), icon: const Icon(Icons.delete, size: 16, color: Colors.red), label: const Text('Sil', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }
}

// Sablon ekle/duzenle bottom sheet
class _SablonSheet extends StatefulWidget {
  final String salonId;
  final List<GrupDersSecenek> personeller;
  final List<GrupDersSecenek> hizmetler;
  final GrupDersSablon? mevcut;
  final int varsayilanGun;
  const _SablonSheet({
    Key? key,
    required this.salonId,
    required this.personeller,
    required this.hizmetler,
    required this.mevcut,
    required this.varsayilanGun,
  }) : super(key: key);
  @override
  State<_SablonSheet> createState() => _SablonSheetState();
}

class _SablonSheetState extends State<_SablonSheet> {
  late int _gun;
  final _dersTipiC = TextEditingController();
  final _kapasiteC = TextEditingController(text: '3');
  String? _personelId;
  String? _hizmetId;
  TimeOfDay _saat = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _bitis = const TimeOfDay(hour: 10, minute: 0);
  bool _kaydediyor = false;

  @override
  void initState() {
    super.initState();
    final m = widget.mevcut;
    _gun = m?.haftaGunu ?? widget.varsayilanGun;
    if (m != null) {
      _dersTipiC.text = m.dersTipi;
      _kapasiteC.text = m.kapasite.toString();
      _personelId = m.personelId;
      _hizmetId = m.hizmetId;
      _saat = _p(m.saat, const TimeOfDay(hour: 9, minute: 0));
      _bitis = _p(m.saatBitis, const TimeOfDay(hour: 10, minute: 0));
    }
  }

  TimeOfDay _p(String s, TimeOfDay def) {
    try { final x = s.split(':'); return TimeOfDay(hour: int.parse(x[0]), minute: int.parse(x[1])); } catch (_) { return def; }
  }

  String _ik(int n) => n.toString().padLeft(2, '0');
  String _st(TimeOfDay t) => '${_ik(t.hour)}:${_ik(t.minute)}';

  Future<void> _kaydet() async {
    if (_dersTipiC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ders tipi girin')));
      return;
    }
    setState(() => _kaydediyor = true);
    try {
      await dersSablonKaydet(
        salonId: widget.salonId,
        sablonId: widget.mevcut?.id,
        haftaGunu: _gun,
        dersTipi: _dersTipiC.text.trim(),
        personelId: _personelId,
        hizmetId: _hizmetId,
        saat: _st(_saat),
        saatBitis: _st(_bitis),
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.mevcut == null ? 'Ders Ekle' : 'Ders Düzenle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _mor)),
              const SizedBox(height: 10),
              _lbl('Gün'),
              DropdownButtonFormField<int>(
                value: _gun,
                isExpanded: true,
                decoration: _dec(),
                items: List.generate(7, (i) => i + 1).map((g) => DropdownMenuItem(value: g, child: Text(_gunAd[g]))).toList(),
                onChanged: (v) => setState(() => _gun = v ?? 1),
              ),
              const SizedBox(height: 10),
              _lbl('Ders Tipi'),
              TextField(controller: _dersTipiC, decoration: _dec(hint: 'Reformer / Mat / Birebir')),
              const SizedBox(height: 10),
              _lbl('Eğitmen'),
              DropdownButtonFormField<String>(
                value: _personelId, isExpanded: true, decoration: _dec(),
                items: [const DropdownMenuItem<String>(value: null, child: Text('— Seçiniz —')), ...widget.personeller.map((p) => DropdownMenuItem(value: p.id, child: Text(p.ad)))],
                onChanged: (v) => setState(() => _personelId = v),
              ),
              const SizedBox(height: 10),
              _lbl('Hizmet (paket düşümü için)'),
              DropdownButtonFormField<String>(
                value: _hizmetId, isExpanded: true, decoration: _dec(),
                items: [const DropdownMenuItem<String>(value: null, child: Text('— Hizmet bağlama (paket düşmez) —')), ...widget.hizmetler.map((h) => DropdownMenuItem(value: h.id, child: Text(h.ad)))],
                onChanged: (v) => setState(() => _hizmetId = v),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _lbl('Başlangıç'),
                  _saatKutu(_st(_saat), () async { final t = await showTimePicker(context: context, initialTime: _saat); if (t != null) setState(() => _saat = t); }),
                ])),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _lbl('Bitiş'),
                  _saatKutu(_st(_bitis), () async { final t = await showTimePicker(context: context, initialTime: _bitis); if (t != null) setState(() => _bitis = t); }),
                ])),
                const SizedBox(width: 10),
                SizedBox(width: 80, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _lbl('Kapasite'),
                  TextField(controller: _kapasiteC, keyboardType: TextInputType.number, decoration: _dec()),
                ])),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _mor),
                  icon: _kaydediyor ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                  label: const Text('Kaydet'),
                  onPressed: _kaydediyor ? null : _kaydet,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)));
  InputDecoration _dec({String? hint}) => InputDecoration(hintText: hint, isDense: true, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12));
  Widget _saatKutu(String metin, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD7DDE3)), borderRadius: BorderRadius.circular(4)),
          child: Row(children: [const Icon(Icons.access_time, size: 16, color: _mor), const SizedBox(width: 6), Text(metin)]),
        ),
      );
}
