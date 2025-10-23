import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Login Sayfası/checklogin.dart' as widget;
import 'filedownload.dart';


ValueNotifier<dynamic> downloadProgressNotifier = ValueNotifier(0);
Future<void> dosyaIndir(String url, String fileName, BuildContext context, ) async {

  var status = await Permission.storage.request();
  if (!status.isGranted) {
    print('Permission denied');
    return;
  }

  downloadProgressNotifier.value = 0;
  Directory directory = Directory("");
  if (Platform.isAndroid) {
    directory = (await getExternalStorageDirectory())!;
  } else {
    directory = (await getApplicationDocumentsDirectory());
  }


  try {
    Directory downloadsDirectory;
    try {
      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDirectory = await getApplicationDocumentsDirectory();
      } else {
        throw UnsupportedError("İndirme desteklenmemektedir");
      }
    } catch (e) {
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(e.toString()), duration: Duration(seconds: 2)),
      );
      return;
    }
    String filePath = '${downloadsDirectory.path}/$fileName';
    Dio dio = Dio();
    indirmedialoggoster(context,"Dosya indirme",downloadProgressNotifier);
    await dio.download(url, filePath, onReceiveProgress: (actualBytes, int totalBytes) {
      downloadProgressNotifier.value = (actualBytes / totalBytes * 100).floor();
    });


  } catch (e) {

  }
}