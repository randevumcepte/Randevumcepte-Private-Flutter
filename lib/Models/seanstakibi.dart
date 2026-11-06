
import 'dart:convert';

import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

import 'adisyonkalemleri.dart';

class SeansTakip  {
  SeansTakip({
    required this.id,
    required this.adisyon,
    required this.musteri,

    required this.paket,
    required this.seanslar,
    required this.seansSayisi,
    required this.bekleyenSeansSayisi,
    required this.gelinenSeansSayisi,
    required this.gelinmeyenSeansSayisi,
    this.tip,
    this.paketHizmetId,
    this.hizmetler = const [],
    this.sinirsiz = false,
    this.sure = '',
    this.baslangic,
    this.bitis,

  });
  final String id;
  dynamic musteri;
  dynamic adisyon;
  final String paket;
  List<dynamic>seanslar;
  final int seansSayisi;
  final int bekleyenSeansSayisi;
  final int gelinenSeansSayisi;
  final int gelinmeyenSeansSayisi;
  final String? tip;
  final String? paketHizmetId;
  final List<dynamic> hizmetler;
  final bool sinirsiz;
  final String sure;
  final String? baslangic;
  final String? bitis;

  String get sinirsizEtiketi => sure.isEmpty ? 'Sınırsız' : 'Sınırsız · $sure';

  /// Bitis gunu dahil gecerli; bitis yoksa (henuz gelinmedi) sure islemez.
  bool get suresiDoldu => _kalanGun != null && _kalanGun! < 0;

  int? get _kalanGun {
    final son = DateTime.tryParse(bitis ?? '');
    if (son == null) return null;
    final simdi = DateTime.now();
    return DateTime(son.year, son.month, son.day)
        .difference(DateTime(simdi.year, simdi.month, simdi.day))
        .inDays;
  }

  String get kalanSureMetni {
    final gun = _kalanGun;
    if (gun == null) return 'İlk gelişte başlar';
    return gun < 0 ? 'Süresi doldu' : '$gun gün kaldı';
  }




  factory SeansTakip.fromJson(Map<String, dynamic> jsonvar) {

    return SeansTakip(

      id:jsonvar["id"].toString(),
      musteri:jsonvar["musteri"],
      adisyon:jsonvar["adisyon"],
      paket:jsonvar["paket"].toString(),
      seanslar:jsonvar["seanslar"],
      seansSayisi:jsonvar["toplamSeansSayisi"],
      bekleyenSeansSayisi:jsonvar["bekleyenSeansSayisi"],
      gelinenSeansSayisi:jsonvar["gelinenSeansSayisi"],
      gelinmeyenSeansSayisi:jsonvar["gelinmeyenSeansSayisi"],
      tip: jsonvar["tip"]?.toString(),
      paketHizmetId: jsonvar["paketHizmetId"]?.toString(),
      hizmetler: (jsonvar["hizmetler"] is List)
          ? jsonvar["hizmetler"] as List<dynamic>
          : const [],
      sinirsiz: jsonvar["sinirsiz"].toString() == '1',
      sure: (jsonvar["sure"] ?? '').toString(),
      baslangic: jsonvar["baslangic"]?.toString(),
      bitis: jsonvar["bitis"]?.toString(),

    );
  }
}
