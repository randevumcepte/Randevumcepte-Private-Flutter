class Cdr {
  Cdr({
    required this.tarih,
    required this.saat,
    required this.musteri,
    required this.gorusmeyiyapan,
    required this.telefon,
    required this.durum,
    required this.seskaydi,
    required this.avatar,


  });

  final String tarih;

  final String saat;
  final String musteri;
  final String gorusmeyiyapan;
  final String telefon;
  final String durum;
  final String seskaydi;
  final String avatar;

  factory Cdr.fromJson(Map<String, dynamic> json) {
    return Cdr(
      tarih: json["tarih"].toString(),
      saat: json["saat"],
      musteri: json["musteri"],
      gorusmeyiyapan: json["gorusmeyiyapan"].toString(),
      telefon: json["telefon"].toString(),
      durum: json["durum"].toString(),
      seskaydi: json["seskaydi"].toString(),
      avatar: json["avatar"].toString(),


    );
  }
}