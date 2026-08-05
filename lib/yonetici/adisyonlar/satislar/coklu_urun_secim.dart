import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/secilipersonel.dart';
import 'package:randevu_sistem/Models/adisyonurunler.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/yonetici/diger/menu/stok/barkod_tarayici.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

/// Yeni Satış ekranı için kuaför-dostu çoklu ürün seçim ekranı.
/// Birden fazla ürüne tik atılır (adet 1 varsayılan); tek satıcı ve tek tarih
/// ile hepsi aynı adisyona eklenir. Mevcut UrunSatisi ekranına dokunulmaz.
class CokluUrunSecim extends StatefulWidget {
  final String musteriid;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final String? mevcutadisyonId;

  const CokluUrunSecim({
    Key? key,
    required this.musteriid,
    required this.isletmebilgi,
    required this.kullanicirolu,
    this.mevcutadisyonId,
  }) : super(key: key);

  @override
  State<CokluUrunSecim> createState() => _CokluUrunSecimState();
}

class _CokluUrunSecimState extends State<CokluUrunSecim> {
  bool isloading = true;
  bool _kaydediliyor = false;

  List<Personel> personeller = [];
  List<Urun> urunler = [];
  Personel? selectedSatici;
  String? seciliisletme;

  final Set<String> _seciliUrunIdler = {};
  String _arama = '';

  final TextEditingController islem_tarihi =
      TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));

  // Kalem bazında düzenlenebilir fiyat alanları: { urun_id: controller }
  final Map<String, TextEditingController> _fiyatCtrl = {};

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    for (final c in _fiyatCtrl.values) {
      c.dispose();
    }
    islem_tarihi.dispose();
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

  /// Kullanıcının düzenlediği güncel fiyat (yoksa ürünün varsayılanı)
  double _guncelFiyat(Urun u) {
    final c = _fiyatCtrl[u.id];
    if (c == null) return _fiyatDouble(u);
    return _parseTl(c.text);
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    final personelliste = await personellistegetir(seciliisletme!);
    final urunliste = await urun_liste(seciliisletme!);
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

    // Her ürün için düzenlenebilir fiyat alanı (varsayılan fiyatla dolu)
    final fmt = NumberFormat("#,##0.00", "tr_TR");
    for (final u in urunliste) {
      _fiyatCtrl.putIfAbsent(
          u.id, () => TextEditingController(text: fmt.format(_fiyatDouble(u))));
    }

    setState(() {
      personeller = temizPersoneller;
      urunler = urunliste;
      selectedSatici = secili;
      isloading = false;
    });
  }

  double _fiyatDouble(Urun u) => double.tryParse(u.fiyat.replaceAll(',', '.')) ?? 0;

  int? _stok(Urun u) => int.tryParse(u.stok_adedi);

  bool _stoktaYok(Urun u) {
    final s = _stok(u);
    return s != null && s < 1;
  }

  // Barkod okut → eşleşen ürünü seçili yap (tik at).
  Future<void> _barkodTara() async {
    final kod = await BarkodTarayici.tekSeferTara(context, baslik: 'Ürün Barkodu Tara');
    if (kod == null || kod.trim().isEmpty || !mounted) return;
    final aranan = kod.trim();
    Urun? eslesen;
    for (final u in urunler) {
      if (u.barkod.trim() == aranan) {
        eslesen = u;
        break;
      }
    }
    if (eslesen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$aranan" barkoduna kayıtlı ürün bulunamadı.'), backgroundColor: Colors.red.shade700),
      );
      return;
    }
    if (_stoktaYok(eslesen)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${eslesen.urun_adi} stokta yok.'), backgroundColor: Colors.orange.shade800),
      );
      return;
    }
    setState(() {
      _seciliUrunIdler.add(eslesen!.id);
      _arama = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${eslesen.urun_adi} eklendi.'), backgroundColor: Colors.green.shade700, duration: const Duration(milliseconds: 1200)),
    );
  }

  List<Urun> get _filtreliUrunler {
    if (_arama.trim().isEmpty) return urunler;
    final q = _arama.toLowerCase();
    return urunler.where((u) => u.urun_adi.toLowerCase().contains(q)).toList();
  }

  double get _secilenToplam {
    double t = 0;
    for (final u in urunler) {
      if (_seciliUrunIdler.contains(u.id)) t += _guncelFiyat(u);
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

  Future<void> _kaydet() async {
    if (selectedSatici == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir satıcı seçin'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_seciliUrunIdler.isEmpty) return;

    setState(() => _kaydediliyor = true);
    final secililer = urunler.where((u) => _seciliUrunIdler.contains(u.id)).toList();
    String adisyonId = widget.mevcutadisyonId ?? "";
    final List<AdisyonUrun> eklenenler = [];
    try {
      for (final u in secililer) {
        final au = AdisyonUrun(
          islem_tarihi: islem_tarihi.text,
          id: "",
          adisyon_id: adisyonId,
          urun_id: u.id,
          adet: "1",
          fiyat: _guncelFiyat(u).toString(),
          personel_id: selectedSatici!.id,
          taksitli_tahsilat_id: "",
          senet_id: "",
          indirim_tutari: "",
          hediye: "false",
          aciklama: "",
          urun: u.toJson(),
          personel: selectedSatici!.toJson(),
        );
        final eklenen = await adisyonurunekle(au, widget.musteriid, context, seciliisletme!, true);
        adisyonId = eklenen.adisyon_id; // zincirle
        eklenenler.add(eklenen);
      }
      if (mounted) Navigator.pop(context, eklenenler);
    } catch (_) {
      if (mounted) Navigator.pop(context, eklenenler);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tryf = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Seç'),
        actions: [
          if (!isloading)
            IconButton(
              tooltip: 'Barkod Tara',
              icon: const Icon(Icons.qr_code_scanner_rounded),
              onPressed: _barkodTara,
            ),
        ],
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
                          Text('${_seciliUrunIdler.length} ürün seçildi',
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          Text(tryf.format(_secilenToplam),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: (_seciliUrunIdler.isEmpty || _kaydediliyor) ? null : _kaydet,
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
                      InkWell(
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
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _arama = v),
                    decoration: InputDecoration(
                      hintText: 'Ürün ara...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                Expanded(
                  child: _filtreliUrunler.isEmpty
                      ? Center(child: Text('Ürün bulunamadı', style: TextStyle(color: cs.onSurfaceVariant)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          itemCount: _filtreliUrunler.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final u = _filtreliUrunler[i];
                            final secili = _seciliUrunIdler.contains(u.id);
                            final stokYok = _stoktaYok(u);
                            return Opacity(
                              opacity: stokYok ? 0.45 : 1,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: stokYok
                                    ? null
                                    : () => setState(() {
                                          if (secili) {
                                            _seciliUrunIdler.remove(u.id);
                                          } else {
                                            _seciliUrunIdler.add(u.id);
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
                                              u.urun_adi,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              stokYok ? 'Stokta yok' : 'Stok: ${u.stok_adedi}',
                                              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: TextField(
                                          controller: _fiyatCtrl[u.id],
                                          enabled: !stokYok,
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
