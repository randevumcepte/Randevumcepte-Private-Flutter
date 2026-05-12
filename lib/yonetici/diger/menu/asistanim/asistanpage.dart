import 'package:flutter/material.dart';
import 'package:randevu_sistem/theme/premium_components.dart';
import 'package:randevu_sistem/yonetici/diger/menu/asistanim/yarinkigorevlerim.dart';

import 'bugunkugorevlerim.dart';

class AsistanimPage extends StatefulWidget {
  final dynamic isletmebilgi;
  const AsistanimPage({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  _AsistanimPageState createState() => _AsistanimPageState();
}

class _AsistanimPageState extends State<AsistanimPage> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          appBar: _buildPremiumAppBar(context, scheme),
          body: PremiumGradientBg(
            child: SafeArea(
              top: false,
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: BugunlukGorevler(isletmebilgi: widget.isletmebilgi),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: YarinkiGorevler(isletmebilgi: widget.isletmebilgi),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar(
      BuildContext context, ColorScheme scheme) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(168),
      child: ClipRect(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.32), Colors.white),
                Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.18), Colors.white),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PremiumCircleAction(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Asistanım',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bugün ve yarın için arama görevlerin',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface.withValues(alpha: 0.60),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PremiumPillTabBar(scheme: scheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumPillTabBar extends StatelessWidget {
  final ColorScheme scheme;
  const _PremiumPillTabBar({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TabBar(
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: scheme.onPrimary,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.65),
        labelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        labelPadding: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        splashBorderRadius: BorderRadius.circular(999),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.32),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.today_rounded, size: 16),
                SizedBox(width: 6),
                Text('Bugünkü Görevlerim'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_rounded, size: 16),
                SizedBox(width: 6),
                Text('Yarınki Görevlerim'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
