// Hesabim (My Account) API istemcisi + modeller.
// Backend: GET /api/v1/hesabim, POST /api/v1/hesabim/fatura-bilgi-guncelle (Bearer).
// Satin alma YOK (Netflix modeli) — sadece bilgilendirme + fatura bilgisi duzenleme.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

String _s(dynamic v) => v == null ? '' : v.toString();
int? _iN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

class HesabimIsletme {
  final String id, salonAdi, uyelikTuruAdi, uyelikPeriyoduAdi;
  final int uyelikTuru, uyelikPeriyodu;
  final String uyelikBitisTarihi, kayitTarihi;
  final int? kalanGun;
  final String vergiAdi, vergiNo, vergiAdresi, kdvOrani;

  HesabimIsletme({
    required this.id,
    required this.salonAdi,
    required this.uyelikTuru,
    required this.uyelikTuruAdi,
    required this.uyelikPeriyodu,
    required this.uyelikPeriyoduAdi,
    required this.uyelikBitisTarihi,
    required this.kayitTarihi,
    required this.kalanGun,
    required this.vergiAdi,
    required this.vergiNo,
    required this.vergiAdresi,
    required this.kdvOrani,
  });

  factory HesabimIsletme.fromJson(Map<String, dynamic> j) => HesabimIsletme(
        id: _s(j['id']),
        salonAdi: _s(j['salon_adi']),
        uyelikTuru: _iN(j['uyelik_turu']) ?? 0,
        uyelikTuruAdi: _s(j['uyelik_turu_adi']),
        uyelikPeriyodu: _iN(j['uyelik_periyodu']) ?? 0,
        uyelikPeriyoduAdi: _s(j['uyelik_periyodu_adi']),
        uyelikBitisTarihi: _s(j['uyelik_bitis_tarihi']),
        kayitTarihi: _s(j['kayit_tarihi']),
        kalanGun: _iN(j['kalan_gun']),
        vergiAdi: _s(j['vergi_adi']),
        vergiNo: _s(j['vergi_no']),
        vergiAdresi: _s(j['vergi_adresi']),
        kdvOrani: j['kdv_orani'] == null ? '' : _s(j['kdv_orani']),
      );
}

class HesabimKullanici {
  final String name, email, gsm1, profilResim;
  HesabimKullanici(
      {required this.name,
      required this.email,
      required this.gsm1,
      required this.profilResim});
  factory HesabimKullanici.fromJson(Map<String, dynamic> j) => HesabimKullanici(
        name: _s(j['name']),
        email: _s(j['email']),
        gsm1: _s(j['gsm1']),
        profilResim: _s(j['profil_resim']),
      );
}

class HesabimHizmet {
  final String kod, ad, aciklama, icon, renk, periyot;
  final bool aktif, deneme;
  final String baslangic, bitis, denemeLabel;
  final int? kalanGun;

  HesabimHizmet({
    required this.kod,
    required this.ad,
    required this.aciklama,
    required this.icon,
    required this.renk,
    required this.periyot,
    required this.aktif,
    required this.deneme,
    required this.baslangic,
    required this.bitis,
    required this.denemeLabel,
    required this.kalanGun,
  });

  factory HesabimHizmet.fromJson(Map<String, dynamic> j) => HesabimHizmet(
        kod: _s(j['kod']),
        ad: _s(j['ad']),
        aciklama: _s(j['aciklama']),
        icon: _s(j['icon']),
        renk: _s(j['renk']),
        periyot: _s(j['periyot']),
        aktif: j['aktif'] == true || j['aktif'] == 1 || j['aktif'] == '1',
        deneme: j['deneme'] == true || j['deneme'] == 1,
        baslangic: _s(j['baslangic']),
        bitis: _s(j['bitis']),
        denemeLabel: _s(j['deneme_label']),
        kalanGun: _iN(j['kalan_gun']),
      );
}

class HesabimVeri {
  final HesabimIsletme isletme;
  final HesabimKullanici kullanici;
  final List<HesabimHizmet> hizmetler;
  final List<Map<String, dynamic>> faturalar;
  final List<Map<String, dynamic>> smsSiparisleri;

  HesabimVeri({
    required this.isletme,
    required this.kullanici,
    required this.hizmetler,
    required this.faturalar,
    required this.smsSiparisleri,
  });

  factory HesabimVeri.fromJson(Map<String, dynamic> j) => HesabimVeri(
        isletme: HesabimIsletme.fromJson(
            Map<String, dynamic>.from(j['isletme'] ?? {})),
        kullanici: HesabimKullanici.fromJson(
            Map<String, dynamic>.from(j['kullanici'] ?? {})),
        hizmetler: ((j['hizmetler'] as List?) ?? [])
            .map((e) => HesabimHizmet.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        faturalar: ((j['faturalar'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        smsSiparisleri: ((j['sms_siparisleri'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
}

class HesabimApi {
  static const String _base = 'https://app.randevumcepte.com.tr/api/v1';

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

  static Future<Map<String, String>> _headers() async {
    final t = await _token();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  static Future<HesabimVeri> getir(String sube) async {
    final uri = Uri.parse('$_base/hesabim').replace(queryParameters: {'sube': sube});
    final res = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Hesap bilgileri alınamadı (${res.statusCode})');
    }
    return HesabimVeri.fromJson(Map<String, dynamic>.from(jsonDecode(res.body)));
  }

  static Future<bool> faturaBilgiGuncelle({
    required String sube,
    required String vergiAdi,
    required String vergiNo,
    required String vergiAdresi,
    required String kdvOrani,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/hesabim/fatura-bilgi-guncelle'),
          headers: await _headers(),
          body: jsonEncode({
            'sube': sube,
            'vergi_adi': vergiAdi,
            'vergi_no': vergiNo,
            'vergi_adresi': vergiAdresi,
            if (kdvOrani.isNotEmpty) 'kdv_orani': kdvOrani,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) return false;
    final j = jsonDecode(res.body);
    return j is Map && j['success'] == true;
  }
}
