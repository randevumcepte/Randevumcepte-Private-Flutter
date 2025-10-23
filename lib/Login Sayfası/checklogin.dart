import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Login%20Sayfas%C4%B1/login_page.dart';
import 'package:randevu_sistem/Login%20Sayfas%C4%B1/tanitim.dart';
import 'package:randevu_sistem/Models/randevuhizmetleri.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/musteri_danisanlar.dart';
import '../Models/user.dart';
import '../basic_bottom_nav_bar.dart';
import '../musteripaneli/anasayfa/anasayfa.dart';
import '../musteripaneli/musterialtbar.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import '../yonetici/subesecimi.dart';


final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();


class CheckAuth extends StatefulWidget {
  @override
  _CheckAuthState createState() => _CheckAuthState();
}

class _CheckAuthState extends State<CheckAuth> {
  bool isAuth = false;
  late Kullanici _kullanici;
  late MusteriDanisan musteri;
  late String user_type;
  bool _isloading = true;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  void _checkIfLoggedIn() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');


    if (token != null ) {


      var usertype = jsonDecode(localStorage.getString('user_type')!);
      Map<String, dynamic>  user = usertype.toString()=='1' ? jsonDecode(localStorage.getString('user')!) : jsonDecode(localStorage.getString('musteri')!);

      if(usertype.toString()=='1'){
        _kullanici = Kullanici.fromJson(user);
      }
      else
        musteri = await kullanicibilgimusteri(user['id'].toString());
      setState(() {
        isAuth = true;
        user_type = usertype;
        _isloading = false;
      });
    } else {
      setState(() {
        _isloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (isAuth && !_isloading) {
      if (user_type.toString() == "1") {
        if (_kullanici.yetkili_olunan_isletmeler.length > 1) {
          child = SubeSecimi(kullanici: _kullanici,scaffoldMessengerKey: scaffoldMessengerKey,);
        } else {
          //log("Üyelik türü "+_kullanici.yetkili_olunan_isletmeler[0]['salonlar']['uyelik_turu']);
          child = BottomNavigationExample(
            scaffoldMessengerKey: scaffoldMessengerKey,
            kullanici: _kullanici,
            isletmebilgi: _kullanici.yetkili_olunan_isletmeler[0]['salonlar'],
            uyelikturu: (_kullanici.yetkili_olunan_isletmeler[0]['salonlar']['uyelik_turu'] as int),

          );
        }
      } else {

        var isletmebilgi = musteri.musteri_olunan_salonlar?.firstWhere((element)=>element['salon_id'].toString()=='182')['salonlar'];
        child =!_isloading ? MusteriAltBar(scaffoldMessengerKey: scaffoldMessengerKey,musteriId: musteri,isletmebilgi: isletmebilgi,): Center(child: CircularProgressIndicator());
      }
    } else {
      log('login sayfasına yönlendiriyor');


      child = !_isloading ? LoginPage(randevuSayfasinaYonlendir: false,tarih: '',saat: '',seciliHizmetler: [],) : Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: child,
    );
  }
}
