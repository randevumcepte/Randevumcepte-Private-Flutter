import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:randevu_sistem/theme/app_tokens.dart';

enum AppThemePreset {
  morLuks('mor_luks'),
  pastelLavanta('pastel_lavanta'),
  pastelSeftali('pastel_seftali'),
  pastelMint('pastel_mint'),
  pastelBebeMavi('pastel_bebe_mavi'),
  pastelPembe('pastel_pembe'),
  pastelSari('pastel_sari'),
  okyanus('okyanus'),
  yesilNaturel('yesil_naturel'),
  gulPembesi('gul_pembesi'),
  altinKaramel('altin_karamel'),
  mercanCorali('mercan_corali'),
  siyahBeyaz('siyah_beyaz'),
  gri('gri'),
  antrasit('antrasit'),
  klasikKoyu('klasik_koyu'),
  ozel('ozel');

  final String key;
  const AppThemePreset(this.key);

  static AppThemePreset fromKey(String? k) {
    if (k == null) return morLuks;
    return AppThemePreset.values.firstWhere(
      (p) => p.key == k,
      orElse: () => morLuks,
    );
  }
}

enum AppBrightnessMode {
  light('light'),
  dark('dark'),
  system('system');

  final String key;
  const AppBrightnessMode(this.key);

  static AppBrightnessMode fromKey(String? k) {
    if (k == null) return light;
    return AppBrightnessMode.values.firstWhere(
      (p) => p.key == k,
      orElse: () => light,
    );
  }
}

@immutable
class AppThemePresetSpec {
  final AppThemePreset preset;
  final String displayName;
  final String description;
  final String emoji;
  final Color seedColor;
  final Color accentColor;
  final Brightness defaultBrightness;

  const AppThemePresetSpec({
    required this.preset,
    required this.displayName,
    required this.description,
    required this.emoji,
    required this.seedColor,
    required this.accentColor,
    this.defaultBrightness = Brightness.light,
  });
}

class AppThemeCatalog {
  static const Map<AppThemePreset, AppThemePresetSpec> presets = {
    AppThemePreset.morLuks: AppThemePresetSpec(
      preset: AppThemePreset.morLuks,
      displayName: 'Mor Lüks',
      description: 'Premium ve canlı mor — markaya güç katar',
      emoji: '💜',
      seedColor: Color(0xFF7C3AED),
      accentColor: Color(0xFFA855F7),
    ),
    AppThemePreset.pastelLavanta: AppThemePresetSpec(
      preset: AppThemePreset.pastelLavanta,
      displayName: 'Pastel Lavanta',
      description: 'Yumuşak, ferah, salon hissi',
      emoji: '🌸',
      seedColor: Color(0xFFB794F4),
      accentColor: Color(0xFFFBCFE8),
    ),
    AppThemePreset.pastelSeftali: AppThemePresetSpec(
      preset: AppThemePreset.pastelSeftali,
      displayName: 'Pastel Şeftali',
      description: 'Sıcak, davetkar şeftali tonları',
      emoji: '🍑',
      seedColor: Color(0xFFFB923C),
      accentColor: Color(0xFFFED7AA),
    ),
    AppThemePreset.pastelMint: AppThemePresetSpec(
      preset: AppThemePreset.pastelMint,
      displayName: 'Pastel Mint',
      description: 'Serin, ferah, dingin',
      emoji: '🍃',
      seedColor: Color(0xFF5EEAD4),
      accentColor: Color(0xFFA7F3D0),
    ),
    AppThemePreset.pastelBebeMavi: AppThemePresetSpec(
      preset: AppThemePreset.pastelBebeMavi,
      displayName: 'Pastel Bebe Mavi',
      description: 'Bulut tonu, hafif ve nazik',
      emoji: '☁️',
      seedColor: Color(0xFF93C5FD),
      accentColor: Color(0xFFBFDBFE),
    ),
    AppThemePreset.pastelPembe: AppThemePresetSpec(
      preset: AppThemePreset.pastelPembe,
      displayName: 'Pastel Pembe',
      description: 'Tatlı, bebek pembesi',
      emoji: '🌷',
      seedColor: Color(0xFFF9A8D4),
      accentColor: Color(0xFFFBCFE8),
    ),
    AppThemePreset.pastelSari: AppThemePresetSpec(
      preset: AppThemePreset.pastelSari,
      displayName: 'Pastel Sarı',
      description: 'Güneşli, neşeli, enerjik',
      emoji: '🌼',
      seedColor: Color(0xFFFCD34D),
      accentColor: Color(0xFFFEF3C7),
    ),
    AppThemePreset.okyanus: AppThemePresetSpec(
      preset: AppThemePreset.okyanus,
      displayName: 'Okyanus',
      description: 'Berrak gök ve turkuaz',
      emoji: '🌊',
      seedColor: Color(0xFF0EA5E9),
      accentColor: Color(0xFF06B6D4),
    ),
    AppThemePreset.yesilNaturel: AppThemePresetSpec(
      preset: AppThemePreset.yesilNaturel,
      displayName: 'Yeşil Naturel',
      description: 'Doğal, sakin ve dengeli',
      emoji: '🌿',
      seedColor: Color(0xFF10B981),
      accentColor: Color(0xFF84CC16),
    ),
    AppThemePreset.gulPembesi: AppThemePresetSpec(
      preset: AppThemePreset.gulPembesi,
      displayName: 'Gül Pembesi',
      description: 'Zarif, sıcak ve feminen',
      emoji: '🌹',
      seedColor: Color(0xFFEC4899),
      accentColor: Color(0xFFF472B6),
    ),
    AppThemePreset.altinKaramel: AppThemePresetSpec(
      preset: AppThemePreset.altinKaramel,
      displayName: 'Altın Karamel',
      description: 'Sıcak bronz, lüks dokunuş',
      emoji: '🥂',
      seedColor: Color(0xFFD97706),
      accentColor: Color(0xFFB45309),
    ),
    AppThemePreset.mercanCorali: AppThemePresetSpec(
      preset: AppThemePreset.mercanCorali,
      displayName: 'Mercan Şeftali',
      description: 'Diri, enerjik, modern',
      emoji: '🪸',
      seedColor: Color(0xFFFB7185),
      accentColor: Color(0xFFF43F5E),
    ),
    AppThemePreset.siyahBeyaz: AppThemePresetSpec(
      preset: AppThemePreset.siyahBeyaz,
      displayName: 'Siyah Beyaz',
      description: 'Klasik, zarif ve zamansız',
      emoji: '⚫',
      seedColor: Color(0xFF1F2937),
      accentColor: Color(0xFF4B5563),
    ),
    AppThemePreset.gri: AppThemePresetSpec(
      preset: AppThemePreset.gri,
      displayName: 'Gri',
      description: 'Sade ve nötr — modern minimal',
      emoji: '🌫️',
      seedColor: Color(0xFF6B7280),
      accentColor: Color(0xFF9CA3AF),
    ),
    AppThemePreset.antrasit: AppThemePresetSpec(
      preset: AppThemePreset.antrasit,
      displayName: 'Antrasit',
      description: 'Profesyonel, ciddi ve güçlü',
      emoji: '🪨',
      seedColor: Color(0xFF334155),
      accentColor: Color(0xFF475569),
    ),
    AppThemePreset.klasikKoyu: AppThemePresetSpec(
      preset: AppThemePreset.klasikKoyu,
      displayName: 'Klasik Koyu',
      description: 'Premium koyu — gözleri yormaz',
      emoji: '🌙',
      seedColor: Color(0xFF6366F1),
      accentColor: Color(0xFF818CF8),
      defaultBrightness: Brightness.dark,
    ),
  };

  static AppThemePresetSpec specOf(AppThemePreset preset) {
    return presets[preset] ?? presets[AppThemePreset.morLuks]!;
  }

  static List<AppThemePresetSpec> get visiblePresets => presets.values.toList();
}

@immutable
class AppThemeConfig {
  final AppThemePreset preset;
  final int? customSeedArgb;
  final AppBrightnessMode brightnessMode;

  const AppThemeConfig({
    this.preset = AppThemePreset.morLuks,
    this.customSeedArgb,
    this.brightnessMode = AppBrightnessMode.light,
  });

  static const AppThemeConfig defaults = AppThemeConfig();

  Color get effectiveSeedColor {
    if (preset == AppThemePreset.ozel && customSeedArgb != null) {
      return Color(customSeedArgb!);
    }
    return AppThemeCatalog.specOf(preset).seedColor;
  }

  Brightness resolveBrightness(Brightness platformBrightness) {
    switch (brightnessMode) {
      case AppBrightnessMode.light:
        return Brightness.light;
      case AppBrightnessMode.dark:
        return Brightness.dark;
      case AppBrightnessMode.system:
        return platformBrightness;
    }
  }

  AppThemeConfig copyWith({
    AppThemePreset? preset,
    int? customSeedArgb,
    bool resetCustomSeed = false,
    AppBrightnessMode? brightnessMode,
  }) {
    return AppThemeConfig(
      preset: preset ?? this.preset,
      customSeedArgb: resetCustomSeed
          ? null
          : (customSeedArgb ?? this.customSeedArgb),
      brightnessMode: brightnessMode ?? this.brightnessMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'preset': preset.key,
        if (customSeedArgb != null) 'customSeedArgb': customSeedArgb,
        'brightnessMode': brightnessMode.key,
      };

  factory AppThemeConfig.fromJson(Map<String, dynamic> json) {
    return AppThemeConfig(
      preset: AppThemePreset.fromKey(json['preset'] as String?),
      customSeedArgb: (json['customSeedArgb'] as num?)?.toInt(),
      brightnessMode:
          AppBrightnessMode.fromKey(json['brightnessMode'] as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppThemeConfig &&
      other.preset == preset &&
      other.customSeedArgb == customSeedArgb &&
      other.brightnessMode == brightnessMode;

  @override
  int get hashCode => Object.hash(preset, customSeedArgb, brightnessMode);
}

class AppTheme {
  static ThemeData fromConfig(
    AppThemeConfig config, {
    required Brightness platformBrightness,
  }) {
    final brightness = config.resolveBrightness(platformBrightness);
    final seed = config.effectiveSeedColor;

    final ColorScheme scheme;
    if (config.preset == AppThemePreset.siyahBeyaz) {
      scheme = _siyahBeyazScheme(brightness);
    } else if (config.preset == AppThemePreset.gri) {
      scheme = _griScheme(brightness);
    } else if (config.preset == AppThemePreset.antrasit) {
      scheme = _antrasitScheme(brightness);
    } else {
      scheme = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      );
    }

    return _buildTheme(scheme);
  }

  /// Nötr orta gri — düz cool gray tonları
  static ColorScheme _griScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const ColorScheme.dark(
        primary: Color(0xFFD1D5DB),
        onPrimary: Color(0xFF1F2937),
        secondary: Color(0xFF9CA3AF),
        onSecondary: Color(0xFF111827),
        tertiary: Color(0xFF6B7280),
        onTertiary: Colors.white,
        surface: Color(0xFF1F2937),
        onSurface: Color(0xFFE5E7EB),
        error: Color(0xFFEF4444),
        onError: Colors.white,
      );
    }
    return const ColorScheme.light(
      primary: Color(0xFF4B5563),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE5E7EB),
      onPrimaryContainer: Color(0xFF1F2937),
      secondary: Color(0xFF6B7280),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF3F4F6),
      onSecondaryContainer: Color(0xFF374151),
      tertiary: Color(0xFF9CA3AF),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFF9FAFB),
      onTertiaryContainer: Color(0xFF4B5563),
      surface: Colors.white,
      onSurface: Color(0xFF1F2937),
      error: Color(0xFFB91C1C),
      onError: Colors.white,
    );
  }

  /// Antrasit — koyu slate-blue, profesyonel
  static ColorScheme _antrasitScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const ColorScheme.dark(
        primary: Color(0xFF94A3B8),
        onPrimary: Color(0xFF0F172A),
        secondary: Color(0xFF64748B),
        onSecondary: Colors.white,
        tertiary: Color(0xFF475569),
        onTertiary: Colors.white,
        surface: Color(0xFF0F172A),
        onSurface: Color(0xFFE2E8F0),
        error: Color(0xFFEF4444),
        onError: Colors.white,
      );
    }
    return const ColorScheme.light(
      primary: Color(0xFF1E293B),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE2E8F0),
      onPrimaryContainer: Color(0xFF0F172A),
      secondary: Color(0xFF475569),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF1F5F9),
      onSecondaryContainer: Color(0xFF1E293B),
      tertiary: Color(0xFF64748B),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFF8FAFC),
      onTertiaryContainer: Color(0xFF334155),
      surface: Colors.white,
      onSurface: Color(0xFF0F172A),
      error: Color(0xFFB91C1C),
      onError: Colors.white,
    );
  }

  /// Gerçek monochrome siyah-beyaz scheme — M3.fromSeed bunu yapamadığı için
  /// (pure black seed bile slate tonları üretiyor) manuel override.
  static ColorScheme _siyahBeyazScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Color(0xFF0A0A0A),
        primaryContainer: Color(0xFF2A2A2A),
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFFD1D5DB),
        onSecondary: Color(0xFF0A0A0A),
        secondaryContainer: Color(0xFF1F1F1F),
        onSecondaryContainer: Colors.white,
        tertiary: Color(0xFF9CA3AF),
        onTertiary: Color(0xFF0A0A0A),
        tertiaryContainer: Color(0xFF374151),
        onTertiaryContainer: Colors.white,
        surface: Color(0xFF0F0F0F),
        onSurface: Colors.white,
        surfaceContainerLowest: Color(0xFF050505),
        surfaceContainerLow: Color(0xFF141414),
        surfaceContainer: Color(0xFF1A1A1A),
        surfaceContainerHigh: Color(0xFF222222),
        surfaceContainerHighest: Color(0xFF2A2A2A),
        outline: Color(0xFF6B7280),
        outlineVariant: Color(0xFF374151),
        error: Color(0xFFEF4444),
        onError: Colors.white,
      );
    }
    return const ColorScheme.light(
      primary: Color(0xFF0A0A0A),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEFEFEF),
      onPrimaryContainer: Color(0xFF0A0A0A),
      secondary: Color(0xFF1F2937),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF3F4F6),
      onSecondaryContainer: Color(0xFF111827),
      tertiary: Color(0xFF6B7280),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE5E7EB),
      onTertiaryContainer: Color(0xFF1F2937),
      surface: Colors.white,
      onSurface: Color(0xFF0A0A0A),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFFAFAFA),
      surfaceContainer: Color(0xFFF5F5F5),
      surfaceContainerHigh: Color(0xFFEEEEEE),
      surfaceContainerHighest: Color(0xFFE5E7EB),
      outline: Color(0xFFD1D5DB),
      outlineVariant: Color(0xFFE5E7EB),
      error: Color(0xFFB91C1C),
      onError: Colors.white,
    );
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    // Light tema'da arkaplanı tema seed rengi ile %8 oranında karıştır →
    // Pastel Pembe seçince hafif pembe wash, Mor seçince hafif mor wash.
    // Dark tema'da M3'ün doğal koyu surface'i kalsın.
    final scaffoldBg = isDark
        ? scheme.surface
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.08),
            Colors.white,
          );
    final cardBg = isDark
        ? scheme.surfaceContainerLow
        : Colors.white;
    final mutedSurface = isDark
        ? scheme.surfaceContainerHigh
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.05),
            Colors.white,
          );

    final baseText = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    final textTheme = baseText
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          displayLarge: baseText.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
          displayMedium: baseText.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: scheme.onSurface,
          ),
          displaySmall: baseText.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
          headlineLarge: baseText.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
          headlineMedium: baseText.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: scheme.onSurface,
          ),
          headlineSmall: baseText.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            color: scheme.onSurface,
          ),
          titleLarge: baseText.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            color: scheme.onSurface,
          ),
          titleMedium: baseText.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          titleSmall: baseText.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          labelLarge: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          bodyLarge: baseText.bodyLarge?.copyWith(
            color: scheme.onSurface,
            height: 1.45,
          ),
          bodyMedium: baseText.bodyMedium?.copyWith(
            color: scheme.onSurface,
            height: 1.45,
          ),
          bodySmall: baseText.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        );

    final extension = AppThemeExtension(
      surfaceMuted: mutedSurface,
      surfaceTinted: scheme.primaryContainer,
      borderSubtle: scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
      borderStrong: scheme.outline.withValues(alpha: isDark ? 0.6 : 0.8),
      shadowBase: isDark ? Colors.black : const Color(0xFF0F172A),
      successColor: const Color(0xFF10B981),
      warningColor: const Color(0xFFF59E0B),
      infoColor: const Color(0xFF3B82F6),
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primary,
          Color.lerp(scheme.primary, scheme.tertiary, 0.6)!,
        ],
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(
        color: scheme.onSurfaceVariant,
        size: 22,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 22),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: scheme.outlineVariant
                .withValues(alpha: isDark ? 0.4 : 0.5),
            width: 1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          side: BorderSide(color: scheme.outline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mutedSurface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: mutedSurface,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        height: 72,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [extension],
    );
  }
}
