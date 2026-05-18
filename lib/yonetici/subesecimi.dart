import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/basic_bottom_nav_bar.dart';

import 'package:randevu_sistem/theme/premium_components.dart';
import 'package:randevu_sistem/yonetici/dashboard/scaffold_layout_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/indexedstack.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:randevu_sistem/services/notification_service.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final isletmeler = widget.kullanici.yetkili_olunan_isletmeler;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.36), Colors.white),
              Color.alphaBlend(
                  scheme.tertiary.withValues(alpha: 0.08), Colors.white),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Top bar — sadece sağda profile circle, sol boş (login akışı)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PremiumCircleAction(
                      icon: Icons.logout_rounded,
                      iconColor: scheme.error,
                      onTap: () => logout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Avatar + greeting
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.18),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: scheme.primary,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hoşgeldiniz 👋',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.kullanici.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: scheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'İşletme Seçiniz',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: isletmeler.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final isletme = isletmeler[index];
                      final salonAdi =
                          isletme['salonlar']['salon_adi'].toString();
                      return PremiumGlassCard(
                        padding: const EdgeInsets.all(14),
                        onTap: () async {
                          SharedPreferences localStorage =
                              await SharedPreferences.getInstance();
                          seciliIsletmeNoKaydet(
                            isletme['salon_id'].toString(),
                            salonAdi,
                          );
                          // FCM cihaz kaydı (şube seçildi)
                          NotificationService.instance.registerForUser(
                            kullaniciTipi: 'yetkili',
                            yetkiliId: widget.kullanici.id,
                            salonId: isletme['salon_id'].toString(),
                          );
                          // Yetki cache'i bu (kullanici, sube) icin tazele.
                          await Yetki.tazele(
                            salonid: isletme['salon_id'].toString(),
                            yetkiliId: widget.kullanici.id.toString(),
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BottomNavigationExample(
                                scaffoldMessengerKey:
                                    widget.scaffoldMessengerKey,
                                kullanici: widget.kullanici,
                                isletmebilgi: isletme['salonlar'],
                                uyelikturu: int.parse(isletme['salonlar']
                                        ['uyelik_turu']
                                    .toString()),
                              ),
                            ),
                            (route) => false,
                          ).then((_) {
                            Provider.of<IndexedStackState>(context,
                                    listen: false)
                                .setSelectedIndex(0);
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    scheme.primary.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                color: scheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    salonAdi,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'İşletmeyi aç',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    scheme.primary.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
