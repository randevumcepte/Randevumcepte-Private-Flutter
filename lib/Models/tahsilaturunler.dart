
import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

class TahsilatUrun implements TahsilatKalemleri{
  TahsilatUrun({

    required this.tahsilat_id,
    required this.tutar,
    required this.adisyon_urun_id,
    this.adisyon_urun,



  });

  final String tahsilat_id;
  final String tutar;
  final String adisyon_urun_id;
  final dynamic adisyon_urun;

  Map<String, dynamic> toJson() {
    return {
      'tahsilat_id': tahsilat_id,
      'tutar': tutar,
      'adisyon_urun_id':adisyon_urun_id,


    };
  }

  factory TahsilatUrun.fromJson(Map<String, dynamic> jsonvar) {

    return TahsilatUrun(
      tahsilat_id:jsonvar["id"].toString(),
      tutar: jsonvar["tutar"].toString(),
      adisyon_urun_id: jsonvar["adisyon_hizmet_id"].toString(),
      adisyon_urun: jsonvar["adisyon_urun"].toString(),




    );
  }
}