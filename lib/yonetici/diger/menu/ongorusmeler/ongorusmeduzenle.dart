import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_model_list/drop_down/model.dart';
import 'package:dropdown_model_list/drop_down/search_drop_list.dart';
import 'package:dropdown_model_list/drop_down/select_drop_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/ongorusmenedeni.dart';


import '../../../../Backend/backend.dart';
import '../../../../Models/musteridanisanreferans.dart';
import '../../../../Models/ongorusmeler.dart';
import '../../../../Models/personel.dart';
import '../../../../Models/sehirler.dart';



class OnGorusmeDuzenle extends StatefulWidget {
  final OnGorusmeDataSource ongorusmedatasource;
  final OnGorusme ongorusme;
  final dynamic isletmebilgi;
  const OnGorusmeDuzenle({Key? key,required this.ongorusmedatasource, required this.ongorusme,required this.isletmebilgi}) : super(key: key);

  @override
  _OnGorusmeState createState() => _OnGorusmeState();
}
enum SingingCharacter { kadin, erkek }
class _OnGorusmeState extends State<OnGorusmeDuzenle> {


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
    ongrusmetarih.text = ""; //set the initial value of text

    super.initState();
    initialize();
  }
  Future<void> initialize() async
  {
    seciliisletme = (await secilisalonid())!;
    final isletmeVerileri = await isletmeVerileriGetir(seciliisletme,false,'','','',0,0);
    List<MusteriDanisan> musteridanisan = isletmeVerileri['musteriler'];
    List<Personel> isletmepersonellerliste = isletmeVerileri['personeller'];
    List<OnGorusmeNedeni> ongorusmenedeniliste = isletmeVerileri['onGorusmeNedeni'];
    List<Sehir> sehirler = await isletmeVerileri['sehirler'];
    log(widget.ongorusme.saat);

    setState(() {
      musteri = musteridanisan;
      ongorusmeyapan = isletmepersonellerliste;
      ongorusmesehir = sehirler;
      ongorusmeneden = ongorusmenedeniliste;
      yukleniyor = false;

      selectedongorusmereferans = ongorusmereferans.firstWhere(

                (item) => item.id == widget.ongorusme.musteri_tipi,

      );
      adsoyad.text = widget.ongorusme.ad_soyad;
      telefon.text = widget.ongorusme.cep_telefon != "null" ? widget.ongorusme.cep_telefon : "";
      email.text = widget.ongorusme.email!="null" ? widget.ongorusme.email : "";
      meslek.text = widget.ongorusme.meslek!="null" ? widget.ongorusme.meslek : "";
      ongorusmetarihi.text = widget.ongorusme.tarih!= "null" ? widget.ongorusme.tarih : "";
      ongorusmesaati.text = widget.ongorusme.saat !="null" ? widget.ongorusme.saat : "";
      ongorusmeaciklama.text = widget.ongorusme.aciklama != "null" ? widget.ongorusme.aciklama : "";
      selectedongorusmeyapan = isletmepersonellerliste.firstWhere((element) => element.id.toString() == widget.ongorusme.personel["id"].toString(),orElse: () => Personel.fromJson(widget.ongorusme.personel),);
      selectedongorusmesebep = ongorusmenedeniliste.firstWhere((element) => element.getPaketUrunAdi() == ongorusmesebebigetir(widget.ongorusme) );
      _selectedGender = musteridanisancinsiyet(widget.ongorusme);
      selectedMusteri = musteridanisan.firstWhere((element) => element.id.toString() == widget.ongorusme.musteri["id"].toString());
      selectedongorusmesehir = sehirler.firstWhere((element) => element.id.toString() == widget.ongorusme.il_id.toString(),orElse: () => null as Sehir,);


    });

  }
  String musteridanisancinsiyet( OnGorusme og)
  {
    String cinsiyet = "";
    if(og.cinsiyet=="0")
      return "kadin";
    if(og.cinsiyet=="1")
      return "erkek";
    return cinsiyet;
  }
  String ongorusmesebebigetir(OnGorusme og)
  {
    String neden = "";
    if(og.paket_id != "null")
      neden = og.paket["paket_adi"] + " (Paket)";
    if(og.urun_id != "null")
      neden = og.urun["urun_adi"]+ " (Ürün)";
    return neden;
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
          title: const Text('Ön Görüşme Düzenle',style: TextStyle(color: Colors.black),),
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
                width: 100, // <-- Your width
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
              ),
            ),
          ],
        ),

        body: yukleniyor ? Center(child: CircularProgressIndicator(),) : GestureDetector(
          onTap: () {
            // Unfocus the current text field, dismissing the keyboard
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            reverse: true,
            child: Container(
              margin: const EdgeInsets.all(15.0),
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate,
                child: formUI(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget formUI() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
              borderRadius: BorderRadius.circular(10), //border corner radius

              //you can set more BoxShadow() here

            ),
            child: DropdownButtonHideUnderline(

                child: DropdownButton2<MusteriDanisan>(

                  isExpanded: true,
                  hint: Text(
                    'Müşteri Seç',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  items: musteri
                      .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ))
                      .toList(),
                  value: selectedMusteri,
                  onChanged: (value) {
                    setState(() {
                      selectedMusteri = value;
                      adsoyad.text = value?.name ??'';

                      telefon.text = value?.cep_telefon ??'';

                      email.text = value?.email ??'';
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
                    searchController: ongorusmemustericontroller,
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
                        controller: ongorusmemustericontroller,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          hintText: 'Müşteri Ara..',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    searchMatchFn: (item, searchValue) {
                      return item.value!.name.toString().toLowerCase().contains(searchValue.toLowerCase());

                    },
                  ),
                  //This to clear the search value when you close the menu
                  onMenuStateChange: (isOpen) {
                    if (!isOpen) {
                      ongorusmemustericontroller.clear();
                    }
                  },

                )),
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
              controller: adsoyad ,
              keyboardType: TextInputType.text,

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
            child: Text('Şehir',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
          ),
          SizedBox(height: 10,),
          Container(
            alignment: Alignment.center,

            height: 40,
            width:double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color(0xFF6A1B9A)),
              borderRadius: BorderRadius.circular(10), //border corner radius

              //you can set more BoxShadow() here

            ),
            child: DropdownButtonHideUnderline(

                child: DropdownButton2<Sehir>(

                  isExpanded: true,
                  hint: Text(
                    'Şehir Seç',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  items: ongorusmesehir
                      .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item.sehir,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ))
                      .toList(),
                  value: selectedongorusmesehir,
                  onChanged: (value) {
                    setState(() {
                      selectedongorusmesehir = value!;
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
                    searchController: ongorusmesehircontroller,
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

                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          hintText: 'Şehir Ara..',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    searchMatchFn: (item, searchValue) {
                      return item.value.toString().contains(searchValue);
                    },
                  ),
                  //This to clear the search value when you close the menu
                  onMenuStateChange: (isOpen) {
                    if (!isOpen) {
                      ongorusmesehircontroller.clear();
                    }
                  },

                )),
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
              borderRadius: BorderRadius.circular(10), //border corner radius

              //you can set more BoxShadow() here

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
                      style: const TextStyle(
                        fontSize: 14,
                      ),
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

                  dropdownStyleData: const DropdownStyleData(
                    maxHeight: 200,

                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    height: 40,
                  ),

                  //This to clear the search value when you close the menu
                  onMenuStateChange: (isOpen) {
                    if (!isOpen) {
                      ongorusmereferanscontroller.clear();
                    }
                  },

                )),
          ),
          SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text('Meslek',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
          ),
          SizedBox(height: 10,),
          Container(
            height: 40,
            child: TextFormField(
              controller: meslek,
              keyboardType: TextInputType.text,

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
              borderRadius: BorderRadius.circular(10), //border corner radius

              //you can set more BoxShadow() here

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
                      style: const TextStyle(
                        fontSize: 14,
                      ),
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

                  dropdownStyleData: const DropdownStyleData(
                    maxHeight: 200,

                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    height: 40,
                  ),
                  dropdownSearchData: DropdownSearchData(
                    searchController: ongorusmesebepcontroller,
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
                        controller: ongorusmesebepcontroller,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          hintText: 'Ara..',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    searchMatchFn: (item, searchValue) {
                      return item.value.toString().contains(searchValue);
                    },
                  ),
                  //This to clear the search value when you close the menu
                  onMenuStateChange: (isOpen) {
                    if (!isOpen) {
                      ongorusmesebepcontroller.clear();
                    }
                  },

                )),
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
              borderRadius: BorderRadius.circular(10), //border corner radius

              //you can set more BoxShadow() here

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
                      style: const TextStyle(
                        fontSize: 14,
                      ),
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

                  dropdownStyleData: const DropdownStyleData(
                    maxHeight: 200,

                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    height: 40,
                  ),
                  dropdownSearchData: DropdownSearchData(
                    searchController: ongorusmeyapancontroller,
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
                        controller: ongorusmeyapancontroller,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          hintText: 'Ara..',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    searchMatchFn: (item, searchValue) {
                      return item.value.toString().contains(searchValue);
                    },
                  ),
                  //This to clear the search value when you close the menu
                  onMenuStateChange: (isOpen) {
                    if (!isOpen) {
                      ongorusmeyapancontroller.clear();
                    }
                  },

                )),
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
                      //editing controller of this TextField
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
                      //set it true, so that user will not able to edit text

                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1950),
                            //DateTime.now() - not to allow to choose before today.
                            lastDate: DateTime(2100));

                        if (pickedDate != null) {
                          print(
                              pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
                          String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                          print(
                              formattedDate); //formatted date output using intl package =>  2021-03-16
                          setState(() {
                            ongorusmetarihi.text =
                                formattedDate; //set output date to TextField value.
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
                      onChanged : (value) {
                        ongorusmesaati.text = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen saati yazınız!';
                        }
                        return null;
                      },
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context, initialTime: TimeOfDay.now(),
                          builder: (BuildContext context, Widget? child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            );
                          },

                        );

                        if (pickedTime != null && pickedTime != _selectedTime) {
                          setState(() {
                            _selectedTime = pickedTime;
                            ongorusmesaati.text = DateFormat.Hm().format(
                              DateTime(
                                2023, // You can use any year, month, and day here.
                                1,    // You can use any month and day here.
                                1,    // You can use any month and day here.
                                pickedTime.hour,
                                pickedTime.minute,
                              ),
                            );
                          });
                        }
                      },
                      decoration: InputDecoration(

                        suffixIcon: Icon(Icons.access_time),
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
          SizedBox(height: 10,),
          const SizedBox(
            height: 20.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: (){

                String urunid = "";
                String paketid = "";
                String hizmetid = '';
                String paketurun = selectedongorusmesebep?.getPaketUrunAdi() ?? "";
                if(paketurun.contains("Paket"))
                  paketid = selectedongorusmesebep?.getId() ?? "";
                if(paketurun.contains("Ürün"))
                  urunid = selectedongorusmesebep?.getId() ?? "";
                if(paketurun.contains('IsletmeHizmet'))
                  hizmetid = selectedongorusmesebep?.getId() ?? '';
                widget.ongorusmedatasource.onGorusmeEkleGuncelle(widget.ongorusme.id.toString(), selectedMusteri?.id ?? "", adsoyad.text, telefon.text, email.text, _selectedGender, context, seciliisletme, selectedongorusmesehir?.id ?? "", selectedongorusmereferans?.id ?? "", meslek.text, urunid, paketid, ongorusmetarihi.text, ongorusmesaati.text, ongorusmeaciklama.text, selectedongorusmeyapan?.id ?? "","",hizmetid);

              },
                child: Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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