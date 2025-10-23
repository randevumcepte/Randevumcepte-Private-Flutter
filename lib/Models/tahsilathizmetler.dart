
import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

class TahsilatHizmet implements TahsilatKalemleri {
  TahsilatHizmet({

    required this.tahsilat_id,
    required this.tutar,
    required this.adisyon_hizmet_id,
    this.adisyon_hizmet,



  });

  final String tahsilat_id;
  final String tutar;
  final String adisyon_hizmet_id;
  final dynamic adisyon_hizmet;

  Map<String, dynamic> toJson() {
    return {
      'tahsilat_id': tahsilat_id,
      'tutar': tutar,
      'adisyon_hizmet_id':adisyon_hizmet_id,


    };
  }

  factory TahsilatHizmet.fromJson(Map<String, dynamic> jsonvar) {

    return TahsilatHizmet(
      tahsilat_id:jsonvar["id"].toString(),
      tutar: jsonvar["tutar"].toString(),
      adisyon_hizmet_id: jsonvar["adisyon_hizmet_id"].toString(),
      adisyon_hizmet: jsonvar["adisyon_hizmet"].toString(),




    );
  }
}