

class TakvimTuru {
  TakvimTuru({
    required this.id,
    required this.takvim_turu,


  });


  final String id;
  final String takvim_turu;
  factory TakvimTuru.fromJson(Map<String, dynamic> json) {
    return TakvimTuru(
      id: json["id"].toString(),
      takvim_turu: json["takvim_turu"].toString(),



    );
  }

}