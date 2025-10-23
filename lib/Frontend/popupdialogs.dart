
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Backend/backend.dart';
Future<bool?> showKampanyaDeleteConfirmationDialog(BuildContext context, int id, Function onDeleteConfirmed)  {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Emin misiniz?'),
        content: Text('Silme işlemi geri alınamaz!'),
        actions: <Widget>[
          TextButton(
            child: Text('VAZGEÇ'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('SİL'),
            onPressed: () {
              log('sil sil sil '+ id.toString() );
              onDeleteConfirmed();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}



Future<bool?> formWarningDialogs(BuildContext context,String title, String description)  {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: <Widget>[
          TextButton(
            child: Text('TAMAM'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),

        ],
      );
    },
  );
}


Future<void> kampanyasil(BuildContext context, int id) async {
  Map<String, dynamic> formData = {
    'kampanyaid':id,
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/kampanyapasifet'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {

  }
  else {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kampanya silinirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
      ),
    );
    debugPrint('Error: ${response.body}');
  }
}
Future<void> ajandasil(BuildContext context, String id) async {
  Map<String, dynamic> formData = {
    'id':id,
  };

  final response = await http.post(
    Uri.parse('https://app.randevumcepte.com.tr/api/v1/ajandasil'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(formData),
  );

  if (response.statusCode == 200) {

  }
  else {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notunuz silinirken bir hata oluştu! Hata kodu : '+response.statusCode.toString()),
      ),
    );
    debugPrint('Error: ${response.body}');
  }
}
Future<bool?> showEtkinlikDeleteConfirmationDialog(BuildContext context, int id, Function onDeleteConfirmed)  {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Emin misiniz?'),
        content: Text('Silme işlemi geri alınamaz!'),
        actions: <Widget>[
          TextButton(
            child: Text('VAZGEÇ'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('SİL'),
            onPressed: () {
              log('sil sil sil '+ id.toString() );
              onDeleteConfirmed();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
Future<void> showSatisYapilmamaNedeniDialog(BuildContext context, String ongorusmeid,String currentPage,String arama,Function(Map<String, dynamic> value)? fetchDataCallback )async {
  TextEditingController aciklamaController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext buildContext) {
      return StatefulBuilder(
        builder: (buildContext, StateSetter setState) {
          return AlertDialog(
            scrollable: true,
            title: Text('Satış Yapılmama Sebebi'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10,),
                  Padding(
                    padding: const EdgeInsets.only(left: 0.0),
                    child: Text('Açıklama', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),),
                  ),
                  SizedBox(height: 10,),
                  Container(
                    height: 110,
                    child: TextField(
                      controller: aciklamaController,  // Set the controller
                      keyboardType: TextInputType.text,
                      maxLines: 6,
                      decoration: InputDecoration(
                        focusColor: Color(0xFF6A1B9A),
                        hoverColor: Color(0xFF6A1B9A),
                        hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
                        contentPadding: EdgeInsets.all(15.0),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(buildContext).pop();
                },
                child: Text('Kapat', style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(buildContext).pop();

                    satisyapilmadi(context, ongorusmeid, aciklamaController.text,currentPage.toString(), arama, false).then((value) {
                      if (fetchDataCallback != null) {
                        fetchDataCallback(value); // Invoke the passed callback
                      }
                    });


                },
                child: Text('Kaydet', style: TextStyle(color: Colors.purple[800])),
              ),
            ],
          );
        },
      );
    },
  );
}

