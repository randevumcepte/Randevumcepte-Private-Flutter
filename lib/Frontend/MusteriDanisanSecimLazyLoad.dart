import 'dart:convert';
import 'dart:developer';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';

class MusteriDanisanSecimLazyLoad {
  static Future<List<MusteriDanisan>> fetch(
      {required String seciliMusteri,required String salonId, String search = '', int offset = 0, int limit = 50}) async {
    log('Seçili müşteri '+seciliMusteri.toString());
    var musteri =  await musterilistegetirSayfali(seciliMusteri,salonId, search, limit.toString(), offset.toString());

    return musteri;
  }
}


