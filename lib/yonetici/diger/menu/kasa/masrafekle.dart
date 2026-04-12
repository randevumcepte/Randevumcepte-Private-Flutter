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
import 'package:randevu_sistem/Models/odemeturu.dart';

import '../../../../Models/masrafkategorileri.dart';
import '../../../../Models/personel.dart';



class MasrafEkle extends StatefulWidget {
    final List<MasrafKategorisi> masrafkategorileri;
    final List<Personel> personeller;
    final GiderDataSource giderDataSource;
    final String seciliisletme;
    final dynamic isletmebilgi;
    const MasrafEkle({Key? key,required this.personeller,required this.masrafkategorileri,required this.giderDataSource,required this.seciliisletme,required this.isletmebilgi}) : super(key: key);

    @override
    _MasrafState createState() => _MasrafState();
}

class _MasrafState extends State<MasrafEkle> {

    Personel? selectedharcayan;
    final TextEditingController masrafharcayancontroller = TextEditingController();
    final List<OdemeTuru> masrafodemeyontem = [
        OdemeTuru(id: '1', odeme_turu: 'Nakit'),
        OdemeTuru(id: '2', odeme_turu: 'Kredi/Banka Kartı'),
        OdemeTuru(id: '3', odeme_turu: 'Havale/EFT'),


    ];
    OdemeTuru? selectedmasrafodemeyontem;

    MasrafKategorisi? selectedmasrafkategori;

    final TextEditingController masrafkategoricontroller = TextEditingController();

    TextEditingController masrafodemeyontemcontroller = TextEditingController();
    TextEditingController masraftarih = TextEditingController();
    TextEditingController tutar = TextEditingController();
    TextEditingController aciklama = TextEditingController();

    @override
    void initState() {
        masraftarih.text = ""; //set the initial value of text field
        super.initState();
    }
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    AutovalidateMode _autoValidate = AutovalidateMode.disabled;

    @override
    Widget build(BuildContext context) {

        return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
                appBar: new AppBar(
                    title: const Text('Yeni Masraf',style: TextStyle(color: Colors.black),),
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
                Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('Tarih',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                ),
                SizedBox(height: 10,),
                Container(
                    height: 40,

                    child: TextFormField(

                        controller: masraftarih,
                        onSaved: (value){
                            if(value!=null)
                                masraftarih.text = value;
                        },
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
                                    masraftarih.text =
                                        formattedDate; //set output date to TextField value.
                                });
                            } else {}
                        },
                    ),

                ),
                SizedBox(height: 10,),
                Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('Tutar (₺)',style: TextStyle( fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                ),
                SizedBox(height: 10,),
                Container(
                    height: 40,
                    child: TextFormField(

                        keyboardType: TextInputType.number,
                        controller: tutar,
                        onSaved: (value){
                            if(value!=null)
                                tutar.text = value;
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
                    child: Text('Masraf Kategorisi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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

                        child: DropdownButton2<MasrafKategorisi>(

                            isExpanded: true,
                            hint: Text(
                                'Seç',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).hintColor,
                                ),
                            ),
                            items: widget.masrafkategorileri
                                .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                    item.kategori,
                                    style: const TextStyle(
                                        fontSize: 14,
                                    ),
                                ),
                            ))
                                .toList(),
                            value: selectedmasrafkategori,
                            onChanged: (value) {
                                setState(() {
                                    selectedmasrafkategori = value;


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
                                searchController: masrafkategoricontroller,
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
                                        controller: masrafkategoricontroller,
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
                                    masrafkategoricontroller.clear();
                                }
                            },

                        )),
                ),
                SizedBox(height: 10,),
                Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('Ödeme Yöntemi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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

                        child: DropdownButton2<OdemeTuru>(

                            isExpanded: true,
                            hint: Text(
                                'Seç',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).hintColor,
                                ),
                            ),
                            items: masrafodemeyontem
                                .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                    item.odeme_turu,
                                    style: const TextStyle(
                                        fontSize: 14,
                                    ),
                                ),
                            ))
                                .toList(),
                            value: selectedmasrafodemeyontem,
                            onChanged: (value) {
                                setState(() {
                                    selectedmasrafodemeyontem = value;
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
                                searchController: masrafodemeyontemcontroller,
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
                                        controller: masrafodemeyontemcontroller,
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
                                    masrafodemeyontemcontroller.clear();
                                }
                            },

                        )),
                ),
                SizedBox(height: 10,),
                Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('Harcayan',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                            items: widget.personeller
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
                            value: selectedharcayan,
                            onChanged: (value) {
                                setState(() {
                                    selectedharcayan = value;
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
                                searchController: masrafharcayancontroller,
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
                                        controller: masrafharcayancontroller,
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
                                    masrafharcayancontroller.clear();
                                }
                            },

                        )),
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
                        controller: aciklama,
                        onSaved: (value){
                            if(value!=null)
                                aciklama.text = value;
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
                ),
                SizedBox(height: 10,),
                const SizedBox(
                    height: 20.0,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        ElevatedButton(onPressed: (){
                            widget.giderDataSource.masrafEkleGuncelle('', tutar.text, selectedmasrafkategori!, aciklama.text, selectedmasrafodemeyontem!, selectedharcayan!, context,widget.seciliisletme ,masraftarih.text);


                        },
                            child: Text('Kaydet'),
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



}