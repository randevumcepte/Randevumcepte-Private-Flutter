import 'package:flutter/material.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';

/// Modern empty state — used when a list has no data.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                icon,
                size: 32,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              title,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.l),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Hero gradient banner — used at the top of dashboards or pickers.
class AppHeroBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double? height;

  const AppHeroBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;

    return Container(
      width: double.infinity,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: ext.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.tinted(context.colors.primary, strength: 0.6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: context.text.titleLarge?.copyWith(
                    color: context.colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: context.text.bodyMedium?.copyWith(
                      color:
                          context.colors.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Color swatch dot used in theme picker.
class AppColorDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool selected;
  final VoidCallback? onTap;

  const AppColorDot({
    super.key,
    required this.color,
    this.size = 32,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dot = AnimatedContainer(
      duration: AppDuration.fast,
      curve: AppCurves.standard,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? context.colors.primary
              : Colors.white.withValues(alpha: 0.6),
          width: selected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: selected
          ? Icon(Icons.check, size: size * 0.5, color: Colors.white)
          : null,
    );

    if (onTap == null) return dot;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: dot,
    );
  }
}
