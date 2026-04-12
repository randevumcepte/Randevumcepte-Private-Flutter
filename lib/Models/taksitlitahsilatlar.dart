import 'package:randevu_sistem/Models/tahsilatkalemleri.dart';

import '../yonetici/dashboard/paketsatisi.dart';

class TaksitliTahsilat implements TahsilatKalemleri {
  TaksitliTahsilat({

    required this.id,
    required this.adisyon,
    required this.musteri,
    required this.vadeler,

  });

  final String id;
  final Map<String, dynamic>? adisyon;
  final Map<String, dynamic> musteri;
  final List<dynamic> vadeler;
  factory TaksitliTahsilat.fromJson(Map<String, dynamic> json) {
    return TaksitliTahsilat(
      id: json["id"].toString()?? '',
      adisyon: json["adisyon"] != null ? Map<String, dynamic>.from(json["adisyon"]) : null,
      musteri:json["musteri"],
      vadeler:json["vadeler"],



    );
  }
}