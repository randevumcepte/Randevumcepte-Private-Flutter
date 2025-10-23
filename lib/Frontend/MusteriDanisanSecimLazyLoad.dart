import '../Backend/backend.dart';
import '../Models/musteri_danisanlar.dart';

class MusteriDanisanSecimLazyLoad {
  static Future<List<MusteriDanisan>> fetch(
      {required String salonId, String search = '', int offset = 0, int limit = 50}) async {
    return await musterilistegetirSayfali(salonId, search, limit.toString(), offset.toString());
  }
}




