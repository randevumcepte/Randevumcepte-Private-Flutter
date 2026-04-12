import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:dropdown_model_list/drop_down/search_drop_list.dart';
import 'package:dropdown_model_list/drop_down/select_drop_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/secilipersonel.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/ongorusmenedeni.dart';

import '../../../../../Backend/backend.dart';
import '../../../../../Models/musteridanisanreferans.dart';
import '../../../../../Models/personel.dart';
import '../../../../../Models/sehirler.dart';
import '../../../../Frontend/lazyload.dart';

class YeniOnGorusme extends StatefulWidget {
  final OnGorusmeDataSource ongorusmedatasource;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const YeniOnGorusme({Key? key,required this.ongorusmedatasource,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _YeniOnGorusmeState createState() => _YeniOnGorusmeState();
}

enum SingingCharacter { kadin, erkek }

class _YeniOnGorusmeState extends State<YeniOnGorusme> {
  TimeOfDay _selectedTime = TimeOfDay.now();

  late List<MusteriDanisan> musteri;
  MusteriDanisan? selectedMusteri;
  final TextEditingController ongorusmemustericontroller = TextEditingController();
  late List<Sehir> ongorusmesehir;
  Sehir? selectedongorusmesehir;
  final TextEditingController ongorusmesehircontroller = TextEditingController();
  final List<Referans> ongorusmereferans = [
    Referans(id: "", referans: "Yok"),
    Referans(id: "1", referans: "İnternet"),
    Referans(id: "2", referans: "Reklam"),
    Referans(id: "3", referans: "Instagram"),
    Referans(id: "4", referans: "Facebook"),
    Referans(id: "5", referans: "Tanıdık")
  ];
  Referans? selectedongorusmereferans;
  final TextEditingController ongorusmereferanscontroller = TextEditingController();

  OnGorusmeNedeni? selectedongorusmesebep;
  late String seciliisletme;

  final TextEditingController ongorusmesebepcontroller = TextEditingController();
  final TextEditingController adsoyad = TextEditingController();
  final TextEditingController telefon = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController meslek = TextEditingController();
  final TextEditingController ongorusmetarihi = TextEditingController();
  final TextEditingController ongorusmesaati =  TextEditingController();
  final TextEditingController ongorusmeaciklama = TextEditingController();

  late List<Personel> ongorusmeyapan;
  late List<OnGorusmeNedeni> ongorusmeneden;
  Personel? selectedongorusmeyapan;
  final TextEditingController ongorusmeyapancontroller = TextEditingController();
  bool yukleniyor=true;
  TextEditingController ongrusmetarih = TextEditingController();

  String _selectedGender = '';

  @override
  void initState() {
    ongrusmetarih.text = "";
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    final isletmeVerileri = await isletmeVerileriGetir(seciliisletme,false,'','','',0,0);
    List<MusteriDanisan> musteridanisan = isletmeVerileri['musteriler'];
    List<Personel> isletmepersonellerliste = isletmeVerileri['personeller'];
    List<OnGorusmeNedeni> ongorusmenedeniliste = isletmeVerileri['onGorusmeNedeni'];
    List<Sehir> sehirler = isletmeVerileri['sehirler'];
    selectedongorusmeyapan = await seciliPersonelgetir(widget.isletmebilgi);
    setState(() {
      musteri = musteridanisan;
      ongorusmeyapan = isletmepersonellerliste;
      ongorusmesehir = sehirler;
      ongorusmeneden = ongorusmenedeniliste;
      yukleniyor = false;
      selectedongorusmereferans = ongorusmereferans.firstWhere((item) => item.id == "");
      selectedongorusmeyapan = selectedongorusmeyapan;
    });
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: new AppBar(
          title: const Text('Yeni Ön Görüşme',style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.clear_rounded, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                    width: 100,
                    child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
                ),
              ),
          ],
        ),
        body: yukleniyor ? Center(child: CircularProgressIndicator()) : GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidate,
              child: formUI(),
            ),
          ),
        ),
      ),
    );
  }

  // YENİ: Modern saat seçim fonksiyonu - DAKİKALAR 00-15-30-45 OLARAK GÜNCELLENDİ
  Future<void> _showModernTimePicker(BuildContext context) async {
    TimeOfDay initialTime = _selectedTime;
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
        setState(() {
          _selectedTime = result;
          ongorusmesaati.text = '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
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

  Widget formUI() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text('Müşteri/Danışan',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
          ),
          SizedBox(height: 10,),
          Container(
            alignment: Alignment.center,
            height: 40,
            width:double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color(0xFF6A1B9A)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: LazyDropdown(
              salonId: seciliisletme??'',
              selectedItem: selectedMusteri,
              onChanged: (value) {
                selectedMusteri = value;
                setState(() {
                  selectedMusteri = value;
                  adsoyad.text = value?.name ?? '';
                  telefon.text = value?.cep_telefon ?? '';
                  log('email '+value!.email);
                  email.text = value.email != 'null' ? value.email : '';
                  if(value?.cinsiyet == "0")
                    _selectedGender = "kadin";
                  if(value?.cinsiyet == "1")
                    _selectedGender = "erkek";
                  if(value?.il_id != "null")
                    selectedongorusmesehir = ongorusmesehir.firstWhere((item) => item.id == value?.il_id);
                  if(value?.musteri_tipi != "null")
                    selectedongorusmereferans = ongorusmereferans.firstWhere((item) => item.id == value?.musteri_tipi);
                  if(value?.meslek != "null")
                    meslek.text = value?.meslek ?? "";
                });
              },
            ),


          ),
          SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text('Ad Soyad',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
          ),
          SizedBox(height: 10,),
          Container(
            height: 40,
            child: TextFormField(
              controller: adsoyad,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                focusColor:Color(0xFF6A1B9A),
                hoverColor: Color(0xFF6A1B9A),
                hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                contentPadding:  EdgeInsets.all(15.0),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6A1B9A)), borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text('Telefon Numarası',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
          ),
          SizedBox(height: 10,),
          Container(
            height: 40,
            child: TextFormField(
              keyboardType: TextInputType.phone,
              controller: telefon,
              decoration: InputDecoration(
                focusColor:Color(0xFF6A1B9A),
                hoverColor: Color(0xFF6A1B9A),
                hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                contentPadding:  EdgeInsets.all(15.0),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6A1B9A)), borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text('E-mail',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
          ),
          SizedBox(height: 10,),
          Container(
            height: 40,
            child: TextField(
              keyboardType: TextInputType.emailAddress,
              controller: email,
              decoration: InputDecoration(
                focusColor:Color(0xFF6A1B9A),
                hoverColor: Color(0xFF6A1B9A),
                hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                contentPadding:  EdgeInsets.all(15.0),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6A1B9A)), borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text('Cinsiyet',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  leading: Radio<String>(
                    value: 'kadin',
                    groupValue: _selectedGender,
                    activeColor: Colors.purple[800],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                  title: const Text('Kadın'),
                ),
              ),
              Expanded(
                child: ListTile(
                  leading: Radio<String>(
                    value: 'erkek',
                    groupValue: _selectedGender,
                    activeColor: Colors.purple[800],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                  title: const Text('Erkek'),
                ),
              ),
            ],
          ),
          SizedBox(height: 10,),

          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text('Referans',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
          ),
          SizedBox(height: 10,),
          Container(
            alignment: Alignment.center,
            height: 40,
            width:double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color(0xFF6A1B9A)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<Referans>(
                isExpanded: true,
                hint: Text(
                  'Referans Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                items: ongorusmereferans
                    .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.referans,
                    style: const TextStyle(fontSize: 14),
                  ),
                ))
                    .toList(),
                value: selectedongorusmereferans,
                onChanged: (value) {
                  setState(() {
                    selectedongorusmereferans = value;
                  });
                },
                buttonStyleData: const ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: 400,
                ),
                dropdownStyleData: const DropdownStyleData(maxHeight: 200),
                menuItemStyleData: const MenuItemStyleData(height: 40),
                onMenuStateChange: (isOpen) {
                  if (!isOpen) {
                    ongorusmereferanscontroller.clear();
                  }
                },
              ),
            ),
          ),
          SizedBox(height: 10,),

          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text('Ön Görüşme Nedeni',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
          ),
          SizedBox(height: 10,),
          Container(
            alignment: Alignment.center,
            height: 40,
            width:double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color(0xFF6A1B9A)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<OnGorusmeNedeni>(
                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                items: ongorusmeneden
                    .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.getPaketUrunAdi(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ))
                    .toList(),
                value: selectedongorusmesebep,
                onChanged: (value) {
                  setState(() {
                    selectedongorusmesebep = value;
                  });
                },
                buttonStyleData: const ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: 400,
                ),
                dropdownStyleData: const DropdownStyleData(maxHeight: 200),
                menuItemStyleData: const MenuItemStyleData(height: 40),
                dropdownSearchData: DropdownSearchData(
                  searchController: ongorusmesebepcontroller,
                  searchInnerWidgetHeight: 50,
                  searchInnerWidget: Container(
                    height: 50,
                    padding: const EdgeInsets.only(top: 8, bottom: 4, right: 8, left: 8),
                    child: TextFormField(
                      expands: true,
                      maxLines: null,
                      controller: ongorusmesebepcontroller,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        hintText: 'Ara..',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  searchMatchFn: (item, searchValue) {
                    return item.value!.getPaketUrunAdi().toString().toLowerCase().contains(searchValue.toLowerCase());
                  },
                ),
                onMenuStateChange: (isOpen) {
                  if (!isOpen) {
                    ongorusmesebepcontroller.clear();
                  }
                },
              ),
            ),
          ),
          SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text('Görüşmeyi Yapan',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
          ),
          SizedBox(height: 10,),
          Container(
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
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                items: ongorusmeyapan
                    .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.personel_adi,
                    style: const TextStyle(fontSize: 14),
                  ),
                ))
                    .toList(),
                value: selectedongorusmeyapan,
                onChanged: (value) {
                  setState(() {
                    selectedongorusmeyapan = value;
                  });
                },
                buttonStyleData: const ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: 400,
                ),
                dropdownStyleData: const DropdownStyleData(maxHeight: 200),
                menuItemStyleData: const MenuItemStyleData(height: 40),
                dropdownSearchData: DropdownSearchData(
                  searchController: ongorusmeyapancontroller,
                  searchInnerWidgetHeight: 50,
                  searchInnerWidget: Container(
                    height: 50,
                    padding: const EdgeInsets.only(top: 8, bottom: 4, right: 8, left: 8),
                    child: TextFormField(
                      expands: true,
                      maxLines: null,
                      controller: ongorusmeyapancontroller,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        hintText: 'Ara..',
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
                    ongorusmeyapancontroller.clear();
                  }
                },
              ),
            ),
          ),
          SizedBox(height: 10,),
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 0.0),
                    child: Text('Randevu Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                  ),
                  SizedBox(height: 10,),
                  Container(
                    height: 40,
                    padding: EdgeInsets.only(left:0,right: 20),
                    child: TextFormField(

                      onChanged: (value) {
                        ongorusmetarihi.text = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen tarihi yazınız!';
                        }
                        return null;
                      },
                      controller: ongorusmetarihi,
                      enabled:true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.calendar_month),
                        focusColor:Color(0xFF6A1B9A),
                        hoverColor: Color(0xFF6A1B9A),
                        hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                        contentPadding:  EdgeInsets.all(8.0),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6A1B9A)), borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      readOnly: true,
                      onTap: () async {
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
                            ongorusmetarihi.text = formattedDate;
                          });
                        } else {}
                      },
                    ),
                  ),
                ],
              )
              ),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 0.0),
                    child: Text('Randevu Saati',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                  ),
                  SizedBox(height: 10,),
                  Container(
                    height: 40,
                    padding: EdgeInsets.only(left:0,right: 0),
                    child: TextFormField(
                      controller: ongorusmesaati,
                      onChanged: (value) {
                        ongorusmesaati.text = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen saati yazınız!';
                        }
                        return null;
                      },
                      onTap: () async {
                        await _showModernTimePicker(context);
                      },
                      readOnly: true,
                      decoration: InputDecoration(
                        suffixIcon: Icon(Icons.access_time, color: Color(0xFF6A1B9A)),
                        focusColor:Color(0xFF6A1B9A),
                        hoverColor: Color(0xFF6A1B9A),
                        hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                        contentPadding:  EdgeInsets.all(15.0),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6A1B9A)), borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ))
            ],
          ),
          SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text('Açıklama',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
          ),
          SizedBox(height: 10,),
          Container(
            child: TextFormField(
              keyboardType: TextInputType.text,
              controller: ongorusmeaciklama,
              onSaved: (value){
                ongorusmeaciklama.text = value!;
              },
              maxLines: 2,
              decoration: InputDecoration(
                enabled:true,
                focusColor:Color(0xFF6A1B9A),
                hoverColor: Color(0xFF6A1B9A),
                hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                contentPadding:  EdgeInsets.all(15.0),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6A1B9A)), borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 10,),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: (){
                String urunid = "";
                String paketid = "";
                String hizmetid ='';
                String paketurun = selectedongorusmesebep?.getPaketUrunAdi() ?? "";
                if(paketurun.contains("Paket"))
                  paketid = selectedongorusmesebep?.getId() ?? "";
                if(paketurun.contains("Ürün"))
                  urunid = selectedongorusmesebep?.getId() ?? "";
                if(paketurun.contains('IsletmeHizmet'))
                  hizmetid = selectedongorusmesebep?.getId() ?? '';
                widget.ongorusmedatasource.onGorusmeEkleGuncelle("", selectedMusteri?.id ?? "", adsoyad.text, telefon.text, email.text, _selectedGender, context, seciliisletme, selectedongorusmesehir?.id ?? "", selectedongorusmereferans?.id ?? "", meslek.text, urunid, paketid, ongorusmetarihi.text, ongorusmesaati.text, ongorusmeaciklama.text, selectedongorusmeyapan?.id ?? "","",hizmetid);
              },
                child: Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(90, 40)
                ),
              ),
            ],
          ),
          Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
        ],
      ),
    );
  }

  String? validateName(String? value) {
    if (value!.isEmpty) {
      return 'İsmi boş bırakmayınız';
    }
    if (value.length < 3) {
      return '2 karakterden fazla olmalıdır';
    } else {
      return null;
    }
  }
}