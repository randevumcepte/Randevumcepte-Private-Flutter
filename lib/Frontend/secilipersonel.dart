import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../Models/personel.dart';
import '../Models/user.dart';

Future<Personel>seciliPersonelgetir(dynamic isletmebilgi)
async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var kullaniciStr = prefs.getString('user');
  Kullanici kullanici = Kullanici.fromJson(jsonDecode(kullaniciStr!));
  var personelStr = kullanici.yetkili_olunan_isletmeler.firstWhere((element) => element["salon_id"].toString() == isletmebilgi["id"].toString());
  return Personel.fromJson(jsonDecode(jsonEncode(personelStr)));
}