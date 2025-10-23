class BosDoluSaatler{
  BosDoluSaatler({
    required this.dolu,
    required this.saat,

  });

  final String dolu;
  final String saat;


  factory BosDoluSaatler.fromJson(Map<String, dynamic> json){
    return BosDoluSaatler(
        dolu:json["dolu"].toString(),
        saat:json["saat"].toString(),


    );
  }
}