class Depo {
  Depo({
    required this.id,
    required this.depo_adi,
    this.aciklama = '',
    this.varsayilan = false,
    this.aktif = true,
    this.toplam_stok = '0',
    this.salon_id = '',
  });

  final String id;
  final String depo_adi;
  final String aciklama;
  final bool varsayilan;
  final bool aktif;
  final String toplam_stok;
  final String salon_id;

  factory Depo.fromJson(Map<String, dynamic> j) {
    bool toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      final s = v.toString();
      return s == '1' || s == 'true';
    }

    return Depo(
      id: j['id'].toString(),
      depo_adi: (j['depo_adi'] ?? '').toString(),
      aciklama: (j['aciklama'] ?? '').toString(),
      varsayilan: toBool(j['varsayilan']),
      aktif: toBool(j['aktif']),
      toplam_stok: (j['toplam_stok'] ?? '0').toString(),
      salon_id: (j['salon_id'] ?? '').toString(),
    );
  }
}
