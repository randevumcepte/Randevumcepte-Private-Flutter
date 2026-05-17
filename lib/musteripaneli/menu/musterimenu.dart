import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/musteriprofilbilgileri.dart';
import 'package:randevu_sistem/musteripaneli/menu/saglikbilgileri.dart';
import 'package:randevu_sistem/musteripaneli/menu/siparislerim.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/Frontend/indexedstack.dart';
import 'package:randevu_sistem/Login Sayfası/tanitim.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import '../anasayfa/raporlar/seanslar.dart';
import 'musteriresimleri.dart';
import 'musterisözlesmeleri.dart';

class MenuPage extends StatefulWidget {
  final VoidCallback onLogout;
  final MusteriDanisan md;
  final dynamic isletmebilgi;

  const MenuPage({
    Key? key,
    required this.onLogout,
    required this.md,
    this.isletmebilgi,
  }) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  Color get _primaryColor => Theme.of(context).colorScheme.primary;
  Color get _lightPurple =>
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);
  Color get _textColor => Theme.of(context).colorScheme.onSurface;
  Color get _borderColor =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10);

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
          content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
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
              child: const Text(
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
        await prefs.remove('musteri');
        await prefs.remove('user_type');
        await prefs.remove('token');

        Navigator.pushAndRemoveUntil(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 300),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: _primaryColor.withValues(alpha: 0.10),
          highlightColor: _primaryColor.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                      letterSpacing: -0.2,
                    ),
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
          color: _textColor.withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.md.name.isNotEmpty ? widget.md.name : 'Müşteri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profileSubtitle(),
                  style: TextStyle(
                    fontSize: 14,
                    color: _textColor.withValues(alpha: 0.6),
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
                  duration: const Duration(milliseconds: 300),
                  child: MusteriProfilBilgileri(kullanici: widget.md),
                ),
              );
            },
            icon: Icon(Icons.edit_rounded, color: _primaryColor, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _profileSubtitle() {
    final email = widget.md.email;
    if (email.isNotEmpty && email != 'null') return email;
    final tel = widget.md.cep_telefon;
    if (tel.isNotEmpty && tel != 'null') return tel;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
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
      ),
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),

                  _buildSectionTitle('İŞLEMLERİM'),
                  _buildMenuButton(
                    icon: Icons.event_available_rounded,
                    label: 'Seanslarım',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: const Duration(milliseconds: 300),
                          child: SeanslarDashboard(
                            isletmebilgi: widget.isletmebilgi,
                            md: widget.md,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Satın Aldıklarım',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: const Duration(milliseconds: 300),
                          child: MusteriPaneliAdiayonlari(
                            kullanici: widget.md,
                            isletmebilgi: widget.isletmebilgi,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  _buildSectionTitle('BELGELERİM'),
                  _buildMenuButton(
                    icon: Icons.description_outlined,
                    label: 'Sözleşme / Belgelerim',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: const Duration(milliseconds: 300),
                          child: MusteriPaneliArsivDetay(
                            md: widget.md,
                            isletmebilgi: widget.isletmebilgi,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    icon: Icons.health_and_safety_outlined,
                    label: 'Sağlık Bilgilerim',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: const Duration(milliseconds: 300),
                          child: MusteriPaneliSaglikBilgileri(md: widget.md),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Resimlerim',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: const Duration(milliseconds: 300),
                          child: ImageGallery(
                            md: widget.md,
                            isletmebilgi: widget.isletmebilgi,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  _buildSectionTitle('HESABIM'),
                  _buildMenuButton(
                    icon: Icons.person_pin_rounded,
                    label: 'Profil Bilgilerim',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: const Duration(milliseconds: 300),
                          child: MusteriProfilBilgileri(kullanici: widget.md),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    icon: Icons.logout_rounded,
                    label: 'Çıkış Yap',
                    onTap: () => _logout(context),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
