import 'package:flutter_test/flutter_test.dart';
import 'package:randevu_sistem/services/notification_navigation_bus.dart';
import 'package:randevu_sistem/services/notification_router.dart';
import 'package:randevu_sistem/services/notification_types.dart';

/// Bildirime dokununca (ve Bildirimler listesinde satira dokununca) acilacak ekran.
/// Sunucunun gonderdigi gercek veri bicimleriyle: type + deep_link + randevu_id + salon_id.
NotificationIntent? _hedef(Map<String, dynamic> veri, {required bool musteri}) =>
    NotificationRouter.hedef(NotificationPayload.fromMap(veri), isMusteri: musteri);

void main() {
  group('Randevu', () {
    test('musteri: randevu bildirimi o randevunun detayini acar', () {
      final i = _hedef({'type': 'appointment_reminder', 'randevu_id': '981', 'salon_id': '236'}, musteri: true);
      expect(i?.target, NotificationIntent.appointmentDetail);
      expect(i?.params['randevu_id'], '981');
    });
    test('personel: randevu bildirimi o randevunun detayini acar', () {
      final i = _hedef({'type': 'appointment_created', 'randevu_id': '981'}, musteri: false);
      expect(i?.target, NotificationIntent.adminAppointment);
      expect(i?.params['randevu_id'], '981');
    });
    test('randevu numarasi yalniz adreste (genel duyuru turuyle) -> yine randevu', () {
      final i = _hedef({'type': 'system_announcement', 'deep_link': 'appointment_detail?randevu_id=77'}, musteri: false);
      expect(i?.target, NotificationIntent.adminAppointment);
      expect(i?.params['randevu_id'], '77');
    });
    test('musteri cevabi (Geliyorum / Gecikecegim) personelde o randevuyu acar', () {
      final i = _hedef({'type': 'appointment_reply', 'randevu_id': '42', 'deep_link': 'appointment_detail?randevu_id=42'}, musteri: false);
      expect(i?.target, NotificationIntent.adminAppointment);
      expect(i?.params['randevu_id'], '42');
    });
    test('randevu numarasi yoksa: musteri Randevularim sekmesi, personel Takvim', () {
      expect(_hedef({'type': 'appointment_cancelled', 'randevu_id': ''}, musteri: true)?.target,
          NotificationIntent.appointments);
      expect(_hedef({'type': 'appointment_cancelled'}, musteri: false)?.target, NotificationIntent.adminCalendar);
    });
    test('"0" / "null" randevu numarasi bos sayilir', () {
      expect(_hedef({'type': 'appointment_approved', 'randevu_id': '0'}, musteri: true)?.target,
          NotificationIntent.appointments);
      expect(_hedef({'type': 'appointment_approved', 'randevu_id': 'null'}, musteri: true)?.target,
          NotificationIntent.appointments);
    });
    test('liste kaydi (turu bos eski kayit) randevu numarasiyla randevuyu acar', () {
      final p = NotificationRouter.listeKaydi(tip: null, deepLink: null, randevuId: '55', salonId: '236');
      expect(NotificationRouter.hedef(p, isMusteri: true)?.target, NotificationIntent.appointmentDetail);
      final bos = NotificationRouter.listeKaydi(tip: null, deepLink: null, randevuId: 'null', salonId: '236');
      expect(NotificationRouter.hedef(bos, isMusteri: true), isNull);
    });
  });

  group('Musteri diger', () {
    test('ikram (damga) -> Ikram Hizmetlerim, salon ile', () {
      final i = _hedef({'type': 'stamp_reward', 'deep_link': 'ikram_hizmet?salon_id=236', 'salon_id': '236'}, musteri: true);
      expect(i?.target, NotificationIntent.loyaltyPoints);
      expect(i?.params['salon_id'], '236');
    });
    test('seans -> Seanslarim', () {
      expect(_hedef({'type': 'session_used', 'deep_link': 'sessions'}, musteri: true)?.target, NotificationIntent.sessions);
    });
    test('cark -> Carkifelek', () {
      expect(_hedef({'type': 'wheel_chance', 'deep_link': 'wheel'}, musteri: true)?.target, NotificationIntent.wheel);
    });
    test('reklam / indirim -> Indirimlerim', () {
      expect(_hedef({'type': 'discount', 'deep_link': 'reklam_detay?reklam_id=3'}, musteri: true)?.target,
          NotificationIntent.discounts);
    });
    test('isletme fotograf yukledi -> Fotograflarim', () {
      expect(_hedef({'type': 'isletme_resim_yuklendi', 'deep_link': 'musteri_resimlerim'}, musteri: true)?.target,
          NotificationIntent.myPhotos);
    });
    test('grup dersi -> Derslerim', () {
      expect(_hedef({'type': 'class_reminder', 'deep_link': 'group_classes'}, musteri: true)?.target,
          NotificationIntent.groupClasses);
    });
    test('odeme -> Satin aldiklarim', () {
      expect(_hedef({'type': 'payment_received'}, musteri: true)?.target, NotificationIntent.purchases);
    });
    test('musteriye personel hedefi asla verilmez', () {
      expect(_hedef({'type': 'team_request', 'deep_link': 'ekibim'}, musteri: true), isNull);
      expect(_hedef({'type': 'alacak_reminder', 'deep_link': 'customer_detail?user_id=5'}, musteri: true), isNull);
      expect(_hedef({'deep_link': 'wa_assistant?oturum_id=3'}, musteri: true), isNull);
    });
    test('hedefsiz genel duyuru -> null (Bildirimler acilir)', () {
      expect(_hedef({'type': 'system_announcement'}, musteri: true), isNull);
    });
  });

  group('Personel diger', () {
    test('alacak hatirlatma -> o musterinin detayi', () {
      final i = _hedef({'type': 'alacak_reminder', 'deep_link': 'customer_detail?user_id=4120'}, musteri: false);
      expect(i?.target, NotificationIntent.adminCustomerDetail);
      expect(i?.params['user_id'], '4120');
    });
    test('izin / mola talebi -> Ekibim, izin karari -> Izinlerim', () {
      expect(_hedef({'type': 'team_request', 'deep_link': 'ekibim?salon_id=236'}, musteri: false)?.target,
          NotificationIntent.adminTeam);
      final k = _hedef({'type': 'leave_decision', 'deep_link': 'izinlerim?salon_id=236'}, musteri: false);
      expect(k?.target, NotificationIntent.adminLeaves);
      expect(k?.params['salon_id'], '236');
    });
    test('ikram kazanildi -> Ikram Hizmet', () {
      expect(_hedef({'type': 'stamp_reward'}, musteri: false)?.target, NotificationIntent.adminIkram);
    });
    test('santral asistani / WhatsApp asistani', () {
      final a = _hedef({'deep_link': 'assistant_calls?salon_id=236&oturum_id=9'}, musteri: false);
      expect(a?.target, NotificationIntent.adminAssistantCalls);
      expect(a?.params['oturum_id'], '9');
      final w = _hedef({'type': 'wa_asistan_talep', 'deep_link': 'wa_assistant?salon_id=236&oturum_id=12'}, musteri: false);
      expect(w?.target, NotificationIntent.adminWaAssistant);
      expect(w?.params['oturum_id'], '12');
    });
    test('musteri fotograf yukledi -> musteri detayi', () {
      final i = _hedef({'type': 'musteri_resim_yuklendi', 'deep_link': 'customer_detail?user_id=46120'}, musteri: false);
      expect(i?.target, NotificationIntent.adminCustomerDetail);
      expect(i?.params['user_id'], '46120');
    });
    test('seans (randevulu) -> randevu, odeme -> Satis Takibi', () {
      expect(_hedef({'type': 'session_reminder', 'randevu_id': '5'}, musteri: false)?.target,
          NotificationIntent.adminAppointment);
      expect(_hedef({'type': 'payment_received'}, musteri: false)?.target, NotificationIntent.adminSales);
    });
    test('reklam kampanyasi / dusuk puan / yeni mesaj -> null (Bildirimler)', () {
      expect(_hedef({'type': 'ad_campaign'}, musteri: false), isNull);
      expect(_hedef({'type': 'survey', 'deep_link': 'survey?salon_id=236'}, musteri: false), isNull);
      expect(_hedef({'type': 'new_message'}, musteri: false), isNull);
    });
    test('personele musteri hedefi asla verilmez', () {
      expect(_hedef({'type': 'wheel_chance', 'deep_link': 'wheel'}, musteri: false), isNull);
      expect(_hedef({'deep_link': 'group_classes'}, musteri: false), isNull);
      expect(_hedef({'type': 'discount'}, musteri: false), isNull);
    });
  });
}
