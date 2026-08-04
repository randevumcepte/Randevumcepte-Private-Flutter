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
    required this.tur,
    required this.iptalEdilebilir,
    required this.iptalEdildi,
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

  // Gorev turu: 'randevu' | 'alacak' | 'kampanya' | 'musteri'
  final String tur;
  // Web ile ayni kosula gore backend'in hesapladigi iptal edilebilirlik
  final bool iptalEdilebilir;
  // Gorev iptal edilmis mi (hatirlatma_gorevi_iptal / tanitim_gorev_iptal = 1)
  final bool iptalEdildi;

  factory EAsistan.fromJson(Map<String, dynamic> json) {
    // ID'leri kontrol et ve birlestir.
    // UNION sorgusunda tum satirlarin id'si ilk select'in alias'i olan
    // randevu_id anahtari altinda doner; gorev turunu 'tur' alani belirler.
    String alacakId = json["alacak_id"]?.toString() ?? "";
    String kampanyaId = json["kampanya_id"]?.toString() ?? "";
    String randevuId = json["randevu_id"]?.toString() ?? "";

    // Eger bir tanesi varsa, digerlerinden oncelikli olarak birini kullan
    String ortakId = alacakId.isNotEmpty ? alacakId :
    kampanyaId.isNotEmpty ? kampanyaId :
    randevuId.isNotEmpty ? randevuId : "";

    // Backend 1/0, true/false veya string dondurebilir; hepsini normalize et
    final iptalRaw = json["iptal_edilebilir"];
    final bool iptalEdilebilir =
        iptalRaw == 1 || iptalRaw == true || iptalRaw == "1" || iptalRaw == "true";

    final iptalEdildiRaw = json["iptal_edildi"];
    final bool iptalEdildi = iptalEdildiRaw == 1 ||
        iptalEdildiRaw == true ||
        iptalEdildiRaw == "1" ||
        iptalEdildiRaw == "true";

    return EAsistan(
      id: ortakId,              // Ortak ID
      alsacakId: alacakId,      // Alsacak ID
      kampanyaId: kampanyaId,   // Kampanya ID
      randevuId: randevuId,     // Randevu ID
      tur: json["tur"]?.toString() ?? "",
      iptalEdilebilir: iptalEdilebilir,
      iptalEdildi: iptalEdildi,
      baslik: json["baslik"]?.toString() ?? "",
      mesaj: json["mesaj"]?.toString() ?? "",
      durum: json["durum"]?.toString() ?? "",
      arama_saati: json["saat"]?.toString() ?? "",
      sonuc: json["sonuc"]?.toString() ?? "",
    );
  }

}
