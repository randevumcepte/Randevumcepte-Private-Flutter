
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:randevu_sistem/Backend/backend.dart';

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

  final phoneMask = MaskTextInputFormatter(
    mask: '0### ### ## ##',
    filter: { "#": RegExp(r'[0-9]') },
  );
  @override
  void initState() {
    super.initState();
    ceptelefon.text = "0";  // Format en başta görünsün
  }
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
                child:
                  Image.asset(
                    'images/vionnaguzellik.png',
                    width: MediaQuery.of(context).size.width > 520 ? 500 : MediaQuery.of(context).size.width - 20,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                margin: const EdgeInsets.only(top: 60),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 25),

                      // 🔙 GERİ + BAŞLIK AYNI SATIR
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.purple, size: 28),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),

                          Expanded(
                            child: Center(
                              child:
                                const Text(
                                  "Müşteri Ol",
                                  style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.purple,
                                    letterSpacing: 2,
                                    fontFamily: "Lobster",
                                  ),
                                ),

                            ),
                          ),

                          // Sağ boşluk — geri butonunun simetrisi
                          const SizedBox(width: 48),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // 🟣 AD SOYAD

                        Container(
                          width: double.infinity,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.purple, width: 1),
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(Icons.add_link_sharp),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  child: TextFormField(
                                    controller: adsoyad,
                                    onSaved: (value) {
                                      adsoyad.text = value!;
                                    },
                                    maxLines: 1,
                                    decoration: const InputDecoration(
                                      hintText: " Adınız Soyadınız",
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),


                      // 🟣 TELEFON

                        Container(
                          width: double.infinity,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.purple, width: 1),
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_in_talk),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  child: TextFormField(
                                    controller: ceptelefon,
                                    keyboardType: TextInputType.number,
                                    maxLines: 1,
                                    inputFormatters: [phoneMask],

                                    onTap: () {
                                      if (ceptelefon.text.length < 2) {
                                        ceptelefon.text = "0";
                                      }
                                      ceptelefon.selection = TextSelection.fromPosition(
                                        TextPosition(offset: ceptelefon.text.length),
                                      );
                                    },

                                    onChanged: (value) {
                                      if (!value.startsWith("0")) {
                                        ceptelefon.text = "0";
                                        ceptelefon.selection = TextSelection.fromPosition(
                                          TextPosition(offset: ceptelefon.text.length),
                                        );
                                      }
                                    },

                                    decoration: const InputDecoration(
                                      hintText: " Telefon Numarası ...",
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),


                      const SizedBox(height: 15),

                      // 🟣 BUTON

                        ElevatedButton(
                          onPressed: () {
                            bool isValid = true;

                            if (ceptelefon.text == '' || ceptelefon.text == '0') isValid = false;
                            if (adsoyad.text == '') isValid = false;

                            if (isValid) {
                              musteridanisankaydi(
                                ceptelefon.text,
                                adsoyad.text,
                                context,
                                widget.randevuSayfasinaYonlendir,
                              );
                            } else {
                              formWarningDialogs(context, "UYARI", "Lütfen formu eksiksiz doldurunuz");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.purpleAccent,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            side: BorderSide(color: Colors.purple, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
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


                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
  Future<void> musteridanisankaydi(String tel,String adsoyad,context,bool randevuSayfasinaYonlendir) async {
    showProgressLoading(context);

    bool loadingPopped = false;
    void popLoadingOnce() {
      if (loadingPopped) return;
      loadingPopped = true;
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
    }

    try {
      String appBundle = await appBundleAl();

      Map<String, dynamic> formData = {
        'cep_telefon':tel,
        'name':adsoyad,
        'sms_baslik' : '',
        'sms_apikey' : '',
        'salonidler' : '352',
        'sms_username':'',
        'sms_secret':'',
        'isletmeadi': 'Vionna Güzellik Salonu',
        'appBundle': appBundle
      };

      final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/yenimusteridanisankaydi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      ).timeout(const Duration(seconds: 25));

      debugPrint('kayit response status: ${response.statusCode}');
      debugPrint('kayit response body: ${response.body}');

      popLoadingOnce();

      if (response.statusCode == 200) {
        if (response.body.trim() == "exists") {
          formWarningDialogs(
            context,
            "HATA",
            "Sistemde " + tel + " telefon numarasına ait kayıt bulunmaktadır. Eğer şifrenizi unuttuysanız lütfen şifremi unuttum bölümünden yeni şifrenizi alınız",
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (builder) => LoginPage(
                randevuSayfasinaYonlendir: randevuSayfasinaYonlendir,
                seciliHizmetler: widget.seciliHizmetler,
                tarih: widget.tarih,
                saat: widget.saat,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt oluşturulurken bir hata oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin. (${response.statusCode})'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on TimeoutException catch (_) {
      popLoadingOnce();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sunucu yanıt vermiyor. Lütfen daha sonra tekrar deneyin.'),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      popLoadingOnce();
      debugPrint('kayit exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: ${e.toString()}'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

}