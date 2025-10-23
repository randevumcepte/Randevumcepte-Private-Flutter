import '../yonetici/dashboard/paketsatisi.dart';

class Satis {
  Satis({

    required this.id,
    required this.musteri,
    required this.paketler,
    //required this.urunler,
    //required this.hizmetler,

    required this.notlar,
    required this.dogrulama_kdou,
    required this.tarih,

  });
  final String id;
  final String tarih;
  final Map<String, dynamic> musteri;
  final List<dynamic> paketler;
  //final List<dynamic> urunler;
  //final List<dynamic> hizmetler;
  final String notlar;
  final String dogrulama_kdou;



  factory Satis.fromJson(Map<String, dynamic> json) {
    return Satis(
      id: json["id"].toString(),
      tarih: json["tarih"].toString(),
      musteri: json["musteri"],
      paketler: json["paketler"],
      //urunler: json["urunler"],
      //hizmetler: json["geldimi"],
      notlar:json["notlar"].toString(),
      dogrulama_kdou: json["dogrulama_kdou"].toString(),

    );
  }
}