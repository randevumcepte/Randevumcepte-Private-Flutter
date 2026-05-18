class Oda {
  Oda({
    required this.id,
    required this.oda_adi,
    required this.durum,
    required this.aciklama,
    required this.aktifmi,
    this.personeller = const [],




  });


  final String id;
  final String oda_adi;
  final String durum;
  final String aciklama;
  final String aktifmi;
  final List<Map<String, String>> personeller;



  /*Map<String, dynamic> toJson() {
    return {
      'id': id,

      'etkinlik_adi':paket_isim,
      'fiyat':fiyat,
      'aktifmi':aktifmi,
      'mesaj':mesaj,
      'katilimcilar':katilimcilar,
      'himzet_adi':hizmet_adi,
      'paket_isim':paket_isim,
      'seans':seans,

    };
  }*/
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'oda_adi': oda_adi,

    };
  }
  factory Oda.fromJson(Map<String, dynamic> jsonvar) {

    final rawPersoneller = jsonvar["personeller"];
    final List<Map<String, String>> personeller =
        (rawPersoneller is List)
            ? rawPersoneller
                .map<Map<String, String>>((e) => {
                      'id': (e is Map && e['id'] != null)
                          ? e['id'].toString()
                          : '',
                      'personel_adi': (e is Map && e['personel_adi'] != null)
                          ? e['personel_adi'].toString()
                          : '',
                    })
                .toList()
            : const [];
    return Oda(
      id: jsonvar["id"].toString(),
      oda_adi: jsonvar["oda_adi"].toString(),
      durum: jsonvar["durum"].toString(),
      aciklama: jsonvar["aciklama"].toString(),
      aktifmi: jsonvar["aktifmi"].toString(),
      personeller: personeller,
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Oda &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              oda_adi == other.oda_adi ;

  @override
  int get hashCode => id.hashCode ^ oda_adi.hashCode;
}