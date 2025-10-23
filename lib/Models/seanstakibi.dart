
import 'dart:convert';

import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

import 'adisyonkalemleri.dart';

class SeansTakip  {
  SeansTakip({
    required this.id,
    required this.adisyon,
    required this.musteri,

    required this.paket,
    required this.seanslar,
    required this.seansSayisi,
    required this.bekleyenSeansSayisi,
    required this.gelinenSeansSayisi,
    required this.gelinmeyenSeansSayisi,

  });
  final String id;
  dynamic musteri;
  dynamic adisyon;
  final String paket;
  List<dynamic>seanslar;
  final int seansSayisi;
  final int bekleyenSeansSayisi;
  final int gelinenSeansSayisi;
  final int gelinmeyenSeansSayisi;






  factory SeansTakip.fromJson(Map<String, dynamic> jsonvar) {

    return SeansTakip(

      id:jsonvar["id"].toString(),
      musteri:jsonvar["musteri"],
      adisyon:jsonvar["adisyon"],
      paket:jsonvar["paket"].toString(),
      seanslar:jsonvar["seanslar"],
      seansSayisi:jsonvar["toplamSeansSayisi"],
      bekleyenSeansSayisi:jsonvar["bekleyenSeansSayisi"],
      gelinenSeansSayisi:jsonvar["gelinenSeansSayisi"],
      gelinmeyenSeansSayisi:jsonvar["gelinmeyenSeansSayisi"],



    );
  }
}