import 'dart:convert';

import 'package:randevu_sistem/Models/katilimcilar.dart';
class Kampanya {
  Kampanya({
    required this.id,

    required this.paket_isim,
    required this.hizmet_adi,
    required this.seans,
    required this.fiyat,
    required this.aktifmi,
    required this.mesaj,
    required this.katilimcilar,


  });

  final String id;

  final String paket_isim;
  final String seans;
  final String hizmet_adi;
  final String fiyat;
  final String aktifmi;
  final String mesaj;
  final List<dynamic> katilimcilar;

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'etkinlik_adi':paket_isim,
      'fiyat':fiyat,
      'aktifmi':aktifmi,
      'mesaj':mesaj,
      'katilimcilar':katilimcilar,
      'himzet_adi':hizmet_adi,
      'paket_isim':paket_isim,
      'seans':seans,

    };
  }

  factory Kampanya.fromJson(Map<String, dynamic> jsonvar) {

    return Kampanya(
      id:jsonvar["id"].toString(),

      paket_isim: jsonvar["paket_isim"].toString(),
      hizmet_adi: jsonvar["hizmet_adi"].toString(),
      seans: jsonvar["seans"].toString(),
      fiyat: jsonvar["fiyat"].toString(),
      aktifmi: jsonvar["aktifmi"].toString(),
      mesaj: jsonvar["mesaj"].toString(),
      katilimcilar: jsonvar["kampanya_katilimcilari"],


    );
  }
}