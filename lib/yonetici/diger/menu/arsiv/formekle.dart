import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Backend/backend.dart';
import '../../../../Frontend/lazyload.dart';
import '../../../../Frontend/progressloading.dart';
import '../../../../Frontend/tryInputFormat.dart';
import '../../../../Models/personel.dart';
import '../../../../Models/sozlesme.dart';
import 'arsivyonetimipage.dart';
import 'package:http/http.dart' as http;

class FormEkle extends StatefulWidget {
  final dynamic isletmebilgi;
  FormEkle({Key? key,required this.isletmebilgi}) : super(key: key);
  @override
  _FormEkleState createState() => _FormEkleState();
}
class _FormEkleState extends State<FormEkle> {

  final _formKey = GlobalKey<FormState>();

  String secyazisi = 'Veriler getiriliyor. Lütfen bekleyiniz!';


  TextEditingController formController = TextEditingController();


  TextEditingController musteriController = TextEditingController();
  late List<IsletmeHizmet> isletmehizmetliste;
  late List<Personel> personelliste;
  late List<MusteriDanisan> musteridanisanliste;
  late List<Sozlesme> formlar;
  var seciliisletme = '';
  bool isloading = true;
  Personel? selectedpersonel;
  Sozlesme? selectedform;
  MusteriDanisan? selectedmusteri;
  TextEditingController personelController = TextEditingController();
  final List<String> mustericins = [
    'Kadın',
    'Erkek',
  ];
  String? selectedmustericins;
  TextEditingController mustericinsController = TextEditingController();

  TextEditingController musteritelefon = TextEditingController();
  TextEditingController musteritc = TextEditingController();
  TextEditingController musteridotarih = TextEditingController();
  TextEditingController personeltelefon = TextEditingController();
  TextEditingController hizmet = TextEditingController();
  TextEditingController hizmetFiyati = TextEditingController(text: "0");

  IsletmeHizmet? secilihizmet;


  void initState() {
    super.initState();
    initialize();
  }

  @override
  Future<void> initialize() async
  {
    seciliisletme = (await secilisalonid())!;

    // TÜM müşterileri getir - randevu eklemedeki gibi
    final isletmeVerileri = await isletmeVerileriGetir(seciliisletme, false, '', '', '', 0, 0);
    List<MusteriDanisan> musteridanisan = isletmeVerileri['musteriler'];

    List<Personel> isletmepersonellerliste =  isletmeVerileri['personeller'];
    List<Sozlesme> sozlesmeler = isletmeVerileri['formlar'];


    setState(() {
      musteridanisanliste = musteridanisan;
      personelliste = isletmepersonellerliste;
      formlar = sozlesmeler;
      isletmehizmetliste = isletmeVerileri['hizmetler'];
      isloading = false;
    });
  }
  void _closeKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title:  const Text('Yeni Form Oluştur',style: TextStyle(color: Colors.black),),
        leading: IconButton(
          icon: Icon(Icons.clear_rounded, color: Colors.black),
          onPressed: () {Navigator.of(context).pop(); Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft,duration: Duration(milliseconds:500), child: ArsivYonetimiPage(isletmebilgi: widget.isletmebilgi,)));},
        ),
        toolbarHeight: 60,
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 100,
                  child:  YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
              ),
            ),
        ],
        backgroundColor: Colors.white,
      ),
      body: isloading ? Center(child: CircularProgressIndicator(),) : SingleChildScrollView(
          reverse: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text('Form/Sözleşme Türü',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(left:20,right: 20),
                height: 40,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton2<Sozlesme>(
                      isExpanded: true,
                      hint: Text(
                        'Seç',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      items: formlar
                          .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.form_adi,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ))
                          .toList(),
                      value: selectedform,
                      onChanged: (value) {
                        setState(() {
                          selectedform = value;
                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                        width: 400,
                      ),
                      dropdownStyleData: const DropdownStyleData(
                        maxHeight: 200,
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                      ),
                      dropdownSearchData: DropdownSearchData(
                        searchController: formController,
                        searchInnerWidgetHeight: 50,
                        searchInnerWidget: Container(
                          height: 50,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 4,
                            right: 8,
                            left: 8,
                          ),
                          child: TextFormField(
                            expands: true,
                            maxLines: null,
                            controller: formController,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              hintText: ' Ara..',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                        searchMatchFn: (item, searchValue) {
                          return item.value!.form_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
                        },
                      ),
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) {
                          formController.clear();
                        }
                      },
                    )),
              ),

              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text('Müşteri/Danışan',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 10,),
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(left:20,right: 20),
                height: 43,
                width:double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                    child: LazyDropdown(
                      salonId: seciliisletme,
                      selectedItem: selectedmusteri,
                      onChanged: (value) {
                        setState(() {
                          selectedmusteri = value;
                          if(value?.dogum_tarihi != 'null')
                            musteridotarih.text = value?.dogum_tarihi ??'';
                          if(value?.cep_telefon != 'null')
                            musteritelefon.text = value?.cep_telefon ?? '';
                          if(value?.tc_kimlik_no != 'null')
                            musteritc.text = value?.tc_kimlik_no ?? '';
                          if(value?.cinsiyet == '0')
                            selectedmustericins = 'Kadın';
                          else if(value?.cinsiyet == '1')
                            selectedmustericins = 'Erkek';
                        });


                      },
                    ), ),
              ),

              SizedBox(height: 10,),
              Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text('Cep Telefon',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 10,),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.only(left: 20.0,right: 20),
                      child: TextField(
                        controller: musteritelefon,
                        onSubmitted: (text)=>print(musteritelefon.text),
                        keyboardType: TextInputType.text,
                        enabled:true,
                        decoration: InputDecoration(
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(15.0),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                              color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                          border:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                  ],)),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('TC Kimlik No',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.only(left: 20.0,right: 20),
                        child: TextField(
                          controller: musteritc,
                          onSubmitted: (text)=>print(musteritc.text),
                          keyboardType: TextInputType.text,
                          enabled:true,
                          decoration: InputDecoration(
                            focusColor:Color(0xFF6A1B9A) ,
                            hoverColor: Color(0xFF6A1B9A) ,
                            hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                            contentPadding:  EdgeInsets.all(15.0),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                            border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                    ],))
                ],
              ),
              SizedBox(height: 10,),
              Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Doğum Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 40,
                        padding: EdgeInsets.only(left:20,right: 20),
                        child: TextField(
                          controller: musteridotarih,
                          enabled:true,
                          decoration: InputDecoration(
                            focusColor:Color(0xFF6A1B9A) ,
                            hoverColor: Color(0xFF6A1B9A) ,
                            hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                            contentPadding:  EdgeInsets.all(15.0),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                            border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
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
                              String formattedDate =
                              DateFormat('yyyy-MM-dd').format(pickedDate);
                              setState(() {
                                musteridotarih.text = formattedDate;
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
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Cinsiyet',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(left:20,right: 20),
                        height: 40,
                        width:double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Color(0xFF6A1B9A)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              isExpanded: true,
                              hint: Text(
                                'Seç',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              items: mustericins
                                  .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ))
                                  .toList(),
                              value: selectedmustericins,
                              onChanged: (value) {
                                setState(() {
                                  selectedmustericins = value;
                                });
                              },
                              buttonStyleData: const ButtonStyleData(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                height: 50,
                                width: 400,
                              ),
                              dropdownStyleData: const DropdownStyleData(
                                maxHeight: 200,
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                height: 40,
                              ),
                              dropdownSearchData: DropdownSearchData(
                                searchController: mustericinsController,
                                searchInnerWidgetHeight: 50,
                                searchInnerWidget: Container(
                                  height: 50,
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 4,
                                    right: 8,
                                    left: 8,
                                  ),
                                  child: TextFormField(
                                    expands: true,
                                    maxLines: null,
                                    controller: mustericinsController,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      hintText: ' Ara..',
                                      hintStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                                searchMatchFn: (item, searchValue) {
                                  return item.value.toString().contains(searchValue);
                                },
                              ),
                              onMenuStateChange: (isOpen) {
                                if (!isOpen) {
                                  mustericinsController.clear();
                                }
                              },
                            )),
                      ),
                    ],
                  ))
                ],
              ),
              SizedBox(height: 10,),
              Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('İşlemi Yapan Personel',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(left:20,right: 20),
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
                              items: personelliste
                                  .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  item.personel_adi,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ))
                                  .toList(),
                              value: selectedpersonel,
                              onChanged: (value) {
                                setState(() {
                                  selectedpersonel = value;
                                  personeltelefon.text = value?.cep_telefon ?? '';
                                });
                              },
                              buttonStyleData: const ButtonStyleData(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                height: 50,
                                width: 400,
                              ),
                              dropdownStyleData: const DropdownStyleData(
                                maxHeight: 200,
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                height: 40,
                              ),
                              dropdownSearchData: DropdownSearchData(
                                searchController: personelController,
                                searchInnerWidgetHeight: 50,
                                searchInnerWidget: Container(
                                  height: 50,
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 4,
                                    right: 8,
                                    left: 8,
                                  ),
                                  child: TextFormField(
                                    expands: true,
                                    maxLines: null,
                                    controller: personelController,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      hintText: ' Ara..',
                                      hintStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                                searchMatchFn: (item, searchValue) {
                                  return item.value.toString().contains(searchValue);
                                },
                              ),
                              onMenuStateChange: (isOpen) {
                                if (!isOpen) {
                                  personelController.clear();
                                }
                              },
                            )),
                      ),
                    ],
                  )),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text('Personel Cep Telefon',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.only(left: 20.0,right: 20),
                        child: TextField(
                          controller: personeltelefon,
                          onSubmitted: (text)=>print(personeltelefon .text),
                          keyboardType: TextInputType.text,
                          enabled:true,
                          decoration: InputDecoration(
                            focusColor:Color(0xFF6A1B9A) ,
                            hoverColor: Color(0xFF6A1B9A) ,
                            hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                            contentPadding:  EdgeInsets.all(15.0),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                                color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                            border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ))
                ],
              ),
              SizedBox(height: 10),
              selectedform!=null && selectedform!.id.toString() == "12" ?

                  Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text('Hizmet',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                  ),
                  SizedBox(height: 10,),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0,right: 20.0),
                    child:  GestureDetector(
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
                            hint: Text('Hizmet Seç', style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
                            items: isletmehizmetliste
                                .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.hizmet['hizmet_adi'], style: TextStyle(fontSize: 14)),
                            ))
                                .toList(),
                            value: secilihizmet,
                            onChanged: (value) {
                              _closeKeyboard(); // YENİ: Değişiklikte klavyeyi kapat
                              setState(() {
                                hizmetFiyati.text = value!.fiyat != 'null' ? value!.fiyat : '0';
                                secilihizmet = value;
                              });
                            },
                            buttonStyleData: ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 10), height: 50, width: 400),
                            dropdownStyleData: DropdownStyleData(maxHeight: 400),
                            menuItemStyleData: MenuItemStyleData(height: 60),
                            dropdownSearchData: DropdownSearchData(
                              searchController: hizmet,
                              searchInnerWidgetHeight: 50,
                              searchInnerWidget: Container(
                                height: 50,
                                padding: EdgeInsets.all(8),
                                child: TextFormField(
                                  expands: true,
                                  maxLines: null,
                                  controller: hizmet,
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
                  ),

                ],
              )),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text('Hizmet Fiyatı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                  ),
                  SizedBox(height: 10,),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.only(left: 20.0,right: 20),
                    child: TextField(
                      controller: hizmetFiyati,

                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        TurkishLiraFormatter(),
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')), // Sadece rakam, virgül ve nokta
                      ],
                      enabled:true,
                      decoration  : InputDecoration(
                        focusColor:Color(0xFF6A1B9A) ,
                        hoverColor: Color(0xFF6A1B9A) ,
                        hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                        contentPadding:  EdgeInsets.all(15.0),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                            color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(10.0),),
                        border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(10.0),),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ))
            ],
          )

                  : SizedBox(),
              SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: (){
                    formekleguncelle();
                  },
                    child: Row(
                      children: [
                        Text(' Gönder'),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        minimumSize: Size(90, 40)
                    ),
                  ),
                ],
              ),
              Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
            ],
          )
      ),
    );
  }

  Future<void> formekleguncelle() async {
    List<String> errors = [];

    // 1. Form/Sözleşme Türü kontrolü
    if (selectedform == null) {
      errors.add('Form/Sözleşme türü seçilmedi.');
    }

    // 2. Müşteri/Danışan kontrolü
    if (selectedmusteri == null) {
      errors.add('Müşteri/Danışan seçilmedi.');
    }

    // 3. Personel kontrolü
    if (selectedpersonel == null) {
      errors.add('İşlemi yapacak personel seçilmedi.');
    }

    // 4. Eğer form ID 12 ise hizmet ve fiyat kontrolü
    if (selectedform != null && selectedform!.id.toString() == "12") {
      if (secilihizmet == null) {
        errors.add('Hizmet seçilmedi.');
      }

      if (hizmetFiyati.text.trim().isEmpty ||
          double.tryParse(hizmetFiyati.text.replaceAll(',', '.')) == null ||
          double.parse(hizmetFiyati.text.replaceAll(',', '.')) <= 0) {
        errors.add('Geçerli bir hizmet fiyatı girilmedi.');
      }
    }

    // Eksik varsa toplu uyarı göster
    if (errors.isNotEmpty) {
      _showValidationErrors(errors);
      return;
    }

    // Tüm kontroller geçildi, API çağrısı yapılıyor
    showProgressLoading(context);
    SharedPreferences localStorage = await SharedPreferences.getInstance();

    var user = jsonDecode(localStorage.getString('user')!);
    Map<String, dynamic> formData = {
      'user_id': selectedmusteri?.id,
      'form_id': selectedform?.id,
      'personel_id': selectedpersonel?.id,
      'cinsiyet': selectedmustericins ?? '',
      'dogumtarihi': musteridotarih.text,
      'cep_telefon': musteritelefon.text,
      'personel_cep': personeltelefon.text,
      'tc_kimlik_no': musteritc.text,
      'salon_id': seciliisletme,
      'olusturan': user["id"],
      "hizmet": secilihizmet?.hizmet_id,
      "ucret": hizmetFiyati.text,
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/arsivformekleguncelle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context).pop(response.body);
      Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeft,
          duration: Duration(milliseconds: 500),
          child: ArsivYonetimiPage(isletmebilgi: widget.isletmebilgi),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form oluşturulurken bir hata oluştu! Hata kodu : ${response.statusCode}'),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }
  void _showStyledAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Tamam'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _showValidationErrors(List<String> errors) {
    if (errors.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Eksik Bilgiler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey, thickness: 0.5),
                const SizedBox(height: 12),
                ...errors.map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Tamam'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}