class Salonlar {
  Salonlar({
    required this.id,
    required this.takvim,
    required this.randevu,
    required this.salon_adi,
    this.musteriOnlineRandevuAktif = false,
  });
  final String id;
  final String takvim;
  final String randevu;
  final String salon_adi;
  // Bu şube online randevuya açık mı (salonlar.musteri_online_randevu_aktif).
  final bool musteriOnlineRandevuAktif;

  factory Salonlar.fromJson(Map<String, dynamic> json) {
    final v = json["musteri_online_randevu_aktif"];
    final aktif = v != null &&
        (v.toString().trim().toLowerCase() == '1' ||
            v.toString().trim().toLowerCase() == 'true');
    return Salonlar(
      takvim: json["randevu_saat_araligi"].toString(),
      randevu: json["randevu_takvim_turu"].toString(),
      id: json["id"].toString(),
      salon_adi: json['salon_adi'].toString(),
      musteriOnlineRandevuAktif: aktif,
    );
  }
}
