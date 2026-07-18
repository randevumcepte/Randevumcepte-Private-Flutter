// Cagri Merkezi (Call Center) API istemcisi.
// Backend: /api/v1/cagri-merkezi/* — Bearer (Passport) auth ZORUNLU.
// Web paneldeki cagri merkezi is mantiginin AYNISI; tek fark guard.
//
// Tum istekler 'sube' (salon_id) gonderir: backend mevcutsube($request) once
// $request->sube okur, boylece api guard'inda session'a ihtiyac duymaz.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'cagri_models.dart';

class CagriApi {
  static const String _base =
      'https://app.randevumcepte.com.tr/api/v1/cagri-merkezi';

  /// Login akisi token'i json.encode ile saklar: setString('token', json.encode(...)).
  /// yetki.dart ile ayni saglam cozme.
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('token');
    if (raw == null || raw.isEmpty) {
      // Fallback: user objesi icindeki token
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

  static Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    final q = <String, String>{...?query};
    return Uri.parse('$_base/$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  static Future<dynamic> _get(String path, Map<String, String> query) async {
    final res = await http
        .get(_uri(path, query), headers: await _headers())
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw CagriApiException(res.statusCode, _mesaj(res.body));
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(_uri(path), headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 40));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw CagriApiException(res.statusCode, _mesaj(res.body));
  }

  static String _mesaj(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['message'] != null) return j['message'].toString();
    } catch (_) {}
    return 'Sunucu hatası';
  }

  // ───────── Dialer ─────────

  static Future<List<AramaKart>> kartlar(String sube) async {
    final j = await _get('arama-kartlarim', {'sube': sube});
    return ((j['kartlar'] as List?) ?? [])
        .map((e) => AramaKart.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<ListeDetay> listeDetay(int aramaDetayId, String sube,
      {int page = 1, int perPage = 50}) async {
    final j = await _post('arama-liste-detay', {
      'arama_detay_id': aramaDetayId,
      'page': page,
      'perPage': perPage,
      'sube': sube,
    });
    return ListeDetay.fromJson(Map<String, dynamic>.from(j));
  }

  static Future<AramaBaslatSonuc> aramaBaslat(int aranacakMusteriId, String sube) async {
    final j = await _post('arama-baslat', {
      'aranacak_musteri_id': aranacakMusteriId,
      'sube': sube,
    });
    return AramaBaslatSonuc.fromJson(Map<String, dynamic>.from(j));
  }

  /// Telefon numarasi ile santral uzerinden arama baslat (musteri detay ekrani).
  static Future<AramaBaslatSonuc> aramaBaslatNumara(String telefon, String sube) async {
    final j = await _post('arama-baslat', {
      'telefon': telefon,
      'sube': sube,
    });
    return AramaBaslatSonuc.fromJson(Map<String, dynamic>.from(j));
  }

  /// Gorusme sonucu kaydet. sonuc: 0,2,4,5,6,7 veya null (sadece not).
  /// santralnottarih/santralnotsaat verilirse (3 veya 6) geri arama planlanir.
  static Future<bool> notEkle({
    required int aramaDetayId,
    required int aranacakMusteriId,
    String noticerik = '',
    int? sonuc,
    int? kategoriId,
    int? altKategoriId,
    String? satisTutari,
    String? santralnottarih,
    String? santralnotsaat,
    required String sube,
  }) async {
    final j = await _post('not-ekle', {
      'arama_detay_id': aramaDetayId,
      'aranacak_musteri_id': aranacakMusteriId,
      'noticerik': noticerik,
      if (sonuc != null) 'sonuc': sonuc,
      if (kategoriId != null) 'kategori_id': kategoriId,
      if (altKategoriId != null) 'alt_kategori_id': altKategoriId,
      'satis_tutari': satisTutari ?? '',
      'santralnottarih': santralnottarih ?? '',
      'santralnotsaat': santralnotsaat ?? '',
      'sube': sube,
    });
    return j is Map && j['success'] == true;
  }

  static Future<List<CagriGecmis>> musteriGecmisi(int aranacakMusteriId, String sube) async {
    final j = await _post('musteri-gecmisi', {
      'aranacak_musteri_id': aranacakMusteriId,
      'sube': sube,
    });
    return ((j['gecmis'] as List?) ?? [])
        .map((e) => CagriGecmis.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<YaklasanRandevu>> yaklasanRandevular(String sube) async {
    final j = await _get('yaklasan-randevular', {'sube': sube});
    return ((j['randevular'] as List?) ?? [])
        .map((e) => YaklasanRandevu.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<OngorusmeBilgi?> ongorusmeBilgi(int aranacakMusteriId, String sube) async {
    final j = await _post('ongorusme-bilgi', {
      'aranacak_musteri_id': aranacakMusteriId,
      'sube': sube,
    });
    if (j is Map && j['success'] == true) {
      return OngorusmeBilgi.fromJson(Map<String, dynamic>.from(j));
    }
    return null;
  }

  static Future<Map<String, dynamic>> hizliSatis({
    required String sube,
    required int musteriId,
    required String kalemTip, // hizmet | urun | paket
    required int kalemId,
    required double fiyat,
    required int odemeYontemi,
    int adet = 1,
  }) async {
    final j = await _post('hizli-satis', {
      'sube': sube,
      'musteri_id': musteriId,
      'kalem_tip': kalemTip,
      'kalem_id': kalemId,
      'fiyat': fiyat,
      'odeme_yontemi': odemeYontemi,
      'adet': adet,
    });
    return Map<String, dynamic>.from(j as Map);
  }

  // ───────── Dashboard (yonetici) ─────────

  static Future<List<PersonelKart>> dashboardVerileri(String sube) async {
    final j = await _get('dashboard-verileri', {'sube': sube});
    return ((j['kartlar'] as List?) ?? [])
        .map((e) => PersonelKart.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<DashboardNot>> dashboardPersonelDetay(int personelId, String sube) async {
    final j = await _post('dashboard-personel-detay', {
      'personel_id': personelId,
      'sube': sube,
    });
    return ((j['notlar'] as List?) ?? [])
        .map((e) => DashboardNot.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ───────── Liste yonetimi (yonetici) ─────────

  static Future<SegmentSonuc> listeSegmentler(int aramaId, String sube) async {
    final j = await _get('liste-segmentler', {'arama_id': '$aramaId', 'sube': sube});
    return SegmentSonuc.fromJson(Map<String, dynamic>.from(j));
  }

  static Future<Map<String, dynamic>> segmentAta({
    required int aramaId,
    required String kod,
    required int personelId,
    required String sube,
  }) async {
    final j = await _post('segment-ata', {
      'arama_id': aramaId,
      'kod': kod,
      'personel_id': personelId,
      'sube': sube,
    });
    return Map<String, dynamic>.from(j as Map);
  }

  static Future<Map<String, dynamic>> listePersonelDegistir({
    required int aramaId,
    required int? personelId,
    required String sube,
  }) async {
    final j = await _post('liste-personel-degistir', {
      'arama_id': aramaId,
      'personel_id': personelId,
      'sube': sube,
    });
    return Map<String, dynamic>.from(j as Map);
  }

  static Future<Map<String, dynamic>> listeSil(int aramaId, String sube) async {
    final j = await _post('liste-sil', {'arama_id': aramaId, 'sube': sube});
    return Map<String, dynamic>.from(j as Map);
  }

  static Future<List<CagriPersonel>> personeller(String sube) async {
    final j = await _get('personeller', {'sube': sube});
    final list = j is List ? j : (j['data'] as List? ?? []);
    return list.map((e) => CagriPersonel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // ───────── Referans veriler ─────────

  static Future<List<CagriScript>> scriptler(String sube) async {
    final j = await _get('scriptler', {'sube': sube});
    return ((j['scriptler'] as List?) ?? [])
        .map((e) => CagriScript.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<CagriKategori>> kategoriler(String sube) async {
    final j = await _get('kategoriler', {'sube': sube});
    return ((j['kategoriler'] as List?) ?? [])
        .map((e) => CagriKategori.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class CagriApiException implements Exception {
  final int statusCode;
  final String message;
  CagriApiException(this.statusCode, this.message);
  @override
  String toString() => 'CagriApiException($statusCode): $message';
}
