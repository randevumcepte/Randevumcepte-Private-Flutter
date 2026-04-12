class SaglikBilgileri{
  SaglikBilgileri({
    required this.id,
    required this.saglik
});
  final String id;
  final String saglik;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saglik': saglik,

    };
  }
}