import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';

/// Beyaz etiket marka logosu: uygulamanın paket adından (applicationId) seçilir.
/// Böylece bir salonun build'ine başka salonun logosu karışmaz; yeni salon
/// eklenince yalnız aşağıdaki tabloya bir satır eklenir.
class Marka {
  static const String _varsayilan = 'images/randevumcepteicon.png';

  static const Map<String, String> _logolar = {
    'olanail': 'images/olanailicon.png',
    'senailbeauty': 'images/senailbeauty.png',
    'salooncadde': 'images/salooncaddeicon.png',
    'fizyofly': 'images/fizyoflyic.png',
    'eymlife': 'images/eymlifeicon.png',
    'ezgitakmaz': 'images/ezgitakmazicon.png',
    'yasemintuzun': 'images/yasemintuzunicon.png',
    'aydangurece': 'images/aydangureceicon.png',
    'bercislinaguzellik': 'images/bercislina.png',
    'cerenceviz': 'images/ccicon.png',
    'dermatouch': 'images/dermatouchicon.png',
    'drmet': 'images/drmeticon.png',
    'ebrumete': 'images/ebrumeteicon.png',
    'esemavci': 'images/esemavciicon.png',
    'fulyakandemir': 'images/fulyakandemiricon.png',
    'moncher': 'images/monchericon.png',
    'shemall': 'images/shemallicon.png',
    'shiningstars': 'images/shiningstarsicon.png',
    'vionnaguzellik': 'images/vionnaguzellik.png',
    'randevumcepteprivate': 'images/randevumcepteicon.png',
  };

  /// Müşteriye giden mesajda (kayıt şifresi) geçen işletme adı. Tabloda olmayan markada uygulamanın telefondaki adı kullanılır.
  static const Map<String, String> _adlar = {
    'olanail': 'Ola Nail',
    'senailbeauty': 'Senail Beauty',
    'salooncadde': 'Saloon Cadde',
    'fizyofly': 'FizyoFLY',
    'eymlife': 'EYM Life Güzellik Merkezi',
    'ezgitakmaz': 'Ezgi Takmaz Güzellik Merkezi',
    'yasemintuzun': 'Yasemin Tüzün Güzellik Merkezi',
    'bercislinaguzellik': 'Bercislina Güzellik Salonu',
    'cerenceviz': 'Ceren Ceviz Estetik',
    'vionnaguzellik': 'Vionna Güzellik Salonu',
  };

  /// İşletme adı (kod içine sabit salon adı yazılmaz)
  static String ad = 'RandevumCepte';

  /// Açılış, giriş, kayıt ve şifre ekranlarında gösterilen logo
  static String logo = _varsayilan;

  /// Aktif marka kodu (markalar/KOD), config yoksa paket adının son parçası.
  static String kod = '';

  /// main() içinde runApp'ten önce bir kez çağrılır.
  /// Önce tool/marka.sh'in ürettiği assets/marka/aktif.json (tek config),
  /// yoksa paket adına göre aşağıdaki tablo.
  static Future<void> yukle() async {
    try {
      final j = jsonDecode(await rootBundle.loadString('assets/marka/aktif.json'));
      if (j is Map) {
        final k = (j['kod'] ?? '').toString();
        final l = (j['logo'] ?? '').toString();
        final a = (j['ad'] ?? '').toString();
        if (k.isNotEmpty && l.isNotEmpty && a.isNotEmpty) {
          kod = k;
          logo = l;
          ad = a;
          return;
        }
      }
    } catch (_) {
      // Config yok (eski kurulum) -> paket adı tablosu.
    }
    try {
      final bilgi = await PackageInfo.fromPlatform();
      final marka = bilgi.packageName.split('.').last;
      kod = marka;
      logo = _logolar[marka] ?? _varsayilan;
      final uygulamaAdi = bilgi.appName.trim();
      ad = _adlar[marka] ?? (uygulamaAdi.isEmpty ? ad : uygulamaAdi);
    } catch (_) {
      logo = _varsayilan;
    }
  }
}
