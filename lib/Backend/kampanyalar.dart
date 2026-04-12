import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;



import '../Models/kampanyalar.dart';

class Services {

  //$reqeust->tarih1,$request->tarih2,$request->salon,$request->web,$request->uygulama,$request->durum,$isletme_id,''
  Future<List<Kampanya>> etkinlikgetir() async {


    final response = await http.get(
        Uri.parse('https://app.randevumcepte.com.tr/api/v1/kampanyalar/114')
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);

      return jsonResponse.map((e) => Kampanya.fromJson(e)).toList();
    } else {

      throw Exception(response.reasonPhrase);
    }

  }
}