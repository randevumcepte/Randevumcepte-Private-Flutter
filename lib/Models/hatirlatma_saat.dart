class Hatirlatma {
  Hatirlatma({

    required this.id,
    required this.hatirlatma,

  });
  final String id;
  final String hatirlatma;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referans': hatirlatma,

    };
  }
}