import 'package:flutter/material.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

/// Günlük rapor sayfaları (Randevular, Ön Görüşme, Paket/Ürün Satışı,
/// Alacaklar) icin ortak modern UI parcalari. Tum sayfalarin gorunumunu
/// uygulamanin geri kalaniyla (ornegin hizmetler.dart) tutarli kilar.
class RaporUi {
  /// Sayfa basligi + geri butonu + alt cizgili modern AppBar.
  static PreferredSizeWidget appBar(
    BuildContext context,
    String title, {
    List<Widget> actions = const [],
  }) {
    final cs = context.colors;
    return AppBar(
      toolbarHeight: 62,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: cs.onSurface, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: context.appTheme.borderSubtle),
      ),
    );
  }

  /// Ust kisimda toplam adet kartı (gradient ikon + sayac).
  static Widget statsBanner(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final cs = context.colors;
    final ext = context.appTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: ext.heroGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: cs.onPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Modern arama kutusu — temizle butonu metin oldukca otomatik gorunur.
  static Widget searchField(
    BuildContext context, {
    required TextEditingController controller,
    String hint = 'Müşteri adıyla ara',
    VoidCallback? onClear,
  }) {
    final cs = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: cs.primary, size: 22),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 18, color: cs.onSurfaceVariant),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              );
            },
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        ),
      ),
    );
  }

  /// Bos durum gosterimi.
  static Widget empty(
    BuildContext context, {
    required bool searching,
    required IconData icon,
    required String emptyTitle,
    String emptySubtitle = '',
  }) {
    final cs = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                searching ? Icons.search_off_rounded : icon,
                size: 44,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              searching ? 'Eşleşme bulunamadı' : emptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Aramanı temizleyip tekrar deneyebilirsin.'
                  : emptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SfDataGrid'i yumusak koseli, golgeli bir karta sarar.
  static Widget gridCard(BuildContext context, {required Widget child}) {
    final cs = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  /// Modern sayfalama (pill butonlar + sayfa rozeti).
  static Widget pagination(
    BuildContext context, {
    required int current,
    required int total,
    required ValueChanged<int> onPage,
  }) {
    if (total <= 1) return const SizedBox.shrink();
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(context, Icons.chevron_left_rounded, current > 1,
              () => onPage(current - 1)),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Sayfa $current / $total',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: cs.primary,
                letterSpacing: -0.1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          _pageBtn(context, Icons.chevron_right_rounded, current < total,
              () => onPage(current + 1)),
        ],
      ),
    );
  }

  static Widget _pageBtn(
      BuildContext context, IconData icon, bool enabled, VoidCallback onTap) {
    final cs = context.colors;
    return Material(
      color: enabled ? cs.primary : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: enabled
                ? cs.onPrimary
                : cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
