import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Login%20Sayfas%C4%B1/kayit_ol.dart';
import 'package:randevu_sistem/Login%20Sayfas%C4%B1/sifremi_unuttum.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:randevu_sistem/randevualma/randevuozetonay.dart';
import 'package:randevu_sistem/yonetici/subesecimi.dart';
// ! import here file animate 
import '../Frontend/indexedstack.dart';
import '../Models/musteri_danisanlar.dart';
import '../Models/randevuhizmetleri.dart';
import '../basic_bottom_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../musteripaneli/musterialtbar.dart';

import '../yonetici/dashboard/home_screen.dart';
import 'fade_animation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/network_utils/api.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:randevu_sistem/musteripaneli/anasayfa/anasayfa.dart';
import 'package:randevu_sistem/Backend/backend.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();


class LoginPage extends StatefulWidget {
  final bool randevuSayfasinaYonlendir;
  final List<RandevuHizmet> seciliHizmetler;
  final String tarih;
  final String saat;


  LoginPage({Key? key, required this.randevuSayfasinaYonlendir, required this.seciliHizmetler,required this.tarih,required this.saat}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<LoginPage> {
  bool _isSelected = false;

  bool _isLoading = false;
  var cep_telefon;
  var password;
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  void _validateInputs() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    } else {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [

                    Colors.purple.shade50,
                    Colors.purple.shade900,
                  ])),
          child: Column(
            children: [
              Container(
                  margin: const EdgeInsets.only(top: 80),
                  child:  FadeAnimation(
                    1,
                    Image.asset(
                      'images/aronshine-yatay.png',  // Replace with your image path
                      width: 500,  // Adjust width if needed
                      height: 100,  // Adjust height if needed
                    ),
                  )),
              Expanded(
                child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(50))),
                    margin: const EdgeInsets.only(top: 60),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 50,
                          ),
                          Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.only(left: 1, bottom: 20),
                              child: const
                                Text(
                                  "Kullanıcı Girişi",
                                  style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.purple,
                                      fontFamily: "Lobster"),
                                ),
                              ),

                            Container(
                                width: double.infinity,
                                height: 50,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 5),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.purple, width: 2),

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
                                          keyboardType: TextInputType.number,
                                          maxLines: 1,
                                          decoration: const InputDecoration(
                                            hintText: "Telefon Numarası ...",
                                            border: InputBorder.none,
                                          ),
                                          validator: (telefonNo) {
                                            if (telefonNo!.isEmpty) {
                                              return 'Telefon alanı gereklidir';
                                            }
                                            cep_telefon = telefonNo;
                                            return null;
                                          },
                                          onSaved: (String? val) {
                                            cep_telefon = val;
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )),


                            Container(
                                width: double.infinity,
                                height: 50,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 5),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.purple, width: 2),

                                    color: Colors.white,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.password_outlined),
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 10),
                                        child: TextFormField(
                                          obscureText: true,
                                          maxLines: 1,
                                          decoration: const InputDecoration(
                                            hintText: "Şifre ...",
                                            border: InputBorder.none,
                                          ),
                                          validator: (passwordValue) {
                                            if (passwordValue!.isEmpty) {
                                              return 'Şifre gereklidir';
                                            }
                                            password = passwordValue;
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )),


                            Padding(
                              padding: EdgeInsets.only(top: 0.0),
                              child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (builder) => SifremiUnuttum(randevuSayfasinaYonlendir: widget.randevuSayfasinaYonlendir,seciliHizmetler: widget.seciliHizmetler,tarih: widget.tarih,saat: widget.saat,),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Şifremi Unuttum",
                                    style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: Colors.deepPurple,
                                        fontSize: 16.0,
                                        fontFamily: "WorkSansMedium"),
                                  )),
                            ),


                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                                ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      _login();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.purpleAccent, backgroundColor: Colors.transparent, // Set the text color
                                    shadowColor: Colors.transparent, // Remove shadow
                                    elevation: 0, // Remove elevation
                                    side: BorderSide(color: Colors.purple, width: 1.5), // Add a border
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Container(
                                    width: 90,
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Giriş Yap',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.purple, // Match the text color to the border
                                      ),
                                    ),
                                  ),
                                ),



                              const SizedBox(
                                width: 25,
                              ),

                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (builder) => KayitOl(randevuSayfasinaYonlendir: widget.randevuSayfasinaYonlendir,seciliHizmetler: widget.seciliHizmetler,tarih: widget.tarih,saat: widget.saat,),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.purpleAccent, backgroundColor: Colors.transparent, // Set the text color
                                    shadowColor: Colors.transparent, // Remove shadow
                                    elevation: 0, // Remove elevation
                                    side: BorderSide(color: Colors.purple, width: 1.5), // Add a border
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Container(
                                    width: 150,
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Müşteri Ol',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.purple, // Match the text color to the border
                                      ),
                                    ),
                                  ),
                                ),


                            ],
                          ),
                          const SizedBox(
                            height: 20.00,
                          ),


                        ],
                      ),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }

  void dispose() {
    super.dispose();
  }

  void _login() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var oneSignalId = localStorage.getString('onesignal_player_id');
    showProgressLoading(context);
    setState(() {
      _isLoading = true;
    });
    var data = {
      'cep_telefon' : cep_telefon,
      'password' : password,

      'appBunle': await appBundleAl(),
      'cihazBilgi': await cihazBilgisi(),
      'bildirimId':oneSignalId.toString(),
    };
    log('login data '+json.encode(data));

    var res = await Network().authData(data, '/login');
    var body = json.decode(res.body);

    _showMsg(msg) {
      final snackBar = SnackBar(
        content: Text(msg),
        action: SnackBarAction(
          label: 'Close',
          onPressed: () {},
        ),
      );
    }
    log('login body' + body.toString());
    if(body['message']['success']) {
      Navigator.of(context,rootNavigator: true).pop();
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      localStorage.setString('token', json.encode(body['message']['token']));

      localStorage.setString('user', json.encode(body['message']['user']));
      log('giriş yapan kullanıcı giriş bölümü '+json.encode(body['message']['user']));

      localStorage.setString('musteri', json.encode(body['message']['musteri']));
      localStorage.setString('user_type', json.encode(body['message']['user_type']));

      Map<String, dynamic> userMap  = body['message']['user_type'].toString() == '1'? json.decode(json.encode(body['message']['user'])) :json.decode(json.encode(body['message']['musteri'])) ;




      if(body['message']['user_type'].toString() == "1") {



        Kullanici kullanici = Kullanici.fromJson(userMap);
        log("Kullanıcı id : "+kullanici.id.toString());
        //saveVoipTokenToBackend(localStorage.getString('ios_voip_token')??'',kullanici.id.toString(),localStorage.getString('fcm_token')??"");
          if(kullanici.yetkili_olunan_isletmeler.length == 1)
          {
            bildirimkimligiekleguncelle(kullanici.id.toString(),kullanici.yetkili_olunan_isletmeler[0]['salon_id'].toString(),body['message']['user_type'],localStorage.getString('onesignal_player_id')??"");

            localStorage.setString('sube',kullanici.yetkili_olunan_isletmeler[0]['salon_id'].toString());
            localStorage.setString('isletmeadi', kullanici.yetkili_olunan_isletmeler[0]['salonlar']['salon_adi']);


          }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => (kullanici.yetkili_olunan_isletmeler.length > 1) ? SubeSecimi(kullanici: kullanici, scaffoldMessengerKey: scaffoldMessengerKey,) : BottomNavigationExample(scaffoldMessengerKey: scaffoldMessengerKey, isletmebilgi: kullanici.yetkili_olunan_isletmeler[0]['salonlar'], kullanici: kullanici, uyelikturu: int.parse(kullanici.yetkili_olunan_isletmeler[0]['salonlar']['uyelik_turu'].toString()),),

          ),
              (route) => false,
        ).then((_) {
          // Reset IndexedStackState to 0 after logging in
          Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
        });
      } else {
        MusteriDanisan musteri = MusteriDanisan.fromJson(userMap);

        var isletmebilgi = musteri.musteri_olunan_salonlar?.firstWhere((element)=>element['salon_id'].toString() == '182')['salonlar'];

        bildirimkimligiekleguncelle(musteri.id.toString(),"",body['message']['user_type'].toString(),localStorage.getString('onesignal_player_id')??"");
        if(widget.randevuSayfasinaYonlendir)
          Navigator.of(context).pop();
        else
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MusteriAltBar(musteriId: musteri,isletmebilgi :isletmebilgi,scaffoldMessengerKey: scaffoldMessengerKey)
            ),
          );
      }
    } else {
      Navigator.of(context, rootNavigator: true).pop();
      formWarningDialogs(context,'HATA',body['message']['message']);
    }

    setState(() {
      _isLoading = false;
    });
  }


}