import 'package:randevu_sistem/Models/adisyonkalemleri.dart';

class TaksitVade implements AdisyonKalemleri {
  TaksitVade({
    required this.id,
    required this.taksitli_tahsilat_id,
    required this.vade_tarih,
    required this.tutar,
    required this.odendi,
    required this.notlar,
    required this.odeme_yontemi_id,
    required this.dogrulama_kodu,
  });
  final String id;
  final String taksitli_tahsilat_id;
  final String vade_tarih;
  final String tutar;
  final String notlar;
  final String odendi;
  final String odeme_yontemi_id;
  final String dogrulama_kodu;
  @override
  int getSortValue() => int.parse(id);
  Map<String,dynamic >toJson() {
    return {
      'id': id,
      'taksitli_tahsilat_id': taksitli_tahsilat_id,
      'vade_tarih': vade_tarih,
      'tutar':tutar,
      'notlar':notlar,
      'odendi':odendi,
      'odeme_yontemi_id':odeme_yontemi_id,
      'dogurlama_kodu':dogrulama_kodu,
    };
  }
  factory TaksitVade.fromJson(Map<String, dynamic> json) {
    return TaksitVade(

      id: json["id"].toString(),
      taksitli_tahsilat_id: json["taksitli_tahsilat_id"].toString(),
      vade_tarih: json["vade_tarih"].toString(),
      tutar:json["tutar"].toString(),
      notlar:json["notlar"].toString(),
      odendi:json["odendi"].toString(),
        odeme_yontemi_id: json["odeme_yontemi_id"].toString(),
        dogrulama_kodu: json["dogrulama_kodu"].toString(),


    );
  }
}