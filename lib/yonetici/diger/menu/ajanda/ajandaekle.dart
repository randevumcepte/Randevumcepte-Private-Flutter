import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../../../Frontend/yukseltbutonu.dart';
import 'ajanda.dart';
class AjandaEkle extends StatefulWidget {
  final AjandaDataSource ajandaDataSource;
  final dynamic isletmebilgi;
  AjandaEkle({Key? key,required this.ajandaDataSource,required this.isletmebilgi}) : super(key: key);
  @override
  _AjandaEkleState createState() => _AjandaEkleState();
}
class _AjandaEkleState extends State<AjandaEkle> {
  bool light = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  String _baslik = '';
  String _tarih = '';
  String _saat = '';
  String _kac_saat_once = '2';
  bool _hatirlatma = true;
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
  bool selectAll = false;
  TextEditingController searchController = TextEditingController();
  String buttonLabel = 'Katılımcı Seç';
  void updateButtonLabel() {
    setState(() {
      if (selectedItems.isEmpty) {
        buttonLabel = 'Katılımcı Seç';
      } else if (selectedItems.length <= items.length) {
        buttonLabel = 'Katılımcı Sayısı: ${selectedItems.length} ';
      }
      else {
        buttonLabel = 'Katılımcı Sayısı: ${selectedItems.length} ';
      }

    });
  }


  final List<String> sablon = [
    '1 saat',
    '2 saat',
    '3 saat',
    '4 saat',
    '5 saat',


  ];

  String? selectedsablon;
  TextEditingController sablonController = TextEditingController();
  TextEditingController dateInput = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  TextEditingController _controller = TextEditingController();
  String? _selectedItem='2';

  TextEditingController _contentController = TextEditingController();
  TextEditingController _contentController2 = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus(); // Hide the keyboard
        },
        child: new Scaffold(
          resizeToAvoidBottomInset: false,

            appBar: AppBar(
              title:  const Text('Yeni Not Ekle',style: TextStyle(color: Colors.black),),

              leading: IconButton(
                icon: Icon(Icons.clear_rounded, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AjandaNotlar(isletmebilgi: widget.isletmebilgi,)),
                  );
                },
              ),
              toolbarHeight: 60,
              actions: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 100, // <-- Your width
                    child: YukseltButonu(isletme_bilgi:widget.isletmebilgi)
                  ),
                ),


              ],
              backgroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
           reverse: true,
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
                      controller: _contentController2,
                      onChanged: (value) {
                        _baslik = value!;
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
                              onChanged: (value) {
                                _tarih = value!;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen tarihi yazınız!';
                                }
                                return null;
                              },
                              controller: dateInput,
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
                                    _tarih = formattedDate;
                                    dateInput.text = formattedDate;
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
                              controller: _controller,
                              onChanged : (value) {
                                _saat = value!;
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
                                    _saat = _selectedTime.format(context);
                                    _controller.text = _selectedTime.format(context);

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
                                child: DropdownButton<String>( // DropdownButton<String?>
                                  value: _selectedItem,
                                  onChanged: (String? newValue) { // onChanged: (String? newValue)
                                    setState(() {
                                      _selectedItem = newValue;
                                      _kac_saat_once = newValue!;
                                    });
                                  },
                                  items: <String>[
                                    '1',
                                    '2',
                                    '3',
                                    '4',
                                    '5',
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
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
                              value: light,
                              activeColor: Colors.purple[800],

                              onChanged: (bool value) {
                                // This is called when the user toggles the switch.

                                setState(() {
                                  light = value;
                                  _hatirlatma = value;
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
                      controller: _contentController,
                      keyboardType: TextInputType.text,
                      onChanged: (value) {
                        _icerik = value!;
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

                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          print('Başlık: $_baslik');
                          print('Tarih: $_tarih');
                          print('Saat: $_saat');
                          print('Hatırlatma: $_hatirlatma');
                          print('Kaç saat önce: $_kac_saat_once');

                          _isLoading ? null : widget.ajandaDataSource.ajandaEkleGuncelle('',_baslik,_icerik,_tarih,_saat,_kac_saat_once,_hatirlatma,context);
                        };

                        final Map<String, dynamic> data = {
                          'text': dateInput.text,
                          'text2': _controller.text,
                          'text3': _contentController2.text,
                          'text4': _contentController.text,
                          'dropdownValue': selectedsablon,

                        };

                      },
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline),
                            Text(' Kaydet'),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor:Colors.white,
                            minimumSize: Size(90, 40)
                        ),

                      ),

                    ],
                  ),
                  Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
                ],
              ),
            )
        ),
    );

  }

}
