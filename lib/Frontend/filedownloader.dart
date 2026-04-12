// file_downloader.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileDownloader {
  final Dio _dio = Dio();

  Future<String> downloadFile(String url, String fileName) async {
    try {
      var status = await Permission.storage.request();
      if (status.isGranted) {
        final String downloadPath = '/storage/emulated/0/Download'; // Specify the target download directory

        // Ensure the Download directory exists
        final dir = Directory(downloadPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final String savePath = '$downloadPath/$fileName';

        // Start the download
        final Response response = await _dio.download(url, savePath);

        if (response.statusCode == 200) {
          return savePath; // Return the file path on successful download
        } else {
          throw Exception('Failed to download file');
        }
      } else {
        throw Exception('Storage permission not granted');
      }
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }
}