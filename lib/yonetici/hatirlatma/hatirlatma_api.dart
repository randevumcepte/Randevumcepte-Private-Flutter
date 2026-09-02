// Salon hatirlatma feed API istemcisi.
// Backend: GET /api/v1/hatirlatma-feed?sube=... — Bearer (Passport) auth.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'hatirlatma_model.dart';

class HatirlatmaApi {
  static const String _url =
      'https://app.randevumcepte.com.tr/api/v1/hatirlatma-feed';

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('token');
    if (raw == null || raw.isEmpty) {
      final userRaw = prefs.getString('user');
      if (userRaw != null) {
        try {
          final user = jsonDecode(userRaw);
          if (user is Map && user['token'] != null) return user['token'].toString();
        } catch (_) {}
      }
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is String ? decoded : decoded?.toString();
    } catch (_) {
      return raw;
    }
  }

  /// Hatirlatma listesini ceker. Hata olursa bos liste doner (UI sessizce gecer).
  static Future<List<Hatirlatma>> feed(String sube) async {
    try {
      final token = await _token();
      final uri = Uri.parse(_url).replace(queryParameters: {'sube': sube});
      final res = await http.get(uri, headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return [];
      final j = jsonDecode(res.body);
      final list = (j is Map ? j['hatirlatmalar'] : null) as List? ?? [];
      final out = list
          .map((e) => Hatirlatma.fromJson(Map<String, dynamic>.from(e)))
          // Dogum gunu app'te ayri merkezi modal ile gosteriliyor
          // (dogum_gunu_popup.dart) -> sagdan cikan feed kartinda tekrar cikmasin.
          .where((h) => h.tip != 'dogum_gunu')
          .toList();
      // Oncelik (yuksek once)
      out.sort((a, b) => b.oncelik.compareTo(a.oncelik));
      return out;
    } catch (_) {
      return [];
    }
  }
}
