class CiltTipi{
  CiltTipi({
    required this.id,
    required this.citl
});
  final String id;
  final String citl;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'citl': citl,

    };
  }
}