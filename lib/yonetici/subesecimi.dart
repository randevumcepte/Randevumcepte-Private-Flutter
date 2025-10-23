import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/basic_bottom_nav_bar.dart';

import 'package:randevu_sistem/yonetici/dashboard/scaffold_layout_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Backend/backend.dart';
import '../Frontend/indexedstack.dart';
import '../Models/user.dart';
import 'dashboard/home_screen.dart';

class SubeSecimi extends StatefulWidget {
  final Kullanici kullanici;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  SubeSecimi({Key? key, required this.kullanici,required this.scaffoldMessengerKey}) : super(key: key);
  @override
  _SubeSecimiState createState() => _SubeSecimiState();
}

class _SubeSecimiState extends State<SubeSecimi> {
  ScrollController _scrollController = ScrollController();
  bool _showAppBar = false;



  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        // Scrolling down
        if (!_showAppBar) {
          setState(() {
            _showAppBar = true;
          });
        }
      } else {
        // Scrolling up
        if (_showAppBar) {
          setState(() {
            _showAppBar = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  bool _isAllDay = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return  Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 230,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage('images/randevumcepte.jpg'), fit: BoxFit.fill),
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20))),
                    ),
                    Container(
                      child: Column(
                        children: [

                          Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Column(
                              children: [

                                Center(
                                  child: Text('Hoşgeldiniz',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color:Colors.white),),
                                ),
                                Center(
                                  child: Text(widget.kullanici.name,style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color:Colors.white)),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [Container(padding: EdgeInsets.all(20)),],
                          ),

                          Container(
                            decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    topRight: Radius.circular(15),
                                    bottomLeft: Radius.circular(15),
                                    bottomRight: Radius.circular(15)),
                                color: Colors.white),
                            width: width * 0.9,
                            height: 140,
                            padding: EdgeInsets.only(top: 0),
                            child: Column(
                              children: [
                                Image.asset('images/aronshine-land.png', height: 140,),


                              ],
                            ),
                          ),
                          SizedBox(height: 20,),
                          Text('İşletme Seçiniz',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                  fontSize: 25)),
                          SizedBox(height: 10,),
                          SingleChildScrollView(
                            child: Container(
                              decoration:  BoxDecoration(

                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20)),
                                   color: Colors.grey[200],
                                border: Border.all(
                                  color: Colors.black12, // Color of the border
                                  width: 1.0, // Width of the border
                                ),


                              ),

                              padding: EdgeInsets.only(left: 40,right: 40,top: 25),
                              width: MediaQuery.of(context).size.width*0.9,
                              height: MediaQuery.of(context).size.height * 0.38,
                              child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1, // Number of columns
                                  mainAxisSpacing: 15.0, // Spacing between rows
                                  crossAxisSpacing: 10.0, // Spacing between columns
                                  childAspectRatio: 5.5, // Aspect ratio of the items
                                ),

                                itemCount: widget.kullanici.yetkili_olunan_isletmeler.length,
                                itemBuilder: (context, index) {
                                  return ElevatedButton(
                                    onPressed: () async{
                                      SharedPreferences localStorage = await SharedPreferences.getInstance();
                                      seciliIsletmeNoKaydet(
                                          widget.kullanici.yetkili_olunan_isletmeler[index]['salon_id'].toString(),
                                          widget.kullanici.yetkili_olunan_isletmeler[index]['salonlar']['salon_adi']);

                                      bildirimkimligiekleguncelle(widget.kullanici.id,widget.kullanici.yetkili_olunan_isletmeler[index]['salon_id'].toString(),"1",localStorage.getString('onesignal_player_id')??"");
                                      Navigator.of(context).pop();

                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          new MaterialPageRoute(
                                              builder: (context) => new BottomNavigationExample(
                                                scaffoldMessengerKey: widget.scaffoldMessengerKey,
                                                kullanici: widget.kullanici,
                                                isletmebilgi: widget.kullanici.yetkili_olunan_isletmeler[index]['salonlar'],
                                                uyelikturu: int.parse(widget.kullanici
                                                    .yetkili_olunan_isletmeler[index]['salonlar']['uyelik_turu'].toString()),)),
                                            (route) => false,
                                      ).then((_) {
                                        // Reset IndexedStackState to 0 after logging in
                                        Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      shadowColor: Colors.black54,
                                      elevation: 6.0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Space between the image and text
                                        Text(widget.kullanici.yetkili_olunan_isletmeler[index]['salonlar']['salon_adi'],
                                            style: TextStyle(color: Colors.deepPurple, fontSize: 20)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Divider(),
                          SizedBox(height: 10,),
                          Center(
                            child: Text('VEYA'),
                          ),
                          Container(
                            padding: EdgeInsets.all(10),
                            child: ElevatedButton(
                              onPressed: () {
                                logout(context);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                                backgroundColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'images/logout.png', // Path to your image
                                    height: 30.0, // Height of the image
                                  ),
                                  SizedBox(width: 8.0), // Space between the image and text
                                  Text('ÇIKIŞ YAPIN',
                                      style: TextStyle(color: Colors.deepPurple, fontSize: 18)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void seciliIsletmeNoKaydet(String sube, String isletmeadi) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    localStorage.remove('sube');
    localStorage.setString('sube', sube);
    localStorage.remove('isletmeadi');
    localStorage.setString('isletmeadi', isletmeadi);
  }

  Widget _appBar(BuildContext context, ColorAnimated colorAnimated) {
    return AppBar(
      elevation: 100,
      title: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [

            Center(
              child: Text('Hoşgeldiniz'),
            ),
            Center(
              child: Text(widget.kullanici.name),
            ),
          ],
        ),
      ),
      toolbarHeight: 300,
      backgroundColor: colorAnimated.background,
    );
  }
}

class HexColor extends Color {
  static int _getColor(String hex) {
    String formattedHex = "FF" + hex.toUpperCase().replaceAll("#", "");
    return int.parse(formattedHex, radix: 16);
  }

  HexColor(final String hex) : super(_getColor(hex));
}
