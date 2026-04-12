import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_model_list/drop_down/model.dart';
import 'package:dropdown_model_list/drop_down/search_drop_list.dart';
import 'package:dropdown_model_list/drop_down/select_drop_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Backend/backend.dart';
import '../../../../Models/musteri_danisanlar.dart';
import '../../../../Models/musteridanisanreferans.dart';
import 'musteriliste.dart';



class MusteriDuzenle extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const MusteriDuzenle({Key? key,required this.md,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _MusteriDuzenleState createState() => _MusteriDuzenleState();
}


class _MusteriDuzenleState extends State<MusteriDuzenle> {
  final _formKey = GlobalKey<FormState>();

  late String seciliisletme;
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  late TextEditingController musteriid;
  late TextEditingController musteriadi;
  late TextEditingController musteritelefon;
  late TextEditingController musteritarih;
  late TextEditingController musteriemail;
  late TextEditingController musterinotlar;
  late TextEditingController cinsiyet;
  final phoneMask = MaskTextInputFormatter(
    mask: '0### ### ## ##',
    filter: { "#": RegExp(r'[0-9]') },
  );

  String _selectedGender = '';
  final List<Referans> musterireferans = [
    Referans(id: " ", referans: "Yok"),
    Referans(id: "1", referans: "İnternet"),
    Referans(id: "2", referans: "Reklam"),
    Referans(id: "3", referans: "Instagram"),
    Referans(id: "4", referans: "Facebook"),
    Referans(id: "5", referans: "Tanıdık")


  ];
  Referans? selectedmusterireferans;
  final TextEditingController musterireferanscontroller = TextEditingController();
  void initState() {
    super.initState();

    if (widget.md.cinsiyet == '0') {
      _selectedGender = 'kadin';
    } else if (widget.md.cinsiyet == '1') {
      _selectedGender = 'erkek';
    }

    musteriid=TextEditingController(text:widget.md.id);
    musteriadi=TextEditingController(text:widget.md.name != 'null' ? widget.md.name : '');
    musteritelefon=TextEditingController(text:widget.md.cep_telefon != 'null' ? '0'+widget.md.cep_telefon : '');
    musteritarih=TextEditingController(text:widget.md.dogum_tarihi != 'null' ? widget.md.dogum_tarihi : '');
    musteriemail=TextEditingController(text:widget.md.eposta != 'null' ? widget.md.eposta : '');
    musterinotlar=TextEditingController(text:widget.md.ozel_notlar!= 'null' ? widget.md.ozel_notlar : '');
    selectedmusterireferans = musterireferans.firstWhere(
          (item) => item.id == widget.md.musteri_tipi,
      orElse: () => musterireferans.first, // return the first element if no match
    );

    initialize();
  }
  Future<void> initialize() async
  {
    seciliisletme = (await secilisalonid())!;

  }

  @override
  Widget build(BuildContext context) {

    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Hide the keyboard
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: new AppBar(
            title: const Text('Müşteri Düzenle',style: TextStyle(color: Colors.black),),
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.clear_rounded, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),


          ),

          body: SafeArea(
            child: SingleChildScrollView(
              reverse: true,
              child: Container(
                margin: const EdgeInsets.all(15.0),
                child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidate,
                    child: formUI()
                ),
              ),
            ),
          ),

        ),
      ),
    );
  }
  Widget formUI(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Ad Soyad',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        TextFormField(

          keyboardType: TextInputType.text,
          controller: musteriadi,
          onSaved: (value) {

            musteriadi.text = value!;
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bu alan zorunludur!';
            }
            return null;
          },

          decoration: InputDecoration(

            focusColor:Color(0xFF6A1B9A) ,
            hoverColor: Color(0xFF6A1B9A) ,
            hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
            contentPadding:  EdgeInsets.all(15.0),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(50.0),),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(50.0),),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(50.0),
            ),
          ),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Telefon Numarası',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        TextFormField(

          keyboardType: TextInputType.phone,
          inputFormatters: [phoneMask],
          controller: musteritelefon,
          onSaved: (value) {

            musteritelefon.text = value!;
          },
          onTap: () {
            // Cursor daima +90'ın sonuna gelsin
            if (musteritelefon.text.length < 2) {
              musteritelefon.text = "0";
            }
            musteritelefon.selection = TextSelection.fromPosition(
              TextPosition(offset: musteritelefon.text.length),
            );
          },

          onChanged: (value) {
            // Kullanıcı +90 kısmını silmeye çalışırsa düzelt
            if (!value.startsWith("0")) {
              musteritelefon.text = "0";
              musteritelefon.selection = TextSelection.fromPosition(
                TextPosition(offset: musteritelefon.text.length),
              );
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bu alan zorunludur!';
            }
            return null;
          },

          decoration: InputDecoration(

            focusColor:Color(0xFF6A1B9A) ,
            hoverColor: Color(0xFF6A1B9A) ,
            hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
            contentPadding:  EdgeInsets.all(15.0),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(50.0),),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(50.0),),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(50.0),
            ),
          ),
        ),
        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('E-posta',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        TextFormField(

          keyboardType: TextInputType.emailAddress,
          controller: musteriemail,
          onSaved: (value) {

            musteriemail.text = value!;

          },



          decoration: InputDecoration(

            focusColor:Color(0xFF6A1B9A) ,
            hoverColor: Color(0xFF6A1B9A) ,
            hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
            contentPadding:  EdgeInsets.all(15.0),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                color: Color(0xFF6A1B9A)),borderRadius: BorderRadius.circular(50.0),),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(50.0),),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6A1B9A),), borderRadius: BorderRadius.circular(50.0),
            ),
          ),
        ),

        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Doğum Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        Container(
          height: 40,
          padding: EdgeInsets.only(left:20,right: 20),
          child: TextFormField(

            controller:musteritarih,
            enabled:true,
            onSaved: (value) {
              musteritarih.text=value!;
            },

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
                  musteritarih.text =
                      formattedDate; //set output date to TextField value.
                });
              } else {}
            },
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
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Referans',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        const SizedBox(
          height: 10.0,
        ),
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
                items: musterireferans
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
                value: selectedmusterireferans,
                onChanged: (value) {
                  setState(() {
                    selectedmusterireferans = value;
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
                    musterireferanscontroller.clear();
                  }
                },

              )),
        ),
        const SizedBox(
          height: 10.0,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text('Notlar',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 10,),
        TextFormField(

          keyboardType: TextInputType.text,

          controller: musterinotlar,
          onSaved: (value) {

            musterinotlar.text = value!;
          },
          maxLines: 3,



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

        const SizedBox(
          height: 20.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: (){
              log(_formKey.currentState!.toString());
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                submitForm(widget.isletmebilgi,musteriid.text,seciliisletme,musteriadi.text,musteritelefon.text,musteriemail.text,musteritarih.text,_selectedGender == 'kadin' ? '0' : '1',selectedmusterireferans?.id ?? "",musterinotlar.text,context);
              }
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
  Future<void> submitForm(dynamic isletmebilgi,String musteri_id,String salonid,String musteriad,String telefon,String e_posta,String dogumtarihi,String cinsiyet,String referans,String notlar,context)async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    log('müşteri adı : '+musteriad);

    Map<String,dynamic> formData={
      'ad_soyad':musteriad,
      'telefon':telefon,
      'email':e_posta,
      'dogum_tarihi':dogumtarihi,
      'cinsiyet':cinsiyet,
      'musteri_tipi':referans,
      'ozel_notlar':notlar,
      'musteri_id':musteri_id


    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteriekleguncelle/'+salonid.toString()),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );
    log('Response status: ${response.statusCode}');
    log('Response body: ${response.body}');
    log(dogumtarihi);
    if (response.statusCode == 200) {
      log('müşteri ekleme : '+response.body);
      if (response.body.isNotEmpty) {
        log('Response body: ${response.body}');
      } else {
        log('Response body is empty');
      }
      Navigator.of(context).pop();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MusteriListesi(kullanicirolu: widget.kullanicirolu ,isletmebilgi:isletmebilgi)),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müşteri eklenirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }

}
