import 'dart:convert';

import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

import 'ongorusmenedeni.dart';
class IsletmeHizmet implements OnGorusmeNedeni,TahsilatKalemleri {
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


  /*Map<String, dynamic> toJson() {
    return {
      'id': id,

      'etkinlik_adi':paket_isim,
      'fiyat':fiyat,
      'aktifmi':aktifmi,
      'mesaj':mesaj,
      'katilimcilar':katilimcilar,
      'himzet_adi':hizmet_adi,
      'paket_isim':paket_isim,
      'seans':seans,

    };
  }*/

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
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is IsletmeHizmet &&
              runtimeType == other.runtimeType &&
              hizmet_id == other.hizmet_id &&
              hizmet["hizmet_adi"] == other. hizmet["hizmet_adi"] ;

  @override
  int get hashCode => hizmet_id.hashCode ^  hizmet["hizmet_adi"].hashCode;
  String getPaketUrunAdi() => hizmet['hizmet_adi'] + ' (Hizmet)';
  String getId()=>hizmet_id;
}