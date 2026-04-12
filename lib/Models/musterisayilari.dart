// models/musteri_sayilari_model.dart
class MusteriSayilari {
  final int tumMusteriler;
  final int sadikMusteriler;
  final int aktifMusteriler;
  final int pasifMusteriler;

  MusteriSayilari({
    required this.tumMusteriler,
    required this.sadikMusteriler,
    required this.aktifMusteriler,
    required this.pasifMusteriler,
  });

  factory MusteriSayilari.fromJson(Map<String, dynamic> json) {
    return MusteriSayilari(
      tumMusteriler: json['tum_musteriler'] ?? 0,
      sadikMusteriler: json['sadik_musteriler'] ?? 0,
      aktifMusteriler: json['aktif_musteriler'] ?? 0,
      pasifMusteriler: json['pasif_musteriler'] ?? 0,
    );
  }
}