import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

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
  final GlobalKey<LazyDropdownState> dropdownKey = GlobalKey<LazyDropdownState>();

  TextEditingController personel = TextEditingController();

  List<Personel?> secilipersonel = [];
  List<Oda?> secilioda = [];
  List<Cihaz?> secilicihaz = [];
  List<IsletmeHizmet?> secilihizmet = [];
  List<List<Personel?>> seciliyardimcipersonel = [];
  MusteriDanisan? secilimusteridanisan;

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
        birusttekiileaynisaat: ''
    )
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
    seciliisletme = (await secilisalonid())!;
    final isletmeVerileri = await isletmeVerileriGetir(seciliisletme, false, '', '', '', 0, 0);
    List<MusteriDanisan> musteridanisanliste = isletmeVerileri['musteriler'];
    List<IsletmeHizmet> isletmehizmetleriliste = isletmeVerileri['hizmetler'];
    List<Personel> isletmepersonellerliste = isletmeVerileri['personeller'];
    List<Cihaz> isletmecihazliste = isletmeVerileri['cihazlar'];
    List<Oda> isletmeodaliste = isletmeVerileri['odalar'];

    setState(() {
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
        randevutarihi.text = DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.tarihsaat));
        randevusaati.text = DateFormat('HH:mm').format(DateTime.parse(widget.tarihsaat));
      }

      _autoSelectResource();

      isloading = false;
    });
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
        DateTime now = DateTime.now();

        if (randevutarihi.text == DateFormat('yyyy-MM-dd').format(now)) {
          if (result.hour < now.hour ||
              (result.hour == now.hour && result.minute < now.minute)) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Hata'),
                content: Text('Geçmiş saati seçemezsiniz!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Tamam'),
                  ),
                ],
              ),
            );
            continue;
          }
        }

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

  Widget _getAppointmentEditor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color softBorder = scheme.outline.withValues(alpha: 0.25);

    return isloading
        ? Center(child: CircularProgressIndicator())
        : GestureDetector(
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
                    secilimusteridanisan = value;
                    secilimusteridanisanid = value?.id;
                    _closeKeyboard();
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
                      birusttekiileaynisaat: '',
                    ));
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...List.generate(randevuhizmetleri.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      if (widget.isletmebilgi["randevu_takvim_turu"] == 0 ||
                          widget.isletmebilgi["randevu_takvim_turu"] == 1)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                right: randevuhizmetleri.length > 1 ? 32 : 0,
                              ),
                              child: Text(
                                'Personel',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface.withValues(alpha: 0.55),
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
                                    value: secilipersonel[index],
                                    items: personelliste
                                        .map((item) => DropdownMenuItem(
                                              value: item,
                                              child: Text(
                                                item.personel_adi,
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      _closeKeyboard();
                                      setState(() {
                                        secilipersonel[index] = value!;
                                        randevuhizmetleri[index].personel_id = value.id;
                                      });
                                    },
                                    buttonStyleData: const ButtonStyleData(
                                      padding: EdgeInsets.symmetric(horizontal: 14),
                                      height: 50,
                                      width: 400,
                                    ),
                                    dropdownStyleData: const DropdownStyleData(maxHeight: 400),
                                    menuItemStyleData: const MenuItemStyleData(height: 40),
                                    dropdownSearchData: DropdownSearchData(
                                      searchController: personel,
                                      searchInnerWidgetHeight: 50,
                                      searchInnerWidget: Container(
                                        height: 50,
                                        padding: const EdgeInsets.only(top: 8, bottom: 4, right: 8, left: 8),
                                        child: TextFormField(
                                          expands: true,
                                          maxLines: null,
                                          controller: personel,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            hintText: 'Personel Ara..',
                                            hintStyle: const TextStyle(fontSize: 12),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      searchMatchFn: (item, searchValue) {
                                        return item.value!.personel_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
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
                          ],
                        ),
                      if (widget.isletmebilgi["randevu_takvim_turu"] == 0 ||
                          widget.isletmebilgi["randevu_takvim_turu"] == 1)
                        const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.isletmebilgi["randevu_takvim_turu"] == 2)
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cihaz',
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
                                        child: DropdownButton2<Cihaz>(
                                          isExpanded: true,
                                          hint: Text((cihazliste.length > 0 ? 'Cihaz Seçin' : 'Sitemde cihaz bulunmamaktadır'), style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
                                          items: cihazliste
                                              .map((item) => DropdownMenuItem(
                                                    value: item,
                                                    child: Text(item.cihaz_adi, style: TextStyle(fontSize: 14)),
                                                  ))
                                              .toList(),
                                          value: secilicihaz[index],
                                          onChanged: (value) {
                                            _closeKeyboard(); // YENİ: Değişiklikte klavyeyi kapat
                                            setState(() {
                                              secilicihaz[index] = value!;
                                              randevuhizmetleri[index].cihaz_id = value.id;
                                            });
                                          },
                                          buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 14), height: 50, width: 400),
                                          dropdownStyleData: DropdownStyleData(maxHeight: 400),
                                          menuItemStyleData: MenuItemStyleData(height: 40),
                                          dropdownSearchData: DropdownSearchData(
                                            searchController: cihaz[index],
                                            searchInnerWidgetHeight: 50,
                                            searchInnerWidget: Container(
                                              height: 50,
                                              padding: EdgeInsets.all(8),
                                              child: TextFormField(
                                                expands: true,
                                                maxLines: null,
                                                controller: cihaz[index],
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  hintText: 'Cihaz Ara..',
                                                  hintStyle: TextStyle(fontSize: 12),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ),
                                            searchMatchFn: (item, searchValue) => item.value!.cihaz_adi.toLowerCase().contains(searchValue.toLowerCase()),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (widget.isletmebilgi["randevu_takvim_turu"] == 3)
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Oda',
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
                                        child: DropdownButton2<Oda>(
                                          isExpanded: true,
                                          hint: Text((odaliste.length > 0 ? 'Oda Seçin' : 'Sistemde oda bulunmamaktadır'), style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
                                          items: odaliste
                                              .map((item) => DropdownMenuItem(
                                                    value: item,
                                                    child: Text(item.oda_adi, style: TextStyle(fontSize: 14)),
                                                  ))
                                              .toList(),
                                          value: secilioda[index],
                                          onChanged: (value) {
                                            _closeKeyboard(); // YENİ: Değişiklikte klavyeyi kapat
                                            setState(() {
                                              secilioda[index] = value!;
                                              randevuhizmetleri[index].oda_id = value.id;
                                            });
                                          },
                                          buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 14), height: 50, width: 400),
                                          dropdownStyleData: DropdownStyleData(maxHeight: 400),
                                          menuItemStyleData: MenuItemStyleData(height: 40),
                                          dropdownSearchData: DropdownSearchData(
                                            searchController: oda[index],
                                            searchInnerWidgetHeight: 50,
                                            searchInnerWidget: Container(
                                              height: 50,
                                              padding: EdgeInsets.all(8),
                                              child: TextFormField(
                                                expands: true,
                                                maxLines: null,
                                                controller: oda[index],
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  hintText: 'Oda Ara..',
                                                  hintStyle: TextStyle(fontSize: 12),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ),
                                            searchMatchFn: (item, searchValue) => item.value!.oda_adi.toLowerCase().contains(searchValue.toLowerCase()),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (widget.isletmebilgi["randevu_takvim_turu"] == 2 ||
                              widget.isletmebilgi["randevu_takvim_turu"] == 3)
                            const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hizmet',
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
                                      child: DropdownButton2<IsletmeHizmet>(
                                        isExpanded: true,
                                        hint: Text('Hizmet Seç', style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
                                        items: isletmehizmetliste
                                            .map((item) => DropdownMenuItem(
                                                  value: item,
                                                  child: Text(item.hizmet['hizmet_adi'], style: TextStyle(fontSize: 14)),
                                                ))
                                            .toList(),
                                        value: secilihizmet[index],
                                        onChanged: (value) {
                                          _closeKeyboard(); // YENİ: Değişiklikte klavyeyi kapat
                                          setState(() {
                                            secilihizmet[index] = value!;
                                            randevuhizmetleri[index].hizmet_id = value.hizmet_id;
                                            suredk[index].text = value.sure != 'null' ? value.sure : '30';
                                            fiyat[index].text = value.fiyat != 'null' ? value.fiyat : '0';
                                            randevuhizmetleri[index].sure_dk = value.sure != 'null' ? value.sure : '30';
                                            randevuhizmetleri[index].fiyat = value.fiyat != 'null' ? value.fiyat : '0';
                                          });
                                        },
                                        buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 14), height: 50, width: 400),
                                        dropdownStyleData: DropdownStyleData(maxHeight: 400),
                                        menuItemStyleData: MenuItemStyleData(height: 60),
                                        dropdownSearchData: DropdownSearchData(
                                          searchController: hizmet[index],
                                          searchInnerWidgetHeight: 50,
                                          searchInnerWidget: Container(
                                            height: 50,
                                            padding: EdgeInsets.all(8),
                                            child: TextFormField(
                                              expands: true,
                                              maxLines: null,
                                              controller: hizmet[index],
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                hintText: 'Hizmet Ara..',
                                                hintStyle: TextStyle(fontSize: 12),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                          searchMatchFn: (item, searchValue) => item.value!.hizmet["hizmet_adi"].toString().toLowerCase().contains(searchValue.toLowerCase()),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Süre (dk)',
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
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: softBorder),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextFormField(
                                        controller: suredk[index],
                                        keyboardType: TextInputType.phone,
                                        onTap: () {},
                                        onChanged: (value) {
                                          suredk[index].text = value!;
                                          randevuhizmetleri[index].sure_dk = value;
                                        },
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fiyat (₺)',
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
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: softBorder),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextFormField(
                                        controller: fiyat[index],
                                        keyboardType: TextInputType.phone,
                                        onTap: () {},
                                        onChanged: (value) {
                                          fiyat[index].text = value!;
                                          randevuhizmetleri[index].fiyat = value;
                                        },
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
                        ],
                      ),
                    ],
                  ),
                  if (randevuhizmetleri.length > 1)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            _closeKeyboard(); // YENİ: Butona tıklanınca klavyeyi kapat
                            setState(() => randevuhizmetleri.removeAt(index));
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

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
                                    child: DropdownButton2<RandevuTekrarSikligi>(
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
                    bool personelSeciliDegil = secilipersonel.any((element) => element == null);
                    bool cihazSeciliDegil = secilicihaz.any((element) => element == null);
                    bool odaSeciliDegil = secilioda.any((element) => element == null);

                    if (widget.isletmebilgi["randevu_takvim_turu"] == 1) {
                      if (personelSeciliDegil) {
                        formisvalid = false;
                        uyari += '\nLütfen personel seçiniz.';
                      }
                    }

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