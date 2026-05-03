
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
    this.tip,
    this.paketHizmetId,
    this.hizmetler = const [],

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
  final String? tip;
  final String? paketHizmetId;
  final List<dynamic> hizmetler;




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
      tip: jsonvar["tip"]?.toString(),
      paketHizmetId: jsonvar["paketHizmetId"]?.toString(),
      hizmetler: (jsonvar["hizmetler"] is List)
          ? jsonvar["hizmetler"] as List<dynamic>
          : const [],

    );
  }
}
