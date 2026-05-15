import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Personel yetki kontrol merkezi.
///
/// Backend'in /api/v1/benimYetkilerim cevabini cache'ler, sayfalarda
/// sayet yetki kontrolu yapilmasi gerekiyorsa buraya bakar.
///
/// Onemli:
///   - Yetki yoksa false doner (kapali default)
///   - Cache yenileme: girisin sonunda + Personeller listesi acilirken
///   - "Salon sahibi" veya "Personel rolu degil" durumunda TUM yetkiler acik
///   - Cache yoksa GERIYE DONUK UYUMLU: tum yetkiler acik (eski mobile davranisi)
///
/// Kullanim:
///   await Yetki.tazele(salonid: '15');
///   if (Yetki.varMi('musteri.telefon_gor')) { ... }
///   Text(Yetki.telefonGoster(musteri.cep_telefon));
class Yetki {
  static const _prefsKey = 'yetkilerim_v1';

  static Map<String, bool> _ayarlar = {};
  static bool _salonSahibi = true; // default tam yetki (geriye donuk)
  static bool _personelRolunde = false;
  static String _sablon = 'tam_yetki';
  static bool _yuklendi = false;

  // ═════════════════════ Public API ═════════════════════

  /// Sayfa ilk acilirken cache'i bellege yukle.
  static Future<void> baslat() async {
    if (_yuklendi) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _ayarlar = ((json['ayarlar'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(k.toString(), v == true),
        );
        _salonSahibi = json['salon_sahibi'] == true;
        _personelRolunde = json['personel_rolunde'] == true;
        _sablon = (json['sablon'] ?? 'tam_yetki').toString();
      }
    } catch (e) {
      debugPrint('Yetki.baslat hata: $e');
    }
    _yuklendi = true;
  }

  /// Backend'den yetkileri yeniden cek ve cache'le. Login sonrasi + Personeller
  /// sayfasi acilirken cagirilmasi onerilir.
  ///
  /// salonid: mevcut secili sube
  static Future<void> tazele({required String salonid}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Login akisi token'i ayri bir key'de tutuyor: setString('token', json.encode(...))
      String? token;
      final rawToken = prefs.getString('token');
      if (rawToken != null && rawToken.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawToken);
          token = decoded is String ? decoded : decoded?.toString();
        } catch (_) {
          token = rawToken; // direkt string olabilir
        }
      }
      // Fallback: user objesi icindeki token
      if (token == null || token.isEmpty) {
        final userRaw = prefs.getString('user');
        if (userRaw != null) {
          try {
            final user = jsonDecode(userRaw);
            if (user is Map) token = user['token']?.toString();
          } catch (_) {}
        }
      }
      if (token == null || token.isEmpty) {
        // Token yoksa auth gerektiren benimYetkilerim'i cagiramayiz.
        // Cache default'a duselim (tum yetkiler acik - geriye donuk).
        _ayarlar = {};
        _salonSahibi = true;
        _personelRolunde = false;
        _sablon = 'tam_yetki';
        await prefs.remove(_prefsKey);
        _yuklendi = true;
        return;
      }
      final response = await http.post(
        Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/benimYetkilerim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'sube': salonid}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['basarili'] == true) {
          _ayarlar = ((data['ayarlar'] as Map?) ?? const {}).map(
            (k, v) => MapEntry(k.toString(), v == true),
          );
          _salonSahibi = data['salon_sahibi'] == true;
          _personelRolunde = data['personel_rolunde'] == true;
          _sablon = (data['sablon'] ?? 'tam_yetki').toString();
          await prefs.setString(
            _prefsKey,
            jsonEncode({
              'ayarlar': _ayarlar,
              'salon_sahibi': _salonSahibi,
              'personel_rolunde': _personelRolunde,
              'sablon': _sablon,
            }),
          );
        }
      } else {
        debugPrint('Yetki.tazele non-200: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Yetki.tazele hata: $e');
    }
    _yuklendi = true;
  }

  /// Logout / hesap degisikligi sirasinda cache'i temizle.
  static Future<void> temizle() async {
    _ayarlar = {};
    _salonSahibi = true;
    _personelRolunde = false;
    _sablon = 'tam_yetki';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  /// Belirli bir yetki anahtarı var mı?
  ///
  /// Salon sahibi veya Personel rolu DEGIL ise: her zaman true.
  /// Personel rolu ise: cache'ten oku, yoksa false.
  /// Cache hic yuklenmediyse (henuz tazele cagirilmadi): true (defansif).
  static bool varMi(String key) {
    if (!_yuklendi) return true; // henuz baslatilmadi - eski davranis
    if (_salonSahibi || !_personelRolunde) return true;
    return _ayarlar[key] == true;
  }

  /// Telefon numarasini gosterilebilir hale getir.
  /// Yetki yoksa maskeli: "0532 *** ** 47"
  static String telefonGoster(String? tel) {
    if (tel == null || tel.isEmpty) return '';
    if (varMi('musteri.telefon_gor')) return tel;
    return _maskele(tel);
  }

  /// Hassas tutar maskeleme (yetki yoksa "****")
  static String tutarGoster(String tutar, String key) {
    if (varMi(key)) return tutar;
    return '****';
  }

  // === Getter'lar (UI'da ozel goruntu icin) ===
  static bool get salonSahibi => _salonSahibi;
  static bool get personelRolunde => _personelRolunde;
  static String get sablon => _sablon;
  static Map<String, bool> get tumAyarlar => Map.unmodifiable(_ayarlar);

  // ═════════════════════ Helpers ═════════════════════

  /// 0532 123 45 67 → 0532 *** ** 67
  static String _maskele(String tel) {
    final digits = tel.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 2) return tel;
    final son2 = digits.substring(digits.length - 2);
    final bas4 = digits.length >= 4 ? digits.substring(0, 4) : digits.substring(0, digits.length - 2);
    return '$bas4 *** ** $son2';
  }
}
