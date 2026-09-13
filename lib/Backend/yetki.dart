import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Personel yetki kontrol merkezi.
///
/// Backend'in /api/v1/benimYetkilerim cevabini cache'ler, sayfalarda
/// sayet yetki kontrolu yapilmasi gerekiyorsa buraya bakar.
///
/// Onemli:
///   - Yetki yoksa false doner (kapali default)
///   - Cache yenileme: girisin sonunda + Personeller listesi acilirken
///   - Cache anahtari kullanici + sube scope'lu: 'yetkilerim_v2_{yetkiliId}_{salonId}'
///     Boylece farkli kullanici veya sube arasinda karismaz.
///   - "Salon sahibi" veya "Personel rolu degil" durumunda TUM yetkiler acik
///   - Cache yoksa GERIYE DONUK UYUMLU: tum yetkiler acik (eski mobile davranisi)
///
/// Reactive:
///   - [versiyon] ValueNotifier her tazele/temizle'de artar. UI ValueListenableBuilder
///     ile dinleyip otomatik rebuild olur. Boylece yetki ayar ekraninda kayit yapinca
///     ya da kullanici degisince bottom nav vb. anlik guncellenir.
///
/// Kullanim:
///   await Yetki.tazele(salonid: '15', yetkiliId: '42');
///   if (Yetki.varMi('musteri.telefon_gor')) { ... }
///   Text(Yetki.telefonGoster(musteri.cep_telefon));
class Yetki {
  static const _prefsKeyPrefix = 'yetkilerim_v2';

  static Map<String, bool> _ayarlar = {};
  static bool _salonSahibi = true; // default tam yetki (geriye donuk)
  static bool _personelRolunde = false;
  static String _sablon = 'tam_yetki';
  static bool _yuklendi = false;
  static String? _scopeKey; // bellekteki ayarin scope'u (kullanici+sube)

  /// Yetki her degistiginde (tazele/temizle) artan versiyon.
  /// UI'da ValueListenableBuilder ile dinleyip yetkiye bagimli alanlari
  /// otomatik rebuild ettirmek icin kullanilir.
  static final ValueNotifier<int> versiyon = ValueNotifier<int>(0);

  /// Backend'den gelen yetki ayarlari ONCEKI tazele ile farkliysa true olur
  /// (ilk yukleme/login disinda). UI bunu dinleyip kullaniciyi cikis yapmaya
  /// zorlar — yonetici yetki degistirdiyse anlik etki icin.
  static final ValueNotifier<bool> yetkiAyarlariDegisti =
      ValueNotifier<bool>(false);

  // ═════════════════════ Public API ═════════════════════

  /// Sayfa ilk acilirken cache'i bellege yukle. Aktif kullanici+sube
  /// belirlenirse scope'lu cache okunur. Yoksa ilk uygun scope'lu key okunur
  /// (uygulama yeni acildi, henuz tazele cagrilmadi senaryosu).
  static Future<void> baslat({String? yetkiliId, String? salonid}) async {
    if (_yuklendi) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? raw;
      String? scope;
      if (yetkiliId != null && salonid != null) {
        scope = _scope(yetkiliId, salonid);
        raw = prefs.getString(scope);
      } else {
        // Hangi scope oldugunu bilmiyoruz; herhangi bir scope'lu kayit varsa
        // ilk eslesen okunur (en yaygin senaryo: tek kullanici, tek sube).
        for (final k in prefs.getKeys()) {
          if (k.startsWith('${_prefsKeyPrefix}_')) {
            raw = prefs.getString(k);
            scope = k;
            break;
          }
        }
      }
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _ayarlar = ((json['ayarlar'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(k.toString(), v == true),
        );
        _salonSahibi = json['salon_sahibi'] == true;
        _personelRolunde = json['personel_rolunde'] == true;
        _sablon = (json['sablon'] ?? 'tam_yetki').toString();
        _scopeKey = scope;
      }
    } catch (e) {
      debugPrint('Yetki.baslat hata: $e');
    }
    _yuklendi = true;
    versiyon.value++;
  }

  /// Backend'den yetkileri yeniden cek ve cache'le. Login sonrasi + Personeller
  /// sayfasi acilirken + sube secimi sonrasi cagirilmasi gereklidir.
  ///
  /// salonid: mevcut secili sube
  /// yetkiliId: giris yapan kisinin isletme_yetkilileri.id'si. Verilirse cache
  ///   anahtari (yetkiliId, salonid) ile scope'lanir. Verilmezse SharedPrefs
  ///   icindeki 'user' objesinden cikarilmaya calisilir.
  static Future<void> tazele({required String salonid, String? yetkiliId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Login akisi token'i ayri bir key'de tutuyor: setString('token', json.encode(...))
      String? token;
      final rawToken = prefs.getString('token');
      if (rawToken != null && rawToken.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawToken);
          token = decoded is String ? decoded : decoded?.toString();
        } catch (_) {
          token = rawToken; // direkt string olabilir
        }
      }
      // Fallback: user objesi icindeki token + yetkili_id
      String? userIdFromPrefs;
      if (token == null || token.isEmpty || yetkiliId == null) {
        final userRaw = prefs.getString('user');
        if (userRaw != null) {
          try {
            final user = jsonDecode(userRaw);
            if (user is Map) {
              token ??= user['token']?.toString();
              userIdFromPrefs = user['id']?.toString();
            }
          } catch (_) {}
        }
      }
      yetkiliId ??= userIdFromPrefs;

      if (token == null || token.isEmpty) {
        // Token yoksa auth gerektiren benimYetkilerim'i cagiramayiz.
        // Cache default'a duselim (tum yetkiler acik - geriye donuk).
        _ayarlar = {};
        _salonSahibi = true;
        _personelRolunde = false;
        _sablon = 'tam_yetki';
        if (_scopeKey != null) {
          await prefs.remove(_scopeKey!);
          _scopeKey = null;
        }
        _yuklendi = true;
        versiyon.value++;
        return;
      }
      final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/benimYetkilerim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'sube': salonid}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['basarili'] == true) {
          // ONCEKI yetki snapshot'ini sakla — yeni ile karsilastirip
          // degisiklik varsa (ilk yukleme degilse) notifier tetiklenecek.
          final eskiAyarlar = Map<String, bool>.from(_ayarlar);
          final eskiSalonSahibi = _salonSahibi;
          final eskiPersonelRolunde = _personelRolunde;
          final ilkYukleme = !_yuklendi;

          _ayarlar = ((data['ayarlar'] as Map?) ?? const {}).map(
            (k, v) => MapEntry(k.toString(), v == true),
          );
          _salonSahibi = data['salon_sahibi'] == true;
          _personelRolunde = data['personel_rolunde'] == true;
          _sablon = (data['sablon'] ?? 'tam_yetki').toString();

          // Degisiklik tespiti (sadece ilk yukleme/login disinda)
          if (!ilkYukleme) {
            final ayarlarFarkli = !_haritalarEsit(eskiAyarlar, _ayarlar);
            final rolFarkli = eskiSalonSahibi != _salonSahibi ||
                eskiPersonelRolunde != _personelRolunde;
            if (ayarlarFarkli || rolFarkli) {
              yetkiAyarlariDegisti.value = true;
            }
          }
          // Scope key'i belirle (yetkiliId varsa onu kullan, yoksa fallback 'anon')
          final scope = _scope(yetkiliId ?? 'anon', salonid);
          // Eski (farkli scope'lu) bellek varsa onu da temizle ki kullanici
          // veya sube degisikliginde stale cache kalmasin.
          if (_scopeKey != null && _scopeKey != scope) {
            await prefs.remove(_scopeKey!);
          }
          _scopeKey = scope;
          await prefs.setString(
            scope,
            jsonEncode({
              'ayarlar': _ayarlar,
              'salon_sahibi': _salonSahibi,
              'personel_rolunde': _personelRolunde,
              'sablon': _sablon,
            }),
          );
        }
      } else {
        debugPrint('Yetki.tazele non-200: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Yetki.tazele hata: $e');
    }
    _yuklendi = true;
    versiyon.value++;
  }

  /// Logout / hesap degisikligi sirasinda cache'i temizle.
  /// Hem bellekteki state hem de tum scope'lu kayitlar (cihazda kalan eski
  /// kullanicilarin yetkileri dahil) silinir.
  static Future<void> temizle() async {
    _ayarlar = {};
    _salonSahibi = true;
    _personelRolunde = false;
    _sablon = 'tam_yetki';
    _scopeKey = null;
    _yuklendi = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final silinecek = prefs.getKeys()
          .where((k) => k.startsWith('${_prefsKeyPrefix}_') || k == 'yetkilerim_v1')
          .toList();
      for (final k in silinecek) {
        await prefs.remove(k);
      }
    } catch (_) {}
    versiyon.value++;
  }

  /// Belirli bir yetki anahtarı var mı?
  ///
  /// Salon sahibi veya Personel rolu DEGIL ise: her zaman true.
  /// Personel rolu ise: cache'ten oku, yoksa false.
  /// Cache hic yuklenmediyse (henuz tazele cagirilmadi): true (defansif).
  static bool varMi(String key) {
    if (!_yuklendi) return true; // henuz baslatilmadi - eski davranis
    if (_salonSahibi || !_personelRolunde) return true;
    return _ayarlar[key] == true;
  }

  /// Telefon numarasini gosterilebilir hale getir.
  /// Yetki yoksa maskeli: "0532 *** ** 47"
  static String telefonGoster(String? tel) {
    if (tel == null || tel.isEmpty) return '';
    if (varMi('musteri.telefon_gor')) return tel;
    return _maskele(tel);
  }

  /// Hassas tutar maskeleme (yetki yoksa "****")
  static String tutarGoster(String tutar, String key) {
    if (varMi(key)) return tutar;
    return '****';
  }

  // === Getter'lar (UI'da ozel goruntu icin) ===
  static bool get salonSahibi => _salonSahibi;
  static bool get personelRolunde => _personelRolunde;
  static String get sablon => _sablon;
  static bool get yuklendi => _yuklendi;
  static Map<String, bool> get tumAyarlar => Map.unmodifiable(_ayarlar);

  // ═════════════════════ Helpers ═════════════════════

  static String _scope(String yetkiliId, String salonid) =>
      '${_prefsKeyPrefix}_${yetkiliId}_$salonid';

  static bool _haritalarEsit(Map<String, bool> a, Map<String, bool> b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (a[k] != b[k]) return false;
    }
    return true;
  }

  /// 0532 123 45 67 → 0532 *** ** 67
  static String _maskele(String tel) {
    final digits = tel.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 2) return tel;
    final son2 = digits.substring(digits.length - 2);
    final bas4 = digits.length >= 4 ? digits.substring(0, 4) : digits.substring(0, digits.length - 2);
    return '$bas4 *** ** $son2';
  }
}
