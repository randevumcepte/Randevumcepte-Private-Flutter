class SistemBildirimleri {
  final String tarihsaat;
  final String url;
  final String avatar;
  final String aciklama;
  final String randevuid;
  final String id;
  final dynamic arsiv;
  String okundu;



  SistemBildirimleri({

    required this.tarihsaat,
    required this.url,
    required this.avatar,
    required this.aciklama,
    required this.randevuid,
    required this.id,
    required this.okundu,
    required this.arsiv,

  });
  factory SistemBildirimleri.fromJson(Map<String , dynamic> json){
    return SistemBildirimleri(
      tarihsaat:json["tarih_saat"].toString() as String,
      url: json["url"]?.toString() ?? '',
      avatar:json["img_src"].toString() as String,
      id:json["id"].toString() as String,
      aciklama:json["aciklama"].toString() as String,
      randevuid: json["randevu_id"].toString() as String,
      okundu: json["okundu"].toString() as String,
      arsiv: json["arsiv"],

    );
  }
}