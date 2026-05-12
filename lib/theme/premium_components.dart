import 'package:flutter/material.dart';

/// Premium dashboard tasarımında kullanılan paylaşılan bileşenler.
/// Diğer ekranları aynı dile getirirken bu yapı taşları kullanılır.

/// Premium scaffold gradient — referans resimdeki "mor → beyaz wash".
/// Tema seed rengiyle hesaplanır → Pastel Pembe seçince pembe, Mor seçince mor wash.
class PremiumGradientBg extends StatelessWidget {
  final Widget child;
  const PremiumGradientBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.50, 1.0],
          colors: [
            Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.32), Colors.white),
            Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.14), Colors.white),
            Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.10), Colors.white),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Premium beyaz kart — soft tinted shadow, 20px radius. Çoğu içerik için kullan.
class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? shadowTint;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
    this.shadowTint,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = shadowTint ?? scheme.primary;
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: box,
      ),
    );
  }
}

/// 44x44 daire içinde icon (notification bell, profile vs.). Optional badge.
class PremiumCircleAction extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;
  final Color? iconColor;

  const PremiumCircleAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor ?? scheme.primary, size: 20),
            ),
          ),
        ),
        if (badge != null && badge!.isNotEmpty && badge != '0')
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pill formatlı stat: icon + value + label. Yatay scroll satırlarında kullan.
class PremiumQuickPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  const PremiumQuickPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: tint),
          ),
          const SizedBox(width: 9),
          Column(
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
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// Tema gradient li action button (FAB benzeri ama küçük pill). "Çevir", "Yeni Randevu" vb.
class PremiumGradientPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PremiumGradientPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: scheme.onPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium section header — sol "Başlık", sağ "Tümü →" (opsiyonel).
class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final EdgeInsetsGeometry padding;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: scheme.onSurface,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                children: [
                  Text(
                    'Tümü',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: scheme.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Premium uyarı dialog'u — "Bu numara zaten kayıtlı" gibi durumlar için.
/// Tek bir Tamam butonuyla dismiss edilir. tone = warning (orange) | error (red) | success (green) | info (primary).
Future<void> showPremiumWarning(
  BuildContext context, {
  required String title,
  required String message,
  String okLabel = 'Tamam',
  String tone = 'warning',
}) {
  final scheme = Theme.of(context).colorScheme;
  Color accent;
  IconData icon;
  switch (tone) {
    case 'error':
      accent = const Color(0xFFDC2626);
      icon = Icons.error_outline_rounded;
      break;
    case 'success':
      accent = const Color(0xFF16A34A);
      icon = Icons.check_circle_outline_rounded;
      break;
    case 'info':
      accent = scheme.primary;
      icon = Icons.info_outline_rounded;
      break;
    case 'warning':
    default:
      accent = const Color(0xFFD97706);
      icon = Icons.warning_amber_rounded;
      break;
  }
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.40),
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.20),
                blurRadius: 28,
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.20),
                        accent.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 30),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.70),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => Navigator.of(ctx).pop(),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        okLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
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
