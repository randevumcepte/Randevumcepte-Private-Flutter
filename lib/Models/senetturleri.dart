

class SenetTuru {
  SenetTuru({
    required this.id,
    required this.senet_turu,


  });


  final String id;
  final String senet_turu;
  factory SenetTuru.fromJson(Map<String, dynamic> json) {
    return SenetTuru(
      id: json["id"].toString(),
      senet_turu: json["senet_turu"].toString(),



    );
  }

}