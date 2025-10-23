class Tahsilat {
  Tahsilat({

    required this.id,
    required this.tutar,
    required this.tarih,
    required this.notlar,
    required this.odeme_yontemi_id,
    required this.musteri,
    required this.olusturan,
  });
  final String id;
  final String tutar;
  final String tarih;
  final String notlar;
  final String odeme_yontemi_id;
  final Map<String, dynamic> musteri;
  final Map<String, dynamic> olusturan;

  factory Tahsilat.fromJson(Map<String, dynamic> json) {
    return Tahsilat(
      id: json["id"].toString(),
      tutar: json["tutar"].toString(),
      tarih: json["odeme_tarihi"].toString(),
      notlar: json["notlar"].toString(),
      odeme_yontemi_id:json["odeme_yontemi_id"].toString(),
      musteri:json["musteri"],
      olusturan:json["olusturan"],


    );
  }
}