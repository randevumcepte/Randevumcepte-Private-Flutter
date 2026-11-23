import 'package:package_info_plus/package_info_plus.dart';

/// Beyaz etiket marka logosu: uygulamanın paket adından (applicationId) seçilir.
/// Böylece bir salonun build'ine başka salonun logosu karışmaz; yeni salon
/// eklenince yalnız aşağıdaki tabloya bir satır eklenir.
class Marka {
  static const String _varsayilan = 'images/randevumcepteicon.png';

  static const Map<String, String> _logolar = {
    'olanail': 'images/olanailicon.png',
    'salooncadde': 'images/salooncaddeicon.png',
    'fizyofly': 'images/fizyoflyic.png',
    'eymlife': 'images/eymlifeicon.png',
    'ezgitakmaz': 'images/ezgitakmazicon.png',
    'yasemintuzun': 'images/yasemintuzunicon.png',
    'randevumcepteprivate': 'images/randevumcepteicon.png',
  };

  /// Açılış, giriş, kayıt ve şifre ekranlarında gösterilen logo
  static String logo = _varsayilan;

  /// main() içinde runApp'ten önce bir kez çağrılır.
  static Future<void> yukle() async {
    try {
      final paket = (await PackageInfo.fromPlatform()).packageName;
      logo = _logolar[paket.split('.').last] ?? _varsayilan;
    } catch (_) {
      logo = _varsayilan;
    }
  }
}
