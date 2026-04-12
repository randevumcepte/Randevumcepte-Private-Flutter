import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

import 'ongorusmenedeni.dart';

class Urun implements OnGorusmeNedeni,TahsilatKalemleri{
  Urun({

    required this.id,
    required this.urun_adi,
    required this.barkod,
    required this.fiyat,
    required this.aktif,
    required this.stok_adedi,
    required this.dusuk_stok_siniri,


  });
  final String id;
  final String urun_adi;
  final String barkod;
  final String fiyat;
  final String aktif;
  final String stok_adedi;
  final String dusuk_stok_siniri;
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'urun_adi': urun_adi,
      'barkod': barkod,
      'fiyat':fiyat,
      'aktif':aktif,
      'stok_adedi':stok_adedi,
      'dusuk_stok_siniri':dusuk_stok_siniri
    };
  }
  factory Urun.fromJson(Map<String, dynamic> json) {
    return Urun(
      id: json["id"].toString(),
      urun_adi: json["urun_adi"].toString(),
      barkod: json["barkod"].toString(),
      fiyat: json["fiyat"].toString(),
      aktif: json["aktif"].toString(),
      stok_adedi: json["stok_adedi"].toString(),
      dusuk_stok_siniri: json["dusuk_stok_siniri"].toString(),



    );
  }
  String getId()=>id;
  String getPaketUrunAdi() => urun_adi+ ' (Ürün)';
}