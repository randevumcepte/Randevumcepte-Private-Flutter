import 'dart:convert';

import 'package:randevu_sistem/yonetici/dashboard/bildirimler/bildirimler_class.dart';
import 'package:http/http.dart' as http;

class BildirimSayfasi_Service{

  Future<SistemBildirimleri> getCount() async{
    const String url="https://app.randevumcepte.com.tr/api/v1/dashboard/114/";
    final response= await http.get(Uri.parse(url));
    final jsonresponse = json.decode(response.body);

    return SistemBildirimleri.fromJson(jsonresponse);
  }
}
class IsletmePuani_Service{

  Future<double> getPoint() async{
    const String url="https://app.randevumcepte.com.tr/api/v1/isletmepuani/114/";
    final response= await http.get(Uri.parse(url));
    final jsonresponse = response.body;

    return double.parse(jsonresponse);
  }
}