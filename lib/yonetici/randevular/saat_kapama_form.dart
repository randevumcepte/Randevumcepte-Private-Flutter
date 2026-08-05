import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';
import 'package:randevu_sistem/Models/cihazlar.dart';
import 'package:randevu_sistem/Models/odalar.dart';
import 'package:randevu_sistem/Models/personel.dart';

/// Saat Kapama formu (personel/oda/cihaz icin belirli tarih+saat araligini
/// randevuya kapatir). Takvim top bar'daki lock ikonundan bottom sheet
/// olarak acilir. Onceden AppointmentEditor icinde tab olarak duruyordu;
/// yeni randevu ekleme akisi ile karistigi icin ayri widget'a alindi.
///
/// [showSaatKapamaSheet] cagrisi ile modal bottom sheet olarak acilir.
Future<bool?> showSaatKapamaSheet({
  required BuildContext context,
  required String salonId,
  required String takvimTuruId,
  String tarihsaat = '',
  String onceSeciliKaynakId = '',
  String onceSeciliKaynakTipi = '',
  required List<Personel> personeller,
  required List<Oda> odalar,
  required List<Cihaz> cihazlar,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Saat Kapama',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SaatKapamaFormu(
                    salonId: salonId,
                    takvimTuruId: takvimTuruId,
                    tarihsaat: tarihsaat,
                    onceSeciliKaynakId: onceSeciliKaynakId,
                    onceSeciliKaynakTipi: onceSeciliKaynakTipi,
                    personeller: personeller,
                    odalar: odalar,
                    cihazlar: cihazlar,
                    onKaydedildi: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Saat Kapama formu — takvim hangi turde ise (personel/cihaz/oda), ilgili
/// kaynak dropdown'i ve tiklanan saat-tarih onceden secili gelir.
class SaatKapamaFormu extends StatefulWidget {
  final String salonId;
  final String takvimTuruId; // 0/1=personel, 2=cihaz, 3=oda
  final String tarihsaat; // ISO string; bos olabilir
  final String onceSeciliKaynakId;
  final String onceSeciliKaynakTipi; // 'personel' | 'cihaz' | 'oda' | 'hizmet'
  final List<Personel> personeller;
  final List<Oda> odalar;
  final List<Cihaz> cihazlar;
  final VoidCallback onKaydedildi;

  const SaatKapamaFormu({
    super.key,
    required this.salonId,
    required this.takvimTuruId,
    required this.tarihsaat,
    required this.onceSeciliKaynakId,
    required this.onceSeciliKaynakTipi,
    required this.personeller,
    required this.odalar,
    required this.cihazlar,
    required this.onKaydedildi,
  });

  @override
  State<SaatKapamaFormu> createState() => _SaatKapamaFormuState();
}

class _SaatKapamaFormuState extends State<SaatKapamaFormu> {
  late DateTime _tarih;
  TimeOfDay? _baslangic;
  TimeOfDay? _bitis;
  bool _tumGun = false;
  bool _tekrarlayan = false;
  String _tekrarSikligi = '+1 day';
  final TextEditingController _tekrarSayisiCtrl =
      TextEditingController(text: '1');
  final TextEditingController _notlarCtrl = TextEditingController();
  String? _kaynakId;
  bool _yukleniyor = false;

  final List<MapEntry<String, String>> _siklikSecenekleri = const [
    MapEntry('+1 day', 'Her gun'),
    MapEntry('+2 days', '2 gunde bir'),
    MapEntry('+3 days', '3 gunde bir'),
    MapEntry('+1 week', 'Haftada bir'),
    MapEntry('+2 weeks', '2 haftada bir'),
    MapEntry('+1 month', 'Her ay'),
  ];

  String get _kaynakTipi {
    final t = widget.onceSeciliKaynakTipi;
    if (t == 'cihaz' || t == 'oda' || t == 'personel') return t;
    switch (widget.takvimTuruId) {
      case '2':
        return 'cihaz';
      case '3':
        return 'oda';
      default:
        return 'personel';
    }
  }

  String get _kaynakEtiketi {
    switch (_kaynakTipi) {
      case 'cihaz':
        return 'Cihaz';
      case 'oda':
        return 'Oda';
      default:
        return 'Personel';
    }
  }

  List<MapEntry<String, String>> get _kaynakOgeleri {
    switch (_kaynakTipi) {
      case 'cihaz':
        return widget.cihazlar.map((c) => MapEntry(c.id, c.cihaz_adi)).toList();
      case 'oda':
        return widget.odalar.map((o) => MapEntry(o.id, o.oda_adi)).toList();
      default:
        return widget.personeller
            .map((p) => MapEntry(p.id, p.personel_adi))
            .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    DateTime? gelen;
    if (widget.tarihsaat.isNotEmpty) {
      gelen = DateTime.tryParse(widget.tarihsaat);
    }
    final now = DateTime.now();
    final base = gelen ?? now;
    _tarih = DateTime(base.year, base.month, base.day);
    if (gelen != null) {
      _baslangic = TimeOfDay(hour: gelen.hour, minute: gelen.minute);
      final son = gelen.add(const Duration(minutes: 30));
      _bitis = TimeOfDay(hour: son.hour, minute: son.minute);
    }
    if (widget.onceSeciliKaynakId.isNotEmpty &&
        widget.onceSeciliKaynakTipi == _kaynakTipi) {
      _kaynakId = widget.onceSeciliKaynakId;
    }
  }

  @override
  void dispose() {
    _tekrarSayisiCtrl.dispose();
    _notlarCtrl.dispose();
    super.dispose();
  }

  String _ikiHane(int n) => n.toString().padLeft(2, '0');
  String _saatStr(TimeOfDay? t) =>
      t == null ? '' : '${_ikiHane(t.hour)}:${_ikiHane(t.minute)}';

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (secilen != null) setState(() => _tarih = secilen);
  }

  Future<void> _saatSec(bool baslangic) async {
    final secilen = await showTimePicker(
      context: context,
      initialTime: baslangic
          ? (_baslangic ?? const TimeOfDay(hour: 9, minute: 0))
          : (_bitis ?? const TimeOfDay(hour: 18, minute: 0)),
    );
    if (secilen != null) {
      setState(() {
        if (baslangic) {
          _baslangic = secilen;
        } else {
          _bitis = secilen;
        }
      });
    }
  }

  Future<void> _kaydet() async {
    if (_kaynakId == null || _kaynakId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lutfen ${_kaynakEtiketi.toLowerCase()} secin.')),
      );
      return;
    }
    if (!_tumGun) {
      if (_baslangic == null || _bitis == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Baslangic ve bitis saatini secin (veya Tum gun isaretleyin).')),
        );
        return;
      }
      final b = _baslangic!.hour * 60 + _baslangic!.minute;
      final s = _bitis!.hour * 60 + _bitis!.minute;
      if (s <= b) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bitis saati baslangictan sonra olmali.')),
        );
        return;
      }
    }

    setState(() => _yukleniyor = true);
    try {
      final sonuc = await saatKapamaEkle(
        salonId: widget.salonId,
        tarih: DateFormat('yyyy-MM-dd').format(_tarih),
        saat: _tumGun ? '' : _saatStr(_baslangic),
        saatBitis: _tumGun ? '' : _saatStr(_bitis),
        personelId: _kaynakTipi == 'personel' ? (_kaynakId ?? '') : '',
        cihazId: _kaynakTipi == 'cihaz' ? (_kaynakId ?? '') : '',
        odaId: _kaynakTipi == 'oda' ? (_kaynakId ?? '') : '',
        personelNotu: _notlarCtrl.text.trim(),
        tekrarlayan: _tekrarlayan,
        tekrarSikligi: _tekrarSikligi,
        tekrarSayisi: _tekrarlayan
            ? (int.tryParse(_tekrarSayisiCtrl.text.trim()) ?? 0)
            : 0,
      );
      if (!mounted) return;
      if (sonuc['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(sonuc['message']?.toString() ?? 'Saat kapama eklendi')),
        );
        widget.onKaydedildi();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(sonuc['error']?.toString() ??
                  sonuc['message']?.toString() ??
                  'Hata olustu')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saat kapama eklenemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Widget _kaynakAlani() => AramaliDropdownFormField<String>(
        value: _kaynakId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: _kaynakEtiketi,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        hint: Text('$_kaynakEtiketi secin'),
        items: _kaynakOgeleri
            .map((e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (v) => setState(() => _kaynakId = v),
      );

  Widget _tarihAlani() => InkWell(
        onTap: _tarihSec,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Tarih',
            isDense: true,
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today, size: 18),
          ),
          child: Text(DateFormat('dd.MM.yyyy').format(_tarih)),
        ),
      );

  Widget _saatAlanlari() => Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _tumGun ? null : () => _saatSec(true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Baslangic',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                child:
                    Text(_baslangic == null ? '--:--' : _saatStr(_baslangic)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: _tumGun ? null : () => _saatSec(false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Bitis',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                child: Text(_bitis == null ? '--:--' : _saatStr(_bitis)),
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool wide = media.size.width >= 720 &&
        media.orientation == Orientation.landscape;

    final solKolon = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _kaynakAlani(),
        const SizedBox(height: 12),
        _tarihAlani(),
        const SizedBox(height: 12),
        _saatAlanlari(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Tum gun'),
          value: _tumGun,
          onChanged: (v) => setState(() {
            _tumGun = v;
            if (v) {
              _baslangic = null;
              _bitis = null;
            }
          }),
        ),
      ],
    );

    final sagKolon = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Tekrarlayan'),
          value: _tekrarlayan,
          onChanged: (v) => setState(() => _tekrarlayan = v),
        ),
        if (_tekrarlayan) ...[
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AramaliDropdownFormField<String>(
                  value: _tekrarSikligi,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tekrar sikligi',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: _siklikSecenekleri
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _tekrarSikligi = v ?? '+1 day'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tekrarSayisiCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tekrar sayisi',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _notlarCtrl,
          minLines: 2,
          maxLines: wide ? 5 : 3,
          decoration: const InputDecoration(
            labelText: 'Notlar',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );

    final form = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: solKolon),
              const SizedBox(width: 16),
              Expanded(child: sagKolon),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [solKolon, const SizedBox(height: 8), sagKolon],
          );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: form,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _yukleniyor ? null : () => Navigator.of(context).pop(),
                child: const Text('Iptal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _yukleniyor ? null : _kaydet,
                icon: _yukleniyor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save, size: 18),
                label: const Text('Saat Kapama Kaydet'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
