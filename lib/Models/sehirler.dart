class Sehir {
  Sehir({

    required this.id,
    required this.sehir,

  });
  final String id;
  final String sehir;



  factory Sehir.fromJson(Map<String, dynamic> json) {
    return Sehir(
      id: json["id"].toString(),
      sehir: json["il_adi"].toString(),

    );
  }
}