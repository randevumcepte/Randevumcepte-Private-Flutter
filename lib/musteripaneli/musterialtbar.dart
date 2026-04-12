
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:randevu_sistem/musteripaneli/randevularim/randevularim.dart';




import 'package:shared_preferences/shared_preferences.dart';


import '../Frontend/indexedstack.dart';
import '../Login Sayfası/checklogin.dart';
import '../Login Sayfası/tanitim.dart';
import '../Models/musteri_danisanlar.dart';
import 'anasayfa/anasayfa.dart';
import 'menu/musterimenu.dart';





class MusteriAltBar extends StatefulWidget {
  final MusteriDanisan musteriId;
  final dynamic isletmebilgi;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const MusteriAltBar({
    Key? key,
    required this.musteriId,
    required this.isletmebilgi,
    required this.scaffoldMessengerKey,
  }) : super(key: key);

  @override
  _BottomNavigationExampleState createState() => _BottomNavigationExampleState();
}

class _BottomNavigationExampleState extends State<MusteriAltBar> {
  int _selectedTab = 0;
  bool _isKeyboardVisible = false;

  // SAYFALARI DİNAMİK GETTER YAPIYORUZ
  List<Widget> get _pages => [
    MusteriAnsayfa(
      kullanicirolu: 0,
      md: widget.musteriId,
      onLogout: _handleLogout,
      isletmebilgi: widget.isletmebilgi,
    ),
    MusteriRandevulari(
      md: widget.musteriId,
      isletmebilgi: widget.isletmebilgi,
      geriButonu: false,
    ),
    MenuPage(
      onLogout: _handleLogout,
      md: widget.musteriId,
      isletmebilgi: widget.isletmebilgi,
    ),
  ];

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

        bottomNavigationBar: _isKeyboardVisible
            ? const SizedBox.shrink()
            : BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (index) {
            setState(() => _selectedTab = index);
          },
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.black26,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: "Ana Sayfa"),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                label: "Randevularım"),
            BottomNavigationBarItem(
                icon: Icon(Icons.checklist_outlined), label: "Menü"),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => CheckAuth()),
          (route) => false,
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/musteripaneli/randevularim/randevularim.dart';

import 'package:randevu_sistem/yeni/yeni_page.dart';
import 'package:randevu_sistem/yonetici/adisyonlar/adisyonpage.dart';
import 'package:randevu_sistem/yonetici/dashboard/home_screen.dart';
import 'package:randevu_sistem/yonetici/diger/diger_page.dart';
import 'package:randevu_sistem/yonetici/randevular/randevu_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Frontend/indexedstack.dart';
import '../Login Sayfası/tanitim.dart';
import '../Models/musteri_danisanlar.dart';
import 'anasayfa/anasayfa.dart';
import 'anasayfa/raporlar/randevularim.dart';
import 'avantajlar/avantajlarim.dart';
import 'menu/musterimenu.dart';

class MusteriAltBar extends StatefulWidget {
  final MusteriDanisan musteriId;
  final dynamic isletmebilgi;
  const MusteriAltBar({Key? key, required this.musteriId,required this.isletmebilgi}) : super(key: key);

  @override
  _MusteriAltBarState createState() =>
      _MusteriAltBarState();
}

class _MusteriAltBarState  extends State<MusteriAltBar> {
  int _selectedTab = 0;
  bool _isKeyboardVisible = false;
  void _selectScreen(int index) {
    setState(() {
      _selectedTab = index;
    });
  }
  late List<Widget> _pages;
  final List<bool> _isPageBuilt = [true, false, false];

  @override
  void initState(){
    super.initState();
    _isPageBuilt.setAll(0, [true, false, false]);
    _pages=[
      MusteriAnsayfa(md: widget.musteriId,onLogout: _handleLogout,isletmebilgi: widget.isletmebilgi,),
      MusteriRandevulari(md: widget.musteriId,isletmebilgi: widget.isletmebilgi,),
      MenuPage(onLogout: _handleLogout, md: widget.musteriId,)

    ];

  }
  bool _showBottomNavigationBar = true;


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
  void _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');

    setState(() {
      _selectedTab = 0;
      _isPageBuilt.setAll(0, [true, false, false]); // Reset built status
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
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,s
      appBar: null,
      body: IndexedStack(
        index: _selectedTab ,
        children: _pages,

      ),
      bottomNavigationBar: (_isKeyboardVisible) ? SizedBox.shrink() : Consumer<IndexedStackState>(
          builder: (context, state, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              BottomNavigationBar(
                currentIndex: _selectedTab,
                enableFeedback: false,

                onTap: _selectScreen,s
                selectedItemColor: Colors.deepPurple,
                unselectedItemColor: Colors.black26,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 10,
                unselectedFontSize: 10,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Ana Sayfa"),
                  BottomNavigationBarItem(icon:Icon(Icons.calendar_month_outlined), label: "Randevularım"),
                  BottomNavigationBarItem(icon: Icon(Icons.checklist_outlined), label: "Menü"),


                ],
              ),
            ],
          );
        }
      ),
    );
  }
}*/