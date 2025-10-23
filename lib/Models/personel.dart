import 'package:randevu_sistem/Models/personelcihaz.dart';

class Personel implements PersonelCihaz{
  Personel({
    required this.id,
    required this.personel_adi,
    required this.salon_id,
    required this.profil_resmi,
    required this.cinsiyet,
    required this.unvan,
    required this.hizmet_prim_yuzde,
    required this.urun_prim_yuzde,
    required this.paket_prim_yuzde,
    required this.cep_telefon,
    required this.renk,
    required this.maas,
    required this.hesap_turu,
    required this.dahili_no,
    required this.takvim_sirasi,
    required this.takvimde_gorunsun,
    required this.durum

  });

  String id;
  String  personel_adi;
  String  salon_id;
  String  profil_resmi;
  String  cinsiyet;
  String  unvan;
  String durum;
  String  hizmet_prim_yuzde;
  String  urun_prim_yuzde;
  String  paket_prim_yuzde;
  String  cep_telefon;
  String  renk;
  String  hesap_turu;
  String  maas;

  String  takvimde_gorunsun;
  String  dahili_no;
  String  takvim_sirasi;


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personel_adi':personel_adi,
      'aktif':durum,
      'salon_id':salon_id,
      'profil_resmi':profil_resmi,
      'cinsiyet':cinsiyet,
      'unvan':unvan,
      'hizmet_prim_yuzde':hizmet_prim_yuzde,
      'urun_prim_yuzde':urun_prim_yuzde,
      'paket_prim_yuzde':paket_prim_yuzde,
      'cep_telefon':cep_telefon,
      'renk':renk,
      'maas':maas,
      'hesap_turu':hesap_turu,

      'takvimde_gorunsun':takvimde_gorunsun,
      'dahili_no':dahili_no,
      'takvim_sirasi':takvim_sirasi


    };
  }

  factory Personel.fromJson(Map<String, dynamic> jsonvar) {

    return Personel(
      id:jsonvar["id"].toString(),
      hesap_turu:jsonvar["hesap_turu"].toString(),
      salon_id: jsonvar["salon_id"].toString(),
      personel_adi:jsonvar["personel_adi"].toString(),
      profil_resmi:jsonvar["profil_resmi"].toString(),
      cinsiyet:jsonvar["cinsiyet"].toString(),
      unvan:jsonvar["unvan"].toString(),
      hizmet_prim_yuzde:jsonvar["hizmet_prim_yuzde"].toString(),
      urun_prim_yuzde:jsonvar["urun_prim_yuzde"].toString(),
      paket_prim_yuzde:jsonvar["paket_prim_yuzde"].toString(),
      cep_telefon:jsonvar["cep_telefon"].toString(),
      renk:jsonvar["renk"].toString(),
      maas:jsonvar["maas"].toString(),
      takvimde_gorunsun:jsonvar["takvimde_gorunsun"].toString(),
      dahili_no:jsonvar["dahili_no"].toString() ?? "",
      takvim_sirasi: jsonvar['takvim_sirasi'].toString(),
      durum: jsonvar['aktif'].toString(),






    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personel_adi': personel_adi,

    };
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Personel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              personel_adi == other.personel_adi ;

  @override
  int get hashCode => id.hashCode ^ personel_adi.hashCode;
}