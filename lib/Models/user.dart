
class Kullanici {
  Kullanici({
   required this.id,
   required this.name,
   required this.email,


   required this.profil_resim,

   required this.gsm1,

   required this.cinsiyet,
   required this.sms_gonderimi,
   required this.unvan,
   required this.aktif,
   required this.dogrulama_kodu,
    required this.dogrulama_kodu_kullanildi,
    required this.yetkili_olunan_isletmeler,
    required this.password,





  });

   String id;

   String name;
   String email;
   String profil_resim;
   String gsm1;
   String cinsiyet;
   String sms_gonderimi;
   String unvan;
   String aktif;
   String dogrulama_kodu;
   String dogrulama_kodu_kullanildi;
  final String password;
  final List<dynamic> yetkili_olunan_isletmeler;

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'name':name,
      'email':email,
      'profil_resim':profil_resim,
      'gsm1':gsm1,
      'cinsiyet':cinsiyet,
      'sms_gonderimi':sms_gonderimi,
      'unvan':unvan,
      'aktif':aktif,
      'dogrulama_kodu':dogrulama_kodu,
      'dogrulama_kodu_kullanildi':dogrulama_kodu_kullanildi,
      'salonlar':yetkili_olunan_isletmeler,
      'password':password,

    };
  }

  factory Kullanici.fromJson(Map<String, dynamic> jsonvar) {

    return Kullanici(
      id:jsonvar["id"].toString(),

      name: jsonvar["name"].toString(),
      email: jsonvar["email"].toString(),
      profil_resim: jsonvar["profil_resim"].toString(),
      gsm1: jsonvar["gsm1"].toString(),
      cinsiyet: jsonvar["cinsiyet"].toString(),
      sms_gonderimi: jsonvar["sms_gonderimi"].toString(),
      unvan: jsonvar["unvan"].toString(),
      dogrulama_kodu: jsonvar["dogrulama_kodu"].toString(),
      dogrulama_kodu_kullanildi: jsonvar["dogrulama_kodu_kullanildi"].toString(),
      yetkili_olunan_isletmeler: jsonvar["yetkili_olunan_isletmeler"],
      aktif: jsonvar["aktif"].toString(),
      password: jsonvar["password"].toString(),



    );
  }
}