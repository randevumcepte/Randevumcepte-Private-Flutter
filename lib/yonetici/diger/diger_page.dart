import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/Frontend/dialpad.dart';
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
import '../santral/santralraporlari.dart';
import '../subesecimi.dart';
import 'menu/ajanda/ajanda.dart';
import 'menu/arsiv/arsivyonetimipage.dart';
import 'menu/asistanim/asistanpage.dart';
import 'menu/ayarlar/ayarlar.dart';
import 'menu/ayarlar/personeller/personeller.dart';
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
import 'menu/satisraporlari/satisraporlaripersonel.dart';
import 'menu/satisraporlari/satisraporu.dart';
import 'menu/seanstakibi/seanstakibi.dart';
import 'menu/seanstakibi/seanstakibiyeni.dart';
import 'menu/senetler/senetlistesi.dart';
import 'package:http/http.dart' as http;

bool menu_sayfasindayiz = false;
late Kullanici _kullanici;
late int kullanicirolu;

class DigerPage extends StatefulWidget {
  final Kullanici kullanici;
  final int uyelikturu;
  final VoidCallback onLogout;
  final dynamic isletmebilgi;
  final DialPadManager dialpadManager;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;


  DigerPage({
    Key? key,
    required this.kullanici,
    required this.uyelikturu,
    required this.onLogout,
    required this.isletmebilgi,
    required this.dialpadManager,
    required this.scaffoldMessengerKey,
  }) : super(key: key);

  @override
  _DigerPageState createState() => _DigerPageState();
}

class _DigerPageState extends State<DigerPage> {
  @override
  void initState() {
    super.initState();
    setState(() {
      _kullanici = widget.kullanici;
      kullanicirolu = int.parse(
          widget.kullanici.yetkili_olunan_isletmeler.firstWhere((element) =>
          element["salon_id"].toString() == widget.isletmebilgi["id"].toString()
          )["role_id"].toString()
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Menu(
        isletmebilgi: widget.isletmebilgi,
        kullanici: widget.kullanici,
        uyelikturu: widget.uyelikturu,
        onLogout: widget.onLogout,
        dialpadManager: widget.dialpadManager,
        scaffoldMessengerKey: widget.scaffoldMessengerKey,
      ),
    );
  }
}

class Menu extends StatefulWidget {
  final Kullanici kullanici;
  final int uyelikturu;
  final dynamic isletmebilgi;
  final VoidCallback onLogout;
  final DialPadManager dialpadManager;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  Menu({
    Key? key,
    required this.kullanici,
    required this.uyelikturu,
    required this.onLogout,
    required this.isletmebilgi,
    required this.dialpadManager,
    required this.scaffoldMessengerKey
  }) : super(key: key);

  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  final Color _primaryColor = Color(0xFF7C3AED);
  final Color _lightPurple = Color(0xFFF3E8FF);
  final Color _backgroundColor = Color(0xFFFAFAFA);
  final Color _textColor = Color(0xFF1F2937);
  final Color _borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
  }

  void _logout(BuildContext context) async {
    try {
      bool? confirmLogout = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Çıkış Yap',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          content: Text('Çıkış yapmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Hayır',
                style: TextStyle(color: _primaryColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Evet',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmLogout == true) {
        Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
        Provider.of<IndexedStackState>(context, listen: false).resetSelectedIndex();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('user');
        await prefs.remove('token');
        await prefs.remove('user_type');

        Navigator.pushAndRemoveUntil(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            duration: Duration(milliseconds: 300),
            child: OnBoardingPage(),
          ),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showBadge = false,
    String? badgeText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: _primaryColor.withOpacity(0.1),
          highlightColor: _primaryColor.withOpacity(0.05),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _lightPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _borderColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _textColor.withOpacity(0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _lightPurple,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.person_rounded,
              color: _primaryColor,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kullanici.name ?? 'Kullanıcı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.kullanici.email != 'null' ? widget.kullanici.email : '',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textColor.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  duration: Duration(milliseconds: 300),
                  child: ProfilBilgileri(kullanici: _kullanici),
                ),
              );
            },
            icon: Icon(Icons.edit_rounded, color: _primaryColor, size: 20),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Menü',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _textColor,
            letterSpacing: -0.5,
          ),
        ),
        toolbarHeight: 64,
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        actions: [
          if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
            ),
          if (widget.kullanici.yetkili_olunan_isletmeler.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageTransition(
                          type: PageTransitionType.fade,
                          duration: Duration(milliseconds: 300),
                          child: (widget.kullanici.yetkili_olunan_isletmeler.length > 1)
                              ? SubeSecimi(
                            kullanici: widget.kullanici,
                            scaffoldMessengerKey: scaffoldMessengerKey,
                          )
                              : BottomNavigationExample(
                            scaffoldMessengerKey: scaffoldMessengerKey,
                            isletmebilgi: widget.kullanici.yetkili_olunan_isletmeler[0]['salonlar'],
                            kullanici: widget.kullanici,
                            uyelikturu: int.parse(
                              widget.kullanici.yetkili_olunan_isletmeler[0]['salonlar']['uyelik_turu'].toString(),
                            ),
                          ),
                        ),
                            (route) => false,
                      ).then((_) {
                        Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.storefront_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            "Şube Seç",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // İşlemler Bölümü
                _buildSectionTitle('İŞLEMLER'),
                if (widget.uyelikturu > 2 && kullanicirolu < 5)
                  _buildMenuButton(
                    icon: Icons.assistant_rounded,
                    label: 'Asistanım',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: AsistanimPage(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },
                  ),
                if (widget.uyelikturu > 2 && kullanicirolu < 5)
                  _buildMenuButton(
                    icon: Icons.phone,
                    label: 'Santral',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: CDRRaporlari(scaffoldMessengerKey: widget.scaffoldMessengerKey , kullanici: widget.kullanici, isletmebilgi: widget.isletmebilgi ,kullanicirolu:kullanicirolu ,dialPadManager:widget.dialpadManager,),
                        ),
                      );
                    },
                  ),

                if (widget.uyelikturu > 2)
                  _buildMenuButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Ön Görüşmeler',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: OnGorusmeler(
                            kullanicirolu: kullanicirolu,
                            isletmebilgi: widget.isletmebilgi,
                          ),
                        ),
                      );
                    },
                  ),

                if (widget.uyelikturu > 2)
                  _buildMenuButton(
                    icon: Icons.calendar_today_rounded,
                    label: 'Randevular',
                    onTap: () {
                      String personelid = "";
                      if (kullanicirolu == 5) {
                        widget.kullanici.yetkili_olunan_isletmeler.forEach((element) {
                          if (element["salon_id"].toString() == widget.isletmebilgi["id"].toString())
                            personelid = element["id"].toString();
                        });
                      }
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: RandevularMenu(
                            kullanicirolu: kullanicirolu,
                            isletmebilgi: widget.isletmebilgi,
                            personelid: personelid,
                            cihazid: "",
                            personel_adi: "",
                            cihaz_adi: "",
                          ),
                        ),
                      );
                    },
                  ),

                if (kullanicirolu < 5)
                  _buildMenuButton(
                    icon: Icons.group_rounded,
                    label: 'Müşteriler',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: MusteriListesi(
                            kullanicirolu: kullanicirolu,
                            isletmebilgi: widget.isletmebilgi,
                          ),
                        ),
                      );
                    },
                  ),
                if(widget.uyelikturu>1 && kullanicirolu<5)
                  _buildMenuButton(
                      icon: Icons.supervised_user_circle_outlined,
                      label: 'Personeller',
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            duration: Duration(milliseconds: 300),
                            child: Personeller(kullanicirolu: kullanicirolu, isletmebilgi: widget.isletmebilgi),
                          ),
                        );
                      },
                  ),

                // Yönetim Bölümü
                _buildSectionTitle('YÖNETİM'),
                if (widget.uyelikturu > 1 && kullanicirolu < 5)
                  _buildMenuButton(
                    icon: Icons.archive_rounded,
                    label: 'Arşiv Yönetimi',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: ArsivYonetimiPage(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },

                  ),


                if (widget.uyelikturu > 1 && kullanicirolu < 5)
                  _buildMenuButton(
                    icon: Icons.checklist_rtl_rounded,
                    label: 'Seans Takibi',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: SeansTakibi(isletmebilgi: widget.isletmebilgi)//SeansTakibi(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },
                  ),

                _buildMenuButton(
                  icon: Icons.analytics_rounded,
                  label: 'Satış Raporları',
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: Duration(milliseconds: 300),
                        child: kullanicirolu == 5
                            ? SalesReportsPersonelPage(
                          isletmebilgi: widget.isletmebilgi,
                          kullanicirolu: kullanicirolu, kullanici: _kullanici,
                        )
                            : SalesReportsPage(
                          isletmebilgi: widget.isletmebilgi,
                          kullanicirolu: kullanicirolu,
                        ),
                      ),
                    );
                  },
                ),

                if (widget.uyelikturu > 1 && kullanicirolu < 5)
                  _buildMenuButton(
                    icon: Icons.widgets_rounded,
                    label: 'Paket Yönetimi',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: PaketSatislari(
                            adisyonId: "",
                            kullanicirolu: kullanicirolu,
                            kullanici: widget.kullanici,
                            isletmebilgi: widget.isletmebilgi,
                          ),
                        ),
                      );
                    },
                  ),

                if (widget.uyelikturu > 1 && kullanicirolu < 5)
                  _buildMenuButton(
                    icon: Icons.inventory_2_rounded,
                    label: 'Stok Yönetimi',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: Urunler(
                            adisyonId: "",
                            kullanicirolu: kullanicirolu,
                            kullanici: widget.kullanici,
                            isletmebilgi: widget.isletmebilgi,
                          ),
                        ),
                      );
                    },
                  ),

                _buildMenuButton(
                  icon: Icons.note_alt_rounded,
                  label: 'Ajanda',
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: Duration(milliseconds: 300),
                        child: AjandaNotlar(isletmebilgi: widget.isletmebilgi),
                      ),
                    );
                  },
                ),

                if (widget.uyelikturu > 1 && kullanicirolu < 4)
                  _buildMenuButton(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Kasa Raporu',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: KasaRaporu(isletmebilgi: widget.isletmebilgi),
                        ),
                      );
                    },
                  ),

                if (widget.uyelikturu > 1 && kullanicirolu < 5)
                  _buildMenuButton(
                    icon: Icons.money_off_rounded,
                    label: 'Masraflar',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: Masraflar(
                            odeme_yontemi: '',
                            tarih: '',
                            isletmebilgi: widget.isletmebilgi,
                          ),
                        ),
                      );
                    },
                  ),

                // Ayarlar Bölümü
                _buildSectionTitle('AYARLAR'),
                if (kullanicirolu < 4)
                  _buildMenuButton(
                    icon: Icons.settings_rounded,
                    label: 'Sistem Ayarları',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: Duration(milliseconds: 300),
                          child: Ayarlar(
                            kullanicirolu: kullanicirolu,
                            isletmebilgi: widget.isletmebilgi,
                          ),
                        ),
                      );
                    },
                  ),

                _buildMenuButton(
                  icon: Icons.person_pin_rounded,
                  label: 'Profil Bilgileri',
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: Duration(milliseconds: 300),
                        child: ProfilBilgileri(kullanici: _kullanici),
                      ),
                    );
                  },
                ),

                _buildMenuButton(
                  icon: Icons.logout_rounded,
                  label: 'Çıkış Yap',
                  onTap: () => _logout(context),
                ),


                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}