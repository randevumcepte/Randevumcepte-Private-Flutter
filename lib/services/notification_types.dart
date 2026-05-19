/// Bildirim tipleri. Laravel app/Services/NotificationTypes.php ile birebir aynı.
/// Yeni tip eklendiğinde her iki tarafta da güncellenmeli.
class NotificationTypes {
  // Randevu
  static const appointmentCreated      = 'appointment_created';
  static const appointmentApproved     = 'appointment_approved';
  static const appointmentCancelled    = 'appointment_cancelled';
  static const appointmentTimeChanged  = 'appointment_time_changed';
  static const appointmentReminder     = 'appointment_reminder';
  static const appointmentReminderHour = 'appointment_reminder_hour';
  static const staffAssigned           = 'staff_assigned';

  // Seans / paket
  static const sessionReminder         = 'session_reminder';
  static const sessionUsed             = 'session_used';

  // Ödeme & mesaj
  static const paymentReceived         = 'payment_received';
  static const newMessage              = 'new_message';

  // Pazarlama (rich + popup)
  static const campaign                = 'campaign';
  static const discount                = 'discount';
  static const wheelChance             = 'wheel_chance';
  static const birthday                = 'birthday';

  // Geri besleme
  static const survey                  = 'survey';

  // Sistem
  static const membershipExpiring      = 'membership_expiring';
  static const systemAnnouncement      = 'system_announcement';
  // Personelin yetkileri yonetici tarafindan guncellendi -> popup + logout.
  static const yetkiDegisti            = 'yetki_degisti';

  /// Bu tipler foreground'da resimli popup ile gösterilmeli.
  static bool isPopup(String? type) =>
      type != null &&
      const {campaign, discount, wheelChance, birthday}.contains(type);

  /// Yüksek öncelikli kanal (titreşim, ses, ekran yakma).
  static bool isHighPriority(String? type) =>
      type != null &&
      const {
        appointmentReminder,
        appointmentReminderHour,
        appointmentTimeChanged,
        appointmentCancelled,
        sessionReminder,
        sessionUsed,
        newMessage,
        paymentReceived,
      }.contains(type);
}

/// FCM `data` payload'unu type-safe sarmalayan helper.
class NotificationPayload {
  final String? type;
  final String? title;
  final String? body;
  final String? image;
  final String? deepLink;
  final bool popup;
  final String? salonId;
  final String? randevuId;
  final Map<String, dynamic> raw;

  NotificationPayload({
    this.type,
    this.title,
    this.body,
    this.image,
    this.deepLink,
    this.popup = false,
    this.salonId,
    this.randevuId,
    this.raw = const {},
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> data) {
    String? s(dynamic v) {
      if (v == null) return null;
      final str = v.toString();
      return str.isEmpty ? null : str;
    }

    return NotificationPayload(
      type:      s(data['type']),
      title:     s(data['title']),
      body:      s(data['body']),
      image:     s(data['image']),
      deepLink:  s(data['deep_link']),
      popup:     s(data['popup']) == '1' || data['popup'] == true,
      salonId:   s(data['salon_id']),
      randevuId: s(data['randevu_id']),
      raw:       Map<String, dynamic>.from(data),
    );
  }

  Map<String, String> toStringMap() => raw.map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      );
}
