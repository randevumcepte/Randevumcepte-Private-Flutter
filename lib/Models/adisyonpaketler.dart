
import 'dart:convert';

import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

import 'adisyonkalemleri.dart';

class AdisyonPaket implements AdisyonKalemleri {
  AdisyonPaket({
    required this.id,
    required this.adisyon_id,
    required this.paket_id,
    required this.baslangic_tarihi,
    required this.seans_araligi,
    required this.fiyat,

    required this.personel_id,

    required this.taksitli_tahsilat_id,
    required this.senet_id,
    required this.indirim_tutari,
    required this.hediye,
    required this.seans_baslangic_saati,

    this.personel,
    this.urun,
    this.paket,
    this.seanslar,




  });
  final String paket_id;
  final String id;

  final String fiyat;

  final String personel_id;
  final String baslangic_tarihi;

  final String taksitli_tahsilat_id;
  final String senet_id;
  final String indirim_tutari;
  final String hediye;
  final String adisyon_id;
  final String seans_araligi;
  final String seans_baslangic_saati;
  dynamic personel;
  dynamic urun;
  dynamic paket;
  List<dynamic>? seanslar;


  @override
  int getSortValue() => int.parse(id);
  Map<String, dynamic> toJson() {
    return {
      'id':id,
      'adisyon_id':adisyon_id,
      'paket_id': paket_id,


      'fiyat': fiyat,

      'personel_id':personel_id,

      'paket':paket,
      'taksitli_tahsilat_id':taksitli_tahsilat_id,
      'senet_id':senet_id,
      'indirim_tutari':indirim_tutari,
      'hediye':hediye,
      'baslangic_tarihi':baslangic_tarihi,
      'seans_araligi':seans_araligi,
      'seanslar':seanslar,
      'seans_baslangic_saati':seans_baslangic_saati,





    };
  }

  factory AdisyonPaket.fromJson(Map<String, dynamic> jsonvar) {

    return AdisyonPaket(
      id:jsonvar["id"].toString(),
      adisyon_id:jsonvar["adisyon_id"].toString(),
      paket_id:jsonvar["paket_id"].toString(),
      seans_araligi:jsonvar["seans_araligi"].toString(),

      fiyat:jsonvar["fiyat"].toString(),

      personel_id:jsonvar["personel_id"].toString(),


      taksitli_tahsilat_id:jsonvar["taksitli_tahsilat_id"].toString(),
      senet_id:jsonvar["senet_id"].toString(),
      indirim_tutari:jsonvar["indirim_tutari"].toString(),
      hediye:jsonvar["hediye"].toString(),
      seanslar:jsonvar["seanslar"],
      personel: jsonvar["personel"],
      urun:jsonvar["urun"],
      baslangic_tarihi: jsonvar["baslangic_tarihi"].toString() ?? '',
      paket: jsonvar["paket"],
      seans_baslangic_saati:jsonvar["seans_baslangic_saati"].toString(),



    );
  }
}