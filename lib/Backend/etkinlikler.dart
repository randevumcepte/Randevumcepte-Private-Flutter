import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:randevu_sistem/Models/etkinlikler.dart';
import 'package:http/http.dart' as http;



class Services {

  //$reqeust->tarih1,$request->tarih2,$request->salon,$request->web,$request->uygulama,$request->durum,$isletme_id,''
  Future<List<Etkinlik>> etkinlikgetir() async {


    final response = await http.get(
      Uri.parse('https://app.randevumcepte.com.tr/api/v1/etkinlikyukle/114')
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);

      return jsonResponse.map((e) => Etkinlik.fromJson(e)).toList();
    } else {

      throw Exception(response.reasonPhrase);
    }

  }
}