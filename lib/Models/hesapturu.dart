class HesapTuru {
  HesapTuru({

    required this.id,
    required this.hesapturu,

  });
  final String id;
  final String hesapturu;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hesapturu': hesapturu,

    };
  }
}