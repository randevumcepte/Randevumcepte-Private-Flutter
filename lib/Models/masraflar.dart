import '../yonetici/dashboard/paketsatisi.dart';

class Masraf {
  Masraf({

    required this.id,
    required this.tutar,
    required this.tarih,
    required this.notlar,
    required this.odeme_yontemi_id,
    required this.harcayan,
    required this.masraf_kategorisi,
    required this.aciklama,
    required this.odeme_yontemi,



  });
  final String id;
  final String tutar;
  final String tarih;
  final String notlar;
  final String odeme_yontemi_id;
  final Map<String, dynamic> harcayan;
  final Map<String, dynamic> masraf_kategorisi;
  final Map<String, dynamic> odeme_yontemi;
  final String aciklama;





  factory Masraf.fromJson(Map<String, dynamic> json) {
    return Masraf(
      id: json["id"].toString(),
      tutar: json["tutar"].toString(),
      tarih: json["tarih"].toString(),
      notlar: json["notlar"].toString(),
      odeme_yontemi_id : json["odeme_yontemi_id"].toString(),
      harcayan:json["harcayan"],
      masraf_kategorisi: json["masraf_kategorisi"],
        odeme_yontemi: json["odeme_yontemi"],
      aciklama: json["aciklama"].toString()


    );
  }
}