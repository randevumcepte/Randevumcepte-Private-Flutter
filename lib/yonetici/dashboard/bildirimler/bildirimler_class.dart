class SistemBildirimleri {
  final String tarihsaat;
  final String url;
  final String avatar;
  final String aciklama;
  final String randevuid;
  final String id;
  final dynamic arsiv;
  final String? baslik;
  final String? tip;       // 'wheel_chance', 'appointment_reminder', vs.
  final String? deepLink;
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
    this.baslik,
    this.tip,
    this.deepLink,

  });
  factory SistemBildirimleri.fromJson(Map<String , dynamic> json){
    String? _opt(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return (s.isEmpty || s == 'null') ? null : s;
    }
    return SistemBildirimleri(
      tarihsaat:json["tarih_saat"].toString() as String,
      url: json["url"]?.toString() ?? '',
      avatar:json["img_src"].toString() as String,
      id:json["id"].toString() as String,
      aciklama:json["aciklama"].toString() as String,
      randevuid: json["randevu_id"].toString() as String,
      okundu: json["okundu"].toString() as String,
      arsiv: json["arsiv"],
      baslik: _opt(json["baslik"]),
      tip: _opt(json["tip"]),
      deepLink: _opt(json["deep_link"]),

    );
  }
}