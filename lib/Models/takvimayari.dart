class TakvimAyari{
  TakvimAyari({
    required this.id,
    required this.takvim
  });
  final String id;
  final String takvim;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'takvim': takvim,

    };
  }
}