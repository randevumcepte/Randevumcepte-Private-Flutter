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
    required this.salonAdi,
    required this.gorevIptalEdilebilir,
    this.on_gorusme_id = '',
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
  final String salonAdi;

  // Hatirlatma (asistan arama) gorevinin iptal edilebilir olup olmadigi.
  // Web (StoreAdminController e_asistan) ile ayni kosul.
  final bool gorevIptalEdilebilir;

  // Dolu ise randevu bir on gorusmeden uretilmistir (on_gorusme_id FK).
  final String on_gorusme_id;

  // 1 / "1" / true -> true; null / 0 / "0" -> false
  static bool _isBir(dynamic v) => v == 1 || v == "1" || v == true;

  factory Randevu.fromJson(Map<String, dynamic> json) {
    final aramaYapildi = _isBir(json["hatirlatma_aramasi_yapildi"]);
    final ulasilamadi = _isBir(json["hatirlatma_ulasilamadi"]);
    final gorevIptal = _isBir(json["hatirlatma_gorevi_iptal"]);
    final tekrarArandi = _isBir(json["tekrar_arandi"]);
    // Web kosulu: gorev iptal edilmemis + (arama yapildi&ulasilamadi VEYA arama
    // hic yapilmamis) + tekrar aranmamis.
    final gorevIptalEdilebilir = !gorevIptal &&
        ((aramaYapildi && ulasilamadi) || !aramaYapildi) &&
        !tekrarArandi;

    return Randevu(
      gorevIptalEdilebilir: gorevIptalEdilebilir,
      on_gorusme_id: json["on_gorusme_id"] == null ? '' : json["on_gorusme_id"].toString(),
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
      salonAdi: (json["salonlar"] is Map && json["salonlar"]["salon_adi"] != null)
          ? json["salonlar"]["salon_adi"].toString()
          : '',
    );
  }
}