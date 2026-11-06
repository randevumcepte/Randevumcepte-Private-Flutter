import 'dart:convert';

import 'package:randevu_sistem/Models/katilimcilar.dart';
import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

import 'ongorusmenedeni.dart';

class Paket implements OnGorusmeNedeni,TahsilatKalemleri{
  Paket({
    required this.id,

    required this.paket_adi,
    required this.aktif,

    required this.hizmetler,
    this.miktar = '',
    this.fiyat = '',
    this.sure = '',
    this.sinirsiz = false,
    this.gecerlilikSayi = '',
    this.gecerlilikBirim = '',
    this.gunlukLimit = '',


  });

  final String id;

  final String paket_adi;



  final String aktif;

  final List<dynamic> hizmetler;

  final String miktar;
  final String fiyat;
  final String sure;
  final bool sinirsiz;
  final String gecerlilikSayi;
  final String gecerlilikBirim;
  final String gunlukLimit;

  /// "6 Ay" / "2 Yıl"; sure yoksa bos.
  String get sureMetni {
    final sayi = int.tryParse(gecerlilikSayi) ?? 0;
    return sayi > 0 ? '$sayi ${gecerlilikBirim == 'yil' ? 'Yıl' : 'Ay'}' : '';
  }

  /// Sinirsiz pakette seans adedi yerine gosterilir (miktar teknik degerdir, ekrana yazilmaz).
  String get sinirsizEtiketi =>
      sureMetni.isEmpty ? 'Sınırsız' : 'Sınırsız · $sureMetni';

  /// Satista hazir gelen seans: her bolge icin hak (8,8,8 = 8), yoksa paket miktari.
  int get varsayilanSeans {
    int enBuyuk = 0;
    for (final h in hizmetler) {
      final seans = double.tryParse(h['seans']?.toString() ?? '0')?.round() ?? 0;
      if (seans > enBuyuk) enBuyuk = seans;
    }
    return enBuyuk > 0 ? enBuyuk : (int.tryParse(miktar) ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'paket_adi':paket_adi,

      'hizmetler':hizmetler,

      'aktif':aktif,

      'miktar':miktar,

      'fiyat':fiyat,

      'sure':sure,

      'sinirsiz':sinirsiz ? 1 : 0,

      'gecerlilik_sayi':gecerlilikSayi,

      'gecerlilik_birim':gecerlilikBirim,

      'gunluk_limit':gunlukLimit,

    };
  }

  factory Paket.fromJson(Map<String, dynamic> jsonvar) {

    return Paket(
      id:jsonvar["id"].toString(),

      paket_adi: jsonvar["paket_adi"].toString(),


      aktif: jsonvar["aktif"].toString(),
      hizmetler: jsonvar["hizmetler"],

      miktar: (jsonvar["miktar"] ?? '').toString(),
      fiyat: (jsonvar["fiyat"] ?? '').toString(),
      sure: (jsonvar["sure"] ?? '').toString(),
      sinirsiz: jsonvar["sinirsiz"].toString() == '1' || jsonvar["sinirsiz"] == true,
      gecerlilikSayi: (jsonvar["gecerlilik_sayi"] ?? '').toString(),
      gecerlilikBirim: (jsonvar["gecerlilik_birim"] ?? '').toString(),
      gunlukLimit: (jsonvar["gunluk_limit"] ?? '').toString(),


    );
  }
  String getPaketUrunAdi() => paket_adi + ' (Paket)';
  String getId()=>id;
}