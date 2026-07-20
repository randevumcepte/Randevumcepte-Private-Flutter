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
    this.kayitli = false,


  });

  final String tarih;

  final String saat;
  final String musteri;
  final String gorusmeyiyapan;
  final String telefon;
  final String durum;
  final String seskaydi;
  final String avatar;

  /// Bu isletmenin (salon) AKTIF musteri_portfoy kaydinda bu numara var mi?
  /// false ise santral raporunda "Musteri Ekle" butonu gosterilir.
  final bool kayitli;

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
      kayitli: json["kayitli"] == true || json["kayitli"]?.toString() == "1",


    );
  }
}