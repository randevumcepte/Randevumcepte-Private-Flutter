class Seans {
  Seans({

    required this.id,
    required this.tarih,
    required this.telefonno,
    required this.durum,
    required this.musteriname,
    required this.geldimi,
    required this.hizmetler,
    required this.yardimci_personeller,
    required this.olusturulma,
    required this.olusturan,
  });
  final String id;
  final String tarih;
  final String telefonno;
  final String durum;
  final String musteriname;
  final String geldimi;
  final String hizmetler;
  final String yardimci_personeller;
  final String olusturulma;
  final String olusturan;


  factory Seans.fromJson(Map<String, dynamic> json) {
    return Seans(
      tarih: json["tarih"].toString() +' '+ json["saat"].toString(),
      telefonno: json["telefon"].toString(),
      durum: json["durum"].toString(),
      musteriname: json["musteri"].toString(),
      geldimi: json["geldimi"].toString(),
      hizmetler: json["hizmetler"].toString(),
      yardimci_personeller: json["yardimci_personel"].toString(),
      olusturan: json["olusturan"].toString(),
      olusturulma: json["olusturulma"].toString(),
      id: json["id"].toString(),
    );
  }
}