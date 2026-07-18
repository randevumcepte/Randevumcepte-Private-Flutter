class Islemler {
  Islemler({
    required this.id,
    required this.islem_fotolari,
    required this.tarih,
    this.resim_notu = '',
  });

  final String id;
  final String islem_fotolari;
  final String tarih;
  final String resim_notu; // Musteri gorseline eklenen not (backend'den)


  // Convert from JSON
  factory Islemler.fromJson(Map<String, dynamic> json) {
    return Islemler(
      tarih: json["tarih"].toString(),
      id: json["id"].toString(),
      islem_fotolari: json["islem_fotolari"].toString(),
      resim_notu: (json["resim_notu"] ?? '').toString(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'islem_fotolari': islem_fotolari,
      'tarih':tarih,
      'resim_notu': resim_notu,
    };
  }
}
