import 'dart:convert';
import 'dart:developer';


import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Login%20Sayfas%C4%B1/tanitim.dart';
import 'package:randevu_sistem/Models/masrafkategorileri.dart';
import 'package:randevu_sistem/Models/ongorusmenedeni.dart';
import 'package:randevu_sistem/Models/randevular.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/ornekdatagrid.dart';
import 'package:randevu_sistem/yonetici/diger/menu/kampanya/kampanyalar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/sms_taslaklari.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Models/e_asistan.dart';
import '../Models/musteridashboard.dart';
import '../Models/hizmetkategorisi.dart';
import '../Frontend/progressloading.dart';
import '../Login Sayfası/checklogin.dart';
import '../Models/adisyonhizmetler.dart';
import '../Models/adisyonkalemleri.dart';
import '../Models/adisyonpaketler.dart';
import '../Models/adisyonurunler.dart';
import '../Models/ajanda.dart';
import '../Models/cdr.dart';
import '../Models/cihazlar.dart';
import '../Models/dashboard.dart';
import '../Models/etkinlikler.dart';
import '../Models/form.dart';
import '../Models/hizmetler.dart';
import '../Models/isletmecalismasaatleri.dart';
import '../Models/isletmehizmetleri.dart';
import '../Models/molasaatleri.dart';
import '../Models/musterisayilari.dart';
import '../Models/ongorusmeler.dart';
import '../Models/randevuhizmetleri.dart';
import '../Models/randevuhizmetyardimcipersonelleri.dart';
import '../Models/salonlar.dart';
import '../Models/sehirler.dart';
import '../Models/senetvadeleri.dart';
import '../Models/sozlesme.dart';
import '../Models/kampanyalar.dart';
import '../Models/odalar.dart';
import '../Models/paketler.dart';
import '../Models/personel.dart';
import '../Models/taksitvadeleri.dart';
import '../Models/urunler.dart';
import '../Models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../musteripaneli/musterialtbar.dart';
import '../yonetici/dashboard/ozetsayfasi.dart';
import 'dart:io';
import 'package:path/path.dart';

import '../yonetici/diger/menu/ayarlar/personeller/personelcalismasaatleri.dart';
import '../yonetici/diger/menu/ayarlar/personeller/personelmolasaatleri.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../yonetici/diger/menu/musteriler/rehberdekimusteriler.dart';
import '../yonetici/diger/menu/musteriler/yeni_musteri.dart';

Future<Map<String,dynamic>> ajandagetir(String salonid,String currpage,String baslik) async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'baslik': baslik,


    // Add other form fields
  };


  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/ajandaget/"+salonid.toString()+"/"+user['id'].toString()+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Ajanda sayfası. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return json.decode(response.body);
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future<Map<String,dynamic>> cihazgetir(String salonid,String currpage,String baslik) async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'baslik': baslik,


    // Add other form fields
  };


  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/cihazgetir/"+salonid.toString()+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Cihaz getir. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return json.decode(response.body);
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future<Map<String,dynamic>> odagetir(String salonid,String currpage,String baslik) async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'baslik': baslik,


    // Add other form fields
  };


  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/odagetir/"+salonid.toString()+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Oda getir. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return json.decode(response.body);
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}

Future<List<MusteriDanisan>> musterilistegetir(String salonid) async {
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteriler/'+salonid.toString())
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Müşteriler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");

    // JSON yanıtını decode et
    var jsonResponse = json.decode(response.body);

    // Eğer yanıt bir map ise ve içinde data anahtarı varsa, onu kullan
    List jsonList;
    if (jsonResponse is Map<String, dynamic>) {
      if (jsonResponse.containsKey('data')) {
        jsonList = jsonResponse['data'];
      } else if (jsonResponse.containsKey('musteriler')) {
        jsonList = jsonResponse['musteriler'];
      } else {
        // Map'in direkt kendisini liste olarak kullan
        jsonList = [jsonResponse];
      }
    } else if (jsonResponse is List) {
      jsonList = jsonResponse;
    } else {
      throw Exception('Beklenmeyen yanıt formatı: ${jsonResponse.runtimeType}');
    }

    return jsonList.map((e) => MusteriDanisan.fromJson(e)).toList();
  } else {
    logyaz(response.statusCode, response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}

Future<MusteriDanisan> musterilistegetirTahsilat(String userId) async {
  final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteritahsilat?userId='+userId)
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Müşteriler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");

    // JSON yanıtını decode et
    var jsonResponse = json.decode(response.body);
    log('müşteri tahsilat json response '+response.body);
    return MusteriDanisan.fromJson(jsonResponse);
  } else {
    logyaz(response.statusCode, response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}

Future<List<MusteriDanisan>> musterilistegetirSayfali(String seciliMusteri,
    String salonid, String filter, String limit, String offset) async {

  final response = await http.get(Uri.parse(
      'https://app.randevumcepte.com.tr/api/v1/musteriler/$salonid?search=$filter&limit=$limit&offset=$offset&seciliMusteri?$seciliMusteri'));

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(response.body);

    // API'den gelen "data" listesini çekiyoruz
    List data = jsonResponse['data'];
    return data.map((e) => MusteriDanisan.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load');
  }
}
Future<List<Sehir>> sehirgetir() async {
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/sehirler')
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Şehirler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    List jsonResponse = json.decode(response.body);

    return jsonResponse.map((e) => Sehir.fromJson(e)).toList();
  } else {

    throw Exception(response.reasonPhrase);
  }
}

Future<List<OnGorusmeNedeni>> ongorusmenedeni(String salonid) async {
  final response = await http.get(Uri.parse('https://app.randevumcepte.com.tr/api/v1/ongorusmenedeni/'+salonid));

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Ön görüşme nedeni? Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    List<OnGorusmeNedeni> loadedItems = [];



    if (jsonResponse['paketler'] != null) {
      loadedItems.addAll((jsonResponse['paketler'] as List).map((item) => Paket.fromJson(item)).toList());
    }
    if (jsonResponse['urunler'] != null) {
      loadedItems.addAll((jsonResponse['urunler'] as List).map((item) => Urun.fromJson(item)).toList());
    }
    return loadedItems;
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception('Failed to load items');
  }
}



Future<List<Personel>> personellistegetir(String salonid) async {
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/personeller/'+salonid.toString())
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Personeller. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    List jsonResponse = json.decode(response.body);

    return jsonResponse.map((e) => Personel.fromJson(e)).toList();
  } else {

    throw Exception(response.reasonPhrase);
  }
}

Future<List<Sozlesme>> formlarigetir() async{
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/formlar')
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Formlar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    List jsonResponse = json.decode(response.body);

    return jsonResponse.map((e) => Sozlesme.fromJson(e)).toList();
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future<List<MasrafKategorisi>> masrafkategorileri() async {
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/masrafkategorileri')
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Masraf Kategori liste. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    List jsonResponse = json.decode(response.body);

    return jsonResponse.map((e) => MasrafKategorisi.fromJson(e)).toList();
  } else {

    throw Exception(response.reasonPhrase);
  }
}
Future<List<SmsTaslak>> smstaslakgetir(String salonid) async {
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/smstaslaklari/'+salonid.toString())
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    List jsonResponse = json.decode(response.body);

    return jsonResponse.map((e) => SmsTaslak.fromJson(e)).toList();
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}

Future<Map<String,dynamic>> kampanyagetir(String salonid,String currpage,String arama) async {

  Map<String, dynamic> formData = {
    'arama': arama,

  };


  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/kampanyalar/'+salonid.toString()+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Kampanyalar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");

    return  json.decode(response.body);
  } else {logyaz(response.statusCode,response.reasonPhrase);
  throw Exception(response.reasonPhrase);
  }
}
Future<Map<String,dynamic>> etkinlikgetir(String salonid,String currpage,String arama) async {


  Map<String, dynamic> formData = {
    'arama': arama,

  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/etkinlikyukle/'+salonid.toString()+'?page='+currpage.toString()),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Etkinlikler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return  json.decode(response.body);
  } else {logyaz(response.statusCode,response.reasonPhrase);
  throw Exception(response.reasonPhrase);
  }
}
Future<List<Paket>> paketgetir(String salonid) async {
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/paketget/'+salonid.toString())
  );

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Paketler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return jsonResponse.map((e) => Paket.fromJson(e)).toList();
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }



}


Future<Map<String, dynamic>> arsivgetir(String salonid,String musteriid,String currpage,String arama,String durum,String cevapladi,String cevapladi2) async {
  Map<String, dynamic> formData = {

    'arama':arama,
    'durum':durum,
    'cevapladi':cevapladi,
    'cevapladi2':cevapladi2,
    'musteri_id':musteriid,

    // Add other form fields
  };
  log("arşiv salon id "+salonid.toString());
  log("müşteri id "+musteriid);


  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/arsivyukle/'+salonid.toString()+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );


  if (response.statusCode == 200) {
    debugPrint(response.body);
    return json.decode(response.body);


  } else {
    debugPrint(response.body);
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);

  }
}

Future<Kullanici> kullanicibilgi(String userid) async {
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/kullaniciBilgiGetir/'+userid.toString())
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Kullanıcı bilgi. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    final jsonResponse = json.decode(response.body);

    return  Kullanici.fromJson(jsonResponse);
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future<List<IsletmeHizmet>> isletmehizmetleri(String salonid) async{
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/hizmetler/'+salonid.toString())
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Hizmetler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    List jsonResponse = json.decode(response.body);

    return jsonResponse.map((e) => IsletmeHizmet.fromJson(e)).toList();
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future<List<Cihaz>> isletmecihazlari(String salonid) async{
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/cihazlar/'+salonid.toString())
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Cihazlar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    List jsonResponse = json.decode(response.body);

    return jsonResponse.map((e) => Cihaz.fromJson(e)).toList();
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future<List<Oda>> isletmeodalari(String salonid) async{
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/odalar/'+salonid.toString())
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Odalar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    List jsonResponse = json.decode(response.body);

    return jsonResponse.map((e) => Oda.fromJson(e)).toList();
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}Future<Map<String, dynamic>> fetchSalonSettings(String salonId) async {
  Map<String, dynamic> formData = {
    'salon_id': salonId,


    // Add other form fields
  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/salonlar'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  debugPrint('Response status: ${response.statusCode}');
  debugPrint('Response body: ${salonId}');

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Salonlar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future<List<IsletmeCalismaSaatleri>> fetchSalonHoursSettings(String salonId) async{

  final response = await http.get(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/salonsaatleri/'+salonId),

    headers: {'Content-Type': 'application/json'},

  );
  debugPrint('Response status: ${response.statusCode}');
  debugPrint('Response body: ${response.body}');

  if (response.statusCode == 200) {
    try {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => IsletmeCalismaSaatleri.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error decoding JSON: $e');
      throw Exception('Error parsing response');
    }
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    debugPrint('Failed to load data. Status code: ${response.statusCode}');
    throw Exception('Failed to load data: ${response.reasonPhrase}');
  }
}
Future<List<IsletmeMolaSaatleri>> fetchSalonBreakHoursSettings(String salonId) async{

  final response = await http.get(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/salonmolasaatleri/'+salonId),

    headers: {'Content-Type': 'application/json'},

  );
  debugPrint('Response status: ${response.statusCode}');
  debugPrint('Response body: ${response.body}');

  if (response.statusCode == 200) {
    try {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => IsletmeMolaSaatleri.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error decoding JSON: $e');
      throw Exception('Error parsing response');
    }
  } else {
    debugPrint('Failed to load data. Status code: ${response.statusCode}');
    throw Exception('Failed to load data: ${response.reasonPhrase}');
  }
}
Future<String?> secilisalonid() async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  try {

    return localStorage.getString('sube');

  }
  catch (e) {
    return 'Hata oluştu: $e';
  }
}
Future<OzetSayfasi> dashboardGunlukRapor(String salonid ) async{
  SharedPreferences localStorage = await SharedPreferences.getInstance();

  var user = jsonDecode(localStorage.getString('user')!);
  log("salon id "+salonid +" user id "+user["id"].toString());
  Map<String, dynamic> formData = {

    'sube': salonid,
    'user_id': user["id"],

    // Add other form fields
  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/dashboard'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );


  log("Özet Sayfası "+response.body);
  final jsonresponse = json.decode(response.body);

  return OzetSayfasi.fromJson(jsonresponse);

}
Future<File> _fileFromImageUrl() async {
  final response = await http.get(Uri.parse('https://example.com/xyz.jpg)'));

  final documentDirectory = await getApplicationDocumentsDirectory();

  final file = File(join(documentDirectory.path, 'imagetest.png'));

  file.writeAsBytesSync(response.bodyBytes);

  return file;
}
Future <Map<String, dynamic>> ongorusmeler(String Salonid,  String currpage,String musteridanisanadi) async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {

    'salon_id': Salonid,

    'musteridanisan': musteridanisanadi,
    'userId':user['id'],

    // Add other form fields
  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/ongorusmeget/'+Salonid.toString()+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Ön görüşmeler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return json.decode(response.body);

  } else {

    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future <Map<String, dynamic>> ongorusmelergunluk(String Salonid,  String currpage,String musteridanisanadi) async {
  Map<String, dynamic> formData = {

    'salon_id': Salonid,

    'musteridanisan': musteridanisanadi,

    // Add other form fields
  };
  log('formdata '+jsonEncode(formData).toString());
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/ongorusmegetgunluk/'+Salonid.toString()+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Ön görüşme günlük. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future<List<Cdr>> santralraporlari(
    String salonId,
    String tarih1,
    String tarih2,
    int currentoffset,
    String arama,
    ) async {
  try {
    final buffer = StringBuffer();
    buffer.write("salonId=$salonId");
    buffer.write("&tarih1=$tarih1");
    buffer.write("&tarih2=$tarih2");
    buffer.write("&offset=$currentoffset");
    buffer.write("&arama=$arama");
    buffer.write("&limit=50"); // <-- YENİ: limit parametresi eklendi

    final uri = Uri.parse(
      "https://app.randevumcepte.com.tr/api/v1/cdrraporson?${buffer.toString()}",
    );

    print('santralraporlari: URI = $uri');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    print('santralraporlari: HTTP status = ${response.statusCode}');

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);

      // Güvenlik: boş veya null gelirse boş liste dön
      if (decoded == null) return [];

      // Backend düz liste döndürüyor (mevcut Cdr.fromJson uyumlu)
      final List<dynamic> data = decoded is List ? decoded : [];

      print('santralraporlari: veri alındı, count = ${data.length}');
      return data.map((item) => Cdr.fromJson(item)).toList();
    } else {
      print('santralraporlari: response body = ${response.body}');
      throw Exception('HTTP error ${response.statusCode}');
    }
  } catch (e, st) {
    print('santralraporlari: exception = $e');
    print(st);
    return [];
  }
}


Future <Map<String, dynamic>>   randevularigetir(String musteri_id,String Salonid,String olusturma,String durum,String tarih, String currpage,String musteridanisanadi,String personelid,String cihazid,bool musteriMi) async {
  bool web = false;
  bool salon = false;
  bool uygulama = false;
  String tarih1 = '';
  String tarih2 = '';
  String randevudurumu = '';
  final now = new DateTime.now();
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final thismonth1 = DateTime.utc(now.year,now.month,1);
  final thismonth2 = DateTime.utc(now.year,now.month + 1,0);
  final nextmonth1 = DateTime.utc(now.year,now.month + 1,1);
  final nextmonth2 = DateTime.utc(now.year,now.month +2,0);
  final thisyear1 = DateTime.utc(now.year,1 ,1);
  final thisyear2 = DateTime.utc(now.year,12,31);
  final nextyear1 = DateTime.utc(now.year+1,1,1);
  final nextyear2 = DateTime.utc(now.year+1,12,31);

  if(olusturma == 'Web')
    web = true;
  if(olusturma == 'Salon')
    salon = true;
  if(olusturma == 'Uygulama')
    uygulama = true;
  if(olusturma == 'Tümü') {
    uygulama = true;
    web= true;
    salon=true;
  }

  if(tarih == 'Bugün')
  {
    tarih1 = DateFormat('yyyy-MM-dd').format(now);
    tarih2 = DateFormat('yyyy-MM-dd').format(now);
  }
  if(tarih == 'Yarın') {
    tarih1 = DateFormat('yyyy-MM-dd').format(tomorrow);
    tarih2 = DateFormat('yyyy-MM-dd').format(tomorrow);
  }
  if(tarih == 'Bu ay') {
    tarih1 = DateFormat('yyyy-MM-dd').format(thismonth1);
    tarih2 = DateFormat('yyyy-MM-dd').format(thismonth2);
  }
  if(tarih == 'Önümüzdeki ay') {
    tarih1 = DateFormat('yyyy-MM-dd').format(nextmonth1);
    tarih2 = DateFormat('yyyy-MM-dd').format(nextmonth2);
  }
  if(tarih == 'Bu yıl') {
    tarih1 = DateFormat('yyyy-MM-dd').format(thisyear1);
    tarih2 = DateFormat('yyyy-MM-dd').format(thisyear2);
  }
  if(tarih == 'Önümüzdeki yıl') {
    tarih1 = DateFormat('yyyy-MM-dd').format(nextyear1);
    tarih2 = DateFormat('yyyy-MM-dd').format(nextyear2);
  }
  if(tarih == 'Tümü')
  {
    tarih1 = '1970-01-01';
    tarih2 = '2050-01-01';
  }

  if(durum == 'Tümü') {
    randevudurumu = '';
  }
  if(durum == 'Onay bekleyen')
    randevudurumu = '0';
  if(durum == 'Onaylı')
    randevudurumu = '1';
  if(durum=='Reddedilen/İptal Edilen')
    randevudurumu = '2';
  if(durum=='Müşteri tarafından iptal edilen')
    randevudurumu = '3';


  SharedPreferences localStorage = await SharedPreferences.getInstance();

  var usertype = localStorage.getString('user_type') ?? '';
  usertype = usertype.replaceAll('"', '').trim();

  Map<String, dynamic> user;
  if (usertype == '1') {
    user = jsonDecode(localStorage.getString('user')!);
  } else {
    user = jsonDecode(localStorage.getString('musteri')!);
  }

  Map<String, dynamic> formData = {
    'tarih1': tarih1,
    'tarih2': tarih2,
    'salon': salon,
    'web':web,
    'uygulama':uygulama,
    'durum':randevudurumu,
    'userid':user['id'].toString(),
    'musteridanisan': musteridanisanadi,
    'musteri_id': musteri_id.toString(),
    'cihaz_id':cihazid,
    'personel_id':personelid,
    'appBundle':await appBundleAl(),
    'musteriMi':musteriMi,
    'salonId':Salonid.toString(),


    // Add other form fields
  };

  log('randevu liste '+jsonEncode(formData));
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevular?page='+currpage.toString()),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];



    return  json.decode(response.body);

  } else {

    logyaz(response.statusCode,response.reasonPhrase);
    debugPrint(response.body);
    throw Exception(response.reasonPhrase);
  }

}
Future <Map<String, dynamic>> calismasaatlerinigetir(String Salonid) async {
  Map<String, dynamic> formData = {
    'salonid': Salonid,


    // Add other form fields
  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/isletmecalismasaatleri/'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("çalışma saatleri. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}

Future <Map<String ,dynamic>> randevucek(String Salonid,String currpage,String musteridanisanadi) async {
  String randevudurumu = '';
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'id':user['id'],
    'musteridanisan': musteridanisanadi,

    // Add other form fields
  };
  var response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/tum_randevulari_getir/"+Salonid.toString()+'?page='+currpage.toString()),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("tüm randevular. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    var jsonResponse = json.decode(response.body);
    // Assuming 'data' is the key in the JSON object that holds the list of randevular
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future <Map<String ,dynamic>> randevuceksalon(String Salonid,String currpage,String musteridanisanadi) async {
  String randevudurumu = '';
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'id':user['id'],
    'musteridanisan': musteridanisanadi,

    // Add other form fields
  };
  var response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/salon_randevu_getir/"+Salonid.toString()+'?page='+currpage.toString()),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("salon randevuları. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    var jsonResponse = json.decode(response.body);
    // Assuming 'data' is the key in the JSON object that holds the list of randevular
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future <Map<String ,dynamic>> randevucekuygulama(String Salonid,String currpage,String musteridanisanadi) async {
  String randevudurumu = '';
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'id':user['id'],
    'musteridanisan': musteridanisanadi,

    // Add other form fields
  };
  var response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/uygulama_randevu_getir/"+Salonid.toString()+'?page='+currpage.toString()),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("uygulama randevuları. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    var jsonResponse = json.decode(response.body);
    // Assuming 'data' is the key in the JSON object that holds the list of randevular
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future <Map<String ,dynamic>> randevucekweb(String Salonid,String currpage,String musteridanisanadi) async {
  String randevudurumu = '';
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'id':user['id'],
    'musteridanisan': musteridanisanadi,

    // Add other form fields
  };
  var response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/web_randevu_getir/"+Salonid.toString()+'?page='+currpage.toString()),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("web randevuları. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    var jsonResponse = json.decode(response.body);
    // Assuming 'data' is the key in the JSON object that holds the list of randevular
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}








Future <Map<String, dynamic>> urunlerigetir(String Salonid , String currpage,String urunadi) async {

  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'urunadi': urunadi,


    // Add other form fields
  };
  log('formdata '+jsonEncode(formData).toString());

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/urunler/'+Salonid+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Ürünler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}

Future <Map<String, dynamic>> paketlerigetir(String Salonid , String currpage,String pakethizmet) async {

  SharedPreferences localStorage = await SharedPreferences.getInstance();

  Map<String, dynamic> formData = {
    'arama': pakethizmet,



    // Add other form fields
  };


  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/paketler/'+Salonid+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );


  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Paketler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}
Future <Map<String, dynamic>> paketsatislarigetir(String Salonid,String currpage,String musteridanisanadi) async {
  Map<String, dynamic> formData = {
    'salon_id': Salonid,
    'musteridanisan': musteridanisanadi,

    // Add other form fields
  };
  log('formdata '+jsonEncode(formData).toString());
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/paketsatisget/'+Salonid+'?page='+currpage.toString()),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );


  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Paket satışları. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}
Future <Map<String, dynamic>> urunsatislarigetir(String Salonid,String currpage,String musteridanisanadi) async {
  Map<String, dynamic> formData = {
    'salon_id': Salonid,
    'musteridanisan': musteridanisanadi,

    // Add other form fields
  };
  log('formdata '+jsonEncode(formData).toString());
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/urunsatisget/'+Salonid+'?page='+currpage.toString()),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );


  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Ürün satışları. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}
Future <Map<String, dynamic>> alacaklargetir(String Salonid,String currpage,String musteridanisanadi) async {
  Map<String, dynamic> formData = {
    'id': Salonid,
    'musteridanisan': musteridanisanadi,

    // Add other form fields
  };
  log('formdata '+jsonEncode(formData).toString());
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/alacaklar/'+Salonid+'?page='+currpage.toString()),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );


  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Alacaklar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}

Future <Map<String, dynamic>> satislarigetir(String Salonid , String currpage,String arama) async {


  Map<String, dynamic> formData = {
    'arama': arama,
    'salonId':Salonid,
    // Add other form fields
  };


  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/seanslar?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Seanslar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}

Future <Map<String, dynamic>> senetlerigetir(String Salonid , String currpage,String arama,String durum) async {


  Map<String, dynamic> formData = {
    'arama': arama,
    'durum':durum,
    // Add other form fields
  };


  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/senetler/'+Salonid+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Senetler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}

Future <Map<String, dynamic>> musteridanisanlistesi(String Salonid , String currpage,String arama,String durum) async {


  Map<String, dynamic> formData = {
    'arama': arama,
    'durum':durum,
    // Add other form fields
  };

log('curr page '+currpage.toString());
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/musterilistegetir/'+Salonid+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    log('müşteri josn response '+response.body);
    return  json.decode(response.body);

  } else {
    log('Hata oluştu '+response.body);
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}

Future <Map<String, dynamic>> tahsilatraporu(String Salonid , String currpage,String tarih,String odemeyontemi) async {
  String tarih1= '';
  String tarih2='';
  String odeme = '';
  final now = new DateTime.now();
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final thismonth1 = DateTime.utc(now.year,now.month,1);
  final thismonth2 = DateTime.utc(now.year,now.month + 1,0);
  final lastmonth1 = DateTime.utc(now.year,now.month - 1,1);
  final lastmonth2 = DateTime.utc(now.year,now.month -2,0);
  final thisyear1 = DateTime.utc(now.year,1 ,1);
  final thisyear2 = DateTime.utc(now.year,12,31);


  if(tarih == 'Bugün')
  {
    tarih1 = DateFormat('yyyy-MM-dd').format(now);
    tarih2 = DateFormat('yyyy-MM-dd').format(now);
  }
  if(tarih == 'Dün') {
    tarih1 = DateFormat('yyyy-MM-dd').format(yesterday);
    tarih2 = DateFormat('yyyy-MM-dd').format(yesterday);
  }
  if(tarih == 'Bu ay') {
    tarih1 = DateFormat('yyyy-MM-dd').format(thismonth1);
    tarih2 = DateFormat('yyyy-MM-dd').format(thismonth2);
  }
  if(tarih == 'Geçen ay') {
    tarih1 = DateFormat('yyyy-MM-dd').format(lastmonth1);
    tarih2 = DateFormat('yyyy-MM-dd').format(lastmonth2);
  }
  if(tarih == 'Bu yıl') {
    tarih1 = DateFormat('yyyy-MM-dd').format(thisyear1);
    tarih2 = DateFormat('yyyy-MM-dd').format(thisyear2);
  }

  if(tarih == 'Tümü'||tarih=='')
  {
    tarih1 = '1970-01-01';
    tarih2 = DateFormat('yyyy-MM-dd').format(now);
  }
  if(odemeyontemi =='Nakit'){
    odeme = '1';
  }

  if(odemeyontemi=='Kredi Kartı')
    odeme = '2';
  if(odemeyontemi=='Havale/EFT')
    odeme = '3';
  Map<String, dynamic> formData = {
    'tarih1': tarih1,
    'tarih2': tarih2,
    'odemeyontemi':odeme
    // Add other form fields
  };

  log('odeme id'+ odeme);
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/tahsilatraporu/'+Salonid+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Tahsilat satışlar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}
Future <Map<String, dynamic>> masrafraporu(String Salonid , String currpage,String tarih,String odemeyontemi,String harcayan) async {

  String tarih1= '';
  String tarih2='';
  String odeme = '';
  final now = new DateTime.now();
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final thismonth1 = DateTime.utc(now.year,now.month,1);
  final thismonth2 = DateTime.utc(now.year,now.month + 1,0);
  final lastmonth1 = DateTime.utc(now.year,now.month - 1,1);
  final lastmonth2 = DateTime.utc(now.year,now.month -2,0);
  final thisyear1 = DateTime.utc(now.year,1 ,1);
  final thisyear2 = DateTime.utc(now.year,12,31);


  if(tarih == 'Bugün')
  {
    tarih1 = DateFormat('yyyy-MM-dd').format(now);
    tarih2 = DateFormat('yyyy-MM-dd').format(now);
  }
  if(tarih == 'Dün') {
    tarih1 = DateFormat('yyyy-MM-dd').format(yesterday);
    tarih2 = DateFormat('yyyy-MM-dd').format(yesterday);
  }
  if(tarih == 'Bu ay') {
    tarih1 = DateFormat('yyyy-MM-dd').format(thismonth1);
    tarih2 = DateFormat('yyyy-MM-dd').format(thismonth2);
  }
  if(tarih == 'Geçen ay') {
    tarih1 = DateFormat('yyyy-MM-dd').format(lastmonth1);
    tarih2 = DateFormat('yyyy-MM-dd').format(lastmonth2);
  }
  if(tarih == 'Bu yıl') {
    tarih1 = DateFormat('yyyy-MM-dd').format(thisyear1);
    tarih2 = DateFormat('yyyy-MM-dd').format(thisyear2);
  }

  if(tarih == 'Tümü'||tarih=='')
  {
    tarih1 = '1970-01-01';
    tarih2 = DateFormat('yyyy-MM-dd').format(now);
  }
  if(odemeyontemi =='Nakit'){
    odeme = '1';
  }

  if(odemeyontemi=='Kredi Kartı')
    odeme = '2';
  if(odemeyontemi=='Havale/EFT')
    odeme = '3';

  Map<String, dynamic> formData = {
    'tarih1': tarih1,
    'tarih2': tarih2,
    'odemeyontemi':odeme,
    'harcayan':harcayan,
    // Add other form fields
  };


  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/masrafraporu/'+Salonid+'?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Masraflar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}

Future <Map<String, dynamic>> kasaraporu(String Salonid , String tarih,String odemeyontemi) async {



  String tarih1= '';
  String tarih2='';
  String odeme = '';
  final now = new DateTime.now();
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final thismonth1 = DateTime.utc(now.year,now.month,1);
  final thismonth2 = DateTime.utc(now.year,now.month + 1,0);
  final lastmonth1 = DateTime.utc(now.year,now.month - 1,1);
  final lastmonth2 = DateTime.utc(now.year,now.month -2,0);
  final thisyear1 = DateTime.utc(now.year,1 ,1);
  final thisyear2 = DateTime.utc(now.year,12,31);


  if(tarih == 'Bugün')
  {
    tarih1 = DateFormat('yyyy-MM-dd').format(now);
    tarih2 = DateFormat('yyyy-MM-dd').format(now);
  }
  if(tarih == 'Dün') {
    tarih1 = DateFormat('yyyy-MM-dd').format(yesterday);
    tarih2 = DateFormat('yyyy-MM-dd').format(yesterday);
  }
  if(tarih == 'Bu ay') {
    tarih1 = DateFormat('yyyy-MM-dd').format(thismonth1);
    tarih2 = DateFormat('yyyy-MM-dd').format(thismonth2);
  }
  if(tarih == 'Geçen ay') {
    tarih1 = DateFormat('yyyy-MM-dd').format(lastmonth1);
    tarih2 = DateFormat('yyyy-MM-dd').format(lastmonth2);
  }
  if(tarih == 'Bu yıl') {
    tarih1 = DateFormat('yyyy-MM-dd').format(thisyear1);
    tarih2 = DateFormat('yyyy-MM-dd').format(thisyear2);
  }

  if(tarih == 'Tümü'||tarih=='')
  {
    tarih1 = '1970-01-01';
    tarih2 = DateFormat('yyyy-MM-dd').format(now);
  }
  if(odemeyontemi =='Nakit'){
    odeme = '1';
  }

  if(odemeyontemi=='Kredi Kartı')
    odeme = '2';
  if(odemeyontemi=='Havale/EFT')
    odeme = '3';
  Map<String, dynamic> formData = {
    'tarih1': tarih1,
    'tarih2': tarih2,
    'odemeyontemi':odeme
    // Add other form fields
  };


  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/kasaraporu/'+Salonid),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Kasa. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}

// backend.dart dosyasına ekleyin

Future<Map<String, dynamic>> devredenAylar(String salonId, int year) async {
  Map<String, dynamic> formData = {
    'salonId': salonId,
    'yil': year,

    // Add other form fields
  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/devredenAylar'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),

  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Devreden aylar yüklenirken hata oluştu: ${response.reasonPhrase}');
  }
}



void logout(BuildContext context) async {
  try {
    // Show a confirmation dialog
    bool? confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkış Yap'),
        content: Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Evet'),
          ),
        ],
      ),
    );

    // If the user confirms logout
    if (confirmLogout == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('token');
      await prefs.remove('user_type');
      // Replace the current route with the login page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => OnBoardingPage()),
            (Route<dynamic> route) => false,
      );
    }
  } catch (e) {
    // Handle errors if needed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
    );
  }
}

Future <Map<String, dynamic>> seanslarigetir(String Salonid , String currpage,String arama,String musteri_id,BuildContext context,bool musteriMi) async {

  showProgressLoading(context);
  Map<String, dynamic> formData = {
    'arama': arama,
    'musteri_id':musteri_id,
    'salonId':Salonid,
    'appBundle':await appBundleAl(),
    'musteriMi':musteriMi,

    // Add other form fields
  };


  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/seanslar?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    Navigator.of(context,rootNavigator: true).pop();
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Seanslar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");

    return  json.decode(response.body);

  } else {
    Navigator.of(context,rootNavigator: true).pop();
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}
Future<dynamic>fetchRandevular(String seciliisletme,String personelid,String tarih1, String tarih2,bool yukleniyor,BuildContext context ,String takvimTuru) async {
  if(yukleniyor)
    showProgressLoading(context);
  Map<String, dynamic> formData = {
    'personel_id': personelid,
    'tarih1': tarih1,
    'tarih2': tarih2,
    'takvim_turu':takvimTuru,

    // Add other form fields
  };
  log('randevu personel id '+personelid);
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevular/'+seciliisletme+'/0'),


    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if(yukleniyor)
    Navigator.of(context,rootNavigator: true).pop();
  if (response.statusCode == 200) {
    log("randevudata "+response.body);
    return json.decode(response.body);
  }
  else
  {
    debugPrint(response.body);
    throw Exception('Failed to load appointments');
  }
}

Future<List<Appointment>> fetchAppointments(String seciliisletme) async {
  final response = await http.get(Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevular/'+seciliisletme+'/0'));

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    log("takvim açılıyor");
    final List<dynamic> data = json.decode(response.body);


    return data.map<Appointment>((item) {
      return Appointment(
        startTime: DateTime.parse(item['start']),
        endTime: DateTime.parse(item['end']),
        subject: item['title'],
        id: item['id'],
        color: Color(int.parse(item['bgcolor'])),
        resourceIds: [item['resourceId']],
        notes: item["notes"],
        location: item["durum"].toString(),
        recurrenceId: item["ongorusmeid"].toString(),

      );
    }).toList();
  } else {
    throw Exception('Failed to load appointments');
  }
}
Future<List<CalendarResource>> fetchResources(String seciliisletme) async {
  final response = await http.get(Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevular/'+seciliisletme+'/1'));
  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("takvim kaynak. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    final List<dynamic> data = json.decode(response.body);

    return data.map<CalendarResource>((item) {

      return CalendarResource(
        displayName: item['name'],
        id: item['id'],
        color: Color(int.parse(item['bgcolor'])),
        image: NetworkImage('https://app.randevumcepte.com.tr' + item["avatar"]),
      );
    }).toList();
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception('Failed to load resources');
  }
}

Future<List<Randevu>> tumrandevular(seciliisletme) async {
  final response = await http.get(Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevular/'+seciliisletme+'/2'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];
    logyaz2("tüm randevular. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return data.map((e) => Randevu.fromJson(e)).toList();

  } else {
    throw Exception('Failed to load appointments');
  }
}
void randevuonayla(String randevuid, BuildContext context) async {
  showProgressLoading(context);
  TextEditingController dogrulama_kodu = TextEditingController();

  Map<String, dynamic> formData = {
    'randevuid': randevuid,

    // Add other form fields
  };


  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevuonayla'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Randevu onayla. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    Navigator.of(context,rootNavigator: true).pop();


  } else {
    Navigator.of(context,rootNavigator: true).pop();
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}
Future<void> randevugelmediisaretle(String randevuid, BuildContext context) async {
  showProgressLoading(context);
  TextEditingController dogrulama_kodu = TextEditingController();
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);

  Map<String, dynamic> formData = {
    'randevuid': randevuid,
    'user':user["id"]
    // Add other form fields
  };


  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevuyagelmediisaretle'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Gelmedi işaretle. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    Navigator.of(context,rootNavigator: true).pop();


  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    Navigator.of(context,rootNavigator: true).pop();
    throw Exception(response.reasonPhrase);
  }

}
Future<void> randevuiptalet(String randevuid, BuildContext context,String usertype) async {
  showProgressLoading(context);

  String durum='';
  if(usertype=="0")
    durum='3';
  else
    durum='2';
  log('user type '+usertype);
  Map<String, dynamic> formData = {
    'randevuid': randevuid,
    'durum':durum
    // Add other form fields
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevuiptalet'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    Navigator.of(context).pop();
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("randevu iptal. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
  } else {
    debugPrint(response.body);
    if (context.mounted) {
      Navigator.of(context).pop(); // Close the progress dialog
      showErrorDialog(context, response.reasonPhrase);
    }
  }
}
void showErrorDialog(BuildContext context, String? message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Error'),
        content: Text(message ?? 'Unknown error'),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<int> randevuGeldiGelmediIsaretiKaldir(
    String randevuid,

    BuildContext context,

    ) async {
  showProgressLoading(context);
  Map<String, dynamic> formData = {
    'randevuid': randevuid,

  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevuGeldiGelmediIsaretiKaldir'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    if (!context.mounted) return 0;
    Navigator.of(context).pop();
    log('işaret kaldır sonucu '+response.body);
    return response.statusCode;




  } else {
    log("işaret kaldır sonucu "+response.body);
    logyaz(response.statusCode, response.reasonPhrase);
    return -1;
  }
}



Future<void> randevugeldiisaretle(
    String randevuid,
    String dogrulamakodu2,
    BuildContext context,
    String onayKodu2,
    ) async {
  showProgressLoading(context);

  log("doğrulama kodu: $dogrulamakodu2, onay kodu: $onayKodu2");

  Map<String, dynamic> formData = {
    'randevuid': randevuid,
    'dogrulama_kodu': dogrulamakodu2,
    'kvkkKodu': onayKodu2,
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevugeldiisaretle'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    if (!context.mounted) return;
    Navigator.of(context).pop();

    dynamic result = json.decode(response.body);
    log("randevu result: $result");

    String dogrulamaKodu = dogrulamakodu2;
    String onayKodu = onayKodu2;
    log('popup çıkacak mı '+result["hatali"]);
    // 1️⃣ Doğrulama popup'ı
    if ((result["hatali"].toString() == "2" || result["hatali"].toString() == "1") && dogrulamaKodu.isEmpty) {
      final popupKod = await randevudogrulamapopup(
        result,
        TextEditingController(),
        context,
        randevuid,
        TextEditingController(),
      );

      if (popupKod != null && popupKod.isNotEmpty) {
        dogrulamaKodu = popupKod;

        if (!context.mounted) return;
        // recursive çağrı, KVKK kodu zaten varsa geçecek
        await randevugeldiisaretle(randevuid, dogrulamaKodu, context, onayKodu);
        return; // recursive çağrı sonrası devam etme
      }
    }

    // 2️⃣ KVKK popup'ı
    if (result["hatali"] == "3" && onayKodu.isEmpty) {
      final popupOnay = await kvkkPopup(
        result,
        TextEditingController(),
        context,
        randevuid,
        TextEditingController(),
      );

      if (popupOnay != null && popupOnay.isNotEmpty) {
        onayKodu = popupOnay;

        if (!context.mounted) return;
        // recursive çağrı, doğrulama kodu zaten varsa geçecek
        await randevugeldiisaretle(randevuid, dogrulamaKodu, context, onayKodu);
        return; // recursive çağrı sonrası devam etme
      }
    }

    // 3️⃣ Başarılı veya hatalı durumlar artık popup'lar tamamlandıktan sonra buraya gelir
    if (result["hatali"] == "0") {
      log("Randevu başarıyla işaretlendi.");
    }

  } else {
    logyaz(response.statusCode, response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}

// Doğrulama popup'ı
Future<String?> randevudogrulamapopup(
    var result,
    TextEditingController dogrulama_kodu,
    BuildContext context,
    String randevuid,
    TextEditingController onayKodu,
    ) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context2) {
      return AlertDialog(
        title: const Text('RANDEVU DOĞRULAMA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result["mesaj"]),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.number,
              controller: dogrulama_kodu,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                hintText: 'Doğrulama kodu..',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('VAZGEÇ'),
            onPressed: () {
              Navigator.of(context2).pop(''); // boş dönüyor, recursive çağrı tetiklenmez
            },
          ),
          TextButton(
            child: const Text('GÖNDER'),
            onPressed: () {
              if (dogrulama_kodu.text.isNotEmpty) {
                Navigator.of(context2).pop(dogrulama_kodu.text); // doğru kodu döndür
              }
            },
          ),
        ],
      );
    },
  );
}

// KVKK popup'ı
Future<String?> kvkkPopup(
    var result,
    TextEditingController dogrulama_kodu,
    BuildContext context,
    String randevuid,
    TextEditingController onayKodu,
    ) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context2) {
      return AlertDialog(
        title: const Text('UYARI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Müşteri bilgilerini sisteme kaydetmeden önce verilerinin işlenmesine ve kayıtlı iletişim adresleri üzerinden SMS, e-posta ve aramalar vasıtasıyla ticari elektronik ileti gönderimine izin verdiğine dair cep telefonuna gönderilen onay kodunu girmeniz gerekmektedir."),
            const SizedBox(height: 16),
            TextFormField(
              controller: onayKodu,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                hintText: 'Onay kodu..',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('VAZGEÇ'),
            onPressed: () {
              Navigator.of(context2).pop(''); // boş dönüyor, recursive çağrı tetiklenmez
            },
          ),
          TextButton(
            child: const Text('GÖNDER'),
            onPressed: () {
              if (onayKodu.text.isNotEmpty) {
                Navigator.of(context2).pop(onayKodu.text); // doğru kodu döndür
              }
            },
          ),
        ],
      );
    },
  );
}
Future<AdisyonPaket> adisyonpaketekle(AdisyonPaket paket,String musteriid,BuildContext context,String salonid,String seanssaati, bool showprogress,String senetid) async{
  if(showprogress)
    showProgressLoading(context);

  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);

  Map<String, dynamic> formData = {
    'adisyon_id':paket.adisyon_id,
    'adisyon_paket_id':paket.id,
    'paketid' : paket.paket_id,
    'paket_satis_tarihi':DateFormat('yyyy-MM-dd').format(DateTime.now()),
    'paketbaslangictarihi':paket.baslangic_tarihi,
    'seansaralikgun':paket.seans_araligi,
    'paketfiyat':paket.fiyat,
    'personel_id':paket.personel_id,
    'paket_satis_seans_saati':seanssaati,
    'musteri_id':musteriid,
    'sube':salonid,
    'olusturan':user["id"],
    'senet_id':senetid

  };
  log(json.encode(formData));
  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/adisyonpaketekle"),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200 || response.statusCode==201) {
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("adisyon paket ekle. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    final jsonResponse = json.decode(response.body);


    return  AdisyonPaket.fromJson(jsonResponse);

  } else {
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();
    debugPrint(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paket satışı eklenirken bir hata oluştu. Hata kodu : '+response.statusCode.toString()),
      ),
    );
    throw Exception('Failed to load resources');
  }
}
Future<Map<String, dynamic>> senetvetaksitler(String salonid, String musteriid,String adisyonId) async{
  late String tur;
  Map<String, dynamic> formData = {
    'musteri_id': musteriid,
    'salon_id' : salonid,
    'adisyon_id': adisyonId,

  };
  log('tahsilat verisi '+jsonEncode(formData));
  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/tum-alacaklar"),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Tüm alacaklar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    return json.decode(response.body);
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception('Failed to load resources');
  }
}
Future <int> taksitekleguncelle(BuildContext context, String Salonid,List<AdisyonKalemleri> adisyonkalemleri,String taksitsayisi,String ilkodemetarih,String toplamtutar,String musteridanisan,String musteriindirimi,String odemeyontemi,String odenentutar,String tahsilattarihi,String notlar,String hariciindirim) async {
  showProgressLoading(context);
  log("kalem sayısı "+adisyonkalemleri.length.toString());

  List<AdisyonHizmet> adisyonhizmetleri = [];
  List<AdisyonUrun> adisyonurunleri = [];
  List<AdisyonPaket> adisyonpaketleri = [];
  List<SenetVade>senetvadeleri = [];
  List<TaksitVade>taksitvadeleri = [];
  List<String>adisyonhizmetidler = [];
  List<String>adisyonurunidler = [];
  List<String>adisyonpaketidler = [];


  log("kalem sayısı "+adisyonkalemleri.length.toString());
  adisyonkalemleri.forEach((element) {
    log("eleman türü "+element.toString());
    if(element is AdisyonHizmet){
      adisyonhizmetleri.add(element);
      adisyonhizmetidler.add(element.id);
    }

    if(element is AdisyonUrun){
      adisyonurunleri.add(element);
      adisyonurunidler.add(element.id);
    }

    if(element is AdisyonPaket){
      adisyonpaketleri.add(element);
      adisyonpaketidler.add(element.id);
    }

    if(element is SenetVade){
      senetvadeleri.add(element);

    }

    if(element is TaksitVade){
      taksitvadeleri.add(element);
    }

  });
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'tahsilat_musteri_id':musteridanisan,
    'sube': Salonid,
    'vade_baslangic_tarihi':ilkodemetarih,
    'taksit_tutar':toplamtutar,
    'vade':taksitsayisi,
    'adisyon_hizmetleri':adisyonhizmetleri,
    'adisyon_paketleri':adisyonpaketleri,
    'adisyon_urunleri':adisyonurunleri,
    'senet_vadeleri':senetvadeleri,
    'taksit_vadeleri':taksitvadeleri,
    'olusturan':user['id'],
    'musteri_indirimi':musteriindirimi,
    'indirim_tutari':hariciindirim,
    'adisyon_hizmet_id':adisyonhizmetidler,
    'adisyon_urun_id':adisyonurunidler,
    'adisyon_paket_id':adisyonpaketidler,
    'odeme_yontemi':odemeyontemi,
    'indirimli_toplam_tahsilat_tutari':odenentutar,
    'tahsilat_tarihi':tahsilattarihi,
    'tahsilat_notlari':notlar,
    // Add other form fields
  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/taksitekleguncelle'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  return response.statusCode;
  /**/

}

Future <String> tahsilet(BuildContext context, String Salonid,List<AdisyonKalemleri> adisyonkalemleri,String taksitsayisi,String ilkodemetarih,String toplamtutar,String musteridanisan,String musteriindirimi,String odemeyontemi,String odenentutar,String tahsilattarihi,String notlar,String hariciindirim) async {
  showProgressLoading(context);


  List<AdisyonHizmet> adisyonhizmetleri = [];
  List<AdisyonUrun> adisyonurunleri = [];
  List<AdisyonPaket> adisyonpaketleri = [];
  List<SenetVade>senetvadeleri = [];
  List<TaksitVade>taksitvadeleri = [];
  List<String>adisyonhizmetidler = [];
  List<String>adisyonurunidler = [];
  List<String>adisyonpaketidler = [];
  List<String>adisyonsenetidler = [];
  List<String>adisyontaksitidler = [];

  adisyonkalemleri.forEach((element) {
    log("eleman türü "+element.toString());
    if(element is AdisyonHizmet){
      adisyonhizmetleri.add(element);
      adisyonhizmetidler.add(element.id);
    }

    if(element is AdisyonUrun){
      adisyonurunleri.add(element);

      adisyonurunidler.add(element.id);
    }

    if(element is AdisyonPaket){
      adisyonpaketleri.add(element);
      adisyonpaketidler.add(element.id);
    }

    if(element is SenetVade){
      senetvadeleri.add(element);
      adisyonsenetidler.add(element.id);
    }

    if(element is TaksitVade){
      taksitvadeleri.add(element);
      adisyontaksitidler.add(element.id);
    }

  });
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'ad_soyad':musteridanisan,
    'sube': Salonid,
    'vade_baslangic_tarihi':ilkodemetarih,
    'taksit_tutar':toplamtutar,
    'vade':taksitsayisi,
    'adisyon_hizmetleri':adisyonhizmetleri,
    'adisyon_paketleri':adisyonpaketleri,
    'adisyon_urunleri':adisyonurunleri,
    'senet_vadeleri':senetvadeleri,
    'taksit_vadeleri':taksitvadeleri,
    'olusturan':user['id'],
    'musteri_indirimi':musteriindirimi,
    'indirim_tutari':hariciindirim,
    'adisyon_hizmet_id':adisyonhizmetidler,
    'adisyon_urun_id':adisyonurunidler,
    'adisyon_paket_id':adisyonpaketidler,
    'odeme_yontemi':odemeyontemi,
    'indirimli_toplam_tahsilat_tutari':odenentutar,
    'tahsilat_tarihi':tahsilattarihi,
    'tahsilat_notlari':notlar,
    'senet_vade_id':adisyonsenetidler,
    'taksit_vade_id':adisyontaksitidler,
    // Add other form fields
  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/tahsilatekle'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Taksit ekle. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    Navigator.of(context,rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tahsilat başarıyla kaydedildi'),
      ),
    );
    debugPrint("sonuç "+response.body);
    return  response.body;

  } else {
    Navigator.of(context,rootNavigator: true).pop();
    debugPrint(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tahsilat işlenirken bir hata oluştu. Hata kodu : '+response.statusCode.toString()),
      ),
    );
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}

Future <String> senetolustur(BuildContext context, String Salonid,List<AdisyonKalemleri> adisyonkalemleri,String vadesayisi,String vadebaslangictarihi,String senettutari,String musteridanisan,String onodemetutari,String onodemeyontemi,String musteritc
    ,String musteriadres,String kefiladsoyad,String kefiltc, String kefiladres,String senetturu) async {
  showProgressLoading(context);


  List<AdisyonHizmet> adisyonhizmetleri = [];
  List<AdisyonUrun> adisyonurunleri = [];
  List<AdisyonPaket> adisyonpaketleri = [];
  List<SenetVade>senetvadeleri = [];
  List<TaksitVade>taksitvadeleri = [];
  List<String>adisyonhizmetidler = [];
  List<String>adisyonurunidler = [];
  List<String>adisyonpaketidler = [];


  adisyonkalemleri.forEach((element) {
    log("eleman türü "+element.toString());
    if(element is AdisyonHizmet){
      adisyonhizmetleri.add(element);
      adisyonhizmetidler.add(element.hizmet_id);
    }

    if(element is AdisyonUrun){
      adisyonurunleri.add(element);

      adisyonurunidler.add(element.urun_id);
    }

    if(element is AdisyonPaket){
      adisyonpaketleri.add(element);
      adisyonpaketidler.add(element.paket_id);
    }



  });
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  adisyonpaketidler.forEach((element) {

    log("adisyon paketleri "+element);
  });

  Map<String, dynamic> formData = {
    'musteri_id':musteridanisan,
    'sube': Salonid,
    'vade_baslangic_tarihi':vadebaslangictarihi,
    'senet_tutar':senettutari,
    'vade':vadesayisi,
    'senet_hizmetleri':adisyonhizmetleri,
    'senet_paketleri':adisyonpaketleri,
    'senet_urunleri':adisyonurunleri,
    'senet_vadeleri':senetvadeleri,
    'taksit_vadeleri':taksitvadeleri,
    'olusturan':user['id'],
    'senet_turu' : senetturu,
    'senet_hizmet_id':adisyonhizmetidler,
    'senet_urun_id':adisyonurunidler,
    'senet_paket_id':adisyonpaketidler,
    'on_odeme_yontemi':onodemeyontemi,
    'on_odeme_tutari':onodemetutari,
    'tc_kimlik_no': musteritc,
    'adres':musteriadres,
    'kefil_adi':kefiladsoyad,
    'kefil_tc_vergi_no':kefiltc,
    'kefil_adres':kefiladres,





    // Add other form fields
  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/senetekleguncelle'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Senet ekle. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    Navigator.of(context,rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Senet başarıyla kaydedildi'),
      ),
    );
    debugPrint("sonuç "+response.body);
    return  response.body;

  } else {
    Navigator.of(context,rootNavigator: true).pop();
    debugPrint(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tahsilat işlenirken bir hata oluştu. Hata kodu : '+response.statusCode.toString()),
      ),
    );
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}



Future<AdisyonHizmet> adisyonhizmetekle(AdisyonHizmet hizmet,String musteriid,BuildContext context,String salonid) async{
  showProgressLoading(context);

  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  log("adisyonideklemeguncelleme : " + hizmet.adisyon_id);
  Map<String, dynamic> formData = {
    'adisyon_id':hizmet.adisyon_id,
    'adisyon_hizmet_id':hizmet.id,
    'adisyonhizmetleriyeni' : hizmet.hizmet_id,
    'islemtarihiyeni':hizmet.islem_tarihi,
    'islemsaatiyeni':hizmet.islem_saati,
    'adisyonhizmetsuresi':hizmet.sure,
    'adisyonhizmetfiyati':hizmet.fiyat,
    'adisyonhizmetpersonelleriyeni':hizmet.personel_id,
    'musteri_id':musteriid,
    'sube':salonid,
    'olusturan':user["id"]

  };
  log(json.encode(formData));
  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/adisyonhizmetekle"),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200 || response.statusCode==201) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Adisyon hizmet ekle. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    Navigator.of(context, rootNavigator: true).pop();

    final jsonResponse = json.decode(response.body);
    return  AdisyonHizmet.fromJson(jsonResponse);

  } else {
    Navigator.of(context, rootNavigator: true).pop();
    debugPrint(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hizmet satışı eklenirken bir hata oluştu. Hata kodu : '+response.statusCode.toString()),
      ),
    );
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception('Failed to load resources');
  }
}
Future<AdisyonUrun> adisyonurunekle(AdisyonUrun urun,String musteriid,BuildContext context,String salonid,bool showprogress) async{
  if(showprogress)
    showProgressLoading(context);

  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);

  Map<String, dynamic> formData = {
    'adisyon_id':urun.adisyon_id,
    'adisyon_urun_id':urun.id,
    'urunyeni' : urun.urun_id,
    'urun_satis_tarihi':urun.islem_tarihi,

    'urun_adedi':urun.adet,
    'urun_fiyati':urun.fiyat,
    'urun_satici':urun.personel_id,
    'musteri_id':musteriid,
    'sube':salonid,
    'olusturan':user["id"]

  };
  log(json.encode(formData));
  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/adisyonurunekle"),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200 || response.statusCode==201) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Adisyon ürün ekle. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();

    final jsonResponse = json.decode(response.body);


    return  AdisyonUrun.fromJson(jsonResponse);

  } else {
    if(showprogress)
      Navigator.of(context, rootNavigator: true).pop();
    debugPrint(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ürün satışı eklenirken bir hata oluştu. Hata kodu : '+response.statusCode.toString()),
      ),
    );
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception('Failed to load resources');
  }
}

Future<dynamic> adisyonhizmetsil(AdisyonHizmet hizmet,BuildContext context) async{
  showProgressLoading(context);


  Map<String, dynamic> formData = {
    'hizmet_id':hizmet.id,


  };
  log(json.encode(formData));
  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/tahsilat-hizmet-sil"),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200 || response.statusCode==201) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Tahislat hizmet sil. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    Navigator.of(context,rootNavigator: true).pop();

    dynamic result = json.decode(response.body);


    return  json.decode(response.body);

  } else {
    Navigator.of(context,rootNavigator: true).pop();
    return json.decode("{'basarili':'0','mesaj': 'Hizmet satışı kaldırılırken bir hata oluştu. Hata Kodu : '"+response.statusCode.toString()+"'}");
    throw Exception('Failed to load resources');
  }
}

Future<dynamic> adisyonurunsil(AdisyonUrun urun,BuildContext context) async{
  showProgressLoading(context);
  Map<String, dynamic> formData = {
    'adisyonurunid':urun.id,
  };
  log(json.encode(formData));
  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/tahsilat-urun-sil"),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200 || response.statusCode==201) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Tahsilat ürün sil. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    Navigator.of(context,rootNavigator: true).pop();
    return  json.decode(response.body);

  } else {
    Navigator.of(context,rootNavigator: true).pop();
    return json.decode('{"basarili":"0","mesaj": "Ürün satışı kaldırılırken bir hata oluştu. Hata Kodu : '+response.statusCode.toString()+'"}');
    throw Exception('Failed to load resources');
  }
}
Future<dynamic> adisyonpaketsil(AdisyonPaket paket,BuildContext context) async{
  showProgressLoading(context);
  Map<String, dynamic> formData = {
    'adisyonpaketid':paket.id,
  };
  log(json.encode(formData));
  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/tahsilat-paket-sil"),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200 || response.statusCode==201) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Tahsilat paket sil. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    Navigator.of(context,rootNavigator: true).pop();
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    Navigator.of(context,rootNavigator: true).pop();

    return json.decode('{"basarili":"0","mesaj": "Paket satışı kaldırılırken bir hata oluştu. Hata Kodu : '+response.statusCode.toString()+'"}');

    throw Exception('Failed to load resources');
  }
}

Future <List<Urun>> urun_liste(String Salonid) async {


  Map<String, dynamic> formData = {
    'salon_id': Salonid,

  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/urunler'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Ürün liste. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    debugPrint(response.body);
    List jsonResponse = json.decode(response.body);

    return jsonResponse.map((e) => Urun.fromJson(e)).toList();


  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    debugPrint(response.body);
    throw Exception(response.reasonPhrase);
  }

}

Future <List<Paket>> paket_liste(String Salonid) async {


  Map<String, dynamic> formData = {
    'salon_id': Salonid,

  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/paketler'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Paket liste. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    debugPrint(response.body);
    List jsonResponse = json.decode(response.body);

    return jsonResponse.map((e) => Paket.fromJson(e)).toList();


  } else {

    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }

}
Future<String> musteriDanisanTuru(String salonid, String musteriid) async{
  late String tur;
  Map<String, dynamic> formData = {
    'musteri_id': musteriid,
    'salon_id' : salonid,

  };
  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/musteri-danisan-turunu-getir"),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200) { var rateLimit = response.headers['x-ratelimit-limit'];
  var remaining = response.headers['x-ratelimit-remaining'];
  var reset = response.headers['x-ratelimit-reset'];

  print("Rate Limit: $rateLimit");
  print("Requests Remaining: $remaining");
  print("Rate Limit Reset Time: $reset");
  logyaz2("Müşteri türü. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
  tur = response.body;

  return tur;
  } else {

    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception('Failed to load resources');
  }
}

Future<Map<String, dynamic>> satislar(String Salonid , String currpage,String tarih1,String tarih2,String musteriid,String tur,String personel_id,bool musteriMi,String user_id,int acikKapali) async {


  Map<String, dynamic> formData = {
    'salonid': Salonid,
    'tarih1':tarih1,
    'tarih2':tarih2,
    'musteriid':musteriid,
    'adisyonturu':tur,
    'personel_id': personel_id,
    'musteriMi': musteriMi,
    'user_id':user_id,
    'appBundle':await appBundleAl(),
    'acikKapali':acikKapali
    // Add other form fields
  };

  log('satış data filter '+jsonEncode(formData));
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/satislar?page='+currpage.toString()),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  log('satış verisi '+response.body);
  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Satışlar. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    log("Adisyon Datası "+response.body.toString());
    return  json.decode(response.body);

  } else {
    logyaz(response.statusCode,response.reasonPhrase);

    throw Exception(response.reasonPhrase);
  }

}
void launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Could not launch $url';
  }
}
void logyaz(int statusCode, String? reasonPhrase) async {

  Map<String, dynamic> formData = {
    'aciklama': "Loglama : " + statusCode.toString() + " : " + (reasonPhrase ?? 'No reason available'),
  };

  final response = await http.get(
    Uri.parse("https://nifty-lamport.92-205-164-182.plesk.page/writelog.php?aciklama2=&aciklama=Bir hata oluştu : " + statusCode.toString() + " : " + (reasonPhrase ?? 'No reason available')),
    headers: {'Content-Type': 'application/json'},

  );
  if (response.statusCode == 200) {


    debugPrint("log yazdırıldı");

  } else {

    debugPrint("log yazdırılamadı : "+response.body);

  }
}


void logyaz2(String logstr) async {
  log("istek logu yazılıyor : "+logstr);
  final logstr2 = Uri.encodeComponent(logstr);
  log("https://nifty-lamport.92-205-164-182.plesk.page/writelog.php?aciklama=&aciklama2="+logstr2);
  final response = await http.get(

    Uri.parse("https://nifty-lamport.92-205-164-182.plesk.page/writelog.php?aciklama=&aciklama2="+logstr2),
    headers: {'Content-Type': 'application/json'},

  );
  if (response.statusCode == 200) {


    debugPrint("log yazdırıldı");

  } else {

    debugPrint("log yazdırılamadı : "+response.body);

  }
}
Future<void> randevuEkleGuncelle(
    String cakismavarmi,
    String cakisanrandevuekle, // Bu parametreyi String yap
    String randevuid,
    MusteriDanisan secilimusteridanisan,
    String randevutarihi,
    String randevusaati,
    List<RandevuHizmet> randevuhizmetleri,
    List<RandevuHizmetYardimciPersonelleri> yardimcipersoneller,
    bool tekrarlayan,
    String tekrarsayisi,
    String? siklik,
    String notlar,
    String salonid,
    BuildContext context,
    String kaynak,
    String durum,
    dynamic isletmebilgi,
    ) async {
  showProgressLoading(context);
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  log('randevu hizmet data ' + jsonEncode(randevuhizmetleri));
  var user = jsonDecode(localStorage.getString('user')!);

  Map<String, dynamic> formData = {
    'randevu_id': randevuid,
    'user_id': secilimusteridanisan.id,
    'randevu_tarihi': randevutarihi,
    'randevu_saati': randevusaati,
    'hizmetler': randevuhizmetleri,
    'yardimcipersoneller': yardimcipersoneller,
    'tekrarlayan': tekrarlayan,
    'tekrar_sayisi': tekrarsayisi,
    'tekrar_sikligi': siklik,
    'notlar': notlar,
    'salonid': salonid,
    'cakisma_varmi': cakismavarmi,
    'cakisanrandevuekle': cakisanrandevuekle, // Burada string olarak gönder
    'olusturan': kaynak == 'salon' ? user["id"] : null,
    'olusturanMusteri': kaynak == 'uygulama' ? secilimusteridanisan.id : null,
    'randevuKaynak': kaynak,
    'durum': durum,
    'appBundle': await appBundleAl(),
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevuekleguncelle'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var result = json.decode(response.body);
    if (result["cakismavar"] == "1") {
      Navigator.of(context, rootNavigator: true).pop();

      // EĞER cakisanrandevuekle zaten "1" ise (yani kullanıcı daha önce "Yine de oluştur" dediyse)
      // tekrar sorma, direkt olarak "yine de oluştur" modunda çağır
      if (cakisanrandevuekle == "1") {
        // Zaten "yine de oluştur" modundayız, bu yüzden tekrar recursive çağırma
        // Bu durumda işlemi iptal et ve hata mesajı göster
        showDialog<bool>(
          context: context,
          builder: (BuildContext context2) {
            return AlertDialog(
              title: Text('HATA'),
              content: Text('Randevu oluşturulamadı. Lütfen farklı bir tarih/saat deneyin.'),
              actions: <Widget>[
                TextButton(
                  child: Text('TAMAM'),
                  onPressed: () {
                    Navigator.of(context2).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        // İlk kez çakışma tespit edildi, kullanıcıya sor
        showDialog<bool>(
          context: context,
          builder: (BuildContext context2) {
            return AlertDialog(
              title: Text('UYARI'),
              content: Text('Oluşturduğunuz randevu aşağıdakilerle çakışmaktadır!\n\n' +
                  result["cakisanunsurlar"].replaceAll(r'\n', '\n')),
              actions: <Widget>[
                TextButton(
                  child: Text('VAZGEÇ'),
                  onPressed: () {
                    Navigator.of(context2).pop();
                  },
                ),
                TextButton(
                  child: Text('YİNE DE RANDEVUYU OLUŞTUR'),
                  onPressed: () {
                    Navigator.of(context2).pop();
                    // Recursive çağrıda cakisanrandevuekle = "1" olarak gönder
                    randevuEkleGuncelle(
                      '1', // cakismavarmi
                      '1', // cakisanrandevuekle - ARTIK "1" olarak gönder
                      randevuid,
                      secilimusteridanisan,
                      randevutarihi,
                      randevusaati,
                      randevuhizmetleri,
                      yardimcipersoneller,
                      tekrarlayan,
                      tekrarsayisi,
                      siklik,
                      notlar,
                      salonid,
                      context,
                      kaynak,
                      durum,
                      isletmebilgi,
                    );
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      // Başarılı
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context).pop();

      if (kaynak == 'uygulama') {
        Navigator.of(context).pop();
        log('işletme bilgi');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (builder) => MusteriAltBar(
              musteriId: secilimusteridanisan,
              isletmebilgi: isletmebilgi,
              scaffoldMessengerKey: scaffoldMessengerKey,
            ),
          ),
        );
      }

      showDialog<bool>(
        context: context,
        builder: (BuildContext context2) {
          String returntext = '';
          if (durum == '0')
            returntext = 'Randevu talebiniz alınmıştır. Talebiniz kısa sürede sonuçlanacaktır. İlginiz için teşekkür ederiz!';
          else
            returntext = "Randevu başarıyla " + (randevuid != "" ? "güncellendi." : "oluşturuldu");

          return AlertDialog(
            title: Text('BAŞARILI'),
            content: Text(returntext),
            actions: <Widget>[
              TextButton(
                child: Text('TAMAM'),
                onPressed: () {
                  Navigator.of(context2).pop(true);
                },
              ),
            ],
          );
        },
      );
    }
  } else {
    debugPrint('Error: ${response.body}');
  }
}
Future<dynamic> satisyapilmadi(BuildContext context, String ongorusmeid,String aciklama,String currentPage,String aramaterimi,bool showprogress) async {


  Map<String, dynamic> formData = {
    'ongorusmeid': ongorusmeid,
    'satisyapilmamasebebi': aciklama,
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/ongorusmesatisyapilmadi'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {

    return {
      'durum': 'Başarılı',
      'currentPage': currentPage,
      'arama' : aramaterimi,
      'showprogress':showprogress,
    };

  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bir hata oluştu. Hata kodu : ' + response.statusCode.toString()),
      ),

    );
    return {
      'durum': 'Hatalı',
      'currentPage': currentPage,
      'arama' : aramaterimi,
      'showprogress':showprogress
    };


  }
}
Future<Map<String, dynamic>> personelgetir(String salonid, String currpage, String baslik) async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);

  Map<String, dynamic> formData = {
    'baslik': baslik,

    // Add other form fields
  };

  final response = await http.post(
      Uri.parse("https://app.randevumcepte.com.tr/api/v1/personelgetir/$salonid?page=$currpage"),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    // Check if response body is not empty
    if (response.body.isNotEmpty) {
      try {
        // Parse the response body
        return json.decode(response.body);
      } catch (e) {
        throw Exception('Failed to decode JSON: ${e.toString()}');
      }
    } else {
      throw Exception('Empty response from server');
    }
  } else {
    throw Exception('Failed to load data: ${response.reasonPhrase}');
  }
}
Future<List<PersonelMolaSaatleri>> fetchPersonelBreakHoursSettings(String personelid) async{

  final response = await http.get(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/personelmolasaatleri/'+personelid),

    headers: {'Content-Type': 'application/json'},

  );
  debugPrint('Response status: ${response.statusCode}');
  debugPrint('Response body: ${response.body}');

  if (response.statusCode == 200) {
    try {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => PersonelMolaSaatleri.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error decoding JSON: $e');
      throw Exception('Error parsing response');
    }
  } else {
    debugPrint('Failed to load data. Status code: ${response.statusCode}');
    throw Exception('Failed to load data: ${response.reasonPhrase}');
  }
}
Future<List<PersonelCalismaSaatleri>> fetchPersonelHoursSettings(String personelid) async {
  final int maxRetries = 5;
  int attempt = 0;

  while (attempt < maxRetries) {
    final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/personelcalismasaatleri/$personelid'),
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => PersonelCalismaSaatleri.fromJson(data)).toList();
      } catch (e) {
        debugPrint('Error decoding JSON: $e');
        throw Exception('Error parsing response');
      }
    } else if (response.statusCode == 429) {
      debugPrint('Rate limit exceeded. Attempt: ${attempt + 1} of $maxRetries');
      attempt++;
      // Optional: Check if the server suggests a delay
      await Future.delayed(Duration(seconds: 2 * attempt)); // Exponential backoff
    } else {
      debugPrint('Failed to load data. Status code: ${response.statusCode}');
      throw Exception('Failed to load data: ${response.reasonPhrase}');
    }
  }

  throw Exception('Max retries exceeded for fetching salon hours.');
}

Future <dynamic> randevudantahsilatagit(BuildContext context,String randevuid) async{
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'randevuid': randevuid,
    'olusturan':user["id"],
  };
  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/randevutahsilet"),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200) {
    return true;

  } else {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tahsilat ekranı açılırken bir hata oluştu. Hata kodu : '+response.statusCode.toString()),
      ),
    );

  }
}
Future<Map<String, dynamic>> hizmetgetir(String salonid, String currpage, String baslik) async {

  Map<String, dynamic> formData = {
    'baslik': baslik,
    // Add other form fields
  };

  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/hizmet_liste_getir/$salonid?page=$currpage"),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    // Check if response body is not empty
    if (response.body.isNotEmpty) {
      try {
        // Parse the response body
        return json.decode(response.body);
      } catch (e) {
        throw Exception('Failed to decode JSON: ${e.toString()}');
      }
    } else {
      throw Exception('Empty response from server');
    }
  } else {
    throw Exception('Failed to load data: ${response.reasonPhrase}');
  }
}
Future<List<Hizmet>> seciliolmayanhizmetgetir(String salonid) async {
  Map<String, dynamic> formData = {
    'sube': salonid,
    // Add other form fields
  };

  final response = await http.post(
    Uri.parse("https://app.randevumcepte.com.tr/api/v1/seciliolmayanhizmetlerigetir"),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    // Check if response body is not empty
    if (response.body.isNotEmpty) {
      try {
        List jsonResponse = json.decode(response.body);

        return jsonResponse.map((e) => Hizmet.fromJson(e)).toList();

      } catch (e) {
        throw Exception('Failed to decode JSON: ${e.toString()}');
      }
    } else {
      throw Exception('Empty response from server');
    }
  } else {
    throw Exception('Failed to load data: ${response.reasonPhrase}');
  }

}
Future<List<HizmetKategorisi>> hizmetkategorileri() async{
  final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/hizmetkategorileri')
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Hizmetler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    List jsonResponse = json.decode(response.body);

    return jsonResponse.map((e) => HizmetKategorisi.fromJson(e)).toList();
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
void gelenaramagoster(String bildirimkimligi) async{
  Map<String, dynamic> formData = {
    'bildirimkimligi': bildirimkimligi,
    'appid':"5e50f84e-2cd8-4532-a765-f2cb82a22ff9",
    "baslik":"Gelen Arama",
    "icerik":"ARANIYORSUNUZ",


    // Add other form fields
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/mobildegelenaramagoster'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200) {



    debugPrint("gönderildi");
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    debugPrint("gödnerilemedi");
  }
}
Future<dynamic> arayanbilgi(String telefon,String seciliisletme) async {
  Map<String, dynamic> formData = {
    'telefon': telefon,
    'sube': seciliisletme
  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/arayanmusteribilgi'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {

    return json.decode(response.body);
  } else {

    throw Exception(response.reasonPhrase);
  }
}

Future<OnGorusme> ongorsumebilgi(String ongorusmeid) async{
  Map<String, dynamic> formData = {
    'ongorusmeid': ongorusmeid,

  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/ongorusmebilgi'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200) {
    final jsonResponse = json.decode(response.body);
    return  OnGorusme.fromJson(jsonResponse);
  } else {

    throw Exception(response.reasonPhrase);
  }
}
void satisyapildi(BuildContext context, String ongorusmeid,String adet,String baslangictarih,String seansaralik) async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();

  var user = jsonDecode(localStorage.getString('user')!);

  showProgressLoading(context);
  Map<String, dynamic> formData = {
    'ongorusmeid': ongorusmeid,
    'baslangic_tarihi': baslangictarih,
    'urun_adedi': adet,
    'seans_araligi': seansaralik,
    'olusturan':user['id']
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/ongorusmesatisyapildi'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  Navigator.of(context).pop();
  if (response.statusCode == 200) {
    Navigator.of(context).pop();

  } else {

    debugPrint(response.body);
  }
}
Future<dynamic>personelprimhesapla(BuildContext context, String personelid,String salonid) async
{
  showProgressLoading(context);
  Map<String, dynamic> formData = {
    'sube': salonid,
    'personel_id': personelid,

  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/personelprimhesapla'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200) {
    Navigator.of(context).pop();
    return json.decode(response.body);

  } else {
    Navigator.of(context).pop();
    debugPrint(response.body);
  }
}
Future<MusteriDanisan> kullanicibilgimusteri(String userid) async {
  final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/kullaniciBilgiGetir/'+userid.toString())
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Kullanıcı bilgi. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    final jsonResponse = json.decode(response.body);

    return  MusteriDanisan.fromJson(jsonResponse);
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future<List<Map<String, dynamic>>> fetchCustomerAppointments(String musteriId) async {

  final String url = 'https://app.randevumcepte.com.tr/api/v1/randevularimusteri/$musteriId';
  List<String> salonidler=["114","115"];
  final response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "musteri_id": musteriId,
      'salon_id':salonidler
    }),
  );
  // Log the response status and body

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(responseData['data']);
  } else {
    throw Exception('Failed to load appointments');
  }
}
Future<void>bildirimkimligiekleguncelle(String yetkiliId,String seciliisletme,String usertype,String bildirimkimligi) async
{
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  final String appBundle = await appBundleAl(); // Önce değişkene atayın

  var user = jsonDecode(localStorage.getString('user')!);
    final String url = 'https://app.randevumcepte.com.tr/api/v1/bildirimkimligiekleguncelle';
  log("bildirim işin Seçili işletme : "+seciliisletme);
  log("bildirim için kimlik : "+bildirimkimligi);
  log("yetkili veya user id : "+user["id"].toString());
  final String? cihaz = await cihazBilgisi();
  final requestBody = jsonEncode({
    "yetkili_id": usertype == "1" ? user["id"]: "",
    "user_id" :usertype != "1" ? user["id"]: "",
    'sube':seciliisletme,
    "bildirim_kimligi":bildirimkimligi,
    "cihaz":cihaz,
    "appBundle":appBundle
  });
  log('Yetkili request body '+requestBody);
// Body'yi logluyoruz

  final response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},

    body: jsonEncode({
      "yetkili_id": usertype == "1" ? user["id"]: "",
      "user_id" :usertype != "1" ? user["id"]: "",
      'sube':seciliisletme,
      "bildirim_kimligi":bildirimkimligi,
      "cihaz":cihaz,
      "appBundle":appBundle
    }),


  );
  // Log the response status and body

  if (response.statusCode == 200) {
    log('Response status: ${response.statusCode}');
    log('Response body: ${response.body}');

  } else {
    log('bildirim kimliği kaydetmedi '+response.body);

    throw Exception('bildirim kinliği kaydedilemedi');
  }
}
Future<String?> cihazBilgisi() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    // Android cihaz bilgileri
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    return androidInfo.id;
  } else if (Platform.isIOS) {
    // iOS cihaz bilgileri
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

    return iosInfo.identifierForVendor;
  } else {
    return 'Desteklenmeyen bir platform!';
  }
}
Future<MusteriOzet> dashboardGunlukRaporMusteri() async{
  SharedPreferences localStorage = await SharedPreferences.getInstance();

  var user = jsonDecode(localStorage.getString('musteri')!);

  Map<String, dynamic> formData = {

    'appBundle': await appBundleAl(),
    'user_id': user["id"],

    // Add other form fields
  };
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteriozet'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  final jsonresponse = json.decode(response.body);

  return MusteriOzet.fromJson(jsonresponse);

}

Future<Map<String, dynamic>> easistan(String salonid, String currpage, int bugunYarin) async {
  try {
    final uri = Uri.parse('https://demoapptest.randevumcepte.com.tr/api/v1/easistandata/$bugunYarin/$salonid?page=$currpage');

    final response = await http.get(
      uri,
      headers: {"Content-Type": "application/json"},
    );


    if (response.statusCode == 200) {

      Map<String, dynamic> jsonResponse = json.decode(response.body);
      List<EAsistan> asistanList = (jsonResponse['data'] as List)
          .map((data) => EAsistan.fromJson(data))
          .toList();
      jsonResponse['asistanList'] = asistanList;
      return jsonResponse;
    } else {
      throw Exception('API Hatası: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    throw Exception('API isteği başarısız oldu: $e');
  }
}
Future<List<EAsistan>> easistandashboard(String salonid, int bugunYarin) async {
  try {
    final url = Uri.parse(
      'https://app.randevumcepte.com.tr/api/v1/easistandatadashboard/$bugunYarin/$salonid',
    );


    final response = await http.get(url, headers: {"Content-Type": "application/json"});



    if (response.statusCode == 200) {
      // Since the response is a list, decode it directly as a list
      List<dynamic> jsonResponse = json.decode(response.body);

      // Map the list to a List of EAsistan objects
      return jsonResponse
          .map((data) => EAsistan.fromJson(data))
          .toList();
    } else {
      throw Exception('API Hatası: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    throw Exception('API isteği başarısız oldu: $e');
  }
}
Future<Map<String, dynamic>> isletmeVerileriGetir(String salonid,bool randevuAlSayfasi,String appbundle,String musteriArama,String hizmetArama,int limit, int offset) async {

  Map<String, dynamic> formData = {
    'salonid': salonid,
    'randevuAlSayfasi':randevuAlSayfasi,
    'appBundle': appbundle,
    'musteriArama':musteriArama,
    'hizmetArama':hizmetArama,
    'limit':limit,
    'offset':offset,


    // Add other form fields
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevuIcinGerekliVeriler'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {

    final data = json.decode(response.body);

    List<OnGorusmeNedeni> loadedItems = [];
    if(!randevuAlSayfasi)
      {
        loadedItems.addAll((data['paketler'] as List).map((item) => Paket.fromJson(item)).toList());
        /*loadedItems.addAll((data['urunler'] as List).map((item) => Urun.fromJson(item)).toList());
        loadedItems.addAll((data['hizmetler'] as List).map((item) => IsletmeHizmet.fromJson(item)).toList());*/
      }

    return {
      'personeller':   data['personeller']!=''? (data['personeller'] as List).map((e) => Personel.fromJson(e)).toList() : [],
      'hizmetler':     data['hizmetler']!='' ? (data['hizmetler'] as List).map((e) => IsletmeHizmet.fromJson(e)).toList() : [],
      'odalar': !randevuAlSayfasi ? (data['odalar'] as List).map((e) => Oda.fromJson(e)).toList() : [],
      'cihazlar': !randevuAlSayfasi ? (data['cihazlar'] as List).map((e) => Cihaz.fromJson(e)).toList(): [],
      'musteriler': !randevuAlSayfasi ?(data['musteriler'] as List).map((e) => MusteriDanisan.fromJson(e)).toList(): [],
      'paketler': !randevuAlSayfasi ? (data['paketler'] as List).map((e) => Paket.fromJson(e)).toList(): [],
      'urunler': !randevuAlSayfasi ? (data['urunler'] as List).map((e) => Urun.fromJson(e)).toList(): [],
      'sehirler': !randevuAlSayfasi ? (data['sehirler'] as List).map((e) => Sehir.fromJson(e)).toList() : [],
      'subeler' : randevuAlSayfasi ? (data['subeler'] as List).map((e) => Salonlar.fromJson(e)).toList() : [],
      'onGorusmeNedeni':loadedItems,
      'formlar': !randevuAlSayfasi ? (data ['formlar'] as List).map((e)=>Sozlesme.fromJson(e)).toList() : [],
    };
  } else {
    throw Exception("Veriler alınamadı: ${response.reasonPhrase}");
  }
}
Future<Map<String, dynamic>> bosVeDoluSaatleriGetir(
    String salonid,
    List<String> seciliPersoneller,
    List<String> seciliHizmetler,
    String tarih,
    String appBundle
    ) async {

  Map<String, dynamic> formData = {
    'sube': salonid,
    'personeller': seciliPersoneller,
    'secilenhizmetler': seciliHizmetler,
    'randevutarihi': tarih,
    'appBundle':appBundle,
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevuTarihSaatAdimi'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);


  } else {
    throw Exception("Veriler alınamadı: ${response.reasonPhrase}");
  }
}
Future<void> saveVoipTokenToBackend(String token,String personelId)
async {
  Map<String, dynamic> formData = {

    'voipToken' :token,
    'personelId' : personelId,



    // Add other form fields
  };
  log('token form data '+formData.toString());
  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/voipTokenKaydet'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200) {
    log('Token başarıyla kaydedildi');
  }
  else {
    logyaz(response.statusCode,(response.reasonPhrase ?? '')+' token kaydedilemedi.');
    throw Exception("Token kaydedilemedi: ${response.reasonPhrase}");
  }


}
String arayanBilgiVer(String phone){

  dynamic musteriAdi = arayanbilgi(phone,'20');
  log('ad soyad arayan : '+musteriAdi["musteri_adi"]);
  return musteriAdi["musteri_adi"];
}
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {


  await Firebase.initializeApp(); //make sure firebase is initialized before using it (showCallkitIncoming)
  logyaz(200, 'firebase arkada dinleniyor');

}
Future<String> appBundleAl() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();


  return packageInfo.packageName; // Bundle ID (Android’de applicationId, iOS’ta bundle identifier)

}

Future<Map<String, dynamic>> personelAdiminaGec(String salonid,String appbundle,String hizmetId) async {





  Map<String, dynamic> formData = {
    'sube': salonid,

    'appBundle': appbundle,
    'randevuhizmet':hizmetId,


    // Add other form fields
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/personelAdiminaGec'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    log('Salon id '+ salonid.toString()+' appbunde ' + appbundle+ 'hizmet id '+hizmetId.toString()+ ' Personeller '+response.body);
    final data = json.decode(response.body);
    List<OnGorusmeNedeni> loadedItems = [];

    return {
      'personeller':  (data as List).map((e) => Personel.fromJson(e)).toList(),

    };
  } else {
    throw Exception("Veriler alınamadı: ${response.reasonPhrase}");
  }
}
Future<void> rehberdenTopluSec(BuildContext context,dynamic isletmebilgi,int kullancirolu) async {
  if (await Permission.contacts.request().isGranted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactSelectionPage(kullanicirolu: kullancirolu, isletmebilgi: isletmebilgi),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rehber erişim izni reddedildi!"))
    );
  }
}
Future<MusteriSayilari> musteriSayilariGetir(String salonId) async {
  try {
    final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/musteri_sayilari_getir/$salonId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return MusteriSayilari.fromJson(jsonResponse['data']);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Müşteri sayıları alınamadı');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Müşteri sayıları getirme hatası: $e');
    rethrow;
  }
}
Future<MusteriDanisan?> rehberdenSecAlternatif(BuildContext context,dynamic isletmebilgi,int kullanicirolu) async {
  try {
    PermissionStatus status = await Permission.contacts.status;

    if (status != PermissionStatus.granted) {
      status = await Permission.contacts.request();
    }

    if (status == PermissionStatus.granted) {
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null) {
        final fullContact = await FlutterContacts.getContact(contact.id, withProperties: true);

        if (fullContact != null) {
          String isim = fullContact.displayName.trim();
          String telefon = fullContact.phones.isNotEmpty ? fullContact.phones.first.number : "";
          telefon = telefon.trim().replaceAll('+90', '');

          telefon = telefon.trim().replaceAll('-', '');
          telefon = telefon.trim().replaceAll(' ', '');
          telefon = telefon.trim().replaceFirst('0', '');
          MusteriDanisan md = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Yenimusteri(
                kullanicirolu: kullanicirolu,
                isletmebilgi: isletmebilgi,
                isim: isim,
                telefon: telefon,
                sadeceekranikapat: true,
              ),
            ),
          );
          return md;
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rehber erişim izni reddedildi!")),
      );
    }
  } catch (e) {
    print("Hata: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Bir hata oluştu: $e")),
    );
  }
}
Future<List<dynamic>> hizmetRaporlari(String salonId,String tarih1,String tarih2, String personel) async {
  try {
    Map<String, dynamic> formData = {
      'salonId': salonId,

      'tarih1': tarih1,
      'tarih2':tarih2,
      'personel':personel,


      // Add other form fields
    };
    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/hizmetRaporlari'),
      headers: {'Content-Type': 'application/json'},
      body:jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      log(response.body);
      return jsonResponse;
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Hizmet raporu getirme hatası: $e');
    rethrow;
  }
}

Future<List<dynamic>> urunRaporlari(String salonId,String tarih1,String tarih2, String personel) async {
  try {
    Map<String, dynamic> formData = {
      'salonId': salonId,

      'tarih1': tarih1,
      'tarih2':tarih2,
      'personel':personel,


      // Add other form fields
    };
    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/urunRaporlari'),
      headers: {'Content-Type': 'application/json'},
      body:jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      return jsonResponse;
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Ürün raporu getirme hatası: $e');
    rethrow;
  }
}
Future<List<dynamic>> paketRaporlari(String salonId,String tarih1,String tarih2, String personel) async {
  try {
    Map<String, dynamic> formData = {
      'salonId': salonId,

      'tarih1': tarih1,
      'tarih2':tarih2,
      'personel':personel,


      // Add other form fields
    };
    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/paketRaporlari'),
      headers: {'Content-Type': 'application/json'},
      body:jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      return jsonResponse;
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Paket raporu getirme hatası: $e');
    rethrow;
  }
}

Future<List<dynamic>> personelRaporlari(String salonId,String tarih1,String tarih2) async {
  try {
    Map<String, dynamic> formData = {
      'salonId': salonId,

      'tarih1': tarih1,
      'tarih2':tarih2,



      // Add other form fields
    };
    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/personelRaporlari'),
      headers: {'Content-Type': 'application/json'},
      body:jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      return jsonResponse;
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Paket raporu getirme hatası: $e');
    rethrow;
  }
}

// Backend.dart dosyanıza ekleyin
Future<List<dynamic>> hizmetMusteriListesiGetir(
    String salonId,
    String hizmetId,
    String tarih1,
    String tarih2,
    String personelId, // Yeni parametre: isteğe bağlı personelId
    ) async {
  try {
    Map<String, dynamic> formData = {
      'salonId': salonId,
      'tarih1': tarih1,
      'tarih2': tarih2,
      'hizmetId': hizmetId,
      'personelId': personelId,
    };

    // Personel ID'si varsa ekle
    if (personelId != null && personelId.isNotEmpty) {
      formData['personelId'] = personelId;
    }

    log(jsonEncode(formData));
    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/hizmet-musteri-listes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );
    log(response.body);

    if (response.statusCode == 200) {
      log('hizmet müşterileri ' + response.body);
      return jsonDecode(response.body);
    }
    return [];
  } catch (e) {
    log('Hizmet müşteri listesi getirme hatası: $e');
    return [];
  }
}

Future<List<dynamic>> urunMusteriListesiGetir(
    String salonId,
    String urunId,
    String tarih1,
    String tarih2,
    String personelId // Yeni parametre: isteğe bağlı personelId
    ) async {
  try {
    Map<String, dynamic> formData = {
      'salonId': salonId,
      'tarih1': tarih1,
      'tarih2': tarih2,
      'urunId': urunId,
      'personelId': personelId,
    };

    // Personel ID'si varsa ekle
    if (personelId != null && personelId.isNotEmpty) {
      formData['personelId'] = personelId;
    }

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/urun-musteri-listesi'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  } catch (e) {
    log('Ürün müşteri listesi getirme hatası: $e');
    return [];
  }
}

Future<List<dynamic>> paketMusteriListesiGetir(
    String salonId,
    String paketId,
    String tarih1,
    String tarih2,
    String personelId // Yeni parametre: isteğe bağlı personelId
    ) async {
  try {
    Map<String, dynamic> formData = {
      'salonId': salonId,
      'tarih1': tarih1,
      'tarih2': tarih2,
      'paketId': paketId,
      'personelId': paketId,
    };

    // Personel ID'si varsa ekle
    if (personelId != null && personelId.isNotEmpty) {
      formData['personelId'] = personelId;
    }

    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/paket-musteri-listesi'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  } catch (e) {
    log('Paket müşteri listesi getirme hatası: $e');
    return [];
  }
}
// backend.dart dosyasına ekleyin
Future<Map<String, dynamic>> adisyonSil(String adisyonId) async {
  try {
    final response = await http.post(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/adisyonSil'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'adisyon_id': adisyonId
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Silme işlemi başarısız: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Silme hatası: $e');
  }
}
Future<void> aramaYap(String phoneNumber, BuildContext context) async {
  // Telefon numarasını temizle (gerekiyorsa)
  final String cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
  // Uri nesnesi oluştur. 'tel:' şeması kullanılır.
  final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

  // `canLaunchUrl` ile cihazın bu eylemi destekleyip desteklemediğini kontrol et
  if (await canLaunchUrl(phoneUri)) {
    // Destekliyorsa, telefon uygulamasını aç ve numarayı çevirmeye hazırla
    await launchUrl(phoneUri);
  } else {
    // Desteklemiyorsa (örneğin bir tablet veya VoIP uygulaması kurulu değilse) hata göster
    if (context.mounted) { // Sayfa hala açık mı kontrol et
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu cihazda arama yapılamıyor. Lütfen cihazınıza softphone yükleyiniz.')),
      );
    }
  }
}