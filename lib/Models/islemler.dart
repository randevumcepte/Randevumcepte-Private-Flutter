class Islemler {
  Islemler({
    required this.id,
    required this.islem_fotolari,
    required this.tarih

  });

  final String id;
  final String islem_fotolari;
  final String tarih;


  // Convert from JSON
  factory Islemler.fromJson(Map<String, dynamic> json) {
    return Islemler(
      tarih: json["tarih"].toString() as String,
      id: json["id"].toString() as String,
      islem_fotolari: json["islem_fotolari"].toString() as String,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'islem_fotolari': islem_fotolari,
      'tarih':tarih,

    };
  }
}
