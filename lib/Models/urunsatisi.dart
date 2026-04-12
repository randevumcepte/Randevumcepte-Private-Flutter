class UrunSatisi {
  UrunSatisi({
    required this.id,
    required this.musteri,
    required this.urun,
    required this.fiyat,
    required this.satan,
    required this.tarih

  });
  final String id;
  final String musteri;
  final String urun;
  final String fiyat;
  final String satan;
  final String tarih;



  factory UrunSatisi.fromJson(Map<String, dynamic> json) {
    return UrunSatisi(
      musteri: json["musteri"].toString(),
      urun: json["urun_adi"].toString(),
      fiyat: json["fiyat"].toString(),
      satan: json["satan"].toString(),
      tarih: json["tarih"].toString(),
      id: json["id"].toString(),

    );
  }
}