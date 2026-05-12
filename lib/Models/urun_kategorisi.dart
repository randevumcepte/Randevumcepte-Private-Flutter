class UrunKategorisi {
  UrunKategorisi({
    required this.id,
    required this.ad,
    this.ikon = '',
    this.renk = '',
    this.sira = 0,
    this.aktif = true,
  });

  final String id;
  final String ad;
  final String ikon;
  final String renk;
  final int sira;
  final bool aktif;

  factory UrunKategorisi.fromJson(Map<String, dynamic> j) {
    return UrunKategorisi(
      id: j['id'].toString(),
      ad: (j['ad'] ?? '').toString(),
      ikon: (j['ikon'] ?? '').toString(),
      renk: (j['renk'] ?? '').toString(),
      sira: int.tryParse((j['sira'] ?? '0').toString()) ?? 0,
      aktif: (j['aktif']?.toString() ?? '1') == '1' || j['aktif'] == true,
    );
  }
}
