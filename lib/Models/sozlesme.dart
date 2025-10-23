import 'dart:convert';

import 'package:randevu_sistem/Models/katilimcilar.dart';
class Sozlesme {
  Sozlesme({
    required this.id,
    required this.form_adi,



  });

  final String id;
  final String form_adi;


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'form_adi': form_adi,


    };
  }

  factory Sozlesme.fromJson(Map<String, dynamic> jsonvar) {

    return Sozlesme(
      id:jsonvar["id"].toString(),
      form_adi: jsonvar["form_adi"].toString(),




    );
  }
}