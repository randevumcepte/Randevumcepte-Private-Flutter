import 'ajanda.dart';

class OzetSayfasi {
  final String randevusayisi;
  final String ongorusmesayisi;
  final String paketsatissayisi;
  final String urunsatissayisi;
  final String toplamkasa;
  final String kalantutar;
  final String kalansms;
  final String salonpuan;
  final String gelenarama;
  final String gidenarama;
  final String cevapsizarama;
  final String isletmeadi;
  final String isletmepuani;
  final String okunmamisbildirimler;
  final String prim;
  final List<dynamic> ajanda;



  const OzetSayfasi({

    required this.ongorusmesayisi,
    required this.kalantutar,
    required this.paketsatissayisi,
    required this.randevusayisi,
    required this.toplamkasa,
    required this.urunsatissayisi,
    required this.kalansms,
    required this.salonpuan,
    required this.gelenarama,
    required this.gidenarama,
    required this.cevapsizarama,
    required this.isletmeadi,
    required this.isletmepuani,
    required this.ajanda,
    required this.okunmamisbildirimler,
    required this.prim,
  });


  factory OzetSayfasi.fromJson(Map<String , dynamic> json){
    return OzetSayfasi(
      randevusayisi:json["randevu_sayisi"].toString() as String,
      ongorusmesayisi:json["ongorusme_sayisi"].toString() as String,
      paketsatissayisi:json["paket_satislari"].toString() as String,
      urunsatissayisi:json["urun_satislari"].toString() as String,
      toplamkasa:json["toplam_kasa"].toString() as String,
      kalantutar:json["kalan_tutar"].toString() as String,
      kalansms:json["kalan_sms"].toString() as String,
      salonpuan: json["puan"].toString() as String,
      gelenarama: json["gelen_arama"].toString() as String,
      gidenarama: json["giden_arama"].toString() as String,
      cevapsizarama:json["cevapsiz_arama"].toString() as String,
      isletmeadi: json['isletme_adi'].toString() as String,
      isletmepuani : json['puan'].toString() as String,
      ajanda : json['ajanda'],
      okunmamisbildirimler: json["okunmamisbildirimler"].toString() as String,
      prim:json['prim'].toString()

    );
  }





}