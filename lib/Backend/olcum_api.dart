// Vucut olcumu (Pilates/studyo) API cagrilari — backend /api/v1 musteri-olcum-* + danisan-olcumlerim.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/Backend/backend.dart' show appBundleAl;
import 'package:randevu_sistem/Models/olcum.dart';

// GEÇİCİ: vucut olcumu once TEST sunucusunda denenecek (apptest). Canliya
// cikinca 'app.randevumcepte.com.tr' yap. DB ortak oldugu icin veri ayni yere duser.
const String _kBase = 'https://apptest.randevumcepte.com.tr/api/v1';

Future<int?> _callerUserId() async {
  final ls = await SharedPreferences.getInstance();
  // Isletme/personel girisi 'user', danisan/musteri girisi 'musteri' key'inde saklanir.
  for (final key in ['user', 'musteri']) {
    final s = ls.getString(key);
    if (s == null) continue;
    try {
      final id = int.tryParse(jsonDecode(s)['id'].toString());
      if (id != null && id > 0) return id;
    } catch (_) {}
  }
  return null;
}

Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
  body['appBundle'] = await appBundleAl();
  body['user_id'] ??= await _callerUserId();
  final r = await http
      .post(Uri.parse('$_kBase/$path'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(body))
      .timeout(const Duration(seconds: 30));
  final j = (r.body.isNotEmpty) ? jsonDecode(r.body) : {};
  if (j is Map<String, dynamic>) return j;
  return {'durum': 'hata'};
}

List<VucutOlcum> _parse(dynamic list) {
  if (list is! List) return [];
  return list.map((e) => VucutOlcum.fromJson(Map<String, dynamic>.from(e))).toList();
}

// ---- Isletme tarafi ----
Future<List<VucutOlcum>> olcumListe(String salonId, int musteriId) async {
  final j = await _post('musteri-olcum-liste', {'salon_id': salonId, 'musteri_id': musteriId});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Ölçümler yüklenemedi');
  return _parse(j['olcumler']);
}

Future<void> olcumEkle({
  required String salonId,
  required int musteriId,
  required String tarih,
  String? yas,
  String? boy,
  String? kilo,
  String? yagOrani,
  String? odem,
  String? kasPuani,
  String? kasKg,
  String? icYaglanma,
  String? not,
}) async {
  final j = await _post('musteri-olcum-ekle', {
    'salon_id': salonId,
    'musteri_id': musteriId,
    'olcum_tarihi': tarih,
    'yas': yas,
    'boy': boy,
    'kilo': kilo,
    'yag_orani': yagOrani,
    'odem': odem,
    'kas_puani': kasPuani,
    'kas_kg': kasKg,
    'ic_yaglanma': icYaglanma,
    'not': not,
  });
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Kaydedilemedi');
}

Future<void> olcumSil(String salonId, int olcumId) async {
  final j = await _post('musteri-olcum-sil', {'salon_id': salonId, 'olcum_id': olcumId});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Silinemedi');
}

// ---- Danisan tarafi (kendi olcumleri, artan tarih) ----
Future<List<VucutOlcum>> danisanOlcumlerim({String? salonId}) async {
  final j = await _post('danisan-olcumlerim', {if (salonId != null) 'salon_id': salonId});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Ölçümler yüklenemedi');
  return _parse(j['olcumler']);
}
