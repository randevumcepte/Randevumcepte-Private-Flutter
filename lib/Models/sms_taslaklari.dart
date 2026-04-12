class SmsTaslak {
  SmsTaslak({
    required this.id,
    required this.baslik,
    required this.icerik,

  });

  final String id;
  final String baslik;
  final String icerik;



  factory SmsTaslak.fromJson(Map<String, dynamic> json) {
    return SmsTaslak(
      id: json["id"].toString() +' '+ json["saat"].toString(),
      baslik: json["baslik"].toString(),
      icerik: json["taslak_icerik"].toString(),

    );
  }
}