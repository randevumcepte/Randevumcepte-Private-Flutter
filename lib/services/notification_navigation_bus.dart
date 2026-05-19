import 'package:flutter/foundation.dart';

/// Bildirim tıklamasından gelen yönlendirme niyeti. Hedef sayfa
/// `target` ile soyut isimle belirtilir; gerçek sayfa açma işlemi
/// altbar'da yapılır çünkü sayfaların constructor'ları MusteriDanisan /
/// isletmebilgi gibi runtime nesneleri ister.
class NotificationIntent {
  final String target;
  final Map<String, dynamic> params;

  const NotificationIntent(this.target, [this.params = const {}]);

  /// Müşteri tarafı hedefleri
  static const wheel         = 'wheel';
  static const appointments  = 'appointments';
  static const sessions      = 'sessions';
  static const purchases     = 'purchases';
  static const discounts     = 'discounts';
  static const notifications = 'notifications';

  /// İşletme tarafı hedefleri
  static const adminCalendar      = 'admin_calendar';
  static const adminSales         = 'admin_sales';
  static const adminNotifications = 'admin_notifications';
}

/// Pub-sub. Router publish eder, altbar dinler ve consume eder.
/// Cold-start senaryosu: app kapalıyken tap → main() splash öncesi router
/// publish eder → altbar mount olunca initial value'yu okuyup tüketir.
class NotificationNavigationBus {
  NotificationNavigationBus._();

  static final ValueNotifier<NotificationIntent?> current =
      ValueNotifier<NotificationIntent?>(null);

  static void publish(NotificationIntent intent) {
    current.value = intent;
  }

  static void consume() {
    current.value = null;
  }
}
