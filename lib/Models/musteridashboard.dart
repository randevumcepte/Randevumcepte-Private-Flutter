class MusteriOzet {
  final String okunmamisbildirimler;
  final String kategori;         // 'pasif' | 'aktif' | 'sadik'
  final String kategoriLabel;    // 'Pasif Müşteri' | 'Aktif Müşteri' | 'Sadık Müşteri'
  final int tahsilatSayisi;
  final int sadakatPuani;

  const MusteriOzet({
    required this.okunmamisbildirimler,
    required this.kategori,
    required this.kategoriLabel,
    required this.tahsilatSayisi,
    required this.sadakatPuani,
  });

  factory MusteriOzet.fromJson(Map<String, dynamic> json) {
    return MusteriOzet(
      okunmamisbildirimler: json["musteriokunmamis"]?.toString() ?? '0',
      kategori: (json["kategori"] ?? 'pasif').toString(),
      kategoriLabel: (json["kategori_label"] ?? 'Pasif Müşteri').toString(),
      tahsilatSayisi: int.tryParse(json["tahsilat_sayisi"]?.toString() ?? '0') ?? 0,
      sadakatPuani: int.tryParse(json["sadakat_puani"]?.toString() ?? '0') ?? 0,
    );
  }
}
