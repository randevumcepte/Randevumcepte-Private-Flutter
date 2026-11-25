import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show Element, WidgetsBinding;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ceviri.dart';

class DilSecenek {
  final String kod;
  final String ad; // dilin kendi adı (Русский), yanlış dilde de tanınsın
  final String bayrak;
  const DilSecenek(this.kod, this.ad, this.bayrak);
}

/// Müşteri uygulamasının dili. Salon için açık değilse (sunucu /dil/ayar) ya da personel
/// oturumundaysa daima Türkçe; ekran metinleri lib/dil/material.dart üzerinden çevrilir.
class Dil {
  static const _kok = 'https://app.randevumcepte.com.tr/api/v1';
  static const _kKod = 'dil_kod';
  static const _kSecildi = 'dil_secildi';
  static const _kListe = 'dil_liste';
  static const _kSozluk = 'dil_sozluk_';

  /// MaterialApp bunu dinler (locale).
  static final ValueNotifier<String> degisim = ValueNotifier<String>('tr');

  static SharedPreferences? _prefs;
  static List<DilSecenek> diller = const [];
  static String _secili = 'tr';

  static bool get acik => diller.length > 1;
  static bool get _personel {
    final t = _prefs?.getString('user_type') ?? '';
    return t == '1' || t == '"1"';
  }

  /// Etkin dil
  static String get kod => (!acik || _personel || !diller.any((d) => d.kod == _secili)) ? 'tr' : _secili;
  static Locale get locale => Locale(kod);
  static DilSecenek? get secili {
    for (final d in diller) {
      if (d.kod == kod) return d;
    }
    return null;
  }

  static bool get soruldu => _prefs?.getBool(_kSecildi) ?? false;

  static String cevir(String s) => kod == 'tr' ? s : Ceviri.cevir(s);

  /// main() içinde runApp'ten önce: son bilinen dil ve sözlük diskten yüklenir.
  static Future<void> yukle() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _listeCoz(_prefs!.getString(_kListe));
      _secili = _prefs!.getString(_kKod) ?? 'tr';
      await _sozlukHazirla();
    } catch (e) {
      log('Dil.yukle: $e');
    }
    degisim.value = kod;
  }

  static void _listeCoz(String? ham) {
    if (ham == null || ham.isEmpty) {
      diller = const [];
      return;
    }
    try {
      diller = [
        for (final m in jsonDecode(ham) as List)
          DilSecenek(m['kod'].toString(), m['ad'].toString(), m['bayrak'].toString())
      ];
    } catch (_) {
      diller = const [];
    }
  }

  /// Bu markada dil seçimi açık mı, hangi diller var; seçili dilin güncel sözlüğü.
  static Future<void> sunucudanAl(String bundle) async {
    try {
      final res = await http
          .get(Uri.parse('$_kok/dil/ayar').replace(queryParameters: {'appBundle': bundle}))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      if (j is! Map || j['diller'] is! List) return;
      final ham = jsonEncode(j['diller']);
      await _prefs?.setString(_kListe, ham);
      _listeCoz(ham);
      await _sozlukHazirla();
      _yenile();
      unawaited(_sozlukGuncelle(bundle, (j['surum'] is Map ? j['surum'][_secili] : null)?.toString()));
    } catch (e) {
      log('Dil.sunucudanAl: $e');
    }
  }

  static Future<void> _sozlukHazirla() async {
    if (_secili == 'tr' || Ceviri.dil == _secili) return;
    String? ham = _prefs?.getString('$_kSozluk$_secili');
    ham ??= await rootBundle.loadString('assets/dil/$_secili.json');
    Ceviri.yukle(_secili, ham);
  }

  static Future<void> _sozlukGuncelle(String bundle, String? surum) async {
    if (_secili == 'tr' || (surum != null && surum == Ceviri.surum)) return;
    try {
      final dil = _secili;
      final res = await http
          .get(Uri.parse('$_kok/dil/sozluk/$dil').replace(queryParameters: {'appBundle': bundle}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;
      final ham = utf8.decode(res.bodyBytes);
      if (jsonDecode(ham) is! Map || dil != _secili) return;
      Ceviri.yukle(dil, ham);
      await _prefs?.setString('$_kSozluk$dil', ham);
      _yenile();
    } catch (e) {
      log('Dil.sozluk: $e');
    }
  }

  /// Müşteri dil seçti (ya da sunucudaki kaydı uygulandı).
  static Future<void> sec(String yeni, {bool kaydet = true}) async {
    if (!diller.any((d) => d.kod == yeni)) return;
    _secili = yeni;
    await _prefs?.setString(_kKod, yeni);
    await _prefs?.setBool(_kSecildi, true);
    try {
      await _sozlukHazirla();
    } catch (e) {
      log('Dil.sec: $e');
    }
    _yenile();
    if (kaydet) unawaited(sunucuyaYaz());
    final b = _sonBundle;
    if (b != null) unawaited(_sozlukGuncelle(b, null));
  }

  static String? _sonBundle;
  static void bundleAta(String b) => _sonBundle = b;

  /// Cihazın dili listede varsa kodu (ilk açılışta öneri), yoksa null.
  static String? cihazDili() {
    final c = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return diller.any((d) => d.kod == c) ? c : null;
  }

  static Future<String?> _token() async {
    final raw = _prefs?.getString('token');
    if (raw == null || raw.isEmpty) return null;
    try {
      final d = jsonDecode(raw);
      return d is String ? d : d?.toString();
    } catch (_) {
      return raw;
    }
  }

  /// Seçimi müşteri kaydına yazar: WhatsApp / bildirim de bu dilde gider (SMS Türkçe).
  static Future<void> sunucuyaYaz() async {
    final t = await _token();
    if (t == null || !acik || _personel || !soruldu) return;
    try {
      await http.post(Uri.parse('$_kok/musteri-profil/dil'),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $t'},
          body: jsonEncode({'dil': _secili})).timeout(const Duration(seconds: 15));
    } catch (e) {
      log('Dil.sunucuyaYaz: $e');
    }
  }

  /// Giriş yapan müşteri: bu telefonda seçim varsa sunucuya yazılır; yoksa salonun/önceki
  /// telefonun kaydettiği dil uygulanır.
  static Future<void> musteriEsitle() async {
    if (!acik || _personel) return;
    _yenile();
    if (soruldu) return sunucuyaYaz();
    final t = await _token();
    if (t == null) return;
    try {
      final res = await http.get(Uri.parse('$_kok/musteri-profil/dil'),
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'}).timeout(const Duration(seconds: 15));
      final j = jsonDecode(res.body);
      final d = j is Map ? (j['dil'] ?? '').toString() : '';
      if (d.isNotEmpty && d != 'tr') await sec(d, kaydet: false);
    } catch (e) {
      log('Dil.musteriEsitle: $e');
    }
  }

  /// Giriş / çıkış sonrası etkin dil yeniden hesaplanır (personel: Türkçe).
  static void oturumDegisti() => _yenile();

  /// Kullanıcı değişince / dil değişince ekrandaki her şey yeniden çizilir (const alt ağaçlar dahil).
  static void _yenile() {
    final yeni = kod;
    degisim.value = yeni;
    void gez(Element e) {
      e.markNeedsBuild();
      e.visitChildren(gez);
    }

    final bag = WidgetsBinding.instance;
    bag.addPostFrameCallback((_) => bag.rootElement?.visitChildren(gez));
    bag.scheduleFrame();
  }
}
