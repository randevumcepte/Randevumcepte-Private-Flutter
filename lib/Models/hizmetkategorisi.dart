class HizmetKategorisi {
  HizmetKategorisi({
    required this.id,
    required this.hizmet_kategori_adi,




  });


  String id;

  dynamic hizmet_kategori_adi;




  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hizmet_kategori':hizmet_kategori_adi,



    };
  }

  factory HizmetKategorisi.fromJson(Map<String, dynamic> jsonvar) {

    return HizmetKategorisi(
      id: jsonvar["id"].toString(),

      hizmet_kategori_adi: jsonvar["hizmet_kategorisi_adi"],

    );
  }
}