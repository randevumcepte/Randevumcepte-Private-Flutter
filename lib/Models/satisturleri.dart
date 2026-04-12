class SatisTuru {
  SatisTuru({

    required this.id,
    required this.satisturu,


  });
  final String id;
  final String satisturu;



  factory SatisTuru.fromJson(Map<String, dynamic> json) {
    return SatisTuru(
      id: json["id"].toString(),
      satisturu: json["satisturu"].toString(),


    );
  }
}