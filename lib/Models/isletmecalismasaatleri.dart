class IsletmeCalismaSaatleri {
  IsletmeCalismaSaatleri({
    required this.id,
    required this.haftaninGunu,
    required this.calisiyor,
    required this.baslangic,
    required this.bitis,
  });

  final int id;
  final int haftaninGunu;
  final int calisiyor; // This should be an integer
  final String baslangic;
  final String bitis;

  // Convert from JSON
  factory IsletmeCalismaSaatleri.fromJson(Map<String, dynamic> json) {
    return IsletmeCalismaSaatleri(
      id: int.tryParse(json["id"].toString()) ?? 0,
      haftaninGunu: int.tryParse(json["haftanin_gunu"].toString()) ?? 0,
      calisiyor: (json["calisiyor"] is String)
          ? int.tryParse(json["calisiyor"]) ?? 0 // Handle case where it's a string
          : json["calisiyor"] as int,
      baslangic: json["baslangic_saati"] as String,
      bitis: json["bitis_saati"] as String,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'haftanin_gunu': haftaninGunu,
      'calisiyor': calisiyor,
      'baslangic_saati': baslangic,
      'bitis_saati': bitis,
    };
  }
}
