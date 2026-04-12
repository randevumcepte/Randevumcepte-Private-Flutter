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


  });

  final String id;

  final String paket_adi;



  final String aktif;

  final List<dynamic> hizmetler;

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'paket_adi':paket_adi,

      'hizmetler':hizmetler,

      'aktif':aktif,

    };
  }

  factory Paket.fromJson(Map<String, dynamic> jsonvar) {

    return Paket(
      id:jsonvar["id"].toString(),

      paket_adi: jsonvar["paket_adi"].toString(),


      aktif: jsonvar["aktif"].toString(),
      hizmetler: jsonvar["hizmetler"],


    );
  }
  String getPaketUrunAdi() => paket_adi + ' (Paket)';
  String getId()=>id;
}