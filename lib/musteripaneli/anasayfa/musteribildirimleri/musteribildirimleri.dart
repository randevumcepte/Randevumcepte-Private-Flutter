import 'dart:io';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/dashboard/bildirimler/bildirimler_class.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/filedownload.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/yonetici/diger/menu/randvular/randevularmenu.dart';

import '../../randevularim/randevularim.dart';

class MusteriBildirimlerScreen extends StatefulWidget {
  final dynamic isletmebilgi;
  final MusteriDanisan md;

  const MusteriBildirimlerScreen({Key? key,required this.isletmebilgi,required this.md}) : super(key: key);

  @override
  _MusteriBildirimlerScreenState createState() =>
      _MusteriBildirimlerScreenState();
}

class _MusteriBildirimlerScreenState extends State<MusteriBildirimlerScreen> {
  late Future<List<SistemBildirimleri>> items;
  final _formKey = GlobalKey<FormState>();
  Map<String, bool> clickedNotifications = {};
  late String seciliisletme;

  void _fetchData() async {
    seciliisletme = widget.isletmebilgi['id'].toString();

    setState(() {
      items = fetchData(seciliisletme);
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize items with an empty list Future to avoid LateInitializationError
    items = Future.value([]);
    _fetchData();
  }

  Future<void> markAsRead(String notificationId) async {
    Map<String, dynamic> formData = {
      'bildirim_id': notificationId,
    };
    final url = 'https://app.randevumcepte.com.tr/api/v1/bildirimguncelle';
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(formData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      log('Error: ${response.statusCode}, ${response.reasonPhrase}');
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<List<SistemBildirimleri>> fetchData(String salonid) async {
    final url = 'https://app.randevumcepte.com.tr/api/v1/bildirimgetirmusteri';

    Map<String, dynamic> formData = {
      'sube': '352',
      'user_id': widget.md.id.toString(),
    };

    // Make the API request
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data.map((item) => SistemBildirimleri.fromJson(item)).toList();
      } else {
        throw Exception("Bildiriminiz bulunmamaktadır");
      }
    } else {
      log('Error: ${response.statusCode}, ${response.reasonPhrase}');
      throw Exception('Failed to load data');
    }
  }

  // Tarih formatını düzenleyen yardımcı fonksiyon
  String _formatTarih(String tarihsaat) {
    try {
      // Tarih formatını parse et
      DateTime dateTime = DateTime.parse(tarihsaat);

      // Türkçe tarih formatı
      String gun = dateTime.day.toString().padLeft(2, '0');
      String ay = dateTime.month.toString().padLeft(2, '0');
      String yil = dateTime.year.toString();
      String saat = dateTime.hour.toString().padLeft(2, '0');
      String dakika = dateTime.minute.toString().padLeft(2, '0');

      return '$gun.$ay.$yil $saat:$dakika';
    } catch (e) {
      // Eğer tarih parse edilemezse orijinal string'i döndür
      return tarihsaat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bildirimler', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 60,
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder<List<SistemBildirimleri>>(
        future: items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Bildirimler yükleniyor...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      "Veri yüklenirken bir hata oluştu: ${snapshot.error.toString()}",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchData,
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final List<SistemBildirimleri> bildirimListe = snapshot.data!;

            if (bildirimListe.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Bildiriminiz bulunmamaktadır',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: bildirimListe.length,
              itemBuilder: (BuildContext context, int index) {
                final bildirimData = bildirimListe[index];
                final bool isRead = bildirimData.okundu == '1';

                return Card(
                  elevation: 3.0,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  color: isRead ? Colors.white : Color(0xFFF9EEFF),
                  child: InkWell(
                    onTap: () async {
                      if (!isRead) {
                        await markAsRead(bildirimData.id);
                        setState(() {
                          bildirimData.okundu = '1';
                        });
                      }

                      // Check if randevu_id is not null
                      if (bildirimData.randevuid != "null") {
                        // Navigate to the appointments page and pass the randevu_id if needed
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MusteriRandevulari(
                              isletmebilgi: widget.isletmebilgi,
                              md: widget.md,
                              geriButonu: true,
                            ),
                          ),
                        );
                      }
                      if (bildirimData.randevuid == "null") {
                        String url = '';
                        print(bildirimData.arsiv['uzanti']);
                        print(url);
                        await downloadPdf(
                            "https://app.randevumcepte.com.tr/" + bildirimData.arsiv['uzanti'],
                            'appointment_${bildirimData.id}',
                            context
                        );
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar/Icon
                          Container(
                            width: 40,
                            height: 40,
                            child: Image.network(
                              'https://app.randevumcepte.com.tr${bildirimData.avatar}',
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                } else {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                }
                              },
                              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                return Image.asset(
                                  'images/randevumcepteicon.png',
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                          ),

                          SizedBox(width: 12),

                          // Bildirim içeriği - Geniş alan
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            

                                // Açıklama - TAM METİN
                                Text(
                                  "${bildirimData.aciklama}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.left,
                                ),

                                SizedBox(height: 8),

                                // Tarih ve okunma durumu - Sağ alt köşede
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Okunma durumu
                                    if (!isRead)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Yeni',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(),

                                    // Tarih ve saat
                                    Text(
                                      _formatTarih(bildirimData.tarihsaat),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: 8),

                          // Chevron icon
                          Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: Text(
                "Bildiriminiz bulunmamaktadır",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
        },
      ),
    );
  }
}

Future<void> downloadPdf(String url, String fileName, BuildContext context) async {
  // Request storage permission
  var status = await Permission.storage.request();
  if (!status.isGranted) {
    print('Permission denied');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dosya indirme izni reddedildi.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Initializing the download progress notifier
  ValueNotifier<int> downloadProgressNotifier = ValueNotifier<int>(0);

  // Get the downloads directory based on the platform
  Directory downloadsDirectory;
  if (Platform.isAndroid) {
    downloadsDirectory = Directory('/storage/emulated/0/Download');
  } else if (Platform.isIOS) {
    downloadsDirectory = await getApplicationDocumentsDirectory();
  } else {
    throw UnsupportedError("Download is not supported on this platform");
  }

  String filePath = '${downloadsDirectory.path}/$fileName.pdf';

  Dio dio = Dio();

  // Show a download progress dialog
  _showDownloadDialog(context, "PDF İndirme", downloadProgressNotifier);

  try {
    // Start the download
    await dio.download(
      url,
      filePath,
      onReceiveProgress: (actualBytes, totalBytes) {
        // Update the download progress
        downloadProgressNotifier.value = (actualBytes / totalBytes * 100).floor();
      },
    );

    // Close the progress dialog
    Navigator.of(context, rootNavigator: true).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dosyanız başarıyla indirildi: $filePath'),
        backgroundColor: Colors.green,
      ),
    );

    print('File downloaded to: $filePath');

  } catch (e) {
    // Close the progress dialog
    Navigator.of(context, rootNavigator: true).pop();

    // Handle errors
    print('Error downloading file: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dosya indirilirken hata oluştu: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void _showDownloadDialog(BuildContext context, String title, ValueNotifier<int> progressNotifier) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: progressNotifier,
              builder: (context, value, child) {
                return Column(
                  children: [
                    Text('İndiriliyor: $value%'),
                    SizedBox(height: 16),
                    LinearProgressIndicator(value: value / 100),
                    SizedBox(height: 8),
                    Text(
                      'Lütfen bekleyin...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    },
  );
}