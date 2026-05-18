import 'dart:async';
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

import 'package:randevu_sistem/Models/e_asistan.dart';
import 'package:randevu_sistem/Models/musteridashboard.dart';
import 'package:randevu_sistem/Models/salonyorumlarozet.dart';
import 'package:randevu_sistem/Models/hizmetkategorisi.dart';
import 'package:randevu_sistem/Frontend/progressloading.dart';
import 'package:randevu_sistem/Login Sayfası/checklogin.dart';
import 'package:randevu_sistem/Models/adisyonhizmetler.dart';
import 'package:randevu_sistem/Models/adisyonkalemleri.dart';
import 'package:randevu_sistem/Models/adisyonpaketler.dart';
import 'package:randevu_sistem/Models/adisyonurunler.dart';
import 'package:randevu_sistem/Models/ajanda.dart';
import 'package:randevu_sistem/Models/cdr.dart';
import 'package:randevu_sistem/Models/cihazlar.dart';
import 'package:randevu_sistem/Models/dashboard.dart';
import 'package:randevu_sistem/Models/etkinlikler.dart';
import 'package:randevu_sistem/Models/form.dart';
import 'package:randevu_sistem/Models/hizmetler.dart';
import 'package:randevu_sistem/Models/isletmecalismasaatleri.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/molasaatleri.dart';
import 'package:randevu_sistem/Models/musterisayilari.dart';
import 'package:randevu_sistem/Models/ongorusmeler.dart';
import 'package:randevu_sistem/Models/randevuhizmetleri.dart';
import 'package:randevu_sistem/Models/randevuhizmetyardimcipersonelleri.dart';
import 'package:randevu_sistem/Models/salonlar.dart';
import 'package:randevu_sistem/Models/sehirler.dart';
import 'package:randevu_sistem/Models/senetvadeleri.dart';
import 'package:randevu_sistem/Models/sozlesme.dart';
import 'package:randevu_sistem/Models/kampanyalar.dart';
import 'package:randevu_sistem/Models/odalar.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/taksitvadeleri.dart';
import 'package:randevu_sistem/Models/urunler.dart';
import 'package:randevu_sistem/Models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/musteripaneli/musterialtbar.dart';
import 'package:randevu_sistem/yonetici/dashboard/ozetsayfasi.dart';
import 'dart:io';
import 'package:path/path.dart';

import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/personelcalismasaatleri.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/personeller/personelmolasaatleri.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:randevu_sistem/yonetici/diger/menu/musteriler/rehberdekimusteriler.dart';
import 'package:randevu_sistem/yonetici/diger/menu/musteriler/yeni_musteri.dart';

Future<Map<String,dynamic>> ajandagetir(String salonid,String currpage,String baslik) async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);
  Map<String, dynamic> formData = {
    'baslik': baslik,


    // Add other form fields
  };


  final response = await http.post(
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/ajandaget/"+salonid.toString()+"/"+user['id'].toString()+'?page='+currpage.toString()),

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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/cihazgetir/"+salonid.toString()+'?page='+currpage.toString()),

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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/odagetir/"+salonid.toString()+'?page='+currpage.toString()),

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

Future<List<Map<String, String>>> odaPersonelListesi(String salonid) async {
  final response = await http.get(
    Uri.parse(
        'https://apptest.randevumcepte.com.tr/api/v1/oda_personel_listesi/$salonid'),
    headers: {'Content-Type': 'application/json'},
  );
  if (response.statusCode != 200) {
    throw Exception(response.reasonPhrase);
  }
  final body = json.decode(response.body);
  final List list = (body is Map && body['data'] is List)
      ? body['data'] as List
      : (body is List ? body : const []);
  return list
      .map<Map<String, String>>((e) => {
            'id': (e['id'] ?? '').toString(),
            'personel_adi': (e['personel_adi'] ?? '').toString(),
          })
      .toList();
}

Future<Map<String, dynamic>> odaDetayGetir(String odaId) async {
  final response = await http.get(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/oda_detay/$odaId'),
    headers: {'Content-Type': 'application/json'},
  );
  if (response.statusCode != 200) {
    throw Exception(response.reasonPhrase);
  }
  return Map<String, dynamic>.from(json.decode(response.body) as Map);
}

Future<List<MusteriDanisan>> musterilistegetir(String salonid) async {
  final response = await http.get(
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/musteriler/'+salonid.toString())
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/musteritahsilat?userId='+userId)
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
      'https://apptest.randevumcepte.com.tr/api/v1/musteriler/$salonid?search=$filter&limit=$limit&offset=$offset&seciliMusteri?$seciliMusteri'));

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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/sehirler')
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
  final response = await http.get(Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/ongorusmenedeni/'+salonid));

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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personeller/'+salonid.toString())
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/formlar')
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/masrafkategorileri')
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/smstaslaklari/'+salonid.toString())
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/kampanyalar/'+salonid.toString()+'?page='+currpage.toString()),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/etkinlikyukle/'+salonid.toString()+'?page='+currpage.toString()),
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/paketget/'+salonid.toString())
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/arsivyukle/'+salonid.toString()+'?page='+currpage.toString()),

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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/kullaniciBilgiGetir/'+userid.toString())
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/hizmetler/'+salonid.toString())
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Hizmetler. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");
    List jsonResponse = json.decode(response.body);

    final liste = jsonResponse.map((e) => IsletmeHizmet.fromJson(e)).toList();
    // salon_hizmetler tablosunda ayni hizmet icin birden fazla satir oldugunda
    // tum seciciler ayni adi/satiri tekrarli gosteriyordu. Inner hizmet.id ve
    // hizmet_adi'na gore tekille — kullanici bir kez tiklayinca tek satir
    // secilsin.
    final seen = <String>{};
    final seenAd = <String>{};
    final deduped = <IsletmeHizmet>[];
    for (final h in liste) {
      final innerId = h.hizmet?['id']?.toString() ?? '';
      final adKey = (h.hizmet?['hizmet_adi']?.toString() ?? '').trim().toLowerCase();
      final idKey = innerId.isNotEmpty ? innerId : h.hizmet_id;
      if (idKey.isEmpty && adKey.isEmpty) continue;
      if (idKey.isNotEmpty && !seen.add(idKey)) continue;
      if (adKey.isNotEmpty && !seenAd.add(adKey)) continue;
      deduped.add(h);
    }
    return deduped;
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception(response.reasonPhrase);
  }
}
Future<List<Cihaz>> isletmecihazlari(String salonid) async{
  final response = await http.get(
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/cihazlar/'+salonid.toString())
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/odalar/'+salonid.toString())
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/salonlar'),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/salonsaatleri/'+salonId),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/salonmolasaatleri/'+salonId),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/dashboard'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );


  log("Özet Sayfası "+response.body);
  final jsonresponse = json.decode(response.body);

  return OzetSayfasi.fromJson(jsonresponse);

}

/// Dashboard karşılaştırma — periyot bazlı (gunluk|haftalik|aylik|yillik) toplam ciro,
/// önceki periyot, son 7 periyot serisi, top performer'lar, saat yoğunluğu,
/// kâr-maliyet özeti, alacak.
///
/// Backend henüz deploy edilmediyse null döner — UI mock veri ile devam eder.
Future<Map<String, dynamic>?> dashboardKarsilastirma(
    String salonId, String period) async {
  try {
    final response = await http
        .get(
          Uri.parse(
              'https://apptest.randevumcepte.com.tr/api/v1/dashboardKarsilastirma/$salonId?period=$period'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is Map<String, dynamic>) return body;
    }
  } catch (e) {
    log('dashboardKarsilastirma hata: $e');
  }
  return null;
}

/// Dashboard saat bosluk onerisinden gercek kampanya olusturur.
/// kampanyalar tablosuna 7 gun gecerli kayit ekler.
/// Donus: {status: success|duplicate|error, message: ..., kampanya_id: ...}
Future<Map<String, dynamic>?> saatBosluguKampanyaOlustur({
  required String salonId,
  required String gapKey,
  required String gapLabel,
  required int startHour,
  required int endHour,
  required int discount,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse(
              'https://apptest.randevumcepte.com.tr/api/v1/saatBosluguKampanyaOlustur/$salonId'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'gapKey': gapKey,
            'gapLabel': gapLabel,
            'startHour': startHour,
            'endHour': endHour,
            'discount': discount,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final body = json.decode(response.body);
    if (body is Map<String, dynamic>) return body;
  } catch (e) {
    log('saatBosluguKampanyaOlustur hata: $e');
  }
  return null;
}

/// Gap kampanyasi icin salonun tum aktif musterilerine SMS gonderir.
/// VoiceTelekom multi-recipient API ile tek call'da bulk gonderim.
/// Donus: {status: success|error, gonderildi: int, message: ...}
Future<Map<String, dynamic>?> saatBosluguKampanyaBildirimGonder({
  required String salonId,
  required int kampanyaId,
  int maxAdet = 500,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse(
              'https://apptest.randevumcepte.com.tr/api/v1/saatBosluguKampanyaBildirimGonder/$salonId'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'kampanyaId': kampanyaId,
            'maxAdet': maxAdet,
          }),
        )
        .timeout(const Duration(seconds: 60));
    final body = json.decode(response.body);
    if (body is Map<String, dynamic>) return body;
  } catch (e) {
    log('saatBosluguKampanyaBildirimGonder hata: $e');
  }
  return null;
}

/// Salonun tum aktif gap kampanyalarini liste halinde getirir.
/// Takvim/ajanda ekraninda kampanya saatlerini bildirim seridi olarak gostermek icin.
/// Donus: {count: int, kampanyalar: [{id, gapKey, gapLabel, startHour, endHour, discount, ...}]}
Future<Map<String, dynamic>?> aktifGapKampanyalari(String salonId) async {
  if (salonId.isEmpty) return null;
  try {
    final response = await http
        .get(
          Uri.parse(
              'https://apptest.randevumcepte.com.tr/api/v1/aktifGapKampanyalari/$salonId'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));
    final body = json.decode(response.body);
    if (body is Map<String, dynamic>) return body;
  } catch (e) {
    log('aktifGapKampanyalari hata: $e');
  }
  return null;
}

/// Belirli bir saat icin aktif gap kampanyasi var mi kontrol eder.
/// Tahsilat ekraninda "bu randevu indirim aralginda mi?" sorusu icin.
/// [saat] format: "HH:MM" (opsiyonel, yoksa server now kullanir)
/// Donus: {hasCampaign: bool, gapKey, gapLabel, discount, baslik, ...}
Future<Map<String, dynamic>?> randevuKampanyaKontrol({
  required String salonId,
  String? saat,
}) async {
  try {
    final qp = saat != null && saat.isNotEmpty ? '?saat=$saat' : '';
    final response = await http
        .get(
          Uri.parse(
              'https://apptest.randevumcepte.com.tr/api/v1/randevuKampanyaKontrol/$salonId$qp'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));
    final body = json.decode(response.body);
    if (body is Map<String, dynamic>) return body;
  } catch (e) {
    log('randevuKampanyaKontrol hata: $e');
  }
  return null;
}

/// Dashboard saat bosluk kampanyasini iptal eder (soft-deactivate).
/// Donus: {status: success|error, message: ...}
Future<Map<String, dynamic>?> saatBosluguKampanyaIptal({
  required String salonId,
  required int kampanyaId,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse(
              'https://apptest.randevumcepte.com.tr/api/v1/saatBosluguKampanyaIptal/$salonId'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'kampanyaId': kampanyaId}),
        )
        .timeout(const Duration(seconds: 15));
    final body = json.decode(response.body);
    if (body is Map<String, dynamic>) return body;
  } catch (e) {
    log('saatBosluguKampanyaIptal hata: $e');
  }
  return null;
}

/// Anket ozeti: toplam gonderim/cevap, response rate, ort NPS/CSAT,
/// promoter/passive/detractor sayilari, son 7 gun cevap trend serisi.
Future<Map<String, dynamic>?> anketOzet(String salonId, {int gun = 30}) async {
  if (salonId.isEmpty) return null;
  try {
    final response = await http.get(
      Uri.parse(
          'https://apptest.randevumcepte.com.tr/api/v1/anketOzet/$salonId?gun=$gun'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is Map<String, dynamic>) return body;
    }
  } catch (e) {
    log('anketOzet hata: $e');
  }
  return null;
}

/// Anket gonderim listesi (cevaplanmis olanlar, en yeni once).
/// Pagination destekli (limit/offset).
Future<List<Map<String, dynamic>>?> anketGonderimleri(
  String salonId, {
  int limit = 20,
  int offset = 0,
  bool sadeceCevaplilar = true,
  String? filtre, // 'google_tiklayan' | 'kotu_puan' | 'cevapli' | 'tum' | null
}) async {
  if (salonId.isEmpty) return null;
  try {
    final params = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      'sadeceCevaplilar': sadeceCevaplilar ? '1' : '0',
      if (filtre != null && filtre.isNotEmpty) 'filtre': filtre,
    };
    final uri = Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/anketGonderimleri/$salonId')
        .replace(queryParameters: params);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is Map<String, dynamic> && body['kayitlar'] is List) {
        return (body['kayitlar'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
  } catch (e) {
    log('anketGonderimleri hata: $e');
  }
  return null;
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/ongorusmeget/'+Salonid.toString()+'?page='+currpage.toString()),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/ongorusmegetgunluk/'+Salonid.toString()+'?page='+currpage.toString()),

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
      "https://apptest.randevumcepte.com.tr/api/v1/cdrraporson?${buffer.toString()}",
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevular?page='+currpage.toString()),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/isletmecalismasaatleri/'),

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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/tum_randevulari_getir/"+Salonid.toString()+'?page='+currpage.toString()),
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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/salon_randevu_getir/"+Salonid.toString()+'?page='+currpage.toString()),
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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/uygulama_randevu_getir/"+Salonid.toString()+'?page='+currpage.toString()),
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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/web_randevu_getir/"+Salonid.toString()+'?page='+currpage.toString()),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/urunler/'+Salonid+'?page='+currpage.toString()),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/paketler/'+Salonid+'?page='+currpage.toString()),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/paketsatisget/'+Salonid+'?page='+currpage.toString()),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/urunsatisget/'+Salonid+'?page='+currpage.toString()),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/alacaklar/'+Salonid+'?page='+currpage.toString()),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/seanslar?page='+currpage.toString()),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/senetler/'+Salonid+'?page='+currpage.toString()),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/musterilistegetir/'+Salonid+'?page='+currpage.toString()),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/tahsilatraporu/'+Salonid+'?page='+currpage.toString()),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/masrafraporu/'+Salonid+'?page='+currpage.toString()),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/kasaraporu/'+Salonid),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/devredenAylar'),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/seanslar?page='+currpage.toString()),

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

Future<Map<String, dynamic>> seansGuncelleApi(
    String seansId, dynamic geldi, BuildContext context) async {
  final formData = {
    'seansId': seansId,
    'geldi': geldi,
  };
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/seansGuncelle'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  logyaz(response.statusCode, response.reasonPhrase);
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> seansEkleApi(
    String paketHizmetId, String hizmetId, int paketMi, int geldi,
    BuildContext context) async {
  final formData = {
    'paketId': paketHizmetId,
    'hizmetId': hizmetId,
    'paket': paketMi,
    'geldi': geldi,
  };
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/seansEkle'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  logyaz(response.statusCode, response.reasonPhrase);
  throw Exception(response.reasonPhrase);
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevular/'+seciliisletme+'/0'),


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
  final response = await http.get(Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevular/'+seciliisletme+'/0'));

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
  final response = await http.get(Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevular/'+seciliisletme+'/1'));
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
        image: NetworkImage('https://apptest.randevumcepte.com.tr' + item["avatar"]),
      );
    }).toList();
  } else {
    logyaz(response.statusCode,response.reasonPhrase);
    throw Exception('Failed to load resources');
  }
}

Future<List<Randevu>> tumrandevular(seciliisletme) async {
  final response = await http.get(Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevular/'+seciliisletme+'/2'));

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
Future<void> randevuonayla(String randevuid, BuildContext context) async {
  showProgressLoading(context);
  TextEditingController dogrulama_kodu = TextEditingController();

  Map<String, dynamic> formData = {
    'randevuid': randevuid,

    // Add other form fields
  };


  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevuonayla'),

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
Future<void> randevugelmediisaretle(String randevuid, BuildContext context, [String seansDusumuYap = '']) async {
  showProgressLoading(context);
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = jsonDecode(localStorage.getString('user')!);

  Map<String, dynamic> formData = {
    'randevuid': randevuid,
    'user': user["id"],
    'seansDusumuYap': seansDusumuYap,
  };

  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevuyagelmediisaretle'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {
    var rateLimit = response.headers['x-ratelimit-limit'];
    var remaining = response.headers['x-ratelimit-remaining'];
    var reset = response.headers['x-ratelimit-reset'];

    logyaz2("Gelmedi işaretle. Rate Limit: $rateLimit Requests Remaining: $remaining Rate Limit Reset Time: $reset");

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    dynamic result;
    try {
      result = json.decode(response.body);
    } catch (_) {
      result = null;
    }

    if (result is Map && result['seansDusmeOnayi'] == true) {
      final secim = await seansDusmeOnayPopup(result['mesaj']?.toString() ?? 'Seansından düşülsün mü?', context);
      if (secim == null) return;
      await randevugelmediisaretle(randevuid, context, secim);
    }
  } else {
    logyaz(response.statusCode, response.reasonPhrase);
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    throw Exception(response.reasonPhrase);
  }
}

Future<String?> seansDusmeOnayPopup(String mesaj, BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: const Text('Seans Düşümü'),
        content: Text(mesaj),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('0'),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('1'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet, Düşür'),
          ),
        ],
      );
    },
  );
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevuiptalet'),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevuGeldiGelmediIsaretiKaldir'),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevugeldiisaretle'),
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
Future<AdisyonPaket> adisyonpaketekle(AdisyonPaket paket,String musteriid,BuildContext context,String salonid,String seanssaati, bool showprogress,String senetid, {String seansSayisi = ''}) async{
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
    'senet_id':senetid,
    'seans_sayisi':seansSayisi,

  };
  log(json.encode(formData));
  final response = await http.post(
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/adisyonpaketekle"),

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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/tum-alacaklar"),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/taksitekleguncelle'),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/tahsilatekle'),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/senetekleguncelle'),

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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/adisyonhizmetekle"),

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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/adisyonurunekle"),

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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/tahsilat-hizmet-sil"),

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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/tahsilat-urun-sil"),

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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/tahsilat-paket-sil"),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/urunler'),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/paketler'),

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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/musteri-danisan-turunu-getir"),

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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/satislar?page='+currpage.toString()),

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
  final userStr = localStorage.getString('user');
  final user = userStr != null ? jsonDecode(userStr) : null;

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
    'olusturan': kaynak == 'salon' && user != null ? user["id"] : null,
    'olusturanMusteri': kaynak == 'uygulama' ? secilimusteridanisan.id : null,
    'randevuKaynak': kaynak,
    'durum': durum,
    'appBundle': await appBundleAl(),
  };

  http.Response response;
  try {
    log('randevuEkleGuncelle POST gönderiliyor — payload boyut: ${jsonEncode(formData).length} bytes');
    final t0 = DateTime.now();
    response = await http
        .post(
          Uri.parse(
              'https://apptest.randevumcepte.com.tr/api/v1/randevuekleguncelle'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(formData),
        )
        .timeout(const Duration(seconds: 60));
    log('randevuEkleGuncelle POST tamamlandı — ${DateTime.now().difference(t0).inMilliseconds}ms, status ${response.statusCode}');
  } catch (e, st) {
    log('randevuEkleGuncelle hatası: $e', stackTrace: st);
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    final String mesaj;
    if (e is TimeoutException) {
      mesaj =
          'Sunucu 60 saniyede yanıt vermedi. Lütfen biraz sonra tekrar deneyin. '
          'Sorun devam ederse internet bağlantınızı veya VPN ayarlarınızı kontrol edin.';
    } else {
      mesaj = 'Randevu kaydedilemedi.\n\nHata türü: ${e.runtimeType}\nDetay: $e';
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HATA'),
        content: SingleChildScrollView(child: Text(mesaj)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('TAMAM'),
          ),
        ],
      ),
    );
    return;
  }

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
    debugPrint('Error: ${response.statusCode} ${response.body}');
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HATA'),
        content: Text(
            'Randevu kaydedilemedi. Sunucu hata kodu: ${response.statusCode}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('TAMAM'),
          ),
        ],
      ),
    );
  }
}
// Takvimde saat kapama (Laravel sistemdeki saat-kapama tab'inin mobil karsiligi).
// personelId bos olabilir (genel kapama). tarih yyyy-MM-dd, saat HH:mm (bos -> tum gun, sunucuda calisma saatleri uygulanir).
Future<Map<String, dynamic>> saatKapamaEkle({
  required String salonId,
  required String tarih,
  String saat = '',
  String saatBitis = '',
  String personelId = '',
  String odaId = '',
  String cihazId = '',
  String personelNotu = '',
  bool tekrarlayan = false,
  String tekrarSikligi = '+1 day',
  int tekrarSayisi = 0,
}) async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  final userStr = localStorage.getString('user');
  final user = userStr != null ? jsonDecode(userStr) : null;

  final Map<String, dynamic> formData = {
    'salonid': salonId,
    'tarih': tarih,
    'saat': saat,
    'saat_bitis': saatBitis,
    'personel': personelId,
    'oda': odaId,
    'cihaz': cihazId,
    'personel_notu': personelNotu,
    'tekrarlayan': tekrarlayan ? 1 : 0,
    'tekrar_sikligi': tekrarSikligi,
    'tekrar_sayisi': tekrarSayisi,
    'olusturan_personel_id': user != null ? user['id'] : null,
  };

  final response = await http
      .post(
        Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/saatkapamaekle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      )
      .timeout(const Duration(seconds: 30));

  Map<String, dynamic> body = {};
  try {
    body = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    body = {'message': response.body};
  }
  if (response.statusCode == 200) {
    return {'ok': true, ...body};
  }
  return {'ok': false, 'status': response.statusCode, ...body};
}

Future<Map<String, dynamic>> kapaliSaatSil(String randevuId) async {
  final response = await http
      .post(
        Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/kapalisaatsil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'randevu_id': randevuId}),
      )
      .timeout(const Duration(seconds: 30));
  Map<String, dynamic> body = {};
  try {
    body = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    body = {'message': response.body};
  }
  return {'ok': response.statusCode == 200, 'status': response.statusCode, ...body};
}

Future<dynamic> satisyapilmadi(BuildContext context, String ongorusmeid,String aciklama,String currentPage,String aramaterimi,bool showprogress) async {


  Map<String, dynamic> formData = {
    'ongorusmeid': ongorusmeid,
    'satisyapilmamasebebi': aciklama,
  };

  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/ongorusmesatisyapilmadi'),
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
      Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/personelgetir/$salonid?page=$currpage"),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelmolasaatleri/'+personelid),

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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelcalismasaatleri/$personelid'),
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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/randevutahsilet"),

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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/hizmet_liste_getir/$salonid?page=$currpage"),
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
    Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/seciliolmayanhizmetlerigetir"),
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/hizmetkategorileri')
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/mobildegelenaramagoster'),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/arayanmusteribilgi'),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/ongorusmebilgi'),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/ongorusmesatisyapildi'),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelprimhesapla'),
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

// TOPLU prim hakedis: salondaki tum aktif personelin ay/yil ozeti tek istekte.
// Hata detayini yakalar; UI'da gosterilebilir.
Future<Map<String, dynamic>> primHakedisToplu({
  required String salonid,
  required String ay,
  required String yil,
}) async {
  try {
    final response = await http.post(
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/primHakedisToplu/$salonid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ay': ay, 'yil': yil}),
    );
    debugPrint('primHakedisToplu status: ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'basarili': false, '_hata_mesaj': 'Beklenmeyen cevap formati'};
      } catch (e) {
        return {'basarili': false, '_hata_mesaj': 'JSON parse hatasi: $e'};
      }
    }
    return {
      'basarili': false,
      '_hata_mesaj': 'HTTP ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
    };
  } catch (e) {
    return {'basarili': false, '_hata_mesaj': 'Ag hatasi: $e'};
  }
}

// Ay/yil filtreli prim hesaplama (personeldetay sayfasi icin).
// Donus: hizmet/urun/paket toplam+hakedis (string + numeric), adisyon listesi.
Future<Map<String, dynamic>?> personelPrimHesaplaAyYil({
  required String personelid,
  required String salonid,
  required String ay,   // "01".."12"
  required String yil,  // "2026"
}) async {
  final formData = {
    'sube': salonid,
    'personel_id': personelid,
    'ay': ay,
    'yil': yil,
  };
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelPrimHesaplaAyYil'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  debugPrint('personelPrimHesaplaAyYil failed: ${response.statusCode} ${response.body}');
  return null;
}

// Personeli arsivle (soft delete): listeden gizler, gecmis veriler korunur.
Future<bool> personelArsivle(String personelid, String salonid) async {
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelArsivle'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'personelid': personelid, 'sube': salonid}),
  );
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data is Map && data['sonuc'] == 'ok';
  }
  debugPrint('personelArsivle failed: ${response.statusCode}');
  return false;
}

// Aktif personeller arasinda sirayi 1 kaydir. delta: -1 yukari, +1 asagi.
Future<bool> personelSiralamaKaydir(String personelid, String salonid, int delta) async {
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelSiralamaKaydir'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'personelid': personelid, 'sube': salonid, 'delta': delta}),
  );
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data is Map && data['sonuc'] == 'ok';
  }
  debugPrint('personelSiralamaKaydir failed: ${response.statusCode}');
  return false;
}

// takvimde_gorunsun toggle. Donus: yeni deger (0/1) veya null.
Future<int?> personelTakvimdeGorunsunToggle(String personelid, String salonid) async {
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelTakvimdeGorunsunToggle'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'personelid': personelid, 'sube': salonid}),
  );
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data is Map && data['sonuc'] == 'ok') {
      return (data['takvimde_gorunsun'] as num?)?.toInt();
    }
  }
  debugPrint('personelTakvimdeGorunsunToggle failed: ${response.statusCode}');
  return null;
}

// Mobilden aktif/pasif yap + sifre gonder icin context-bagimsiz wrapperlar
// (sfdatatable.dart icindeki versiyonlar SnackBar gosteriyor, biz cagiran yere brakacagiz).
Future<bool> personelAktifYap(String personelid) async {
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelaktifyap'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'personelid': personelid}),
  );
  return response.statusCode == 200;
}

Future<bool> personelPasifYap(String personelid) async {
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelpasifyap'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'personelid': personelid}),
  );
  return response.statusCode == 200;
}

Future<bool> personelSifreGonder(String personelid) async {
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelsifregonder'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'personelid': personelid}),
  );
  return response.statusCode == 200;
}

// === Prim & Maas odemeleri (web prim_hakedis_panel.blade.php API'lerinin Flutter karsiligi) ===

// Maas/Prim/Avans odemesi ekle. Otomatik kasa/masraf kaydi backend tarafinda olusur.
// odeme_tipi: 'maas' | 'prim' | 'diger'
// donem: 'YYYY-MM'
Future<Map<String, dynamic>> primOde({
  required String salonid,
  required String personelid,
  required String donem,
  required double tutar,
  required String odemeTipi,
  String? odemeTarihi,    // 'YYYY-MM-DD' (default: bugun)
  String? odemeYontemi,   // serbest text (Nakit / Kart / Havale ...)
  String? aciklama,
}) async {
  final body = {
    'sube': salonid,
    'personel_id': personelid,
    'donem': donem,
    'tutar': tutar.toStringAsFixed(2),
    'odeme_tipi': odemeTipi,
    if (odemeTarihi != null) 'odeme_tarihi': odemeTarihi,
    if (odemeYontemi != null) 'odeme_yontemi': odemeYontemi,
    if (aciklama != null) 'aciklama': aciklama,
  };
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/primOde'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  return {'basarili': false, 'mesaj': 'HTTP ${response.statusCode}'};
}

// Donem icindeki tum odemeler + bonus/kesinti hareketleri + toplamlar.
Future<Map<String, dynamic>?> primOdemeListesi({
  required String salonid,
  required String personelid,
  required String donem, // 'YYYY-MM'
}) async {
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/primOdemeListesi'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'sube': salonid,
      'personel_id': personelid,
      'donem': donem,
    }),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  debugPrint('primOdemeListesi failed: ${response.statusCode}');
  return null;
}

Future<bool> primOdemeSil({required String salonid, required int odemeId}) async {
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/primOdemeSil'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'sube': salonid, 'id': odemeId}),
  );
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data is Map && data['basarili'] == true;
  }
  return false;
}

// Bonus / Kesinti ekle. tip: 'bonus' | 'kesinti'
Future<Map<String, dynamic>> primHareketEkle({
  required String salonid,
  required String personelid,
  required String tip,
  required double tutar,
  String? tarih,
  String? aciklama,
}) async {
  final body = {
    'sube': salonid,
    'personel_id': personelid,
    'tip': tip,
    'tutar': tutar.toStringAsFixed(2),
    if (tarih != null) 'tarih': tarih,
    if (aciklama != null) 'aciklama': aciklama,
  };
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/primHareketEkle'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  return {'basarili': false, 'mesaj': 'HTTP ${response.statusCode}'};
}

Future<bool> primHareketSil({required String salonid, required int hareketId}) async {
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/primHareketSil'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'sube': salonid, 'id': hareketId}),
  );
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data is Map && data['basarili'] == true;
  }
  return false;
}

// === Personel granular yetki yonetimi ===
// Tanimlar + sablonlar + kategori etiketleri (sayfa acilirken tek cagri).
Future<Map<String, dynamic>?> personelYetkiSema() async {
  final response = await http.get(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelYetkiSema'),
    headers: {'Content-Type': 'application/json'},
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  debugPrint('personelYetkiSema failed: ${response.statusCode}');
  return null;
}

// Belli personelin yetkilerini ve aktif sablonunu cek.
Future<Map<String, dynamic>?> personelYetkiGetir({
  required String salonid,
  required String personelid,
}) async {
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelYetkiGetir'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'sube': salonid, 'personel_id': personelid}),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  debugPrint('personelYetkiGetir failed: ${response.statusCode}');
  return null;
}

// Yetkileri kaydet. sablon: 'sekreter' | 'personel_tam' | 'personel_sade' | 'demo' | 'ozel'
// Donus: { 'basarili': bool, 'mesaj'?: string }
Future<Map<String, dynamic>> personelYetkiKaydet({
  required String salonid,
  required String personelid,
  required String sablon,
  required Map<String, bool> ayarlar,
}) async {
  try {
    final response = await http.post(
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelYetkiKaydet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sube': salonid,
        'personel_id': personelid,
        'sablon': sablon,
        'ayarlar': ayarlar,
      }),
    );
    debugPrint('personelYetkiKaydet status: ${response.statusCode}');
    debugPrint('personelYetkiKaydet body: ${response.body}');
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) return data;
        return {'basarili': false, 'mesaj': 'Beklenmeyen cevap: ${response.body}'};
      } catch (e) {
        return {'basarili': false, 'mesaj': 'JSON parse hatasi: $e'};
      }
    }
    if (response.statusCode == 403) {
      return {'basarili': false, 'mesaj': 'Yetkiniz yok (403). Sadece yetki yönetimi izni olanlar bu işlemi yapabilir.'};
    }
    if (response.statusCode == 404) {
      return {'basarili': false, 'mesaj': 'API endpoint bulunamadı (404). Backend deploy edilmiş mi?'};
    }
    return {
      'basarili': false,
      'mesaj': 'HTTP ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
    };
  } catch (e) {
    return {'basarili': false, 'mesaj': 'Ağ hatası: $e'};
  }
}
Future<MusteriDanisan> kullanicibilgimusteri(String userid) async {
  final response = await http.get(
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/kullaniciBilgiGetir/'+userid.toString())
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

  final String url = 'https://apptest.randevumcepte.com.tr/api/v1/randevularimusteri/$musteriId';
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
    final String url = 'https://apptest.randevumcepte.com.tr/api/v1/bildirimkimligiekleguncelle';
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/musteriozet'),

    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  final jsonresponse = json.decode(response.body);

  return MusteriOzet.fromJson(jsonresponse);

}

Future<SalonYorumlarOzet> salonYorumlariGetir() async {
  final Map<String, dynamic> formData = {
    'appBundle': await appBundleAl(),
  };
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/salonyorumlari'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );
  if (response.statusCode != 200) {
    throw Exception('Yorumlar yuklenemedi: ${response.statusCode}');
  }
  final jsonresponse = json.decode(response.body) as Map<String, dynamic>;
  return SalonYorumlarOzet.fromJson(jsonresponse);
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
      'https://apptest.randevumcepte.com.tr/api/v1/easistandatadashboard/$bugunYarin/$salonid',
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevuIcinGerekliVeriler'),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/randevuTarihSaatAdimi'),
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
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/voipTokenKaydet'),
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
String? _cachedAppBundle;
Future<String> appBundleAl() async {
  if (_cachedAppBundle != null) return _cachedAppBundle!;
  final packageInfo = await PackageInfo.fromPlatform();
  _cachedAppBundle = packageInfo.packageName;
  return _cachedAppBundle!;
}

Future<Map<String, dynamic>> salonAyarlariByBundle(String appBundle) async {
  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/salonAyarlariByBundle'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'appBundle': appBundle}),
  );
  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }
  throw Exception('Salon ayarlari alinamadi: ${response.reasonPhrase}');
}

bool musteriOnlineRandevuAktifMi(dynamic kaynak) {
  if (kaynak == null) return false;
  dynamic v;
  if (kaynak is Map) {
    v = kaynak['musteri_online_randevu_aktif'];
  } else {
    v = kaynak;
  }
  if (v == null) return false;
  final s = v.toString().trim().toLowerCase();
  return s == '1' || s == 'true';
}

Future<Map<String, dynamic>> personelAdiminaGec(String salonid,String appbundle,String hizmetId) async {





  Map<String, dynamic> formData = {
    'sube': salonid,

    'appBundle': appbundle,
    'randevuhizmet':hizmetId,


    // Add other form fields
  };

  final response = await http.post(
    Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelAdiminaGec'),
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/musteri_sayilari_getir/$salonId'),
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/hizmetRaporlari'),
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/urunRaporlari'),
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/paketRaporlari'),
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/personelRaporlari'),
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/hizmet-musteri-listes'),
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/urun-musteri-listesi'),
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
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/paket-musteri-listesi'),
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
/// Musterinin aktif paket/hizmetlerini kontrol eder.
/// Bos liste donerse popup gosterme; doluysa popup ile secime izin ver.
Future<Map<String, dynamic>> paketVarmiKontrolu(String userId, String salonId) async {
  try {
    final response = await http.post(
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/paketVarmiKontrolu'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'sube': salonId,
        'paketRandevuOnayiVar': false,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    log('paketVarmiKontrolu HTTP ${response.statusCode}: ${response.body}');
    return {'paketVarMi': false, 'paketDetaylari': []};
  } catch (e) {
    log('paketVarmiKontrolu hatasi: $e');
    return {'paketVarMi': false, 'paketDetaylari': []};
  }
}

Future<Map<String, dynamic>> adisyonSil(String adisyonId) async {
  try {
    final response = await http.post(
      Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/adisyonSil'),
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

// =============================================================
// SMS YÖNETİMİ ENDPOINTS
// =============================================================

const String _smsApiBase = 'https://apptest.randevumcepte.com.tr/api/v1';

Future<Map<String, dynamic>> smsYonetimInit(String salonid) async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  String userId = '';
  try {
    var u = jsonDecode(localStorage.getString('user') ?? '{}');
    userId = u['id']?.toString() ?? '';
  } catch (_) {}
  final response = await http.get(
    Uri.parse('$_smsApiBase/sms-yonetim/init/$salonid?userId=$userId'),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimMusteriListele(
    String salonid, {
      int page = 1,
      int perPage = 200,
      String search = '',
      String cinsiyet = '',
      int karaliste = 0,
    }) async {
  final response = await http.post(
    Uri.parse('$_smsApiBase/sms-yonetim/musteri-listele/$salonid'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'page': page,
      'perPage': perPage,
      'search': search,
      'cinsiyet': cinsiyet,
      'karaliste': karaliste,
    }),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimTopluGonder(String salonid,
    {required List<int> musteriIdler, required String mesaj}) async {
  final response = await http.post(
    Uri.parse('$_smsApiBase/sms-yonetim/toplu-gonder/$salonid'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'musteri_idler': musteriIdler,
      'smsmesaj': mesaj,
    }),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimFiltreliGonder(String salonid,
    {required List<int> musteriIdler, required String mesaj}) async {
  final response = await http.post(
    Uri.parse('$_smsApiBase/sms-yonetim/filtreli-gonder/$salonid'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'musteri_idler': musteriIdler,
      'filtre_sms': mesaj,
    }),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimTaslakKaydet(String salonid,
    {required String baslik, required String icerik, String? id}) async {
  final response = await http.post(
    Uri.parse('$_smsApiBase/sms-yonetim/taslak-kaydet/$salonid'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'baslik': baslik,
      'icerik': icerik,
      if (id != null && id.isNotEmpty) 'id': id,
    }),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimTaslakSil(
    {required String salonId, required String id}) async {
  final response = await http.post(
    Uri.parse('$_smsApiBase/sms-yonetim/taslak-sil'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id': id, 'salonId': salonId}),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimRaporlar(String salonid) async {
  final response = await http.get(
    Uri.parse('$_smsApiBase/sms-yonetim/raporlar/$salonid'),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimRaporDetay(
    String salonid, String pkgId) async {
  final response = await http.post(
    Uri.parse('$_smsApiBase/sms-yonetim/rapor-detay/$salonid'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'pkg_id': pkgId}),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimAyarKaydet(String salonid,
    {required List<Map<String, dynamic>> ayarlar,
      int? randevuSmsHatirlatma}) async {
  final body = <String, dynamic>{'ayarlar': ayarlar};
  if (randevuSmsHatirlatma != null) {
    body['randevu_sms_hatirlatma'] = randevuSmsHatirlatma;
  }
  final response = await http.post(
    Uri.parse('$_smsApiBase/sms-yonetim/ayar-kaydet/$salonid'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimKaraListe(String salonid) async {
  final response = await http.get(
    Uri.parse('$_smsApiBase/sms-yonetim/karaliste/$salonid'),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimKaraListeEkle(
    String salonid, String userId) async {
  final response = await http.post(
    Uri.parse('$_smsApiBase/sms-yonetim/karaliste-ekle/$salonid'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId}),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimKaraListeSil(
    String salonid, String userId) async {
  final response = await http.post(
    Uri.parse('$_smsApiBase/sms-yonetim/karaliste-sil/$salonid'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId}),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> smsYonetimBakiye(String salonid) async {
  final response = await http.get(
    Uri.parse('$_smsApiBase/sms-yonetim/bakiye/$salonid'),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

// =============================================================
// ÇARKIFELEK ENDPOINTS
// =============================================================

const String _carkApiBase = 'https://apptest.randevumcepte.com.tr/api/v1';

Future<Map<String, dynamic>> carkDurum(String salonId, String userId) async {
  final response = await http.post(
    Uri.parse('$_carkApiBase/cark/durum'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'salon_id': salonId, 'user_id': userId}),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> carkCevir(String salonId, String userId) async {
  final response = await http.post(
    Uri.parse('$_carkApiBase/cark/cevir'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'salon_id': salonId, 'user_id': userId}),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> carkOdullerim(String userId) async {
  final response = await http.post(
    Uri.parse('$_carkApiBase/cark/odullerim'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId}),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> carkPuanOdullerim(String userId, {String? salonId}) async {
  final body = <String, dynamic>{'user_id': userId};
  if (salonId != null && salonId.isNotEmpty) body['salon_id'] = salonId;
  final response = await http.post(
    Uri.parse('$_carkApiBase/cark/puanodullerim'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

Future<Map<String, dynamic>> carkPuanOdulTalep(String userId, String salonId, int odulId) async {
  final response = await http.post(
    Uri.parse('$_carkApiBase/cark/puanodultalep'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId, 'salon_id': salonId, 'odul_id': odulId}),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  throw Exception(response.reasonPhrase);
}

// ============================================================
// ANKET YONETIMI API (mobil admin)
// ============================================================
const String _apiBase = 'https://apptest.randevumcepte.com.tr/api/v1';
Map<String, String> _jsonHeaders() => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

Future<List<Map<String, dynamic>>?> anketSablonListesi(String salonId) async {
  if (salonId.isEmpty) return null;
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/anketSablonlari/$salonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      if (body is Map && body['sablonlar'] is List) {
        return (body['sablonlar'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
  } catch (e) {
    log('anketSablonListesi: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> anketSablonDetay(String salonId, int sablonId) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/anketSablon/$salonId/$sablonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      if (body is Map && body['sablon'] is Map) {
        return Map<String, dynamic>.from(body['sablon'] as Map);
      }
    }
  } catch (e) {
    log('anketSablonDetay: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> anketSablonOlustur(String salonId, Map<String, dynamic> data) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/anketSablon/$salonId'),
      headers: _jsonHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('anketSablonOlustur: $e');
  }
  return null;
}

Future<bool> anketSablonGuncelle(String salonId, int sablonId, Map<String, dynamic> data) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/anketSablon/$salonId/$sablonId'),
      headers: _jsonHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return body is Map && body['basarili'] == true;
    }
  } catch (e) {
    log('anketSablonGuncelle: $e');
  }
  return false;
}

Future<Map<String, dynamic>?> anketSablonSil(String salonId, int sablonId) async {
  try {
    final res = await http.delete(
      Uri.parse('$_apiBase/anketSablon/$salonId/$sablonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('anketSablonSil: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> anketManuelGonder(String salonId, {
  required int sablonId,
  required String telefon,
  int? userId,
  String? adSoyad,
  int? randevuId,
  int? personelId,
}) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/anketManuelGonder/$salonId'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'sablon_id': sablonId,
        'telefon': telefon,
        if (userId != null) 'user_id': userId,
        if (adSoyad != null) 'ad_soyad': adSoyad,
        if (randevuId != null) 'randevu_id': randevuId,
        if (personelId != null) 'personel_id': personelId,
      }),
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('anketManuelGonder: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> anketGonderimDetay(String salonId, int gonderimId) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/anketGonderimDetay/$salonId/$gonderimId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('anketGonderimDetay: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> anketAyarlarGetir(String salonId) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/anketAyarlar/$salonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('anketAyarlarGetir: $e');
  }
  return null;
}

Future<bool> anketAyarlarKaydet(String salonId, Map<String, dynamic> data) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/anketAyarlar/$salonId'),
      headers: _jsonHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return body is Map && body['basarili'] == true;
    }
  } catch (e) {
    log('anketAyarlarKaydet: $e');
  }
  return false;
}

// ============================================================
// CARK-I FELEK ADMIN API (mobil)
// ============================================================

Future<Map<String, dynamic>?> carkAdminSistemGetir(String salonId) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/carkAdmin/sistem/$salonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('carkAdminSistemGetir: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> carkAdminDilimKaydet(String salonId, List<Map<String, dynamic>> dilimler, {int aktifmi = 1}) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/carkAdmin/dilim-kaydet/$salonId'),
      headers: _jsonHeaders(),
      body: jsonEncode({'dilimler': dilimler, 'aktifmi': aktifmi}),
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
    return {'basarili': false, 'mesaj': 'HTTP ${res.statusCode}: ${res.body}'};
  } catch (e) {
    log('carkAdminDilimKaydet: $e');
  }
  return null;
}

Future<bool> carkAdminAktifToggle(String salonId, bool aktif) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/carkAdmin/aktif-toggle/$salonId'),
      headers: _jsonHeaders(),
      body: jsonEncode({'aktifmi': aktif ? 1 : 0}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return body is Map && body['basarili'] == true;
    }
  } catch (e) {
    log('carkAdminAktifToggle: $e');
  }
  return false;
}

/// Salondaki uygulaması yüklü müşterilere çark duyuru push'u gönderir.
/// Dönüş: {basarili, gonderildi, hata, hedef} veya null (bağlantı hatası).
Future<Map<String, dynamic>?> carkAdminBildirimGonder(
  String salonId, {
  String? baslik,
  String? mesaj,
}) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/carkAdmin/bildirim-gonder/$salonId'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        if (baslik != null && baslik.trim().isNotEmpty) 'baslik': baslik.trim(),
        if (mesaj != null && mesaj.trim().isNotEmpty) 'mesaj': mesaj.trim(),
      }),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
    return {'basarili': false, 'mesaj': 'HTTP ${res.statusCode}'};
  } catch (e) {
    log('carkAdminBildirimGonder: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> carkAdminKazananlar(String salonId, {String filtre = 'tumu'}) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/carkAdmin/kazananlar/$salonId?filtre=$filtre'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('carkAdminKazananlar: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> carkAdminKuponDogrula(String salonId, String kod) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/carkAdmin/kupon-dogrula/$salonId'),
      headers: _jsonHeaders(),
      body: jsonEncode({'kod': kod}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200 || res.statusCode == 404 || res.statusCode == 403) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('carkAdminKuponDogrula: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> carkAdminKuponKullan(String salonId, int odulId, {String aksiyon = 'kullan'}) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/carkAdmin/kupon-kullan/$salonId'),
      headers: _jsonHeaders(),
      body: jsonEncode({'odul_id': odulId, 'aksiyon': aksiyon}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('carkAdminKuponKullan: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> carkAdminHatirlatmaGetir(String salonId) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/carkAdmin/hatirlatma/$salonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('carkAdminHatirlatmaGetir: $e');
  }
  return null;
}

Future<bool> carkAdminHatirlatmaKaydet(String salonId, Map<String, dynamic> data) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/carkAdmin/hatirlatma/$salonId'),
      headers: _jsonHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return body is Map && body['basarili'] == true;
    }
  } catch (e) {
    log('carkAdminHatirlatmaKaydet: $e');
  }
  return false;
}

// ============================================================
// WHATSAPP API (mobil)
// ============================================================

Future<Map<String, dynamic>?> whatsappBaslat(String salonId) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/whatsapp/baslat/$salonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('whatsappBaslat: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> whatsappDurum(String salonId) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/whatsapp/durum/$salonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('whatsappDurum: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> whatsappQR(String salonId) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/whatsapp/qr/$salonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('whatsappQR: $e');
  }
  return null;
}

Future<bool> whatsappCikis(String salonId) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/whatsapp/cikis/$salonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return body is Map && body['ok'] == true;
    }
  } catch (e) {
    log('whatsappCikis: $e');
  }
  return false;
}

Future<Map<String, dynamic>?> whatsappOzet(String salonId) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/whatsapp/ozet/$salonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('whatsappOzet: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> whatsappLoglar(String salonId, {
  int page = 1,
  int perPage = 50,
  int? durum,
  String? telefon,
  String? baslangic,
  String? bitis,
  String? arama,
}) async {
  try {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (durum != null) 'durum': '$durum',
      if (telefon != null && telefon.isNotEmpty) 'telefon': telefon,
      if (baslangic != null && baslangic.isNotEmpty) 'baslangic': baslangic,
      if (bitis != null && bitis.isNotEmpty) 'bitis': bitis,
      if (arama != null && arama.isNotEmpty) 'arama': arama,
    };
    final uri = Uri.parse('$_apiBase/whatsapp/loglar/$salonId').replace(queryParameters: params);
    final res = await http.get(uri, headers: _jsonHeaders()).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('whatsappLoglar: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> whatsappAliciler(String salonId) async {
  try {
    final url = '$_apiBase/whatsapp/aliciler/$salonId';
    final res = await http.get(
      Uri.parse(url),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 12));
    log('whatsappAliciler: GET $url -> ${res.statusCode}, body len: ${res.body.length}');
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return {'hata': 'Beklenmeyen yanıt formatı (Map değil)'};
    }
    return {'hata': 'Sunucu hatası: HTTP ${res.statusCode}'};
  } catch (e) {
    log('whatsappAliciler exception: $e');
    return {'hata': 'Bağlantı hatası: $e'};
  }
}

Future<Map<String, dynamic>?> whatsappAliciGecmis(String salonId, String telefon) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/whatsapp/alici/$salonId/$telefon'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('whatsappAliciGecmis: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> whatsappKanalDurum(String salonId) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/whatsapp/kanal-durum/$salonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('whatsappKanalDurum: $e');
  }
  return null;
}

Future<bool> whatsappKanalToggle(String salonId, bool aktif) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/whatsapp/kanal-toggle/$salonId'),
      headers: _jsonHeaders(),
      body: jsonEncode({'aktif': aktif ? 1 : 0}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return body is Map && body['ok'] == true;
    }
  } catch (e) {
    log('whatsappKanalToggle: $e');
  }
  return false;
}

Future<Map<String, dynamic>?> whatsappPaketDurum(String salonId) async {
  try {
    final res = await http.get(
      Uri.parse('$_apiBase/whatsapp/paket-durum/$salonId'),
      headers: _jsonHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('whatsappPaketDurum: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> whatsappPaketTalep(String salonId, {
  required String paket,
  required String periyot,
  String iletisim = '',
}) async {
  try {
    final res = await http.post(
      Uri.parse('$_apiBase/whatsapp/paket-talep/$salonId'),
      headers: _jsonHeaders(),
      body: jsonEncode({'paket': paket, 'periyot': periyot, 'iletisim': iletisim}),
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body) as Map);
    }
  } catch (e) {
    log('whatsappPaketTalep: $e');
  }
  return null;
}