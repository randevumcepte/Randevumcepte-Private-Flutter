import 'dart:convert';
import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Backend/backend.dart';
import '../Login Sayfası/login_page.dart';
import '../Models/personel.dart';
import '../Models/randevuhizmetleri.dart';

class RandevuOnay extends StatefulWidget {
  final List<RandevuHizmet> seciliHizmetler;
  final String salonid;
  final String tarih;
  final String saat;
  final dynamic isletmebilgi;
  RandevuOnay({Key? key,required this.seciliHizmetler,required this.tarih,required this.saat,required this.salonid,required this.isletmebilgi}) : super(key: key);


  @override
  RandevuOnayState createState() => RandevuOnayState();
}

class RandevuOnayState extends State<RandevuOnay> {
  final TextEditingController kampanyaController = TextEditingController();
  final TextEditingController notController = TextEditingController();

  bool kampanyaIzin = false;
  bool kvkkOnay = false;
  bool girisYapilmis = false;
  Map <String,dynamic> user = {};
  void initState() {
    super.initState();
    _checkGiris();

  }
  void _checkGiris() async {
    bool giris = await girisYapilmismi();
    setState(() {
      girisYapilmis = giris;
    });
  }
  Future<bool> girisYapilmismi() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();

    var userType = localStorage.getString('user_type');
    String? userString = localStorage.getString('musteri');

    log('user type ' +userType.toString());
    log('user str ' +userString!);
    if (userType == null && userString == null && userType!='0') {
      return false; // giriş yapılmamış
    }

    user = jsonDecode(userString!);
    return true;
  }


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide the keyboard
      },
      child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title:  const Text('Randevu Özeti',style: TextStyle(color: Colors.black),),

            leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            elevation: 4, // gölge ekler, değeri artırarak gölgeyi güçlendirebilirsin
            shadowColor: Colors.grey.withOpacity(0.5), // gölge rengi
          ),

        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              if(girisYapilmis)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Sayın "+user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),

                  ],
                ),

              ...widget.seciliHizmetler.asMap().entries.map((element) {
                final personel = element.value.personeller as Personel;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0 ), // burada padding ayarlayabilirsin
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        element.value.hizmetler['hizmet_adi'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(personel.personel_adi),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),

              // Tarih
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tarih:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.tarih),
                ],
              ),
              const SizedBox(height: 8),

              // Saat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Saat:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.saat),
                ],
              ),
              const SizedBox(height: 20),



              // Not alanı
              const Divider(
                height: 1.0,
                thickness: 1,
              ),
              ListTile(
                contentPadding: const EdgeInsets.all(5),
                leading: const Icon(
                  Icons.subject,
                  color: Colors.black87,
                ),
                title: TextFormField(
                  controller: notController,
                  onSaved: (value) {
                    notController.text = value!;
                  },
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'İşletmemize iletmek istedikleriniz.',
                  ),
                ),
              ),
              const Divider(
                height: 1.0,
                thickness: 1,
              ),
              const SizedBox(height: 20),


              // CheckboxListTile içinde:
          CheckboxListTile(
            value: kvkkOnay,
            onChanged: (val) {
              setState(() {
                kvkkOnay = val ?? false;
              });
            },
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Kullanım koşullarını ",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final url = Uri.parse("https://randevumcepte.com.tr/kullanim-kosullari/");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                  ),
                  const TextSpan(text: "ve " ,style: TextStyle(fontSize: 14)),
                  TextSpan(
                    text: "Gizlilik & KVKK politikasını ",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final url = Uri.parse("https://randevumcepte.com.tr/gizlilik-politikasi-ve-guvenlik/");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                  ),
                  const TextSpan(text: "okudum, kabul ediyorum.",style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                if (!kvkkOnay) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Devam etmek için KVKK onayı vermelisiniz.")),
                  );
                  return;
                }
                SharedPreferences localStorage = await SharedPreferences.getInstance();
                var token = localStorage.getString('token');
                var userType = localStorage.getString('user_type');



                if(token != null && userType.toString()=='1')
                {
                    await localStorage.remove('musteri');
                    await localStorage.remove('user_type');
                    await localStorage.remove('token');
                    token = null;

                }


                if(token==null)
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (builder) => LoginPage(randevuSayfasinaYonlendir: true,seciliHizmetler: widget.seciliHizmetler,tarih: widget.tarih,saat: widget.saat,),
                    ),
                  );
                else{

                  MusteriDanisan md = MusteriDanisan.fromJson(user);
                  randevuEkleGuncelle(
                      '',
                      '',
                      '',
                      md,
                      widget.tarih,
                      widget.saat,
                      widget.seciliHizmetler,
                      [],
                      false,
                     '0',
                     '',
                      notController.text,
                      widget.salonid.toString(),
                      context,
                      'uygulama',
                      '0',
                      md.musteri_olunan_salonlar?.firstWhere((element)=>element['salon_id'].toString() == widget.salonid.toString())['salonlar']
                  );
                }

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "RANDEVU TALEP ET",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),

      ),
    );

  }


}