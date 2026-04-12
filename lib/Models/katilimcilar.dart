import 'package:randevu_sistem/Models/musteri_danisanlar.dart';

class Katilimcilar {
  Katilimcilar({
    required this.durum,
    required this.musteri_danisan,


  });


  final String durum;
  final String musteri_danisan;


  factory Katilimcilar.fromJson(Map<String, dynamic> json) {
    return Katilimcilar(

      durum: json["durum"].toString(),
      musteri_danisan: json["musteri"].toString(),

    );
  }
}