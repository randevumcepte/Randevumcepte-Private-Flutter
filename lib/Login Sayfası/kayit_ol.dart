
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Frontend/popupdialogs.dart';
import '../Frontend/progressloading.dart';
import '../Models/randevuhizmetleri.dart';
import 'fade_animation.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;

class KayitOl extends StatefulWidget {
  final bool randevuSayfasinaYonlendir;
  final List<RandevuHizmet> seciliHizmetler;
  final String tarih;
  final String saat;
  KayitOl({Key? key,required this.randevuSayfasinaYonlendir, required this.seciliHizmetler,required this.tarih,required this.saat}) : super(key: key);
  @override
  _KayitOlState createState() => _KayitOlState();
}

class _KayitOlState extends State<KayitOl> {
  TextEditingController adsoyad = TextEditingController();
  TextEditingController ceptelefon = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // Colors.purple,
                  Colors.purple.shade50,
                  Colors.purple.shade900,
                ])),
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.only(top: 80),
                child:  FadeAnimation(
                  2,
                  Image.asset(
                    'images/aronshine-yatay.png',  // Replace with your image path
                    width: 500,  // Adjust width if needed
                    height: 100,  // Adjust height if needed
                  ),
                )),
            Expanded(
              child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50))),
                  margin: const EdgeInsets.only(top: 60),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 50,
                        ),
                        Container(
                          // color: Colors.red,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(left: 10, bottom: 20),
                            child: const FadeAnimation(
                              2,
                              Text(
                                "Müşteri/Danışan Ol",
                                style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.purple,
                                    letterSpacing: 2,
                                    fontFamily: "Lobster"),
                              ),
                            )),
                        FadeAnimation(
                          2,
                          Container(
                              width: double.infinity,
                              height: 50,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 5),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.purple, width: 1),

                                  color: Colors.white,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(20))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Icon(Icons.add_link_sharp),
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 10),
                                      child: TextFormField(
                                        controller: adsoyad,
                                        onSaved: (value){
                                          adsoyad.text = value!;
                                        },
                                        maxLines: 1,
                                        decoration: const InputDecoration(
                                          hintText:" Adınız Soyadınız",
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                        ),
                        FadeAnimation(
                          2,
                          Container(
                              width: double.infinity,
                              height: 50,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 5),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.purple, width: 1),


                                  color: Colors.white,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(20))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Icon(Icons.phone_in_talk),
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 10),
                                      child: TextFormField(
                                        controller: ceptelefon,
                                        keyboardType: TextInputType.number,
                                        maxLines: 1,
                                        onSaved: (value){
                                          ceptelefon.text=value!;
                                        },
                                        decoration: const InputDecoration(
                                          hintText: " Telefon Numarası ...",
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        FadeAnimation(
                          2,
                          ElevatedButton(
                            onPressed: () {
                              bool isvalid = true;
                              if(ceptelefon.text=='')
                                isvalid =false;
                              if(adsoyad.text=='')
                                isvalid =false;
                              if(isvalid)
                                musteridanisankaydi(ceptelefon.text, adsoyad.text, context,widget.randevuSayfasinaYonlendir);
                              else
                                formWarningDialogs(context, "UYARI", "Lütfen formu eksiksiz doldurunuz");
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.purpleAccent, backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent, // Remove shadow
                              elevation: 0, // Remove elevation
                              side: BorderSide(color: Colors.purple, width: 1.5), // Add a border
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),),
                            child: Ink(
                              decoration: BoxDecoration(

                                  borderRadius: BorderRadius.circular(20)),
                              child: Container(
                                width: 90,
                                height: 40,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Gönder',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),

                            ),

                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),

                      ],
                    ),
                  )),
            )
          ],
        ),
      ),
    );
  }
  Future<void> musteridanisankaydi(String tel,String adsoyad,context,bool randevuSayfasinaYonlendir) async {
    showProgressLoading(context);



    Map<String, dynamic> formData = {
      'cep_telefon':tel,
      'name':adsoyad,
      'sms_baslik' : 'AYLINGEZDIR',
      'sms_apikey' : 'k2EbrzLmNOlEvl49Dtm2GvrstvTzI23TZ775Ri7mlzh4',
      'salonidler' : '182',
      'isletmeadi': 'Aron Güzellik',
      // Add other form fields
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/yenimusteridanisankaydi'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {

      Navigator.of(context,rootNavigator: true).pop();
      if(response.body =="exists")
        formWarningDialogs(context, "HATA", "Sistemde "+tel+" telefon numarasına ait kayıt bulunmaktadır. Eğer şifrenizi unuttuysanız lütfen şifremi unuttum bölümünden yeni şifrenizi alınız");
      else
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (builder) => LoginPage(randevuSayfasinaYonlendir: randevuSayfasinaYonlendir,seciliHizmetler: widget.seciliHizmetler,tarih: widget.tarih,saat: widget.saat,),
          ),
        );




    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müşteri/danışan kaydınız oluşturuluken bir hata oluştu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }

}