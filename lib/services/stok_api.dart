import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Models/depo.dart';
import 'package:randevu_sistem/Models/stok_hareketi.dart';
import 'package:randevu_sistem/Models/tedarikci.dart';
import 'package:randevu_sistem/Models/urun_kategorisi.dart';
import 'package:randevu_sistem/Models/urunler.dart';

/// Stok Yönetimi v2 — Backend API erişim katmanı.
///
/// Tüm endpoint'ler `https://apptest.randevumcepte.com.tr/api/v1/stok/*`
/// altında toplanmıştır.
class StokApi {
  static const String _base = 'https://apptest.randevumcepte.com.tr/api/v1/stok';

  static Map<String, String> _headers() => const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      };

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final fields = <String, String>{};
    body.forEach((k, v) {
      if (v == null) return;
      if (v is List || v is Map) {
        fields[k] = jsonEncode(v);
      } else {
        fields[k] = v.toString();
      }
    });
    final res = await http.post(Uri.parse('$_base$path'),
        headers: _headers(), body: fields);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Stok API hatası ${res.statusCode}: ${res.body}');
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  static Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'), headers: _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Stok API hatası ${res.statusCode}: ${res.body}');
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  // ============================================================
  // ÖZET & RAPOR
  // ============================================================

  static Future<Map<String, dynamic>> ozet(String salonId) async {
    final data = await _get('/ozet/$salonId');
    return Map<String, dynamic>.from(data ?? {});
  }

  static Future<List<Urun>> dusukStokListesi(String salonId) async {
    final data = await _get('/dusuk-stok/$salonId') as List<dynamic>? ?? [];
    return data.map((e) => Urun.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<List<dynamic>> urunSatisRaporu(String urunId,
      {String? baslangic, String? bitis}) async {
    final body = <String, dynamic>{
      if (baslangic != null) 'baslangic': baslangic,
      if (bitis != null) 'bitis': bitis,
    };
    final data = await _post('/urun-satis-raporu/$urunId', body);
    return List<dynamic>.from(data ?? []);
  }

  // ============================================================
  // ÜRÜN CRUD
  // ============================================================

  static Future<List<Urun>> urunListesi(String salonId,
      {String? arama, String? kategoriId, String? tip}) async {
    final body = <String, dynamic>{
      if (arama != null && arama.isNotEmpty) 'arama': arama,
      if (kategoriId != null && kategoriId.isNotEmpty) 'kategori_id': kategoriId,
      if (tip != null && tip.isNotEmpty) 'tip': tip,
    };
    final data = await _post('/urunler/$salonId', body) as List<dynamic>? ?? [];
    return data.map((e) => Urun.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<Map<String, dynamic>> urunDetay(String urunId) async {
    final data = await _get('/urun/$urunId');
    return Map<String, dynamic>.from(data ?? {});
  }

  static Future<Urun?> urunBarkodAra(String salonId, String barkod) async {
    final data = await _post('/urun-barkod/$salonId', {'barkod': barkod});
    if (data == null || data is! Map || data['status'] == 'bulunamadi') return null;
    return Urun.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<Urun?> urunKaydet(String salonId, Map<String, dynamic> data) async {
    final r = await _post('/urun-kaydet/$salonId', data);
    if (r == null || r is! Map) return null;
    return Urun.fromJson(Map<String, dynamic>.from(r));
  }

  static Future<void> urunSil(String urunId) async {
    await _post('/urun-sil', {'urun_id': urunId});
  }

  // ============================================================
  // KATEGORİ
  // ============================================================

  static Future<List<UrunKategorisi>> kategoriListesi(String salonId) async {
    final data = await _get('/kategoriler/$salonId') as List<dynamic>? ?? [];
    return data.map((e) => UrunKategorisi.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> kategoriKaydet(String salonId, Map<String, dynamic> data) async {
    await _post('/kategori-kaydet/$salonId', data);
  }

  static Future<void> kategoriSil(String id) async {
    await _post('/kategori-sil', {'id': id});
  }

  // ============================================================
  // DEPO
  // ============================================================

  static Future<List<Depo>> depoListesi(String salonId) async {
    final data = await _get('/depolar/$salonId') as List<dynamic>? ?? [];
    return data.map((e) => Depo.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> depoKaydet(String salonId, Map<String, dynamic> data) async {
    await _post('/depo-kaydet/$salonId', data);
  }

  static Future<Map<String, dynamic>> depoSil(String id) async {
    final r = await _post('/depo-sil', {'id': id});
    return Map<String, dynamic>.from(r ?? {});
  }

  // ============================================================
  // TEDARİKÇİ
  // ============================================================

  static Future<List<Tedarikci>> tedarikciListesi(String salonId) async {
    final data = await _get('/tedarikciler/$salonId') as List<dynamic>? ?? [];
    return data.map((e) => Tedarikci.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> tedarikciKaydet(String salonId, Map<String, dynamic> data) async {
    await _post('/tedarikci-kaydet/$salonId', data);
  }

  static Future<void> tedarikciSil(String id) async {
    await _post('/tedarikci-sil', {'id': id});
  }

  // ============================================================
  // HAREKETLER & İŞLEMLER
  // ============================================================

  static Future<List<StokHareketi>> hareketListesi(String salonId,
      {String? urunId,
      String? depoId,
      String? hareketTipi,
      String? baslangic,
      String? bitis,
      int limit = 200}) async {
    final body = <String, dynamic>{
      'limit': limit,
      if (urunId != null) 'urun_id': urunId,
      if (depoId != null) 'depo_id': depoId,
      if (hareketTipi != null) 'hareket_tipi': hareketTipi,
      if (baslangic != null) 'baslangic': baslangic,
      if (bitis != null) 'bitis': bitis,
    };
    final data = await _post('/hareketler/$salonId', body) as List<dynamic>? ?? [];
    return data.map((e) => StokHareketi.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<Map<String, dynamic>> manuelHareket(String salonId, Map<String, dynamic> data) async {
    final r = await _post('/manuel-hareket/$salonId', data);
    return Map<String, dynamic>.from(r ?? {});
  }

  static Future<Map<String, dynamic>> alisGirisi(String salonId, Map<String, dynamic> data) async {
    final r = await _post('/alis-girisi/$salonId', data);
    return Map<String, dynamic>.from(r ?? {});
  }

  static Future<Map<String, dynamic>> transfer(String salonId, Map<String, dynamic> data) async {
    final r = await _post('/transfer/$salonId', data);
    return Map<String, dynamic>.from(r ?? {});
  }

  static Future<Map<String, dynamic>> sayimUygula(String salonId, List<Map<String, dynamic>> kalemler, {Map<String, dynamic>? meta}) async {
    final data = <String, dynamic>{'kalemler': kalemler, ...?meta};
    final r = await _post('/sayim-uygula/$salonId', data);
    return Map<String, dynamic>.from(r ?? {});
  }

  static Future<Map<String, dynamic>> hizliSatis(String salonId, List<Map<String, dynamic>> sepet, {Map<String, dynamic>? meta}) async {
    final data = <String, dynamic>{'sepet': sepet, ...?meta};
    final r = await _post('/hizli-satis/$salonId', data);
    return Map<String, dynamic>.from(r ?? {});
  }
}
