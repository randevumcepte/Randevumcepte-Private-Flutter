class SalonYorumItem {
  final int id;
  final String kullaniciAdi;
  final int puan;
  final String yorum;
  final DateTime? tarih;

  const SalonYorumItem({
    required this.id,
    required this.kullaniciAdi,
    required this.puan,
    required this.yorum,
    required this.tarih,
  });

  factory SalonYorumItem.fromJson(Map<String, dynamic> json) {
    return SalonYorumItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      kullaniciAdi: (json['kullanici_adi'] ?? 'Müşteri').toString(),
      puan: int.tryParse(json['puan']?.toString() ?? '0') ?? 0,
      yorum: (json['yorum'] ?? '').toString(),
      tarih: json['tarih'] != null
          ? DateTime.tryParse(json['tarih'].toString())
          : null,
    );
  }
}

class SalonYorumlarOzet {
  final double ortalama;
  final int toplamPuan;
  final int toplamYorum;
  final Map<int, int> dagilim;
  final List<SalonYorumItem> yorumlar;

  const SalonYorumlarOzet({
    required this.ortalama,
    required this.toplamPuan,
    required this.toplamYorum,
    required this.dagilim,
    required this.yorumlar,
  });

  factory SalonYorumlarOzet.fromJson(Map<String, dynamic> json) {
    final dgRaw = json['dagilim'] as Map<String, dynamic>? ?? {};
    final Map<int, int> dg = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    dgRaw.forEach((k, v) {
      final ki = int.tryParse(k.toString());
      if (ki != null && ki >= 1 && ki <= 5) {
        dg[ki] = int.tryParse(v.toString()) ?? 0;
      }
    });

    final yList = (json['yorumlar'] as List<dynamic>? ?? [])
        .map((e) => SalonYorumItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return SalonYorumlarOzet(
      ortalama: double.tryParse(json['ortalama']?.toString() ?? '0') ?? 0.0,
      toplamPuan: int.tryParse(json['toplam_puan']?.toString() ?? '0') ?? 0,
      toplamYorum: int.tryParse(json['toplam_yorum']?.toString() ?? '0') ?? 0,
      dagilim: dg,
      yorumlar: yList,
    );
  }
}
