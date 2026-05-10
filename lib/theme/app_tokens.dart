import 'package:flutter/material.dart';

class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

class AppDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);
}

class AppCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve bouncy = Curves.easeOutBack;
}

class AppShadows {
  static List<BoxShadow> soft(Color base) => [
        BoxShadow(
          color: base.withValues(alpha: 0.04),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: base.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> elevated(Color base) => [
        BoxShadow(
          color: base.withValues(alpha: 0.05),
          blurRadius: 2,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: base.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> tinted(Color tint, {double strength = 1}) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.10 * strength),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: tint.withValues(alpha: 0.04 * strength),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
}

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color surfaceMuted;
  final Color surfaceTinted;
  final Color borderSubtle;
  final Color borderStrong;
  final Color shadowBase;
  final Color successColor;
  final Color warningColor;
  final Color infoColor;
  final Gradient heroGradient;

  const AppThemeExtension({
    required this.surfaceMuted,
    required this.surfaceTinted,
    required this.borderSubtle,
    required this.borderStrong,
    required this.shadowBase,
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
    required this.heroGradient,
  });

  @override
  AppThemeExtension copyWith({
    Color? surfaceMuted,
    Color? surfaceTinted,
    Color? borderSubtle,
    Color? borderStrong,
    Color? shadowBase,
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    Gradient? heroGradient,
  }) {
    return AppThemeExtension(
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceTinted: surfaceTinted ?? this.surfaceTinted,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      shadowBase: shadowBase ?? this.shadowBase,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceTinted: Color.lerp(surfaceTinted, other.surfaceTinted, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      shadowBase: Color.lerp(shadowBase, other.shadowBase, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      heroGradient: t < 0.5 ? heroGradient : other.heroGradient,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()!;

  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
