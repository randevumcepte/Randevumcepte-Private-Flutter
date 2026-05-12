import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

import 'ongorusmenedeni.dart';

class Urun implements OnGorusmeNedeni, TahsilatKalemleri {
  Urun({
    required this.id,
    required this.urun_adi,
    required this.barkod,
    required this.fiyat,
    required this.aktif,
    required this.stok_adedi,
    required this.dusuk_stok_siniri,
    this.sku = '',
    this.alis_fiyati = '',
    this.kdv_orani = '',
    this.birim = 'adet',
    this.tip = 'satis',
    this.kategori_id = '',
    this.kategori_adi = '',
    this.kategori_renk = '',
    this.kategori_ikon = '',
    this.tedarikci_id = '',
    this.tedarikci_adi = '',
    this.varsayilan_depo_id = '',
    this.kritik_stok_siniri = '',
    this.resim_url = '',
    this.aciklama = '',
    this.salon_id = '',
  });

  final String id;
  final String urun_adi;
  final String barkod;
  final String fiyat;
  final String aktif;
  final String stok_adedi;
  final String dusuk_stok_siniri;

  final String sku;
  final String alis_fiyati;
  final String kdv_orani;
  final String birim;
  final String tip;
  final String kategori_id;
  final String kategori_adi;
  final String kategori_renk;
  final String kategori_ikon;
  final String tedarikci_id;
  final String tedarikci_adi;
  final String varsayilan_depo_id;
  final String kritik_stok_siniri;
  final String resim_url;
  final String aciklama;
  final String salon_id;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'urun_adi': urun_adi,
      'barkod': barkod,
      'fiyat': fiyat,
      'aktif': aktif,
      'stok_adedi': stok_adedi,
      'dusuk_stok_siniri': dusuk_stok_siniri,
      'sku': sku,
      'alis_fiyati': alis_fiyati,
      'kdv_orani': kdv_orani,
      'birim': birim,
      'tip': tip,
      'kategori_id': kategori_id,
      'kategori_adi': kategori_adi,
      'kategori_renk': kategori_renk,
      'kategori_ikon': kategori_ikon,
      'tedarikci_id': tedarikci_id,
      'tedarikci_adi': tedarikci_adi,
      'varsayilan_depo_id': varsayilan_depo_id,
      'kritik_stok_siniri': kritik_stok_siniri,
      'resim_url': resim_url,
      'aciklama': aciklama,
      'salon_id': salon_id,
    };
  }

  factory Urun.fromJson(Map<String, dynamic> json) {
    return Urun(
      id: json["id"].toString(),
      urun_adi: json["urun_adi"].toString(),
      barkod: json["barkod"]?.toString() ?? '',
      fiyat: json["fiyat"]?.toString() ?? '0',
      aktif: json["aktif"]?.toString() ?? '1',
      stok_adedi: json["stok_adedi"]?.toString() ?? '0',
      dusuk_stok_siniri: json["dusuk_stok_siniri"]?.toString() ?? '',
      sku: json["sku"]?.toString() ?? '',
      alis_fiyati: json["alis_fiyati"]?.toString() ?? '',
      kdv_orani: json["kdv_orani"]?.toString() ?? '',
      birim: json["birim"]?.toString() ?? 'adet',
      tip: json["tip"]?.toString() ?? 'satis',
      kategori_id: json["kategori_id"]?.toString() ?? '',
      kategori_adi: json["kategori_adi"]?.toString() ?? '',
      kategori_renk: json["kategori_renk"]?.toString() ?? '',
      kategori_ikon: json["kategori_ikon"]?.toString() ?? '',
      tedarikci_id: json["tedarikci_id"]?.toString() ?? '',
      tedarikci_adi: json["tedarikci_adi"]?.toString() ?? '',
      varsayilan_depo_id: json["varsayilan_depo_id"]?.toString() ?? '',
      kritik_stok_siniri: json["kritik_stok_siniri"]?.toString() ?? '',
      resim_url: json["resim_url"]?.toString() ?? '',
      aciklama: json["aciklama"]?.toString() ?? '',
      salon_id: json["salon_id"]?.toString() ?? '',
    );
  }

  @override
  String getId() => id;

  @override
  String getPaketUrunAdi() => urun_adi + ' (Ürün)';

  double get stokSayisal => double.tryParse(stok_adedi) ?? 0;
  double get dusukSinirSayisal => double.tryParse(dusuk_stok_siniri) ?? 0;
  double get kritikSinirSayisal => double.tryParse(kritik_stok_siniri) ?? 0;
  double get fiyatSayisal => double.tryParse(fiyat) ?? 0;
  double get alisFiyatiSayisal => double.tryParse(alis_fiyati) ?? 0;

  /// yesil / sari / kirmizi
  String get stokDurumu {
    final s = stokSayisal;
    if (s <= 0) return 'kirmizi';
    if (kritikSinirSayisal > 0 && s <= kritikSinirSayisal) return 'kirmizi';
    if (dusukSinirSayisal > 0 && s <= dusukSinirSayisal) return 'sari';
    return 'yesil';
  }
}
