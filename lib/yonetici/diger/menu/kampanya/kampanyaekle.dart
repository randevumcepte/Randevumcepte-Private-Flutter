import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/paket_hizmetleri.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Backend/backend.dart';
import '../../../../Frontend/sfdatatable.dart';
import '../../../../Models/musteri_danisanlar.dart';
import '../../../../Models/paketler.dart';
import '../../../../Models/sms_taslaklari.dart';

import 'package:http/http.dart' as http;

import 'kampanyalar.dart';

class KampanyaEkle extends StatefulWidget {
  final KampanyaDataSource kampanyadatasource;
  final dynamic isletmebilgi;
  KampanyaEkle({Key? key, required this.kampanyadatasource,required this.isletmebilgi}) : super(key: key);
  @override
  _KampanyaEkleState createState() => _KampanyaEkleState();
}
class _KampanyaEkleState extends State<KampanyaEkle> {
  final _formKey = GlobalKey<FormState>();
  late List<MusteriDanisan> musteridanisan;
  List<SmsTaslak> smstaslak = [SmsTaslak(id: '', baslik: 'Veriler getiriliyor. Lütfen bekleyiniz!', icerik: 'icerik')];
  List<Paket> paket = [Paket(id: '0', paket_adi: 'Veriler getiriliyor. Lütfen bekleyiniz!', aktif: '0', hizmetler: []) ];
  String secyazisi = 'Veriler getiriliyor. Lütfen bekleyiniz!';
  late String seciliisletme;
  void _fetchData() async {

      seciliisletme = (await secilisalonid())!;
      List<MusteriDanisan> musteridanisanlistesi = await musterilistegetir(seciliisletme);
      List<SmsTaslak> smstaslakliste = await smstaslakgetir(seciliisletme);
      List<Paket> paketliste = await paketgetir(seciliisletme);

      setState(() {
        musteridanisan = musteridanisanlistesi;
        smstaslak = smstaslakliste;
        paket = paketliste;
        secyazisi = 'Seç';

      });

  }


  List<MusteriDanisan> secilenkatilimcilar = [];
  void initState() {
    super.initState();

    _fetchData();
  }
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

  final List<String> sablon = [
    'etkinlik mesajı',


  ];

  SmsTaslak? selectedsablon;
  Paket? selectedpaketadi;
  TextEditingController sablonController = TextEditingController();





  TextEditingController kampanyahizmetcontroller = TextEditingController();
  TextEditingController kampanyaseanscontroller = TextEditingController();
  TextEditingController kampanyafiyatcontroller = TextEditingController();
  TextEditingController kampanyapaketadicontroller = TextEditingController();
  TextEditingController kampanyamesajcontroller = TextEditingController();

void paketDetayGetir(Paket selectedValue) async {
    try {

        setState(() {
          final List<dynamic> pakethizmetleri = selectedValue.hizmetler;
          String hizmetler = '';
          int seans = 0;
          double fiyat = 0;
          for (var element in pakethizmetleri) {
            log('hizmet seans  : '+element['seans'].toString());
            hizmetler += element['hizmet']['hizmet_adi'] + ' ';
            seans += element['seans'] != null ? int.parse(element['seans'].toString()) : 0;
            fiyat += element['fiyat'] != null ? double.parse(element['fiyat'].toString()) : 0.0;
          }
          kampanyahizmetcontroller.text = hizmetler;
          kampanyaseanscontroller.text = seans.toString();
          kampanyafiyatcontroller.text = fiyat.toString();

          kampanyapaketadicontroller.text = selectedValue.paket_adi;

          // Adjust this line based on the actual JSON response

        });

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  Future<void> smsTaslakDetay(SmsTaslak selectedValue) async {
    try {

      setState(() {
        kampanyamesajcontroller.text = selectedValue.icerik;
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
        title:  const Text('Yeni Kampanya',style: TextStyle(color: Colors.black),),

        leading: IconButton(
          icon: Icon(Icons.clear_rounded, color: Colors.black),
          onPressed: () =>{ Navigator.of(context).pop(), Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Kampanyalar(isletmebilgi: widget.isletmebilgi,)),
        )},

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
      body: GestureDetector(
        onTap: () {
          // Unfocus the current text field, dismissing the keyboard
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          reverse: true,
          child:Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20,),

                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text('Paket',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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

                      child: DropdownButton2<Paket>(

                        isExpanded: true,
                        hint: Text(
                          secyazisi,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        items: paket
                            .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.paket_adi,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ))
                            .toList(),
                        value: selectedpaketadi,

                        onChanged: (Paket? value) {

                          setState(() {

                            selectedpaketadi = value;
                            if (value != null) {
                              paketDetayGetir(value!);
                            }
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
                          searchController: kampanyapaketadicontroller,
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
                              controller: kampanyapaketadicontroller,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                hintText: 'Paket Ara..',
                                hintStyle: const TextStyle(fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                          searchMatchFn: (item, searchValue) {
                            return item.value!.paket_adi.toString().toLowerCase().contains(searchValue.toLowerCase());
                          },
                        ),
                        //This to clear the search value when you close the menu
                        onMenuStateChange: (isOpen) {
                          if (!isOpen) {
                            kampanyapaketadicontroller.clear();
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
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Text('Hizmet(-ler)',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                        ),
                        SizedBox(height: 10,),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.only(left: 20.0,right: 20),
                          child: TextFormField(
                            readOnly: true,
                            controller: kampanyahizmetcontroller,
                            keyboardType: TextInputType.text,
                            onSaved: (value){
                              if(value!=null)
                                kampanyahizmetcontroller.text = value;
                            },
                            decoration: InputDecoration(
                              enabled:true,
                              focusColor:Color(0xFF6A1B9A) ,
                              hoverColor: Color(0xFF6A1B9A) ,
                              hintStyle: TextStyle(color:  Color(0xFF6A1B9A)),
                              contentPadding:  EdgeInsets.all(10.0),
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
                    )
                    ),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Text('Seans',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
                        ),
                        SizedBox(height: 10,),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.only(left: 20.0,right: 20),
                          child: TextFormField(
                            readOnly: true,
                            controller: kampanyaseanscontroller,
                            keyboardType: TextInputType.phone,
                            onSaved: (value){
                              if(value!=null)
                                kampanyaseanscontroller.text=value;
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
                                hintText: 'Şablon Ara..',
                                hintStyle: const TextStyle(fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                          searchMatchFn: (item, searchValue) {
                            return item.value!.baslik.toLowerCase().toString().contains(searchValue.toLowerCase());
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
                    controller: kampanyamesajcontroller,
                    keyboardType: TextInputType.text,
                    onSaved: (value) {
                      if(value != null)
                        kampanyamesajcontroller.text = value;
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
                            controller: kampanyafiyatcontroller,
                            keyboardType: TextInputType.phone,
                            onSaved: (value){
                              if(value!= null)
                                kampanyafiyatcontroller.text = value;
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

                    ElevatedButton(onPressed: (){


                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        bool isvalid = true;
                        String hatamesaj = 'Formu kaydetmeden önce aşağıdaki hataları düzeltmeniz gerekmektedir!';
                        if (selectedpaketadi == null) {
                          isvalid = false;
                          hatamesaj += '\n\n Lütfen listeden paket seçiniz.';
                        }

                        if (secilenkatilimcilar.length == 0) {
                          isvalid = false;
                          hatamesaj +=
                          '\n\n Lütfen kampanyanızı duyurmak istediğiniz en az 1 katılımcı seçiniz.';
                        }
                        if (kampanyamesajcontroller.text == '') {
                          isvalid = false;
                          hatamesaj +=
                          '\n\n Lütfen kampanyanız için mesaj içeriğinizi yazınız.';
                        }
                        if (!isvalid) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('HATA'),
                                content: Text(hatamesaj),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('TAMAM'),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Dismiss the dialog
                                    },
                                  ),

                                ],
                              );
                            },
                          );
                        }
                        else {
                          showProgressLoading(context);
                          widget.kampanyadatasource.kampanyaekleguncelle("", seciliisletme, selectedpaketadi!,  kampanyamesajcontroller.text,
                              kampanyaseanscontroller.text,
                              kampanyahizmetcontroller.text,
                              kampanyafiyatcontroller.text,
                              secilenkatilimcilar,context);


                        }
                      }
                    },
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline),
                          Text(' Kaydet ve Gönder'),
                        ],
                      ),
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

