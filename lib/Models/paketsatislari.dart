class PaketSatisi {
  PaketSatisi({
    required this.id,
    required this.musteri,
    required this.paket,
    required this.fiyat,
    required this.satan,
    required this.tarih

  });
  final String id;
  final String musteri;
  final String paket;
  final String fiyat;
  final String satan;
  final String tarih;



  factory PaketSatisi.fromJson(Map<String, dynamic> json) {
    return PaketSatisi(
      musteri: json["musteri"].toString(),
      paket: json["paket_adi"].toString(),
      fiyat: json["fiyat"].toString(),
      satan: json["satan"].toString(),
      tarih: json["tarih"].toString(),
      id: json["id"].toString(),

    );
  }
}