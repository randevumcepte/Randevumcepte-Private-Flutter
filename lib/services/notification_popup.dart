import 'package:flutter/material.dart';

import 'package:randevu_sistem/services/notification_router.dart';
import 'package:randevu_sistem/services/notification_types.dart';

/// Promosyon tipli bildirimler (kampanya / indirim / çark / doğum günü)
/// foreground'da bu büyük popup ile gösterilir.
///
/// - Üstte tam genişlik resim
/// - Başlık + açıklama
/// - "Fırsatı kullan" CTA butonu (NotificationRouter'a delege eder)
/// - "Daha sonra" yan butonu
Future<void> showPromoNotificationPopup(
  BuildContext context, {
  required NotificationPayload payload,
  String? fallbackTitle,
  String? fallbackBody,
}) async {
  final title = (payload.title?.isNotEmpty ?? false)
      ? payload.title!
      : (fallbackTitle ?? 'Sürpriz fırsat!');
  final body = (payload.body?.isNotEmpty ?? false)
      ? payload.body!
      : (fallbackBody ?? '');
  final cta = _ctaLabel(payload.type);

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'kapat',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return Transform.scale(
        scale: curved.value,
        child: Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: _PromoDialog(
            title: title,
            body: body,
            imageUrl: payload.image,
            ctaLabel: cta,
            onCta: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              NotificationRouter.route(ctx, payload);
            },
          ),
        ),
      );
    },
  );
}

String _ctaLabel(String? type) {
  switch (type) {
    case NotificationTypes.wheelChance:
      return 'ÇARKI ÇEVİR';
    case NotificationTypes.discount:
      return 'İNDİRİMİ KULLAN';
    case NotificationTypes.birthday:
      return 'HEDİYENİ AL';
    case NotificationTypes.campaign:
    default:
      return 'KAMPANYAYI GÖR';
  }
}

class _PromoDialog extends StatelessWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final String ctaLabel;
  final VoidCallback onCta;

  const _PromoDialog({
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.ctaLabel,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.primaryContainer,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.local_offer_outlined,
                          size: 48,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      loadingBuilder: (_, child, p) {
                        if (p == null) return child;
                        return Container(
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (body.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Daha sonra'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: onCta,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            ctaLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
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
}
