import 'dart:convert';

import 'package:randevu_sistem/Models/katilimcilar.dart';
import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

import 'ongorusmenedeni.dart';

class Paket implements OnGorusmeNedeni,TahsilatKalemleri{
  Paket({
    required this.id,

    required this.paket_adi,
    required this.aktif,

    required this.hizmetler,
    this.miktar = '',
    this.fiyat = '',
    this.sure = '',


  });

  final String id;

  final String paket_adi;



  final String aktif;

  final List<dynamic> hizmetler;

  final String miktar;
  final String fiyat;
  final String sure;

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'paket_adi':paket_adi,

      'hizmetler':hizmetler,

      'aktif':aktif,

      'miktar':miktar,

      'fiyat':fiyat,

      'sure':sure,

    };
  }

  factory Paket.fromJson(Map<String, dynamic> jsonvar) {

    return Paket(
      id:jsonvar["id"].toString(),

      paket_adi: jsonvar["paket_adi"].toString(),


      aktif: jsonvar["aktif"].toString(),
      hizmetler: jsonvar["hizmetler"],

      miktar: (jsonvar["miktar"] ?? '').toString(),
      fiyat: (jsonvar["fiyat"] ?? '').toString(),
      sure: (jsonvar["sure"] ?? '').toString(),


    );
  }
  String getPaketUrunAdi() => paket_adi + ' (Paket)';
  String getId()=>id;
}