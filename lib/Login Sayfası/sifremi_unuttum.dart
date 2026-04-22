
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';

// ! import here file animate
import '../Backend/backend.dart';
import '../Frontend/progressloading.dart';
import '../Models/randevuhizmetleri.dart';
import 'fade_animation.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;

class SifremiUnuttum extends StatefulWidget {
  final bool randevuSayfasinaYonlendir;
  final List<RandevuHizmet> seciliHizmetler;
  final String tarih;
  final String saat;

  SifremiUnuttum({Key? key,required this.randevuSayfasinaYonlendir, required this.seciliHizmetler,required this.tarih,required this.saat}) : super(key: key);
  @override
  _SifremiUnuttumState createState() => _SifremiUnuttumState();
}

class _SifremiUnuttumState extends State<SifremiUnuttum> {
  final phoneMask = MaskTextInputFormatter(
    mask: '0### ### ## ##',
    filter: { "#": RegExp(r'[0-9]') },
  );
TextEditingController ceptelefon = TextEditingController();
  @override
  void initState() {
    super.initState();
    ceptelefon.text = "0";  // Format en başta görünsün
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

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
                          // Geri Butonu
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.purple, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),

                          // Başlık ortalı kalsın diye Expanded
                          Expanded(
                            child: Center(
                              child:
                                Text(
                                  "Şifremi Unuttum",
                                  style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.purple,
                                    letterSpacing: 2,
                                    fontFamily: "Lobster",
                                  ),
                                ),
                              ),
                            ),


                          // Sağ tarafı dengelemek için boş ikon kadar yer
                          SizedBox(width: 48),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Bilgilendirme banner'ı
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Şifre sıfırlama, sisteme kayıtlı telefon numaranıza SMS olarak gönderilir. SMS ulaşmazsa lütfen işletmenize ulaşınız.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),


                        Container(
                          width: double.infinity,
                          height: 50,
                          margin:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          padding:
                          const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          decoration: BoxDecoration(
                            border:
                            Border.all(color: Colors.purple, width: 1),
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(Icons.phone_in_talk),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  child: TextFormField(
                                    inputFormatters: [phoneMask],
                                    controller: ceptelefon,
                                    onSaved: (value) {
                                      ceptelefon.text = value!;
                                    },
                                    onTap: () {
                                      if (ceptelefon.text.length < 2) {
                                        ceptelefon.text = "0";
                                      }
                                      ceptelefon.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                                offset: ceptelefon.text.length),
                                          );
                                    },
                                    onChanged: (value) {
                                      if (!value.startsWith("0")) {
                                        ceptelefon.text = "0";
                                        ceptelefon.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                  offset: ceptelefon.text.length),
                                            );
                                      }
                                    },
                                    keyboardType: TextInputType.number,
                                    maxLines: 1,
                                    decoration: const InputDecoration(
                                      hintText:
                                      " Telefon Numarası (başında 0 olmadan)",
                                      hintStyle: TextStyle(fontSize: 14.2),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),


                      const SizedBox(height: 10),

                      ElevatedButton(
                        onPressed: () {
                          if (ceptelefon.text == '' || ceptelefon.text == '0') {
                            formWarningDialogs(
                              context,
                              "UYARI",
                              "Lütfen sisteme kayıtlı olan telefon numaranızı başında 0 olmadan giriniz",
                            );
                          } else {
                            sifregonder(
                              ceptelefon.text,
                              context,
                              widget.randevuSayfasinaYonlendir,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.purple, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Container(
                          width: 90,
                          height: 40,
                          alignment: Alignment.center,
                          child: Text(
                            'Gönder',
                            style: TextStyle(
                              fontSize: 18,
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
  Future<void> sifregonder(String tel,context,bool randevuSayfasinaYonlendir) async {
    showProgressLoading(context);
    String appBundle = await appBundleAl();


    Map<String, dynamic> formData = {
      'cep_telefon':tel,
      'sms_baslik' : '',
      'sms_apikey' : '',
      'salonidler' : '352',
      'sms_username':'',
      'sms_secret':'',
      'isletmeadi': 'Vionna Güzellik Salonu',
      'appBundle': appBundle
      // Add other form fields
    };

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/sifregonder'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      log("cevap body "+response.body);
      Navigator.of(context,rootNavigator: true).pop();
      if(response.body=="error")
        formWarningDialogs(context, "HATA", "Sistemde kayıtlı telefon numarası bulunamadı!");
      else {
        final String maskeli = _maskelePhone(tel);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.sms_outlined, color: Colors.purple),
                const SizedBox(width: 8),
                const Text("Şifreniz Gönderildi"),
              ],
            ),
            content: Text(
              "Yeni şifreniz $maskeli numaralı telefonunuza SMS olarak gönderildi. "
              "SMS birkaç dakika içinde ulaşmazsa lütfen işletmenize ulaşınız.",
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Tamam", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (builder) => LoginPage(randevuSayfasinaYonlendir: randevuSayfasinaYonlendir,seciliHizmetler:widget.seciliHizmetler,tarih: widget.tarih,saat: widget.saat,),
          ),
        );
      }




    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şifreniz gönderilirken bir hata oluştu : '+response.statusCode.toString()),
        ),
      );
      debugPrint('Error: ${response.body}');
    }
  }

  String _maskelePhone(String tel) {
    final digits = tel.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return tel;
    final son = digits.substring(digits.length - 2);
    final bas = digits.substring(0, digits.length >= 4 ? 4 : 1);
    return '$bas *** ** $son';
  }

}