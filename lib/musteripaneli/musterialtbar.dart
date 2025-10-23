
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';

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
  const MusteriAltBar({Key? key, required this.musteriId,required this.isletmebilgi,required this.scaffoldMessengerKey}) : super(key: key);

  @override
  _BottomNavigationExampleState createState() => _BottomNavigationExampleState();
}

class _BottomNavigationExampleState extends State<MusteriAltBar>   {

  late OverlayEntry _dialPadOverlayEntry;
  late StreamSubscription<bool> keyboardSubscription;
  bool _isKeyboardVisible = false;
  bool _showBottomNavigationBar = true;
  int _selectedTab = 0;
  late int kullanicirolu;
  late String dahili;
  late String seciliisletme;
  late int uyelikturu;
  late List<Widget> _pages;
  final List<bool> _isPageBuilt = [true, false, false, false, false];
  bool loggedin=true;
  @override
  void initState() {
    super.initState();
    _isPageBuilt.setAll(0, [true, false, false, false, false]);

    _pages = [
      MusteriAnsayfa(md: widget.musteriId,onLogout: _handleLogout,isletmebilgi: widget.isletmebilgi,),
      MusteriRandevulari(md: widget.musteriId,isletmebilgi: widget.isletmebilgi,geriButonu: false,),
      MenuPage(onLogout: _handleLogout, md: widget.musteriId,isletmebilgi: widget.isletmebilgi,)

    ];


  }
  void _selectScreen(int index) {
    setState(() {
      _selectedTab = index;

    });
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
      MaterialPageRoute(builder: (context) => CheckAuth()),
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
    var bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,

      body: _pages[_selectedTab], // Render the selected page based on the _selectedTab

      bottomNavigationBar: (_isKeyboardVisible) ? SizedBox.shrink() : Consumer<IndexedStackState>(
          builder: (context, state, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                BottomNavigationBar(
                  currentIndex: _selectedTab,
                  enableFeedback: false,
                  onTap: (index) {
                    _selectScreen(index);
                  },
                  selectedItemColor: Colors.deepPurple,
                  unselectedItemColor: Colors.black26,
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  items: [
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