import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/services/notification_navigation_bus.dart';
import 'package:randevu_sistem/services/notification_types.dart';

/// Bildirim tipine göre uygulama içi ekran yönlendirmesini yapar.
///
/// Yeni bir tip eklendiğinde:
///   1. NotificationTypes'a sabit ekle
///   2. Buradaki switch'e route adımı ekle
///   3. (Gerekiyorsa) Laravel tarafına da aynı sabiti ekle
///
/// Bilinmeyen tip / hata durumunda fallback olarak
/// kullanıcı tipine uygun bildirim listesi açılır.
class NotificationRouter {
  static Future<void> route(
      BuildContext context, NotificationPayload payload) async {
    final type = payload.type;
    log('🚏 Router → tip=$type deepLink=${payload.deepLink}');

    final prefs = await SharedPreferences.getInstance();
    final tip = prefs.getString('notif_kullanici_tipi'); // 'musteri' | 'yetkili' | 'personel'
    final isMusteri = tip == 'musteri';

    try {
      switch (type) {
        // Randevu ile dogrudan ilgili tipler -> musteri: randevular tab, yetkili: takvim
        case NotificationTypes.appointmentCreated:
        case NotificationTypes.appointmentApproved:
        case NotificationTypes.appointmentCancelled:
        case NotificationTypes.appointmentTimeChanged:
        case NotificationTypes.appointmentReminder:
        case NotificationTypes.appointmentReminderHour:
        case NotificationTypes.staffAssigned:
          NotificationNavigationBus.publish(NotificationIntent(
            isMusteri
                ? NotificationIntent.appointments
                : NotificationIntent.adminCalendar,
            {'randevu_id': payload.randevuId},
          ));
          break;

        // Seans hatirlatmasi / seans kullanim bilgilendirme -> musteri: seanslarim, yetkili: takvim
        case NotificationTypes.sessionReminder:
        case NotificationTypes.sessionUsed:
          NotificationNavigationBus.publish(NotificationIntent(
            isMusteri
                ? NotificationIntent.sessions
                : NotificationIntent.adminCalendar,
            {'randevu_id': payload.randevuId},
          ));
          break;

        // Odeme alindi -> musteri: satin aldiklarim, yetkili: satis takibi
        case NotificationTypes.paymentReceived:
          NotificationNavigationBus.publish(NotificationIntent(
            isMusteri
                ? NotificationIntent.purchases
                : NotificationIntent.adminSales,
            {'randevu_id': payload.randevuId},
          ));
          break;

        case NotificationTypes.newMessage:
          NotificationNavigationBus.publish(NotificationIntent(
            isMusteri
                ? NotificationIntent.notifications
                : NotificationIntent.adminNotifications,
          ));
          break;

        case NotificationTypes.wheelChance:
          NotificationNavigationBus.publish(
              const NotificationIntent(NotificationIntent.wheel));
          break;

        case NotificationTypes.campaign:
        case NotificationTypes.discount:
        case NotificationTypes.birthday:
          NotificationNavigationBus.publish(
              const NotificationIntent(NotificationIntent.discounts));
          break;

        case NotificationTypes.survey:
        case NotificationTypes.membershipExpiring:
        case NotificationTypes.systemAnnouncement:
        default:
          NotificationNavigationBus.publish(NotificationIntent(
            isMusteri
                ? NotificationIntent.notifications
                : NotificationIntent.adminNotifications,
          ));
      }
    } catch (e) {
      log('Router hatası: $e');
    }
  }
}
