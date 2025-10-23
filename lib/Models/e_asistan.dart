class EAsistan {
  EAsistan({
    required this.id,
    required this.baslik,
    required this.mesaj,
    required this.durum,
    required this.arama_saati,
    required this.sonuc,
    required this.alsacakId,
    required this.kampanyaId,
    required this.randevuId,
  });

  final String id; // Ortak id
  final String baslik;
  final String mesaj;
  final String durum;
  final String sonuc;
  final String arama_saati;

  final String alsacakId;
  final String kampanyaId;
  final String randevuId;

  factory EAsistan.fromJson(Map<String, dynamic> json) {
    // ID'leri kontrol et ve birleştir
    String alacakId = json["alacak_id"]?.toString() ?? "";
    String kampanyaId = json["kampanya_id"]?.toString() ?? "";
    String randevuId = json["randevu_id"]?.toString() ?? "";

    // Eğer bir tanesi varsa, diğerlerinden öncelikli olarak birini kullan
    String ortakId = alacakId.isNotEmpty ? alacakId :
    kampanyaId.isNotEmpty ? kampanyaId :
    randevuId.isNotEmpty ? randevuId : "";

    return EAsistan(
      id: ortakId,              // Ortak ID
      alsacakId: alacakId,      // Alsacak ID
      kampanyaId: kampanyaId,   // Kampanya ID
      randevuId: randevuId,     // Randevu ID
      baslik: json["baslik"]?.toString() ?? "",
      mesaj: json["mesaj"]?.toString() ?? "",
      durum: json["durum"]?.toString() ?? "",
      arama_saati: json["saat"]?.toString() ?? "",
      sonuc: json["sonuc"]?.toString() ?? "",
    );
  }

}
