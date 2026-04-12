
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:randevu_sistem/yeni/yeni_page.dart';
import 'package:randevu_sistem/yonetici/adisyonlar/adisyonpage.dart';

import 'package:randevu_sistem/yonetici/dashboard/home_screen.dart';
import 'package:randevu_sistem/yonetici/diger/diger_page.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ajanda/ajanda.dart';
import 'package:randevu_sistem/yonetici/diger/menu/arsiv/arsivyonetimipage.dart';
import 'package:randevu_sistem/yonetici/randevular/randevu_page.dart';
import 'package:randevu_sistem/yonetici/randevular/takvim.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ongorusmeler/ongorusmeler.dart';
import 'package:randevu_sistem/yonetici/santral/arama.dart';
import 'package:randevu_sistem/yonetici/santral/santralraporlari.dart';

import 'package:randevu_sistem/yonetici/subesecimi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syncfusion_localizations/syncfusion_localizations.dart';

import 'Backend/backend.dart';
import 'Frontend/altyuvarlakmenu.dart';
import 'Frontend/dialpad.dart';
import 'Frontend/indexedstack.dart';
import 'Login Sayfası/checklogin.dart';
import 'Login Sayfası/tanitim.dart';
import 'Models/musteri_danisanlar.dart';
import 'Models/user.dart';




class BottomNavigationExample extends StatefulWidget {

  final Kullanici kullanici;
  final int uyelikturu;
  final dynamic isletmebilgi;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  const BottomNavigationExample({Key? key, required this.kullanici,required this.uyelikturu,required this.isletmebilgi,required this.scaffoldMessengerKey}) : super(key: key);

  @override
  _BottomNavigationExampleState createState() => _BottomNavigationExampleState();
}

class _BottomNavigationExampleState extends State<BottomNavigationExample>   {
  final DialPadManager dialPadManager = DialPadManager();
  late OverlayEntry _dialPadOverlayEntry;
  late StreamSubscription<bool> keyboardSubscription;
  bool _isKeyboardVisible = false;

  bool _showBottomNavigationBar = true;
  int _selectedTab = 0;
  late int kullanicirolu;
  late String dahili;
  late String dahiliSifre;
  late String seciliisletme;
  late String personelId;
  late int uyelikturu;
  late List<Widget> _pages;
  final List<bool> _isPageBuilt = [true, false, false, false, false];
  bool loggedin=true;
  @override
  void initState() {
    super.initState();
    _isPageBuilt.setAll(0, [true, false, false, false, false]);
    kullanicirolu = int.parse(widget.kullanici.yetkili_olunan_isletmeler.firstWhere((element) => element["salon_id"].toString() == widget.isletmebilgi["id"].toString())["role_id"].toString());
    dahili =  widget.kullanici.yetkili_olunan_isletmeler.firstWhere((element) => element["salon_id"].toString() == widget.isletmebilgi["id"].toString())["dahili_no"].toString();
    dahiliSifre = widget.kullanici.yetkili_olunan_isletmeler.firstWhere((element) => element["salon_id"].toString() == widget.isletmebilgi["id"].toString())["dahili_sifre"].toString();
    personelId = widget.kullanici.yetkili_olunan_isletmeler.firstWhere((element) => element["salon_id"].toString() == widget.isletmebilgi["id"].toString())["id"].toString();
    _pages = [
      DashBoard(kullanicirolu: kullanicirolu, kullanici: widget.kullanici, isletmebilgi: widget.isletmebilgi),
      Takvim(selectedTab: _selectedTab, isletmebilgi: widget.isletmebilgi,kullanici:widget.kullanici,kullanicirolu: kullanicirolu,),
      (widget.uyelikturu > 2 && kullanicirolu < 5) ? CDRRaporlari(kullanicirolu: kullanicirolu, isletmebilgi: widget.isletmebilgi,dialPadManager: dialPadManager,scaffoldMessengerKey: widget.scaffoldMessengerKey,kullanici: widget.kullanici) : AjandaNotlar(isletmebilgi: widget.isletmebilgi),
      (widget.uyelikturu > 1 ) ? AdisyonlarPage(kullanicirolu:kullanicirolu,kullanici: widget.kullanici, isletmebilgi: widget.isletmebilgi,geriGitBtn: false,) : OnGorusmeler(kullanicirolu: kullanicirolu, isletmebilgi: widget.isletmebilgi),
      DigerPage(kullanici: widget.kullanici, uyelikturu: widget.uyelikturu, onLogout: _handleLogout, isletmebilgi: widget.isletmebilgi),

    ];
    log("dahili numara: "+dahili);
    if(dahili != null){

      setupVoipAndFcmTokenListener();
      /*_initializeSiprix();
      setupVoipTokenListener();
      _dahiliHesabiniEkle(dahili.toString(),dahiliSifre.toString());
      context.read<AppCallsModel>().onResolveContactName = arayanBilgiVer;*/


      WidgetsBinding.instance.addPostFrameCallback((_) {
        dialPadManager.showDialPad(context,false,"",widget.kullanici,personelId);
      });

    }


  }
  void setupVoipAndFcmTokenListener() {
    // --- iOS VoIP token dinleyici ---
    if (Platform.isIOS) {
      final voipChannel = const MethodChannel('com.randevumcepte.voiptoken');
      voipChannel.setMethodCallHandler((call) async {
        log('call method : ' + call.method);
        if (call.method == 'voipToken') {
          final String token = call.arguments ?? '';
          print('VoIP token from native: $token');
          logyaz(200, 'ios voip token ' + token);

          // 1) Save locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('ios_voip_token', token);

          // 2) Send to backend
          await saveVoipTokenToBackend(token, widget.kullanici.id.toString());

          // 3) Eğer SIP SDK bu token’a ihtiyaç duyuyorsa register/addAccount çağrılarını token geldikten sonra yap
        }
      });
    }
    if(Platform.isAndroid)
    {
      //fcm token dinleyici
      FirebaseMessaging.instance.getToken().then((token) async {
        if (token != null) {
          print('FCM token: $token');
          logyaz(200, 'FCM token ' + token);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', token);

          await saveVoipTokenToBackend(token, widget.kullanici.id.toString());
        }
      });

      // FCM token değişirse otomatik güncelle
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        print('FCM token refreshed: $token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);

        await saveVoipTokenToBackend(token, widget.kullanici.id.toString());
      });
    }


  }

  void _selectScreen(int index) {
    setState(() {
      _selectedTab = index;

    });
  }

  void showDahiliHataBar(dynamic err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
  void showForegroundHata(dynamic err){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
  void _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');

    setState(() {
      _selectedTab = 0;
      _isPageBuilt.setAll(0, [true, false, false, false, false]); // Reset built status
      _showBottomNavigationBar = false;
    });

    // Navigate to login page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => OnBoardingPage()),
          (route) => false,
    );
  }
  @override
  void dispose() {
    //keyboardSubscription.cancel();

    super.dispose();
  }
  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset == 0.0 && _isKeyboardVisible) {
      // Keyboard is fully hidden
      setState(() {
        _isKeyboardVisible = false;
      });
    } else if (bottomInset > 0.0 && !_isKeyboardVisible) {
      // Keyboard is visible
      setState(() {
        _isKeyboardVisible = true;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedTab != 0) {
          setState(() {
            _selectedTab = 0;
          });
          return false;
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Uygulamadan çıkış"),
              content: Text("Uygulamadan çıkmak istediğinize emin misiniz?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("İptal"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    SystemNavigator.pop(); // Android uygulamasını kapatır
                  },
                  child: Text("Çıkış"),
                ),
              ],
            ),
          );
          return false; // dialog açıldı, WillPopScope async callback false döndürür
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: _pages[_selectedTab],
        bottomNavigationBar: (_isKeyboardVisible)
            ? SizedBox.shrink()
            : Consumer<IndexedStackState>(
          builder: (context, state, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                BottomNavigationBar(
                  currentIndex: _selectedTab,
                  onTap: _selectScreen,
                  selectedItemColor: Colors.deepPurple,
                  unselectedItemColor: Colors.black26,
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  items: [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined), label: "Özet"),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.calendar_month_outlined),
                        label: "Randevular"),
                    widget.uyelikturu > 2 && kullanicirolu < 5
                        ? BottomNavigationBarItem(
                        icon: Icon(Icons.phone_in_talk), label: "")
                        : BottomNavigationBarItem(
                        icon: Icon(Icons.view_agenda_outlined),
                        label: "Ajanda"),
                    widget.uyelikturu > 1
                        ? BottomNavigationBarItem(
                        icon: Icon(Icons.copy_all_sharp),
                        label: "Satış Takibi")
                        : BottomNavigationBarItem(
                        icon: Icon(Icons.insert_comment_outlined),
                        label: "Ön Görüşmeler"),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.more_vert), label: "Menü"),
                  ],
                ),
                if (widget.uyelikturu > 2 && kullanicirolu < 5)
                  Positioned(
                    top: -20,
                    left: MediaQuery.of(context).size.width / 2 - 30,
                    child: GestureDetector(
                      onTap: () => _selectScreen(2),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepPurple,
                          border:
                          Border.all(color: Colors.white, width: 4),
                        ),
                        child:
                        Icon(Icons.phone, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }




}