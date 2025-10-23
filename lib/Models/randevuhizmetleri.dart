import 'package:randevu_sistem/Models/personel.dart';

class RandevuHizmet {
  RandevuHizmet({

    required this.hizmetler,
    required this.hizmet_id,
    required this.personel_id,
    required this.personeller,
    required this.oda_id,
    required this.oda,
    required this.cihaz_id,
    required this.cihaz,
    required this.fiyat,
    required this.sure_dk,
    required this.saat,
    required this.saat_bitis,
    required this.yardimci_personel,
    required this.birusttekiileaynisaat,




  });


  dynamic hizmetler;
  late  String hizmet_id;
  late  String personel_id;
  dynamic personeller;
  late  String oda_id;
  dynamic oda;
  late  String cihaz_id;
  dynamic cihaz;
  String fiyat;
  String sure_dk;
  String saat;
  String saat_bitis;
  String yardimci_personel;
  String birusttekiileaynisaat;




  Map<String, dynamic> toJson() {
    return {


      'hizmet_id':hizmet_id,
      'personel_id':personel_id,
      'oda_id':oda_id,
      'cihaz_id':cihaz_id,
      'yardimci_personel':yardimci_personel,
      'sure_dk':sure_dk,
      'fiyat':fiyat,
      'birlestir':birusttekiileaynisaat,



    };
  }

  factory RandevuHizmet.fromJson(Map<String, dynamic> jsonvar) {

    return RandevuHizmet(

        hizmet_id: jsonvar["hizmet_id"].toString(),
        hizmetler: jsonvar["hizmetler"],
        personel_id: jsonvar["personel_id"].toString(),
        personeller: jsonvar["personeller"],
        fiyat: jsonvar["fiyat"].toString(),
        sure_dk: jsonvar["sure_dk"].toString(),

        oda_id: jsonvar["oda_id"].toString(),
        oda: jsonvar["oda"],

        cihaz_id: jsonvar["cihaz_id"].toString(),
        cihaz: jsonvar["cihaz"],
        saat: jsonvar["saat"].toString(),
        saat_bitis: jsonvar["saat_bitis"].toString(),
        yardimci_personel :jsonvar["yardimci_personel"].toString(),
        birusttekiileaynisaat:''





    );
  }
}