import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// MERKEZI API ISTEMCISI (Guvenlik G1 Faz B)
///
/// Her istege Passport token'ini (Authorization: Bearer) OTOMATIK ekler. Boylece
/// backend'deki salon.sahiplik gate'i salonu token'dan dogrulayabilir.
///
/// Token login akisinda prefs['token']'a json.encode ile yazilir; fallback olarak
/// prefs['user'] icindeki 'token' alanina bakilir (yeni/eski kayit uyumu).
///
/// Token eklemek ADDITIVE ve zararsizdir: public/gate'siz uclarda backend yok sayar,
/// gate'li uclarda sahiplik dogrulamasi icin kullanir. Bu yuzden tum cagrilari bu
/// istemciye tasimak guvenlidir (eski davranisi bozmaz).
class ApiClient {
  static const String base = 'https://app.randevumcepte.com.tr/api/v1';

  /// Kayitli Passport token'i (yoksa null).
  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('token');
    if (raw != null && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        return d is String ? d : d?.toString();
      } catch (_) {
        return raw;
      }
    }
    final userRaw = prefs.getString('user');
    if (userRaw != null) {
      try {
        final u = jsonDecode(userRaw);
        if (u is Map && u['token'] != null) return u['token'].toString();
      } catch (_) {}
    }
    return null;
  }

  /// Standart basliklar (+ token varsa Bearer).
  static Future<Map<String, String>> headers({bool json = true}) async {
    final t = await token();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  /// GET — path '/' ile baslamali ( or. '/musteriler/123'). query opsiyonel.
  static Future<http.Response> get(String path, {Map<String, dynamic>? query}) async {
    var uri = Uri.parse('$base$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query.map((k, v) => MapEntry(k, v?.toString() ?? '')));
    }
    return http.get(uri, headers: await headers());
  }

  /// POST (JSON govde).
  static Future<http.Response> postJson(String path, Map<String, dynamic> body) async {
    return http.post(Uri.parse('$base$path'), headers: await headers(), body: jsonEncode(body));
  }

  /// POST (form-urlencoded govde) — backend request()->input ile okuyan uclar icin.
  static Future<http.Response> postForm(String path, Map<String, String> fields) async {
    return http.post(Uri.parse('$base$path'), headers: await headers(json: false), body: fields);
  }

  /// Multipart (dosya yukleme) — token header'li gonderir, StreamedResponse dondurur.
  static Future<http.StreamedResponse> multipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$base$path'));
    final t = await token();
    if (t != null && t.isNotEmpty) req.headers['Authorization'] = 'Bearer $t';
    if (fields != null) req.fields.addAll(fields);
    if (files != null) req.files.addAll(files);
    return req.send();
  }
}
