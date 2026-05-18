import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notification_service.dart';

/// AltBar uzerinde gosterilen kalici uyari seridi.
///
/// FCM token alinamadiginda veya kullanici bildirim iznini reddettiginde
/// kullaniciyi bilgilendirir. Token alindigi anda otomatik gizlenir.
///
/// NotificationService arka planda 5 dk arayla retry yapiyor; bu banner
/// kullanicinin sorunu manuel cozmesi icin bir CTA (ayarlar) sunuyor.
class _NotificationStatusBanner extends StatelessWidget {
  const _NotificationStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NotificationStatus>(
      valueListenable: NotificationService.status,
      builder: (context, st, _) {
        if (st == NotificationStatus.ok || st == NotificationStatus.unknown) {
          return const SizedBox.shrink();
        }

        final isPermission = st == NotificationStatus.permissionDenied;
        final mesaj = isPermission
            ? 'Bildirim izni kapalı. Randevu ve hatırlatmalar için izin verin.'
            : 'Bildirimler şu an çalışmıyor. Tekrar deneniyor…';

        return Material(
          color: isPermission ? Colors.red.shade700 : Colors.orange.shade800,
          child: SafeArea(
            bottom: false,
            child: InkWell(
              onTap: isPermission
                  ? () async {
                      try { await openAppSettings(); } catch (_) {}
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      isPermission ? Icons.notifications_off : Icons.error_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mesaj,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isPermission) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'AYARLAR',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right, color: Colors.white, size: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Public re-export, altbar'lardan kullanilir.
class NotificationStatusBanner extends StatelessWidget {
  const NotificationStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const _NotificationStatusBanner();
}
