class OnGorusme {
  OnGorusme({
    required this.id,
    required this.tarih,
    required this.durum,
    required this.paket_id,
    required this.urun_id,
    required this.ad_soyad,
    required this.cep_telefon,
    required this.email,
    required this.adres,
    required this.aciklama,
    required this.musteri_tipi,
    required this.meslek,
    required this.satisyapilmadi_not,
    required this.musteri,
    required this.personel,
    required this.urun,
    required this.paket,
    required this.saat,
    required this.cinsiyet,
    required this.il_id,
  });

  final String id;
  final String tarih;
  final String durum;
  final String paket_id;
  final String urun_id;
  final String ad_soyad;
  final String cep_telefon;
  final String email;
  final String adres;
  final String aciklama;
  final String musteri_tipi;
  final String meslek;
  final String satisyapilmadi_not;
  final String saat;
  final Map<String, dynamic> musteri;
  final Map<String, dynamic> personel;
  final Map<String, dynamic> urun;
  final Map<String, dynamic> paket;
  final String cinsiyet;
  final String il_id;

  factory OnGorusme.fromJson(Map<String, dynamic> json) {
    return OnGorusme(
      id: json["id"]?.toString() ?? "",
      tarih: json["hatirlatma_tarihi"]?.toString() ?? "",
      durum: json["durum"]?.toString() ?? "",
      saat: json["on_gorusme_saati"]?.toString() ?? "",
      ad_soyad: json["ad_soyad"]?.toString() ?? "",
      cep_telefon: json["cep_telefon"]?.toString() ?? "",
      email: json["email"]?.toString() ?? "",
      adres: json["adres"]?.toString() ?? "",
      aciklama: json["aciklama"]?.toString() ?? "",
      musteri_tipi: json["musteri_tipi"]?.toString() ?? "",
      meslek: json["meslek"]?.toString() ?? "",
      satisyapilmadi_not: json["satisyapilmadi_not"]?.toString() ?? "",
      musteri: json["musteri"] is Map ? Map<String, dynamic>.from(json["musteri"]) : {},
      personel: json["personel"] is Map ? Map<String, dynamic>.from(json["personel"]) : {},
      urun: json["urun"] is Map ? Map<String, dynamic>.from(json["urun"]) : {},
      paket: json["paket"] is Map ? Map<String, dynamic>.from(json["paket"]) : {},
      urun_id: json["urun_id"]?.toString() ?? "",
      paket_id: json["paket_id"]?.toString() ?? "",
      cinsiyet: json["cinsiyet"]?.toString() ?? "",
      il_id: json["il_id"]?.toString() ?? "",
    );
  }
}