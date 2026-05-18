// file_downloader.dart
//
// Cross-platform dosya indirme:
//
// Android (eski, < 11): Sistem Downloads klasorune (/storage/emulated/0/Download)
//   direkt yazar. Manifest'te WRITE_EXTERNAL_STORAGE (maxSdk=29) izni mevcut.
//   Kullanici dosyayi direkt "Indirilenler" klasorunde gorur.
//
// Android (modern, >= 11) ve iOS: Uygulamanin Documents klasoru altina indirir,
//   ardindan Share Sheet acar. Kullanici "Save to Files / Downloads" secip
//   istedigi yere kaydeder. iOS sandbox kurallari ve Android scoped storage
//   nedeniyle dogrudan sistem Downloads klasorune yazmak mumkun degildir.
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class FileDownloader {
  final Dio _dio = Dio();

  /// Dosyayi indirir. Eski Android'de dogrudan Downloads klasorune, diger
  /// platformlarda uygulama klasorune indirir ve Share Sheet acar.
  /// Donus: kaydedilen dosyanin yolu.
  Future<String> downloadFile(String url, String fileName) async {
    String? downloadDir;
    bool isAndroidLegacyDownloads = false;

    if (Platform.isAndroid) {
      // Eski Android: storage izni isteyip sistem Downloads klasorune yaz.
      // Android 11+ icin permission grant olsa bile bu yola yazma izni yok;
      // o durumda asagidaki fallback (Documents) devreye girer.
      try {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          final legacyDir = Directory('/storage/emulated/0/Download');
          if (await legacyDir.exists() || await _tryCreate(legacyDir)) {
            downloadDir = legacyDir.path;
            isAndroidLegacyDownloads = true;
          }
        }
      } catch (_) {
        // Yetki/path hatasi: fallback'e du.
      }
    }

    if (downloadDir == null) {
      // iOS veya modern Android: Documents/Downloads
      final base = Platform.isIOS
          ? await getApplicationDocumentsDirectory()
          : (await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory());
      final dir = Directory('${base.path}/Downloads');
      if (!await dir.exists()) await dir.create(recursive: true);
      downloadDir = dir.path;
    }

    final savePath = '$downloadDir/$fileName';

    try {
      final Response response = await _dio.download(url, savePath);
      if (response.statusCode != 200) {
        throw Exception('Failed to download file (status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }

    // Eski Android'de zaten sistem Downloads'a indi; ek aksiyon gerekmez.
    // Modern Android ve iOS'ta Share Sheet ile kullaniciya "nereye kaydedeyim"
    // secimi sunulur — Save to Files > Downloads ile gercek Downloads'a yazilabilir.
    if (!isAndroidLegacyDownloads) {
      try {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(savePath)], text: fileName),
        );
      } catch (_) {
        // Share basarisiz olsa bile dosya kayitli; yine de yolu donelim.
      }
    }

    return savePath;
  }

  Future<bool> _tryCreate(Directory dir) async {
    try {
      await dir.create(recursive: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
