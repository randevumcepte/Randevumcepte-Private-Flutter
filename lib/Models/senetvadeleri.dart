import 'adisyonkalemleri.dart';

class SenetVade implements AdisyonKalemleri{
  SenetVade({
    required this.id,
    required this.senet_id,
    required this.vade_tarih,
    required this.tutar,
    required this.odendi,
    required this.notlar,
    required this.odeme_yontemi_id,
    required this.dogrulama_kodu,
  });
  final String id;
  final String senet_id;
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
      'senet_id': senet_id,
      'vade_tarih': vade_tarih,
      'tutar':tutar,
      'notlar':notlar,
      'odendi':odendi,
      'odeme_yontemi_id':odeme_yontemi_id,
      'dogurlama_kodu':dogrulama_kodu,
    };
  }
  factory SenetVade.fromJson(Map<String, dynamic> json) {
    return SenetVade(

      id: json["id"].toString(),
      senet_id: json["senet_id"].toString(),
      vade_tarih: json["vade_tarih"].toString(),
      tutar:json["tutar"].toString(),
      notlar:json["notlar"].toString(),
      odendi:json["odendi"].toString(),
      odeme_yontemi_id: json["odeme_yontemi_id"].toString(),
      dogrulama_kodu: json["dogrulama_kodu"].toString(),


    );
  }
}