import 'dart:convert';

import 'package:randevu_sistem/Models/katilimcilar.dart';
class Etkinlik {
  Etkinlik({
    required this.id,
    required this.tarih_saat,
    required this.etkinlik_adi,
    required this.fiyat,
    required this.aktifmi,
    required this.mesaj,
    required this.katilimcilar,


  });

  final String id;
  final String tarih_saat;
  final String etkinlik_adi;
  final String fiyat;
  final String aktifmi;
  final String mesaj;
  final List<dynamic> katilimcilar;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tarih_saat': tarih_saat,
      'etkinlik_adi':etkinlik_adi,
      'fiyat':fiyat,
      'aktifmi':aktifmi,
      'mesaj':mesaj,
      'katilimcilar':katilimcilar,
    };
  }

  factory Etkinlik.fromJson(Map<String, dynamic> jsonvar) {

    return Etkinlik(
      id:jsonvar["id"].toString(),
      tarih_saat: jsonvar["tarih_saat"].toString(),
      etkinlik_adi: jsonvar["etkinlik_adi"].toString(),
      fiyat: jsonvar["fiyat"].toString(),
      aktifmi: jsonvar["aktifmi"].toString(),
      mesaj: jsonvar["mesaj"].toString(),
      katilimcilar: jsonvar["katilimcilar"],


    );
  }
}