import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import '../../../../../Backend/backend.dart';
import '../../../../../Models/isletmecalismasaatleri.dart';
import '../../../../../Models/molasaatleri.dart';
import 'oglen_arasi.dart';

class OglenArasi extends StatefulWidget {
  final dynamic isletmebilgi;
  const OglenArasi({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _OglenArasiState createState() => _OglenArasiState();
}

class _OglenArasiState extends State<OglenArasi> {
  late String seciliisletme;
  TextEditingController baslangicsaati1 = TextEditingController();
  TextEditingController baslangicsaati2 = TextEditingController();
  TextEditingController baslangicsaati3 = TextEditingController();
  TextEditingController baslangicsaati4 = TextEditingController();
  TextEditingController baslangicsaati5 = TextEditingController();
  TextEditingController baslangicsaati6 = TextEditingController();
  TextEditingController baslangicsaati7 = TextEditingController();
  TextEditingController bitissaati1 = TextEditingController();
  TextEditingController bitissaati2 = TextEditingController();
  TextEditingController bitissaati3 = TextEditingController();
  TextEditingController bitissaati4 = TextEditingController();
  TextEditingController bitissaati5 = TextEditingController();
  TextEditingController bitissaati6 = TextEditingController();
  TextEditingController bitissaati7 = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool? isChecked1;
  bool? isChecked2;
  bool? isChecked3;
  bool? isChecked4;
  bool? isChecked5;
  bool? isChecked6;
  bool? isChecked7;
  final formKey = GlobalKey<FormState>();
  late Map<String,dynamic> calismasaatleri;


  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    final List<IsletmeMolaSaatleri> settings = await fetchSalonBreakHoursSettings(seciliisletme);

    setState(() {
      // Initialize all days to default values



      // Map settings to respective days
      for (final setting in settings) {
        final isChecked = setting.mola_var!=0;
        final startTime = setting.baslangic;
        final endTime = setting.bitis;
        debugPrint('Day: ${setting.haftaninGunu}, Start Time: $startTime, End Time: $endTime');

        switch (setting.haftaninGunu) {
          case 1:
            isChecked1 = isChecked;
            baslangicsaati1.text =  setting.baslangic;
            bitissaati1.text = endTime;
            debugPrint('Day: ${setting.haftaninGunu}, Start Time: $baslangicsaati1, End Time: $bitissaati1');
            break;
          case 2:
            isChecked2 = isChecked;
            baslangicsaati2.text = startTime;
            bitissaati2.text = endTime;
            break;
          case 3:
            isChecked3 = isChecked;
            baslangicsaati3.text = startTime;
            bitissaati3.text = endTime;
            break;
          case 4:
            isChecked4 = isChecked;
            baslangicsaati4.text = startTime;
            bitissaati4.text = endTime;
            break;
          case 5:
            isChecked5 = isChecked;
            baslangicsaati5.text = startTime;
            bitissaati5.text = endTime;
            break;
          case 6:
            isChecked6 = isChecked;
            baslangicsaati6.text = startTime;
            bitissaati6.text = endTime;
            break;
          case 7:
            isChecked7 = isChecked;
            baslangicsaati7.text = startTime;
            bitissaati7.text = endTime;
            break;
        }
      }


    });
  }

  @override
  void initState() {
    _selectedTime = TimeOfDay.now();
    super.initState();
    initialize();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 60,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 100, // <-- Your width
              child: YukseltButonu(isletme_bilgi:widget.isletmebilgi)
            ),
          ),
        ],
        title: Text("Mola Saatleri",style: TextStyle(color: Colors.black),),

      ),
      body: Padding( padding: EdgeInsets.all(5),
        child: Form(
          key: formKey,
          child: ListView(


            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
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

              SizedBox(height: 20,),
              ElevatedButton(
                onPressed: () {
                  submitform(
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
                    context, // Pass the context for navigation
                  );
                },
                child: Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  minimumSize: Size(90, 40),
                ),
              ),

            ],
          ),

        ),
      ),

    );
  }


}
Future<void> submitform(String salonId, calisiyor1,  calisiyor2,  calisiyor3,  calisiyor4,  calisiyor5,  calisiyor6,  calisiyor7,
    String baslangic1, String baslangic2, String baslangic3, String baslangic4, String baslangic5, String baslangic6, String baslangic7,
    String bitis1, String bitis2, String bitis3, String bitis4, String bitis5, String bitis6, String bitis7,
    BuildContext context) async{
  final Map<String, dynamic> formData = {
    'isletme_id': salonId,
    'calisiyor1': calisiyor1 == true ? 1 : 0,
    'calisiyor2': calisiyor2 == true ? 1 : 0,
    'calisiyor3': calisiyor3 == true ? 1 : 0,
    'calisiyor4': calisiyor4 == true ? 1 : 0,
    'calisiyor5': calisiyor5 == true ? 1 : 0,
    'calisiyor6': calisiyor6 == true ? 1 : 0,
    'calisiyor7': calisiyor7 == true ? 1 : 0,
    'calismasaatibaslangic1': baslangic1,
    'calismasaatibaslangic2': baslangic2,
    'calismasaatibaslangic3': baslangic3,
    'calismasaatibaslangic4': baslangic4,
    'calismasaatibaslangic5': baslangic5,
    'calismasaatibaslangic6': baslangic6,
    'calismasaatibaslangic7': baslangic7,
    'calismasaatibisis1': bitis1,
    'calismasaatibisis2': bitis2,
    'calismasaatibisis3': bitis3,
    'calismasaatibisis4': bitis4,
    'calismasaatibisis5': bitis5,
    'calismasaatibisis6': bitis6,
    'calismasaatibisis7': bitis7,


  };
  final queryParameters = formData.entries.map((e) => '${e.key}=${e.value}').join('&');

  final response = await http.get(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/mola_saati_guncelle_ekle/$salonId?$queryParameters'),

    headers: {'Content-Type': 'application/json'},


  );
  debugPrint('Response status: ${response.statusCode}');
  debugPrint('Response body: ${response.body}');

  if (response.statusCode == 200) {
    log('etkinlik güncelleme : '+response.body);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Güncelleme Başarılı '),
      ),
    );
  } else {
    debugPrint('Failed to load data. Status code: ${response.statusCode}');
    throw Exception('Failed to load data: ${response.reasonPhrase}');
  }
}