// dialog.dart
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'filedownloader.dart'; // Import the FileDownloader class

import '../Models/colorandtext.dart';
import '../Models/form.dart';
import 'package:randevu_sistem/Frontend/datetimeformatting.dart';

void ArsivDetayGosterDialog(BuildContext context, Arsiv arsiv) {
  final _formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        insetPadding: EdgeInsets.zero,
        content: Container(

          width: 280,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                right: -40,
                top: -40,
                child: InkResponse(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.close),
                  ),
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 20,),
                    Text(
                      arsiv.musteridanisan["name"],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Divider(color: Colors.black, height: 10,),
                    Row(
                      children: [
                        Text('Tarih'),
                        SizedBox(width: 14,),
                        Text(': '),
                        Expanded(child: Text(formatDateTime(arsiv.tarih_saat)))
                      ],
                    ),
                    Row(
                      children: [
                        Text('Başlık'), SizedBox(width: 7,),
                        Text(':'),
                        Expanded(

                            child: Text(
                                arsiv.form["form_adi"] != 'harici' ? arsiv.form["form_adi"] : arsiv.sozlesme_adi))
                      ],
                    ),
                    Row(
                      children: [
                        Text('Durum'),
                        SizedBox(width: 2,),
                        Text(': '),
                        Expanded(child: Text(getStatusColorArsiv(arsiv.durum, arsiv.cevapladi, arsiv.cevapladi2).text))
                      ],
                    ),
                    Row(
                      children: [
                        Text('İşlem Yapan Personel'),
                        SizedBox(width: 2,),
                        Text(': '),
                        Expanded(child: Text(arsiv.personel["personel_adi"]))
                      ],
                    ),
                    Divider(color: Colors.black, height: 20,),
                    SizedBox(height: 10,),
                    Column(
                      crossAxisAlignment:CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 5,),
                        ElevatedButton(
                          onPressed: () {
                            // Handle form resend action
                          },
                          child: Text('Formu Tekrar Gönder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[800],
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            minimumSize: Size(110, 30),
                          ),
                        ),
                        SizedBox(width: 10,),
                        ElevatedButton(
                          onPressed: () async {
                            String formadi = arsiv.form["form_adi"] == "Harici Belge" ? arsiv.sozlesme_adi : arsiv.form["form_adi"];
                            String fileName = '${arsiv.musteridanisan["name"]}_${arsiv.tarih_saat}_$formadi.${path.extension(arsiv.uzanti)}';
                            final fileDownloader = FileDownloader();

                            try {
                              final filePath = await fileDownloader.downloadFile(
                                'https://app.randevumcepte.com.tr/${arsiv.uzanti}',
                                fileName,
                              );
                              log('File downloaded to: $filePath');
                            } catch (e) {
                              log('Failed to download file: $e');
                            }
                          },
                          child: Text('İndir', style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[600],
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            minimumSize: Size(90, 30),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}