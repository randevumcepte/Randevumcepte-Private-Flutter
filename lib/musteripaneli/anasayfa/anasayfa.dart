import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_svg/svg.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/indexedstack.dart';
import 'package:randevu_sistem/Login Sayfası/tanitim.dart';
import 'package:randevu_sistem/services/notification_service.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/musteridashboard.dart';
import 'package:randevu_sistem/Models/salonyorumlarozet.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/carkifelek.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/odullerim.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/puan_odullerim.dart';
import 'package:randevu_sistem/musteripaneli/anasayfa/salon_yorumlari.dart';
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
  SalonYorumlarOzet? yorumOzeti;
  bool isloading = true;
  List<Map<String, dynamic>> _reklamlar = [];
  bool _popupGosterildi = false; // açılış tam ekran reklam oturumda 1 kez

  // Çoklu şubeli markada üst başlıkta salon adı yerine gösterilecek marka başlığı.
  String? _bundleBaslik;
  bool get _cokluSube =>
      (widget.md.musteri_olunan_salonlar?.length ?? 0) > 1;

  // "Hemen Randevu Al": markanın (app_bundle) şubelerinden en az biri online
  // randevuya açıksa göster. Şube listesi boşsa mevcut tek-şube davranışını koru.
  bool get _onlineRandevuAktif {
    final subeler = widget.md.musteri_olunan_salonlar;
    if (subeler != null && subeler.isNotEmpty) {
      return bundleOnlineRandevuAktifMi(subeler);
    }
    return musteriOnlineRandevuAktifMi(widget.isletmebilgi);
  }

  Future<void> initialize() async {
    try {
      setState(() => isloading = true);
      final results = await Future.wait([
        dashboardGunlukRaporMusteri(),
        salonYorumlariGetir().catchError((_) => SalonYorumlarOzet(
              ortalama: 0,
              toplamPuan: 0,
              toplamYorum: 0,
              dagilim: const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
              yorumlar: const [],
            )),
      ]);
      setState(() {
        ozetsayfabilgi = results[0] as MusteriOzet;
        yorumOzeti = results[1] as SalonYorumlarOzet;
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
    _reklamlariYukle();
    _bundleBasligiYukle();
  }

  /// Çoklu şubeli markada üst başlıkta gösterilecek marka başlığını çeker.
  Future<void> _bundleBasligiYukle() async {
    if (!_cokluSube) return;
    try {
      final ayar = await salonAyarlariByBundle(await appBundleAl());
      final b = ayar['bundle_baslik']?.toString().trim() ?? '';
      if (!mounted || b.isEmpty) return;
      setState(() => _bundleBaslik = b);
    } catch (_) {}
  }

  /// Uygulama-içi bildirim reklamlarını çeker (hata olursa sessizce geçer).
  Future<void> _reklamlariYukle() async {
    try {
      final salonId = widget.isletmebilgi?['id']?.toString() ?? '';
      if (salonId.isEmpty) return;
      final res = await reklamListe(salonId, userId: widget.md.id.toString());
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _reklamlar = (res['data'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
        _acilisPopupGoster();
      }
    } catch (_) {
      // reklam yüklenemezse ana sayfa normal çalışmaya devam eder
    }
  }

  /// Açılışta tam ekran (interstitial) reklam popup'ı — oturumda 1 kez gösterilir.
  void _acilisPopupGoster() {
    if (_popupGosterildi || !mounted) return;
    Map<String, dynamic>? hedef;
    for (final r in _reklamlar) {
      final t = r['tam_ekran'];
      if (t == true || t == 1) {
        hedef = r;
        break;
      }
    }
    if (hedef == null) return;
    _popupGosterildi = true;
    final r = hedef;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        builder: (ctx) => _reklamPopup(ctx, r),
      );
    });
  }

  Widget _reklamPopup(BuildContext ctx, Map<String, dynamic> r) {
    final scheme = Theme.of(ctx).colorScheme;
    final gorsel = r['gorsel']?.toString();
    final baslik = r['baslik']?.toString() ?? '';
    final mesaj = r['mesaj']?.toString() ?? '';
    final aksiyon = r['aksiyon_tipi']?.toString() ?? 'kupon';
    final aksiyonVar = aksiyon != 'yok';
    final butonMetni = aksiyon == 'randevu'
        ? 'Randevu Al 📅'
        : (r['kupon'] != null ? 'Kuponu Kap 🎟️' : 'İncele');
    // Instagram Story (9:16) formatinda tam ekran popup. Salon sahibi dikey
    // story gorselini bozulmadan (BoxFit.cover, ayni oranda) tam kaplar sekilde paylasir.
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      backgroundColor: Colors.transparent,
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Story gorseli — ekrani tam kaplar, oran korunur (bozulmaz)
                if (gorsel != null && gorsel.isNotEmpty)
                  Image.network(
                    gorsel,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: scheme.primary),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.primary, scheme.tertiary],
                      ),
                    ),
                  ),
                // Alt karartma + baslik + mesaj + buton
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 46, 18, 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (baslik.isNotEmpty)
                          Text(
                            baslik,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        if (mesaj.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            mesaj,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (aksiyonVar) _reklamTikla(r);
                          },
                          child: Text(
                            butonMetni,
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Kapat (X) — sag ust
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 22, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshPage() async {
    await initialize();
    await _reklamlariYukle();
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
        try { await NotificationService.instance.unregister(); } catch (_) {}
        Provider.of<IndexedStackState>(context, listen: false).setSelectedIndex(0);
        Provider.of<IndexedStackState>(context, listen: false).resetSelectedIndex();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('musteri');
        await prefs.remove('user_type');
        await prefs.remove('token');
        await Yetki.temizle();

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
    // Çoklu şubeli markada üst başlık = marka başlığı (varsa).
    if (_cokluSube && (_bundleBaslik?.trim().isNotEmpty ?? false)) {
      return _bundleBaslik!.trim();
    }
    final b = widget.isletmebilgi;
    if (b == null) return 'Salon';

    if (b is Map) {
      for (final k in const [
        'salon_adi',
        'isletme_adi',
        'salonadi',
        'isletmeadi',
        'adi',
        'name',
      ]) {
        final v = b[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString();
        }
      }
      return 'Salon';
    }

    try {
      final candidates = [
        b.salon_adi,
        b.isletme_adi,
        b.isletmeadi,
        b.salonadi,
        b.adi,
        b.name,
      ];
      for (final c in candidates) {
        if (c != null && c.toString().trim().isNotEmpty) {
          return c.toString();
        }
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
                      if (_onlineRandevuAktif) ...[
                        _heroRandevuCard(context),
                        const SizedBox(height: 16),
                      ],
                      _membershipCard(context),
                      const SizedBox(height: 22),
                      _sectionHeader(context, 'Sana Özel'),
                      const SizedBox(height: 10),
                      _reklamKartlari(context),
                      _carkPromoCard(context),
                      const SizedBox(height: 10),
                      _puanKuponRow(context),
                      const SizedBox(height: 12),
                      _yorumlarCard(context),
                      const SizedBox(height: 12),
                      _duyurularCard(context),
                      const SizedBox(height: 22),
                      _sectionHeader(context, 'Hızlı Erişim'),
                      const SizedBox(height: 10),
                      _quickAccessGrid(context),
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
                    onNotificationRead: initialize,
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

  // ── MEMBERSHIP + SADAKAT KARTI ───────────────────────────────────────────
  Widget _membershipCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;

    final kategori = ozetsayfabilgi?.kategori ?? 'pasif';
    final kategoriLabel = ozetsayfabilgi?.kategoriLabel ?? 'Pasif Müşteri';
    final tahsilatSayisi = ozetsayfabilgi?.tahsilatSayisi ?? 0;
    final sadakatPuani = ozetsayfabilgi?.sadakatPuani ?? 0;

    // Kategoriye göre ikon + renk + alt yazı
    final IconData kategoriIcon;
    final Color kategoriTint;
    final String kategoriAlt;
    switch (kategori) {
      case 'sadik':
        kategoriIcon = Icons.workspace_premium_rounded;
        kategoriTint = scheme.tertiary;
        kategoriAlt = '$tahsilatSayisi+ alışveriş';
        break;
      case 'aktif':
        kategoriIcon = Icons.verified_rounded;
        kategoriTint = ext.successColor;
        kategoriAlt = '$tahsilatSayisi alışveriş';
        break;
      default:
        kategoriIcon = Icons.person_outline_rounded;
        kategoriTint = scheme.onSurface.withValues(alpha: 0.45);
        kategoriAlt = 'Henüz alışveriş yok';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // SOL — kategori
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: kategoriTint.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(kategoriIcon, size: 20, color: kategoriTint),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          kategoriLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                            letterSpacing: -0.2,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kategoriAlt,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Ayraç
            Container(
              width: 1,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: scheme.onSurface.withValues(alpha: 0.08),
            ),
            // SAĞ — sadakat puanı
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
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
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatPuan(sadakatPuani),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.4,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'sadakat puanı',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPuan(int v) {
    if (v >= 1000) {
      final k = v / 1000.0;
      final s = k.toStringAsFixed(k >= 10 ? 0 : 1);
      return '${s}K';
    }
    return v.toString();
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
              geriButonu: true,
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
    final bool isTabletLandscape = width >= 900 &&
        MediaQuery.of(context).orientation == Orientation.landscape;
    final int perRow = isTabletLandscape ? 4 : 2;
    final cardW = (width - 40 - (perRow - 1) * 10) / perRow;
    final cardH = cardW / (isTabletLandscape ? 2.2 : 1.45);

    Widget rowOf(List<_QuickAccessItem> list) => Row(
          children: [
            for (int i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              SizedBox(
                width: cardW,
                height: cardH,
                child: _quickAccessCard(context, list[i]),
              ),
            ],
          ],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (isTabletLandscape)
            rowOf(items)
          else ...[
            rowOf([items[0], items[1]]),
            const SizedBox(height: 10),
            rowOf([items[2], items[3]]),
          ],
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

  // ── PUAN + KUPONLAR HIZLI ROW ────────────────────────────────────────────
  Widget _puanKuponRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;

    final salonId = widget.isletmebilgi is Map
        ? widget.isletmebilgi['id']?.toString()
        : null;

    Widget tile({
      required IconData icon,
      required String title,
      required String subtitle,
      required Color tint,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: tint, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                            letterSpacing: -0.2,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          tile(
            icon: Icons.stars_rounded,
            title: 'Puan Ödüllerim',
            subtitle: 'Bakiye & ödüller',
            tint: ext.warningColor,
            onTap: () => Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                duration: const Duration(milliseconds: 400),
                child: PuanOdullerimPage(md: widget.md, salonId: salonId),
              ),
            ),
          ),
          const SizedBox(width: 10),
          tile(
            icon: Icons.card_giftcard_rounded,
            title: 'Kuponlarım',
            subtitle: 'Kazandığın ödüller',
            tint: scheme.tertiary,
            onTap: () => Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                duration: const Duration(milliseconds: 400),
                child: OdullerimPage(md: widget.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ÇARK-I FELEK PROMO CARD ──────────────────────────────────────────────
  Widget _carkPromoCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 400),
              child: WheelPage(
                md: widget.md,
                isletmebilgi: widget.isletmebilgi,
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.tertiary,
                  Color.lerp(scheme.tertiary, scheme.primary, 0.55) ??
                      scheme.tertiary,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: scheme.tertiary.withValues(alpha: 0.30),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  top: -28,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  bottom: -34,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Row(
                    children: [
                      const _SpinningWheelIcon(size: 58),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Çark-ı Felek',
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
                              'Çevir & Kazan 🎁',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Onaylı randevuna özel ödüller seni bekliyor',
                              style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.85),
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
                      const SizedBox(width: 10),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: scheme.tertiary,
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

  // ── BİLDİRİM REKLAMLARI (resimli/tıklanabilir kartlar) ───────────────────
  Widget _reklamKartlari(BuildContext context) {
    if (_reklamlar.isEmpty) return const SizedBox.shrink();
    return Column(
      children: _reklamlar
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _reklamKart(context, r),
              ))
          .toList(),
    );
  }

  Widget _reklamKart(BuildContext context, Map<String, dynamic> r) {
    final scheme = Theme.of(context).colorScheme;
    final gorsel = r['gorsel']?.toString();
    final baslik = r['baslik']?.toString() ?? '';
    final mesaj = r['mesaj']?.toString() ?? '';
    final aksiyon = r['aksiyon_tipi']?.toString() ?? 'kupon';
    final kupon = r['kupon'];
    final kuponVar = kupon is Map && kupon['deger'] != null;

    // İndirim rozeti (%20 / 100 ₺) — kupon varsa (kupon veya randevu reklamı)
    String? rozet;
    if (kuponVar) {
      final deger = kupon['deger'];
      final tip = kupon['indirim_tipi']?.toString();
      if (deger is num) {
        rozet = tip == 'tutar'
            ? '${deger % 1 == 0 ? deger.toInt() : deger} ₺'
            : '%${deger.toInt()}';
      }
    }

    final ipucu = aksiyon == 'randevu'
        ? (kuponVar ? 'Dokun: indirimli randevu 📅🎟️' : 'Dokun, randevu al 📅')
        : (kuponVar ? 'Dokun, kuponu kap 🎟️' : '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => _reklamTikla(r),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: (gorsel != null && gorsel.isNotEmpty)
                ? Stack(
                    children: [
                      Image.network(
                        gorsel,
                        width: double.infinity,
                        height: 168,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          height: 168,
                          color: scheme.primary.withValues(alpha: 0.10),
                          child: Icon(Icons.image_not_supported_outlined,
                              color: scheme.primary.withValues(alpha: 0.4)),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.60),
                              ],
                              stops: const [0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                      if (rozet != null)
                        Positioned(top: 12, left: 12, child: _reklamRozet(rozet)),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              baslik,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (ipucu.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                ipucu,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : Container(
                    // Görselsiz: gradient metin kartı
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
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Row(
                      children: [
                        if (rozet != null) ...[
                          _reklamRozet(rozet),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                baslik,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (mesaj.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  mesaj,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (ipucu.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  ipucu,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _reklamRozet(String metin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        metin,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _reklamTikla(Map<String, dynamic> r) async {
    final aksiyon = r['aksiyon_tipi']?.toString() ?? 'kupon';

    // Boş slot / randevu: (varsa) kuponu tanımla, sonra kısıtlı randevu ekranını aç
    if (aksiyon == 'randevu') {
      final kupon = r['kupon'];
      if (kupon != null) {
        try {
          final res = await reklamKuponKap(
              widget.md.id.toString(), r['id'].toString());
          if (mounted && res['success'] == true) {
            final zaten = res['zaten'] == true;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(zaten
                  ? 'Kuponun cebinde 👍 Kampanya saatinden randevunu al.'
                  : '🎉 İndirim kuponun tanımlandı! Kampanya saatinden randevunu al.'),
            ));
          }
        } catch (_) {}
      }
      if (!mounted) return;
      final randevu = r['randevu'];
      Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeft,
          duration: const Duration(milliseconds: 400),
          child: RandevuAl(
            kisitTarihBas: randevu is Map ? randevu['tarih_bas']?.toString() : null,
            kisitTarihBit: randevu is Map ? randevu['tarih_bit']?.toString() : null,
            kisitSaatBas: randevu is Map ? randevu['saat_bas']?.toString() : null,
            kisitSaatBit: randevu is Map ? randevu['saat_bit']?.toString() : null,
          ),
        ),
      );
      return;
    }
    if (aksiyon != 'kupon') return; // 'yok' → sadece görsel

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final res =
          await reklamKuponKap(widget.md.id.toString(), r['id'].toString());
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // yükleniyor kapat
      if (res['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => _KuponKapildiDialog(
            mesaj: res['message']?.toString() ?? '🎉 Kuponun tanımlandı!',
            zaten: res['zaten'] == true,
          ),
        );
        _reklamlariYukle(); // toplam adet / durum tazele
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'İşlem başarısız oldu'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı hatası, tekrar deneyin')),
      );
    }
  }

  // ── MÜŞTERİ YORUMLARI CARD ───────────────────────────────────────────────
  Widget _yorumlarCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.appTheme;

    final ortalama = yorumOzeti?.ortalama ?? 0;
    final toplamYorum = yorumOzeti?.toplamYorum ?? 0;
    final toplamPuan = yorumOzeti?.toplamPuan ?? 0;
    final ortStr = ortalama.toStringAsFixed(1).replaceAll('.', ',');
    final tam = ortalama.floor();
    final yarim = (ortalama - tam) >= 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 350),
              child: const SalonYorumlariSayfasi(),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: ext.borderSubtle,
                width: 1,
              ),
              boxShadow: AppShadows.soft(scheme.primary),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFB400), Color(0xFFFF8A00)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33FFB400),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ortStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Müşteri Yorumları',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 1; i <= 5; i++) ...[
                            if (i > 1) const SizedBox(width: 1.5),
                            Icon(
                              i <= tam
                                  ? Icons.star_rounded
                                  : (i == tam + 1 && yarim
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded),
                              size: 14,
                              color: const Color(0xFFFFB400),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Text(
                            toplamYorum > 0
                                ? '$toplamYorum yorum · $toplamPuan puan'
                                : 'Henüz yorum yok',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: scheme.primary,
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
              onTap: () => _iletisimAksiyon(context, mode: 'ara'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _iletisimTile(
              context,
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              tint: const Color(0xFF25D366),
              onTap: () => _iletisimAksiyon(context, mode: 'wp'),
            ),
          ),
        ],
      ),
    );
  }

  /// Iletisim/WhatsApp aksiyonu: brand'in birden fazla subesi varsa BottomSheet
  /// icinde sube listesi acilir; tek sube (veya musteri_olunan_salonlar bos)
  /// ise dogrudan mevcut isletmebilgi uzerinden aranan/wp acilir.
  Future<void> _iletisimAksiyon(BuildContext context, {required String mode}) async {
    final subeler = _brandSubeleri();
    if (subeler.length > 1) {
      await _showSubeSecerekIletisim(context, subeler, mode);
      return;
    }
    // Tek sube (veya liste bos): mevcut isletmebilgi ile calis (geri uyum).
    if (mode == 'ara') {
      final phone = _resolveCallPhone();
      if (phone == null || phone.isEmpty) {
        _showSnack('Salonun arama numarası tanımlı değil.');
        return;
      }
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnack('Arama başlatılamadı.');
      }
    } else {
      final wp = _resolveWhatsappNumber();
      if (wp == null || wp.isEmpty) {
        _showSnack('Salonun WhatsApp numarası tanımlı değil.');
        return;
      }
      try {
        await WhatsAppOpener.openWhatsApp(
          wp,
          'Merhaba, bilgi / randevu almak istiyorum.',
        );
      } catch (_) {
        _showSnack('WhatsApp açılamadı.');
      }
    }
  }

  /// MusteriDanisan.musteri_olunan_salonlar listesinden {salon_id, salon_adi,
  /// telefon, whatsapp} nested map'lerini normalize et. mevcut isletmebilgi
  /// disinda da tum brand subeleri buradan gelir (login akisinda backend
  /// zaten brand app_bundle'a gore filtreliyor).
  List<Map<String, dynamic>> _brandSubeleri() {
    final list = widget.md.musteri_olunan_salonlar;
    if (list == null || list.isEmpty) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in list) {
      if (e is! Map) continue;
      final salon = e['salonlar'];
      if (salon is! Map) continue;
      final salonId = e['salon_id']?.toString() ?? salon['id']?.toString() ?? '';
      final adi = (salon['salon_adi'] ?? '').toString().trim();
      final tel = _pickField(salon, const ['telefon_1', 'telefon', 'telefonno', 'telefon_2']);
      final wp  = _pickField(salon, const ['whatsapp', 'whatsapp_numara', 'whatsappPhone', 'telefon_1', 'telefon']);
      out.add({
        'salon_id': salonId,
        'salon_adi': adi.isEmpty ? 'Şube' : adi,
        'telefon': tel,
        'whatsapp': wp,
      });
    }
    return out;
  }

  String? _pickField(Map salon, List<String> keys) {
    for (final k in keys) {
      final v = salon[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return null;
  }

  Future<void> _showSubeSecerekIletisim(
    BuildContext context,
    List<Map<String, dynamic>> subeler,
    String mode,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final baslik = mode == 'ara' ? 'Aranacak Şubeyi Seçin' : 'WhatsApp Şubesini Seçin';
    final tint = mode == 'ara' ? scheme.primary : const Color(0xFF25D366);
    final ikon = mode == 'ara' ? Icons.phone_rounded : Icons.chat_rounded;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4),
                  child: Text(
                    baslik,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: subeler.map((s) {
                  final adi = s['salon_adi'] as String;
                  final tel = s['telefon'] as String?;
                  final wp  = s['whatsapp'] as String?;
                  final aktifNumara = mode == 'ara' ? tel : wp;
                  final bilgi = mode == 'ara'
                      ? (tel ?? 'Telefon tanımsız')
                      : (wp ?? 'WhatsApp tanımsız');
                  final disable = aktifNumara == null || aktifNumara.isEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: disable ? Colors.grey.shade100 : tint.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: disable
                            ? null
                            : () async {
                                Navigator.of(ctx).pop();
                                if (mode == 'ara') {
                                  final uri = Uri.parse('tel:$aktifNumara');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  } else {
                                    _showSnack('Arama başlatılamadı.');
                                  }
                                } else {
                                  try {
                                    await WhatsAppOpener.openWhatsApp(
                                      _normalizeForWhatsApp(aktifNumara),
                                      'Merhaba, bilgi / randevu almak istiyorum.',
                                    );
                                  } catch (_) {
                                    _showSnack('WhatsApp açılamadı.');
                                  }
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: disable ? Colors.grey.shade300 : tint.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(ikon, color: disable ? Colors.grey.shade500 : tint, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      adi,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      bilgi,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (!disable)
                                const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  String? _readField(List<String> keys) {
    final b = widget.isletmebilgi;
    if (b is! Map) return null;
    for (final k in keys) {
      final v = b[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return null;
  }

  String? _resolveCallPhone() {
    return _readField(const [
      'telefon_1',
      'telefon',
      'telefonno',
      'telefon_2',
      'phone',
    ]);
  }

  String? _resolveWhatsappNumber() {
    final raw = _readField(const [
      'whatsapp',
      'whatsapp_numara',
      'whatsappPhone',
      'telefon_1',
      'telefon',
      'telefonno',
    ]);
    if (raw == null) return null;
    return _normalizeForWhatsApp(raw);
  }

  String _normalizeForWhatsApp(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return digits;
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = '90${digits.substring(1)}';
    if (!digits.startsWith('90') && digits.length == 10) digits = '90$digits';
    return digits;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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

// ── DÖNEN MİNİ ÇARKIFELEK İKONU ─────────────────────────────────────────────
// Web'deki /cark sayfasındaki çarkın küçük, sürekli yavaşça dönen versiyonu.
class _SpinningWheelIcon extends StatefulWidget {
  final double size;
  const _SpinningWheelIcon({this.size = 54});

  @override
  State<_SpinningWheelIcon> createState() => _SpinningWheelIconState();
}

class _SpinningWheelIconState extends State<_SpinningWheelIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Hafif glow halkası
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // Dönen çark
          RotationTransition(
            turns: _ctrl,
            child: CustomPaint(
              size: Size(s, s),
              painter: const _WheelPainter(),
            ),
          ),
          // Üstte pointer pin (sabit, dönmüyor)
          Positioned(
            top: -3,
            child: CustomPaint(
              size: Size(s * 0.18, s * 0.22),
              painter: const _WheelPinPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter();

  // Web'deki çark renkleri (carkifelek/_cark_widget.blade.php → :root)
  static const List<Color> _colors = [
    Color(0xFF6C5CE7), // ck-purple
    Color(0xFFFD79A8), // ck-pink
    Color(0xFFFDCB6E), // ck-gold
    Color(0xFF00B894), // ck-green
    Color(0xFFA29BFE), // ck-purple-l
    Color(0xFF74B9FF), // mavi
    Color(0xFFE17055), // turuncu
    Color(0xFFFFE66D), // sarı
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final n = _colors.length;
    final sweep = 2 * math.pi / n;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Dilimler
    for (int i = 0; i < n; i++) {
      final start = -math.pi / 2 + i * sweep;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(rect, start, sweep, false)
        ..close();
      canvas.drawPath(path, Paint()..color = _colors[i]);
    }

    // Dilim ayraçları (beyaz ince çizgiler)
    final lineP = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * sweep;
      canvas.drawLine(
        c,
        Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a)),
        lineP,
      );
    }

    // Dış halka
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Merkez göbek
    canvas.drawCircle(
      c,
      r * 0.20,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      c,
      r * 0.20,
      Paint()
        ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    canvas.drawCircle(
      c,
      r * 0.08,
      Paint()..color = const Color(0xFF6C5CE7),
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}

class _WheelPinPainter extends CustomPainter {
  const _WheelPinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Web'deki pin: kırmızı gradient üçgen + üstte küçük dikdörtgen
    final w = size.width, h = size.height;
    final triPath = Path()
      ..moveTo(w / 2, h)
      ..lineTo(0, h * 0.20)
      ..lineTo(w, h * 0.20)
      ..close();

    canvas.drawPath(
      triPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF7F1D1D), Color(0xFFEF4444), Color(0xFF7F1D1D)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Üstte tutucu
    final capRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h * 0.22),
      const Radius.circular(2),
    );
    canvas.drawRRect(capRect, Paint()..color = const Color(0xFFEF4444));
  }

  @override
  bool shouldRepaint(covariant _WheelPinPainter oldDelegate) => false;
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

/// Reklam görseline dokunup kupon kapıldığında gösterilen kutlama dialog'u.
/// zaten=true ise (kupon zaten alınmışsa) konfeti/haptic çalmaz.
class _KuponKapildiDialog extends StatefulWidget {
  final String mesaj;
  final bool zaten;
  const _KuponKapildiDialog({required this.mesaj, this.zaten = false});

  @override
  State<_KuponKapildiDialog> createState() => _KuponKapildiDialogState();
}

class _KuponKapildiDialogState extends State<_KuponKapildiDialog> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    if (!widget.zaten) {
      _confetti.play();
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.zaten ? '👍' : '🎉',
                  style: const TextStyle(fontSize: 54),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.zaten ? 'Zaten Senin' : 'Tebrikler!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.mesaj,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Harika!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!widget.zaten) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Kuponların "Ödüllerim" sayfasında',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 16,
          gravity: 0.25,
          emissionFrequency: 0.05,
          colors: const [
            Color(0xFF6C5CE7),
            Color(0xFFFD79A8),
            Color(0xFF00B894),
            Color(0xFFFDCB6E),
          ],
        ),
      ],
    );
  }
}
