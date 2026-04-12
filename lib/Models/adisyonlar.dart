class Adisyon {
  Adisyon({

    required this.id,
    required this.hizmet_veren,

    required this.urun_satan,
    required this.paket_satan,
    required this.planlanan_alacak_tarihi,
    required this.hakedis,
    required this.hizmet_hakedis,
    required this.urun_hakedis,
    required this.paket_hakedis,
    required this.hizmet_hakedis_numeric,
    required this.urun_hakedis_numeric,
    required this.paket_hakedis_numeric,
    required this.hakedis_numeric,
    required this.acilis_tarihi,
    required this.musteri,
    required this.user_id,
    required this.satis_turu,
    required this.icerik,
    required this.indirim,
    required this.toplam,
    required this.hizmet_toplam_numeric,
    required this.urun_toplam_numeric,
    required this.paket_toplam_numeric,
    required this.toplam_numeric,
    required this.odenen,
    required this.odenen_numeric,
    required this.kalan_tutar,
    required this.kalan_tutar_numeric,
    required this.indirim_tutari_toplam_numeric,
    required this.icerikKisaltilmis


  });
  final String id;
  final String urun_satan;
  final String hizmet_veren;
  final String paket_satan;
  final String planlanan_alacak_tarihi;
  final String hakedis;
  final String hizmet_hakedis;
  final String urun_hakedis;
  final String paket_hakedis;
  final String hizmet_hakedis_numeric;
  final String urun_hakedis_numeric;
  final String paket_hakedis_numeric;
  final String hakedis_numeric;
  final String acilis_tarihi;
  final String musteri;
  final String satis_turu;
  final String icerik;
  final String indirim;
  final String toplam;
  final String hizmet_toplam_numeric;
  final String urun_toplam_numeric;
  final String paket_toplam_numeric;
  final String toplam_numeric;
  final String odenen;
  final String odenen_numeric;
  final String kalan_tutar;
  final String kalan_tutar_numeric;
  final String indirim_tutari_toplam_numeric;
  final String user_id;
  final String icerikKisaltilmis;



  factory Adisyon.fromJson(Map<String, dynamic> json) {
    return Adisyon(
        id: json["id"].toString(),
        urun_satan:json["urun_satan"].toString(),
        paket_satan:json["paket_satan"].toString(),
        planlanan_alacak_tarihi:json["planlanan_alacak_tarihi"].toString(),
        hakedis:json["hakedis"].toString(),
        hizmet_hakedis:json["hizmet_hakedis"].toString(),
        urun_hakedis:json["urun_hakedis"].toString(),
        paket_hakedis:json["paket_hakedis"].toString(),
        hizmet_hakedis_numeric:json["hizmet_hakedis_numeric"].toString(),
        urun_hakedis_numeric:json["urun_hakedis_numeric"].toString(),
        paket_hakedis_numeric:json["paket_hakedis_numeric"].toString(),
        hakedis_numeric:json["hakedis_numeric"].toString(),
        acilis_tarihi:json["acilis_tarihi"].toString(),
        musteri:json["musteri"].toString(),
        satis_turu:json["satis_turu"].toString(),
        icerik:json["icerik"].toString(),
      icerikKisaltilmis:json["icerikKisaltilmis"].toString(),
        indirim:json["indirim"].toString(),
        toplam:json["toplam"].toString(),
        hizmet_toplam_numeric:json["hizmet_toplam_numeric"].toString(),
        urun_toplam_numeric:json["urun_toplam_numeric"].toString(),
        paket_toplam_numeric:json["paket_toplam_numeric"].toString(),
        toplam_numeric:json["toplam_numeric"].toString(),
        odenen:json["odenen"].toString(),
        odenen_numeric:json["odenen_numeric"].toString(),
        kalan_tutar:json["kalan_tutar"].toString(),
        kalan_tutar_numeric:json["kalan_tutar_numeric"].toString(),
        indirim_tutari_toplam_numeric:json["indirim_tutari_toplam_numeric"].toString(),
      hizmet_veren:json["hizmet_veren"].toString(),
      user_id : json["user_id"].toString(),


    );
  }
}