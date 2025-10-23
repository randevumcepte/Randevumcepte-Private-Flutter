import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Frontend/sfdatatable.dart';
import '../../../../Models/ajanda.dart';
import '../../../../Models/hatirlatma_saat.dart';
import 'ajanda.dart';

class AjandaDuzenle extends StatefulWidget {
  final Ajanda notdetayi;
  final AjandaDataSource ajandaDataSource;
  final dynamic isletmebilgi;
  AjandaDuzenle({Key? key, required this.notdetayi,required this.ajandaDataSource,required this.isletmebilgi}) : super(key: key);

  @override
  _AjandaDuzenleState createState() => _AjandaDuzenleState();
}
class _AjandaDuzenleState extends State<AjandaDuzenle> {
  
  Hatirlatma? selectedhatirlatmasaat;
  final TextEditingController _setBaslik=TextEditingController();
  final TextEditingController _setTarih=TextEditingController();
  final TextEditingController _setSaat=TextEditingController();
  final TextEditingController _setHatirlatmaSaati=TextEditingController();
  final TextEditingController _setHatirlatma=TextEditingController();
  final TextEditingController _setIcerik=TextEditingController();
  final TextEditingController _setAjandaId=TextEditingController();
  TextEditingController sablonController = TextEditingController();
  String? selectedsablon;
  final List<Hatirlatma> sablon = [
    Hatirlatma(id: "1", hatirlatma: "1 saat"),
    Hatirlatma(id: "2", hatirlatma: "2 saat"),
    Hatirlatma(id: "3", hatirlatma: "3 saat"),
    Hatirlatma(id: "4", hatirlatma: "4 saat"),
    Hatirlatma(id: "5", hatirlatma: "5 saat"),


  ];
  void initState() {

    super.initState();
    initialize();
    

  }
Future<void> initialize() async{
  // Initialize the TextEditingController with the initial value from myClass
  _setBaslik.text = widget.notdetayi.title != "null" ? widget.notdetayi.title : "" ;
  _setTarih.text =widget.notdetayi.ajandatarih;
  _setSaat.text =widget.notdetayi.ajandasaat;
  _setHatirlatmaSaati.text = widget.notdetayi.hatirlatma_saat; // Ensure it's not empty
  _setHatirlatma.text = widget.notdetayi.hatirlatma;
  selectedhatirlatmasaat=sablon.firstWhere((item) => item.id==widget.notdetayi.hatirlatma_saat);
  _setIcerik.text =widget.notdetayi.description;
  _setAjandaId.text =widget.notdetayi.id;
  print('Initialized reminder time: ${_setHatirlatmaSaati.text}');
}
  bool light = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  String _ajandaid='';
  String _baslik = '';
  String _tarih = '';
  String _saat = '';
  String _kac_saat_once = '';
  bool _hatirlatma = false;
  String _icerik = '';
  List<String> items = [ ];

  List<String> selectedItems = [];

  void toggleItemSelection(String item) {
    if (selectedItems.contains(item)) {
      selectedItems.remove(item);
    } else {
      selectedItems.add(item);
    }
  }







  TextEditingController dateInput = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  TextEditingController _controller = TextEditingController();


  TextEditingController _contentController = TextEditingController();
  String? _selectedItem='1';
  @override
  Widget build(BuildContext context) {

    print('Current _kac_saat_once value: $_setHatirlatmaSaati');
    print('Available sablon values: ${sablon.join(', ')}');
// Default value
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },// Hide the keyboard
        child:Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title:  const Text('Notu Düzenle',style: TextStyle(color: Colors.black),),

              leading: IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.black),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AjandaNotlar(isletmebilgi: widget.isletmebilgi,)),
                    );
                  }
              ),
              toolbarHeight: 60,
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
              backgroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              reverse: true,
              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20,),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text('Başlık',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                    ),

                    SizedBox(height: 10,),

                    Container(
                      height: 40,
                      padding: const EdgeInsets.only(left: 20.0,right: 20),

                      child: TextFormField(

                        controller: _setBaslik,
                        onSaved: (value) {
                          _setBaslik.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen not başlığını yazınız!';
                          }
                          return null;
                        },
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
                    SizedBox(height: 10,),
                    Row(
                      children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text('Tarih',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                            ),
                            SizedBox(height: 10,),
                            Container(
                              height: 40,
                              padding: EdgeInsets.only(left:20,right: 20),
                              child: TextFormField(
                                onSaved: (value) {
                                  _setTarih.text = value!;
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Lütfen tarihi yazınız!';
                                  }
                                  return null;
                                },
                                controller: _setTarih,
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

                                      _setTarih.text = formattedDate; //set output date to TextField value.
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
                              child: Text('Saat',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                            ),
                            SizedBox(height: 10,),
                            Container(
                              height: 40,
                              padding: EdgeInsets.only(left:20,right: 20),
                              child: TextFormField(
                                controller: _setSaat,
                                onSaved: (value) {
                                  _setSaat.text = value!;
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
                                      _setSaat.text = _selectedTime.format(context);
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

                    Row(
                      children: [
                        Expanded( child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text('Kaç saat önce hatırlatılsın',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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
                                borderRadius: BorderRadius.circular(10), //border corner radius

                                //you can set more BoxShadow() here

                              ),
                              child: DropdownButtonHideUnderline(

                                  child: DropdownButton2<Hatirlatma>(
                                    isExpanded: true,
                                    hint: Text(
                                      'Seç',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                    items: sablon
                                        .map((item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item.hatirlatma,
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ))
                                        .toList(),
                                    value: selectedhatirlatmasaat,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedhatirlatmasaat = value;
                                        // Ensure it updates the TextEditingController
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

                                    onMenuStateChange: (isOpen) {
                                      if (!isOpen) {
                                        sablonController.clear();
                                      }
                                    },
                                  )
                              ),
                            ),
                          ],
                        )
                        ),
                        Expanded( child:
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text('Hatırlatma ',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                            ),

                            Container(padding: const EdgeInsets.only(left: 50.0),
                              width: 120,
                              height: 50,
                              child:  Switch(
                                // This bool value toggles the switch.
                                //value: stringToBool(_setHatirlatma.text),
                                value: stringToBool(_setHatirlatma.text),
                                activeColor: Colors.purple[800],
                                onChanged: (bool value) {
                                  // This is called when the user toggles the switch.

                                  setState(() {
                                    light = value;
                                    _hatirlatma = value;
                                    if(value==true)
                                      _setHatirlatma.text = "1";
                                    else
                                      _setHatirlatma.text = "0";
                                  });
                                },
                              ),
                            ),

                          ],
                        )


                        )
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text('İçerik',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 10,),
                    Container(

                      padding: const EdgeInsets.only(left: 20.0,right: 20),
                      child: TextFormField(
                        controller: _setIcerik,
                        keyboardType: TextInputType.text,
                        onSaved: (value) {
                          _setIcerik.text = value!;

                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen notunuzu yazınız!';
                          }
                          return null;
                        },
                        maxLines: 6,
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



                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        ElevatedButton(onPressed: (){



                          widget.ajandaDataSource.ajandaEkleGuncelle(widget.notdetayi.id.toString(),_setBaslik.text,_setIcerik.text,_setTarih.text,_setSaat.text,
                              selectedhatirlatmasaat?.id ?? "",_hatirlatma,context);

                          print('ID: ${_setAjandaId.text}');
                          print('Reminder Time: ${_setHatirlatmaSaati.text}');



                        },
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline),
                              Text(' Kaydet'),
                            ],
                          ),
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
              ),
            )
        )
    );
  }

}

bool stringToBool(String str) {
  if(str=="1")
    return true;
  else
    return false;
}