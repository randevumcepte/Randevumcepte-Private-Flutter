import 'package:randevu_sistem/Models/personelcihaz.dart';

class Cihaz implements PersonelCihaz {
  Cihaz({
    required this.id,
    required this.cihaz_adi,
    required this.durum,
    required this.aciklama,
    required this.aktifmi,




  });


  final String id;
  final String cihaz_adi;
  final String durum;
  final String aciklama;
  final String aktifmi;



  /*Map<String, dynamic> toJson() {
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
  }*/
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cihaz_adi': cihaz_adi,

    };
  }
  factory Cihaz.fromJson(Map<String, dynamic> jsonvar) {

    return Cihaz(
      id: jsonvar["id"].toString(),
      cihaz_adi: jsonvar["cihaz_adi"].toString(),
      durum: jsonvar["durum"].toString(),
      aciklama: jsonvar["aciklama"].toString(),
      aktifmi: jsonvar["aktifmi"].toString(),
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Cihaz &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              cihaz_adi == other.cihaz_adi ;

  @override
  int get hashCode => id.hashCode ^ cihaz_adi.hashCode;
}