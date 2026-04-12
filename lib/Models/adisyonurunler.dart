
  import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

  import 'adisyonkalemleri.dart';

  class AdisyonUrun implements AdisyonKalemleri {
    AdisyonUrun({
      required this.adisyon_id,
      required this.urun_id,
      required this.adet,
      required this.id,
      required this.fiyat,
      required this.islem_tarihi,
      required this.personel_id,

      required this.taksitli_tahsilat_id,
      required this.senet_id,
      required this.indirim_tutari,
      required this.hediye,
      required this.aciklama,

      this.personel,
      this.urun,




    });
    final String urun_id;
    final String adet;
    final String id;
    final String fiyat;
    final String islem_tarihi;
    final String personel_id;
    final String aciklama;

    final String taksitli_tahsilat_id;
    final String senet_id;
    final String indirim_tutari;
    final String hediye;
    final String adisyon_id;

    dynamic personel;
    dynamic urun;
    @override
    int getSortValue() => int.parse(id);


    Map<String, dynamic> toJson() {
      return {
        'id':id,
        'adisyon_id':adisyon_id,
        'urun_id': urun_id,
        'urun':urun,

        'fiyat': fiyat,

        'personel_id':personel_id,
        'islem_tarihi':islem_tarihi,

        'taksitli_tahsilat_id':taksitli_tahsilat_id,
        'senet_id':senet_id,
        'indirim_tutari':indirim_tutari,
        'hediye':hediye,
        'aciklama':aciklama,



      };
    }

    factory AdisyonUrun.fromJson(Map<String, dynamic> jsonvar) {

      return AdisyonUrun(
        id:jsonvar["id"].toString() ?? '',
        adisyon_id:jsonvar["adisyon_id"].toString() ?? '',
        urun_id:jsonvar["urun_id"].toString() ?? '',
        adet:jsonvar["adet"].toString() ?? '',

        fiyat:jsonvar["fiyat"].toString() ?? '',

        personel_id:jsonvar["personel_id"].toString() ?? '',


        taksitli_tahsilat_id:jsonvar["taksitli_tahsilat_id"].toString() ?? '',
        senet_id:jsonvar["senet_id"].toString() ?? '',
        indirim_tutari:jsonvar["indirim_tutari"].toString() ?? '',
        hediye:jsonvar["hediye"].toString() ?? '',
        aciklama:jsonvar["aciklama"].toString() ?? '',
        personel: jsonvar["personel"],
        urun:jsonvar["urun"],
        islem_tarihi: jsonvar["islem_tarihi"].toString() ?? '',



      );
    }
  }