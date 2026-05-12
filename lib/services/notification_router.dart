import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/navigatorkey.dart';
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

    try {
      switch (type) {
        case NotificationTypes.appointmentCreated:
        case NotificationTypes.appointmentApproved:
        case NotificationTypes.appointmentCancelled:
        case NotificationTypes.appointmentTimeChanged:
        case NotificationTypes.appointmentReminder:
        case NotificationTypes.appointmentReminderHour:
        case NotificationTypes.staffAssigned:
          await _goToAppointmentDetail(payload);
          break;

        case NotificationTypes.paymentReceived:
          await _goToAppointmentDetail(payload);
          break;

        case NotificationTypes.newMessage:
          await _goToMessages(payload);
          break;

        case NotificationTypes.wheelChance:
          await _goToWheel(payload);
          break;

        case NotificationTypes.campaign:
        case NotificationTypes.discount:
        case NotificationTypes.birthday:
          await _goToCampaigns(payload);
          break;

        case NotificationTypes.survey:
          await _goToSurvey(payload);
          break;

        case NotificationTypes.membershipExpiring:
          await _goToMembership(payload);
          break;

        default:
          await _goToFallback();
      }
    } catch (e) {
      log('Router hatası: $e');
      await _goToFallback();
    }
  }

  // ─── Hedef ekranlar ──────────────────────────────────────────────
  //
  // Tüm hedefler navigatorKey üzerinden açılır. Şu anda mevcut ekran
  // constructor'ları (MusteriRandevulari, CarkifelekScreen vs.) salon/MD
  // gibi runtime nesneler bekliyor — onlara doğrudan açılamıyor.
  // Bu noktada uygulamayı ön plana getiriyoruz; tıklayan kullanıcı bildirim
  // listesinden detaya gidebilir. Her hedef ekran için ileride
  // route yardımcısı (named route veya factory) eklenince burası dolar.

  static Future<void> _goToAppointmentDetail(
      NotificationPayload payload) async {
    log('→ randevu detay (randevu_id=${payload.randevuId})');
    await _goToFallback();
  }

  static Future<void> _goToMessages(NotificationPayload payload) async {
    log('→ mesajlar');
    await _goToFallback();
  }

  static Future<void> _goToWheel(NotificationPayload payload) async {
    log('→ çark');
    await _goToFallback();
  }

  static Future<void> _goToCampaigns(NotificationPayload payload) async {
    log('→ kampanyalar');
    await _goToFallback();
  }

  static Future<void> _goToSurvey(NotificationPayload payload) async {
    log('→ anket');
    await _goToFallback();
  }

  static Future<void> _goToMembership(NotificationPayload payload) async {
    log('→ üyelik');
    await _goToFallback();
  }

  /// Bilinmeyen / yönlendirilemeyen tipler için kullanıcının
  /// bildirim listesine düşer (müşteri / yetkili ayrımıyla).
  static Future<void> _goToFallback() async {
    final prefs = await SharedPreferences.getInstance();
    final tip = prefs.getString('notif_kullanici_tipi');
    final nav = navigatorKey.currentState;
    if (nav == null) {
      log('Navigator yok, yönlendirme atlandı (tip=$tip)');
      return;
    }
    // Şimdilik geri/anasayfaya popla — buraya named route'lar bağlandığında
    // tip'e göre /musteri/bildirimler veya /yetkili/bildirimler açılacak.
    log('Fallback yönlendirme (tip=$tip)');
  }
}
