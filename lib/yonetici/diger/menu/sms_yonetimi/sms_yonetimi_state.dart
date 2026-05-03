import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// Tüm SMS Yönetimi sekmeleri arasında paylaşılan ortak durum.
class SmsYonetimiController extends ChangeNotifier {
  final String salonId;

  SmsYonetimiController({required this.salonId});

  bool isAdmin = false;
  bool yeniSms = false;
  num kalanSms = 0;
  String smsBaslik = '';
  int randevuSmsHatirlatma = 2;

  /// SalonSMSAyarlari listesi: ayar_id -> {musteri, personel}
  final Map<int, Map<String, bool>> ayarlar = {};

  /// Şablonlar
  List<Map<String, dynamic>> taslaklar = [];

  bool yukleniyor = false;
  String? hata;

  Future<void> yukle() async {
    yukleniyor = true;
    hata = null;
    notifyListeners();
    try {
      final res = await smsYonetimInit(salonId);
      isAdmin = res['isAdmin'] == true;
      yeniSms = (res['yeni_sms'] ?? 0) == 1;
      kalanSms = res['kalan_sms'] ?? 0;
      smsBaslik = (res['sms_baslik'] ?? '').toString();
      randevuSmsHatirlatma = int.tryParse(
              (res['randevu_sms_hatirlatma'] ?? 2).toString()) ??
          2;

      ayarlar.clear();
      for (final a in (res['ayarlar'] as List? ?? [])) {
        final m = Map<String, dynamic>.from(a as Map);
        ayarlar[int.parse(m['ayar_id'].toString())] = {
          'musteri': m['musteri'] == true,
          'personel': m['personel'] == true,
        };
      }

      taslaklar = ((res['taslaklar'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      hata = e.toString();
    } finally {
      yukleniyor = false;
      notifyListeners();
    }
  }

  Future<void> bakiyeYenile() async {
    try {
      final res = await smsYonetimBakiye(salonId);
      kalanSms = res['kalan_sms'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> taslaklariYenile() async {
    try {
      final res = await smsYonetimInit(salonId);
      taslaklar = ((res['taslaklar'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  bool ayarMusteri(int ayarId) =>
      ayarlar[ayarId]?['musteri'] ?? false;
  bool ayarPersonel(int ayarId) =>
      ayarlar[ayarId]?['personel'] ?? false;

  void ayarMusteriDegistir(int ayarId, bool v) {
    ayarlar[ayarId] ??= {'musteri': false, 'personel': false};
    ayarlar[ayarId]!['musteri'] = v;
    notifyListeners();
  }

  void ayarPersonelDegistir(int ayarId, bool v) {
    ayarlar[ayarId] ??= {'musteri': false, 'personel': false};
    ayarlar[ayarId]!['personel'] = v;
    notifyListeners();
  }
}
