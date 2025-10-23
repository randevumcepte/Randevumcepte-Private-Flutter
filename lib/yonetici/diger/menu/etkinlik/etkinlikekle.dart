import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/sms_taslaklari.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart';
import '../../../../Frontend/sfdatatable.dart';
import 'etkinikler.dart';

class EtkinlikEkle extends StatefulWidget {
    final dynamic isletmebilgi;
    final EtkinlikDataSource etkinlidatasource;
    EtkinlikEkle({Key? key,required this.isletmebilgi, required this.etkinlidatasource}) : super(key: key);
    @override
    _EtkinlikEkleState createState() => _EtkinlikEkleState();
}
class _EtkinlikEkleState extends State<EtkinlikEkle> {

    final _formKey = GlobalKey<FormState>();
    bool light = true;
    bool _isLoading = false;
    List<SmsTaslak> smstaslak = [SmsTaslak(id: '', baslik: 'Veriler getiriliyor. Lütfen bekleyiniz!', icerik: 'icerik')];
    String secyazisi = 'Veriler getiriliyor. Lütfen bekleyiniz!';
    late String seciliisletme;



    void _fetchData() async {

        seciliisletme = (await secilisalonid())!;
        List<MusteriDanisan> musteridanisanlistesi = await musterilistegetir(seciliisletme);
        List<SmsTaslak> smstaslakliste = await smstaslakgetir(seciliisletme);


        setState(() {
            musteridanisan = musteridanisanlistesi;
            smstaslak = smstaslakliste;

        });

    }

    List<MusteriDanisan> musteridanisan = [];


    void initState() {
        super.initState();
setState(() {
    _fetchData();
});


    }



    List<MusteriDanisan> secilenkatilimcilar = [];

    void toggleItemSelection(MusteriDanisan item) {
        if (secilenkatilimcilar.contains(item)) {
            secilenkatilimcilar.remove(item);
        } else {
            secilenkatilimcilar.add(item);
        }
    }
    bool selectAll = false;
    TextEditingController searchController = TextEditingController();
    String buttonLabel = 'Katılımcı Seç';
    void updateButtonLabel() {
        setState(() {
            if (secilenkatilimcilar.isEmpty) {
                buttonLabel = 'Katılımcı Seç';
            } else if (secilenkatilimcilar.length <= musteridanisan.length) {
                buttonLabel = 'Katılımcı Sayısı: ${secilenkatilimcilar.length} ';
            }
            else {
                buttonLabel = 'Katılımcı Sayısı: ${secilenkatilimcilar.length} ';
            }

        });
    }

    void showCheckboxPopup(BuildContext context) {
        showDialog(
            context: context,
            builder: (context) {
                return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                        return AlertDialog(
                            scrollable: true,
                            title: Text('Katılımcıları Seç'),
                            content: SingleChildScrollView(
                                child:Form(

                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                            TextField(
                                                controller: searchController,
                                                decoration: InputDecoration(labelText: 'Ara'),
                                                onChanged: (value) {
                                                    setState(() {});
                                                },
                                            ),
                                            SizedBox(height: 10),
                                            Container(
                                                child: ElevatedButton(
                                                    onPressed: () {
                                                        setState(() {
                                                            if (selectAll) {
                                                                secilenkatilimcilar.clear();
                                                            } else {
                                                                secilenkatilimcilar.addAll(musteridanisan);
                                                            }
                                                            selectAll = !selectAll;
                                                            updateButtonLabel();// Toggle the "Select All" state
                                                        });
                                                    },
                                                    child: Text(selectAll ? 'Tümünü Seçme' : 'Tümünü Seç'),
                                                    style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.purple[800],
                                                        foregroundColor: Colors.white,
                                                        minimumSize: Size(150, 30),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10.0)
                                                        ),
                                                        elevation: 5,

                                                    ),
                                                ),
                                            ),
                                            Container(
                                                height: 200,
                                                width: 300,
                                                child: ListView.builder(
                                                    itemCount: musteridanisan.length,
                                                    shrinkWrap: true,
                                                    itemBuilder: (context, index) {
                                                        final item = musteridanisan[index];
                                                        if (searchController.text.isNotEmpty &&
                                                            !item.name.toLowerCase().contains(
                                                                searchController.text.toLowerCase())) {
                                                            return Container();
                                                        }
                                                        return CheckboxListTile(
                                                            title: Text(item.name),

                                                            activeColor: Colors.purple[800],
                                                            value: (item.name != 'Veriler getiriliyor. Lütfen bekleyiniz!') ? secilenkatilimcilar.contains(item) : secilenkatilimcilar.contains(''),

                                                            onChanged: (bool? value) {
                                                                setState(() {
                                                                    toggleItemSelection(item);
                                                                    updateButtonLabel();
                                                                });
                                                            },
                                                        );
                                                    },
                                                ),
                                            ),
                                        ],
                                    ),
                                ),

                            ),
                            actions: <Widget>[

                                TextButton(
                                    onPressed: () {
                                        // Handle selected items
                                        print('Selected items: $secilenkatilimcilar');
                                        buttonLabel = 'Katılımcı Sayısı: ${secilenkatilimcilar.length}';
                                        Navigator.of(context).pop();
                                    },
                                    child: Text('Ekle & Kapat',style: TextStyle(color: Colors.purple[800]),),
                                ),
                            ],
                        );
                    },
                );
            },
        );
    }


    SmsTaslak? selectedsablon;
    TextEditingController sablonController = TextEditingController();

    TextEditingController _etkinlikmesajicerikController = TextEditingController();
    TextEditingController _etkinlikfiyatController = TextEditingController();
    TimeOfDay _selectedTime = TimeOfDay.now();
    TextEditingController _etkinliksaatController = TextEditingController();


    TextEditingController _etkinliktarihController = TextEditingController();
    TextEditingController _etkinlikadiController = TextEditingController();


    Future<void> smsTaslakDetay(SmsTaslak selectedValue) async {
        try {

            setState(() {
                _etkinlikmesajicerikController.text = selectedValue.icerik;
                // Adjust this line based on the actual JSON response

            });

        } catch (e) {

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
                title:  const Text('Yeni Etkinlik',style: TextStyle(color: Colors.black),),

                leading: IconButton(
                    icon: Icon(Icons.clear_rounded, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
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
            body: GestureDetector(
                onTap: () {
                    // Unfocus the current text field, dismissing the keyboard
                    FocusScope.of(context).unfocus();
                },
              child: SingleChildScrollView(
                  reverse: true,
                  child: Form(
                      key:_formKey,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              SizedBox(height: 20,),
                              Padding(
                                  padding: const EdgeInsets.only(left: 20.0),
                                  child: Text('Etkinlik İsmi',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                              ),
                              SizedBox(height: 10,),
                              Container(
                                  height: 40,
                                  padding: const EdgeInsets.only(left: 20.0,right: 20),
                                  child: TextFormField(
                                      controller: _etkinlikadiController,

                                      keyboardType: TextInputType.text,
                                      onSaved: (value) {


                                          _etkinlikadiController.text = value!;
                                      },
                                      validator: (value) {
                                          if (value == null || value.isEmpty) {
                                              return 'Bu alan zorunludur!';
                                          }
                                          return null;
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

                                                      controller: _etkinliktarihController,
                                                      enabled:true,
                                                      onSaved: (value) {

                                                          _etkinliktarihController.text = value!;
                                                      },
                                                      validator: (value) {
                                                          if (value == null || value.isEmpty) {
                                                              return 'Bu alan zorunludur!';
                                                          }
                                                          return null;
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
                                                                  _etkinliktarihController.text =
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
                                                  padding: const EdgeInsets.only(left: 20.0),
                                                  child: Text('Saat',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                              ),
                                              SizedBox(height: 10,),
                                              Container(
                                                  height: 40,
                                                  padding: EdgeInsets.only(left:20,right: 20),
                                                  child: TextFormField(
                                                      controller: _etkinliksaatController,
                                                      onSaved: (value) {

                                                          _etkinliksaatController.text = value!;
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
                                                                  _etkinliksaatController.text = DateFormat.Hm().format(
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
                                  padding: const EdgeInsets.only(left: 20.0),
                                  child: Text('SMS Şablonu',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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

                                      child: DropdownButton2<SmsTaslak>(

                                          isExpanded: true,
                                          hint: Text(
                                              secyazisi,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context).hintColor,
                                              ),
                                          ),
                                          items: smstaslak
                                              .map((item) => DropdownMenuItem(
                                              value: item,
                                              child: Text(
                                                  item.baslik,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                  ),
                                              ),
                                          ))
                                              .toList(),
                                          value: selectedsablon,

                                          onChanged: (value) {
                                              setState(() {
                                                  selectedsablon = value;
                                                  if(value!=null)
                                                      smsTaslakDetay(value!);
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
                                              searchController: sablonController,
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
                                                      controller: sablonController,
                                                      decoration: InputDecoration(
                                                          isDense: true,
                                                          contentPadding: const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 8,
                                                          ),
                                                          hintText: 'Personel Ara..',
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
                                          //This to clear the search value when you close the menu
                                          onMenuStateChange: (isOpen) {
                                              if (!isOpen) {
                                                  sablonController.clear();
                                              }
                                          },

                                      )),
                              ),

                              SizedBox(height: 10,),
                              Padding(
                                  padding: const EdgeInsets.only(left: 20.0),
                                  child: Text('Mesaj İçeriği',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                              ),
                              SizedBox(height: 10,),
                              Container(

                                  padding: const EdgeInsets.only(left: 20.0,right: 20),
                                  child: TextFormField(
                                      controller: _etkinlikmesajicerikController,
                                      keyboardType: TextInputType.text,
                                      onSaved: (value) {
                                          if(value != null)
                                              _etkinlikmesajicerikController.text = value;
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

                              Row(
                                  children: [

                                      Expanded(child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                              Padding(
                                                  padding: const EdgeInsets.only(left: 20.0),
                                                  child: Text('Fiyat',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                              ),
                                              SizedBox(height: 10,),
                                              Container(
                                                  height: 40,
                                                  padding: const EdgeInsets.only(left: 20.0,right: 20),
                                                  child: TextFormField(
                                                      controller: _etkinlikfiyatController,
                                                      keyboardType: TextInputType.phone,
                                                      onSaved: (value) {
                                                          _etkinlikfiyatController.text = value!;

                                                      },

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
                                          ],
                                      )),
                                      Expanded(child:  Column(

                                          children: [
                                              Padding(
                                                  padding: const EdgeInsets.only(left: 20.0),
                                                  child: Text('',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                                              ),
                                              SizedBox(height: 10,),
                                              ElevatedButton(
                                                  onPressed: () {
                                                      showCheckboxPopup(context);
                                                  },
                                                  child: Text(buttonLabel),
                                                  style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.purple[800],
                                                      foregroundColor: Colors.white,
                                                      minimumSize: Size(150, 40),
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10.0)
                                                      ),
                                                      elevation: 5,
                                                  ),

                                              ),
                                          ],
                                      ),),
                                  ],
                              ),

                              SizedBox(height: 20,),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [

                                      ElevatedButton(

                                          onPressed: (){


                                                  widget.etkinlidatasource.etkinlikekleguncelle('', widget.isletmebilgi, seciliisletme, _etkinlikadiController.text, _etkinliktarihController.text, _etkinliksaatController.text, _etkinlikmesajicerikController.text, _etkinlikfiyatController.text, secilenkatilimcilar, context);

                                              //_isLoading ? null : submitForm(_baslik,_icerik,_tarih,_saat,_kac_saat_once,_hatirlatma,context);


                                              /*final Map<String, dynamic> data = {
                                          'text': dateInput.text,
                                          'text2': _controller.text,
                                          'text3': _contentController2.text,
                                          'text4': _contentController.text,
                                          'dropdownValue': selectedsablon,

                                      };*/
                                              //Navigator.pop(context, data);
                                          },
                                          child: Row(
                                              children: [
                                                  Icon(Icons.add_circle_outline),
                                                  Text('KAYDET'),
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

              ),
            ),
        );
    }

}
