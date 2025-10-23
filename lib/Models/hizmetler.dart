import 'ongorusmenedeni.dart';

class Hizmet implements OnGorusmeNedeni{
  Hizmet({
    required this.id,
    required this.hizmet_id,
    required this.hizmet_adi,
    required this.hizmet_kategori,
    required this.personel,
    required this.cihaz,
    required this.fiyat,
    required this.sure_dk,
  });
  String id;
  String hizmet_adi;
  dynamic hizmet_kategori;
  String personel;
  String fiyat;
  String cihaz;
  String sure_dk;
  String hizmet_id;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hizmet_adi':hizmet_adi,
      'hizmet_kategori':hizmet_kategori,
      'personel':personel,
      'sure_dk':sure_dk,
      'fiyat':fiyat,
      'cihaz':cihaz,
      'hizmet_id':hizmet_id,

    };
  }

  factory Hizmet.fromJson(Map<String, dynamic> jsonvar) {

    return Hizmet(
      id: jsonvar["id"].toString(),
      hizmet_adi: jsonvar["hizmet_adi"].toString(),
      hizmet_kategori: jsonvar["hizmet_kategorisi"],
      personel:  jsonvar["personel"].toString(),
      sure_dk:  jsonvar["sure_dk"].toString(),
      fiyat:  jsonvar["fiyat"].toString(),
      cihaz:jsonvar["cihaz"].toString(),
      hizmet_id: jsonvar["hizmet_id"].toString(),
    );
  }
  String getPaketUrunAdi() => hizmet_adi + ' (Hizmet)';
  String getId()=>id;
}
