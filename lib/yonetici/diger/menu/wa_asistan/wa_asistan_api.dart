// Diğer > WhatsApp Asistanı — backend istemcisi + ortak biçimlendirme yardımcıları.
// Backend: /api/v1/wa-asistan/* (Bearer, sube zorunlu). Web panelindeki
// /isletmeyonetim/whatsapp-asistan sayfasıyla aynı controller metodları (WaAsistanMobilController).

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaApi {
  static const String host = 'https://app.randevumcepte.com.tr';
  static const String base = '$host/api/v1/wa-asistan';

  /// Görsel/avatar istekleri için (Image.network headers) senkron erişilebilir kopya.
  static Map<String, String> sonHeaders = const {};

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

  static Future<Map<String, String>> headers({bool json = false}) async {
    final token = await _token();
    final h = {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    sonHeaders = {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    return h;
  }

  static Map<String, dynamic> _coz(http.Response r) {
    if (r.statusCode == 403) {
      return {'ok': 0, 'hata': 'WhatsApp Asistanı sayfasını yalnızca işletme yöneticileri görebilir.'};
    }
    if (r.statusCode == 401) {
      return {'ok': 0, 'hata': 'Oturumunuz kapanmış görünüyor; çıkış yapıp tekrar giriş yapın.'};
    }
    try {
      final j = jsonDecode(r.body);
      if (j is Map) return Map<String, dynamic>.from(j);
    } catch (_) {}
    return {'ok': 0, 'hata': 'Sunucu hatası (${r.statusCode}). Tekrar deneyin.'};
  }

  static Uri uri(String sube, String yol, [Map<String, String>? p]) =>
      Uri.parse('$base$yol').replace(queryParameters: {...?p, 'sube': sube});

  static Future<Map<String, dynamic>> al(String sube, String yol, [Map<String, String>? p]) async {
    try {
      final r = await http.get(uri(sube, yol, p), headers: await headers()).timeout(const Duration(seconds: 40));
      return _coz(r);
    } catch (e) {
      return {'ok': 0, 'hata': 'Bağlantı kurulamadı. İnternetinizi kontrol edip tekrar deneyin.'};
    }
  }

  static Future<Map<String, dynamic>> gonder(String sube, String yol, [Map<String, dynamic>? veri]) async {
    try {
      final r = await http
          .post(uri(sube, yol), headers: await headers(json: true), body: jsonEncode(veri ?? {}))
          .timeout(const Duration(seconds: 90)); // "Asistan tamamlasın" yapay zekâ çağırır, uzun sürebilir
      return _coz(r);
    } catch (e) {
      return {'ok': 0, 'hata': 'Bağlantı kurulamadı. İnternetinizi kontrol edip tekrar deneyin.'};
    }
  }

  /// Form + dosya (multipart). Dizi alanlar "ad[0]", "ad[1]" biçiminde gönderilir (PHP dizi olarak okur).
  static Future<Map<String, dynamic>> gonderForm(String sube, String yol, Map<String, String> alanlar,
      {String? dosyaYolu, String dosyaAlan = 'gorsel'}) async {
    try {
      final h = await headers();
      final istek = http.MultipartRequest('POST', uri(sube, yol))
        ..headers.addAll(h)
        ..fields.addAll(alanlar);
      if (dosyaYolu != null) istek.files.add(await http.MultipartFile.fromPath(dosyaAlan, dosyaYolu));
      final r = await http.Response.fromStream(await istek.send().timeout(const Duration(seconds: 90)));
      return _coz(r);
    } catch (e) {
      return {'ok': 0, 'hata': 'Bağlantı kurulamadı. İnternetinizi kontrol edip tekrar deneyin.'};
    }
  }

  static String avatarUrl(String sube, int id) => uri(sube, '/avatar/$id').toString();
  static String gorselUrl(String sube, int id) => uri(sube, '/gorsel/$id').toString();
}

// ---------------------------------------------------------------- yardımcılar
bool okMu(Map<String, dynamic> r) => '${r['ok']}' == '1' || r['ok'] == true;

Map<String, dynamic> harita(dynamic x) => x is Map ? Map<String, dynamic>.from(x) : <String, dynamic>{};

List<dynamic> liste(dynamic x) => x is List ? x : (x is Map ? x.values.toList() : const []);

List<Map<String, dynamic>> haritaListe(dynamic x) => liste(x).map((e) => harita(e)).toList();

num sayiDeger(dynamic x) => x is num ? x : (num.tryParse('${x ?? ''}') ?? 0);

num? sayiYaDaNull(dynamic x) => x == null ? null : (x is num ? x : num.tryParse('$x'));

final _tlFmt = NumberFormat.decimalPattern('tr_TR');

String sayi(dynamic x) => _tlFmt.format(sayiDeger(x).round());

String tl(dynamic x) => '${sayi(x)} TL';

String virgul(dynamic x) => '$x'.replaceAll('.', ',');

DateTime? tarihCoz(dynamic s) {
  if (s == null || '$s'.isEmpty) return null;
  return DateTime.tryParse('$s'.replaceFirst(' ', 'T'));
}

const aylarKisa = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
const aylarUzun = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

String _iki(int x) => x.toString().padLeft(2, '0');

/// "19 Kas 14:05"
String tarihSaat(dynamic s) {
  final d = tarihCoz(s);
  if (d == null) return s == null ? '' : '$s';
  return '${_iki(d.day)} ${aylarKisa[d.month - 1]} ${_iki(d.hour)}:${_iki(d.minute)}';
}

/// Bugünse saat, değilse gün ay
String saatYaDaGun(dynamic s) {
  final d = tarihCoz(s);
  if (d == null) return '';
  final b = DateTime.now();
  if (d.year == b.year && d.month == b.month && d.day == b.day) return '${_iki(d.hour)}:${_iki(d.minute)}';
  return '${_iki(d.day)} ${aylarKisa[d.month - 1]}';
}

/// "14:05" (bugün değilse " · 18 Kas" eklenir)
String saatKisa(dynamic s) {
  final d = tarihCoz(s);
  if (d == null) return '';
  final b = DateTime.now();
  final bugun = d.year == b.year && d.month == b.month && d.day == b.day;
  return '${_iki(d.hour)}:${_iki(d.minute)}${bugun ? '' : ' · ${_iki(d.day)} ${aylarKisa[d.month - 1]}'}';
}

String sure(dynamic sn) {
  if (sn == null) return '—';
  final v = sayiDeger(sn);
  if (v < 60) return '${v.round()} sn';
  return '${virgul((v / 6).round() / 10)} dk';
}

String isoGun(DateTime d) => '${d.year}-${_iki(d.month)}-${_iki(d.day)}';

/// Grafik eksen etiketi: "2026-11-19" -> "19 Kas" ; ay biriminde "2026-11" -> "Kas"
String etiketYaz(String e, String birim, {bool uzun = false}) {
  final p = e.split('-');
  if (p.length < 2) return e;
  final ay = int.tryParse(p[1]) ?? 1;
  final a = (uzun ? aylarUzun : aylarKisa)[(ay - 1).clamp(0, 11)];
  if (birim == 'ay') return uzun ? '$a ${p[0]}' : a;
  return '${int.tryParse(p.length > 2 ? p[2] : '1') ?? 1} $a';
}
