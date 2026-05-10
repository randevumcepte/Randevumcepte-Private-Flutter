import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:randevu_sistem/theme/app_components.dart';
import 'package:randevu_sistem/theme/app_components_extra.dart';
import 'package:randevu_sistem/theme/app_theme.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';
import 'package:randevu_sistem/theme/theme_provider.dart';

class ThemePickerScreen extends StatelessWidget {
  /// canEditServer == true ise değişiklikler salonun tüm kullanıcılarına yansır.
  /// false ise sadece o cihazda kalır (çalışan/müşteri).
  final bool canEditServer;

  const ThemePickerScreen({super.key, this.canEditServer = false});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final config = themeProvider.config;
    final activeSpec = config.preset == AppThemePreset.ozel
        ? null
        : AppThemeCatalog.specOf(config.preset);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görünüm'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.huge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner — aktif tema önizlemesi
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
                vertical: AppSpacing.s,
              ),
              child: AppHeroBanner(
                title: activeSpec?.displayName ?? 'Özel Tema',
                subtitle: activeSpec?.description ??
                    'Kendi seçtiğin renge göre oluşturuldu',
                trailing: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      activeSpec?.emoji ?? '🎨',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),
            ),

            // Mod (Aydınlık/Koyu/Sistem)
            const AppSectionHeader(
              title: 'Görünüm Modu',
              subtitle: 'Aydınlık, koyu veya cihaz ayarına bağla',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: _BrightnessSegmented(
                value: config.brightnessMode,
                onChanged: (mode) => context
                    .read<ThemeProvider>()
                    .setBrightnessMode(mode, canEditServer: canEditServer),
              ),
            ),

            // Hazır temalar
            const AppSectionHeader(
              title: 'Hazır Temalar',
              subtitle: 'Salonuna uygun bir tarz seç',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: _PresetGrid(
                activePreset: config.preset,
                onSelect: (preset) => context
                    .read<ThemeProvider>()
                    .setPreset(preset, canEditServer: canEditServer),
              ),
            ),

            // Özel renk
            const AppSectionHeader(
              title: 'Özel Renk',
              subtitle: 'İstediğin renkten otomatik palet üretelim',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: _CustomColorRow(
                isActive: config.preset == AppThemePreset.ozel,
                currentArgb: config.customSeedArgb,
                onPick: (color) => context
                    .read<ThemeProvider>()
                    .setCustomSeed(color.toARGB32(),
                        canEditServer: canEditServer),
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Yetki bilgisi — sadece çalışan/müşteri için
            if (!canEditServer)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.s,
                ),
                child: AppCard(
                  color: context.colors.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          'Bu tema yalnızca bu cihazda görünür. Salon genelinde değiştirme yetkisi yöneticide.',
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Sync durumu
            if (themeProvider.isSyncing)
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.s,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('Tema bilgisi senkronize ediliyor…'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrightnessSegmented extends StatelessWidget {
  final AppBrightnessMode value;
  final ValueChanged<AppBrightnessMode> onChanged;

  const _BrightnessSegmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Container(
      decoration: BoxDecoration(
        color: ext.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _segment(context, AppBrightnessMode.light, 'Aydınlık',
              Icons.light_mode_rounded),
          _segment(
              context, AppBrightnessMode.dark, 'Koyu', Icons.dark_mode_rounded),
          _segment(context, AppBrightnessMode.system, 'Sistem',
              Icons.settings_suggest_rounded),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    AppBrightnessMode mode,
    String label,
    IconData icon,
  ) {
    final selected = value == mode;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: AppDuration.fast,
          curve: AppCurves.standard,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: selected
                ? AppShadows.soft(context.appTheme.shadowBase)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? context.colors.onSurface
                      : context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetGrid extends StatelessWidget {
  final AppThemePreset activePreset;
  final ValueChanged<AppThemePreset> onSelect;

  const _PresetGrid({required this.activePreset, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 720 ? 3 : 2;
    final specs = AppThemeCatalog.visiblePresets;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: specs.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.m,
        mainAxisSpacing: AppSpacing.m,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) {
        final spec = specs[i];
        final isActive = activePreset == spec.preset;
        return _PresetCard(
          spec: spec,
          isActive: isActive,
          onTap: () => onSelect(spec.preset),
        );
      },
    );
  }
}

class _PresetCard extends StatelessWidget {
  final AppThemePresetSpec spec;
  final bool isActive;
  final VoidCallback onTap;

  const _PresetCard({
    required this.spec,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.fast,
      curve: AppCurves.standard,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isActive
              ? context.colors.primary
              : context.appTheme.borderSubtle,
          width: isActive ? 2 : 1,
        ),
        color: context.colors.surface,
        boxShadow: isActive
            ? AppShadows.tinted(spec.seedColor, strength: 0.8)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Swatch — gradient
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [spec.seedColor, spec.accentColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: AnimatedScale(
                            duration: AppDuration.fast,
                            scale: isActive ? 1 : 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: spec.seedColor,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 10,
                          child: Text(
                            spec.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    spec.displayName,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spec.description,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _CustomColorRow extends StatelessWidget {
  final bool isActive;
  final int? currentArgb;
  final ValueChanged<Color> onPick;

  const _CustomColorRow({
    required this.isActive,
    required this.currentArgb,
    required this.onPick,
  });

  static const List<Color> _swatches = [
    Color(0xFFEF4444), // red
    Color(0xFFF97316), // orange
    Color(0xFFF59E0B), // amber
    Color(0xFF84CC16), // lime
    Color(0xFF14B8A6), // teal
    Color(0xFF0EA5E9), // sky
    Color(0xFF6366F1), // indigo
    Color(0xFF8B5CF6), // violet
    Color(0xFFD946EF), // fuchsia
    Color(0xFFEC4899), // pink
    Color(0xFF64748B), // slate
    Color(0xFF1F2937), // dark
  ];

  @override
  Widget build(BuildContext context) {
    final activeColor = currentArgb != null ? Color(currentArgb!) : null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: activeColor ?? context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: context.appTheme.borderSubtle,
                    width: 1,
                  ),
                ),
                child: activeColor == null
                    ? Icon(
                        Icons.colorize_rounded,
                        color: context.colors.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Özel renk aktif' : 'Bir renk seç',
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isActive
                          ? 'Aşağıdan farklı bir tona geçebilirsin'
                          : 'Hazır temaların yerine kendi tonun',
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in _swatches)
                _SwatchTile(
                  color: c,
                  selected: activeColor != null &&
                      _argbEquals(activeColor, c),
                  onTap: () => onPick(c),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _argbEquals(Color a, Color b) {
    return a.toARGB32() == b.toARGB32();
  }
}

class _SwatchTile extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SwatchTile({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        curve: AppCurves.standard,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? context.colors.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.30),
              blurRadius: selected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}
