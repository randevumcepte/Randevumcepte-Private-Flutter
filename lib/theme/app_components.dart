import 'package:flutter/material.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';

/// Modern, soft-elevation card. 1px border + ultra-subtle shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final VoidCallback? onTap;
  final Color? color;
  final bool elevated;
  final BorderSide? overrideBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.l),
    this.radius,
    this.onTap,
    this.color,
    this.elevated = false,
    this.overrideBorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.appTheme;
    final r = radius ?? AppRadius.lg;

    final container = AnimatedContainer(
      duration: AppDuration.fast,
      curve: AppCurves.standard,
      decoration: BoxDecoration(
        color: color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(r),
        border: Border.fromBorderSide(
          overrideBorder ??
              BorderSide(color: ext.borderSubtle, width: 1),
        ),
        boxShadow:
            elevated ? AppShadows.elevated(ext.shadowBase) : null,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        child: container,
      ),
    );
  }
}

/// Section header with optional trailing action.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding =
        const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.s),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
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

/// Pill / chip with optional leading icon. Stadium border, soft fill.
class AppPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.primary;
    final bg = backgroundColor ?? fg.withValues(alpha: 0.10);

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: (fontSize ?? 12) + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
