class Salonlar {
  Salonlar({
    required this.id,
    required this.takvim,
    required this.randevu,
    required this.salon_adi,



  });
  final String id;
  final String takvim;
  final String randevu;
  final String salon_adi;




  factory Salonlar.fromJson(Map<String, dynamic> json) {
    return Salonlar(
      takvim: json["randevu_saat_araligi"].toString(),
      randevu: json["randevu_takvim_turu"].toString(),

      id: json["id"].toString(),
      salon_adi: json['salon_adi'].toString()

    );
  }
}