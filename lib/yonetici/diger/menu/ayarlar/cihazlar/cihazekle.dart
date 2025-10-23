
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import '../../../../../Backend/backend.dart';
import '../../../../../Frontend/sfdatatable.dart';
import '../personeller/oglen_arasi.dart';

class CihazEkle extends StatefulWidget {
  final CihazDataSource cihazdatasource;
  final dynamic isletmebilgi;
  const CihazEkle({Key? key, required this.cihazdatasource,required this.isletmebilgi}) : super(key: key);

  @override
  _CihazEkleState createState() => _CihazEkleState();
}

class _CihazEkleState extends State<CihazEkle> {
  TextEditingController cihazadi = TextEditingController();

  late String seciliisletme;
  TextEditingController baslangicsaati1 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati2 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati3 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati4 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati5 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati6 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati7 = TextEditingController(text:"00:00");
  TextEditingController bitissaati1 = TextEditingController(text:"00:00");
  TextEditingController bitissaati2 = TextEditingController(text:"00:00");
  TextEditingController bitissaati3 = TextEditingController(text:"00:00");
  TextEditingController bitissaati4 = TextEditingController(text:"00:00");
  TextEditingController bitissaati5 = TextEditingController(text:"00:00");
  TextEditingController bitissaati6 = TextEditingController(text:"00:00");
  TextEditingController bitissaati7 = TextEditingController(text:"00:00");
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool? isChecked1;
  bool? isChecked2;
  bool? isChecked3;
  bool? isChecked4;
  bool? isChecked5;
  bool? isChecked6;
  bool? isChecked7;
  TextEditingController baslangicsaati8 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati9 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati10 = TextEditingController(text:"00:00");
  TextEditingController baslangicsaati11= TextEditingController(text:"00:00");
  TextEditingController baslangicsaati12= TextEditingController(text:"00:00");
  TextEditingController baslangicsaati13= TextEditingController(text:"00:00");
  TextEditingController baslangicsaati14= TextEditingController(text:"00:00");
  TextEditingController bitissaati8 = TextEditingController(text:"00:00");
  TextEditingController bitissaati9 = TextEditingController(text:"00:00");
  TextEditingController bitissaati10 = TextEditingController(text:"00:00");
  TextEditingController bitissaati11= TextEditingController(text:"00:00");
  TextEditingController bitissaati12= TextEditingController(text:"00:00");
  TextEditingController bitissaati13= TextEditingController(text:"00:00");
  TextEditingController bitissaati14= TextEditingController(text:"00:00");

  bool? isChecked8;
  bool? isChecked9;
  bool? isChecked10;
  bool? isChecked11;
  bool? isChecked12;
  bool? isChecked13;
  bool? isChecked14;
  final formKey = GlobalKey<FormState>();
  late Map<String,dynamic> calismasaatleri;
  void _fetchData() async {

    seciliisletme = (await secilisalonid())!;





  }


  void initState() {
    super.initState();

    _fetchData();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus(); // Hide the keyboard
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 60,

          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
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
          title: Text("Yeni Cihaz",style: TextStyle(color: Colors.black),),

        ),
        body: SingleChildScrollView( reverse:true,
          padding: EdgeInsets.all(8),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10,),
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text('Cihaz Adı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                ),
                SizedBox(height: 10,),
                Container(

                  height: 40,
                  child: TextFormField(

                    keyboardType: TextInputType.text,

                    controller: cihazadi,
                    onSaved: (value) {
                      cihazadi.text = value!;
                    },


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

                SizedBox(height: 20,),
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text('Çalışma Saatleri',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,

                  children: [

                    Expanded(
                      child:  Row(
                        children: [
                          Checkbox(
                            value: isChecked1 ?? false, // Default to false if isChecked is null
                            onChanged: (bool? value) {
                              setState(() {
                                isChecked1 = value;
                                // Update text fields to zero if checkbox is unchecked

                              });
                            },
                          ),
                          Text('Pazartesi'),
                        ],
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati1,
                        onSaved: (value) {

                          baslangicsaati1.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
                          }
                          return null;
                        },
                        readOnly: true,
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
                              baslangicsaati1.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati1,
                        onSaved: (value) {

                          bitissaati1.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati1.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),
                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked2 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked2 = value;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Salı'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati2,
                        onSaved: (value) {

                          baslangicsaati2.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati2.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati2,
                        onSaved: (value) {

                          bitissaati2.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati2.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),
                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked3 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked3 = value;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Çarşamba'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati3,
                        onSaved: (value) {

                          baslangicsaati3.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati3.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati3,
                        onSaved: (value) {

                          bitissaati3.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati3.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),
                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked4 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked4 = value;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Perşembe'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati4,
                        onSaved: (value) {

                          baslangicsaati4.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati4.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati4,
                        onSaved: (value) {

                          bitissaati4.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati4.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),
                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked5 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked5 = value;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Cuma'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati5,
                        onSaved: (value) {

                          baslangicsaati5.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati5.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati5,
                        onSaved: (value) {

                          bitissaati5.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati5.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),

                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked6 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked6 = value;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Cumartesi'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati6,
                        onSaved: (value) {

                          baslangicsaati6.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati6.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati6,
                        onSaved: (value) {

                          bitissaati6.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati6.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),
                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked7 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked7 = value ?? false;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Pazar'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati7,
                        onSaved: (value) {

                          baslangicsaati7.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati7.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati7,
                        onSaved: (value) {

                          bitissaati7.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati7.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],

                ),
                Divider(),
                SizedBox(height: 10,),
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text('Cihaz Mola Saatleri',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,

                  children: [

                    Expanded(
                      child:  Row(
                        children: [
                          Checkbox(
                            value: isChecked8 ?? false, // Default to false if isChecked is null
                            onChanged: (bool? value) {
                              setState(() {
                                isChecked8 = value;
                                // Update text fields to zero if checkbox is unchecked

                              });
                            },
                          ),
                          Text('Pazartesi'),
                        ],
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati8,
                        onSaved: (value) {

                          baslangicsaati8.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
                          }
                          return null;
                        },
                        readOnly: true,
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
                              baslangicsaati8.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati8,
                        onSaved: (value) {

                          bitissaati8.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati8.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),
                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked9 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked9 = value;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Salı'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati9,
                        onSaved: (value) {

                          baslangicsaati9.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati9.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati9,
                        onSaved: (value) {

                          bitissaati9.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati9.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),
                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked10 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked10 = value;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Çarşamba'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati10,
                        onSaved: (value) {

                          baslangicsaati10.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati10.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati10,
                        onSaved: (value) {

                          bitissaati10.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati10.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),
                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked11 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked11 = value;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Perşembe'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati11,
                        onSaved: (value) {

                          baslangicsaati11.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati11.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati11,
                        onSaved: (value) {

                          bitissaati11.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati11.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),
                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked12 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked12 = value;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Cuma'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati12,
                        onSaved: (value) {

                          baslangicsaati12.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati12.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati12,
                        onSaved: (value) {

                          bitissaati12.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati12.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),

                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked13 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked13 = value;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Cumartesi'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati13,
                        onSaved: (value) {

                          baslangicsaati13.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati13.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati13,
                        onSaved: (value) {

                          bitissaati13.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati13.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],
                ),
                const Divider(  height: 2.0,
                  thickness: 1,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 0),

                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked14 ?? false, // Default to false if isChecked is null
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked14 = value ?? false;
                                  // Update text fields to zero if checkbox is unchecked

                                });
                              },
                            ),
                            Text('Pazar'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: baslangicsaati14,
                        onSaved: (value) {

                          baslangicsaati14.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              baslangicsaati14.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                    Expanded(child:    Container(
                      height: 40,
                      padding: EdgeInsets.only(left:10,right: 10),
                      child: TextFormField(
                        controller: bitissaati14,
                        onSaved: (value) {

                          bitissaati14.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan zorunludur!';
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
                              bitissaati14.text = DateFormat.Hm().format(
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

                          suffixIcon: Icon(Icons.access_time,size: 15,),
                          focusColor:Color(0xFF6A1B9A) ,
                          hoverColor: Color(0xFF6A1B9A) ,
                          hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                          contentPadding:  EdgeInsets.all(5.0),
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
                    ),
                  ],

                ),
                const Divider(
                  height: 2.0,
                  thickness: 1,
                ),

                SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: (){
                      widget.cihazdatasource.cihazekle(  cihazadi.text,
                        seciliisletme, // You need to pass the correct salonId
                        isChecked1, // Checkbox states
                        isChecked2,
                        isChecked3,
                        isChecked4,
                        isChecked5,
                        isChecked6,
                        isChecked7,
                        baslangicsaati1.text, // Start times
                        baslangicsaati2.text,
                        baslangicsaati3.text,
                        baslangicsaati4.text,
                        baslangicsaati5.text,
                        baslangicsaati6.text,
                        baslangicsaati7.text,
                        bitissaati1.text, // End times
                        bitissaati2.text,
                        bitissaati3.text,
                        bitissaati4.text,
                        bitissaati5.text,
                        bitissaati6.text,
                        bitissaati7.text,
                        isChecked8, // Checkbox states
                        isChecked9,
                        isChecked10,
                        isChecked11,
                        isChecked12,
                        isChecked13,
                        isChecked14,
                        baslangicsaati8.text, // Start times
                        baslangicsaati9.text,
                        baslangicsaati10.text,
                        baslangicsaati11.text,
                        baslangicsaati12.text,
                        baslangicsaati13.text,
                        baslangicsaati14.text,
                        bitissaati8.text, // End times
                        bitissaati9.text,
                        bitissaati10.text,
                        bitissaati11.text,
                        bitissaati12.text,
                        bitissaati13.text,
                        bitissaati14.text,
                        context, );

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

          ),
        ),

      ),
    );
  }





}
