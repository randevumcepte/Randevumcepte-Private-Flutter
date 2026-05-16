import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/indexedstack.dart';
import 'package:randevu_sistem/Login Sayfası/tanitim.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/musteridashboard.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/raporlar/alinanpaketler.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/raporlar/alinanurunler.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/raporlar/seanslar.dart';
import 'package:randevu_sistem/randevualma/randevual.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

import '../randevularim/randevularim.dart';
import 'musteribildirimleri/musteribildirimleri.dart';
import 'musteriprofilbilgileri.dart';

class MusteriAnsayfa extends StatefulWidget {
  final MusteriDanisan md;
  final dynamic isletmebilgi;
  final VoidCallback onLogout;
  final int kullanicirolu;

  MusteriAnsayfa({
    Key? key,
    required this.md,
    this.isletmebilgi,
    required this.onLogout,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  _MusteriAnsayfaState createState() => _MusteriAnsayfaState();
}

class _MusteriAnsayfaState extends State<MusteriAnsayfa> {
  MusteriOzet? ozetsayfabilgi;
  bool isloading = true;

  Future<void> initialize() async {
    try {
      setState(() => isloading = true);
      final ozet = await dashboardGunlukRaporMusteri();
      setState(() {
        ozetsayfabilgi = ozet;
        isloading = false;
      });
    } catch (e) {
      print('Initialize hatası: $e');
      setState(() => isloading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> _refreshPage() async {
    await initialize();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _logout(BuildContext context) async {
    try {
      final confirmLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Evet'),
            ),
          ],
        ),
      );

      if (confirmLogout == true) {
        Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
        Provider.of<IndexedStackState>(context, listen: false).resetSelectedIndex();
        final prefs = await SharedPreferences.getInstance();
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

  String _resolveSalonAdi() {
    try {
      final b = widget.isletmebilgi;
      if (b == null) return 'Salon';
      final candidates = [
        b.isletmeadi,
        b.salonadi,
        b.adi,
        b.name,
      ];
      for (final c in candidates) {
        if (c is String && c.trim().isNotEmpty) return c;
      }
    } catch (_) {}
    return 'Salon';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.10),
                Colors.white,
              ),
              Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.06),
                Colors.white,
              ),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: isloading
              ? Center(child: CircularProgressIndicator(color: scheme.primary))
              : RefreshIndicator(
                  color: scheme.primary,
                  backgroundColor: Colors.white,
                  strokeWidth: 3,
                  onRefresh: _refreshPage,
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      _premiumTopBar(context),
                      _premiumGreeting(context),
                      const SizedBox(height: 18),
                      _heroRandevuCard(context),
                      const SizedBox(height: 16),
                      _statusPills(context),
                      const SizedBox(height: 22),
                      _sectionHeader(context, 'Hızlı Erişim'),
                      const SizedBox(height: 10),
                      _quickAccessGrid(context),
                      const SizedBox(height: 22),
                      _sectionHeader(context, 'Sana Özel'),
                      const SizedBox(height: 10),
                      _duyurularCard(context),
                      const SizedBox(height: 22),
                      _sectionHeader(context, 'İletişim'),
                      const SizedBox(height: 10),
                      _iletisimRow(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _premiumTopBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final salonAdi = _resolveSalonAdi();
    final unread = ozetsayfabilgi?.okunmamisbildirimler ?? '';
    final hasUnread = unread.isNotEmpty && unread != '0' && unread != 'null';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleAction(
            context,
            icon: hasUnread
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            badge: hasUnread ? unread : null,
            pulse: hasUnread,
            onTap: () async {
              await Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  duration: const Duration(milliseconds: 400),
                  child: MusteriBildirimlerScreen(
                    isletmebilgi: widget.isletmebilgi,
                    md: widget.md,
                  ),
                ),
              );
              initialize();
            },
          ),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                salonAdi,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _circleAction(
            context,
            icon: Icons.person_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  duration: const Duration(milliseconds: 400),
                  child: MusteriProfilBilgileri(kullanici: widget.md),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _circleAction(
    BuildContext context, {
    required IconData icon,
    String? badge,
    required VoidCallback onTap,
    bool pulse = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: pulse
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Color.alphaBlend(
                            scheme.primary.withValues(alpha: 0.07),
                            Colors.white,
                          ),
                        ],
                      )
                    : null,
                color: pulse ? null : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: scheme.primary, size: 21),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -3,
            right: -3,
            child: _AnimatedBadge(badge: badge),
          ),
      ],
    );
  }

  // ── GREETING ──────────────────────────────────────────────────────────────
  Widget _premiumGreeting(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ad = widget.md.name.trim().isEmpty ? 'Misafir' : widget.md.name;
    final firstName = ad.split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greetingPrefix(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$firstName 👋',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: scheme.onSurface,
              height: 1.15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Bugün seni neler bekliyor?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  String _greetingPrefix() {
    final h = DateTime.now().hour;
    if (h < 6) return 'İyi geceler';
    if (h < 12) return 'Günaydın';
    if (h < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  // ── HERO RANDEVU CARD ────────────────────────────────────────────────────
  Widget _heroRandevuCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: _onRandevuAlPressed,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary,
                  Color.lerp(scheme.primary, scheme.tertiary, 0.6) ??
                      scheme.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: 30,
                  bottom: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Yeni Randevu',
                              style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Hemen Randevu Al',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tarih ve hizmet seç, dakikalar içinde tamamla',
                              style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.80),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: scheme.primary,
                          size: 18,
                        ),
                      ),
                    ],
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
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 400),
        child: RandevuAl(),
      ),
    );
  }

  // ── STATUS PILLS ─────────────────────────────────────────────────────────
  Widget _statusPills(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _statusPill(
              context,
              icon: Icons.verified_rounded,
              label: 'Üyelik',
              value: 'Aktif',
              tint: ext.successColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statusPill(
              context,
              icon: Icons.workspace_premium_rounded,
              label: 'Sadakat',
              value: 'Standart',
              tint: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color tint,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: tint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION HEADER ───────────────────────────────────────────────────────
  Widget _sectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  // ── QUICK ACCESS GRID ────────────────────────────────────────────────────
  Widget _quickAccessGrid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;

    final items = <_QuickAccessItem>[
      _QuickAccessItem(
        icon: Icons.event_available_rounded,
        title: 'Randevularım',
        subtitle: 'Yaklaşan & geçmiş',
        tint: scheme.primary,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: MusteriRandevulari(
              md: widget.md,
              isletmebilgi: widget.isletmebilgi,
              geriButonu: false,
            ),
          ),
        ),
      ),
      _QuickAccessItem(
        icon: Icons.spa_rounded,
        title: 'Seanslarım',
        subtitle: 'Aktif & tamamlanan',
        tint: scheme.tertiary,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: SeanslarDashboard(
              isletmebilgi: widget.isletmebilgi,
              md: widget.md,
            ),
          ),
        ),
      ),
      _QuickAccessItem(
        icon: Icons.card_giftcard_rounded,
        title: 'Aldığım Paketler',
        subtitle: 'Kalan haklarını gör',
        tint: ext.successColor,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: MusteriALinanPaketlerDashboard(
              kullanicirolu: widget.kullanicirolu,
              isletmebilgi: widget.isletmebilgi,
              kullanici: widget.md,
            ),
          ),
        ),
      ),
      _QuickAccessItem(
        icon: Icons.shopping_bag_rounded,
        title: 'Aldığım Ürünler',
        subtitle: 'Satın alma geçmişi',
        tint: ext.infoColor,
        onTap: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 400),
            child: MusteriALinanUrunlerDashboard(
              kullanicirolu: widget.kullanicirolu,
              isletmebilgi: widget.isletmebilgi,
              kullanici: widget.md,
            ),
          ),
        ),
      ),
    ];

    final width = MediaQuery.of(context).size.width;
    final cardW = (width - 50) / 2;
    final cardH = cardW / 1.45;

    Widget row(_QuickAccessItem a, _QuickAccessItem b) => Row(
          children: [
            SizedBox(width: cardW, height: cardH, child: _quickAccessCard(context, a)),
            const SizedBox(width: 10),
            SizedBox(width: cardW, height: cardH, child: _quickAccessCard(context, b)),
          ],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          row(items[0], items[1]),
          const SizedBox(height: 10),
          row(items[2], items[3]),
        ],
      ),
    );
  }

  Widget _quickAccessCard(BuildContext context, _QuickAccessItem item) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color.alphaBlend(
              item.tint.withValues(alpha: 0.07),
              Colors.white,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, size: 21, color: item.tint),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.2,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // ── DUYURULAR CARD ───────────────────────────────────────────────────────
  Widget _duyurularCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.18),
                    scheme.tertiary.withValues(alpha: 0.18),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.campaign_rounded,
                size: 28,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Yeni Duyurular',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kampanyalar, etkinlikler ve özel teklifler burada görünür.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── İLETİŞİM ROW ─────────────────────────────────────────────────────────
  Widget _iletisimRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _iletisimTile(
              context,
              icon: Icons.phone_rounded,
              label: 'Salonu Ara',
              tint: scheme.primary,
              onTap: () async {
                final phone = _resolveSalonPhone();
                if (phone == null || phone.isEmpty) return;
                final uri = Uri.parse('tel:$phone');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _iletisimTile(
              context,
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              tint: const Color(0xFF25D366),
              onTap: () {
                final phone = _resolveSalonPhone();
                if (phone == null || phone.isEmpty) return;
                WhatsAppOpener.openWhatsApp(
                  phone,
                  'Merhaba, bilgi / randevu almak istiyorum.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _iletisimTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color tint,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolveSalonPhone() {
    try {
      final b = widget.isletmebilgi;
      if (b == null) return null;
      final candidates = [
        b.telefon,
        b.telefonno,
        b.phone,
        b.whatsappPhone,
        b.whatsapp,
      ];
      for (final c in candidates) {
        if (c is String && c.trim().isNotEmpty) return c;
      }
    } catch (_) {}
    return null;
  }
}

// ── ANIMATED BADGE ──────────────────────────────────────────────────────────
class _AnimatedBadge extends StatefulWidget {
  final String badge;
  const _AnimatedBadge({Key? key, required this.badge}) : super(key: key);

  @override
  State<_AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<_AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: badges.Badge(
        badgeStyle: const badges.BadgeStyle(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          badgeColor: Color(0xFFEF4444),
        ),
        badgeContent: Text(
          widget.badge,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

// ── DATA HOLDERS ────────────────────────────────────────────────────────────
class _QuickAccessItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  _QuickAccessItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });
}

// ── KEEP: HELPERS USED BY OTHER FILES ───────────────────────────────────────
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
          WhatsAppOpener.openWhatsApp(
            whatsappPhone,
            'Merhaba, bilgi / randevu almak istiyorum.',
          );
        },
        backgroundColor: const Color(0xFF25D366),
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
      children: const [],
    );
  }
}
