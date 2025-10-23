class Referans {
  Referans({

    required this.id,
    required this.referans,

  });
  final String id;
  final String referans;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referans': referans,

    };
  }
}