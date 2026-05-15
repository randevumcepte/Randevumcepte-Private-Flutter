import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

import 'beklenenformlar.dart';
import 'formekle.dart';
import 'form_sablonlari.dart';
import 'haricibelge.dart';
import 'haricibelgeekle.dart';
import 'iptaledilenformlar.dart';
import 'onaylananformlar.dart';
import 'sozlesme_olustur.dart';
import 'tumarsiv.dart';

class ArsivYonetimiPage extends StatefulWidget {
  final dynamic isletmebilgi;
  const ArsivYonetimiPage({super.key, required this.isletmebilgi});

  @override
  State<ArsivYonetimiPage> createState() => _ArsivYonetimiPageState();
}

class _ArsivYonetimiPageState extends State<ArsivYonetimiPage> {
  void _yeniSec(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'Yeni Oluştur',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                _SecimSatiri(
                  icon: Icons.send_rounded,
                  baslik: 'Form Gönder',
                  altYazi: 'Müşteriye onam/anket formu gönder',
                  renk: const Color(0xFF16A34A),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                        child: FormEkle(isletmebilgi: widget.isletmebilgi),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SecimSatiri(
                  icon: Icons.handshake_outlined,
                  baslik: 'Sözleşme Oluştur',
                  altYazi: 'Hizmet sözleşmesi hazırla ve gönder',
                  renk: const Color(0xFF0EA5E9),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                        child: SozlesmeOlustur(
                            isletmebilgi: widget.isletmebilgi),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SecimSatiri(
                  icon: Icons.upload_file_rounded,
                  baslik: 'Belge Ekle',
                  altYazi: 'Harici bir belgeyi sisteme yükle',
                  renk: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                        child: HariciBelgeEkle(
                            isletmebilgi: widget.isletmebilgi),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDemo = widget.isletmebilgi["demo_hesabi"].toString() == "1";

    return PremiumGradientBg(
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  _PremiumHeader(
                    onBack: () => Navigator.of(context).pop(),
                    onYeni: () => _yeniSec(context),
                    isDemo: isDemo,
                    isletmebilgi: widget.isletmebilgi,
                  ),
                  const SizedBox(height: 6),
                  _PremiumTabBar(scheme: scheme),
                  const SizedBox(height: 4),
                  Expanded(
                    child: TabBarView(
                      children: <Widget>[
                        TumArsiv(),
                        OnaylananArsiv(),
                        BeklenenArsiv(),
                        IptalEdilenArsiv(),
                        HariciArsiv(),
                        FormSablonlari(isletmebilgi: widget.isletmebilgi),
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
}

class _PremiumHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onYeni;
  final bool isDemo;
  final dynamic isletmebilgi;

  const _PremiumHeader({
    required this.onBack,
    required this.onYeni,
    required this.isDemo,
    required this.isletmebilgi,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          PremiumCircleAction(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Form Yönetimi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Form ve sözleşmeleri yönet',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          if (isDemo)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 92,
                child: YukseltButonu(isletme_bilgi: isletmebilgi),
              ),
            ),
          PremiumGradientPill(
            icon: Icons.add_rounded,
            label: 'Yeni',
            onTap: onYeni,
          ),
        ],
      ),
    );
  }
}

class _PremiumTabBar extends StatelessWidget {
  final ColorScheme scheme;
  const _PremiumTabBar({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        indicator: const BoxDecoration(),
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        labelColor: scheme.onPrimary,
        unselectedLabelColor: scheme.primary,
        tabs: const [
          _PillTab(text: 'Tümü'),
          _PillTab(text: 'Onaylananlar'),
          _PillTab(text: 'Beklenenler'),
          _PillTab(text: 'İptal Edilenler'),
          _PillTab(text: 'Harici Belgeler'),
          _PillTab(text: 'Form Şablonları'),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String text;
  const _PillTab({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller.animation!,
      builder: (context, _) {
        final indeks = controller.index;
        final benimIndex = _bul(context, text);
        final aktif = indeks == benimIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: aktif
                ? LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: aktif ? null : Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: aktif
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: aktif ? scheme.onPrimary : scheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  static const _siralama = [
    'Tümü',
    'Onaylananlar',
    'Beklenenler',
    'İptal Edilenler',
    'Harici Belgeler',
    'Form Şablonları',
  ];
  int _bul(BuildContext context, String t) => _siralama.indexOf(t);
}

class _SecimSatiri extends StatelessWidget {
  final IconData icon;
  final String baslik;
  final String altYazi;
  final Color renk;
  final VoidCallback onTap;
  const _SecimSatiri({
    required this.icon,
    required this.baslik,
    required this.altYazi,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: renk.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: renk, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      altYazi,
                      style: const TextStyle(
                          fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: renk),
            ],
          ),
        ),
      ),
    );
  }
}
