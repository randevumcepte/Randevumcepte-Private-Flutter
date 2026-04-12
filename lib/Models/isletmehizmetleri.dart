import 'dart:convert';

import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';
import 'ongorusmenedeni.dart';

class IsletmeHizmet implements OnGorusmeNedeni, TahsilatKalemleri {
  IsletmeHizmet({
    required this.hizmet_id,
    required this.hizmet,
    required this.hizmet_kategorisi,
    required this.fiyat,
    required this.sure,
    required this.bolum,
  });

  final String hizmet_id;
  final dynamic hizmet;
  final dynamic hizmet_kategorisi;
  final String fiyat;
  final String sure;
  final String bolum;

  // ÖNEMLİ: == operatörünü düzgün implemente edin
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is IsletmeHizmet &&
        runtimeType == other.runtimeType &&
        hizmet_id == other.hizmet_id;
  }

  // ÖNEMLİ: hashCode'u da implemente edin
  @override
  int get hashCode => hizmet_id.hashCode;

  // toString metodunu da override edin (debug için faydalı)
  @override
  String toString() {
    return 'IsletmeHizmet{hizmet_id: $hizmet_id, hizmet_adi: ${hizmet['hizmet_adi']}}';
  }

  factory IsletmeHizmet.fromJson(Map<String, dynamic> jsonvar) {
    return IsletmeHizmet(
      hizmet_id: jsonvar["hizmet_id"].toString(),
      hizmet: jsonvar["hizmetler"],
      hizmet_kategorisi: jsonvar["hizmet_kategorisi"],
      sure: jsonvar["sure_dk"].toString(),
      fiyat: jsonvar["baslangic_fiyat"].toString(),
      bolum: jsonvar["bolum"].toString(),
    );
  }

  String getPaketUrunAdi() => hizmet['hizmet_adi'] + ' (Hizmet)';
  String getId() => hizmet_id;
}