
import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

class TahsilatPaket  implements TahsilatKalemleri{
  TahsilatPaket({

    required this.tahsilat_id,
    required this.tutar,
    required this.adisyon_paket_id,
    this.adisyon_paket,



  });

  final String tahsilat_id;
  final String tutar;
  final String adisyon_paket_id;
  final dynamic adisyon_paket;

  Map<String, dynamic> toJson() {
    return {
      'tahsilat_id': tahsilat_id,
      'tutar': tutar,
      'adisyon_paket_id':adisyon_paket_id,


    };
  }

  factory TahsilatPaket.fromJson(Map<String, dynamic> jsonvar) {

    return TahsilatPaket(
      tahsilat_id:jsonvar["id"].toString(),
      tutar: jsonvar["tutar"].toString(),
      adisyon_paket_id: jsonvar["adisyon_paket_id"].toString(),
      adisyon_paket: jsonvar["adisyon_paket"].toString(),




    );
  }
}