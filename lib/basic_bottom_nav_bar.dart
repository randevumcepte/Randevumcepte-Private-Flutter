import 'dart:async';
import 'dart:convert';
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
import 'package:randevu_sistem/yonetici/adisyonlar/satislar/yenisatisyap.dart';

import 'package:randevu_sistem/yonetici/dashboard/home_screen.dart';
import 'package:randevu_sistem/yonetici/diger/diger_page.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ajanda/ajanda.dart';
import 'package:randevu_sistem/yonetici/diger/menu/arsiv/arsivyonetimipage.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kasa/masrafekle.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/yeni_musteri.dart';
import 'package:randevu_sistem/yonetici/randevular/appointment-editor.dart';
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
import 'Frontend/sfdatatable.dart';
import 'Login Sayfası/checklogin.dart';
import 'Login Sayfası/tanitim.dart';
import 'Models/masrafkategorileri.dart';
import 'Models/musteri_danisanlar.dart';
import 'Models/personel.dart';
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
  late GiderDataSource _giderDataGridSource;

  late StreamSubscription<bool> keyboardSubscription;
  bool _isKeyboardVisible = false;

  bool _showBottomNavigationBar = true;
  int _selectedTab = 0;
  late int kullanicirolu;
  late String dahili;
  late String dahiliSifre;

  late String personelId;
  late int uyelikturu;
  late List<Widget> _pages;
  final List<bool> _isPageBuilt = [true, false, false, false, false];
  bool loggedin=true;
  bool giderlerHazir = false;

  // Yeni eklenen değişkenler
  OverlayEntry? _menuOverlayEntry;
  bool _isMenuOpen = false;

  // Animasyon için
  AnimationController? _animationController;
  Animation<double>? _animation;
  late List<Personel>personelliste;
  late List<MasrafKategorisi>masrafkategoriliste;

  @override
  void initState()  {
    super.initState();
    giderleriGetir();
    _isPageBuilt.setAll(0, [true, false, false, false, false]);
    kullanicirolu = int.parse(widget.kullanici.yetkili_olunan_isletmeler.firstWhere((element) => element["salon_id"].toString() == widget.isletmebilgi["id"].toString())["role_id"].toString());
    dahili =  widget.kullanici.yetkili_olunan_isletmeler.firstWhere((element) => element["salon_id"].toString() == widget.isletmebilgi["id"].toString())["dahili_no_webrtc"].toString();
    dahiliSifre = widget.kullanici.yetkili_olunan_isletmeler.firstWhere((element) => element["salon_id"].toString() == widget.isletmebilgi["id"].toString())["dahili_sifre_webrtc"].toString();
    personelId = widget.kullanici.yetkili_olunan_isletmeler.firstWhere((element) => element["salon_id"].toString() == widget.isletmebilgi["id"].toString())["id"].toString();
    _pages = [
      DashBoard(kullanicirolu: kullanicirolu, kullanici: widget.kullanici, isletmebilgi: widget.isletmebilgi),
      Takvim(selectedTab: _selectedTab, isletmebilgi: widget.isletmebilgi,kullanici:widget.kullanici,kullanicirolu: kullanicirolu,),
      //YeniTakvim(),
      (widget.uyelikturu > 2 && kullanicirolu < 5) ? CDRRaporlari(kullanicirolu: kullanicirolu, isletmebilgi: widget.isletmebilgi,dialPadManager: dialPadManager,scaffoldMessengerKey: widget.scaffoldMessengerKey,kullanici: widget.kullanici) : AjandaNotlar(isletmebilgi: widget.isletmebilgi),
      (widget.uyelikturu > 1 ) ? AdisyonlarPage(kullanicirolu:kullanicirolu,kullanici: widget.kullanici, isletmebilgi: widget.isletmebilgi,geriGitBtn: false,) : OnGorusmeler(kullanicirolu: kullanicirolu, isletmebilgi: widget.isletmebilgi),
      DigerPage(scaffoldMessengerKey: widget.scaffoldMessengerKey, kullanici: widget.kullanici, uyelikturu: widget.uyelikturu, onLogout: _handleLogout, isletmebilgi: widget.isletmebilgi,dialpadManager: dialPadManager,),

    ];
    if(dahili != null){
      setupVoipAndFcmTokenListener();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        dialPadManager.showDialPad(context,false,"",widget.kullanici,personelId);
      });
    }
  }

  void giderleriGetir() async {

    personelliste = await personellistegetir(widget.isletmebilgi['id'].toString());
    masrafkategoriliste = await masrafkategorileri();

    _giderDataGridSource = GiderDataSource(
      isletmebilgi: widget.isletmebilgi,
      rowsPerPage: 10,
      salonid:widget.isletmebilgi['id'].toString(),
      context: context,
      odemeyontemi: '',
      tarih: '',
      harcayan: '',
      personelliste: personelliste,
      masrafkategoriliste: masrafkategoriliste,
    );

    setState(() {
      giderlerHazir = true;
    });
  }

  void setupVoipAndFcmTokenListener() {
    if (Platform.isIOS) {
      final voipChannel = const MethodChannel('com.randevumcepte.voiptoken');
      voipChannel.setMethodCallHandler((call) async {
        if (call.method == 'voipToken') {
          final String token = call.arguments ?? '';
          print('VoIP token from native: $token');
          logyaz(200, 'ios voip token ' + token);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('ios_voip_token', token);
          await saveVoipTokenToBackend(token, widget.kullanici.id.toString());
        }
      });
    }
    if(Platform.isAndroid)
    {
      FirebaseMessaging.instance.getToken().then((token) async {
        if (token != null) {
          print('FCM token: $token');
          logyaz(200, 'FCM token ' + token);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', token);
          await saveVoipTokenToBackend(token, widget.kullanici.id.toString());
        }
      });

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
      _isPageBuilt.setAll(0, [true, false, false, false, false]);
      _showBottomNavigationBar = false;
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => OnBoardingPage()),
          (route) => false,
    );
  }

  @override
  void dispose() {
    if (_isMenuOpen) {
      _hideMenu();
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset == 0.0 && _isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = false;
      });
    } else if (bottomInset > 0.0 && !_isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = true;
      });
    }
  }

// Modern menüyü göster - TABLET VE YATAY MOD İÇİN GÜNCELLENMİŞ
  // Modern menüyü göster - TABLET VE YATAY MOD İÇİN GÜNCELLENMİŞ
  // Modern menüyü göster - TABLET VE YATAY MOD İÇİN GÜNCELLENMİŞ
  void _showMenu(BuildContext context) {
    if (_isMenuOpen) return;

    _isMenuOpen = true;

    _menuOverlayEntry = OverlayEntry(
      builder: (context) {
        final bottomNavigationBarHeight = 60.0;
        final safeAreaBottom = MediaQuery.of(context).padding.bottom;
        final screenSize = MediaQuery.of(context).size;
        final bool isTablet = screenSize.width > 600;
        final bool isLandscape = screenSize.width > screenSize.height;

        // Menü genişliğini belirle
        double menuWidth;
        double horizontalMargin;
        int crossAxisCount;

        if (isLandscape) {
          // YATAY MOD - 4 sütun, daha küçük menü
          menuWidth = screenSize.width * 0.5; // Ekranın yarısı
          horizontalMargin = (screenSize.width - menuWidth) / 2;
          crossAxisCount = 4; // 4 sütun
        } else if (isTablet) {
          // DİKEY TABLET - 3 sütun
          menuWidth = screenSize.width * 0.6;
          horizontalMargin = (screenSize.width - menuWidth) / 2;
          crossAxisCount = 3;
        } else {
          // TELEFON - 2 veya 3 sütun
          menuWidth = screenSize.width - 50;
          horizontalMargin = 25;
          crossAxisCount = kullanicirolu == 5 ? 3 : 2;
        }

        return Positioned.fill(
          child: GestureDetector(
            onTap: _hideMenu,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),

                  // Menü içeriği
                  Positioned(
                    bottom: bottomNavigationBarHeight + safeAreaBottom,
                    left: horizontalMargin,
                    right: horizontalMargin,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      transform: Matrix4.translationValues(
                        0,
                        _isMenuOpen ? 0 : 300,
                        0,
                      ),
                      child: Container(
                        width: menuWidth,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 0,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Menü başlık
                            // Menü başlık
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isLandscape ? 16 : 20,
                                  vertical: isLandscape ? 12 : 16
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.05),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,  // Yükseklik aynı kaldı
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(width: 12),  // Boşluk aynı kaldı
                                  Expanded(
                                    child: Text(
                                      "Hızlı İşlemler",
                                      style: TextStyle(
                                        fontSize: 18,  // FONT AYNEN 18 PİKSEL KALDI
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepPurple,
                                        fontFamily: 'Montserrat',
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _hideMenu,
                                    child: Container(
                                      width: 36,  // Boyut aynı kaldı
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 20,  // İkon boyutu aynı kaldı
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Divider(height: 0, thickness: 1, color: Colors.grey[200]),

                            // Menü öğeleri
                            Padding(
                              padding: EdgeInsets.only(
                                left: isLandscape ? 12 : 16,
                                right: isLandscape ? 12 : 16,
                                bottom: isLandscape ? 16 : 25,
                                top: isLandscape ? 8 : 16,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  List<Map<String, dynamic>> menuItems = [
                                    {
                                      'icon': Icons.calendar_today_rounded,
                                      'title': "Yeni Randevu",
                                      'color': Colors.blue,
                                      'onTap': () {
                                        _hideMenu();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AppointmentEditor(
                                              kullanicirolu: kullanicirolu,
                                              isletmebilgi: widget.isletmebilgi,
                                              tarihsaat: "",
                                              personel_id: (kullanicirolu == 5 ? personelId : ""),
                                            ),
                                          ),
                                        );
                                      },
                                    },
                                    {
                                      'icon': Icons.shopping_bag_rounded,
                                      'title': "Yeni Satış",
                                      'color': Colors.green,
                                      'onTap': () async {
                                        _hideMenu();
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SatisEkrani(
                                              kullanicirolu: kullanicirolu,
                                              isletmebilgi: widget.isletmebilgi,
                                              musteridanisanid: '',
                                              kullanici: widget.kullanici,
                                            ),
                                          ),
                                        );
                                        if (result != null && result['refresh'] == true) {
                                          setState(() {
                                            _selectedTab = 3;
                                            _pages[3] = AdisyonlarPage(
                                              kullanicirolu: kullanicirolu,
                                              kullanici: widget.kullanici,
                                              isletmebilgi: widget.isletmebilgi,
                                              geriGitBtn: false,
                                            );
                                          });
                                        } else {
                                          if (widget.uyelikturu > 1) {
                                            setState(() {
                                              _selectedTab = 3;
                                            });
                                          }
                                        }
                                      },
                                    },
                                    {
                                      'icon': Icons.person_add_alt_rounded,
                                      'title': "Yeni Müşteri",
                                      'color': Colors.red,
                                      'onTap': () {
                                        _hideMenu();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Yenimusteri(
                                              kullanicirolu: kullanicirolu,
                                              isletmebilgi: widget.isletmebilgi,
                                              isim: "",
                                              telefon: "",
                                              sadeceekranikapat: true,
                                            ),
                                          ),
                                        );
                                      },
                                    },
                                  ];

                                  if (kullanicirolu != 5) {
                                    menuItems.add({
                                      'icon': Icons.currency_lira_outlined,
                                      'title': "Yeni Masraf",
                                      'color': Colors.orange,
                                      'onTap': () {
                                        _hideMenu();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MasrafEkle(
                                              personeller: personelliste,
                                              masrafkategorileri: masrafkategoriliste,
                                              giderDataSource: _giderDataGridSource,
                                              seciliisletme: widget.isletmebilgi['id'].toString(),
                                              isletmebilgi: widget.isletmebilgi,
                                            ),
                                          ),
                                        );
                                      },
                                    });
                                  }

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: isLandscape ? 8 : 10,
                                      crossAxisSpacing: isLandscape ? 8 : 10,
                                      childAspectRatio: isLandscape ? 1.0 : 1.2,
                                    ),
                                    itemCount: menuItems.length,
                                    itemBuilder: (context, index) {
                                      return _buildModernMenuItem(
                                        icon: menuItems[index]['icon'],
                                        title: menuItems[index]['title'],
                                        color: menuItems[index]['color'],
                                        onTap: menuItems[index]['onTap'],
                                        isLandscape: isLandscape,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context)!.insert(_menuOverlayEntry!);
  }

// Menü başlığı widget'ı
  Widget _buildMenuHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Hızlı İşlemler",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
                fontFamily: 'Montserrat',
                decoration: TextDecoration.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: _hideMenu,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Responsive menü öğeleri
  Widget _buildResponsiveMenuItems(bool isTablet, bool isLandscape) {
    final bool showOnlyThreeItems = kullanicirolu == 5;

    // Grid düzenini belirle
    int crossAxisCount;
    double childAspectRatio;
    double mainSpacing;
    double crossSpacing;

    if (isTablet) {
      if (isLandscape) {
        // Yatay tablet: 4 sütun
        crossAxisCount = showOnlyThreeItems ? 3 : 4;
        childAspectRatio = 1.1;
        mainSpacing = 16;
        crossSpacing = 16;
      } else {
        // Dikey tablet: 3 sütun
        crossAxisCount = showOnlyThreeItems ? 3 : 3;
        childAspectRatio = 1.0;
        mainSpacing = 16;
        crossSpacing = 16;
      }
    } else {
      // Telefon: 2 veya 3 sütun
      crossAxisCount = showOnlyThreeItems ? 3 : 2;
      childAspectRatio = showOnlyThreeItems ? 1.0 : 1.2;
      mainSpacing = 10;
      crossSpacing = 10;
    }

    List<Map<String, dynamic>> menuItems = _getMenuItems();

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        return _buildModernMenuItem(
          icon: menuItems[index]['icon'],
          title: menuItems[index]['title'],
          color: menuItems[index]['color'],
          onTap: menuItems[index]['onTap'],

        );
      },
    );
  }

// Menü öğelerini getir
  List<Map<String, dynamic>> _getMenuItems() {
    List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.calendar_today_rounded,
        'title': "Yeni Randevu",
        'color': Colors.blue,
        'onTap': () {
          _hideMenu();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentEditor(
                kullanicirolu: kullanicirolu,
                isletmebilgi: widget.isletmebilgi,
                tarihsaat: "",
                personel_id: (kullanicirolu == 5 ? personelId : ""),
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.shopping_bag_rounded,
        'title': "Yeni Satış",
        'color': Colors.green,
        'onTap': () async {
          _hideMenu();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SatisEkrani(
                kullanicirolu: kullanicirolu,
                isletmebilgi: widget.isletmebilgi,
                musteridanisanid: '',
                kullanici: widget.kullanici,
              ),
            ),
          );
          if (result != null && result['refresh'] == true) {
            setState(() {
              _selectedTab = 3;
              _pages[3] = AdisyonlarPage(
                kullanicirolu: kullanicirolu,
                kullanici: widget.kullanici,
                isletmebilgi: widget.isletmebilgi,
                geriGitBtn: false,
              );
            });
          } else {
            if (widget.uyelikturu > 1) {
              setState(() {
                _selectedTab = 3;
              });
            }
          }
        },
      },
      {
        'icon': Icons.person_add_alt_rounded,
        'title': "Yeni Müşteri",
        'color': Colors.red,
        'onTap': () {
          _hideMenu();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Yenimusteri(
                kullanicirolu: kullanicirolu,
                isletmebilgi: widget.isletmebilgi,
                isim: "",
                telefon: "",
                sadeceekranikapat: true,
              ),
            ),
          );
        },
      },
    ];

    if (kullanicirolu != 5) {
      menuItems.add({
        'icon': Icons.currency_lira_outlined,
        'title': "Yeni Masraf",
        'color': Colors.orange,
        'onTap': () {
          _hideMenu();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MasrafEkle(
                personeller: personelliste,
                masrafkategorileri: masrafkategoriliste,
                giderDataSource: _giderDataGridSource,
                seciliisletme: widget.isletmebilgi['id'].toString(),
                isletmebilgi: widget.isletmebilgi,
              ),
            ),
          );
        },
      });
    }

    return menuItems;
  }

// Modern menü öğesi widget'ı - TABLET VE YATAY MOD İÇİN GÜNCELLENMİŞ
  // Modern menü öğesi widget'ı - TABLET VE YATAY MOD İÇİN GÜNCELLENMİŞ
  // Modern menü öğesi - SADECE BOYUTLAR DEĞİŞTİ, FONT AYNI
  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isLandscape = false,
  }) {
    // YATAY MODDA SADECE BOYUTLAR KÜÇÜLDÜ, FONT AYNI KALDI
    final double iconContainerSize = isLandscape ? 40 : 56;
    final double iconSize = isLandscape ? 20 : 28;
    final double fontSize = isLandscape ? 10 : (kullanicirolu == 5 ? 11 : 12);
    final double spacing = isLandscape ? 4 : 8;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: iconSize,
              ),
            ),
            SizedBox(height: spacing),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontFamily: 'Roboto',  // Font family geri geldi
                  decoration: TextDecoration.none,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
// Menüyü gizle
  void _hideMenu() {
    if (_menuOverlayEntry != null) {
      _menuOverlayEntry!.remove();
      _menuOverlayEntry = null;
    }
    _isMenuOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isMenuOpen) {
          _hideMenu();
          return false;
        }

        if (_selectedTab != 0) {
          setState(() {
            _selectedTab = 0;
          });
          return false;
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                "Uygulamadan çıkış",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  decoration: TextDecoration.none,
                ),
              ),
              content: Text(
                "Uygulamadan çıkmak istediğinize emin misiniz?",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  decoration: TextDecoration.none,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "İptal",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    SystemNavigator.pop();
                  },
                  child: Text(
                    "Çıkış",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          );
          return false;
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: _pages[_selectedTab],
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: GestureDetector(
          onTap: () {
            if (_isMenuOpen) {
              _hideMenu();
            } else {
              _showMenu(context);
            }
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isMenuOpen
                    ? [Colors.deepPurple.shade700, Colors.purple.shade700]
                    : [Colors.deepPurple, Colors.purple],
              ),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.4),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              _isMenuOpen ? Icons.close_rounded : Icons.add_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),

        bottomNavigationBar: (_isKeyboardVisible)
            ? SizedBox.shrink()
            : Consumer<IndexedStackState>(
          builder: (context, state, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.white,
                    currentIndex: _selectedTab,
                    onTap: (index) {
                      if (_isMenuOpen) {
                        _hideMenu();
                      }
                      _selectScreen(index);
                    },
                    selectedItemColor: Colors.deepPurple,
                    unselectedItemColor: Colors.black26,
                    type: BottomNavigationBarType.fixed,
                    selectedFontSize: 10,
                    unselectedFontSize: 10,
                    selectedLabelStyle: TextStyle(
                      fontFamily: 'Roboto',
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontFamily: 'Roboto',
                    ),

                    items: [
                      BottomNavigationBarItem(
                          icon: Icon(Icons.home_outlined),
                          label: "Özet"
                      ),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.calendar_month_outlined),
                          label: "Randevular"
                      ),
                      BottomNavigationBarItem(
                        icon: SizedBox.shrink(),
                        label: "",
                      ),
                      widget.uyelikturu > 1
                          ? BottomNavigationBarItem(
                          icon: Icon(Icons.copy_all_sharp),
                          label: "Satış Takibi"
                      )
                          : BottomNavigationBarItem(
                          icon: Icon(Icons.insert_comment_outlined),
                          label: "Ön Görüşmeler"
                      ),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.more_vert),
                          label: "Menü"
                      ),
                    ],
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