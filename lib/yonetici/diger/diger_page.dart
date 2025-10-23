import 'dart:convert';
import 'dart:io';


import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/network_utils/api.dart';
import 'package:randevu_sistem/Login%20Sayfas%C4%B1/checklogin.dart';
import 'dart:developer';
import 'package:randevu_sistem/yonetici/dashboard/home_screen.dart';
import '../../Backend/backend.dart';
import '../../Frontend/backroutes.dart';
import '../../Frontend/indexedstack.dart';
import '../../Login Sayfası/tanitim.dart';
import '../../Models/user.dart';
import '../../basic_bottom_nav_bar.dart';
import '../dashboard/profilbilgileri.dart';
import '../subesecimi.dart';
import 'menu/ajanda/ajanda.dart';
import 'menu/arsiv/arsivyonetimipage.dart';
import 'menu/asistanim/asistanpage.dart';
import 'menu/ayarlar/ayarlar.dart';
import 'menu/etkinlik/etkinikler.dart';
import 'menu/kampanya/kampanyalar.dart';
import 'menu/kasa/alacaklar.dart';
import 'menu/kasa/kasaraporu.dart';
import 'menu/kasa/masraflar.dart';
import 'menu/musteriler/musteriliste.dart';
import 'menu/ongorusmeler/ongorusmeler.dart';
import 'menu/randvular/randevularmenu.dart';
import 'menu/satislar/paketsatislariyeni.dart';
import 'menu/satislar/urunsatislariyenisayfa.dart';
import 'menu/seanstakibi/seanstakibiyeni.dart';
import 'menu/senetler/senetlistesi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

bool menu_sayfasindayiz = false;
late Kullanici _kullanici;
late int kullanicirolu;
class DigerPage extends StatefulWidget {

  final Kullanici kullanici;
  final int uyelikturu;
  final VoidCallback onLogout;
  final dynamic isletmebilgi;
  DigerPage({Key? key,required this.kullanici,required this.uyelikturu, required this.onLogout,required this.isletmebilgi}) : super(key: key);

  @override
  _DigerPageState createState() => _DigerPageState();
}

class _DigerPageState extends State<DigerPage> {


  void initState() {
    super.initState();
    setState(() {
      _kullanici = widget.kullanici;
      kullanicirolu = int.parse(widget.kullanici.yetkili_olunan_isletmeler.firstWhere((element) => element["salon_id"].toString()==widget.isletmebilgi["id"].toString())["role_id"].toString());


    });
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      resizeToAvoidBottomInset: false,body: Menu(isletmebilgi:widget.isletmebilgi,kullanici: widget.kullanici,uyelikturu: widget.uyelikturu,onLogout: widget.onLogout),

    );
  }
}
class Menu extends StatefulWidget{
  final Kullanici kullanici;
  final int uyelikturu;
  final dynamic isletmebilgi;
  final VoidCallback onLogout;
  Menu({Key? key,required this.kullanici,required this.uyelikturu,  required this.onLogout,required this.isletmebilgi}) : super(key: key);


  @override
  _MenuState createState() => _MenuState();



}
class _MenuState extends State<Menu> {
  void userinfo() async{}
  void initState() {
    super.initState();



  }
  void _logout(BuildContext context) async {
    try {
      bool? confirmLogout = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Çıkış Yap'),
          content: Text('Çıkış yapmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Hayır'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Evet'),
            ),
          ],
        ),
      );

      if (confirmLogout == true) {
        // Reset the selectedIndex state before logging out
        Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
        Provider.of<IndexedStackState>(context, listen: false).resetSelectedIndex();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('user');
        await prefs.remove('token');
        await prefs.remove('user_type');

        // Call the callback to update the login state
        //widget.onLogout();

        // Replace the current route with the login page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => OnBoardingPage()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
      );
    }
  }
  TextStyle headingStyle = const TextStyle(
      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.purple);





  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => BackRoutes.onWillPop(context,DashBoard(isletmebilgi: widget.isletmebilgi, kullanici: _kullanici,),true),
      child:    Scaffold(
        resizeToAvoidBottomInset: false,

        appBar: AppBar(
          title: Text(
            'Menü',
            style: TextStyle(color: Colors.black),
          ),
          toolbarHeight: 60,
          actions: [
            if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 100, // <-- Your width
                  child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
                ),
              ),
            if (widget.kullanici.yetkili_olunan_isletmeler.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Container(
                  width: 100,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.purple, // Purple frame color
                    borderRadius: BorderRadius.circular(10), // Slightly rounded corners
                  ),
                  padding: EdgeInsets.all(1.5),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => (widget.kullanici.yetkili_olunan_isletmeler.length > 1)
                              ? SubeSecimi(
                            kullanici: widget.kullanici,
                            scaffoldMessengerKey: scaffoldMessengerKey,
                          )
                              : BottomNavigationExample(
                            scaffoldMessengerKey: scaffoldMessengerKey,
                            isletmebilgi: widget.kullanici.yetkili_olunan_isletmeler[0]['salonlar'],
                            kullanici: widget.kullanici,
                            uyelikturu: int.parse(
                              widget.kullanici.yetkili_olunan_isletmeler[0]['salonlar']['uyelik_turu']
                                  .toString(),
                            ),
                          ),
                        ),
                            (route) => false,
                      ).then((_) {
                        Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Button's background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Match the frame's border radius
                      ),
                    ),
                    child: Text(
                      "Şube Seç",
                      style: TextStyle(fontSize: 15, color: Colors.purple, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
          backgroundColor: Colors.white,
        ),

        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(widget.uyelikturu > 2 && kullanicirolu < 5)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Define the action for button press here
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: AsistanimPage(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.task_outlined, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Asistanım",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),

                if(widget.uyelikturu > 2 && kullanicirolu < 5)
                  SizedBox(height: 10,),
                /*ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    elevation: 2,
                  ),
                  onPressed: () {
                    // Define the action for button press here
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: Duration(milliseconds: 500),
                        child: AjandaNotlar(isletmebilgi: widget.isletmebilgi),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.view_agenda_outlined, color: Colors.deepPurple),
                      SizedBox(width: 12),
                      Text(
                        "Ajanda",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                    ],
                  ),
                ),
                SizedBox(height: 10,),*/
                if(widget.uyelikturu > 2 && kullanicirolu < 5)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      String personelid = "";
                      if(kullanicirolu == 5)
                      {
                        widget.kullanici.yetkili_olunan_isletmeler.forEach((element) {
                          log("salon id : "+widget.isletmebilgi["id"].toString());
                          if(element["salon_id"].toString()==widget.isletmebilgi["id"].toString())
                            personelid = element["id"].toString();
                        });
                      }
                      Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.rightToLeft,
                            duration: Duration(milliseconds: 500),
                            child: RandevularMenu(kullanicirolu: kullanicirolu, isletmebilgi: widget.isletmebilgi,personelid: personelid,cihazid: "",personel_adi: "",cihaz_adi: "",)
                        ),
                      );
                    },
                    child: Row(


                      children: [
                        Icon(Icons.calendar_month, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Randevular",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),

                /*if(widget.uyelikturu > 2 && kullanicirolu < 5)
                  SizedBox(height: 10,),
                if(widget.uyelikturu > 2 && kullanicirolu < 5)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Define the action for button press here
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: Etkinlikler(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.notes, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Etkinlikler",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),


                if(widget.uyelikturu > 2 && kullanicirolu < 5)
                  SizedBox(height: 10,),
                if(widget.uyelikturu > 2 && kullanicirolu < 5)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Define the action for button press here
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: Kampanyalar(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.campaign_outlined, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Reklam Yönetimi",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),*/


                if(widget.uyelikturu > 2 && kullanicirolu < 5)
                  SizedBox(height: 10,),
                if(widget.uyelikturu > 1 && kullanicirolu < 5)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Define the action for button press here
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: ArsivYonetimiPage(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Arşiv Yönetimi",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),


                if(widget.uyelikturu > 1)
                  SizedBox(height: 10,),
                if(widget.uyelikturu > 2)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Define the action for button press here
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: OnGorusmeler(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.insert_comment_outlined, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Ön Görüşmeler",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),


                if(widget.uyelikturu > 2)
                  SizedBox(height: 10,),
                kullanicirolu < 5 ?
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    elevation: 2,
                  ),
                  onPressed: () {
                    // Define the action for button press here
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: Duration(milliseconds: 500),
                        child: MusteriListesi(isletmebilgi: widget.isletmebilgi),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.supervised_user_circle_outlined, color: Colors.deepPurple),
                      SizedBox(width: 12),
                      Text(
                        "Müşteriler",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                    ],
                  ),
                ): SizedBox.shrink(),



                kullanicirolu < 5 ?  SizedBox(height: 10,): SizedBox.shrink(),
                if(widget.uyelikturu > 1 && kullanicirolu < 5)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Define the action for button press here
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: Urunler(kullanici: widget.kullanici,isletmebilgi: widget.isletmebilgi,),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.sell_outlined, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Stok Yönetimi",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),


                if(widget.uyelikturu > 1  && kullanicirolu < 5)
                  SizedBox(height: 10,),
                if(widget.uyelikturu > 1  && kullanicirolu < 5)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Define the action for button press here
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: PaketSatislari(kullanici: widget.kullanici,isletmebilgi: widget.isletmebilgi,),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.grid_on, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Paket Yönetimi",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),


                if(widget.uyelikturu > 1  && kullanicirolu < 5)
                  SizedBox(height: 10,),
                if(widget.uyelikturu > 1  && kullanicirolu < 5)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Define the action for button press here
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: SeansTakibi(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.checklist_outlined, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Seans Takibi",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),


                /*if(widget.uyelikturu > 1  && kullanicirolu < 5)
                  SizedBox(height: 10,),
                if(widget.uyelikturu > 2  && kullanicirolu < 5)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Define the action for button press here
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: SenetListesi(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.note, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Senetler",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),
                */
                if(widget.uyelikturu > 2  && kullanicirolu < 5)
                  SizedBox(height: 10,),
                if(widget.uyelikturu > 1 && kullanicirolu<4 )
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Define the action for button press here
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: KasaRaporu(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.money_outlined, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Kasa Raporu",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),


                if(widget.uyelikturu > 1&& kullanicirolu<4)
                  SizedBox(height: 10,),
                if(widget.uyelikturu > 1&& kullanicirolu<5)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Define the action for button press here
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: Masraflar(odeme_yontemi: '', tarih: '',isletmebilgi: widget.isletmebilgi,),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.file_upload_outlined, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Masraflar",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                      ],
                    ),
                  ),


                if(widget.uyelikturu > 1&& kullanicirolu<5)
                  SizedBox(height: 10,),
                /*ListTile(
                  leading: Icon(Icons.file_download_outlined),
                  title: Text("Alacaklar"),
                  trailing: Icon(Icons.keyboard_arrow_right),
                  onTap: () {Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Alacaklar()),
                  );},

                ),
                const Divider(),*/
                kullanicirolu < 4 ?
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    elevation: 2,
                  ),
                  onPressed: () {
                    // Define the action for button press here
                    Navigator.push(
                      context,
                      PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child: Ayarlar(isletmebilgi: widget.isletmebilgi,)
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.settings_sharp, color: Colors.deepPurple),
                      SizedBox(width: 12),
                      Text(
                        "Ayarlar",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                    ],
                  ),
                )
                    : SizedBox.shrink(),

                kullanicirolu < 4 ? SizedBox(height: 10,): SizedBox.shrink(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Hesap", style: headingStyle),
                  ],
                ),


                SizedBox(height: 10,),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.purple, backgroundColor: Colors.white, // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    elevation: 2,
                  ),
                  onPressed: () {
                    // Define the action for button press here
                    Navigator.push(
                      context,
                      PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 500),
                          child:  ProfilBilgileri(kullanici: _kullanici)
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.deepPurple),
                      SizedBox(width: 12),
                      Text(
                        "Profil Bilgileri",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                    ],
                  ),
                ),

                SizedBox(height: 10,),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.deepPurple, backgroundColor: Colors.white, // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    elevation: 2,
                  ),
                  onPressed:() { _logout(context);},
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.deepPurple),
                      SizedBox(width: 12),
                      Text(
                        "Çıkış Yap",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),

    );
  }
}