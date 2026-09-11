// Uye vucut olcumu (Pilates/studyo modu). Her olcum = tarihli tek satir.

double? _d(dynamic v) {
  if (v == null || v.toString().isEmpty) return null;
  return double.tryParse(v.toString());
}

class VucutOlcum {
  final int id;
  final String tarih; // olcum_tarihi (Y-m-d)
  final double? boy;
  final double? kilo;
  final int? yas;
  final double? vki;
  final double? yagOrani;
  final double? odem;
  final double? kasPuani;
  final double? kasKg;
  final double? icYaglanma;
  final String? not;

  VucutOlcum({
    required this.id,
    required this.tarih,
    this.boy,
    this.kilo,
    this.yas,
    this.vki,
    this.yagOrani,
    this.odem,
    this.kasPuani,
    this.kasKg,
    this.icYaglanma,
    this.not,
  });

  factory VucutOlcum.fromJson(Map<String, dynamic> j) => VucutOlcum(
        id: int.tryParse(j['id'].toString()) ?? 0,
        tarih: (j['olcum_tarihi'] ?? '').toString(),
        boy: _d(j['boy']),
        kilo: _d(j['kilo']),
        yas: int.tryParse((j['yas'] ?? '').toString()),
        vki: _d(j['vki']),
        yagOrani: _d(j['yag_orani']),
        odem: _d(j['odem']),
        kasPuani: _d(j['kas_puani']),
        kasKg: _d(j['kas_kg']),
        icYaglanma: _d(j['ic_yaglanma']),
        not: (j['not'] == null || j['not'].toString().isEmpty) ? null : j['not'].toString(),
      );

  static String vkiSinif(double? v) {
    final x = v ?? 0;
    if (x <= 0) return '';
    if (x < 18.5) return 'Zayıf';
    if (x < 25) return 'Normal';
    if (x < 30) return 'Fazla Kilolu';
    return 'Obez';
  }
}
