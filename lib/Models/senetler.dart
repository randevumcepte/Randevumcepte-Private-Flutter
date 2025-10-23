import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

import '../yonetici/dashboard/paketsatisi.dart';

class Senet implements TahsilatKalemleri {
  Senet({

    required this.id,
    required this.kefil_adi,
    required this.kefil_adres,
    required this.kefil_tc_vergi_no,
    required this.adisyon,
    required this.musteri,
    required this.senet_turu,
    required this.vadeler,
    required this.tarih,


  });
  final String id;
  final String kefil_adi;
  final String kefil_adres;
  final String kefil_tc_vergi_no;
  final Map<String, dynamic> adisyon;
  final Map<String, dynamic> musteri;
  final List<dynamic> vadeler;
  //final List<dynamic> urunler;
  //final List<dynamic> hizmetler;
  final String senet_turu;
  final String tarih;




  factory Senet.fromJson(Map<String, dynamic> json) {
    return Senet(
      id: json["id"].toString(),
      kefil_adi: json["kefil_adi"].toString(),
      kefil_adres: json["kefil_adres"].toString(),
      kefil_tc_vergi_no: json["kefil_tc_vergi_no"].toString(),
      //urunler: json["urunler"],
      //hizmetler: json["geldimi"],
        adisyon:json["adisyon"],
      musteri:json["musteri"],
      vadeler:json["vadeler"],
      senet_turu: json["senet_turu"].toString(),
      tarih: json["created_at"].toString(),

    );
  }
}