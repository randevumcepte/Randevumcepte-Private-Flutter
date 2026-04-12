class RandevuAraligi{
  RandevuAraligi({
    required this.id,
    required this.ran
  });
  final String id;
  final String ran;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ran': ran,

    };
  }
}