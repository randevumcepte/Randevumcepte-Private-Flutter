

class MasrafKategorisi {
  MasrafKategorisi({

    required this.id,
    required this.kategori,
  });
  final String id;
  final String kategori;

  factory MasrafKategorisi.fromJson(Map<String, dynamic> json) {
    return MasrafKategorisi(
        id: json["id"].toString(),
        kategori: json["kategori"].toString(),
    );
  }
}