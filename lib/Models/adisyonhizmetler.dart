
import 'dart:convert';

import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

import 'adisyonkalemleri.dart';

class AdisyonHizmet implements AdisyonKalemleri {
  
  AdisyonHizmet({
    required this.id,
    required this.adisyon_id,
    required this.hizmet_id,
    required this.islem_tarihi,
    required this.islem_saati,
    required this.sure,
    required this.fiyat,
    required this.geldi,
    required this.personel_id,
    required this.cihaz_id,
    required this.oda_id,
    required this.dogrulama_kodu,
    required this.taksitli_tahsilat_id,
    required this.senet_id,
    required this.indirim_tutari,
    required this.hediye,
    this.oda,
    this.personel,
    this.cihaz,
    this.hizmet,



  });
  final String id;
  final String hizmet_id;
  final String islem_tarihi;
  final String islem_saati;
  final String sure;
  final String fiyat;
  final String geldi;
  final String personel_id;
  final String cihaz_id;
  final String oda_id;
  final String dogrulama_kodu;
  final String taksitli_tahsilat_id;
  final String senet_id;
  final String indirim_tutari;
  final String hediye;
  final String adisyon_id;
  dynamic oda;
  dynamic personel;
  dynamic cihaz;
  dynamic hizmet;
  @override
  int getSortValue() => int.parse(id);

  Map<String, dynamic> toJson() {
    return {
      'id':id,
      'adisyon_id':adisyon_id,
      'hizmet_id': hizmet_id,
      'islem_tarihi': islem_tarihi,
      'islem_saati':islem_saati,
      'sure':sure,
      'fiyat': fiyat,
      'geldi': geldi,
      'personel_id':personel_id,
      'cihaz_id':cihaz_id,
      'oda_id':oda_id,
      'dogrulama_kodu':dogrulama_kodu,
      'taksitli_tahsilat_id':taksitli_tahsilat_id,
      'senet_id':senet_id,
      'indirim_tutari':indirim_tutari,
      'hediye':hediye,
      'hizmet':hizmet,
      'cihaz':cihaz,
      'oda':oda,
      'personel':personel,



    };
  }

  factory AdisyonHizmet.fromJson(Map<String, dynamic> jsonvar) {

    return AdisyonHizmet(
      id:jsonvar["id"].toString(),
      adisyon_id:jsonvar["adisyon_id"].toString(),
        hizmet_id:jsonvar["hizmet_id"].toString(),
        islem_tarihi:jsonvar["islem_tarihi"].toString(),
        islem_saati:jsonvar["islem_saati"].toString(),
        sure:jsonvar["sure"].toString(),
        fiyat:jsonvar["fiyat"].toString(),
        geldi:jsonvar["geldi"].toString(),
        personel_id:jsonvar["personel_id"].toString(),
        cihaz_id:jsonvar["cihaz_id"].toString(),
        oda_id:jsonvar["oda_id"].toString(),
        dogrulama_kodu:jsonvar["dogrulama_kodu"].toString(),
        taksitli_tahsilat_id:jsonvar["taksitli_tahsilat_id"].toString(),
        senet_id:jsonvar["senet_id"].toString(),
        indirim_tutari:jsonvar["indirim_tutari"].toString(),
        hediye:jsonvar["hediye"].toString(),
      personel: jsonvar["personel"],
      oda:jsonvar["oda"],
      cihaz: jsonvar["cihaz"],
      hizmet:jsonvar["hizmet"],




    );
  }
}