import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_model_list/drop_down/model.dart';
import 'package:dropdown_model_list/drop_down/search_drop_list.dart';
import 'package:dropdown_model_list/drop_down/select_drop_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../../Backend/backend.dart';
import '../../../../../Models/cilttipi.dart';
import '../../../../../Models/musteri_danisanlar.dart';
import '../../../../../Models/saglikbilgileri.dart';





class MusteriPaneliSaglikBilgileri extends StatefulWidget {
  final MusteriDanisan md;
  const MusteriPaneliSaglikBilgileri({Key? key,required this.md}) : super(key: key);

  @override
  _MusteriPaneliSaglikBilgileriState createState() => _MusteriPaneliSaglikBilgileriState();
}

class _MusteriPaneliSaglikBilgileriState extends State<MusteriPaneliSaglikBilgileri> {
  late String seciliisletme;
  final List<SaglikBilgileri> evethayir = [
    SaglikBilgileri(id: "0", saglik: "Hayır"),
    SaglikBilgileri(id: "1", saglik: "Evet"),

  ];
  final List<CiltTipi> cilttipi = [
    CiltTipi(id: '0', citl: 'Karma'),
    CiltTipi(id: '1', citl: 'Yağlı'),
    CiltTipi(id: '2', citl: 'Hassas'),
    CiltTipi(id: '3', citl: 'Kuru'),
    CiltTipi(id: '4', citl: 'Nemli'),
    CiltTipi(id: '5', citl: 'Normla'),


  ];
  late TextEditingController eksaglik;
  late TextEditingController musteriid;
  SaglikBilgileri? selectedhemofili;
  final TextEditingController hemofilicontroller = TextEditingController();
  SaglikBilgileri? selectedseker;
  final TextEditingController sekercontroller = TextEditingController();
  SaglikBilgileri? selectedhamile;
  final TextEditingController hamilecontroller = TextEditingController();
  SaglikBilgileri? selectedameliyat;
  final TextEditingController ameliyatcontroller = TextEditingController();
  SaglikBilgileri? selectedalerji;
  final TextEditingController alerjicontroller = TextEditingController();
  SaglikBilgileri? selectedalkol;
  final TextEditingController alkolcontroller = TextEditingController();
  SaglikBilgileri? selectedregl;
  final TextEditingController reglcontroller = TextEditingController();
  SaglikBilgileri? selecteddoku;
  final TextEditingController dokucontroller = TextEditingController();
  SaglikBilgileri? selectedilac;
  final TextEditingController ilaccontroller = TextEditingController();
  SaglikBilgileri? selectedkemoterapi;
  final TextEditingController kemoterapicontroller = TextEditingController();
  SaglikBilgileri? selecteduygulama;
  final TextEditingController uygulamacontroller = TextEditingController();
  CiltTipi? selectedcilttip;
  final TextEditingController cilttipcontroller = TextEditingController();


  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  Future<void> initialize() async
  {
    seciliisletme = (await secilisalonid())!;
  }

  void initState() {
    super.initState();
    musteriid=TextEditingController(text:widget.md.id);
    eksaglik = TextEditingController(text: widget.md.ek_saglik_sorunu);
    selectedhemofili = evethayir
        .where((item) => item.id == widget.md.hemofili_hastaligi_var)
        .isNotEmpty
        ? evethayir.firstWhere((item) =>
    item.id == widget.md.hemofili_hastaligi_var)
        : null;
    selectedseker = evethayir
        .where((item) => item.id == widget.md.seker_hastaligi_var)
        .isNotEmpty
        ? evethayir.firstWhere((item) =>
    item.id == widget.md.seker_hastaligi_var)
        : null;
    selectedhamile = evethayir
        .where((item) => item.id == widget.md.hamile)
        .isNotEmpty
        ? evethayir.firstWhere((item) => item.id == widget.md.hamile)
        : null;
    selectedameliyat = evethayir
        .where((item) => item.id == widget.md.yakin_zamanda_ameliyat_gecirildi)
        .isNotEmpty
        ? evethayir.firstWhere((item) =>
    item.id == widget.md.yakin_zamanda_ameliyat_gecirildi)
        : null;
    selectedalerji = evethayir
        .where((item) => item.id == widget.md.alerji_var)
        .isNotEmpty
        ? evethayir.firstWhere((item) => item.id == widget.md.alerji_var)
        : null;
    selectedalkol = evethayir
        .where((item) => item.id == widget.md.alkol_alimi_yapildi)
        .isNotEmpty
        ? evethayir.firstWhere((item) =>
    item.id == widget.md.alkol_alimi_yapildi)
        : null;
    selectedregl = evethayir
        .where((item) => item.id == widget.md.regl_doneminde)
        .isNotEmpty
        ? evethayir.firstWhere((item) => item.id == widget.md.regl_doneminde)
        : null;
    selecteddoku = evethayir
        .where((item) => item.id == widget.md.deri_yumusak_doku_hastaligi_var)
        .isNotEmpty
        ? evethayir.firstWhere((item) =>
    item.id == widget.md.deri_yumusak_doku_hastaligi_var)
        : null;
    selectedilac = evethayir
        .where((item) => item.id == widget.md.surekli_kullanilan_ilac_Var)
        .isNotEmpty
        ? evethayir.firstWhere((item) =>
    item.id == widget.md.surekli_kullanilan_ilac_Var)
        : null;
    selectedkemoterapi = evethayir
        .where((item) => item.id == widget.md.kemoterapi_goruyor)
        .isNotEmpty
        ? evethayir.firstWhere((item) =>
    item.id == widget.md.kemoterapi_goruyor)
        : null;
    selecteduygulama = evethayir
        .where((item) => item.id == widget.md.daha_once_uygulama_yaptirildi)
        .isNotEmpty
        ? evethayir.firstWhere((item) =>
    item.id == widget.md.daha_once_uygulama_yaptirildi)
        : null;
    selectedcilttip = cilttipi
        .where((item) => item.id == widget.md.cilt_tipi)
        .isNotEmpty
        ? cilttipi.firstWhere((item) => item.id == widget.md.cilt_tipi)
        : null;

    initialize();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: Scaffold(


        appBar: new AppBar(
          title: const Text(
            'Sağlık Bilgileri', style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.clear_rounded, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),

        ),

        body: SingleChildScrollView(
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
    );
  }

  Widget formUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[

        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Hemofili Hastalığı Var mı?', style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<SaglikBilgileri>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: evethayir
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.saglik,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selectedhemofili,
                onChanged: (value) {
                  setState(() {
                    selectedhemofili = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    hemofilicontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Şeker Hastalığı Var mı?', style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<SaglikBilgileri>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: evethayir
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.saglik,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selectedseker,
                onChanged: (value) {
                  setState(() {
                    selectedseker = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    sekercontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Hamile mi?', style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<SaglikBilgileri>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: evethayir
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.saglik,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selectedhamile,
                onChanged: (value) {
                  setState(() {
                    selectedhamile = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    hamilecontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Yakın bir zamanda ameliyat geçirdi mi?',
            style: TextStyle(fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<SaglikBilgileri>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: evethayir
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.saglik,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selectedameliyat,
                onChanged: (value) {
                  setState(() {
                    selectedameliyat = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    ameliyatcontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),

        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Herhangi bir alerjisi var?', style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<SaglikBilgileri>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: evethayir
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.saglik,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selectedalerji,
                onChanged: (value) {
                  setState(() {
                    selectedalerji = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    alerjicontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('48 saat içinde alkol alımı var mı?', style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<SaglikBilgileri>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: evethayir
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.saglik,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selectedalkol,
                onChanged: (value) {
                  setState(() {
                    selectedalkol = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    alkolcontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Regl döneminde mi?', style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<SaglikBilgileri>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: evethayir
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.saglik,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selectedregl,
                onChanged: (value) {
                  setState(() {
                    selectedregl = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    reglcontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Deri veya yumuşak doku hastalığı var mı?',
            style: TextStyle(fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<SaglikBilgileri>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: evethayir
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.saglik,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selecteddoku,
                onChanged: (value) {
                  setState(() {
                    selecteddoku = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    dokucontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Sürekli kullanıdığı ilaç var mı?', style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<SaglikBilgileri>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: evethayir
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.saglik,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selectedilac,
                onChanged: (value) {
                  setState(() {
                    selectedilac = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    ilaccontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Kemoterapi görüyor mu?', style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<SaglikBilgileri>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: evethayir
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.saglik,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selectedkemoterapi,
                onChanged: (value) {
                  setState(() {
                    selectedkemoterapi = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    kemoterapicontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Daha önce uygulama yaptırdı mı?', style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<SaglikBilgileri>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: evethayir
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.saglik,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selecteduygulama,
                onChanged: (value) {
                  setState(() {
                    selecteduygulama = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    uygulamacontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Cilt Tipi', style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.center,

          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10), //border corner radius

            //you can set more BoxShadow() here

          ),
          child: DropdownButtonHideUnderline(

              child: DropdownButton2<CiltTipi>(

                isExpanded: true,
                hint: Text(
                  'Seç',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme
                        .of(context)
                        .hintColor,
                  ),
                ),
                items: cilttipi
                    .map((item) =>
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.citl,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ))
                    .toList(),
                value: selectedcilttip,
                onChanged: (value) {
                  setState(() {
                    selectedcilttip = value;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  width: MediaQuery.of(context).size.width - 40,
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
                    cilttipcontroller.clear();
                  }
                },

              )),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Ek sağlık sorunları var mı?', style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        TextFormField(

          keyboardType: TextInputType.text,

          controller: eksaglik,
          onSaved: (value) {
            eksaglik.text = value!;
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bu alan zorunludur!';
            }
            return null;
          },

          decoration: InputDecoration(

            focusColor: Color(0xFF6A1B9A),
            hoverColor: Color(0xFF6A1B9A),
            hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
            contentPadding: EdgeInsets.all(15.0),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                color: Color(0xFF6A1B9A)),
              borderRadius: BorderRadius.circular(50.0),),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(50.0),),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6A1B9A),),
              borderRadius: BorderRadius.circular(50.0),
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
            ElevatedButton(onPressed: () {
              log(_formKey.currentState!.toString());
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                submitForm(musteriid.text,
                    selectedhemofili?.id??"",
                    selectedseker?.id??"",
                    selectedhamile?.id??"",
                    selectedameliyat?.id??"",
                    selectedalerji?.id??"",
                    selectedalkol?.id??"",
                    selectedregl?.id??"",
                    selecteddoku?.id??"",
                    selectedilac?.id??"",
                    selectedkemoterapi?.id??"",
                    selecteduygulama?.id??"",
                    eksaglik.text,
                    selectedcilttip?.id??"",
                    context);
              }
            },
              child: Text('Formu Kaydet'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  minimumSize: Size(90, 40)
              ),
            ),
          ],
        )
      ],
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


}Future<void> submitForm(String musteri_id,String hemofili,String seker,String hamile,String ameliyet,String alerji,String alkol,String regl,String doku,String ilac,String kemo,String uygulama,String eksaglik,String cilt,context)async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();


  Map<String,dynamic> formData={
    'hemofili_hastaligi_var':hemofili,
    'seker_hastaligi_var':seker,
    'hamile':hamile,
    'alerji_var':alerji,
    'yakin_zamanda_ameliyat_gecirildi':ameliyet,
    'alkol_alimi_yapildi':alkol,
    'regl_doneminde':regl,
    'deri_yumusak_doku_hastaligi_var':doku,
    'surekli_kullanilan_ilac_Var':ilac,
    'kemoterapi_goruyor':kemo,
    'daha_once_uygulama_yaptirildi':uygulama,
    'ek_saglik_sorunu':eksaglik,
    'cilt_tipi':cilt,
    'musteri_id':musteri_id


  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/saglikbilgilerigir'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  log('Response status: ${response.statusCode}');
  log('Response body: ${response.body}');

  if (response.statusCode == 200) {
    log('müşteri ekleme : '+response.body);
    if (response.body.isNotEmpty) {
      log('Response body: ${response.body}');
    } else {
      log('Response body is empty');
    }
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Güncelleme Başarılı '),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bilgiler değiştirilirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
      ),
    );
    debugPrint('Error: ${response.body}');
  }
}
