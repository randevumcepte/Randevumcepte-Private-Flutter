// Gun sekmeli + egitmen filtreli kompakt ders slotu secici (bottom sheet).
// Paket ve hizmet satis ekranlarinda ortak kullanilir (studyo modu otomatik ders plani).
// Donus: onaylanan sablon id kumesi (Set<int>) veya null (kapatildi).
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/grup_dersi.dart';

class DersSlotSecici extends StatefulWidget {
  final List<GrupDersSablon> slotlar;
  final Set<int> secili;
  const DersSlotSecici({Key? key, required this.slotlar, required this.secili}) : super(key: key);

  @override
  State<DersSlotSecici> createState() => _DersSlotSeciciState();
}

class _DersSlotSeciciState extends State<DersSlotSecici> {
  static const List<String> _gunAdi = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  late Set<int> _secili;
  String? _filtreEgitmen; // null = tumu
  int _aktifGun = 0;

  String _sHHMM(String s) => s.length >= 5 ? s.substring(0, 5) : s;

  @override
  void initState() {
    super.initState();
    _secili = Set<int>.from(widget.secili);
    final g = _gunler;
    if (g.isNotEmpty) _aktifGun = g.first;
  }

  // Filtreye gore slotlar
  List<GrupDersSablon> get _filtreli => widget.slotlar
      .where((s) => _filtreEgitmen == null || (s.personelId ?? '') == _filtreEgitmen)
      .toList();

  List<int> get _gunler {
    final set = <int>{};
    for (final s in _filtreli) {
      set.add(s.haftaGunu);
    }
    final l = set.toList()..sort();
    return l;
  }

  List<MapEntry<String, String>> get _egitmenler {
    final m = <String, String>{};
    for (final s in widget.slotlar) {
      if (s.personelId != null && s.personelId!.isNotEmpty) m[s.personelId!] = s.personel;
    }
    return m.entries.toList();
  }

  List<GrupDersSablon> get _gununSlotlari {
    final l = _filtreli.where((s) => s.haftaGunu == _aktifGun).toList();
    l.sort((a, b) => _sHHMM(a.saat).compareTo(_sHHMM(b.saat)));
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gunler = _gunler;
    if (gunler.isNotEmpty && !gunler.contains(_aktifGun)) _aktifGun = gunler.first;
    final egitmenler = _egitmenler;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(width: 42, height: 4,
                decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(3))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Icon(Icons.event_repeat_rounded, color: cs.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Ders Slotlarını Seç',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              if (_secili.isNotEmpty)
                Text('${_secili.length} seçili', style: TextStyle(fontSize: 12.5, color: cs.primary, fontWeight: FontWeight.w700)),
            ]),
          ),
          // Egitmen filtresi
          if (egitmenler.length > 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _minic('Tüm Eğitmenler', _filtreEgitmen == null, () => setState(() => _filtreEgitmen = null)),
                  for (final e in egitmenler)
                    _minic(e.value, _filtreEgitmen == e.key, () => setState(() => _filtreEgitmen = e.key)),
                ],
              ),
            ),
          // Gun sekmeleri
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final g in gunler)
                  _minic(_gunAdi[g], _aktifGun == g, () => setState(() => _aktifGun = g), guclu: true),
              ],
            ),
          ),
          const Divider(height: 1),
          // Gunun slotlari
          Flexible(
            child: _gununSlotlari.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(30),
                    child: Center(child: Text('Bu günde ders yok.', style: TextStyle(color: cs.onSurfaceVariant))))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    itemCount: _gununSlotlari.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final s = _gununSlotlari[i];
                      final sec = _secili.contains(s.id);
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => sec ? _secili.remove(s.id) : _secili.add(s.id)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: sec ? cs.primary.withValues(alpha: 0.10) : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sec ? cs.primary : cs.outlineVariant, width: sec ? 1.6 : 1),
                          ),
                          child: Row(children: [
                            Icon(sec ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: sec ? cs.primary : cs.outline, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_sHHMM(s.saat)}${s.saatBitis.isNotEmpty ? ' – ${_sHHMM(s.saatBitis)}' : ''}',
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.personel.isNotEmpty && s.personel != 'null' ? s.personel : 'Eğitmen atanmamış'}'
                                    '${s.dersTipi.isNotEmpty && s.dersTipi != 'null' ? ' • ${s.dersTipi}' : ''}'
                                    '${s.kapasite > 0 ? ' • ${s.kapasite} kişi' : ''}',
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(children: [
                if (_secili.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _secili.clear()),
                    child: const Text('Temizle'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _secili),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_secili.isEmpty ? 'Vazgeç' : '${_secili.length} slotu onayla',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _minic(String t, bool sec, VoidCallback onTap, {bool guclu = false}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 7, top: 6, bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: guclu ? 18 : 14, vertical: 8),
          decoration: BoxDecoration(
            color: sec ? cs.primary : Theme.of(context).cardColor,
            border: Border.all(color: sec ? cs.primary : cs.outlineVariant),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(t,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sec ? Colors.white : cs.onSurface)),
        ),
      ),
    );
  }
}
