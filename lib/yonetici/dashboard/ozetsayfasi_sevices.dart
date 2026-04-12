import 'dart:convert';

import 'package:randevu_sistem/yonetici/dashboard/ozetsayfasi.dart';
import 'package:http/http.dart' as http;

class OzetSayfasi_Service{


}
class IsletmePuani_Service{

  Future<double> getPoint() async{
    const String url="https://app.randevumcepte.com.tr/api/v1/isletmepuani/114/";
    final response= await http.get(Uri.parse(url));
    final jsonresponse = response.body;

    return double.parse(jsonresponse);
  }
}