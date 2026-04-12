class PaketHizmetleri {
  PaketHizmetleri({
    required this.seans,
    required this.fiyat,
    required this.hizmet,
    required this.hizmet_id,


  });


  final String seans;
  final String fiyat;
  final dynamic hizmet;
  final String hizmet_id;

  Map<String, dynamic> toJson() {
    return {


      'hizmet_id':hizmet_id,
      'seans':seans,

      'fiyat':fiyat,




    };
  }

  factory PaketHizmetleri.fromJson(Map<String, dynamic> json) {
    return PaketHizmetleri(

      seans: json["seans"].toString(),
      fiyat: json["fiyat"].toString(),
      hizmet: json["hizmet"],
      hizmet_id: json["hizmet_id"].toString(),

    );
  }
}