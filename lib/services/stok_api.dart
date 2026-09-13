import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Models/depo.dart';
import 'package:randevu_sistem/Models/stok_hareketi.dart';
import 'package:randevu_sistem/Models/tedarikci.dart';
import 'package:randevu_sistem/Models/urun_kategorisi.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/navigatorkey.dart';

/// Stok Yönetimi v2 — Backend API erişim katmanı.
///
/// Bütün metotlar **asla exception fırlatmaz** — hata durumunda kullanıcıya
/// global SnackBar ile mesaj gösterir ve uygun fallback değer döndürür
/// (boş liste, boş Map, null). Bu sayede UI'da kırmızı hata ekranı çıkmaz.
class StokApi {
  static const String _base = 'https://app.randevumcepte.com.tr/api/v1/stok';

  static Map<String, String> _headers() => const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      };

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  /// Kullanıcıya global SnackBar ile hata göster.
  static void _hataGoster(String mesaj) {
    try {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(mesaj))]),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {/* sessiz */}
  }

  /// HTTP yanıtından mesaj çıkar (status:'error', mesaj:... beklenir).
  static String _mesajCek(int code, String body, String varsayilan) {
    if (body.isNotEmpty) {
      try {
        final j = jsonDecode(body);
        if (j is Map && j['mesaj'] != null) return j['mesaj'].toString();
      } catch (_) {}
    }
    return '$varsayilan ($code)';
  }

  /// Generic wrapper — async işlem hata atarsa global snackbar göster, fallback dön.
  static Future<T> _guvenli<T>(Future<T> Function() islem, T fallback, {String hataBaslik = 'Bağlantı hatası'}) async {
    try {
      return await islem();
    } catch (e) {
      _hataGoster('$hataBaslik: $e');
      return fallback;
    }
  }

  // ============================================================
  // HTTP HELPERS
  // ============================================================

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
    final res = await http.post(Uri.parse('$_base$path'), headers: _headers(), body: fields);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_mesajCek(res.statusCode, res.body, 'İşlem reddedildi'));
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  static Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'), headers: _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_mesajCek(res.statusCode, res.body, 'Yüklenemedi'));
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  // ============================================================
  // ÖZET & RAPOR
  // ============================================================

  static Future<Map<String, dynamic>> ozet(String salonId) => _guvenli(() async {
        final data = await _get('/ozet/$salonId');
        return Map<String, dynamic>.from(data ?? {});
      }, <String, dynamic>{}, hataBaslik: 'Özet yüklenemedi');

  static Future<List<Urun>> dusukStokListesi(String salonId) => _guvenli(() async {
        final data = await _get('/dusuk-stok/$salonId') as List<dynamic>? ?? [];
        return data.map((e) => Urun.fromJson(Map<String, dynamic>.from(e))).toList();
      }, <Urun>[], hataBaslik: 'Düşük stok listesi yüklenemedi');

  static Future<List<dynamic>> urunSatisRaporu(String urunId, {String? baslangic, String? bitis}) => _guvenli(() async {
        // Backend route GET — query string ile gönder
        final qs = <String, String>{};
        if (baslangic != null) qs['baslangic'] = baslangic;
        if (bitis != null) qs['bitis'] = bitis;
        final yol = '/urun-satis-raporu/$urunId' + (qs.isEmpty ? '' : '?${Uri(queryParameters: qs).query}');
        final data = await _get(yol);
        return List<dynamic>.from(data ?? []);
      }, <dynamic>[], hataBaslik: 'Rapor yüklenemedi');

  // ============================================================
  // ÜRÜN CRUD
  // ============================================================

  static Future<List<Urun>> urunListesi(String salonId, {String? arama, String? kategoriId, String? tip}) => _guvenli(() async {
        final body = <String, dynamic>{
          if (arama != null && arama.isNotEmpty) 'arama': arama,
          if (kategoriId != null && kategoriId.isNotEmpty) 'kategori_id': kategoriId,
          if (tip != null && tip.isNotEmpty) 'tip': tip,
        };
        final data = await _post('/urunler/$salonId', body) as List<dynamic>? ?? [];
        return data.map((e) => Urun.fromJson(Map<String, dynamic>.from(e))).toList();
      }, <Urun>[], hataBaslik: 'Ürünler yüklenemedi');

  static Future<Map<String, dynamic>> urunDetay(String urunId) => _guvenli(() async {
        final data = await _get('/urun/$urunId');
        return Map<String, dynamic>.from(data ?? {});
      }, <String, dynamic>{}, hataBaslik: 'Ürün detayı yüklenemedi');

  static Future<Urun?> urunBarkodAra(String salonId, String barkod) async {
    try {
      final data = await _post('/urun-barkod/$salonId', {'barkod': barkod});
      if (data == null || data is! Map || data['status'] == 'bulunamadi') return null;
      return Urun.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      // 404 normal — sessiz dön
      return null;
    }
  }

  static Future<Urun?> urunKaydet(String salonId, Map<String, dynamic> data) => _guvenli<Urun?>(() async {
        final r = await _post('/urun-kaydet/$salonId', data);
        if (r == null || r is! Map) return null;
        return Urun.fromJson(Map<String, dynamic>.from(r));
      }, null, hataBaslik: 'Ürün kaydedilemedi');

  static Future<bool> urunSil(String urunId) => _guvenli(() async {
        await _post('/urun-sil', {'urun_id': urunId});
        return true;
      }, false, hataBaslik: 'Ürün silinemedi');

  // ============================================================
  // KATEGORİ
  // ============================================================

  static Future<List<UrunKategorisi>> kategoriListesi(String salonId) => _guvenli(() async {
        final data = await _get('/kategoriler/$salonId') as List<dynamic>? ?? [];
        return data.map((e) => UrunKategorisi.fromJson(Map<String, dynamic>.from(e))).toList();
      }, <UrunKategorisi>[], hataBaslik: 'Kategoriler yüklenemedi');

  static Future<bool> kategoriKaydet(String salonId, Map<String, dynamic> data) => _guvenli(() async {
        await _post('/kategori-kaydet/$salonId', data);
        return true;
      }, false, hataBaslik: 'Kategori kaydedilemedi');

  static Future<bool> kategoriSil(String id) => _guvenli(() async {
        await _post('/kategori-sil', {'id': id});
        return true;
      }, false, hataBaslik: 'Kategori silinemedi');

  // ============================================================
  // DEPO
  // ============================================================

  static Future<List<Depo>> depoListesi(String salonId) => _guvenli(() async {
        final data = await _get('/depolar/$salonId') as List<dynamic>? ?? [];
        return data.map((e) => Depo.fromJson(Map<String, dynamic>.from(e))).toList();
      }, <Depo>[], hataBaslik: 'Depolar yüklenemedi');

  static Future<bool> depoKaydet(String salonId, Map<String, dynamic> data) => _guvenli(() async {
        await _post('/depo-kaydet/$salonId', data);
        return true;
      }, false, hataBaslik: 'Depo kaydedilemedi');

  static Future<Map<String, dynamic>> depoSil(String id) => _guvenli(() async {
        final r = await _post('/depo-sil', {'id': id});
        return Map<String, dynamic>.from(r ?? {});
      }, <String, dynamic>{}, hataBaslik: 'Depo silinemedi');

  // ============================================================
  // TEDARİKÇİ
  // ============================================================

  static Future<List<Tedarikci>> tedarikciListesi(String salonId) => _guvenli(() async {
        final data = await _get('/tedarikciler/$salonId') as List<dynamic>? ?? [];
        return data.map((e) => Tedarikci.fromJson(Map<String, dynamic>.from(e))).toList();
      }, <Tedarikci>[], hataBaslik: 'Tedarikçiler yüklenemedi');

  static Future<bool> tedarikciKaydet(String salonId, Map<String, dynamic> data) => _guvenli(() async {
        await _post('/tedarikci-kaydet/$salonId', data);
        return true;
      }, false, hataBaslik: 'Tedarikçi kaydedilemedi');

  static Future<bool> tedarikciSil(String id) => _guvenli(() async {
        await _post('/tedarikci-sil', {'id': id});
        return true;
      }, false, hataBaslik: 'Tedarikçi silinemedi');

  // ============================================================
  // HAREKETLER & İŞLEMLER
  // ============================================================

  static Future<List<StokHareketi>> hareketListesi(String salonId,
          {String? urunId, String? depoId, String? hareketTipi, String? baslangic, String? bitis, int limit = 200}) =>
      _guvenli(() async {
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
      }, <StokHareketi>[], hataBaslik: 'Hareketler yüklenemedi');

  static Future<Map<String, dynamic>> manuelHareket(String salonId, Map<String, dynamic> data) => _guvenli(() async {
        final r = await _post('/manuel-hareket/$salonId', data);
        return Map<String, dynamic>.from(r ?? {});
      }, <String, dynamic>{}, hataBaslik: 'Hareket kaydedilemedi');

  static Future<Map<String, dynamic>> alisGirisi(String salonId, Map<String, dynamic> data) => _guvenli(() async {
        final r = await _post('/alis-girisi/$salonId', data);
        return Map<String, dynamic>.from(r ?? {});
      }, <String, dynamic>{}, hataBaslik: 'Alış kaydedilemedi');

  static Future<Map<String, dynamic>> transfer(String salonId, Map<String, dynamic> data) => _guvenli(() async {
        final r = await _post('/transfer/$salonId', data);
        return Map<String, dynamic>.from(r ?? {});
      }, <String, dynamic>{}, hataBaslik: 'Transfer yapılamadı');

  static Future<Map<String, dynamic>> sayimUygula(String salonId, List<Map<String, dynamic>> kalemler, {Map<String, dynamic>? meta}) =>
      _guvenli(() async {
        final data = <String, dynamic>{'kalemler': kalemler, ...?meta};
        final r = await _post('/sayim-uygula/$salonId', data);
        return Map<String, dynamic>.from(r ?? {});
      }, <String, dynamic>{}, hataBaslik: 'Sayım uygulanamadı');

  static Future<Map<String, dynamic>> hizliSatis(String salonId, List<Map<String, dynamic>> sepet, {Map<String, dynamic>? meta}) =>
      _guvenli(() async {
        final data = <String, dynamic>{'sepet': sepet, ...?meta};
        final r = await _post('/hizli-satis/$salonId', data);
        return Map<String, dynamic>.from(r ?? {});
      }, <String, dynamic>{}, hataBaslik: 'Satış kaydedilemedi');

  // ============================================================
  // SARF REÇETELERİ (Faz 6)
  // ============================================================

  static Future<List<Map<String, dynamic>>> receteListesi(String salonId, {String? hizmetId, String? hizmetTipi}) => _guvenli(() async {
        final qs = <String, String>{};
        if (hizmetId != null) qs['hizmet_id'] = hizmetId;
        if (hizmetTipi != null) qs['hizmet_tipi'] = hizmetTipi;
        final url = '$_base/receteler/$salonId' + (qs.isEmpty ? '' : '?${Uri(queryParameters: qs).query}');
        final r = await http.get(Uri.parse(url), headers: _headers());
        if (r.statusCode < 200 || r.statusCode >= 300) throw Exception(_mesajCek(r.statusCode, r.body, 'Reçeteler yüklenemedi'));
        final data = jsonDecode(r.body) as List<dynamic>? ?? [];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }, <Map<String, dynamic>>[], hataBaslik: 'Reçeteler yüklenemedi');

  static Future<bool> receteKaydet(String salonId, Map<String, dynamic> data) => _guvenli(() async {
        await _post('/recete-kaydet/$salonId', data);
        return true;
      }, false, hataBaslik: 'Reçete kaydedilemedi');

  static Future<bool> receteSil(String id) => _guvenli(() async {
        await _post('/recete-sil', {'id': id});
        return true;
      }, false, hataBaslik: 'Reçete silinemedi');

  // ============================================================
  // HİZMETLER (ApiController üzerinden — Sarf reçeteleri için gerekli)
  // ============================================================

  static Future<List<Map<String, dynamic>>> hizmetListesi(String salonId) => _guvenli(() async {
        final r = await http.get(
          Uri.parse('https://app.randevumcepte.com.tr/api/v1/hizmetler/$salonId'),
          headers: _headers(),
        );
        if (r.statusCode < 200 || r.statusCode >= 300) return <Map<String, dynamic>>[];
        final data = jsonDecode(r.body);
        if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
        return <Map<String, dynamic>>[];
      }, <Map<String, dynamic>>[], hataBaslik: 'Hizmetler yüklenemedi');
}
