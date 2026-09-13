import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/secilipersonel.dart';
import 'package:randevu_sistem/Models/adisyonpaketler.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';
import 'package:randevu_sistem/Backend/grup_dersi_api.dart';
import 'package:randevu_sistem/Models/grup_dersi.dart';

/// Yeni Satış ekranı için çoklu paket seçim ekranı.
/// Birden fazla pakete tik atılır; tek satıcı, tek başlangıç tarihi/saati ile
/// hepsi aynı adisyona eklenir. Mevcut PaketSatisi ekranına dokunulmaz.
/// Fiyat ve seans sayısı paketin varsayılanından hesaplanır; ince ayar için
/// eklendikten sonra kalem düzenleme kullanılabilir.
class CokluPaketSecim extends StatefulWidget {
  final String musteriid;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final String? mevcutadisyonId;

  const CokluPaketSecim({
    Key? key,
    required this.musteriid,
    required this.isletmebilgi,
    required this.kullanicirolu,
    this.mevcutadisyonId,
  }) : super(key: key);

  @override
  State<CokluPaketSecim> createState() => _CokluPaketSecimState();
}

class _CokluPaketSecimState extends State<CokluPaketSecim> {
  // Studyo modu: fiyat gizli + satici (personel) zorunlu degil
  bool get _studyo =>
      widget.isletmebilgi is Map &&
      widget.isletmebilgi['studyo_modu']?.toString() == '1';
  bool isloading = true;
  bool _kaydediliyor = false;

  List<Personel> personeller = [];
  List<Paket> paketler = [];
  Personel? selectedSatici;
  String? seciliisletme;

  final Set<String> _seciliPaketIdler = {};
  String _arama = '';

  // Studyo modu: otomatik ders plani (tekrarli katilim) icin gun + egitmen secimi
  static const List<String> _gunAdi = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  List<GrupDersSablon> _sablonlar = [];
  final Set<int> _seciliSablon = {}; // secili SABIT ders slotlari (sablon id)

  final TextEditingController baslangic_tarihi =
      TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  TimeOfDay _saat = TimeOfDay.now();
  final TextEditingController seans_saati = TextEditingController();

  // Kalem bazında düzenlenebilir fiyat alanları: { paket_id: controller }
  final Map<String, TextEditingController> _fiyatCtrl = {};

  @override
  void initState() {
    super.initState();
    seans_saati.text =
        '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}';
    initialize();
  }

  @override
  void dispose() {
    for (final c in _fiyatCtrl.values) {
      c.dispose();
    }
    baslangic_tarihi.dispose();
    seans_saati.dispose();
    super.dispose();
  }

  /// "1.500,00" / "1500" / "1500.50" → double
  double _parseTl(String s) {
    var t = s.trim().replaceAll('₺', '').replaceAll(' ', '');
    if (t.isEmpty) return 0;
    if (t.contains(',')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(t) ?? 0;
  }

  /// Kullanıcının düzenlediği güncel fiyat (yoksa paketin hesaplanan varsayılanı)
  double _guncelFiyat(Paket p) {
    final c = _fiyatCtrl[p.id];
    if (c == null) return _paketFiyat(p);
    return _parseTl(c.text);
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    final personelliste = await personellistegetir(seciliisletme!);
    final paketliste = await paket_liste(seciliisletme!);
    Personel? seciliPersonel;
    try {
      seciliPersonel = await seciliPersonelgetir(widget.isletmebilgi);
    } catch (_) {}
    if (!mounted) return;

    // Duplicate personelleri id bazında temizle (Dropdown aynı value'yu 2 kez
    // görürse ya da hiç bulamazsa "exactly one item" assertion'u atar).
    final Map<String, Personel> benzersiz = {};
    for (final p in personelliste) {
      benzersiz.putIfAbsent(p.id, () => p);
    }
    final temizPersoneller = benzersiz.values.toList();

    // Seçili satıcıyı LİSTEDEKİ instance ile eşleştir (farklı obje → referans tutmaz).
    Personel? secili;
    if (widget.kullanicirolu == 5 && seciliPersonel != null) {
      for (final p in temizPersoneller) {
        if (p.id == seciliPersonel.id) {
          secili = p;
          break;
        }
      }
      // Personel listede yoksa (farklı kaynak/id) kendisini başa ekle ki adı seçili gelsin
      if (secili == null) {
        temizPersoneller.insert(0, seciliPersonel);
        secili = seciliPersonel;
      }
    }

    // Her paket için düzenlenebilir fiyat alanı (hesaplanan varsayılan fiyatla dolu)
    final fmt = NumberFormat("#,##0.00", "tr_TR");
    for (final p in paketliste) {
      _fiyatCtrl.putIfAbsent(
          p.id, () => TextEditingController(text: fmt.format(_paketFiyat(p))));
    }

    // Studyo modu: haftalik ders programi sablonlari (gun/saat/egitmen eslesme kaynagi)
    List<GrupDersSablon> sablonlar = [];
    if (_studyo) {
      try {
        final p = await dersProgramiListe(seciliisletme!);
        sablonlar = (p['sablon'] as List).cast<GrupDersSablon>();
      } catch (_) {}
    }

    setState(() {
      personeller = temizPersoneller;
      paketler = paketliste;
      selectedSatici = secili;
      _sablonlar = sablonlar;
      isloading = false;
    });
  }

  // Secili paketlerin hizmet id'leri (sablon eslesmesi icin)
  Set<String> get _seciliHizmetIdler {
    final set = <String>{};
    for (final p in paketler) {
      if (!_seciliPaketIdler.contains(p.id)) continue;
      for (final h in p.hizmetler) {
        final hid = (h['hizmet_id'] ?? h['id'])?.toString();
        if (hid != null && hid.isNotEmpty) set.add(hid);
      }
    }
    return set;
  }

  // Bir paketin (grup dersi icin) birincil hizmet id'si
  String? _paketHizmetId(Paket p) {
    for (final h in p.hizmetler) {
      final hid = (h['hizmet_id'] ?? h['id'])?.toString();
      if (hid != null && hid.isNotEmpty) return hid;
    }
    return null;
  }

  String _sHHMM(String s) => s.length >= 5 ? s.substring(0, 5) : s;

  // Secili paketlerin hizmetine ait SABIT ders slotlari (gun+saat+egitmen).
  // Gun, sonra saat sirasiyla.
  List<GrupDersSablon> get _uygunSablon {
    final hids = _seciliHizmetIdler;
    if (hids.isEmpty) return [];
    final l = _sablonlar.where((s) => hids.contains((s.hizmetId ?? '').toString())).toList();
    l.sort((a, b) => a.haftaGunu != b.haftaGunu
        ? a.haftaGunu.compareTo(b.haftaGunu)
        : _sHHMM(a.saat).compareTo(_sHHMM(b.saat)));
    return l;
  }

  double _paketFiyat(Paket p) {
    double toplam = 0;
    for (final h in p.hizmetler) {
      toplam += double.tryParse(h["fiyat"]?.toString() ?? "0") ?? 0;
    }
    if (toplam <= 0) toplam = double.tryParse(p.fiyat.replaceAll(',', '.')) ?? 0;
    return toplam;
  }

  int _paketSeans(Paket p) {
    double toplamSeans = 0;
    for (final h in p.hizmetler) {
      toplamSeans += double.tryParse(h["seans"]?.toString() ?? "0") ?? 0;
    }
    return toplamSeans > 0 ? toplamSeans.round() : (int.tryParse(p.miktar) ?? 0);
  }

  List<Paket> get _filtreliPaketler {
    if (_arama.trim().isEmpty) return paketler;
    final q = _arama.toLowerCase();
    return paketler.where((p) => p.paket_adi.toLowerCase().contains(q)).toList();
  }

  double get _secilenToplam {
    double t = 0;
    for (final p in paketler) {
      if (_seciliPaketIdler.contains(p.id)) t += _guncelFiyat(p);
    }
    return t;
  }

  Future<void> _tarihSec() async {
    final p = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(baslangic_tarihi.text) ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (p != null) {
      setState(() => baslangic_tarihi.text = DateFormat('yyyy-MM-dd').format(p));
    }
  }

  Future<void> _saatSec() async {
    final p = await showTimePicker(context: context, initialTime: _saat);
    if (p != null) {
      setState(() {
        _saat = p;
        seans_saati.text =
            '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _kaydet() async {
    if (selectedSatici == null && !_studyo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir satıcı seçin'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_seciliPaketIdler.isEmpty) return;

    setState(() => _kaydediliyor = true);
    final secililer = paketler.where((p) => _seciliPaketIdler.contains(p.id)).toList();
    String adisyonId = widget.mevcutadisyonId ?? "";
    final List<AdisyonPaket> eklenenler = [];
    try {
      for (final p in secililer) {
        final ap = AdisyonPaket(
          baslangic_tarihi: baslangic_tarihi.text,
          seans_araligi: '30',
          id: "",
          adisyon_id: adisyonId,
          paket_id: p.id,
          fiyat: _guncelFiyat(p).toString(),
          personel_id: selectedSatici?.id ?? "",
          taksitli_tahsilat_id: "",
          senet_id: "",
          indirim_tutari: "",
          hediye: "false",
          paket: p.toJson(),
          personel: selectedSatici?.toJson() ?? {},
          seans_baslangic_saati: seans_saati.text,
        );
        final eklenen = await adisyonpaketekle(
          ap,
          widget.musteriid,
          context,
          seciliisletme!,
          seans_saati.text,
          true,
          "",
          seansSayisi: _paketSeans(p).toString(),
        );
        adisyonId = eklenen.adisyon_id; // zincirle
        eklenenler.add(eklenen);

        // Studyo modu: ders slotu secildiyse otomatik ders planini olustur + dagit
        if (_studyo && _seciliSablon.isNotEmpty) {
          final hid = _paketHizmetId(p);
          final apId = int.tryParse(eklenen.id);
          // Bu paketin hizmetine ait secili slotlar
          final paketSlotlari = _uygunSablon
              .where((s) => _seciliSablon.contains(s.id))
              .map((s) => s.id)
              .toList();
          if (hid != null && (int.tryParse(hid) ?? 0) > 0 && paketSlotlari.isNotEmpty) {
            try {
              final r = await dersTekrarliKaydet(
                salonId: seciliisletme!,
                userId: widget.musteriid,
                hizmetId: int.tryParse(hid) ?? 0,
                toplamSeans: _paketSeans(p),
                sablonlar: paketSlotlari,
                baslangic: baslangic_tarihi.text,
                adisyonPaketId: apId,
              );
              final s = Map<String, dynamic>.from(r['sonuc'] ?? {});
              _planOlusan += int.tryParse(s['olusan'].toString()) ?? 0;
              _planYerlesmeyen += int.tryParse(s['yerlesmeyen'].toString()) ?? 0;
            } catch (_) {/* satis basarili; plan hatasi satisi bozmasin */}
          }
        }
      }
      if (mounted) {
        if (_studyo && _seciliSablon.isNotEmpty && _planOlusan > 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$_planOlusan ders otomatik planlandı'
                '${_planYerlesmeyen > 0 ? ' • $_planYerlesmeyen seans yerleştirilemedi (uygun oturum yok)' : ''}.'),
            backgroundColor: const Color(0xFF2E7D32),
          ));
        }
        Navigator.pop(context, eklenenler);
      }
    } catch (_) {
      if (mounted) Navigator.pop(context, eklenenler);
    }
  }

  int _planOlusan = 0;
  int _planYerlesmeyen = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tryf = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(title: const Text('Paket Seç')),
      bottomNavigationBar: isloading
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(top: BorderSide(color: cs.outlineVariant)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_seciliPaketIdler.length} paket seçildi',
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          if (!_studyo)
                          Text(tryf.format(_secilenToplam),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: (_seciliPaketIdler.isEmpty || _kaydediliyor) ? null : _kaydet,
                      icon: _kaydediliyor
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded),
                      label: const Text('EKLE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: isloading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      if (!_studyo) ...[
                        AramaliDropdownFormField<Personel>(
                          value: selectedSatici,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Satıcı',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          hint: const Text('Satıcı seçin'),
                          items: personeller
                              .map((p) => DropdownMenuItem(value: p, child: Text(p.personel_adi)))
                              .toList(),
                          onChanged: (v) => setState(() => selectedSatici = v),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _tarihSec,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Başlangıç Tarihi',
                                  prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                child: Text(baslangic_tarihi.text),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: _saatSec,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Saat',
                                  prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                child: Text(seans_saati.text),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_studyo) _otomatikPlanBolum(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _arama = v),
                    decoration: InputDecoration(
                      hintText: 'Paket ara...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                Expanded(
                  child: _filtreliPaketler.isEmpty
                      ? Center(child: Text('Paket bulunamadı', style: TextStyle(color: cs.onSurfaceVariant)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          itemCount: _filtreliPaketler.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final p = _filtreliPaketler[i];
                            final secili = _seciliPaketIdler.contains(p.id);
                            final seans = _paketSeans(p);
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() {
                                if (secili) {
                                  _seciliPaketIdler.remove(p.id);
                                } else {
                                  _seciliPaketIdler.add(p.id);
                                }
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: secili ? cs.primary.withValues(alpha: 0.10) : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: secili ? cs.primary : cs.outlineVariant,
                                    width: secili ? 1.6 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      secili ? Icons.check_circle_rounded : Icons.circle_outlined,
                                      color: secili ? cs.primary : cs.outline,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.paket_adi,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                          ),
                                          if (seans > 0)
                                            Text('$seans seans',
                                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                        ],
                                      ),
                                    ),
                                    if (!_studyo)
                                    SizedBox(
                                      width: 120,
                                      child: TextField(
                                        controller: _fiyatCtrl[p.id],
                                        textAlign: TextAlign.end,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                        onChanged: (_) => setState(() {}), // toplam anlık güncellensin
                                        decoration: InputDecoration(
                                          isDense: true,
                                          prefixText: '₺',
                                          filled: true,
                                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: cs.outlineVariant),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: cs.primary, width: 1.4),
                                          ),
                                        ),
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

  // Studyo modu: paket seciminden sonra SABIT ders slotlarini sec -> otomatik ders plani.
  // Her slot = programdaki bir ders (gun + saat + egitmen sabit birlikte).
  Widget _otomatikPlanBolum() {
    final cs = Theme.of(context).colorScheme;
    final slotlar = _uygunSablon;
    if (_seciliPaketIdler.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(Icons.event_repeat_rounded, size: 17, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Paket seçince müşterinin katılacağı ders slotlarını seçip dersleri otomatik planlayabilirsiniz.',
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
            ),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.event_repeat_rounded, size: 17, color: cs.primary),
            const SizedBox(width: 6),
            const Text('Otomatik Ders Planı',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('(opsiyonel)', style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
          ]),
          const SizedBox(height: 4),
          Text('Müşterinin her hafta katılacağı ders(ler)i seçin — seanslar bu slotlara dağıtılır.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          if (slotlar.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(9)),
              child: const Text(
                  'Bu paketin hizmeti için haftalık programda ders yok. Otomatik plan için önce Ders Programı ekleyin.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9A3412))),
            )
          else ...[
            for (final s in slotlar) _slotKart(s),
            if (_seciliSablon.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Seçilen slotlara göre seanslar takvime otomatik dağıtılacak (dolu ders atlanır).',
                    style: TextStyle(fontSize: 11.5, color: cs.primary, fontWeight: FontWeight.w600)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _slotKart(GrupDersSablon s) {
    final cs = Theme.of(context).colorScheme;
    final secili = _seciliSablon.contains(s.id);
    final gun = _gunAdi[s.haftaGunu.clamp(0, 7)];
    final saat = '${_sHHMM(s.saat)}${s.saatBitis.isNotEmpty ? ' – ${_sHHMM(s.saatBitis)}' : ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => secili ? _seciliSablon.remove(s.id) : _seciliSablon.add(s.id)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: secili ? cs.primary.withValues(alpha: 0.10) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: secili ? cs.primary : cs.outlineVariant, width: secili ? 1.6 : 1),
          ),
          child: Row(children: [
            Icon(secili ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: secili ? cs.primary : cs.outline, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(gun,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary)),
                    ),
                    const SizedBox(width: 8),
                    Text(saat, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.person_outline_rounded, size: 13, color: cs.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${s.personel.isNotEmpty && s.personel != 'null' ? s.personel : 'Eğitmen atanmamış'}'
                        '${s.dersTipi.isNotEmpty && s.dersTipi != 'null' ? ' • ${s.dersTipi}' : ''}'
                        '${s.kapasite > 0 ? ' • ${s.kapasite} kişi' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
