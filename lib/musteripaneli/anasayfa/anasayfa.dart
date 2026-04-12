import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/Login%20Sayfas%C4%B1/checklogin.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/raporlar/alinanpaketler.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/raporlar/alinanurunler.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/raporlar/randevularim.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/raporlar/seanslar.dart';
import 'package:badges/badges.dart' as badges;
import 'package:randevu_sistem/yonetici/dashboard/scaffold_layout_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Backend/backend.dart';
import '../../Frontend/indexedstack.dart';
import '../../Login Sayfası/login_page.dart';
import '../../Login Sayfası/tanitim.dart';
import '../../Models/dashboard.dart';
import '../../Models/musteri_danisanlar.dart';
import '../../Models/musteridashboard.dart';
import '../../randevualma/randevual.dart';
import '../../yonetici/dashboard/bildirimler/bildirimler.dart';

import '../randevularim/randevularim.dart';
import '../test.dart';
import 'musteribildirimleri/musteribildirimleri.dart';
import 'musteriprofilbilgileri.dart';

class MusteriAnsayfa extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;
  final VoidCallback onLogout;
  final int kullanicirolu;
  MusteriAnsayfa({Key? key, required this.md, this.isletmebilgi, required this.onLogout, required this.kullanicirolu}) : super(key: key);

  @override
  _MusteriAnsayfaState createState() => _MusteriAnsayfaState();
}

class _MusteriAnsayfaState extends State<MusteriAnsayfa> {

  void _logout(BuildContext context) async {
    try {
      bool? confirmLogout = await showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
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
        Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
        Provider.of<IndexedStackState>(context, listen: false).resetSelectedIndex();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('musteri');
        await prefs.remove('user_type');
        await prefs.remove('token');

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

  MusteriOzet? ozetsayfabilgi;
  ScrollController _scrollController = ScrollController();
  bool isloading = true;

  Future<void> initialize() async {
    try {
      setState(() {
        isloading = true;
      });

      MusteriOzet ozet = await dashboardGunlukRaporMusteri();

      setState(() {
        ozetsayfabilgi = ozet;
        isloading = false;
      });
    } catch (e) {
      print('Initialize hatası: $e');
      setState(() {
        isloading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isAllDay = false;

  @override
  Widget build(BuildContext context) {
    double? _ratingValue;
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFFF5F5F5),
      body: isloading
          ? Center(child: CircularProgressIndicator())
          : ScaffoldLayoutBuilder(
        backgroundColorAppBar:
        const ColorBuilder(Colors.transparent, Color(0xFF6A1B9A)),
        textColorAppBar: const ColorBuilder(Colors.white),
        appBarBuilder: _appBar,
        child: SafeArea(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: RefreshIndicator(
                color: Colors.purple[800],
                backgroundColor: Colors.white,
                strokeWidth: 3.0,
                onRefresh: () async {
                  await initialize();
                  return Future<void>.delayed(const Duration(seconds: 1));
                },
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  physics: BouncingScrollPhysics(parent: ClampingScrollPhysics()),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('images/randevumcepte.jpg'),
                                  fit: BoxFit.fill,
                                ),
                                borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20)
                                )
                            ),
                          ),
                          Container(
                            child: Column(
                                children: [
                                  SizedBox(height: 80),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.only(left: 20),
                                        child: ElevatedButton(
                                          onPressed: () {},
                                          child: Text('Aktif', style: TextStyle(fontSize: 15)),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                              minimumSize: Size(80, 35)
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.only(right: 30),
                                        child: Text(
                                          widget.md.name,
                                          style: TextStyle(color: Colors.white, fontSize: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(15),
                                            topRight: Radius.circular(15),
                                            bottomLeft: Radius.circular(15),
                                            bottomRight: Radius.circular(15)
                                        ),
                                        color: Colors.white
                                    ),
                                    width: width * 0.9,
                                    height: 180,
                                    padding: EdgeInsets.only(top: 15),
                                    child: Column(
                                      children: [
                                        SizedBox(height: 20),
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    PageTransition(
                                                      type: PageTransitionType.rightToLeft,
                                                      duration: Duration(milliseconds: 500),
                                                      child: MusteriRandevulari(
                                                        md: widget.md,
                                                        isletmebilgi: widget.isletmebilgi,
                                                        geriButonu: false,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text('Randevularım'),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: Color(0xFF5E35B1),
                                                    foregroundColor: Colors.white,
                                                    elevation: 5,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                                    minimumSize: Size(150, 50)
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    PageTransition(
                                                      type: PageTransitionType.rightToLeft,
                                                      duration: Duration(milliseconds: 500),
                                                      child: SeanslarDashboard(
                                                          isletmebilgi: widget.isletmebilgi,
                                                          md: widget.md
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text('Seanslarım'),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: Color(0xFF9C27B0),
                                                    foregroundColor: Colors.white,
                                                    elevation: 5,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                                    minimumSize: Size(150, 50)
                                                ),
                                              ),
                                            ]
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  PageTransition(
                                                    type: PageTransitionType.rightToLeft,
                                                    duration: Duration(milliseconds: 500),
                                                    child: MusteriALinanPaketlerDashboard(
                                                      kullanicirolu: widget.kullanicirolu,
                                                      isletmebilgi: widget.isletmebilgi,
                                                      kullanici: widget.md,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Text('Aldığım Paketler'),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(0xFFEA80FC),
                                                  foregroundColor: Colors.white,
                                                  elevation: 5,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                                  minimumSize: Size(150, 50)
                                              ),
                                            ),
                                            SizedBox(width: 5),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  PageTransition(
                                                    type: PageTransitionType.rightToLeft,
                                                    duration: Duration(milliseconds: 500),
                                                    child: MusteriALinanUrunlerDashboard(
                                                      kullanicirolu: widget.kullanicirolu,
                                                      isletmebilgi: widget.isletmebilgi,
                                                      kullanici: widget.md,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Text('Aldığım Ürünler'),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(0xFF1976D2),
                                                  foregroundColor: Colors.white,
                                                  elevation: 5,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                                  minimumSize: Size(150, 50)
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  // Randevu Al Butonu - Duyurular Üstü
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 20),
                                    child: _buildRandevuAlButton(),
                                  ),
                                  Container(
                                      width: MediaQuery.of(context).size.width,
                                      height: MediaQuery.of(context).size.height * 0.62,
                                      child: Column(
                                        children: [
                                          SizedBox(height: 10),
                                          Container(
                                              decoration: const BoxDecoration(
                                                  borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(15),
                                                      topRight: Radius.circular(15),
                                                      bottomLeft: Radius.circular(15),
                                                      bottomRight: Radius.circular(15)
                                                  ),
                                                  color: Colors.white
                                              ),
                                              width: width * 0.9,
                                              height: height * 0.45,
                                              padding: EdgeInsets.only(top: 5),
                                              child: ListView(
                                                children: [
                                                  StickyHeader(
                                                      header: Container(
                                                        color: Colors.white,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                          children: [
                                                            Container(
                                                              padding: EdgeInsets.all(12),
                                                              child: Text(
                                                                'Duyurular',
                                                                style: TextStyle(
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      content: ListView(
                                                        shrinkWrap: true,
                                                        physics: const ClampingScrollPhysics(),
                                                        children: [
                                                          Image.asset(
                                                            'images/announcement.png',
                                                            width: 150,
                                                            height: 150,
                                                          ),
                                                          SizedBox(height: 20),
                                                          Padding(
                                                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                                            child: Text(
                                                              "Duyurular/etkinlikler/kampanyalar burada gösterilecektir.",
                                                              style: TextStyle(fontSize: 16, color: Colors.black),
                                                            ),
                                                          )
                                                        ],
                                                      )
                                                  ),
                                                ],
                                              )
                                          ),
                                        ],
                                      )
                                  )
                                ]
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modern Randevu Al Butonu - Çerçeveli ve Mor Yazılı
  Widget _buildRandevuAlButton() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Color(0xFF6A1B9A).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            _onRandevuAlPressed();
          },
          splashColor: Color(0xFF6A1B9A).withOpacity(0.1),
          highlightColor: Color(0xFF6A1B9A).withOpacity(0.05),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF6A1B9A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: Color(0xFF6A1B9A),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Randevu Oluştur',
                              style: TextStyle(
                                color: Color(0xFF6A1B9A),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Randevunuzu planlayın',
                              style: TextStyle(
                                color: Color(0xFF6A1B9A).withOpacity(0.7),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF6A1B9A).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF6A1B9A),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onRandevuAlPressed() {
    // Randevu al butonuna basıldığında yapılacak işlemler
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: Duration(milliseconds: 500),
        child: RandevuAl(), // RandevuAl sayfasına yönlendir
      ),
    );
  }

  Widget _appBar(BuildContext context, ColorAnimated colorAnimated) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 100,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Bercislina Güzellik Salonu", style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(width: 28),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildNotificationIcon(),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: Duration(milliseconds: 500),
                        child: MusteriProfilBilgileri(kullanici: widget.md),
                      ),
                    );
                  },
                  icon: Icon(Icons.person, color: Colors.white),
                  iconSize: 20,
                ),

              ],
            ),
          )
        ],
      ),
      toolbarHeight: 60,
      backgroundColor: colorAnimated.background,
    );
  }

  Widget _buildNotificationIcon() {
    final bool hasUnreadNotifications = ozetsayfabilgi != null &&
        ozetsayfabilgi!.okunmamisbildirimler.isNotEmpty &&
        ozetsayfabilgi!.okunmamisbildirimler != "0" &&
        ozetsayfabilgi!.okunmamisbildirimler != "null";

    if (!hasUnreadNotifications) {
      return IconButton(
          onPressed: () async {
            await Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                duration: Duration(milliseconds: 500),
                child: MusteriBildirimlerScreen(
                  isletmebilgi: widget.isletmebilgi,
                  md: widget.md,
                ),
              ),
            );

            // Bildirim ekranı kapatıldı → özet sayfası verisini yenile
            initialize();

          },

          icon: Icon(Icons.notifications_active, color: Colors.white),
        iconSize: 20,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                duration: Duration(milliseconds: 500),
                child: MusteriBildirimlerScreen(
                  isletmebilgi: widget.isletmebilgi,
                  md: widget.md,
                ),
              ),
            );
          },
          icon: Icon(Icons.notifications_active, color: Colors.white),
          iconSize: 20,
        ),
        Positioned(
          right: 10,
          top: 13,
          child: badges.Badge(
            badgeStyle: badges.BadgeStyle(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              badgeColor: Colors.red,
            ),
            badgeContent: Text(
              ozetsayfabilgi!.okunmamisbildirimler,
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class WhatsAppOpener {
  static Future<void> openWhatsApp(String phoneNumber, String message) async {
    final encodedMessage = Uri.encodeComponent(message);
    final Uri url = Uri.parse('https://wa.me/$phoneNumber?text=$encodedMessage');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'WhatsApp açılamadı. Lütfen WhatsApp yüklü olduğundan emin olun.';
    }
  }
}

class WhatsAppFAB extends StatelessWidget {
  final String whatsappPhone;
  WhatsAppFAB({Key? key, required this.whatsappPhone}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65.0,
      height: 65.0,
      child: FloatingActionButton(
        onPressed: () {
          WhatsAppOpener.openWhatsApp(whatsappPhone, 'Merhaba, bilgi / randevu almak istiyorum.');
        },
        backgroundColor: Color(0xFF25D366),
        child: SvgPicture.asset(
          'images/wp5.svg',
          width: 30,
          height: 40,
          color: Colors.white,
        ),
      ),
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

class ListCard extends StatelessWidget {
  const ListCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        // İçerik buraya eklenebilir
      ],
    );
  }
}