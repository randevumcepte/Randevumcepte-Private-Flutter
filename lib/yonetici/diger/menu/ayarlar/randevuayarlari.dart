
import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/takvimayari.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../Backend/backend.dart';
import '../../../../Frontend/altyuvarlakmenu.dart';
import '../../../../Models/randevuaraligi.dart';
import '../../../../Models/salonlar.dart';





class RandevuAyarlari extends StatefulWidget {
  final dynamic isletmebilgi;
  const RandevuAyarlari({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _RandevuAyarlariState createState() => _RandevuAyarlariState();
}

class _RandevuAyarlariState extends State<RandevuAyarlari> {
  final List<RandevuAraligi> randevuaraligi = [
    RandevuAraligi(id: "15", ran: '15 dakikada bir',),
    RandevuAraligi(id: "30", ran: '30 dakikada bir',),
    RandevuAraligi(id: "45", ran: '45 dakikada bir',),
    RandevuAraligi(id: "60", ran: '60 dakikada bir',),
    RandevuAraligi(id: "90", ran: '90 dakikada bir',),
    RandevuAraligi(id: "120", ran: '120 dakikada bir',),


  ];

  RandevuAraligi? selectedrandevuaraligi;
  TextEditingController randevuaraligicontroller = TextEditingController();
  final List<TakvimAyari> takvimayari = [
   TakvimAyari(id: '1', takvim:  'Personele Göre',),
   TakvimAyari(id: '0', takvim:  'Hizmet Kategorisine Göre',),
   TakvimAyari(id: '2', takvim:  'Cihaza Göre',),
   TakvimAyari(id: '3', takvim:  'Sınıfa Göre',),

  ];

  TakvimAyari? selectedtakvimayari;
  TextEditingController takvimayaricontroller = TextEditingController();
  late String seciliisletme;
  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    // Fetch existing settings from backend and set the selected values
    final settings = await fetchSalonSettings(seciliisletme);

    // Ensure that the settings data is not null.
    if (settings != null) {
      setState(() {
        // Find the randevuaraligi value matching the fetched setting, or default to the first one.
        selectedrandevuaraligi = randevuaraligi.firstWhere(
              (element) {
            print('Element ID: ${element.id}');
            print('Settings randevu_saat_araligi: ${settings['randevu_saat_araligi']}');
            return element.id.toString() == settings['randevu_saat_araligi'].toString();
          },
          orElse: () => randevuaraligi.first,
        );
        selectedtakvimayari = takvimayari.firstWhere(
              (element) {
            print('Element ID: ${element.id}');
            print('Settings randevu_saat_araligi: ${settings['randevu_takvim_turu']}');
            return element.id.toString() == settings['randevu_takvim_turu'].toString();
          },
          orElse: () => takvimayari.first,
        );


      });
    } else {
      // Handle the case where settings is null.
      setState(() {
        selectedrandevuaraligi = randevuaraligi.last;
        selectedtakvimayari = takvimayari.first;
      });
    }
  }
  void initState() {
    super.initState();



    initialize();
  }
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      // floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),
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
        title: Text("Randevu Ayarları",style: TextStyle(color: Colors.black),),

      ),
      body: Padding( padding: EdgeInsets.all(8),
        child: Form(
          key: formKey,
          child: ListView(

            children: [
              SizedBox(height: 10,),
              Container(
                padding: const EdgeInsets.only(left: 5.0),
                child: Text('Randevu Aralığı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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

                    child: DropdownButton2<RandevuAraligi>(

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
                      items: randevuaraligi
                          .map((item) =>
                          DropdownMenuItem(
                            value: item,
                            child: Text(
                              item.ran,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ))
                          .toList(),
                      value: selectedrandevuaraligi,
                      onChanged: (value) {
                        setState(() {
                          selectedrandevuaraligi = value;
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
                          randevuaraligicontroller.clear();
                        }
                      },

                    )),
              ),
              SizedBox(height: 20,),
              Container(
                padding: const EdgeInsets.only(left: 5.0),
                child: Text('Takvim Ayarı',style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),),
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

                    child: DropdownButton2<TakvimAyari>(

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
                      items: takvimayari
                          .map((item) =>
                          DropdownMenuItem(
                            value: item,
                            child: Text(
                              item.takvim,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ))
                          .toList(),
                      value: selectedtakvimayari,
                      onChanged: (value) {
                        setState(() {
                          selectedtakvimayari = value;
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
                          takvimayaricontroller.clear();
                        }
                      },

                    )),
              ),
              SizedBox(height: 20,),

              SizedBox(height: 20,),
              ElevatedButton(onPressed: (){

                  submitForm(
                      selectedrandevuaraligi?.id??"",
                      selectedtakvimayari?.id??"",
                      seciliisletme,

                      context);

              },
                child: Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(90, 40)
                ),
              ),
            ],
          ),

        ),
      ),

    );
  }


}
Future<void> submitForm(String randevu,String takvim,String salonid,context)async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();


  Map<String,dynamic> formData={
    'randevu_saat_araligi':randevu,
    'randevu_takvim_turu':takvim,
    'salon_id':salonid



  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevuayarguncelle'),

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