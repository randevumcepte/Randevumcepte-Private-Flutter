class PersonelMolaSaatleri {
  PersonelMolaSaatleri({
    required this.id,
    required this.haftaninGunu,
    required this.mola_var,
    required this.baslangic,
    required this.bitis,
  });

  final int id;
  final int haftaninGunu;
  final int  mola_var;
  final String baslangic;
  final String bitis;

  // Convert from JSON
  factory PersonelMolaSaatleri.fromJson(Map<String, dynamic> json) {
    return PersonelMolaSaatleri(
      id: int.tryParse(json["id"].toString()) ?? 0,
      haftaninGunu: int.tryParse(json["haftanin_gunu"].toString()) ?? 0,
      mola_var: (json["mola_var"] is String)
          ? int.tryParse(json["mola_var"]) ?? 0 // Handle case where it's a string
          : json["mola_var"] as int,

      baslangic: json["baslangic_saati"] as String,
      bitis: json["bitis_saati"] as String,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'haftanin_gunu': haftaninGunu,
      'mola_var': mola_var,
      'baslangic_saati': baslangic,
      'bitis_saati': bitis,
    };
  }
}
