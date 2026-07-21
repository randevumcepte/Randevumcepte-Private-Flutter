
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:randevu_sistem/musteripaneli/randevularim/randevularim.dart';




import 'package:shared_preferences/shared_preferences.dart';


import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/indexedstack.dart';
import 'package:randevu_sistem/Frontend/lisans_uyari.dart';
import 'package:randevu_sistem/Login Sayfası/checklogin.dart';
import 'package:randevu_sistem/Login Sayfası/tanitim.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/services/notification_navigation_bus.dart';
import 'package:randevu_sistem/services/notification_service.dart';
import 'package:randevu_sistem/services/notification_status_banner.dart';
import 'anasayfa/anasayfa.dart';
import 'anasayfa/carkifelek.dart';
import 'anasayfa/musteribildirimleri/musteribildirimleri.dart';
import 'anasayfa/raporlar/seanslar.dart';
import 'menu/indirimler.dart';
import 'menu/musterimenu.dart';
import 'menu/siparislerim.dart';





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

class _BottomNavigationExampleState extends State<MusteriAltBar> with WidgetsBindingObserver {
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationNavigationBus.current.addListener(_handleNotificationIntent);
    // Cold-start: bus'ta onceden konmus intent varsa altbar mount olduktan
    // sonra tuket.
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleNotificationIntent());
  }

  @override
  void dispose() {
    NotificationNavigationBus.current.removeListener(_handleNotificationIntent);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App foreground'a geri donduyse token alma denemesini tazele.
      NotificationService.instance.onAppResumed();
    }
  }

  void _handleNotificationIntent() {
    final intent = NotificationNavigationBus.current.value;
    if (intent == null || !mounted) return;
    NotificationNavigationBus.consume();

    switch (intent.target) {
      case NotificationIntent.wheel:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => WheelPage(md: widget.musteriId, isletmebilgi: widget.isletmebilgi),
        ));
        break;
      case NotificationIntent.appointments:
        setState(() => _selectedTab = 1);
        break;
      case NotificationIntent.sessions:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SeanslarDashboard(
            isletmebilgi: widget.isletmebilgi,
            md: widget.musteriId,
          ),
        ));
        break;
      case NotificationIntent.purchases:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MusteriPaneliAdiayonlari(
            kullanici: widget.musteriId,
            isletmebilgi: widget.isletmebilgi,
          ),
        ));
        break;
      case NotificationIntent.discounts:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => KazanilanIndirimlerPage(md: widget.musteriId, isletmebilgi: widget.isletmebilgi),
        ));
        break;
      case NotificationIntent.notifications:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MusteriBildirimlerScreen(md: widget.musteriId, isletmebilgi: widget.isletmebilgi),
        ));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Secili isletmenin lisansi bittiyse musteriye iletisim/adres ekrani goster.
    if (lisansBittiMi(
        widget.isletmebilgi is Map ? widget.isletmebilgi['uyelik_bitis_tarihi'] : null)) {
      return LisansBittiEkrani(isletmebilgi: widget.isletmebilgi, isMusteri: true);
    }
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
        body: Column(
          children: [
            const NotificationStatusBanner(),
            Expanded(child: _pages[_selectedTab]),
          ],
        ),

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
    await Yetki.temizle();

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

import 'package:randevu_sistem/Frontend/indexedstack.dart';
import 'package:randevu_sistem/Login Sayfası/tanitim.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
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

    // Bildirim tıklamasından gelen yönlendirme niyetlerini dinle.
    NotificationNavigationBus.current.addListener(_handleNotificationIntent);
    // Cold-start: bus'ta önceden konmuş bir intent varsa altbar tam mount
    // olduktan sonra tüket.
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleNotificationIntent());
  }

  void _handleNotificationIntent() {
    final intent = NotificationNavigationBus.current.value;
    if (intent == null || !mounted) return;
    NotificationNavigationBus.consume();

    switch (intent.target) {
      case NotificationIntent.wheel:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => WheelPage(md: widget.musteriId, isletmebilgi: widget.isletmebilgi),
        ));
        break;
      case NotificationIntent.appointments:
        try {
          Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(1);
        } catch (_) {}
        setState(() => _selectedTab = 1);
        break;
      case NotificationIntent.discounts:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => KazanilanIndirimlerPage(md: widget.musteriId, isletmebilgi: widget.isletmebilgi),
        ));
        break;
      case NotificationIntent.notifications:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MusteriBildirimlerScreen(md: widget.musteriId, isletmebilgi: widget.isletmebilgi),
        ));
        break;
    }
  }
  bool _showBottomNavigationBar = true;


  @override
  void dispose() {
    //keyboardSubscription.cancel();
    NotificationNavigationBus.current.removeListener(_handleNotificationIntent);

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