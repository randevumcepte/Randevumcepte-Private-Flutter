import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../Login Sayfası/checklogin.dart' as widget;
import 'filedownload.dart';


ValueNotifier<dynamic> downloadProgressNotifier = ValueNotifier(0);
Future<void> dosyaIndir(String url, String fileName, BuildContext context) async {
  final downloadProgressNotifier = ValueNotifier<int>(0);

  Directory directory;
  if (Platform.isIOS) {
    directory = await getApplicationDocumentsDirectory();
  } else if (Platform.isAndroid) {
    directory = (await getExternalStorageDirectory())!;
  } else {
    throw UnsupportedError("İndirme desteklenmemektedir");
  }

  final filePath = '${directory.path}/$fileName';
  final dio = Dio();

  try {
    indirmedialoggoster(
      context,
      "Dosya indiriliyor",
      downloadProgressNotifier,
    );

    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final progress = ((received / total) * 100).round();
          downloadProgressNotifier.value = progress; // 🔥 BU SATIR ŞART
        }
      },
    );

    await Share.shareXFiles(
      [XFile(filePath)],
      text: "Ses kaydınız indirildi",
    );
  } catch (e) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // hata olursa dialog kapansın
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Dosya indirilemedi: $e")),
    );
  } finally {
    downloadProgressNotifier.dispose();
  }
}


/*Future<void> dosyaIndir(String url, String fileName, BuildContext context, ) async {

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
}*/