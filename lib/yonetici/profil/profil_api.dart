import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Profil sayfası uçları: /api/v1/profil/* (Bearer + sube).
class ProfilApi {
  static const _kok = 'https://app.randevumcepte.com.tr/api/v1';

  /// '/' ile başlayan yol api köküne göredir (müşteri: /musteri-profil/...)
  static String _url(String yol) => yol.startsWith('/') ? '$_kok$yol' : '$_kok/profil/$yol';

  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('token');
    if (raw == null || raw.isEmpty) return null;
    try {
      final d = jsonDecode(raw);
      return d is String ? d : d?.toString();
    } catch (_) {
      return raw;
    }
  }

  static Map<String, dynamic> _cevap(http.Response res) {
    try {
      final j = jsonDecode(res.body);
      if (j is Map) return Map<String, dynamic>.from(j);
    } catch (_) {}
    return {'ok': 0, 'hata': 'Sunucudan geçersiz yanıt (${res.statusCode}).'};
  }

  static bool ok(Map r) => r['ok'] == 1 || r['ok'] == true || r['ok'] == '1';

  static Future<Map<String, dynamic>> get(String yol, String sube, [Map<String, String> ek = const {}]) async {
    try {
      final t = await token();
      if (t == null) return {'ok': 0, 'hata': 'Oturum bulunamadı.'};
      final uri = Uri.parse(_url(yol)).replace(queryParameters: {'sube': sube, ...ek});
      final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'})
          .timeout(const Duration(seconds: 25));
      return _cevap(res);
    } catch (e) {
      log('ProfilApi get $yol: $e');
    }
    return {'ok': 0, 'hata': 'Sunucuya bağlanılamadı.'};
  }

  static Future<Map<String, dynamic>> post(String yol, String sube, Map<String, dynamic> govde) async {
    try {
      final t = await token();
      if (t == null) return {'ok': 0, 'hata': 'Oturum bulunamadı.'};
      final res = await http.post(Uri.parse('${_url(yol)}?sube=$sube'),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $t'},
          body: jsonEncode({...govde, 'sube': sube})).timeout(const Duration(seconds: 25));
      return _cevap(res);
    } catch (e) {
      log('ProfilApi post $yol: $e');
    }
    return {'ok': 0, 'hata': 'Sunucuya bağlanılamadı.'};
  }

  static Future<Map<String, dynamic>> dosya(String yol, String sube, String alan, String dosyaYolu,
      [Map<String, String> ek = const {}]) async {
    try {
      final t = await token();
      if (t == null) return {'ok': 0, 'hata': 'Oturum bulunamadı.'};
      final req = http.MultipartRequest('POST', Uri.parse('${_url(yol)}?sube=$sube'))
        ..headers.addAll({'Accept': 'application/json', 'Authorization': 'Bearer $t'})
        ..fields.addAll({'sube': sube, ...ek})
        ..files.add(await http.MultipartFile.fromPath(alan, dosyaYolu));
      final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 90)));
      return _cevap(res);
    } catch (e) {
      log('ProfilApi dosya $yol: $e');
    }
    return {'ok': 0, 'hata': 'Fotoğraf yüklenemedi.'};
  }
}

/// Ortak biçimlendiriciler
String tl(num? v) {
  if (v == null) return '—';
  final n = v.round();
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}₺$b';
}

String binlik(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

String trTarih(String? ymd) {
  if (ymd == null || ymd.length < 10) return ymd ?? '';
  return '${ymd.substring(8, 10)}.${ymd.substring(5, 7)}.${ymd.substring(0, 4)}';
}
