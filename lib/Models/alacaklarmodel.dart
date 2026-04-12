class Alacaklar{
  Alacaklar({
    required this.id,
    required this.olusturulma,
    required this.odemetarih,
    required this.tutar,
    required this.musteri
});

  final String id;
  final String olusturulma;
  final String odemetarih;
  final String tutar;
  final String musteri;

  factory Alacaklar.fromJson(Map<String, dynamic> json){
    return Alacaklar(
      id:json["id"].toString(),
      musteri:json["musteri"].toString(),
      odemetarih:json["planlanan_odeme_tarihi"].toString(),
      olusturulma:json["olusturulma"].toString(),
      tutar:json["tutar"].toString()

    );
  }
}