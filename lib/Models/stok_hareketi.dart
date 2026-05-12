class StokHareketi {
  StokHareketi({
    required this.id,
    required this.urun_id,
    required this.miktar,
    required this.hareket_tipi,
    this.depo_id = '',
    this.referans_tip = '',
    this.referans_id = '',
    this.birim_alis_fiyati = '',
    this.birim_satis_fiyati = '',
    this.aciklama = '',
    this.kullanici_id = '',
    this.kullanici_tipi = '',
    this.tarih = '',
  });

  final String id;
  final String urun_id;
  final String depo_id;
  final String miktar;
  final String hareket_tipi;
  final String referans_tip;
  final String referans_id;
  final String birim_alis_fiyati;
  final String birim_satis_fiyati;
  final String aciklama;
  final String kullanici_id;
  final String kullanici_tipi;
  final String tarih;

  factory StokHareketi.fromJson(Map<String, dynamic> j) {
    return StokHareketi(
      id: j['id'].toString(),
      urun_id: (j['urun_id'] ?? '').toString(),
      depo_id: (j['depo_id'] ?? '').toString(),
      miktar: (j['miktar'] ?? '0').toString(),
      hareket_tipi: (j['hareket_tipi'] ?? '').toString(),
      referans_tip: (j['referans_tip'] ?? '').toString(),
      referans_id: (j['referans_id'] ?? '').toString(),
      birim_alis_fiyati: (j['birim_alis_fiyati'] ?? '').toString(),
      birim_satis_fiyati: (j['birim_satis_fiyati'] ?? '').toString(),
      aciklama: (j['aciklama'] ?? '').toString(),
      kullanici_id: (j['kullanici_id'] ?? '').toString(),
      kullanici_tipi: (j['kullanici_tipi'] ?? '').toString(),
      tarih: (j['tarih'] ?? '').toString(),
    );
  }

  double get miktarSayisal => double.tryParse(miktar) ?? 0;

  String get tipEtiket {
    switch (hareket_tipi) {
      case 'alis':           return 'Alış';
      case 'satis':          return 'Satış';
      case 'sarf':           return 'Sarf';
      case 'fire':           return 'Fire';
      case 'sayim':          return 'Sayım Düzeltme';
      case 'transfer_giris': return 'Transfer (Giriş)';
      case 'transfer_cikis': return 'Transfer (Çıkış)';
      case 'iade':           return 'İade';
      case 'acilis':         return 'Açılış';
      case 'manuel':         return 'Manuel';
      default:               return hareket_tipi;
    }
  }
}
