class Randevu {
  Randevu({

    required this.id,
    required this.user_id,
    required this.tarih,

    required this.telefonno,
    required this.durum,
    required this.musteriname,
    required this.geldimi,
    required this.hizmetler,
    required this.yardimci_personeller,
    required this.olusturulma,
    required this.olusturan,

    required this.musteri,
    required this.toplam,
    required this.musterinotu,
    required this.personelnotu,
    required this.tahsilat_eklendi,
  });
  final String id;
  final String tarih;
  final String telefonno;
  final String durum;
  final String musteriname;
  final String geldimi;
  final dynamic hizmetler;
  final String tahsilat_eklendi;
  final String yardimci_personeller;
  final String olusturulma;
  final dynamic olusturan;

  final String user_id;
  final dynamic musteri;
  final String toplam;
  final String musterinotu;
  final String personelnotu;


  factory Randevu.fromJson(Map<String, dynamic> json) {
    return Randevu(
      tarih: json["tarih"].toString() +' '+ json["saat"].toString(),
      user_id: json["user_id"].toString(),
      musteri : json["users"],
      telefonno: json["telefon"].toString(),
      durum: json["durum"].toString(),
      musteriname: json["users"]['name'].toString(),
      geldimi: json["randevuya_geldi"].toString(),
      hizmetler: json["hizmetler"],
      yardimci_personeller: json["yardimci_personel"].toString(),
      olusturan: json["olusturan_personel"] ?? json["olusturan_musteri"],
      olusturulma: json["olusturulma"].toString(),
      id: json["id"].toString(),
      toplam: json["toplam"].toString(),
      musterinotu : json["musteri_notu"].toString(),
      personelnotu : json["personel_notu"].toString(),
      tahsilat_eklendi: json["tahsilat_eklendi"].toString(),
    );
  }
}