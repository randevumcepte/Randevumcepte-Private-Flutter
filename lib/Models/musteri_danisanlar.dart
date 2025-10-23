class MusteriDanisan {
  MusteriDanisan(  {
    required this.id,
    required this.name,
    required this.cep_telefon,
    required this.randevu_sayisi,
    required this.son_randevu_tarihi,
    required this.cinsiyet,
    required this.eposta,
    required this.dogum_tarihi,
    required this.ozel_notlar,
    required this.baslangic_kg,
    required this.baslangic_gogus,
    required this.baslangic_gobek,
    required this.baslangic_kalca,
    required this.baslangic_basen,
    required this.baslangic_bel,
    required this.baslangic_sirt,
    required this.baslangic_diger,
    required this.kil_yapisi,
    required this.ten_rengi,
    required this.adres,
    required this.hemofili_hastaligi_var,
    required this.seker_hastaligi_var,
    required this.hamile,
    required this.yakin_zamanda_ameliyat_gecirildi,
    required this.alerji_var,
    required this.alkol_alimi_yapildi,
    required this.regl_doneminde,
    required this.deri_yumusak_doku_hastaligi_var,
    required this.surekli_kullanilan_ilac_Var,
    required this.surekli_kullanilan_ilac_aciklama,
    required this.kemoterapi_goruyor,
    required this.daha_once_uygulama_yaptirildi,
    required this.daha_once_yaptirilan_uygulama_aciklama,
    required this.ek_saglik_sorunu,
    required this.cilt_tipi,
    required this.tc_kimlik_no,
    required this.musteri_tipi,
    required this.meslek,
    required this.bildirim_kimligi,
    required this.kayit_tarihi,
    required this.referans,
    required this.email,
    required this.il,
    required this.il_id,
    required this.musteri_olunan_salonlar,
    required this.profil_resim,

  });

  final String id;
  final String name;
  final String cep_telefon;
  final String randevu_sayisi;
  final String son_randevu_tarihi;
  final String cinsiyet;
  final String eposta;
  final String dogum_tarihi;
  final String ozel_notlar;
  final String baslangic_kg;
  final String baslangic_gogus;
  final String baslangic_gobek;
  final String baslangic_kalca;
  final String baslangic_basen;
  final String baslangic_bel;
  final String baslangic_sirt;
  final String baslangic_diger;
  final String kil_yapisi;
  final String ten_rengi;
  final String adres;
  final String hemofili_hastaligi_var;
  final String seker_hastaligi_var;
  final String hamile;
  final String yakin_zamanda_ameliyat_gecirildi;
  final String alerji_var;
  final String alkol_alimi_yapildi;
  final String regl_doneminde;
  final String deri_yumusak_doku_hastaligi_var;
  final String surekli_kullanilan_ilac_Var;
  final String surekli_kullanilan_ilac_aciklama;
  final String kemoterapi_goruyor;
  final String daha_once_uygulama_yaptirildi;
  final String daha_once_yaptirilan_uygulama_aciklama;
  final String ek_saglik_sorunu;
  final String cilt_tipi;
  final String tc_kimlik_no;
  final String musteri_tipi;
  final String meslek;
  final String bildirim_kimligi;
  final String kayit_tarihi;
  final String referans;
  final String email;
  final dynamic il;
  final String il_id;
  final List<dynamic>? musteri_olunan_salonlar;
  final String? profil_resim;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cep_telefon':cep_telefon,
      'email':email,


    };
  }
  factory MusteriDanisan.fromJson(Map<String, dynamic> json) {
    return MusteriDanisan(
      id: json["id"].toString(),
      il_id:json["il_id"].toString(),
      name: json["name"].toString(),
      cep_telefon: json["cep_telefon"].toString(),
      randevu_sayisi: json["randevu_sayisi"].toString(),
      son_randevu_tarihi : json["son_randevu_tarihi"].toString(),
      cinsiyet:json["cinsiyet"].toString(),
      ozel_notlar: json["ozel_notlar"].toString(),
      eposta: json["email"].toString(),

      dogum_tarihi: json["dogum_tarihi"].toString(),
        baslangic_kg : json["baslangic_kg"].toString(),
        baslangic_gogus : json["baslangic_gogus"].toString(),
        baslangic_gobek : json["baslangic_gobek"].toString(),
        baslangic_kalca : json["baslangic_kalca"].toString(),
        baslangic_basen : json["baslangic_basen"].toString(),
        baslangic_bel : json["baslangic_bel"].toString(),
        baslangic_sirt : json["baslangic_sirt"].toString(),
        baslangic_diger : json["baslangic_diger"].toString(),
        kil_yapisi :json["kil_yapisi"].toString(),
        ten_rengi : json["ten_rengi"].toString(),
        adres : json["adres"].toString(),
        hemofili_hastaligi_var : json["hemofili_hastaligi_var"].toString(),
        seker_hastaligi_var : json["seker_hastaligi_var"].toString(),
        hamile : json["hamile"].toString(),
        yakin_zamanda_ameliyat_gecirildi : json["yakin_zamanda_ameliyat_gecirildi"].toString(),
        alerji_var : json["alerji_var"].toString(),
        alkol_alimi_yapildi : json["alkol_alimi_yapildi"].toString(),
        regl_doneminde : json["regl_doneminde"].toString(),
        deri_yumusak_doku_hastaligi_var : json["deri_yumusak_doku_hastaligi_var"].toString(),
        surekli_kullanilan_ilac_Var : json["surekli_kullanilan_ilac_Var"].toString(),
        surekli_kullanilan_ilac_aciklama : json["surekli_kullanilan_ilac_aciklama"].toString(),
        kemoterapi_goruyor : json["kemoterapi_goruyor"].toString(),
        daha_once_uygulama_yaptirildi : json["daha_once_uygulama_yaptirildi"].toString(),
        daha_once_yaptirilan_uygulama_aciklama : json["daha_once_yaptirilan_uygulama_aciklama"].toString(),
        ek_saglik_sorunu : json["ek_saglik_sorunu"].toString(),
        cilt_tipi : json["cilt_tipi"].toString(),
        tc_kimlik_no : json["tc_kimlik_no"].toString(),
        musteri_tipi : json["musteri_tipi"].toString(),
        meslek : json["meslek"].toString(),
        bildirim_kimligi : json["bildirim_kimligi"].toString(),
        kayit_tarihi:json['kayit_tarihi'].toString(),
      referans:json['referans'].toString(),
      email:json['email'].toString(),
      il:json["il"].toString(),
      musteri_olunan_salonlar: json['salonlar'] != null ? List<dynamic>.from(json['salonlar']) : null,
      profil_resim: json['profil_resim']?.toString(),


    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MusteriDanisan &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              cep_telefon == other.cep_telefon;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}