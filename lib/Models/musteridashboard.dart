class MusteriOzet {
  final String okunmamisbildirimler;

  const MusteriOzet({
    required this.okunmamisbildirimler,
  });

  factory MusteriOzet.fromJson(Map<String, dynamic> json){
    return MusteriOzet(

      okunmamisbildirimler: json["musteriokunmamis"].toString() as String,


    );
  }
}