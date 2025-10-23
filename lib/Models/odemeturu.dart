

class OdemeTuru {
  OdemeTuru({
    required this.id,
    required this.odeme_turu,


  });


  final String id;
  final String odeme_turu;
  factory OdemeTuru.fromJson(Map<String, dynamic> json) {
    return OdemeTuru(
        id: json["id"].toString(),
        odeme_turu: json["odeme_turu"].toString(),



    );
  }

}