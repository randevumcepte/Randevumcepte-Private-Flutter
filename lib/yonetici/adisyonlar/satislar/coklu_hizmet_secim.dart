import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/secilipersonel.dart';
import 'package:randevu_sistem/Models/adisyonhizmetler.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

/// Yeni Satış ekranı için kuaför-dostu çoklu hizmet seçim ekranı.
/// Birden fazla hizmete tik atılır; tek personel ve tek tarih/saat ile hepsi
/// aynı adisyona eklenir. Mevcut tek-seçimlik HizmetSatisi ekranına dokunulmaz.
class CokluHizmetSecim extends StatefulWidget {
  final String musteriid;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final String? mevcutadisyonId;

  const CokluHizmetSecim({
    Key? key,
    required this.musteriid,
    required this.isletmebilgi,
    required this.kullanicirolu,
    this.mevcutadisyonId,
  }) : super(key: key);

  @override
  State<CokluHizmetSecim> createState() => _CokluHizmetSecimState();
}

class _CokluHizmetSecimState extends State<CokluHizmetSecim> {
  bool isloading = true;
  bool _kaydediliyor = false;

  List<Personel> personeller = [];
  List<IsletmeHizmet> hizmetler = [];
  Personel? selectedpersonel;
  String? seciliisletme;

  final Set<String> _seciliHizmetIdler = {};
  String _arama = '';

  // { personel_id: [hizmet_id...] } — personele atanmış hizmetler. Boşsa o personel
  // tüm hizmetleri verebilir demektir.
  Map<String, List<String>> _personelHizmetMap = {};

  final TextEditingController islem_tarihi =
      TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  TimeOfDay _saat = TimeOfDay.now();
  final TextEditingController islem_saati = TextEditingController();

  // Kalem bazında düzenlenebilir fiyat alanları: { hizmet_id: controller }
  final Map<String, TextEditingController> _fiyatCtrl = {};
  // Kalem bazında seans sayisi: { hizmet_id: controller } (bos/1 -> tekil, 2+ -> paket)
  final Map<String, TextEditingController> _seansCtrl = {};

  @override
  void initState() {
    super.initState();
    islem_saati.text =
        '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}';
    initialize();
  }

  @override
  void dispose() {
    for (final c in _fiyatCtrl.values) {
      c.dispose();
    }
    for (final c in _seansCtrl.values) {
      c.dispose();
    }
    islem_tarihi.dispose();
    islem_saati.dispose();
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

  /// Kullanıcının düzenlediği güncel fiyat (yoksa hizmetin varsayılanı)
  double _guncelFiyat(IsletmeHizmet h) {
    final c = _fiyatCtrl[h.hizmet_id];
    if (c == null) return _fiyatDouble(h);
    return _parseTl(c.text);
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    final personelliste = await personellistegetir(seciliisletme!);
    // Hizmetleri ve personel-hizmet eşlemesini tek kaynaktan al (id'ler tutarlı olsun)
    final isletmeVerileri =
        await isletmeVerileriGetir(seciliisletme!, false, '', '', '', 0, 0);
    final List<IsletmeHizmet> hizmetliste = isletmeVerileri['hizmetler'];
    final phMapRaw = (isletmeVerileri['personel_hizmet_map'] as Map?) ?? {};
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

    // Seçili personeli LİSTEDEKİ instance ile eşleştir (seciliPersonelgetir farklı
    // bir obje döndürdüğü için referans eşitliği tutmaz).
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

    // Her hizmet için düzenlenebilir fiyat alanı (varsayılan fiyatla dolu)
    final fmt = NumberFormat("#,##0.00", "tr_TR");
    for (final h in hizmetliste) {
      _fiyatCtrl.putIfAbsent(
          h.hizmet_id, () => TextEditingController(text: fmt.format(_fiyatDouble(h))));
      _seansCtrl.putIfAbsent(h.hizmet_id, () => TextEditingController());
    }

    setState(() {
      personeller = temizPersoneller;
      hizmetler = hizmetliste;
      _personelHizmetMap = Map<String, List<String>>.from(
          phMapRaw.map((k, v) => MapEntry(k.toString(), List<String>.from(v))));
      selectedpersonel = secili;
      isloading = false;
    });
  }

  double _fiyatDouble(IsletmeHizmet h) =>
      double.tryParse(h.fiyat.replaceAll(',', '.')) ?? 0;

  // Seçili personele atanmış hizmet id'leri. Boş dönerse (atanmış hizmet yok ya da
  // personel seçili değil) → tüm hizmetler gösterilir.
  Set<String> _izinliHizmetIdler() {
    final p = selectedpersonel;
    if (p != null) {
      final hp = _personelHizmetMap[p.id];
      if (hp != null && hp.isNotEmpty) return hp.toSet();
    }
    return {};
  }

  List<IsletmeHizmet> get _filtreliHizmetler {
    final izinli = _izinliHizmetIdler();
    Iterable<IsletmeHizmet> kaynak = hizmetler;
    if (izinli.isNotEmpty) {
      kaynak = kaynak.where((h) => izinli.contains(h.hizmet_id));
    }
    if (_arama.trim().isNotEmpty) {
      final q = _arama.toLowerCase();
      kaynak = kaynak
          .where((h) => (h.hizmet["hizmet_adi"] ?? "").toString().toLowerCase().contains(q));
    }
    return kaynak.toList();
  }

  double get _secilenToplam {
    double t = 0;
    for (final h in hizmetler) {
      if (_seciliHizmetIdler.contains(h.hizmet_id)) t += _guncelFiyat(h);
    }
    return t;
  }

  Future<void> _tarihSec() async {
    final p = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(islem_tarihi.text) ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (p != null) {
      setState(() => islem_tarihi.text = DateFormat('yyyy-MM-dd').format(p));
    }
  }

  Future<void> _saatSec() async {
    final p = await showTimePicker(context: context, initialTime: _saat);
    if (p != null) {
      setState(() {
        _saat = p;
        islem_saati.text =
            '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _kaydet() async {
    if (selectedpersonel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir personel seçin'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_seciliHizmetIdler.isEmpty) return;

    setState(() => _kaydediliyor = true);
    final secililer = hizmetler.where((h) => _seciliHizmetIdler.contains(h.hizmet_id)).toList();
    String adisyonId = widget.mevcutadisyonId ?? "";
    final List<AdisyonHizmet> eklenenler = [];
    try {
      for (final h in secililer) {
        // Seans sayisi: bos ya da <=1 -> backend NULL kaydeder (tekil hizmet)
        final String _seansTrim = (_seansCtrl[h.hizmet_id]?.text ?? '').trim();
        final String _seansGonder = (_seansTrim.isEmpty || (int.tryParse(_seansTrim) ?? 0) <= 1) ? '' : _seansTrim;
        final ah = AdisyonHizmet(
          id: "",
          adisyon_id: adisyonId,
          hizmet_id: h.hizmet_id,
          islem_tarihi: islem_tarihi.text,
          islem_saati: islem_saati.text,
          sure: (int.tryParse(h.sure) ?? 0).toString(),
          fiyat: _guncelFiyat(h).toStringAsFixed(2).replaceAll('.', ','),
          geldi: "1",
          personel_id: selectedpersonel!.id,
          cihaz_id: "",
          oda_id: "",
          dogrulama_kodu: "",
          taksitli_tahsilat_id: "",
          senet_id: "",
          indirim_tutari: "",
          hediye: "",
          hizmet: h.hizmet,
          personel: selectedpersonel!,
          seans_sayisi: _seansGonder,
        );
        final eklenen = await adisyonhizmetekle(ah, widget.musteriid, context, seciliisletme!);
        adisyonId = eklenen.adisyon_id; // zincirle: sonraki kalem aynı adisyona
        eklenenler.add(eklenen);
      }
      if (mounted) Navigator.pop(context, eklenenler);
    } catch (_) {
      // adisyonhizmetekle hata snackbar'ını kendi gösteriyor; başarılı eklenenleri geri ver
      if (mounted) Navigator.pop(context, eklenenler);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tryf = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hizmet Seç'),
      ),
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
                          Text('${_seciliHizmetIdler.length} hizmet seçildi',
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          Text(tryf.format(_secilenToplam),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: (_seciliHizmetIdler.isEmpty || _kaydediliyor) ? null : _kaydet,
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
                // Personel + Tarih + Saat (tek sefer)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      AramaliDropdownFormField<Personel>(
                        value: selectedpersonel,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Personel',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('Personel seçin'),
                        items: personeller
                            .map((p) => DropdownMenuItem(value: p, child: Text(p.personel_adi)))
                            .toList(),
                        onChanged: (v) => setState(() {
                          selectedpersonel = v;
                          // Yeni personele atanmamış seçili hizmetleri kaldır
                          // (atanmış hizmeti yoksa hepsi geçerli, dokunma).
                          final izinli = _izinliHizmetIdler();
                          if (izinli.isNotEmpty) {
                            _seciliHizmetIdler.removeWhere((id) => !izinli.contains(id));
                          }
                        }),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _tarihSec,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Tarih',
                                  prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                child: Text(islem_tarihi.text),
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
                                child: Text(islem_saati.text),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arama
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _arama = v),
                    decoration: InputDecoration(
                      hintText: 'Hizmet ara...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                // Hizmet listesi (çoklu tik)
                Expanded(
                  child: _filtreliHizmetler.isEmpty
                      ? Center(child: Text('Hizmet bulunamadı', style: TextStyle(color: cs.onSurfaceVariant)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          itemCount: _filtreliHizmetler.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final h = _filtreliHizmetler[i];
                            final secili = _seciliHizmetIdler.contains(h.hizmet_id);
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() {
                                if (secili) {
                                  _seciliHizmetIdler.remove(h.hizmet_id);
                                } else {
                                  _seciliHizmetIdler.add(h.hizmet_id);
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
                                      child: Text(
                                        (h.hizmet["hizmet_adi"] ?? "").toString(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // Seans: yalnizca secili hizmette, ad ile fiyat arasinda tek satirda
                                    if (secili) ...[
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 66,
                                        child: TextField(
                                          controller: _seansCtrl[h.hizmet_id],
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            hintText: 'Seans',
                                            hintStyle: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                            filled: true,
                                            fillColor: Theme.of(context).scaffoldBackgroundColor,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
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
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 110,
                                      child: TextField(
                                        controller: _fiyatCtrl[h.hizmet_id],
                                        textAlign: TextAlign.end,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                        onChanged: (_) => setState(() {}),
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
}
