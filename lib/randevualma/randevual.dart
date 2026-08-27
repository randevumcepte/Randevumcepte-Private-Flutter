import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/BosDoluSaatler.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/randevuhizmetleri.dart';
import 'package:randevu_sistem/Models/salonlar.dart';
import 'package:randevu_sistem/randevualma/randevuozetonay.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';
import 'package:randevu_sistem/yonetici/randevular/musteri_paketleri_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RandevuAl extends StatefulWidget {
  /// Reklamdan (boş slot kampanyası) gelindiğinde ekranı belirli bir tarih
  /// ARALIĞINA ve saat aralığına kısıtlar. null ise normal (tüm gün) davranış.
  final String? kisitTarihBas; // başlangıç "yyyy-MM-dd"
  final String? kisitTarihBit; // bitiş "yyyy-MM-dd"
  final String? kisitSaatBas; // "10:00"
  final String? kisitSaatBit; // "12:00"

  const RandevuAl({
    Key? key,
    this.kisitTarihBas,
    this.kisitTarihBit, 
    this.kisitSaatBas,
    this.kisitSaatBit,
  }) : super(key: key);

  @override
  AppointmentEditorState createState() => AppointmentEditorState();
}

class AppointmentEditorState extends State<RandevuAl> {
  bool isloading = true;
  List<IsletmeHizmet> isletmehizmetliste = [];
  List<Personel> personelliste = [];

  List<Personel?> secilipersonel = [];
  List<IsletmeHizmet?> secilihizmet = [];

  List<Salonlar> subeler = [];
  List<List<Personel>> filtreliPersonelListesi = [[]];

  DateTime secilitarih = DateTime.now();
  DateTime secilisaat = DateTime.now();

  TextEditingController randevutarihi = TextEditingController(text: "");
  TextEditingController randevusaati = TextEditingController(text: '');

  List<TextEditingController> hizmet = [];
  List<TextEditingController> personel = [];
  TextEditingController sube = TextEditingController();
  Salonlar? seciliSube;

  final TextEditingController textEditingController = TextEditingController();

  bool formisvalid = true;
  late String seciliisletme;
  List<RandevuHizmet> randevuhizmetleri = [
    RandevuHizmet(
      hizmetler: null,
      hizmet_id: '',
      personel_id: '',
      personeller: null,
      oda_id: '',
      oda: null,
      cihaz_id: '',
      cihaz: null,
      fiyat: '',
      sure_dk: '',
      saat: '',
      saat_bitis: '',
      yardimci_personel: '',
      birusttekiileaynisaat: '',
    )
  ];

  late List<String> tarihListesi;
  String? secilenTarih;
  String? secilenSaat;
  List<BosDoluSaatler> saatler = [];
  List<String> hizmetSecimHintText = [];
  List<String> personelSecimHintText = [];

  @override
  void initState() {
    super.initState();
    initialize();
    tarihListesi = tarihleriOlustur();
    secilenTarih = tarihListesi.first;
    // Reklam kısıtı: kampanya tarih ARALIĞINI uygula — yalnız o günler seçilebilir
    if (widget.kisitTarihBas != null && widget.kisitTarihBas!.isNotEmpty) {
      try {
        final bas = DateTime.parse(widget.kisitTarihBas!);
        final bit = (widget.kisitTarihBit != null && widget.kisitTarihBit!.isNotEmpty)
            ? DateTime.parse(widget.kisitTarihBit!)
            : bas;
        final basG = DateTime(bas.year, bas.month, bas.day);
        final bitG = DateTime(bit.year, bit.month, bit.day);
        final filtreli = tarihListesi.where((t) {
          final d = stringiDateTimeYap(t);
          final dg = DateTime(d.year, d.month, d.day);
          return !dg.isBefore(basG) && !dg.isAfter(bitG);
        }).toList();
        if (filtreli.isNotEmpty) {
          tarihListesi = filtreli;
          secilenTarih = tarihListesi.first;
        }
      } catch (_) {}
    }
  }

  List<String> tarihleriOlustur() {
    final bugun = DateTime.now();
    final toplamGun = 180;
    final List<String> list = [];

    for (int i = 0; i < toplamGun; i++) {
      final gun = bugun.add(Duration(days: i));
      if (i == 0) {
        list.add("Bugün");
      } else if (i == 1) {
        list.add("Yarın");
      } else {
        String gunAdi = DateFormat.E("tr").format(gun);
        String tarih = DateFormat("dd.MM").format(gun);
        list.add("$tarih $gunAdi");
      }
    }
    return list;
  }

  Future<void> hizmetleriGetir() async {
    final isletmeVerileri = await isletmeVerileriGetir(
        seciliSube!.id.toString(), true, await appBundleAl(), '', '', 0, 0);
    List<IsletmeHizmet> isletmehizmetleriliste =
        isletmeVerileri['hizmetler'];
    setState(() {
      hizmetSecimHintText.clear;
      hizmetSecimHintText =
          hizmetSecimHintText.map((e) => 'Hizmet seç...').toList();
      isletmehizmetliste = isletmehizmetleriliste;
    });
    // Hizmet listesi hazir — musterinin paketi varsa paketten randevu teklif et.
    await _paketKontrolu();
  }

  Future<void> initialize() async {
    String salonId = '';

    final isletmeVerileri = await isletmeVerileriGetir(
        salonId, true, await appBundleAl(), '', '', 0, 0);

    List<Salonlar> isletmesubeler = isletmeVerileri['subeler'];
    // Yalnızca online randevuya AÇIK şubeler seçilebilsin. Böylece:
    //  - tek aktif şube → seçimsiz otomatik o şubeden randevu,
    //  - birden fazla aktif şube → şube seçimi (dropdown) görünür.
    // Hiç aktif şube yoksa (buton normalde gizli) tümünü koru — güvenli varsayılan.
    final aktifSubeler =
        isletmesubeler.where((s) => s.musteriOnlineRandevuAktif).toList();
    if (aktifSubeler.isNotEmpty) isletmesubeler = aktifSubeler;
    final tekSube = isletmesubeler.length == 1;

    setState(() {
      hizmet.add(TextEditingController());
      personel.add(TextEditingController());
      secilipersonel.add(null);
      secilihizmet.add(null);
      isletmehizmetliste = []; // hizmetler seçili şube için aşağıda yüklenir
      personelliste = [];
      subeler = isletmesubeler;
      if (tekSube) seciliSube = isletmesubeler[0];
      hizmetSecimHintText.add(
          tekSube ? 'Hizmet seç...' : 'Önce şube seçmeniz gerekir!');
      personelSecimHintText.add('Önce hizmet seçmeniz gerekir!');
      isloading = false;
    });
    // Tek şube otomatik seçildiyse o şubenin hizmetlerini yükle (paket kontrolü içinde).
    if (seciliSube != null) await hizmetleriGetir();
  }

  DateTime stringiDateTimeYap(String tarihString) {
    final bugun = DateTime.now();
    if (tarihString == "Bugün") {
      return DateTime(bugun.year, bugun.month, bugun.day);
    }
    if (tarihString == "Yarın") {
      final yarin = bugun.add(const Duration(days: 1));
      return DateTime(yarin.year, yarin.month, yarin.day);
    }
    String tarihPart = tarihString.split(' ')[0];
    List<String> parts = tarihPart.split('.');
    if (parts.length != 2) {
      throw FormatException("Tarih string formatı yanlış: $tarihString");
    }
    int gun = int.parse(parts[0]);
    int ay = int.parse(parts[1]);
    int yil = bugun.year;
    DateTime dt = DateTime(yil, ay, gun);
    if (dt.isBefore(DateTime(bugun.year, bugun.month, bugun.day))) {
      dt = DateTime(yil + 1, ay, gun);
    }
    return dt;
  }

  void personelSecAdiminaGec(int index, String hizmetId) async {
    String sube = '';
    if (seciliSube != null) sube = seciliSube!.id;
    var personelData =
        await personelAdiminaGec(sube, await appBundleAl(), hizmetId);
    List<Personel> hizmetPersonelleriListe = personelData['personeller'];
    // "Farketmez" (backend'de id=0 sahte personel) musteri randevu ekraninda
    // gosterilmesin — musteri belirli personel secsin. Geri getirmek icin
    // asagidaki filtreyi kaldirip duz atamayi (yorumdaki satiri) kullanin.
    hizmetPersonelleriListe =
        hizmetPersonelleriListe.where((p) => p.id != '0').toList();
    setState(() {
      filtreliPersonelListesi[index] = hizmetPersonelleriListe;
      // filtreliPersonelListesi[index] = hizmetPersonelleriListe; // Farketmez'li hali
      personelSecimHintText[index] = 'Personel seç...';
    });
  }

  void tarihSaatAdiminaGec() async {
    bool secimTamam = randevuhizmetleri.every((element) {
      return element.hizmet_id != '' && element.personel_id != '';
    });
    if (secimTamam) {
      List<String> seciliHizmetler = [];
      List<String> seciliPersoneller = [];
      randevuhizmetleri.forEach((element) {
        seciliHizmetler.add(element.hizmet_id);
        seciliPersoneller.add(element.personel_id);
      });
      String sube = '';
      if (seciliSube != null) sube = seciliSube!.id;
      dynamic randevuSaatleri = await bosVeDoluSaatleriGetir(
          sube,
          seciliPersoneller,
          seciliHizmetler,
          DateFormat("yyyy-MM-dd").format(stringiDateTimeYap(secilenTarih!)),
          await appBundleAl());
      if (randevuSaatleri["saatler"] != null &&
          randevuSaatleri["saatler"] is List) {
        var tumSaatler = (randevuSaatleri["saatler"] as List)
            .map((e) => BosDoluSaatler.fromJson(e))
            .toList();
        // Reklam kısıtı: sadece kampanya saat aralığındaki slotları göster
        final bas = widget.kisitSaatBas;
        final bit = widget.kisitSaatBit;
        if (bas != null && bas.isNotEmpty && bit != null && bit.isNotEmpty) {
          tumSaatler = tumSaatler.where((s) {
            final t = s.saat; // "HH:mm" — aynı formatta sözlüksel karşılaştırma çalışır
            return t.compareTo(bas) >= 0 && t.compareTo(bit) <= 0;
          }).toList();
        }
        saatler = tumSaatler;
      } else {
        saatler = [];
      }
      setState(() {});
    }
  }

  void _hizmetEkle() {
    setState(() {
      hizmet.add(TextEditingController());
      personel.add(TextEditingController());
      secilipersonel.add(null);
      secilihizmet.add(null);
      filtreliPersonelListesi.add([]);
      randevuhizmetleri.add(RandevuHizmet(
        hizmetler: null,
        hizmet_id: '',
        personel_id: '',
        personeller: null,
        oda_id: '',
        oda: null,
        cihaz_id: '',
        cihaz: null,
        fiyat: '',
        sure_dk: '',
        saat: '',
        saat_bitis: '',
        yardimci_personel: '',
        birusttekiileaynisaat: '',
      ));
      hizmetSecimHintText.add(isletmehizmetliste.isEmpty
          ? 'Önce şube seçmeniz gerekir'
          : 'Hizmet seç...');
      personelSecimHintText.add('Önce hizmet seçmeniz gerekir!');
    });
  }

  void _hizmetSil(int index) {
    tarihSaatAdiminaGec();
    setState(() => randevuhizmetleri.removeAt(index));
  }

  // ── PAKETTEN RANDEVU ─────────────────────────────────────────────────────
  // Musteri kendi paketinden randevu olusturabilsin. Yonetici tarafindaki
  // appointment-editor._musteriPaketKontrolu ile AYNI mantik; tek fark musteri
  // sabittir (SharedPreferences 'musteri'), oda/cihaz secimi yoktur.
  //   paketRandevuOnayiGerekli=true  => popup ile secim
  //   paketRandevuOnayiGerekli=false => popup yok, hepsi otomatik eklenir

  /// Ayni salon icin popup'i bir kez sor (sube degisirse tekrar sorulur).
  String? _paketKontroluSalonId;

  /// Onay gerekmeyen senaryoda tum paket/hizmetleri satirlara ceviren yardimci.
  List<Map<String, dynamic>> _tumPaketleriHizmetSatirlarinaCevir(
      List<Map<String, dynamic>> paketDetaylari) {
    final out = <Map<String, dynamic>>[];
    for (final item in paketDetaylari) {
      final isPaket = item['type'] == 'paket';
      final icerik = (item['icerik'] as List?) ?? [];
      for (final h in icerik) {
        out.add({
          'hizmet_id': h['id'],
          'hizmet_adi': h['text']?.toString() ?? '',
          'sure': h['sure'],
          'seans': h['seans'],
          'paket_sure': isPaket ? item['sure'] : null,
          'paket_adi': isPaket ? item['adi']?.toString() : null,
          'adisyon_paket_id': item['adisyon_paket_id'],
          'adisyon_hizmet_id': item['adisyon_hizmet_id'],
          'dusum_miktari': '1',
        });
      }
    }
    return out;
  }

  /// Hizmet suresini cozumle: paketten gelen sure > salon hizmet listesi > 30 dk.
  int _hizmetSuresiCozumle(Map secim) {
    final s1 = int.tryParse(secim['sure']?.toString() ?? '');
    if (s1 != null && s1 > 0) return s1;
    final hid = secim['hizmet_id']?.toString() ?? '';
    if (hid.isNotEmpty) {
      for (final h in isletmehizmetliste) {
        if (h.hizmet_id == hid) {
          final s2 = int.tryParse(h.sure.toString());
          if (s2 != null && s2 > 0) return s2;
          break;
        }
      }
    }
    return 30;
  }

  Future<void> _paketKontrolu() async {
    final salonId = seciliSube?.id;
    if (salonId == null || salonId.isEmpty) return;
    if (_paketKontroluSalonId == salonId) return;
    _paketKontroluSalonId = salonId;

    try {
      final prefs = await SharedPreferences.getInstance();
      final musteriRaw = prefs.getString('musteri');
      if (musteriRaw == null || musteriRaw.isEmpty) return; // giris yapilmamis
      final musteri = jsonDecode(musteriRaw);
      final musteriId = musteri is Map ? musteri['id']?.toString() : null;
      if (musteriId == null || musteriId.isEmpty) return;

      final yanit = await paketVarmiKontrolu(musteriId, salonId);
      if (!mounted) return;
      if (yanit['paketVarMi'] != true) return;

      final paketDetaylari = (yanit['paketDetaylari'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          <Map<String, dynamic>>[];
      if (paketDetaylari.isEmpty) return;

      final bool onayGerekli = yanit['paketRandevuOnayiGerekli'] == true;
      final String? onayMetni = yanit['onayMetni']?.toString();

      List<Map<String, dynamic>>? secilenler;
      if (onayGerekli) {
        secilenler = await showPaketSecimBottomSheet(
          context: context,
          userName: (yanit['userName'] as String?) ??
              (musteri is Map ? (musteri['name']?.toString() ?? '') : ''),
          paketDetaylari: paketDetaylari,
          onayMetni: onayMetni,
        );
      } else {
        secilenler = _tumPaketleriHizmetSatirlarinaCevir(paketDetaylari);
      }
      if (secilenler == null || secilenler.isEmpty || !mounted) return;

      // Paket-bazli toplam sure: ayni pakete ait ILK satira paketin toplam
      // suresi yazilir, sonrakiler 0 dk olur ki takvimde tek slot kaplasin.
      final Map<String, int> paketToplamSure = {};
      final Map<String, int> paketKalemToplam = {};
      for (final s in secilenler) {
        final pAdi = s['paket_adi']?.toString();
        if (pAdi == null || pAdi.isEmpty) continue;
        final pid = s['adisyon_paket_id']?.toString() ?? pAdi;
        final pSure = int.tryParse(s['paket_sure']?.toString() ?? '');
        if (pSure != null && pSure > 0) paketToplamSure[pid] = pSure;
        paketKalemToplam[pid] =
            (paketKalemToplam[pid] ?? 0) + _hizmetSuresiCozumle(s);
      }
      for (final pid in paketKalemToplam.keys) {
        paketToplamSure.putIfAbsent(pid, () => paketKalemToplam[pid]!);
      }
      final Set<String> paketIlkAtildi = {};

      // Hangi satirlara yazildigini tut — sonrasinda personel listesi cekilecek.
      final List<MapEntry<int, String>> personelYuklenecek = [];

      setState(() {
        // Son satir bossa once onu doldur, sonrakiler yeni satir acar.
        int? bosSatirIndex;
        if (randevuhizmetleri.isNotEmpty &&
            secilihizmet.isNotEmpty &&
            secilihizmet.last == null) {
          bosSatirIndex = randevuhizmetleri.length - 1;
        }

        for (final secim in secilenler!) {
          final hizmetIdStr = secim['hizmet_id']?.toString() ?? '';
          if (hizmetIdStr.isEmpty) {
            log('paket secim atlandi: bos hizmet_id - $secim');
            continue;
          }

          // Salon hizmet listesinde ara; yoksa yapay obje uret ve LISTEYE EKLE.
          // (Aksi halde DropdownButton2 "exactly one item with value" atar.)
          IsletmeHizmet hizmetObj;
          final eslesen = isletmehizmetliste
              .where((h) => h.hizmet_id == hizmetIdStr)
              .toList();
          if (eslesen.isNotEmpty) {
            hizmetObj = eslesen.first;
          } else {
            hizmetObj = IsletmeHizmet(
              hizmet_id: hizmetIdStr,
              hizmet: {'hizmet_adi': secim['hizmet_adi']?.toString() ?? ''},
              hizmet_kategorisi: null,
              sure: secim['sure']?.toString() ?? '0',
              fiyat: '0',
              bolum: '',
            );
            isletmehizmetliste.add(hizmetObj);
          }

          final hamSureStr = _hizmetSuresiCozumle(secim).toString();
          final paketAdi = secim['paket_adi']?.toString();
          final adisyonPaketId = secim['adisyon_paket_id'];
          final adisyonHizmetId = secim['adisyon_hizmet_id'];

          String sureStr = hamSureStr;
          if (paketAdi != null && paketAdi.isNotEmpty) {
            final pid = adisyonPaketId?.toString() ?? paketAdi;
            if (!paketIlkAtildi.contains(pid)) {
              sureStr = (paketToplamSure[pid] ?? int.tryParse(hamSureStr) ?? 30)
                  .toString();
              paketIlkAtildi.add(pid);
            } else {
              sureStr = '0';
            }
          }

          final yeniHizmet = RandevuHizmet(
            hizmetler: hizmetObj.hizmet,
            hizmet_id: hizmetIdStr,
            personel_id: '',
            personeller: null,
            oda_id: '',
            oda: null,
            cihaz_id: '',
            cihaz: null,
            fiyat: '0', // paket — zaten odenmis
            sure_dk: sureStr,
            saat: '',
            saat_bitis: '',
            yardimci_personel: '',
            birusttekiileaynisaat: '',
            paket_adi: paketAdi,
            adisyon_paket_id: adisyonPaketId,
            adisyon_hizmet_id: adisyonHizmetId,
            dusum_miktari: secim['dusum_miktari']?.toString() ?? '1',
          );

          int hedefIndex;
          if (bosSatirIndex != null) {
            hedefIndex = bosSatirIndex;
            secilihizmet[hedefIndex] = hizmetObj;
            randevuhizmetleri[hedefIndex] = yeniHizmet;
            bosSatirIndex = null;
          } else {
            hedefIndex = randevuhizmetleri.length;
            hizmet.add(TextEditingController());
            personel.add(TextEditingController());
            secilipersonel.add(null);
            secilihizmet.add(hizmetObj);
            filtreliPersonelListesi.add([]);
            randevuhizmetleri.add(yeniHizmet);
            hizmetSecimHintText.add('Hizmet seç...');
            personelSecimHintText.add('Personel seç...');
          }
          personelYuklenecek.add(MapEntry(hedefIndex, hizmetIdStr));
        }
      });

      // Her paket satiri icin personel listesini yukle (musteri kendi secer).
      for (final e in personelYuklenecek) {
        personelSecAdiminaGec(e.key, e.value);
      }

      if (mounted && personelYuklenecek.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${personelYuklenecek.length} paket hizmeti randevuya eklendi. Personel ve saat seçin.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, st) {
      log('musteri paket kontrolu hatasi: $e', stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.08),
                Colors.white,
              ),
              Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.04),
                Colors.white,
              ),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: isloading
              ? Center(
                  child: CircularProgressIndicator(color: scheme.primary),
                )
              : Column(
                  children: [
                    _topBar(context),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: ListView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          children: [
                            if (subeler.length > 1) ...[
                              _sectionHeader(context, 'Şube Seçimi',
                                  icon: Icons.store_mall_directory_rounded),
                              const SizedBox(height: 10),
                              _subeDropdown(context),
                              const SizedBox(height: 20),
                            ],
                            _sectionHeaderWithAction(
                              context,
                              title: 'Hizmet & Personel',
                              icon: Icons.spa_rounded,
                              actionLabel: 'Hizmet Ekle',
                              actionIcon: Icons.add_rounded,
                              onAction: _hizmetEkle,
                            ),
                            const SizedBox(height: 10),
                            ...List.generate(randevuhizmetleri.length,
                                (i) => _hizmetPersonelCard(context, i)),
                            const SizedBox(height: 22),
                            _sectionHeader(context, 'Tarih Seçimi',
                                icon: Icons.event_rounded),
                            const SizedBox(height: 10),
                            _tarihStrip(context),
                            const SizedBox(height: 22),
                            _sectionHeader(context, 'Uygun Saatler',
                                icon: Icons.access_time_rounded),
                            const SizedBox(height: 10),
                            _saatlerCard(context),
                            const SizedBox(height: 24),
                            _legendRow(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────
  Widget _topBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _circleIconBtn(
            context,
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni Randevu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: scheme.onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Adımları takip et, dakikalar içinde tamamla',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: scheme.primary, size: 20),
        ),
      ),
    );
  }

  // ── SECTION HEADERS ──────────────────────────────────────────────────────
  Widget _sectionHeader(BuildContext context, String title,
      {required IconData icon}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeaderWithAction(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String actionLabel,
    required IconData actionIcon,
    required VoidCallback onAction,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: _sectionHeader(context, title, icon: icon)),
        Material(
          color: scheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(actionIcon, size: 16, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── ŞUBE DROPDOWN ────────────────────────────────────────────────────────
  Widget _subeDropdown(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<Salonlar>(
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'Şube Seç',
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          items: subeler
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.salon_adi,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          value: seciliSube,
          onChanged: (value) {
            setState(() {
              seciliSube = value;
              hizmetleriGetir();
            });
          },
          buttonStyleData: ButtonStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            height: 52,
            width: MediaQuery.of(context).size.width - 32,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(height: 44),
          dropdownSearchData: DropdownSearchData(
            searchController: sube,
            searchInnerWidgetHeight: 52,
            searchInnerWidget: Padding(
              padding: const EdgeInsets.all(8),
              child: TextFormField(
                controller: sube,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  hintText: 'Şube ara...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) => item.value!.salon_adi
                .toString()
                .toLowerCase()
                .contains(searchValue.toLowerCase()),
          ),
        ),
      ),
    );
  }

  // ── HİZMET + PERSONEL KARTI ──────────────────────────────────────────────
  Widget _hizmetPersonelCard(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    final isFirst = index == 0;
    final isOnly = randevuhizmetleri.length == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isFirst ? 'Ana Hizmet' : 'Ek Hizmet ${index + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              if (!isOnly)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: scheme.error,
                    size: 22,
                  ),
                  onPressed: () => _hizmetSil(index),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _fieldLabel(context, 'Hizmet', Icons.spa_rounded),
          const SizedBox(height: 6),
          _hizmetDropdown(context, index),
          const SizedBox(height: 12),
          _fieldLabel(context, 'Personel', Icons.person_outline_rounded),
          const SizedBox(height: 6),
          _personelDropdown(context, index),
          if (secilihizmet[index] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _miniStat(
                  context,
                  icon: Icons.schedule_rounded,
                  value: '${randevuhizmetleri[index].sure_dk} dk',
                  tint: ext.infoColor,
                ),
                // Fiyat girilmemis/0 ise "null ₺" yerine ciplen hic gosterme
                if (_fiyatEtiketi(randevuhizmetleri[index].fiyat) != null) ...[
                  const SizedBox(width: 8),
                  _miniStat(
                    context,
                    icon: Icons.payments_outlined,
                    value: _fiyatEtiketi(randevuhizmetleri[index].fiyat)!,
                    tint: ext.successColor,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Fiyat cipi etiketi. Fiyat null/bos/0 ise null doner (cip gizlenir).
  /// Ornek: "1500" -> "1500 ₺", "80.5" -> "80,50 ₺".
  String? _fiyatEtiketi(dynamic fiyat) {
    final n = double.tryParse((fiyat?.toString() ?? '').trim().replaceAll(',', '.'));
    if (n == null || n <= 0) return null;
    final tam = n % 1 == 0;
    final s = tam ? n.toInt().toString() : n.toStringAsFixed(2).replaceAll('.', ',');
    return '$s ₺';
  }

  Widget _fieldLabel(BuildContext context, String text, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: scheme.onSurface.withValues(alpha: 0.55)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  Widget _miniStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }

  /// DropdownButton2 item listesi: ayni hizmet_id birden fazla kez gelirse
  /// (bir hizmet birden cok kategoride olabilir) DropdownButton2 "exactly one
  /// item with value" assertion atar — cunku IsletmeHizmet.== hizmet_id bazli.
  /// Ilk gorulen kaydi tutarak tekillestir.
  List<IsletmeHizmet> get _tekilHizmetler {
    final gorulen = <String>{};
    final out = <IsletmeHizmet>[];
    for (final h in isletmehizmetliste) {
      if (gorulen.add(h.hizmet_id)) out.add(h);
    }
    return out;
  }

  Widget _hizmetDropdown(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.04),
          Colors.white,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<IsletmeHizmet>(
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              hizmetSecimHintText[index],
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          items: _tekilHizmetler
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.hizmet['hizmet_adi'],
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          value: secilihizmet[index],
          onChanged: (value) {
            setState(() {
              secilihizmet[index] = value!;
              randevuhizmetleri[index].hizmet_id = value.hizmet_id;
              randevuhizmetleri[index].sure_dk = value.sure;
              randevuhizmetleri[index].fiyat = value.fiyat;
              randevuhizmetleri[index].hizmetler = value.hizmet;
              personelSecAdiminaGec(index, value.hizmet_id);
              tarihSaatAdiminaGec();
            });
          },
          buttonStyleData: ButtonStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 46,
            width: MediaQuery.of(context).size.width - 64,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(height: 56),
          dropdownSearchData: DropdownSearchData(
            searchController: hizmet[index],
            searchInnerWidgetHeight: 52,
            searchInnerWidget: Padding(
              padding: const EdgeInsets.all(8),
              child: TextFormField(
                controller: hizmet[index],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  hintText: 'Hizmet ara...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) => item.value!.hizmet["hizmet_adi"]
                .toString()
                .toLowerCase()
                .contains(searchValue.toLowerCase()),
          ),
        ),
      ),
    );
  }

  Widget _personelDropdown(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.04),
          Colors.white,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<Personel>(
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              personelSecimHintText[index],
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          value: secilipersonel[index],
          items: filtreliPersonelListesi[index]
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.personel_adi,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              secilipersonel[index] = value!;
              randevuhizmetleri[index].personel_id = value.id;
              randevuhizmetleri[index].personeller = value;
              tarihSaatAdiminaGec();
            });
          },
          buttonStyleData: ButtonStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 46,
            width: MediaQuery.of(context).size.width - 64,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(height: 44),
          dropdownSearchData: DropdownSearchData(
            searchController: personel[index],
            searchInnerWidgetHeight: 52,
            searchInnerWidget: Padding(
              padding: const EdgeInsets.all(8),
              child: TextFormField(
                controller: personel[index],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  hintText: 'Personel ara...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) => item.value!.personel_adi
                .toString()
                .toLowerCase()
                .contains(searchValue.toLowerCase()),
          ),
        ),
      ),
    );
  }

  // ── TARİH STRIP ──────────────────────────────────────────────────────────
  Widget _tarihStrip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tarihListesi.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final tarih = tarihListesi[i];
          final selected = secilenTarih == tarih;

          String topLabel;
          String bottomLabel;
          if (tarih == 'Bugün' || tarih == 'Yarın') {
            topLabel = tarih;
            bottomLabel = DateFormat('dd.MM').format(
              DateTime.now().add(Duration(days: tarih == 'Bugün' ? 0 : 1)),
            );
          } else {
            final parts = tarih.split(' ');
            topLabel = parts.length > 1 ? parts[1] : tarih;
            bottomLabel = parts[0];
          }

          return Material(
            color: selected ? scheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  secilenTarih = tarih;
                  secilenSaat = null;
                  tarihSaatAdiminaGec();
                });
              },
              child: Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : scheme.primary.withValues(alpha: 0.18),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      topLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.85)
                            : scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bottomLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: selected ? Colors.white : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── SAATLER ──────────────────────────────────────────────────────────────
  Widget _saatlerCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;

    bool selectionComplete = randevuhizmetleri.every(
      (e) => e.hizmet_id.isNotEmpty && e.personel_id.isNotEmpty,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.kisitSaatBas != null && widget.kisitSaatBas!.isNotEmpty) ...[
            _kampanyaBanner(context),
            const SizedBox(height: 12),
          ],
          !selectionComplete
          ? _saatlerEmpty(
              context,
              icon: Icons.touch_app_rounded,
              title: 'Önce hizmet ve personel seç',
              subtitle:
                  'Uygun saatler hizmet/personel seçtikten sonra burada listelenir.',
            )
          : (saatler.isEmpty
              ? _saatlerEmpty(
                  context,
                  icon: Icons.event_busy_rounded,
                  title: 'Uygun saat bulunamadı',
                  subtitle: 'Başka bir tarih dene.',
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: saatler.map((saat) {
                    final dolu = saat.dolu == '1';
                    final selected = secilenSaat == saat.saat;
                    final base = dolu
                        ? scheme.onSurface.withValues(alpha: 0.08)
                        : (selected
                            ? scheme.primary
                            : Color.alphaBlend(
                                ext.successColor.withValues(alpha: 0.10),
                                Colors.white,
                              ));
                    final textColor = dolu
                        ? scheme.onSurface.withValues(alpha: 0.4)
                        : (selected ? Colors.white : ext.successColor);
                    final borderColor = dolu
                        ? Colors.transparent
                        : (selected
                            ? Colors.transparent
                            : ext.successColor.withValues(alpha: 0.35));

                    return Material(
                      color: base,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: dolu
                            ? null
                            : () {
                                setState(() {
                                  if (secilenSaat == saat.saat) {
                                    secilenSaat = null;
                                  } else {
                                    secilenSaat = saat.saat;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RandevuOnay(
                                          isletmebilgi: {},
                                          seciliHizmetler:
                                              randevuhizmetleri,
                                          tarih: DateFormat("dd.MM.yyyy")
                                              .format(stringiDateTimeYap(
                                                  secilenTarih!)),
                                          saat: secilenSaat!,
                                          salonid: seciliSube?.id ?? '',
                                        ),
                                      ),
                                    );
                                  }
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: scheme.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            saat.saat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                              color: textColor,
                              decoration: dolu
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )),
        ],
      ),
    );
  }

  /// Reklam (boş slot) kampanyası aktifken saatlerin üstünde gösterilen uyarı şeridi.
  Widget _kampanyaBanner(BuildContext context) {
    final bas = widget.kisitSaatBas ?? '';
    final bit = widget.kisitSaatBit ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kampanya saatleri: $bas – $bit. Bu aralıktan randevu al, indirim kuponun geçerli olsun.',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saatlerEmpty(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.15),
                  scheme.tertiary.withValues(alpha: 0.15),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: scheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.55),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── LEGEND ───────────────────────────────────────────────────────────────
  Widget _legendRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    Widget dot(Color c) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(c),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          item(ext.successColor, 'Müsait'),
          item(scheme.primary, 'Seçili'),
          item(scheme.onSurface.withValues(alpha: 0.2), 'Dolu'),
        ],
      ),
    );
  }
}
