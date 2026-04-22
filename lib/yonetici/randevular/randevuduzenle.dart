import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import '../../Backend/backend.dart';
import '../../Frontend/datetimeformatting.dart';
import '../../Frontend/popupdialogs.dart';

import '../../Models/cihazlar.dart';
import '../../Models/hizmetler.dart';
import '../../Models/isletmehizmetleri.dart';
import '../../Models/musteri_danisanlar.dart';
import '../../Models/odalar.dart';
import '../../Models/personel.dart';
import '../../Models/randevuhizmetleri.dart';
import '../../Models/randevuhizmetyardimcipersonelleri.dart';

import '../../Models/randevular.dart';
import '../../Models/randevutekrarsikligi.dart';
import '../../yeni/app_colors.dart';
import 'hizmet_add.dart';
import 'package:randevu_sistem/yonetici/randevular/musteri.dart';

class RandevuDuzenle extends StatefulWidget {
  final Randevu randevu;
  final dynamic isletmebilgi;

  const RandevuDuzenle({Key? key,required this.randevu,required this.isletmebilgi}) : super(key: key);

  @override
  AppointmentEditorState createState() => AppointmentEditorState();
}

class AppointmentEditorState extends State<RandevuDuzenle> {
  late List<IsletmeHizmet> isletmehizmetliste;
  late List<Personel> personelliste;
  late List<Cihaz> cihazliste;
  late List<Oda> odaliste;
  late List<MusteriDanisan> musteridanisanlar;
  bool isloading = true;

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

  TextEditingController musteridanisan = TextEditingController();
  final TextEditingController textEditingController = TextEditingController();

  bool formisvalid = true;
  late String seciliisletme;
  List<RandevuHizmet> randevuhizmetleri = [RandevuHizmet(hizmetler: null, hizmet_id: '', personel_id: '', personeller: null, oda_id: '', oda: null, cihaz_id: '', cihaz: null, fiyat: '', sure_dk: '', saat: '', saat_bitis: '', yardimci_personel: '', birusttekiileaynisaat: '')];

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
    final isletmeVerileri = await isletmeVerileriGetir(seciliisletme,false,'','','',0,0);
    List <MusteriDanisan> musteridanisanliste = isletmeVerileri['musteriler'];
    List<IsletmeHizmet> isletmehizmetleriliste =  isletmeVerileri['hizmetler'];
    List<Personel> isletmepersonellerliste =  isletmeVerileri['personeller'];
    List<Cihaz>isletmecihazliste =  isletmeVerileri['cihazlar'];
    List<Oda>isletmeodaliste =  isletmeVerileri['odalar'];

    setState(() {
      final List<dynamic> hizmetdata = widget.randevu.hizmetler;
      randevuhizmetleri = hizmetdata.map((e) => RandevuHizmet.fromJson(e)).toList();

      secilimusteridanisan = MusteriDanisan.fromJson(widget.randevu.musteri);
      secilimusteridanisanid = widget.randevu.user_id;
      secilimusteridanisanadi = widget.randevu.musteri["name"];

      randevutarihi.text = widget.randevu.tarih.split(' ')[0];
      randevusaati.text = widget.randevu.tarih.split(' ')[1];



      musteridanisanlar = musteridanisanliste;
      isletmehizmetliste = isletmehizmetleriliste;
      personelliste = isletmepersonellerliste;
      odaliste= isletmeodaliste;
      cihazliste = isletmecihazliste;

      randevutarihi.text = DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.randevu.tarih));
      randevusaati.text = DateFormat('HH:mm').format(DateTime.parse(widget.randevu.tarih));

      isloading = false;
    });

    randevuhizmetleri.asMap().entries.forEach((element){
      secilipersonel.add(null);
      seciliyardimcipersonel.add([null]);
      secilihizmet.add(null);
      secilioda.add(null);
      secilicihaz.add(null);
      suredk.add(TextEditingController());
      fiyat.add(TextEditingController());
      oda.add(TextEditingController());
      cihaz.add(TextEditingController());
      hizmet.add(TextEditingController());
      secilihizmet[element.key] = isletmehizmetliste.firstWhere((element2) => element2.hizmet_id == element.value.hizmet_id);
      secilipersonel[element.key] = Personel.fromJson(element.value.personeller);
      if(element.value.oda != null)
        secilioda[element.key]=Oda.fromJson(element.value.oda);
      if(element.value.cihaz != null)
        secilicihaz[element.key]=Cihaz.fromJson(element.value.cihaz);
      print('süre '+element.value.sure_dk);
      suredk[element.key].text = element.value.sure_dk != 'null' ? element.value.sure_dk : '30';
      fiyat[element.key].text = element.value.fiyat != 'null' ? element.value.fiyat : '0';
    });
  }

  // YENİ: Klavyeyi kapatma fonksiyonu
  void _closeKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> tarihsec(BuildContext context) async {
    // YENİ: Klavyeyi kapat
    _closeKeyboard();

    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        lastDate: DateTime(2100));

    if (pickedDate != null) {
      print(pickedDate);
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      print(formattedDate);
      setState(() {
        randevutarihi.text = formattedDate;
      });
    } else {}
  }

  // YENİ: Modern saat seçim fonksiyonu - DAKİKALAR 00-15-30-45 OLARAK GÜNCELLENDİ
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

        /*if (randevutarihi.text == DateFormat('yyyy-MM-dd').format(now)) {
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
        }*/

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
    final double columnWidth = MediaQuery.of(context).size.width / 2 - 20;
    final screenHeight = MediaQuery.of(context).size.height;

    return isloading ? Center(child: CircularProgressIndicator()) : GestureDetector(
        onTap: () {
          // YENİ: Tüm ekrana tıklanınca klavyeyi kapat
          _closeKeyboard();
        },
        child: Container(
            height: screenHeight,
            color: Colors.white,
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  height: 40,
                  width: 150,
                  child: GestureDetector(
                    onTap: _closeKeyboard, // YENİ: Dropdown'a tıklanınca klavyeyi kapat
                    child: DropdownSearch<MusteriDanisan>(
                      items: (String filter, LoadProps? loadProps) async {
                        final all = await musterilistegetir(seciliisletme);
                        final filtered = (filter.isEmpty)
                            ? all
                            : all.where((e) => e.name.toLowerCase().contains(filter.toLowerCase())).toList();
                        return filtered;
                      },
                      selectedItem: secilimusteridanisan,
                      compareFn: (a, b) => a.id == b.id,
                      dropdownBuilder: (context, selected) =>
                          Text(selected?.name ?? 'Müşteri Seç'),
                      onChanged: (value) {
                        _closeKeyboard(); // YENİ: Değişiklikte klavyeyi kapat
                        secilimusteridanisan = value;
                        secilimusteridanisanid = value?.id;
                      },
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        itemBuilder: (context, item, isDisabled, isSelected) {
                          return ListTile(title: Text(item.name));
                        },
                        constraints: BoxConstraints(maxHeight: 250),
                      ),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                ),

                Row(
                    children:[
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _closeKeyboard();
                            tarihsec(context);
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                            leading: const Icon(Icons.calendar_today),
                            title: Text('Tarih'),
                            trailing: randevutarihi.text != ''
                                ? Text(randevutarihi.text)
                                : Icon(Icons.keyboard_arrow_right),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        height: 40,
                        width: 2,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _closeKeyboard();
                            saatsec(context);
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                            leading: const Icon(Icons.watch_later_outlined),
                            title: Text('Saat'),
                            trailing: randevusaati.text != ''
                                ? Text(randevusaati.text)
                                : Icon(Icons.keyboard_arrow_right),
                          ),
                        ),
                      )
                    ]
                ),

                const Divider(height: 1.0, thickness: 1),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Detaylar',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
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
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Hizmet Ekle", style: TextStyle(fontSize: 12, color: Colors.green)),
                            SizedBox(width: 4),
                            Icon(Icons.add, size: 30, color: Colors.green),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                SizedBox(height: 5),

                ...List.generate(randevuhizmetleri.length, (index) {
                  final set = randevuhizmetleri[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 3),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        children: [
                          widget.isletmebilgi["randevu_takvim_turu"] >= 0 ?
                          Row(
                            children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children:[
                                        Text('Personel', style: TextStyle(fontSize: 11)),
                                        SizedBox(height:5),
                                        GestureDetector(
                                          onTap: _closeKeyboard, // YENİ: Dropdown'a tıklanınca klavyeyi kapat
                                          child: Container(
                                            alignment: Alignment.center,
                                            height: 40,
                                            width:double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(color: Color(0xFF6A1B9A)),
                                              borderRadius: BorderRadius.circular(10),
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
                                                  _closeKeyboard(); // YENİ: Değişiklikte klavyeyi kapat
                                                  setState(() {
                                                    secilipersonel[index] = value!;
                                                    randevuhizmetleri[index].personel_id = value.id;
                                                  });
                                                },
                                                buttonStyleData: const ButtonStyleData(
                                                  padding: EdgeInsets.symmetric(horizontal: 16),
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
                                                    _closeKeyboard(); // YENİ: Dropdown kapanınca klavyeyi kapat
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]
                                  )
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Yardımcı Personel(-ler)', style: TextStyle(fontSize: 11)),
                                    SizedBox(height: 5),
                                    GestureDetector(
                                      onTap: _closeKeyboard, // YENİ: Dropdown'a tıklanınca klavyeyi kapat
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 40,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Color(0xFF6A1B9A)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton2<Personel>(
                                            isExpanded: true,
                                            customButton: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      seciliyardimcipersonel[index]
                                                          .whereType<Personel>()
                                                          .map((e) => e.personel_adi)
                                                          .join(', ')
                                                          .trim()
                                                          .isNotEmpty
                                                          ? seciliyardimcipersonel[index]
                                                          .whereType<Personel>()
                                                          .map((e) => e.personel_adi)
                                                          .join(', ')
                                                          : 'Yardımcı Personel(-ler)i Seç',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: seciliyardimcipersonel[index].whereType<Personel>().isEmpty
                                                            ? Theme.of(context).hintColor
                                                            : Colors.black,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            value: null,
                                            onChanged: (_) {},
                                            items: personelliste.map((item) {
                                              return DropdownMenuItem<Personel>(
                                                value: item,
                                                child: StatefulBuilder(
                                                  builder: (context, menuSetState) {
                                                    final isSelected = seciliyardimcipersonel[index].contains(item);
                                                    return InkWell(
                                                      onTap: () {
                                                        _closeKeyboard(); // YENİ: Seçim yapılınca klavyeyi kapat
                                                        setState(() {
                                                          if (isSelected) {
                                                            seciliyardimcipersonel[index].remove(item);
                                                            randevuhizmetyardimcipersoneller.removeWhere((element){return element.index == index  && element.yardimcipersonel['id'].toString() == item.id.toString();});
                                                          } else {
                                                            seciliyardimcipersonel[index].add(item);
                                                            randevuhizmetyardimcipersoneller.add(new RandevuHizmetYardimciPersonelleri('',item.toJson(),index.toString()));
                                                          }
                                                        });
                                                        menuSetState(() {});
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                                              color: isSelected ? Colors.blue : null,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Flexible(
                                                              child: Text(
                                                                item.personel_adi,
                                                                style: const TextStyle(fontSize: 14),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                            buttonStyleData: const ButtonStyleData(
                                              height: 40,
                                              padding: EdgeInsets.symmetric(horizontal: 0),
                                            ),
                                            dropdownStyleData: const DropdownStyleData(
                                              maxHeight: 400,
                                              width: null,
                                            ),
                                            menuItemStyleData: const MenuItemStyleData(height: 40),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ) : SizedBox(),
                          SizedBox(height: 5),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [

                                SizedBox(
                                  width: columnWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Cihaz (Opsiyonel)', style: TextStyle(fontSize: 11)),
                                      SizedBox(height: 5),
                                      GestureDetector(
                                        onTap: _closeKeyboard, // YENİ: Dropdown'a tıklanınca klavyeyi kapat
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: 40,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Color(0xFF6A1B9A)),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton2<Cihaz>(
                                              isExpanded: true,
                                              hint: Text((cihazliste.length>0 ? 'Cihaz Seçin' : 'Sistemde cihaz bulunmamaktadır'), style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
                                              items: cihazliste.map((item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item.cihaz_adi, style: TextStyle(fontSize: 14)),
                                              )).toList(),
                                              value: secilicihaz[index],
                                              onChanged: (value) {
                                                _closeKeyboard(); // YENİ: Değişiklikte klavyeyi kapat
                                                setState(() {
                                                  secilicihaz[index] = value!;
                                                  randevuhizmetleri[index].cihaz_id = value.id;
                                                });
                                              },
                                              buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 16), height: 50, width: 400),
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


                                SizedBox(
                                  width: columnWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Oda (Opsiyonel)', style: TextStyle(fontSize: 11)),
                                      SizedBox(height: 5),
                                      GestureDetector(
                                        onTap: _closeKeyboard, // YENİ: Dropdown'a tıklanınca klavyeyi kapat
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: 40,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Color(0xFF6A1B9A)),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton2<Oda>(
                                              isExpanded: true,
                                              hint: Text((odaliste.length > 0 ?'Oda Seçin' : 'Sistemde oda bulunmamaktadır'), style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
                                              items: odaliste.map((item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item.oda_adi, style: TextStyle(fontSize: 14)),
                                              )).toList(),
                                              value: secilioda?[index],
                                              onChanged: (value) {
                                                _closeKeyboard(); // YENİ: Değişiklikte klavyeyi kapat
                                                setState(() {
                                                  secilioda[index] = value!;
                                                  randevuhizmetleri[index].oda_id = value.id;
                                                });
                                              },
                                              buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 10), height: 50, width: 400),
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

                              // Hizmet
                              SizedBox(
                                width: columnWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Hizmet', style: TextStyle(fontSize: 11)),
                                    SizedBox(height: 5),
                                    GestureDetector(
                                      onTap: _closeKeyboard, // YENİ: Dropdown'a tıklanınca klavyeyi kapat
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 40,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Color(0xFF6A1B9A)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton2<IsletmeHizmet>(
                                            isExpanded: true,
                                            hint: Text('Hizmet Seç', style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor)),
                                            items: isletmehizmetliste.map((item) => DropdownMenuItem(
                                              value: item,
                                              child: Text(item.hizmet['hizmet_adi'], style: TextStyle(fontSize: 14)),
                                            )).toList(),
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
                                            buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 10), height: 50, width: 400),
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

                              // Süre
                              SizedBox(
                                width: columnWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Süre (dk)', style: TextStyle(fontSize: 11)),
                                    SizedBox(height: 5),
                                    Container(
                                      alignment: Alignment.center,
                                      height: 40,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Color(0xFF6A1B9A)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: TextFormField(
                                        controller: suredk[index],
                                        keyboardType: TextInputType.phone,
                                        onTap: () {
                                          // YENİ: TextField'a tıklanınca klavyeyi aç (diğerlerini kapatmaya gerek yok)
                                        },
                                        onChanged: (value) {
                                          suredk[index].text = value!;
                                          randevuhizmetleri[index].sure_dk = value;
                                        },
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.all(15.0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Fiyat
                              SizedBox(
                                width: columnWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Fiyat (₺)', style: TextStyle(fontSize: 11)),
                                    SizedBox(height: 5),
                                    Container(
                                      alignment: Alignment.center,
                                      height: 40,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Color(0xFF6A1B9A)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: TextFormField(
                                        controller: fiyat[index],
                                        keyboardType: TextInputType.phone,
                                        onTap: () {
                                          // YENİ: TextField'a tıklanınca klavyeyi aç
                                        },
                                        onChanged: (value) {
                                          fiyat[index].text = value!;
                                          randevuhizmetleri[index].fiyat=value;
                                        },
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.all(15.0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (randevuhizmetleri.length > 1)
                                IconButton(
                                  icon: Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () {
                                    _closeKeyboard(); // YENİ: Butona tıklanınca klavyeyi kapat
                                    setState(() => randevuhizmetleri.removeAt(index));
                                  },
                                )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                }),

                const Divider(height: 1.0, thickness: 1),

                /*ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                  leading: const Icon(Icons.cached_rounded, color: Colors.black54),
                  title: Row(children: <Widget>[
                    const Expanded(child: Text('Tekrarlayan')),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Switch(
                          value: tekrarlayanrandevu,
                          activeColor: Colors.deepPurple,
                          onChanged: (bool value) {
                            _closeKeyboard(); // YENİ: Switch değişince klavyeyi kapat
                            setState(() {
                              tekrarlayanrandevu = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ]),
                ),

                const Divider(height: 1.0, thickness: 1),

                tekrarlayanrandevu
                    ? Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Container(
                            height: 20,
                            margin: EdgeInsets.all(8.0),
                            child: Text('Tekrar Sıklığı', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            height: 50,
                            margin: EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: _closeKeyboard, // YENİ: Dropdown'a tıklanınca klavyeyi kapat
                              child: Container(
                                alignment: Alignment.center,
                                height: 40,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Color(0xFF6A1B9A)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton2<RandevuTekrarSikligi>(
                                    isExpanded: true,
                                    hint: Text(
                                      'Tekrar Sıklığı Seç',
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
                                      padding: EdgeInsets.symmetric(horizontal: 16),
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
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Container(
                            height: 20,
                            margin: EdgeInsets.all(8.0),
                            child: Text('Tekrar Sayısı', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            height: 50,
                            margin: EdgeInsets.all(8.0),
                            child: TextFormField(
                              onTap: () {
                                // YENİ: TextField'a tıklanınca klavyeyi aç
                              },
                              onChanged: (value) {
                                tekrarsayisi.text = value!;
                              },
                              keyboardType: TextInputType.phone,
                              controller: tekrarsayisi,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(15.0),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                )
                    : Padding(padding: const EdgeInsets.all(0)),

                tekrarlayanrandevu ? const Divider(height: 1.0, thickness: 1) : Padding(padding: const EdgeInsets.all(0)),

                const Divider(height: 1.0, thickness: 1),
                */
                ListTile(
                  contentPadding: const EdgeInsets.all(5),
                  leading: const Icon(Icons.subject, color: Colors.black87),
                  title: TextFormField(
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
                    style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w400),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Notlar',
                    ),
                  ),
                ),

                const Divider(height: 1.0, thickness: 1),
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        bottomNavigationBar: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.mainBg,
          ),
          child: ElevatedButton(
            onPressed: () {
              _closeKeyboard(); // YENİ: Butona tıklanınca klavyeyi kapat
              setState(() {
                formisvalid = true;
                String uyari = 'Randevuyu güncellemeden önce gerekli alanları eksiksiz doldurunuz.\n';

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
                bool odaSeciliDegil = secilicihaz.any((element) => element == null);

                if (widget.isletmebilgi["randevu_takvim_turu"] == 1) {
                  if(personelSeciliDegil) {
                    formisvalid = false;
                    uyari += '\nLütfen personel seçiniz.';
                  }
                }

                if (widget.isletmebilgi["randevu_takvim_turu"] == 2) {
                  if(cihazSeciliDegil){
                    formisvalid = false;
                    uyari += '\nLütfen cihaz seçiniz.';
                  }
                }

                if (widget.isletmebilgi["randevu_takvim_turu"] == 3) {
                  if(odaSeciliDegil){
                    formisvalid = false;
                    uyari += '\nLütfen oda seçiniz.';
                  }
                }

                if(himzetSeciliDegil) {
                  formisvalid = false;
                  uyari += '\nLütfen hizmet seçiniz.';
                }

                if (formisvalid == false)
                  formWarningDialogs(context, 'UYARI', uyari);
                else {
                  log('hizmetler json '+jsonEncode(randevuhizmetleri));
                  randevuEkleGuncelle(
                    '',
                    '',
                    widget.randevu.id.toString(),
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
                    widget.isletmebilgi
                  );
                }
              });
            },
            child: Text('RANDEVUYU GÜNCELLE'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              minimumSize: Size(90, 40),
            ),
          ),
        ),
        appBar: new AppBar(
          title: const Text('Randevu Düzenle', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.clear_rounded, color: Colors.black),
            onPressed: () {
              _closeKeyboard(); // YENİ: Geri butonuna tıklanınca klavyeyi kapat
              Navigator.of(context).pop();
            },
          ),
          actions: [
            if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 100,
                  child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
                ),
              ),
          ],
          toolbarHeight: 60,
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Stack(
            children: <Widget>[_getAppointmentEditor(context)],
          ),
        ),
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
      if (index != randevuhizmetyardimcipersoneller.length)
        yardimcipersoneller += ', ';
    });
    return yardimcipersoneller;
  }
}