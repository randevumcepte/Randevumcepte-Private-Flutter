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

/// Uygulama dili (müşteri ve personel, herkes kendi dilini seçer). Salon için açık değilse (sunucu
/// /dil/ayar) daima Türkçe; ekran metinleri lib/dil/material.dart üzerinden çevrilir.
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
  static String _musteriSecili = 'tr'; // müşteri + giriş öncesi ekranlar

  static bool get acik => diller.length > 1;
  static bool get _personel {
    final t = _prefs?.getString('user_type') ?? '';
    return t == '1' || t == '"1"';
  }

  /// Personel seçimi kişiye özel saklanır (aynı telefonu birden çok personel kullanabilir).
  static String get _kPersonel {
    var id = '';
    try {
      final u = jsonDecode(_prefs?.getString('user') ?? '');
      if (u is Map) id = (u['id'] ?? '').toString();
    } catch (_) {}
    return 'dil_kod_personel_$id';
  }

  /// Oturuma göre seçili dil: personel kendi seçimi, müşteri / giriş öncesi telefonun seçimi.
  static String get _secili => _personel ? (_prefs?.getString(_kPersonel) ?? 'tr') : _musteriSecili;

  /// Etkin dil
  static String get kod => (!acik || !diller.any((d) => d.kod == _secili)) ? 'tr' : _secili;
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
      _musteriSecili = _prefs!.getString(_kKod) ?? 'tr';
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
    final dil = _secili;
    // Uygulama güncellendiyse paketteki sözlük, sunucudan inmiş eskisinin yerine geçer
    final paket = await rootBundle.loadString('assets/dil/$dil.json');
    final paketSurum = RegExp(r'"surum":"(w+)"').firstMatch(paket)?.group(1) ?? '';
    var ham = _prefs?.getString('$_kSozluk$dil');
    if (ham == null || _prefs?.getString('${_kSozluk}paket_$dil') != paketSurum) {
      ham = paket;
      await _prefs?.remove('$_kSozluk$dil');
      await _prefs?.setString('${_kSozluk}paket_$dil', paketSurum);
    }
    Ceviri.yukle(dil, ham);
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
    if (_personel) {
      await _prefs?.setString(_kPersonel, yeni);
    } else {
      _musteriSecili = yeni;
      await _prefs?.setString(_kKod, yeni);
      await _prefs?.setBool(_kSecildi, true);
    }
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

  /// Seçimi müşteri / personel kaydına yazar: WhatsApp / bildirim de bu dilde gider (SMS Türkçe).
  static Future<void> sunucuyaYaz() async {
    final t = await _token();
    if (t == null || !acik || (!_personel && !soruldu)) return;
    try {
      await http.post(Uri.parse(_personel ? '$_kok/profil/dil' : '$_kok/musteri-profil/dil'),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $t'},
          body: jsonEncode({'dil': _secili})).timeout(const Duration(seconds: 15));
    } catch (e) {
      log('Dil.sunucuyaYaz: $e');
    }
  }

  /// Giriş yapan müşteri / personel: bu telefonda seçim varsa sunucuya yazılır; yoksa salonun/önceki
  /// telefonun kaydettiği dil uygulanır.
  static Future<void> oturumEsitle() async {
    if (!acik) return;
    await _sozlukHazirla();
    _yenile();
    if (_personel ? _prefs?.getString(_kPersonel) != null : soruldu) return sunucuyaYaz();
    final t = await _token();
    if (t == null) return;
    try {
      final res = await http.get(Uri.parse(_personel ? '$_kok/profil/dil' : '$_kok/musteri-profil/dil'),
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'}).timeout(const Duration(seconds: 15));
      final j = jsonDecode(res.body);
      final d = j is Map ? (j['dil'] ?? '').toString() : '';
      if (d.isNotEmpty && d != 'tr') await sec(d, kaydet: false);
    } catch (e) {
      log('Dil.oturumEsitle: $e');
    }
  }

  /// Giriş / çıkış sonrası etkin dil yeniden hesaplanır (personel kendi dili, müşteri kendi dili).
  static void oturumDegisti() {
    _sozlukHazirla().whenComplete(_yenile);
  }

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
