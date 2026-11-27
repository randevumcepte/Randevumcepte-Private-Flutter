import 'dart:developer';

import 'package:randevu_sistem/dil/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/services/notification_navigation_bus.dart';
import 'package:randevu_sistem/services/notification_types.dart';

/// Bildirime dokununca (push) ve Bildirimler listesinde bir satira dokununca
/// gidilecek ekrani TEK yerde cozer. Ikisi de [hedef] kullanir; boylece ayni
/// bildirim her iki yerden de ayni ekrani acar.
///
/// Sira: once bildirimin tasidigi adres (deep_link, ornek "appointment_detail?randevu_id=5"),
/// yoksa bildirim turu. Hicbiri eslesmezse null: push'ta Bildirimler ekrani acilir,
/// listede bildirimin tam metni gosterilir.
///
/// Yeni bir tur/adres eklendiginde: NotificationTypes'a sabit, buraya eslesme,
/// gerekiyorsa NotificationIntent'e hedef + ilgili altbar'a sayfa acma.
class NotificationRouter {
  static Future<void> route(
      BuildContext context, NotificationPayload payload) async {
    log('🚏 Router → tip=${payload.type} deepLink=${payload.deepLink} randevu=${payload.randevuId}');
    try {
      final isMusteri = await musteriMi();
      final intent = hedef(payload, isMusteri: isMusteri) ??
          NotificationIntent(isMusteri
              ? NotificationIntent.notifications
              : NotificationIntent.adminNotifications);
      NotificationNavigationBus.publish(intent);
    } catch (e) {
      log('Router hatası: $e');
    }
  }

  /// Oturumdaki kisi musteri mi? Once bildirim kaydindaki tip; o yoksa (eski
  /// kurulum / tip yazilamamis) oturum bilgisinden: user_type '1' isletme.
  static Future<bool> musteriMi() async {
    final prefs = await SharedPreferences.getInstance();
    final tip = prefs.getString('notif_kullanici_tipi');
    if (tip != null && tip.isNotEmpty) return tip == 'musteri';
    final userType = prefs.getString('user_type');
    if (userType != null && userType.contains('1')) return false;
    return (prefs.getString('musteri') ?? '').isNotEmpty;
  }

  /// Bildirimin acacagi ekran; yoksa null.
  static NotificationIntent? hedef(NotificationPayload p,
      {required bool isMusteri}) {
    final dl = p.deepLink ?? '';
    final rota = _rota(dl);
    final randevuId = _dolu(p.randevuId) ?? _param(dl, 'randevu_id');
    final salonId = _dolu(p.salonId) ?? _param(dl, 'salon_id');

    NotificationIntent randevu() => randevuId != null
        ? NotificationIntent(
            isMusteri
                ? NotificationIntent.appointmentDetail
                : NotificationIntent.adminAppointment,
            {'randevu_id': randevuId})
        : NotificationIntent(isMusteri
            ? NotificationIntent.appointments
            : NotificationIntent.adminCalendar);

    // 1) Adres (deep link)
    switch (rota) {
      case 'appointment_detail':
        return randevu();
      case 'group_classes':
        return isMusteri
            ? const NotificationIntent(NotificationIntent.groupClasses)
            : null;
      case 'assistant_calls':
        return isMusteri
            ? null
            : NotificationIntent(NotificationIntent.adminAssistantCalls,
                {'salon_id': salonId, 'oturum_id': _param(dl, 'oturum_id')});
      case 'wa_assistant':
        return isMusteri
            ? null
            : NotificationIntent(NotificationIntent.adminWaAssistant,
                {'salon_id': salonId, 'oturum_id': _param(dl, 'oturum_id')});
      case 'customer_detail':
        final uid = _param(dl, 'user_id');
        return (!isMusteri && uid != null)
            ? NotificationIntent(
                NotificationIntent.adminCustomerDetail, {'user_id': uid})
            : null;
      case 'musteri_resimlerim':
        return isMusteri
            ? const NotificationIntent(NotificationIntent.myPhotos)
            : null;
      case 'sessions':
        return isMusteri
            ? const NotificationIntent(NotificationIntent.sessions)
            : randevu();
      case 'ikram_hizmet':
        return NotificationIntent(
            isMusteri
                ? NotificationIntent.loyaltyPoints
                : NotificationIntent.adminIkram,
            {'salon_id': salonId});
      case 'wheel':
        return isMusteri
            ? const NotificationIntent(NotificationIntent.wheel)
            : null;
      case 'reklam_detay':
      case 'campaign_detail':
        return isMusteri
            ? const NotificationIntent(NotificationIntent.discounts)
            : null;
      case 'ekibim':
        return isMusteri
            ? null
            : NotificationIntent(NotificationIntent.adminTeam, {'salon_id': salonId});
      case 'izinlerim':
        return isMusteri
            ? null
            : NotificationIntent(NotificationIntent.adminLeaves, {'salon_id': salonId});
    }

    // 2) Tur
    switch (p.type) {
      case NotificationTypes.isletmeResimYukledi:
        return isMusteri
            ? const NotificationIntent(NotificationIntent.myPhotos)
            : null;
      case NotificationTypes.musteriResimYukledi:
        final uid = _param(dl, 'user_id');
        return (!isMusteri && uid != null)
            ? NotificationIntent(
                NotificationIntent.adminCustomerDetail, {'user_id': uid})
            : null;
      case NotificationTypes.appointmentCreated:
      case NotificationTypes.appointmentApproved:
      case NotificationTypes.appointmentCancelled:
      case NotificationTypes.appointmentTimeChanged:
      case NotificationTypes.appointmentReminder:
      case NotificationTypes.appointmentReminderHour:
      case NotificationTypes.staffAssigned:
        return randevu();
      case NotificationTypes.sessionReminder:
      case NotificationTypes.sessionUsed:
        return isMusteri
            ? const NotificationIntent(NotificationIntent.sessions)
            : randevu();
      case NotificationTypes.paymentReceived:
        return NotificationIntent(isMusteri
            ? NotificationIntent.purchases
            : NotificationIntent.adminSales);
      case NotificationTypes.wheelChance:
        return isMusteri
            ? const NotificationIntent(NotificationIntent.wheel)
            : null;
      case NotificationTypes.stampReward:
        return NotificationIntent(
            isMusteri
                ? NotificationIntent.loyaltyPoints
                : NotificationIntent.adminIkram,
            {'salon_id': salonId});
      case NotificationTypes.campaign:
      case NotificationTypes.discount:
      case NotificationTypes.birthday:
        return isMusteri
            ? const NotificationIntent(NotificationIntent.discounts)
            : null;
      case NotificationTypes.teamRequest:
        return isMusteri
            ? null
            : NotificationIntent(NotificationIntent.adminTeam, {'salon_id': salonId});
      case NotificationTypes.leaveDecision:
        return isMusteri
            ? null
            : NotificationIntent(NotificationIntent.adminLeaves, {'salon_id': salonId});
    }

    // 3) Turu belirsiz ama randevuya bagli bildirim (eski kayitlar)
    if (randevuId != null) return randevu();
    return null;
  }

  /// Bildirimler listesindeki kayit icin payload (push ile ayni alanlar).
  static NotificationPayload listeKaydi({
    String? tip,
    String? deepLink,
    String? randevuId,
    String? salonId,
  }) =>
      NotificationPayload.fromMap({
        'type': tip ?? '',
        'deep_link': deepLink ?? '',
        'randevu_id': _dolu(randevuId) ?? '',
        'salon_id': salonId ?? '',
      });

  /// "appointment_detail?randevu_id=5" -> "appointment_detail"
  static String _rota(String deepLink) {
    if (deepLink.isEmpty) return '';
    final i = deepLink.indexOf('?');
    return (i < 0 ? deepLink : deepLink.substring(0, i)).trim();
  }

  /// Deep link'ten tek parametre; yoksa / bossa null.
  static String? _param(String? deepLink, String key) {
    if (deepLink == null || deepLink.isEmpty) return null;
    try {
      return _dolu(Uri.parse(deepLink).queryParameters[key]);
    } catch (_) {
      return null;
    }
  }

  /// 'null', '0', bos -> null
  static String? _dolu(String? v) {
    if (v == null) return null;
    final s = v.trim();
    return (s.isEmpty || s == 'null' || s == '0') ? null : s;
  }
}
