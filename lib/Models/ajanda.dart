class Ajanda {
  Ajanda({
    required this.id,
    required this.title,
    required this.description,
    required this.hatirlatma_saat,
    required this.hatirlatma,
    required this.durum,
    required this.ajandatarih,
    required this.ajandasaat,

  });

  final String id;
  final String title;
  final String description;
  final String hatirlatma_saat;
  final String hatirlatma;
  final String durum;
  final String ajandatarih;
  final String ajandasaat;


  factory Ajanda.fromJson(Map<String, dynamic> json) {
    return Ajanda(
      id: json["id"].toString(),
      title: json["title"].toString(),
      description: json["description"].toString(),
      hatirlatma_saat: json["ajanda_hatirlatma_saat"].toString(),
      hatirlatma: json["ajanda_hatirlatma"].toString(),
      durum: json["durum"].toString(),
      ajandatarih: json["tarih"].toString(),
      ajandasaat: json["saat"].toString(),

    );
  }
}