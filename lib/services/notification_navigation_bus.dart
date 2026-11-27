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
  /// Müşterinin kendi fotoğrafları ekranı — isletme resim yükleyince
  /// gönderilen push tıklanınca burası açılır. params: yok.
  static const myPhotos      = 'my_photos';
  /// Grup dersleri (Derslerim) ekrani — ders bitiminde "katildiniz mi?" push'u
  /// tiklaninca acilir.
  static const groupClasses  = 'group_classes';
  /// Puan Ödüllerim (damga kartları dahil) — damga kartı dolunca gelen push.
  /// params: {'salon_id': String?}
  static const loyaltyPoints = 'loyalty_points';
  /// Tek randevu: Randevularim acilir ve o randevunun detayi kendiliginden gelir. params: {'randevu_id'}
  static const appointmentDetail = 'appointment_detail';

  /// İşletme tarafı hedefleri
  static const adminCalendar      = 'admin_calendar';
  static const adminSales         = 'admin_sales';
  static const adminNotifications = 'admin_notifications';
  /// İşletme tarafı — bir müşterinin detay/fotoğraf ekranı. Müşteri fotoğraf
  /// yükleyince gönderilen push tıklanınca açılır. params: {'user_id': String}
  static const adminCustomerDetail = 'admin_customer_detail';
  /// İşletme tarafı — Asistanım > Asistan Görüşmeleri (geri aranacak filtresi).
  /// "Geri aranacak müşteri" (santral asistanı) push'u. params: {'salon_id', 'oturum_id'}
  static const adminAssistantCalls = 'admin_assistant_calls';
  // WhatsApp asistani talep bildirimi -> Diger > WhatsApp Asistani (ilgili sohbet)
  static const adminWaAssistant = 'admin_wa_assistant';
  /// Tek randevu (isletme): Randevular acilir, o randevunun detay penceresi gelir. params: {'randevu_id'}
  static const adminAppointment = 'admin_appointment';
  /// Profil > Ekibim (izin / mola talepleri). Yalniz yonetici.
  static const adminTeam = 'admin_team';
  /// Profil > Izinlerim (izin karari)
  static const adminLeaves = 'admin_leaves';
  /// Ikram Hizmet (damga karti) yonetimi
  static const adminIkram = 'admin_ikram';
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
