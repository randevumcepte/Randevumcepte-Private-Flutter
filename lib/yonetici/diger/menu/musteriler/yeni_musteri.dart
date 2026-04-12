import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_model_list/drop_down/model.dart';
import 'package:dropdown_model_list/drop_down/search_drop_list.dart';
import 'package:dropdown_model_list/drop_down/select_drop_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Backend/backend.dart';
import '../../../../Frontend/progressloading.dart';
import '../../../../Models/musteri_danisanlar.dart';
import '../../../../Models/musteridanisanreferans.dart';
import 'package:http/http.dart' as http;

import '../../../../Models/user.dart';
import 'musteriliste.dart';



class Yenimusteri extends StatefulWidget {
    final dynamic isletmebilgi;
    final String telefon;
    final String isim;
    final bool sadeceekranikapat;
    final int kullanicirolu;
    const Yenimusteri({Key? key,required this.kullanicirolu, required this.isletmebilgi,required this.telefon,required this.sadeceekranikapat, required this.isim}) : super(key: key);

    @override
    _YenimusteriState createState() => _YenimusteriState();
}


class _YenimusteriState extends State<Yenimusteri> {
    final phoneMask = MaskTextInputFormatter(
        mask: '0### ### ## ##',
        filter: { "#": RegExp(r'[0-9]') },
    );
    final List<Referans> musterireferans = [
        Referans(id: "", referans: "Yok"),
        Referans(id: "1", referans: "İnternet"),
        Referans(id: "2", referans: "Reklam"),
        Referans(id: "3", referans: "Instagram"),
        Referans(id: "4", referans: "Facebook"),
        Referans(id: "5", referans: "Tanıdık")


    ];
    late String seciliisletme;

    Referans? selectedmusterireferans;
    final TextEditingController musterireferanscontroller = TextEditingController();
    TextEditingController adsoyad = TextEditingController();
    TextEditingController telefon = TextEditingController();
    TextEditingController dogumtarihi = TextEditingController();
    TextEditingController eposta = TextEditingController();
    TextEditingController notlar = TextEditingController();
    String selectedcinsiyet = '';
    bool yukleniyor=true;
    @override
    void initState() {
        dogumtarihi.text = ""; //set the initial value of text field
        telefon.text = "0";
        super.initState();
        initialize();
    }
    final _formKey = GlobalKey<FormState>();

    Future<void> initialize() async
    {
        seciliisletme = (await secilisalonid())!;

        setState(() {

            telefon.text = widget.telefon ?? "";
            adsoyad.text = widget.isim ?? "";
            yukleniyor = false;
            selectedmusterireferans = musterireferans.firstWhere((item) => item.id == "");
        });

    }

    @override
    Widget build(BuildContext context) {

        return
           Scaffold(
            resizeToAvoidBottomInset: false,
                appBar: new AppBar(
                    title: const Text('Yeni Müşteri/Danışan',style: TextStyle(color: Colors.black),),
                    backgroundColor: Colors.white,
                    leading: IconButton(
                        icon: Icon(Icons.clear_rounded, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                    ),


                ),
                
                body: yukleniyor ? Center(child: CircularProgressIndicator(),) : GestureDetector(
                    onTap: () {
                        FocusScope.of(context).unfocus(); // Hide the keyboard
                    },
                    child: SingleChildScrollView(

                        child: Container(
                            margin: const EdgeInsets.all(15.0),
                            child: Form(
                                key: _formKey,
                                child:    Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                        Padding(
                                            padding: const EdgeInsets.only(left: 5.0),
                                            child: Text('Ad Soyad',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                        ),
                                        SizedBox(height: 10,),
                                        Container(
                                            height: 40,
                                            child: TextFormField(

                                                keyboardType: TextInputType.text,
                                                controller: adsoyad,
                                                onSaved: (value){
                                                    adsoyad.text=value!;
                                                },

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
                                                inputFormatters: [phoneMask],
                                                keyboardType: TextInputType.phone,

                                                controller: telefon,
                                                onSaved: (value){
                                                    telefon.text=value!;
                                                },
                                                onTap: () {
                                                    // Cursor daima +90'ın sonuna gelsin
                                                    if (telefon.text.length < 2) {
                                                        telefon.text = "0";
                                                    }
                                                    telefon.selection = TextSelection.fromPosition(
                                                        TextPosition(offset: telefon.text.length),
                                                    );
                                                },

                                                onChanged: (value) {
                                                    // Kullanıcı +90 kısmını silmeye çalışırsa düzelt
                                                    if (!value.startsWith("0")) {
                                                        telefon.text = "0";
                                                        telefon.selection = TextSelection.fromPosition(
                                                            TextPosition(offset: telefon.text.length),
                                                        );
                                                    }
                                                },
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
                                            child: Text('E-posta',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                        ),
                                        SizedBox(height: 10,),
                                        Container(
                                            height: 40,
                                            child: TextFormField(

                                                keyboardType: TextInputType.emailAddress,

                                                controller: eposta,
                                                onSaved: (value){

                                                    eposta.text = value!;
                                                },

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
                                            child: Text('Doğum Tarihi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                        ),
                                        SizedBox(height: 10,),
                                        Container(height: 40,
                                            child: TextFormField(
                                                controller: dogumtarihi,
                                                enabled:true,
                                                onSaved: (value){

                                                    dogumtarihi.text = value!;
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
                                                            dogumtarihi.text =
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
                                                            value: '0',
                                                            groupValue: selectedcinsiyet,
                                                            activeColor: Colors.purple[800],
                                                            onChanged: (value) {
                                                                setState(() {
                                                                    selectedcinsiyet = value!;
                                                                });
                                                            },
                                                        ),
                                                        title: const Text('Kadın'),
                                                    ),
                                                ),
                                                Expanded(
                                                    child: ListTile(
                                                        leading: Radio<String>(
                                                            value: '1',
                                                            groupValue: selectedcinsiyet,
                                                            activeColor: Colors.purple[800],
                                                            onChanged: (value) {
                                                                setState(() {
                                                                    selectedcinsiyet = value!;
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
                                        Container(
                                            height: 40,
                                            child: TextFormField(

                                                keyboardType: TextInputType.text,
                                                controller: notlar,

                                                onSaved: (value){

                                                    notlar.text = value!;
                                                },

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

                                        const SizedBox(
                                            height: 20.0,
                                        ),
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                                ElevatedButton(onPressed: () async{

                                                    log(_formKey.currentState!.toString());
                                                    if (_formKey.currentState!.validate()) {
                                                        _formKey.currentState!.save();
                                                        MusteriDanisan yenimusteridanisan = await submitForm(widget.isletmebilgi,seciliisletme,adsoyad.text,telefon.text,eposta.text,dogumtarihi.text,selectedcinsiyet,selectedmusterireferans?.id ?? "",notlar.text,context);
                                                        Navigator.of(context).pop(yenimusteridanisan);

                                                        if(!widget.sadeceekranikapat)
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(builder: (context) => MusteriListesi(kullanicirolu: widget.kullanicirolu, isletmebilgi:widget.isletmebilgi)),
                                                            );

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
                                        )
                                    ],
                                )
                    ),
                        ),
                    ),
                ),
            );

    }
    Future<MusteriDanisan> submitForm(dynamic isletmebilgisi,String salonid,String musteriad,String telefon,String e_posta,String dogumtarihi,String cinsiyet,String referans,String notlar,context)async {

        showProgressLoading(context);


        Map<String,dynamic> formData={
            'ad_soyad':musteriad,
            'telefon':telefon,
            'email':e_posta,
            'dogum_tarihi':dogumtarihi,
            'cinsiyet':cinsiyet,
            'musteri_tipi':referans,
            'ozel_notlar':notlar


        };

        final response = await http.post(
            Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteriekleguncelle/'+salonid.toString()),

            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(formData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
            Navigator.of(context,rootNavigator: true).pop();

            return  MusteriDanisan.fromJson( json.decode(response.body));

        } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Müşteri eklenirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
                ),
            );
            throw Exception('Bir hata oluştu');
        }
    }


}
