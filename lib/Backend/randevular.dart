import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:randevu_sistem/Models/randevular.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/intl.dart';
class Services {

  //$reqeust->tarih1,$request->tarih2,$request->salon,$request->web,$request->uygulama,$request->durum,$isletme_id,''
  Future<List<Randevu>> randevularigetir(String olusturma,String durum,String tarih) async {
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
    log(tarih);
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
        tarih2 = DateFormat('yyyy-MM-dd').format(now);
      }
    log(tarih);
    if(durum == 'Tümü') {
      randevudurumu = '';
    }
    if(durum == 'Onay Bekleyen')
      randevudurumu = '0';
    if(durum == 'Onaylı')
      randevudurumu = '1';
    if(durum=='Reddedilen')
      randevudurumu = '2';
    if(durum=='müşteri tarafından iptal edilen')
      randevudurumu = '3';
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = jsonDecode(localStorage.getString('user')!);
    Map<String, dynamic> formData = {
        'tarih1': tarih1,
        'tarih2': tarih2,
        'salon': salon,
        'web':web,
        'uygulama':uygulama,
        'durum':randevudurumu,
        'userid':user['id'],

        // Add other form fields
    };
    log('formdata '+jsonEncode(formData).toString());

    final response = await http.post(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/randevular/126'),

        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);

        return jsonResponse.map((e) => Randevu.fromJson(e)).toList();
    } else {

        throw Exception(response.reasonPhrase);
    }

  }
}