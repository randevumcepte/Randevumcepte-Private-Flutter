import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/datetimeformatting.dart';
import 'package:randevu_sistem/Frontend/MusteriDanisanSecimLazyLoad.dart';
import 'package:randevu_sistem/Frontend/lazyload.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';

import 'package:randevu_sistem/Models/cihazlar.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/odalar.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/randevuhizmetleri.dart';
import 'package:randevu_sistem/Models/randevuhizmetyardimcipersonelleri.dart';

import 'package:randevu_sistem/Models/randevutekrarsikligi.dart';
import 'package:randevu_sistem/yeni/app_colors.dart';
import 'package:randevu_sistem/theme/premium_components.dart';
import '../diger/menu/musteriler/yeni_musteri.dart';
import 'hizmet_add.dart';
import 'musteri_paketleri_dialog.dart';
import 'hizli_paket_randevu_sheet.dart';
import 'package:randevu_sistem/yonetici/randevular/musteri.dart';

class AppointmentEditor extends StatefulWidget {
  final dynamic isletmebilgi;
  final String tarihsaat;
  final String personel_id;
  final String? resourceId;
  final String? resourceType;
  final int kullanicirolu;

  const AppointmentEditor({
    super.key,
    required this.isletmebilgi,
    required this.tarihsaat,
    required this.personel_id,
    this.resourceId,
    this.resourceType,
    required this.kullanicirolu
  });

  @override
  AppointmentEditorState createState() => AppointmentEditorState();
}

class AppointmentEditorState extends State<AppointmentEditor> {
  late List<IsletmeHizmet> isletmehizmetliste;
  late List<Personel> personelliste;
  late List<Cihaz> cihazliste;
  late List<Oda> odaliste;
  late List<MusteriDanisan> musteridanisanlar;
  bool isloading = true;
  String? _initError;
  final GlobalKey<LazyDropdownState> dropdownKey = GlobalKey<LazyDropdownState>();

  TextEditingController personel = TextEditingController();

  List<Personel?> secilipersonel = [];
  List<Oda?> secilioda = [];
  List<Cihaz?> secilicihaz = [];
  List<IsletmeHizmet?> secilihizmet = [];
  List<List<Personel?>> seciliyardimcipersonel = [];
  MusteriDanisan? secilimusteridanisan;

  // v2 randevu-ekle-modal-v2 filtreleme mapleri (backend personel/oda/cihaz/
  // hizmet pivotlarindan dolduruluyor). Bos = filtre yok.
  Map<String, List<String>> _personelHizmetMap = {};
  Map<String, List<String>> _cihazHizmetMap = {};
  Map<String, List<String>> _odaHizmetMap = {};
  Map<String, List<String>> _odaPersonelMap = {};

  /// v2FilterHizmetler karsiligi: secili personel/cihaz/oda'ya gore izinli
  /// hizmet id'lerini birleştirir. Hicbiri tanımlı atama yapmamissa tüm
  /// listeyi döner (permisif). Strict: tanımlı atama varsa kesişimle filtreler.
  List<IsletmeHizmet> _filtreliHizmetler({
    Personel? personel,
    Cihaz? cihaz,
    Oda? oda,
  }) {
    final tum = isletmehizmetliste;
    List<String>? izinli;
    if (personel != null) {
      final hp = _personelHizmetMap[personel.id];
      if (hp != null && hp.isNotEmpty) izinli = List<String>.from(hp);
    }
    if (cihaz != null) {
      final hc = _cihazHizmetMap[cihaz.id];
      if (hc != null && hc.isNotEmpty) {
        izinli = (izinli ?? <String>[])..addAll(hc);
      }
    }
    if (oda != null) {
      final ho = _odaHizmetMap[oda.id];
      if (ho != null && ho.isNotEmpty) {
        izinli = (izinli ?? <String>[])..addAll(ho);
      }
    }
    if (izinli == null || izinli.isEmpty) return tum;
    final s = izinli.toSet();
    return tum.where((h) => s.contains(h.hizmet_id)).toList();
  }

  /// v2RefreshPersonelByOda karsiligi: oda secilince personel listesi
  /// odanin atanmis personellerine filtrelenir; atama yoksa hepsi gosterilir.
  List<Personel> _filtreliPersoneller({Oda? oda}) {
    if (oda == null) return personelliste;
    final izinli = _odaPersonelMap[oda.id];
    if (izinli == null || izinli.isEmpty) return personelliste;
    final s = izinli.toSet();
    return personelliste.where((p) => s.contains(p.id)).toList();
  }

  bool tekrarlayanrandevu = false;

  bool _isAllDay = false;
  DateTime secilitarih = DateTime.now();
  DateTime secilisaat = DateTime.now();
  List<Color> _colorCollection = <Color>[];
  RandevuTekrarSikligi? secilitekrarsikligi;
  String? secilimusteridanisanid;
  String? secilimusteridanisanadi;

  List<RandevuHizmetYardimciPersonelleri> randevuhizmetyardimcipersoneller = [];
  TextEditingController randevutarihi = TextEditingController(text: "");
  TextEditingController randevusaati = TextEditingController(text: '');
  TextEditingController tekrarsayisi = TextEditingController(text: '1');
  TextEditingController notlar = TextEditingController(text: '');
  List<TextEditingController> suredk = [];
  List<TextEditingController> fiyat = [];
  List<TextEditingController> oda = [];
  List<TextEditingController> cihaz = [];
  List<TextEditingController> hizmet = [];

  int offset = 0;
  final int limit = 50;
  bool isLoading = false;
  bool hasMore = true;

  TextEditingController musteridanisan = TextEditingController();
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
        // chain default (backend semantik): birlestir bos/yok => bir sonraki
        // hizmet bu hizmetin bitis saatinden baslar. '1' = paralel (ayni saat).
        birusttekiileaynisaat: '',
    ),
  ];

  List<RandevuTekrarSikligi> tekrarsikliklari = [
    RandevuTekrarSikligi(siklik_str: "+1 day", tekrar_sikligi: "Her Gün"),
    RandevuTekrarSikligi(siklik_str: "+2 days", tekrar_sikligi: "2 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+3 days", tekrar_sikligi: "3 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+4 days", tekrar_sikligi: "4 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+5 days", tekrar_sikligi: "5 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+6 days", tekrar_sikligi: "6 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+1 week", tekrar_sikligi: "Haftada Bir"),
    RandevuTekrarSikligi(siklik_str: "+2 weeks", tekrar_sikligi: "2 Haftada Bir"),
    RandevuTekrarSikligi(siklik_str: "+3 weeks", tekrar_sikligi: "3 Haftada Bir"),
    RandevuTekrarSikligi(siklik_str: "+4 weeks", tekrar_sikligi: "4 Haftada Bir"),
    RandevuTekrarSikligi(siklik_str: "+1 month", tekrar_sikligi: "Her Ay"),
    RandevuTekrarSikligi(siklik_str: "+45 days", tekrar_sikligi: "45 Günde Bir"),
    RandevuTekrarSikligi(siklik_str: "+2 months", tekrar_sikligi: "2 Ayda Bir"),
    RandevuTekrarSikligi(siklik_str: "+3 months", tekrar_sikligi: "3 Ayda Bir"),
    RandevuTekrarSikligi(siklik_str: "+6 months", tekrar_sikligi: "6 Ayda Bir"),
  ];

  // YENİ: Klavye kontrolü için FocusNode
  final FocusNode _notlarFocusNode = FocusNode();
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    initialize();

    // YENİ: Klavye durumunu dinle
    _notlarFocusNode.addListener(() {
      setState(() {
        _keyboardVisible = _notlarFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // YENİ: FocusNode'u temizle
    _notlarFocusNode.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    if (!mounted) return;
    setState(() {
      isloading = true;
      _initError = null;
    });
    try {
      final salonId = await secilisalonid();
      if (salonId == null || salonId.isEmpty) {
        throw Exception('Seçili işletme bulunamadı. Lütfen tekrar giriş yapın.');
      }
      seciliisletme = salonId;

      final isletmeVerileri = await isletmeVerileriGetir(
        seciliisletme,
        false,
        '',
        '',
        '',
        0,
        0,
      ).timeout(const Duration(seconds: 25));

      List<MusteriDanisan> musteridanisanliste = isletmeVerileri['musteriler'];
      List<IsletmeHizmet> isletmehizmetleriliste = isletmeVerileri['hizmetler'];
      List<Personel> isletmepersonellerliste = isletmeVerileri['personeller'];
      List<Cihaz> isletmecihazliste = isletmeVerileri['cihazlar'];
      List<Oda> isletmeodaliste = isletmeVerileri['odalar'];
      final personelHizmetMap =
          (isletmeVerileri['personel_hizmet_map'] as Map?) ?? {};
      final cihazHizmetMap =
          (isletmeVerileri['cihaz_hizmet_map'] as Map?) ?? {};
      final odaHizmetMap = (isletmeVerileri['oda_hizmet_map'] as Map?) ?? {};
      final odaPersonelMap =
          (isletmeVerileri['oda_personel_map'] as Map?) ?? {};

      if (!mounted) return;
      setState(() {
        _personelHizmetMap = Map<String, List<String>>.from(personelHizmetMap
            .map((k, v) => MapEntry(k.toString(), List<String>.from(v))));
        _cihazHizmetMap = Map<String, List<String>>.from(cihazHizmetMap
            .map((k, v) => MapEntry(k.toString(), List<String>.from(v))));
        _odaHizmetMap = Map<String, List<String>>.from(odaHizmetMap
            .map((k, v) => MapEntry(k.toString(), List<String>.from(v))));
        _odaPersonelMap = Map<String, List<String>>.from(odaPersonelMap
            .map((k, v) => MapEntry(k.toString(), List<String>.from(v))));
        // Liste sıfırla — retry'de duplicate eklenmesin
        suredk.clear();
        fiyat.clear();
        oda.clear();
        cihaz.clear();
        hizmet.clear();
        secilipersonel.clear();
        seciliyardimcipersonel.clear();
        secilihizmet.clear();
        secilioda.clear();
        secilicihaz.clear();

        suredk.add(TextEditingController());
        fiyat.add(TextEditingController());
        oda.add(TextEditingController());
        cihaz.add(TextEditingController());
        hizmet.add(TextEditingController());
        secilipersonel.add(null);
        seciliyardimcipersonel.add([null]);
        secilihizmet.add(null);
        secilioda.add(null);
        secilicihaz.add(null);

        musteridanisanlar = musteridanisanliste;
        isletmehizmetliste = isletmehizmetleriliste;
        personelliste = isletmepersonellerliste;
        odaliste = isletmeodaliste;
        cihazliste = isletmecihazliste;

        if (widget.tarihsaat != "") {
          randevutarihi.text =
              DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.tarihsaat));
          randevusaati.text =
              DateFormat('HH:mm').format(DateTime.parse(widget.tarihsaat));
        }

        _autoSelectResource();

        isloading = false;
      });
    } catch (e, st) {
      log('AppointmentEditor initialize hatası: $e', stackTrace: st);
      if (!mounted) return;
      setState(() {
        isloading = false;
        _initError = e is TimeoutException
            ? 'Sunucuya ulaşılamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.'
            : 'Veriler yüklenemedi: $e';
      });
    }
  }

  void _autoSelectResource() {
    if (widget.resourceId != null && widget.resourceType != null) {
      switch (widget.resourceType) {
        case 'personel':
          Personel? foundPersonel = personelliste.firstWhere(
                (personel) => personel.id == widget.resourceId,
            orElse: () => Personel(id: '', personel_adi: '', salon_id: '', profil_resmi: '', cinsiyet: '', unvan: '', hizmet_prim_yuzde: '', urun_prim_yuzde: '', paket_prim_yuzde: '', cep_telefon: '', renk: '', maas: '', hesap_turu: '', dahili_no: '', takvim_sirasi: '', takvimde_gorunsun: '', durum: ''),
          );
          if (foundPersonel.id.isNotEmpty) {
            secilipersonel[0] = foundPersonel;
            randevuhizmetleri[0].personel_id = foundPersonel.id;
          }
          break;

        case 'hizmet':
          IsletmeHizmet? foundHizmet = isletmehizmetliste.firstWhere(
                (hizmet) => hizmet.hizmet_id == widget.resourceId,
            orElse: () => IsletmeHizmet(
                hizmet_id: '',
                hizmet: {'hizmet_adi': ''},
                sure: '',
                fiyat: '',
                hizmet_kategorisi: null, bolum: ''
            ),
          );
          if (foundHizmet.hizmet_id.isNotEmpty) {
            secilihizmet[0] = foundHizmet;
            randevuhizmetleri[0].hizmet_id = foundHizmet.hizmet_id;
            suredk[0].text = foundHizmet.sure != 'null' ? foundHizmet.sure : '30';
            fiyat[0].text = foundHizmet.fiyat != 'null' ? foundHizmet.fiyat : '';
            randevuhizmetleri[0].sure_dk = foundHizmet.sure != 'null' ? foundHizmet.sure : '30';
            randevuhizmetleri[0].fiyat = foundHizmet.fiyat != 'null' ? foundHizmet.fiyat : '';
          }
          break;

        case 'cihaz':
          Cihaz? foundCihaz = cihazliste.firstWhere(
                (cihaz) => cihaz.id == widget.resourceId,
            orElse: () => Cihaz(id: '', cihaz_adi: '',  durum: '', aciklama: '', aktifmi: ''),
          );
          if (foundCihaz.id.isNotEmpty) {
            secilicihaz[0] = foundCihaz;
            randevuhizmetleri[0].cihaz_id = foundCihaz.id;
          }
          break;

        case 'oda':
          Oda? foundOda = odaliste.firstWhere(
                (oda) => oda.id == widget.resourceId,
            orElse: () => Oda(id: '', oda_adi: '',  durum: '', aciklama: '', aktifmi: ''),
          );
          if (foundOda.id.isNotEmpty) {
            secilioda[0] = foundOda;
            randevuhizmetleri[0].oda_id = foundOda.id;
          }
          break;
      }
    }

    if (widget.personel_id != null && widget.personel_id.isNotEmpty) {
      Personel? foundPersonel = personelliste.firstWhere(
            (personel) => personel.id == widget.personel_id,
        orElse: () => Personel(id: '', personel_adi: '', salon_id: '', profil_resmi: '', cinsiyet: '', unvan: '', hizmet_prim_yuzde: '', urun_prim_yuzde: '', paket_prim_yuzde: '', cep_telefon: '', renk: '', maas: '', hesap_turu: '', dahili_no: '', takvim_sirasi: '', takvimde_gorunsun: '', durum: '', ),
      );
      if (foundPersonel.id.isNotEmpty) {
        secilipersonel[0] = foundPersonel;
        randevuhizmetleri[0].personel_id = foundPersonel.id;
      }
    }
  }

  Future<void> tarihsec(BuildContext context) async {
    // YENİ: Klavyeyi kapat
    _closeKeyboard();

    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: DateTime(2100));

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        randevutarihi.text = formattedDate;
      });
    }
  }

  // YENİ: Klavyeyi kapatma fonksiyonu
  void _closeKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// "Ustteki ile aynı saatte (paralel)" checkbox'i — hizmet satiri >0 iken
  /// gorunur. Semantik: satir i tiklandiginda satir i-1'in
  /// `birusttekiileaynisaat` alani "1" olur; backend randevuekleguncelle
  /// value["birlestir"]=="1" iken saat ilerletmedigi icin satir i, satir
  /// i-1 ile ayni baslangic saatinde kaydedilir (web modali ile ayni akis).
  Widget _buildBirlestirCheckbox(int i) {
    if (i <= 0 || i - 1 >= randevuhizmetleri.length) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final aktif = randevuhizmetleri[i - 1].birusttekiileaynisaat == '1';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          _closeKeyboard();
          setState(() {
            randevuhizmetleri[i - 1].birusttekiileaynisaat = aktif ? '' : '1';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: aktif
                ? scheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: aktif
                  ? scheme.primary.withValues(alpha: 0.35)
                  : scheme.outline.withValues(alpha: 0.3),
              width: 1,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                aktif
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: aktif
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 8),
              Icon(Icons.link_rounded,
                  size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Üsttekiyle aynı saatte (paralel)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: aktif
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Onay gerekmeyen senaryoda: tum paket/hizmetleri dogrudan satirlara
  /// ceviren yardimci. Dialog'un secim listesi olusturma mantigi ile bire bir
  /// ayni — web tarafi convertAllPackagesToServiceData() karsiligi.
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

  /// Musteri secildikten sonra cagrilir: aktif paket/hizmet var mi backend'e sor.
  /// Varsa bottom sheet ac, secilenleri hizmet satirlarina inject et.
  /// Web tarafindaki paketleri-goster popup'inin Flutter karsiligi.
  Future<void> _musteriPaketKontrolu(MusteriDanisan musteri) async {
    try {
      final yanit = await paketVarmiKontrolu(
        musteri.id.toString(),
        seciliisletme.toString(),
      );
      if (!mounted) return;

      final paketVarMi = yanit['paketVarMi'] == true;
      if (!paketVarMi) return;

      final paketDetaylari = (yanit['paketDetaylari'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          <Map<String, dynamic>>[];
      if (paketDetaylari.isEmpty) return;

      // Web randevumcepte-yeni semantigi:
      //   paketRandevuOnayiGerekli=true  => popup ile kullanici secimi
      //   paketRandevuOnayiGerekli=false => popup gosterme, hepsini oto ekle
      final bool onayGerekli = yanit['paketRandevuOnayiGerekli'] == true;
      final String? onayMetni = yanit['onayMetni']?.toString();

      List<Map<String, dynamic>>? secilenlerHam;
      if (onayGerekli) {
        secilenlerHam = await showPaketSecimBottomSheet(
          context: context,
          userName: (yanit['userName'] as String?) ?? (musteri.name ?? ''),
          paketDetaylari: paketDetaylari,
          onayMetni: onayMetni,
        );
      } else {
        secilenlerHam = _tumPaketleriHizmetSatirlarinaCevir(paketDetaylari);
      }
      if (secilenlerHam == null || secilenlerHam.isEmpty || !mounted) return;
      final List<Map<String, dynamic>> secilenler = secilenlerHam;

      // BIRDEN FAZLA hizmet -> Hizli Paket Randevu sheet'i ac (web ile ayni mantik):
      // her hizmet icin inline personel/oda/cihaz/sure secimi + dogrudan olustur.
      // TEK hizmet -> asagidaki mevcut "forma ekle" akisi devam eder.
      if (secilenler.length > 1) {
        final takvimTuru = int.tryParse(
                widget.isletmebilgi['randevu_takvim_turu']?.toString() ?? '0') ??
            0;
        // Mevcut formda secili personel/oda/cihaz varsa base olarak gec
        Personel? bP;
        for (int i = secilipersonel.length - 1; i >= 0; i--) {
          if (secilipersonel[i] != null) { bP = secilipersonel[i]; break; }
        }
        Oda? bO;
        for (int i = secilioda.length - 1; i >= 0; i--) {
          if (secilioda[i] != null) { bO = secilioda[i]; break; }
        }
        Cihaz? bC;
        for (int i = secilicihaz.length - 1; i >= 0; i--) {
          if (secilicihaz[i] != null) { bC = secilicihaz[i]; break; }
        }

        final hazirHizmetler = await showHizliPaketRandevuSheet(
          context: context,
          secilenler: secilenler,
          personelliste: personelliste,
          odaliste: odaliste,
          cihazliste: cihazliste,
          isletmehizmetliste: isletmehizmetliste,
          takvimTuru: takvimTuru,
          musteriAdi: (yanit['userName'] as String?) ?? (musteri.name ?? ''),
          tarih: randevutarihi.text,
          saat: randevusaati.text,
          basePersonel: bP,
          baseOda: bO,
          baseCihaz: bC,
        );
        if (hazirHizmetler == null || hazirHizmetler.isEmpty || !mounted) return;

        // Dogrudan randevu olustur
        randevuEkleGuncelle(
          '',
          '',
          '',
          secilimusteridanisan!,
          randevutarihi.text,
          randevusaati.text,
          hazirHizmetler,
          <RandevuHizmetYardimciPersonelleri>[],
          false,
          '',
          null,
          notlar.text,
          seciliisletme.toString(),
          context,
          'salon',
          '1',
          widget.isletmebilgi,
        );
        return;
      }

      int eklenenSatir = 0;
      setState(() {
        // Paket secimi: TUM secilen hizmetler ayni groupId'ye sahip olur =>
        // UI tarafinda tek bir "Hizmet Grubu" karti icinde gosterilirler
        // (1 personel + N hizmet). Web modali ile esit davranis.
        // Mevcut son satir bossa onun groupId'sini kullan ve uzerine yaz;
        // degilse yeni unique groupId uret.
        int? bosSatirIndex;
        String hedefGroupId;
        if (randevuhizmetleri.isNotEmpty &&
            secilihizmet.isNotEmpty &&
            secilihizmet.last == null) {
          bosSatirIndex = randevuhizmetleri.length - 1;
          hedefGroupId = randevuhizmetleri[bosSatirIndex].groupId;
        } else {
          hedefGroupId = 'g-${DateTime.now().millisecondsSinceEpoch}';
        }

        // Personel devralma: kullanici paket eklemeden once personel
        // secmisse, paket satirlarinda da ayni personel kullanilsin.
        // Once bos satirin personeli; yoksa son dolu satirin personeli.
        Personel? hedefPersonel;
        if (bosSatirIndex != null) {
          hedefPersonel = secilipersonel[bosSatirIndex];
        }
        if (hedefPersonel == null && secilipersonel.isNotEmpty) {
          for (int i = secilipersonel.length - 1; i >= 0; i--) {
            if (secilipersonel[i] != null) {
              hedefPersonel = secilipersonel[i];
              break;
            }
          }
        }
        final String hedefPersonelId = hedefPersonel?.id ?? '';

        // Paket-bazli toplam sure hesabi: ayni pakete ait tum hizmetlerin
        // suresi PAKETTEKI ILK satira yazilir, geri kalanlar 0 dk olur ki
        // takvimde tek slot kaplasin (chain'de toplam = paket suresi).
        // Sure backend'den bos gelirse: salon hizmet listesinden cek,
        // yoksa 30 dk varsay (her kalemin asgari katkisi).
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

        // Oncelik: dialog'tan gelen paket_sure (paketin TOPLAM suresi, ornegin
        // listede '90 dk' gosterilen deger). Yoksa kalem sureleri toplami,
        // o da yoksa _hizmetSuresiCozumle ile 30 dk varsayim.
        final Map<String, int> paketToplamSure = {};
        final Map<String, int> paketKalemToplam = {};
        for (final s in secilenler) {
          final pAdi = s['paket_adi']?.toString();
          if (pAdi == null || pAdi.isEmpty) continue;
          final pid = s['adisyon_paket_id']?.toString() ?? pAdi;
          final pSure = int.tryParse(s['paket_sure']?.toString() ?? '');
          if (pSure != null && pSure > 0) {
            paketToplamSure[pid] = pSure; // tek seferlik kesin deger
          }
          paketKalemToplam[pid] =
              (paketKalemToplam[pid] ?? 0) + _hizmetSuresiCozumle(s);
        }
        for (final pid in paketKalemToplam.keys) {
          paketToplamSure.putIfAbsent(pid, () => paketKalemToplam[pid]!);
        }
        final Set<String> paketIlkAtildi = {};

        for (final secim in secilenler) {
          final hizmetIdStr = secim['hizmet_id']?.toString() ?? '';
          if (hizmetIdStr.isEmpty) {
            log('paket secim atlandi: bos hizmet_id - $secim');
            continue;
          }

          // Once salon aktif hizmet listesinde ara — varsa tam metaveri ile kullan,
          // yoksa paket verisinden yapay IsletmeHizmet uret.
          IsletmeHizmet hizmetObj;
          final eslesen = isletmehizmetliste
              .where((h) => h.hizmet_id == hizmetIdStr)
              .toList();
          if (eslesen.isNotEmpty) {
            hizmetObj = eslesen.first;
          } else {
            log('paket hizmeti salon listesinde yok, fallback obje uretiliyor: '
                'hizmet_id=$hizmetIdStr adi=${secim['hizmet_adi']}');
            hizmetObj = IsletmeHizmet(
              hizmet_id: hizmetIdStr,
              hizmet: {'hizmet_adi': secim['hizmet_adi']?.toString() ?? ''},
              hizmet_kategorisi: null,
              sure: secim['sure']?.toString() ?? '0',
              fiyat: '0',
              bolum: '',
            );
            // KRITIK: yapay obje 'isletmehizmetliste'ye eklenmezse,
            // DropdownButton2 (value=hizmetObj, items=isletmehizmetliste.map...)
            // "There should be exactly one item with DropdownButton's value"
            // assertion error fırlatır -> gri ekran. Listeye ekleyerek hem
            // value hem items'da bulunmasini garanti et.
            isletmehizmetliste.add(hizmetObj);
          }

          final hamSureStr = _hizmetSuresiCozumle(secim).toString();
          final hizmetAdi = secim['hizmet_adi']?.toString() ?? '';
          final paketAdi = secim['paket_adi']?.toString();
          final adisyonPaketId = secim['adisyon_paket_id'];
          final adisyonHizmetId = secim['adisyon_hizmet_id'];

          // Paket icindeki ilk hizmet => paket toplam suresi; sonrakiler => 0
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

          // chain default (backend semantik):
          // - randevuekleguncelle: birlestir bos => yenisaatbaslangic = saat_bitis (chain)
          // - cakisan_randevu_kontrol: ayni semantik (bug fix sonrasi)
          // '1' deger ise PARALEL anlamina gelir, kayitta tum hizmetler ayni
          // saatten baslar ve takvimde ust uste binerek "kaybolur"lar.
          final yeniHizmet = RandevuHizmet(
            hizmetler: hizmetObj,
            hizmet_id: hizmetIdStr,
            personel_id: hedefPersonelId,
            personeller: hedefPersonel,
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
            groupId: hedefGroupId,
          );

          if (bosSatirIndex != null) {
            // Bos satira yaz — yeni satir acma (kullanicinin "2 hizmet secmisim
            // gibi" sikayetinin cozumu).
            final i = bosSatirIndex;
            hizmet[i].text = hizmetAdi;
            suredk[i].text = sureStr;
            fiyat[i].text = '0';
            secilihizmet[i] = hizmetObj;
            randevuhizmetleri[i] = yeniHizmet;
            bosSatirIndex = null; // bir sonraki secim icin yeni satir
          } else {
            // Yeni satir — personel devralma: ust grup ile ayni personel
            suredk.add(TextEditingController(text: sureStr));
            fiyat.add(TextEditingController(text: '0'));
            oda.add(TextEditingController());
            cihaz.add(TextEditingController());
            hizmet.add(TextEditingController(text: hizmetAdi));
            secilipersonel.add(hedefPersonel);
            seciliyardimcipersonel.add([null]);
            secilihizmet.add(hizmetObj);
            secilioda.add(null);
            secilicihaz.add(null);
            randevuhizmetleri.add(yeniHizmet);
          }
          eklenenSatir++;
        }
      });

      if (mounted && eklenenSatir > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$eklenenSatir paket hizmeti randevuya eklendi.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, st) {
      log('paket kontrolu hatasi: $e', stackTrace: st);
    }
  }


  // YENİ: Modern saat seçim fonksiyonu
  Future<void> saatsec(BuildContext context) async {
    // YENİ: Klavyeyi kapat
    _closeKeyboard();

    TimeOfDay initialTime = TimeOfDay.fromDateTime(secilisaat);
    bool valid = false;

    while (!valid) {
      final result = await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _buildModernTimePicker(initialTime),
      );

      if (result == null) return;

      if (result is TimeOfDay) {
        // NOT: Gecmis saat kontrolu kasitli kaldirildi — salon calisani
        // gecmis randevulari kaydedebilmeli (unutulmus/gecmis is randevusu).
        String dakika = result.minute.toString().padLeft(2, '0');
        setState(() {
          randevusaati.text = '${result.hour}:$dakika';
        });

        valid = true;
      }
    }
  }

  // YENİ: Modern saat seçim widget'ı - DAKİKALAR 00-15-30-45 OLARAK GÜNCELLENDİ
  Widget _buildModernTimePicker(TimeOfDay initialTime) {
    int selectedHour = initialTime.hour;
    int selectedMinute = _getNearestQuarterMinute(initialTime.minute);

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {},
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Başlık ve butonlar
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'İptal',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'Saat Seç',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final selectedTime = TimeOfDay(hour: selectedHour, minute: selectedMinute);
                          Navigator.of(context).pop(selectedTime);
                        },
                        child: Text(
                          'Tamam',
                          style: TextStyle(
                            color: Color(0xFF6A1B9A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Büyük saat gösterimi
                Container(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ),

                // Saat ve dakika seçiciler
                Expanded(
                  child: Row(
                    children: [
                      // Saat seçici
                      Expanded(
                        child: ListWheelScrollView(
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          physics: FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedHour = index;
                            });
                          },
                          children: List.generate(24, (hour) {
                            final isSelected = hour == selectedHour;
                            return Container(
                              alignment: Alignment.center,
                              child: Text(
                                hour.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 22 : 18,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? Color(0xFF6A1B9A) : Colors.grey[600],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Dakika seçici - SADECE 00-15-30-45
                      Expanded(
                        child: ListWheelScrollView(
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          physics: FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedMinute = _getMinuteFromIndex(index);
                            });
                          },
                          children: List.generate(4, (index) {
                            final minute = _getMinuteFromIndex(index);
                            final isSelected = minute == selectedMinute;
                            return Container(
                              alignment: Alignment.center,
                              child: Text(
                                minute.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 22 : 18,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? Color(0xFF6A1B9A) : Colors.grey[600],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // YENİ: Dakika indeksini gerçek dakika değerine dönüştürme
  int _getMinuteFromIndex(int index) {
    switch (index) {
      case 0: return 0;   // 00
      case 1: return 15;  // 15
      case 2: return 30;  // 30
      case 3: return 45;  // 45
      default: return 0;
    }
  }

  // YENİ: Mevcut dakikayı en yakın çeyrek saate yuvarlama
  int _getNearestQuarterMinute(int minute) {
    if (minute < 8) return 0;
    if (minute < 23) return 15;
    if (minute < 38) return 30;
    if (minute < 53) return 45;
    return 0; // 53-59 arası için 00 (saat artar)
  }

  Widget _buildInitErrorView(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 34, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 14),
            Text(
              'Randevu ekranı yüklenemedi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _initError ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.65),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Kapat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                    side: BorderSide(
                        color: scheme.onSurface.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => initialize(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getAppointmentEditor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color softBorder = scheme.outline.withValues(alpha: 0.25);

    if (isloading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_initError != null) {
      return _buildInitErrorView(context);
    }
    return GestureDetector(
      onTap: () {
        // YENİ: Tüm ekrana tıklanınca klavyeyi kapat
        _closeKeyboard();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          // Müşteri seçimi
          PremiumGlassCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Müşteri',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                LazyDropdown(
                  key: dropdownKey,
                  salonId: seciliisletme,
                  selectedItem: secilimusteridanisan,
                  onChanged: (value) {
                    setState(() {
                      secilimusteridanisan = value;
                      secilimusteridanisanid = value?.id;
                    });
                    _closeKeyboard();
                    // Web ile esit: musteri secilince aktif paket/hizmet
                    // sorgula, varsa popup ile paketten randevu secimine olanak ver.
                    if (value != null) {
                      _musteriPaketKontrolu(value);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tarih + Saat
          Row(
            children: [
              Expanded(
                child: _buildDateTimeTile(
                  context: context,
                  icon: Icons.calendar_today_rounded,
                  label: 'Tarih',
                  value: randevutarihi.text,
                  onTap: () {
                    _closeKeyboard();
                    tarihsec(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimeTile(
                  context: context,
                  icon: Icons.access_time_rounded,
                  label: 'Saat',
                  value: randevusaati.text,
                  onTap: () {
                    _closeKeyboard();
                    saatsec(context);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Detaylar header + Hizmet Ekle pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Detaylar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: scheme.onSurface,
                ),
              ),
              PremiumGradientPill(
                icon: Icons.add_rounded,
                label: 'Hizmet Ekle',
                onTap: () {
                  _closeKeyboard(); // YENİ: Butona tıklanınca klavyeyi kapat
                  setState(() {
                    // Yeni personel/hizmet grubu: ayri bir groupId ile yeni
                    // satir ekle (kendi bagimsiz kartinda gozukur).
                    final yeniGroupId =
                        'g-${DateTime.now().millisecondsSinceEpoch}';
                    suredk.add(TextEditingController());
                    fiyat.add(TextEditingController());
                    oda.add(TextEditingController());
                    cihaz.add(TextEditingController());
                    hizmet.add(TextEditingController());
                    secilipersonel.add(null);
                    seciliyardimcipersonel.add([null]);
                    secilihizmet.add(null);
                    secilioda.add(null);
                    secilicihaz.add(null);
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
                      // chain default (backend semantik): bos => bir sonraki
                      // hizmet bu hizmetin bitis saatinden baslar. '1' = paralel.
                      birusttekiileaynisaat: '',
                      groupId: yeniGroupId,
                    ));
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...() {
            // Grup-tabanli render: ayni groupId'ye sahip satirlar tek bir
            // "Hizmet Grubu" kartinda gosterilir (1 personel + N hizmet) —
            // web "Yeni Randevu" modali ile esit UX.
            const Color paketRenk = Color(0xFF6A1B9A);
            final List<String> groupOrder = [];
            final Map<String, List<int>> groups = {};
            for (int i = 0; i < randevuhizmetleri.length; i++) {
              final gid = randevuhizmetleri[i].groupId;
              if (!groups.containsKey(gid)) {
                groups[gid] = [];
                groupOrder.add(gid);
              }
              groups[gid]!.add(i);
            }
            final int toplamGrupSayisi = groupOrder.length;

            return groupOrder.map((gid) {
              final List<int> indices = groups[gid]!;
              final int firstIndex = indices.first;
              final bool grupPaket =
                  indices.any((i) => randevuhizmetleri[i].isPaket);
              String? grupPaketAdi;
              if (grupPaket) {
                for (final i in indices) {
                  final h = randevuhizmetleri[i];
                  if (h.isPaket &&
                      h.paket_adi != null &&
                      h.paket_adi!.isNotEmpty) {
                    grupPaketAdi = h.paket_adi;
                    break;
                  }
                }
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      grupPaket ? const Color(0xFFF6F0FA) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: grupPaket
                      ? Border.all(
                          color: paketRenk.withValues(alpha: 0.35),
                          width: 1.4,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: (grupPaket ? paketRenk : scheme.primary)
                          .withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (grupPaket) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: paketRenk,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_giftcard,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              grupPaketAdi != null && grupPaketAdi.isNotEmpty
                                  ? 'PAKET: $grupPaketAdi'
                                  : 'PAKET',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Personel her takvim turunde gorunur; cihaza/odaya gore
                    // modda Personel + Cihaz/Oda yan yana gosterilir.
                    Builder(builder: (context) {
                      final tur = widget.isletmebilgi["randevu_takvim_turu"];
                      final Widget personelKolon = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              right: toplamGrupSayisi > 1 ? 32 : 0,
                            ),
                            child: Text(
                              'Personel',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _closeKeyboard,
                            child: Container(
                              alignment: Alignment.center,
                              height: 44,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: softBorder),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2<Personel>(
                                  isExpanded: true,
                                  hint: Text(
                                    'Personel Seç',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                  value: secilipersonel[firstIndex],
                                  // v2: Oda secilince personel listesi oda
                                  // atanmis personellere filtrelenir.
                                  items: _filtreliPersoneller(
                                          oda: secilioda[firstIndex])
                                      .map((item) => DropdownMenuItem(
                                            value: item,
                                            child: Text(
                                              item.personel_adi,
                                              style: const TextStyle(
                                                  fontSize: 14),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    _closeKeyboard();
                                    setState(() {
                                      for (final i in indices) {
                                        secilipersonel[i] = value!;
                                        randevuhizmetleri[i].personel_id =
                                            value.id;
                                      }
                                    });
                                  },
                                  buttonStyleData: const ButtonStyleData(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 14),
                                    height: 50,
                                    width: 400,
                                  ),
                                  dropdownStyleData:
                                      const DropdownStyleData(
                                          maxHeight: 400),
                                  menuItemStyleData:
                                      const MenuItemStyleData(height: 40),
                                  dropdownSearchData: DropdownSearchData(
                                    searchController: personel,
                                    searchInnerWidgetHeight: 50,
                                    searchInnerWidget: Container(
                                      height: 50,
                                      padding: const EdgeInsets.only(
                                          top: 8,
                                          bottom: 4,
                                          right: 8,
                                          left: 8),
                                      child: TextFormField(
                                        expands: true,
                                        maxLines: null,
                                        controller: personel,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 8),
                                          hintText: 'Personel Ara..',
                                          hintStyle: const TextStyle(
                                              fontSize: 12),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8)),
                                        ),
                                      ),
                                    ),
                                    searchMatchFn: (item, searchValue) {
                                      return item.value!.personel_adi
                                          .toString()
                                          .toLowerCase()
                                          .contains(
                                              searchValue.toLowerCase());
                                    },
                                  ),
                                  onMenuStateChange: (isOpen) {
                                    if (!isOpen) {
                                      _closeKeyboard();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                      final Widget cihazKolon = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cihaz',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _closeKeyboard,
                            child: Container(
                              alignment: Alignment.center,
                              height: 44,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: softBorder),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2<Cihaz>(
                                  isExpanded: true,
                                  hint: Text(
                                      (cihazliste.length > 0
                                          ? 'Cihaz Seçin'
                                          : 'Sitemde cihaz bulunmamaktadır'),
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .hintColor)),
                                  items: cihazliste
                                      .map((item) => DropdownMenuItem(
                                            value: item,
                                            child: Text(item.cihaz_adi,
                                                style: TextStyle(
                                                    fontSize: 14)),
                                          ))
                                      .toList(),
                                  value: secilicihaz[firstIndex],
                                  onChanged: (value) {
                                    _closeKeyboard();
                                    setState(() {
                                      for (final i in indices) {
                                        secilicihaz[i] = value!;
                                        randevuhizmetleri[i].cihaz_id =
                                            value.id;
                                      }
                                    });
                                  },
                                  buttonStyleData: ButtonStyleData(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 14),
                                      height: 50,
                                      width: 400),
                                  dropdownStyleData:
                                      DropdownStyleData(maxHeight: 400),
                                  menuItemStyleData:
                                      MenuItemStyleData(height: 40),
                                  dropdownSearchData: DropdownSearchData(
                                    searchController: cihaz[firstIndex],
                                    searchInnerWidgetHeight: 50,
                                    searchInnerWidget: Container(
                                      height: 50,
                                      padding: EdgeInsets.all(8),
                                      child: TextFormField(
                                        expands: true,
                                        maxLines: null,
                                        controller: cihaz[firstIndex],
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 8),
                                          hintText: 'Cihaz Ara..',
                                          hintStyle:
                                              TextStyle(fontSize: 12),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8)),
                                        ),
                                      ),
                                    ),
                                    searchMatchFn: (item, searchValue) =>
                                        item.value!.cihaz_adi
                                            .toLowerCase()
                                            .contains(searchValue
                                                .toLowerCase()),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                      final Widget odaKolon = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Oda',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _closeKeyboard,
                            child: Container(
                              alignment: Alignment.center,
                              height: 44,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: softBorder),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2<Oda>(
                                  isExpanded: true,
                                  hint: Text(
                                      (odaliste.length > 0
                                          ? 'Oda Seçin'
                                          : 'Sistemde oda bulunmamaktadır'),
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .hintColor)),
                                  items: odaliste
                                      .map((item) => DropdownMenuItem(
                                            value: item,
                                            child: Text(item.oda_adi,
                                                style: TextStyle(
                                                    fontSize: 14)),
                                          ))
                                      .toList(),
                                  value: secilioda[firstIndex],
                                  onChanged: (value) {
                                    _closeKeyboard();
                                    setState(() {
                                      for (final i in indices) {
                                        secilioda[i] = value!;
                                        randevuhizmetleri[i].oda_id =
                                            value.id;
                                      }
                                    });
                                  },
                                  buttonStyleData: ButtonStyleData(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 14),
                                      height: 50,
                                      width: 400),
                                  dropdownStyleData:
                                      DropdownStyleData(maxHeight: 400),
                                  menuItemStyleData:
                                      MenuItemStyleData(height: 40),
                                  dropdownSearchData: DropdownSearchData(
                                    searchController: oda[firstIndex],
                                    searchInnerWidgetHeight: 50,
                                    searchInnerWidget: Container(
                                      height: 50,
                                      padding: EdgeInsets.all(8),
                                      child: TextFormField(
                                        expands: true,
                                        maxLines: null,
                                        controller: oda[firstIndex],
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 8),
                                          hintText: 'Oda Ara..',
                                          hintStyle:
                                              TextStyle(fontSize: 12),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8)),
                                        ),
                                      ),
                                    ),
                                    searchMatchFn: (item, searchValue) =>
                                        item.value!.oda_adi
                                            .toLowerCase()
                                            .contains(searchValue
                                                .toLowerCase()),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                      if (tur == 2) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: personelKolon),
                            const SizedBox(width: 10),
                            Expanded(child: cihazKolon),
                          ],
                        );
                      }
                      if (tur == 3) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: personelKolon),
                            const SizedBox(width: 10),
                            Expanded(child: odaKolon),
                          ],
                        );
                      }
                      return personelKolon;
                    }),
                    // Grup icindeki hizmet mini-kartlari
                    ...indices.map((i) {
                      final bool grupCokluHizmet = indices.length > 1;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: softBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: grupCokluHizmet ? 32 : 0,
                                  ),
                                  child: Text(
                                    'Hizmet',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: _closeKeyboard,
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 44,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border:
                                          Border.all(color: softBorder),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child:
                                          DropdownButton2<IsletmeHizmet>(
                                        isExpanded: true,
                                        hint: Text('Hizmet Seç',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                    .hintColor)),
                                        // v2: hizmet listesi grup'taki secili
                                        // personel/oda/cihaz'a gore strict
                                        // filtrelenir (atama yoksa hepsi).
                                        items: _filtreliHizmetler(
                                          personel: secilipersonel[firstIndex],
                                          oda: secilioda[firstIndex],
                                          cihaz: secilicihaz[firstIndex],
                                        )
                                            .map((item) => DropdownMenuItem(
                                                  value: item,
                                                  child: Text(
                                                      item.hizmet[
                                                          'hizmet_adi'],
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                ))
                                            .toList(),
                                        value: secilihizmet[i],
                                        onChanged: (value) {
                                          _closeKeyboard();
                                          setState(() {
                                            secilihizmet[i] = value!;
                                            randevuhizmetleri[i]
                                                    .hizmet_id =
                                                value.hizmet_id;
                                            suredk[i].text =
                                                value.sure != 'null'
                                                    ? value.sure
                                                    : '30';
                                            fiyat[i].text =
                                                value.fiyat != 'null'
                                                    ? value.fiyat
                                                    : '0';
                                            randevuhizmetleri[i]
                                                    .sure_dk =
                                                value.sure != 'null'
                                                    ? value.sure
                                                    : '30';
                                            randevuhizmetleri[i].fiyat =
                                                value.fiyat != 'null'
                                                    ? value.fiyat
                                                    : '0';
                                          });
                                        },
                                        buttonStyleData: ButtonStyleData(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 14),
                                            height: 50,
                                            width: 400),
                                        dropdownStyleData:
                                            DropdownStyleData(
                                                maxHeight: 400),
                                        menuItemStyleData:
                                            MenuItemStyleData(height: 60),
                                        dropdownSearchData:
                                            DropdownSearchData(
                                          searchController: hizmet[i],
                                          searchInnerWidgetHeight: 50,
                                          searchInnerWidget: Container(
                                            height: 50,
                                            padding: EdgeInsets.all(8),
                                            child: TextFormField(
                                              expands: true,
                                              maxLines: null,
                                              controller: hizmet[i],
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 8),
                                                hintText: 'Hizmet Ara..',
                                                hintStyle: TextStyle(
                                                    fontSize: 12),
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(8)),
                                              ),
                                            ),
                                          ),
                                          searchMatchFn: (item,
                                                  searchValue) =>
                                              item.value!
                                                  .hizmet["hizmet_adi"]
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains(searchValue
                                                      .toLowerCase()),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Süre (dk)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurface
                                                  .withValues(alpha: 0.55),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            alignment: Alignment.center,
                                            height: 44,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: softBorder),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      12),
                                            ),
                                            child: TextFormField(
                                              controller: suredk[i],
                                              keyboardType:
                                                  TextInputType.phone,
                                              onTap: () {},
                                              onChanged: (value) {
                                                suredk[i].text = value;
                                                randevuhizmetleri[i]
                                                    .sure_dk = value;
                                              },
                                              decoration:
                                                  const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fiyat (₺)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurface
                                                  .withValues(alpha: 0.55),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            alignment: Alignment.center,
                                            height: 44,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: softBorder),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      12),
                                            ),
                                            child: TextFormField(
                                              controller: fiyat[i],
                                              keyboardType:
                                                  TextInputType.phone,
                                              onTap: () {},
                                              onChanged: (value) {
                                                fiyat[i].text = value;
                                                randevuhizmetleri[i]
                                                    .fiyat = value;
                                              },
                                              decoration:
                                                  const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (i > 0) _buildBirlestirCheckbox(i),
                              ],
                            ),
                            if (grupCokluHizmet)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      _closeKeyboard();
                                      setState(() {
                                        randevuhizmetleri.removeAt(i);
                                        secilihizmet.removeAt(i);
                                        suredk.removeAt(i);
                                        fiyat.removeAt(i);
                                        oda.removeAt(i);
                                        cihaz.removeAt(i);
                                        hizmet.removeAt(i);
                                        secilipersonel.removeAt(i);
                                        seciliyardimcipersonel
                                            .removeAt(i);
                                        secilioda.removeAt(i);
                                        secilicihaz.removeAt(i);
                                      });
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444)
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: Color(0xFFDC2626)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    // "Bu Personele Hizmet Ekle" ve "Grubu Sil" ayni satirda:
                    // solda ekle, sagda sil (grup >1 iken).
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            _closeKeyboard();
                            setState(() {
                              // Yeni hizmet ayni grup'ta — personel/oda/cihaz
                              // grup uzerinden paylasilir.
                              final src = randevuhizmetleri[firstIndex];
                              suredk.add(TextEditingController());
                              fiyat.add(TextEditingController());
                              oda.add(TextEditingController());
                              cihaz.add(TextEditingController());
                              hizmet.add(TextEditingController());
                              secilipersonel.add(secilipersonel[firstIndex]);
                              seciliyardimcipersonel.add([null]);
                              secilihizmet.add(null);
                              secilioda.add(secilioda[firstIndex]);
                              secilicihaz.add(secilicihaz[firstIndex]);
                              randevuhizmetleri.add(RandevuHizmet(
                                hizmetler: null,
                                hizmet_id: '',
                                personel_id: src.personel_id,
                                personeller: null,
                                oda_id: src.oda_id,
                                oda: null,
                                cihaz_id: src.cihaz_id,
                                cihaz: null,
                                fiyat: '',
                                sure_dk: '',
                                saat: '',
                                saat_bitis: '',
                                yardimci_personel: '',
                                birusttekiileaynisaat: '',
                                groupId: gid,
                              ));
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'Bu Personele Hizmet Ekle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (toplamGrupSayisi > 1)
                          TextButton.icon(
                            onPressed: () {
                              _closeKeyboard();
                              setState(() {
                                // Sondan basa sil — index kaymalarini onler.
                                final sortedDesc = [...indices]
                                  ..sort((a, b) => b.compareTo(a));
                                for (final i in sortedDesc) {
                                  randevuhizmetleri.removeAt(i);
                                  secilihizmet.removeAt(i);
                                  suredk.removeAt(i);
                                  fiyat.removeAt(i);
                                  oda.removeAt(i);
                                  cihaz.removeAt(i);
                                  hizmet.removeAt(i);
                                  secilipersonel.removeAt(i);
                                  seciliyardimcipersonel.removeAt(i);
                                  secilioda.removeAt(i);
                                  secilicihaz.removeAt(i);
                                }
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18),
                            label: const Text(
                              'Grubu Sil',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList();
          }(),

          // V2 stili ozet kart: Toplam Sure + Toplam Tutar
          if (randevuhizmetleri.isNotEmpty) ...[
            const SizedBox(height: 4),
            _v2OzetKart(scheme),
          ],

          const SizedBox(height: 8),

          // Tekrarlayan
          PremiumGlassCard(
            padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.cached_rounded, color: scheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tekrarlayan Randevu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: tekrarlayanrandevu,
                      activeColor: scheme.primary,
                      onChanged: (bool value) {
                        _closeKeyboard(); // YENİ: Switch değişince klavyeyi kapat
                        setState(() {
                          tekrarlayanrandevu = value;
                        });
                      },
                    ),
                  ],
                ),
                if (tekrarlayanrandevu) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 6, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tekrar Sıklığı',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _closeKeyboard, // YENİ: Dropdown'a tıklanınca klavyeyi kapat
                                child: Container(
                                  alignment: Alignment.center,
                                  height: 44,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: softBorder),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: AramaliDropdown<RandevuTekrarSikligi>(
                                      isExpanded: true,
                                      hint: Text(
                                        'Sıklık Seç',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                      value: secilitekrarsikligi,
                                      items: tekrarsikliklari
                                          .map((item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(
                                                  item.tekrar_sikligi,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        _closeKeyboard(); // YENİ: Değişiklikte klavyeyi kapat
                                        setState(() {
                                          secilitekrarsikligi = value;
                                        });
                                      },
                                      buttonStyleData: const ButtonStyleData(
                                        padding: EdgeInsets.symmetric(horizontal: 14),
                                        height: 50,
                                        width: 400,
                                      ),
                                      dropdownStyleData: const DropdownStyleData(maxHeight: 400),
                                      menuItemStyleData: const MenuItemStyleData(height: 40),
                                      onMenuStateChange: (isOpen) {
                                        if (!isOpen) {
                                          _closeKeyboard(); // YENİ: Dropdown kapanınca klavyeyi kapat
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tekrar Sayısı',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                alignment: Alignment.center,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: softBorder),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextFormField(
                                  onTap: () {
                                    // YENİ: TextField'a tıklanınca klavyeyi aç
                                  },
                                  onChanged: (value) {
                                    tekrarsayisi.text = value!;
                                  },
                                  keyboardType: TextInputType.phone,
                                  controller: tekrarsayisi,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Notlar
          PremiumGlassCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.subject_rounded, color: scheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Notlar',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: notlar,
                  focusNode: _notlarFocusNode, // YENİ: FocusNode kullan
                  onTap: () {
                    // YENİ: Notlar alanına tıklanınca klavyeyi aç (diğerlerini kapatmaya gerek yok)
                  },
                  onChanged: (value) {
                    notlar.text = value!;
                  },
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 15,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    hintText: 'Randevu notunuzu yazın...',
                    hintStyle: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // RANDEVUYU OLUŞTUR
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _closeKeyboard(); // YENİ: Butona tıklanınca klavyeyi kapat
                  setState(() {
                    formisvalid = true;
                    String uyari = 'Randevuyu oluşturmadan önce gerekli alanları eksiksiz doldurunuz.\n';

                    if (!isNumeric(secilimusteridanisanid.toString())) {
                      uyari += '\nLütfen müşteri seçiniz.';
                      formisvalid = false;
                    }
                    if (randevutarihi.text == '') {
                      uyari += '\nLütfen randevu tarihini seçiniz.';
                      formisvalid = false;
                    }
                    if (randevusaati.text == '') {
                      uyari += '\nLütfen randevu saatini seçiniz.';
                      formisvalid = false;
                    }
                    if (tekrarlayanrandevu) {
                      if (secilitekrarsikligi == null) {
                        uyari += '\nLütfen randevu tekrar sıklığını seçiniz.';
                        formisvalid = false;
                      }
                      if (tekrarsayisi.text == '') {
                        uyari += '\nLütfen randevu tekrar sayısını giriniz.';
                        formisvalid = false;
                      }
                    }
                    bool himzetSeciliDegil = secilihizmet.any((element) => element == null);
                    bool cihazSeciliDegil = secilicihaz.any((element) => element == null);
                    bool odaSeciliDegil = secilioda.any((element) => element == null);

                    if (widget.isletmebilgi["randevu_takvim_turu"] == 2) {
                      if (cihazSeciliDegil) {
                        formisvalid = false;
                        uyari += '\nLütfen cihaz seçiniz.';
                      }
                    }

                    if (widget.isletmebilgi["randevu_takvim_turu"] == 3) {
                      if (odaSeciliDegil) {
                        formisvalid = false;
                        uyari += '\nLütfen oda seçiniz.';
                      }
                    }

                    if (himzetSeciliDegil) {
                      formisvalid = false;
                      uyari += '\nLütfen hizmet seçiniz.';
                    }

                    if (formisvalid == false) {
                      formWarningDialogs(context, 'UYARI', uyari);
                    } else {
                      debugPrint('seçili müşteri ' + secilimusteridanisanid!);
                      debugPrint('tarih ' + randevutarihi.text!);
                      debugPrint('saat ' + randevusaati.text!);
                      randevuhizmetleri.forEach((element) {
                        debugPrint('hizmet id : ' + element.hizmet_id);
                        debugPrint('personel id : ' + element.personel_id);
                        debugPrint('cihaz id : ' + element.cihaz_id);
                        debugPrint('oda id : ' + element.oda_id);
                      });
                      randevuhizmetyardimcipersoneller.forEach((element) {
                        debugPrint('Yardımcı personel for index : ' + element.index);
                        debugPrint('Yardımcı personel id : ' + element.yardimcipersonel['id']);
                        debugPrint('Yardımcı personel hizmet : ' + element.randevuhizmetid);
                      });

                      randevuEkleGuncelle(
                          '',
                          '',
                          '',
                          secilimusteridanisan!,
                          randevutarihi.text,
                          randevusaati.text,
                          randevuhizmetleri,
                          randevuhizmetyardimcipersoneller,
                          tekrarlayanrandevu,
                          tekrarsayisi.text,
                          secilitekrarsikligi?.siklik_str,
                          notlar.text,
                          seciliisletme.toString(),
                          context,
                          'salon',
                          '1',
                          widget.isletmebilgi);
                    }
                  });
                },
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.32),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    'RANDEVUYU OLUŞTUR',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// v2 randevu-ekle-modal-v2.blade.php'deki ozet panelinin karsiligi.
  /// Tum hizmet satirlarinin toplam sure + toplam fiyatini gosterir.
  Widget _v2OzetKart(ColorScheme scheme) {
    int toplamSure = 0;
    double toplamFiyat = 0;
    for (int i = 0; i < randevuhizmetleri.length; i++) {
      final dk = (i < suredk.length)
          ? int.tryParse(suredk[i].text)
          : int.tryParse(randevuhizmetleri[i].sure_dk);
      if (dk != null && dk > 0) toplamSure += dk;
      final fiy = (i < fiyat.length)
          ? double.tryParse(fiyat[i].text.replaceAll(',', '.'))
          : double.tryParse(
              randevuhizmetleri[i].fiyat.replaceAll(',', '.'));
      if (fiy != null && fiy > 0) toplamFiyat += fiy;
    }
    String fiyatStr;
    if (toplamFiyat == toplamFiyat.roundToDouble()) {
      fiyatStr = toplamFiyat.toStringAsFixed(0);
    } else {
      fiyatStr = toplamFiyat.toStringAsFixed(2);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.92),
            scheme.tertiary.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.hourglass_bottom_rounded,
                    color: scheme.onPrimary.withValues(alpha: 0.9), size: 18),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Süre',
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$toplamSure dk',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: scheme.onPrimary.withValues(alpha: 0.25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.payments_rounded,
                    color: scheme.onPrimary.withValues(alpha: 0.9), size: 18),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Tutar',
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$fiyatStr ₺',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value.isNotEmpty;
    return PremiumGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasValue ? value : 'Seçin',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: hasValue
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: 0.35),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurface.withValues(alpha: 0.30),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Yeni Randevu',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            child: PremiumCircleAction(
              icon: Icons.close_rounded,
              iconColor: scheme.onSurface,
              onTap: () {
                _closeKeyboard();
                Navigator.of(context).pop();
              },
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: PremiumCircleAction(
                icon: Icons.person_add_alt_1_rounded,
                onTap: () async {
                  final MusteriDanisan yenimusteridanisan = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Yenimusteri(
                              kullanicirolu: widget.kullanicirolu,
                              isletmebilgi: widget.isletmebilgi,
                              isim: "",
                              telefon: "",
                              sadeceekranikapat: true,
                            )),
                  );
                  if (yenimusteridanisan != null)
                    setState(() {
                      musteridanisanlar.add(yenimusteridanisan);
                      secilimusteridanisan = yenimusteridanisan;
                      dropdownKey.currentState?.addItemAndSelect(yenimusteridanisan);
                    });
                },
              ),
            ),
          ],
          toolbarHeight: 64,
        ),
        body: _getAppointmentEditor(context),
      ),
    );
  }

  bool isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return int.tryParse(str) != null || double.tryParse(str) != null;
  }

  String getTitle() {
    return 'Yeni Randevu';
  }

  String getYardimciPersonel(String hizmetid) {
    String yardimcipersoneller = '';
    int index = 0;
    randevuhizmetyardimcipersoneller.forEach((element) {
      ++index;
      if (element.randevuhizmetid == hizmetid)
        yardimcipersoneller += element.yardimcipersonel['personel_adi'];
      if (index != randevuhizmetyardimcipersoneller.length) yardimcipersoneller += ', ';
    });
    return yardimcipersoneller;
  }
}

