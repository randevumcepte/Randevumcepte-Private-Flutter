import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Takvim "Tek Renk" ayari API koprusu.
///
/// GET  /api/v1/takvimRenkGet/{salonId}
///   -> { "basarili": true, "aktif": 0/1, "renk": "#RRGGBB" }
///
/// POST /api/v1/takvimRenkSet/{salonId}
///   body: { "aktif": 0/1, "renk": "#RRGGBB" }  (token + sahiplik zorunlu)
///
/// Acikken takvimde tum personel/oda/cihaz kolonlari ve bu kaynaklara ait
/// normal randevular tek renge boyanir; durum renkleri (geldi/gelmedi/...) korunur.
class TakvimRenkAyari {
  final bool aktif;
  final String renk; // #RRGGBB
  const TakvimRenkAyari({required this.aktif, required this.renk});

  factory TakvimRenkAyari.fromJson(Map<String, dynamic> j) => TakvimRenkAyari(
        aktif: (j['aktif']?.toString() == '1'),
        renk: (j['renk']?.toString().isNotEmpty ?? false) ? j['renk'].toString() : '#5C008E',
      );
}

class TakvimRenkApi {
  static const String _baseUrl = 'https://app.randevumcepte.com.tr/api/v1';
  static const Duration _timeout = Duration(seconds: 8);

  static Future<TakvimRenkAyari?> fetch(String salonId) async {
    if (salonId.isEmpty) return null;
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/takvimRenkGet/$salonId'))
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) return null;
      return TakvimRenkAyari.fromJson(body);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> push(String salonId, bool aktif, String renk) async {
    if (salonId.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await http
          .post(
            Uri.parse('$_baseUrl/takvimRenkSet/$salonId'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'aktif': aktif ? 1 : 0, 'renk': renk}),
          )
          .timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
