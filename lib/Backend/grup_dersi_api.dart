// Grup dersi (Pilates/kurs) API cagrilari — backend /api/v1 ders_* endpointleri.
// Projedeki backend.dart kalibi: http + json, salon body'de, caller user_id + appBundle.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/Backend/backend.dart' show appBundleAl;
import 'package:randevu_sistem/Models/grup_dersi.dart';

const String _kBase = 'https://app.randevumcepte.com.tr/api/v1';

Future<int?> _callerUserId() async {
  final ls = await SharedPreferences.getInstance();
  final s = ls.getString('user');
  if (s == null) return null;
  try {
    final u = jsonDecode(s);
    return int.tryParse(u['id'].toString());
  } catch (_) {
    return null;
  }
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
  if (j is Map<String, dynamic>) {
    j['_http'] = r.statusCode;
    return j;
  }
  return {'_http': r.statusCode, 'raw': j};
}

// ---------- Oturum + katilimci ----------

Future<Map<String, dynamic>> dersOturumGetir(String salonId, int oturumId) async {
  final j = await _post('ders-oturum-getir', {'salon_id': salonId, 'oturum_id': oturumId});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Oturum yuklenemedi');
  final oturum = GrupDersOturum.fromJson(Map<String, dynamic>.from(j['oturum']));
  final katilimcilar = (j['katilimcilar'] as List)
      .map((e) => GrupDersKatilimci.fromJson(Map<String, dynamic>.from(e)))
      .toList();
  return {'oturum': oturum, 'katilimcilar': katilimcilar};
}

Future<int> dersOturumKaydet({
  required String salonId,
  int? oturumId,
  required String dersTipi,
  String? personelId,
  String? hizmetId,
  required String tarih,
  required String saat,
  required String saatBitis,
  required int kapasite,
}) async {
  final j = await _post('ders-oturum-kaydet', {
    'salon_id': salonId,
    'oturum_id': oturumId,
    'ders_tipi': dersTipi,
    'personel_id': personelId,
    'hizmet_id': hizmetId,
    'tarih': tarih,
    'saat': saat,
    'saat_bitis': saatBitis,
    'kapasite': kapasite,
  });
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Kaydedilemedi');
  return int.tryParse(j['oturum_id'].toString()) ?? 0;
}

Future<void> dersOturumSil(String salonId, int oturumId) async {
  final j = await _post('ders-oturum-sil', {'salon_id': salonId, 'oturum_id': oturumId});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Silinemedi');
}

// Donus: {'durum':'ok','katilimci_durum':'rezerve'|'bekleme'} veya hata (mesaj)
Future<Map<String, dynamic>> dersKatilimciEkle(String salonId, int oturumId, int musteriId) async {
  final j = await _post('ders-katilimci-ekle', {'salon_id': salonId, 'oturum_id': oturumId, 'musteri_id': musteriId});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Eklenemedi');
  return j;
}

Future<void> dersKatilimciCikar(String salonId, int katilimciId) async {
  final j = await _post('ders-katilimci-cikar', {'salon_id': salonId, 'katilimci_id': katilimciId});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Cikarilamadi');
}

// Donus 'dusum': dusuldu | iade | hak_yok | hizmet_bagli_degil | null
Future<String?> dersKatilimciDurum(String salonId, int katilimciId, String yeniDurum) async {
  final j = await _post('ders-katilimci-durum', {'salon_id': salonId, 'katilimci_id': katilimciId, 'yeni_durum': yeniDurum});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Guncellenemedi');
  return j['dusum']?.toString();
}

// ---------- Ders Programi (sablon) ----------

// Donus: {'personeller':List<GrupDersSecenek>, 'hizmetler':List<GrupDersSecenek>, 'sablon':List<GrupDersSablon>}
Future<Map<String, dynamic>> dersProgramiListe(String salonId) async {
  final j = await _post('ders-programi-liste', {'salon_id': salonId});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Yuklenemedi');
  final personeller = (j['personeller'] as List)
      .map((e) => GrupDersSecenek.fromJson(Map<String, dynamic>.from(e), 'personel_adi'))
      .toList();
  final hizmetler = (j['hizmetler'] as List)
      .map((e) => GrupDersSecenek.fromJson(Map<String, dynamic>.from(e), 'hizmet_adi'))
      .toList();
  final sablon = (j['sablon'] as List)
      .map((e) => GrupDersSablon.fromJson(Map<String, dynamic>.from(e)))
      .toList();
  final eslesme = ((j['eslesme'] as List?) ?? [])
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  return {'personeller': personeller, 'hizmetler': hizmetler, 'sablon': sablon, 'eslesme': eslesme};
}

Future<void> dersSablonKaydet({
  required String salonId,
  int? sablonId,
  required int haftaGunu,
  required String dersTipi,
  String? personelId,
  String? hizmetId,
  required String saat,
  required String saatBitis,
  required int kapasite,
}) async {
  final j = await _post('ders-sablon-kaydet', {
    'salon_id': salonId,
    'sablon_id': sablonId,
    'hafta_gunu': haftaGunu,
    'ders_tipi': dersTipi,
    'personel_id': personelId,
    'hizmet_id': hizmetId,
    'saat': saat,
    'saat_bitis': saatBitis,
    'kapasite': kapasite,
  });
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Kaydedilemedi');
}

Future<void> dersSablonSil(String salonId, int sablonId) async {
  final j = await _post('ders-sablon-sil', {'salon_id': salonId, 'sablon_id': sablonId});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Silinemedi');
}

// ---------- Rapor ----------

// Donus: {'ozet':Map, 'egitmen':List, 'ders':List, 'tarih1':.., 'tarih2':..}
Future<Map<String, dynamic>> grupDersiRapor(String salonId, String tarih1, String tarih2) async {
  final j = await _post('grup-dersi-rapor', {'salon_id': salonId, 'tarih1': tarih1, 'tarih2': tarih2});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Rapor alınamadı');
  return j;
}

// ---------- Danisan (musteri) tarafi ----------

// Musterinin dahil oldugu grup dersleri (gecmis 3 gun + ileri). Her kayit:
// katilimci_id, durum, oturum_id, ders_tipi, tarih, saat, saat_bitis, salon_adi,
// personel, gecmis(bool), geldim_isaretleyebilir(bool)
Future<List<Map<String, dynamic>>> danisanGrupDerslerim(String userId, {String? salonId}) async {
  final body = <String, dynamic>{'user_id': userId};
  if (salonId != null) body['salon_id'] = salonId;
  final j = await _post('danisan-grup-derslerim', body);
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Yuklenemedi');
  return (j['dersler'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
}

// Danisan kendi katilimini "Geldim" isaretler. Donus 'dusum' bilgisi.
Future<String?> danisanDersGeldim(String userId, int katilimciId) async {
  final j = await _post('danisan-ders-geldim', {'user_id': userId, 'katilimci_id': katilimciId});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'İşlem başarısız');
  return j['dusum']?.toString();
}

// Donus: {'olusan':int, 'atlanan':int}
Future<Map<String, dynamic>> dersProgramiYayinla(String salonId, String baslangic, int hafta) async {
  final j = await _post('ders-programi-yayinla', {'salon_id': salonId, 'baslangic': baslangic, 'hafta': hafta});
  if (j['durum'] != 'ok') throw Exception(j['mesaj'] ?? 'Yayinlanamadi');
  return j;
}
