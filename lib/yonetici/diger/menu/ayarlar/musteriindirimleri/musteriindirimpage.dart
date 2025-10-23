import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../../../../Backend/backend.dart';

class MusteriIndirimleri extends StatefulWidget {
  final dynamic isletmebilgi;
  const MusteriIndirimleri({Key? key,required this.isletmebilgi}) : super(key: key);

  @override
  _MusteriIndirimleriState createState() => _MusteriIndirimleriState();
}

class _MusteriIndirimleriState extends State<MusteriIndirimleri> {
  late String seciliisletme;
  bool? isChecked;
  bool? isChecked2;
  TextEditingController aktif = TextEditingController();
  TextEditingController sadik = TextEditingController();

  Future<void> initialize() async {
    seciliisletme = (await secilisalonid())!;
    final settings = await fetchSalonSettings(seciliisletme);

    if (settings != null) {
      setState(() {
        // Update discount text fields
        sadik.text = settings['sadik_musteri_indirim_yuzde']?.toString() ?? '0';
        aktif.text = settings['aktif_musteri_indirim_yuzde']?.toString() ?? '0';

        // Update checkbox states based on discount values
        isChecked = sadik.text != '0'; // Check if sadik.text is not '0'
        isChecked2 = aktif.text != '0'; // Check if aktif.text is not '0'
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus(); // Hide the keyboard
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(
            'Müşteri İndirimleri',
            style: TextStyle(color: Colors.black),
          ),
          leading: IconButton(
            icon: Icon(Icons.clear_rounded, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          toolbarHeight: 60,
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 100,
                child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
            ),)
          ],
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(height: 25),
                            Container(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text(
                                'Sadık Müşteri İndirimi(%)',
                                style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 40,
                              padding: EdgeInsets.only(left: 20, right: 20),
                              child: TextFormField(
                                controller: sadik,
                                onSaved: (value) {

                                  sadik.text = value!;
                                },
                                keyboardType: TextInputType.phone,
                                enabled: isChecked ?? false,
                                decoration: InputDecoration(
                                  filled: true,
                                  focusColor: Color(0xFF6A1B9A),
                                  fillColor: Colors.white,
                                  hoverColor: Color(0xFF6A1B9A),
                                  hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
                                  contentPadding: EdgeInsets.all(15.0),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 50),
                          Row(
                            children: [
                              Checkbox(
                                value: isChecked ?? false, // Default to false if isChecked is null
                                onChanged: (bool? value) {
                                  setState(() {
                                    isChecked = value;
                                    // Update text fields to zero if checkbox is unchecked
                                    if (value == false) {
                                      sadik.text = '0';
                                    }
                                  });
                                },
                              ),
                              Text(isChecked ?? false ? 'Açık   ' : 'Kapalı'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(height: 25),
                            Container(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text(
                                'Aktif Müşteri İndirimi(%)',
                                style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 40,
                              padding: EdgeInsets.only(left: 20, right: 20),
                              child: TextFormField(
                                controller: aktif,
                                onSaved: (value) {

                                  aktif.text = value!;
                                },
                                keyboardType: TextInputType.phone,
                                enabled: isChecked2 ?? false,
                                decoration: InputDecoration(
                                  filled: true,
                                  focusColor: Color(0xFF6A1B9A),
                                  fillColor: Colors.white,
                                  hoverColor: Color(0xFF6A1B9A),
                                  hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
                                  contentPadding: EdgeInsets.all(15.0),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 50),
                          Row(
                            children: [
                              Checkbox(
                                value: isChecked2 ?? false, // Default to false if isChecked2 is null
                                onChanged: (bool? value) {
                                  setState(() {
                                    isChecked2 = value;
                                    // Update text fields to zero if checkbox is unchecked
                                    if (value == false) {
                                      aktif.text = '0';
                                    }
                                  });
                                },
                              ),
                              Text(isChecked2 ?? false ? 'Açık   ' : 'Kapalı'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {

                  submitForm(
                      sadik.text,
                      aktif.text,
                      seciliisletme,
                      isChecked,
                      isChecked2,

                      context);
                },
                child: Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(90, 40),
                ),
              ),
              Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))
            ],
          ),
        ),

      ),
    );
  }
}
Future<void> submitForm(String sadik,String aktif,String salonid,check,check2,context)async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();


  Map<String,dynamic> formData={
    'sadik_musteri_indirimi':sadik,
    'aktif_musteri_indirimi':aktif,
    'sube':salonid,
    'sadik_acikkapali':check,
    'aktif_acikkapali':check2,



  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteriindirim_kaydet'),

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