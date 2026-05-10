import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/theme/app_theme.dart';

/// API endpoint sözleşmesi (Laravel tarafında deploy edilecek):
///
/// GET  /api/v1/salonTemaGet/{salonId}
///   -> { "preset": "mor_luks", "customSeedArgb": null, "brightnessMode": "light" }
///
/// POST /api/v1/salonTemaSet/{salonId}
///   body: { "preset": "...", "customSeedArgb": int|null, "brightnessMode": "..." }
///   -> { "ok": true }
///
/// Server uçları henüz deploy edilmemişse fonksiyonlar sessizce başarısız olur,
/// uygulama lokal config ile çalışmaya devam eder.

class SalonTemaApi {
  static const String _baseUrl = 'https://app.randevumcepte.com.tr/api/v1';
  static const Duration _timeout = Duration(seconds: 8);

  static Future<AppThemeConfig?> fetch(String salonId) async {
    if (salonId.isEmpty) return null;
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/salonTemaGet/$salonId'))
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) return null;
      // Boş cevap -> default
      if (body.isEmpty || body['preset'] == null) {
        return AppThemeConfig.defaults;
      }
      return AppThemeConfig.fromJson(body);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> push(String salonId, AppThemeConfig config) async {
    if (salonId.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await http
          .post(
            Uri.parse('$_baseUrl/salonTemaSet/$salonId'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(config.toJson()),
          )
          .timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
