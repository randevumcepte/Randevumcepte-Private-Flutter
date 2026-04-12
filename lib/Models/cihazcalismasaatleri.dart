class CihazCalismaSaatleri {
  CihazCalismaSaatleri({
    required this.id,
    required this.haftaninGunu,
    required this.calisiyor,
    required this.baslangic,
    required this.bitis,
  });

  final int id;
  final int haftaninGunu;
  final bool calisiyor;
  final String baslangic;
  final String bitis;

  // Convert from JSON
  factory CihazCalismaSaatleri.fromJson(Map<String, dynamic> json) {
    return CihazCalismaSaatleri(
      id: json["id"] as int,
      haftaninGunu: json["haftanin_gunu"] as int,
      calisiyor: json["calisiyor"] == 1,
      baslangic: json["baslangic_saati"] as String,
      bitis: json["bitis_saati"] as String,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'haftanin_gunu': haftaninGunu,
      'calisiyor': calisiyor ? 1 : 0,
      'baslangic_saati': baslangic,
      'bitis_saati': bitis,
    };
  }
}
