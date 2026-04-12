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
import '../../../Backend/backend.dart';
import '../../../Frontend/filedownload.dart';
import '../../diger/menu/randvular/randevularmenu.dart';

class BildirimlerScreen extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  final VoidCallback? onNotificationRead; // Yeni callback eklendi
  const BildirimlerScreen({
    Key? key,
    required this.isletmebilgi,
    required this.kullanicirolu,
    this.onNotificationRead, // Yeni callback parametresi
  }) : super(key: key);

  @override
  _BildirimlerScreenState createState() => _BildirimlerScreenState();
}

class _BildirimlerScreenState extends State<BildirimlerScreen> {
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

    // Bildirim okundu olarak işaretlendikten sonra callback'i çağır
    if (widget.onNotificationRead != null) {
      widget.onNotificationRead!();
    }
  }

  Future<List<SistemBildirimleri>> fetchData(String salonid) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = jsonDecode(localStorage.getString('user')!);
    var personelid;

    var yetkiliolunanisletmeler = jsonDecode(jsonEncode(user['yetkili_olunan_isletmeler']));

    yetkiliolunanisletmeler.forEach((item) {
      if (item['salon_id'].toString() == salonid.toString()) {
        personelid = item['id'];
      }
    });

    if (personelid == null) {
      throw Exception('Personel ID bulunamadı');
    }

    final url = 'https://app.randevumcepte.com.tr/api/v1/bildirimgetir/$salonid/${personelid.toString()}';

    final response = await http.get(Uri.parse(url));

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

  String _formatTarih(String tarihsaat) {
    try {
      DateTime dateTime = DateTime.parse(tarihsaat);
      String gun = dateTime.day.toString().padLeft(2, '0');
      String ay = dateTime.month.toString().padLeft(2, '0');
      String yil = dateTime.year.toString();
      String saat = dateTime.hour.toString().padLeft(2, '0');
      String dakika = dateTime.minute.toString().padLeft(2, '0');

      return '$gun.$ay.$yil $saat:$dakika';
    } catch (e) {
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
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Veri yüklenirken bir hata oluştu. " + snapshot.error.toString()));
          } else if (snapshot.hasData) {
            final List<SistemBildirimleri> bildirimListe = snapshot.data!;

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

                      if (bildirimData.randevuid != "null") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RandevularMenu(
                              kullanicirolu: widget.kullanicirolu,
                              isletmebilgi: widget.isletmebilgi,
                              personelid: "",
                              cihazid: "",
                              personel_adi: "",
                              cihaz_adi: "",
                            ),
                          ),
                        );
                      }
                      if (bildirimData.randevuid == "null") {
                        String url='';
                        print(bildirimData.arsiv['uzanti']);
                        print(url);
                        await downloadPdf("https://app.randevumcepte.com.tr/"+bildirimData.arsiv['uzanti'], 'appointment_${bildirimData.id}', context);
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.network(
                            width: 40,
                            height: 40,
                            'https://app.randevumcepte.com.tr${bildirimData.avatar}',
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              } else {
                                return Container(
                                  width: 40,
                                  height: 40,
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
                                width: 40,
                                height: 40,
                              );
                            },
                          ),

                          SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  "${bildirimData.aciklama}",
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _formatTarih(bildirimData.tarihsaat),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text("Bildiriminiz bulunmamaktadır"));
          }
        },
      ),
    );
  }
}

// downloadPdf ve indirmedialoggoster fonksiyonları aynı kalacak
Future<void> downloadPdf(String url, String fileName, BuildContext context) async {
  // Request storage permission
  var status = await Permission.storage.request();
  if (!status.isGranted) {
    print('Permission denied');
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

  String filePath = '${downloadsDirectory.path}/$fileName.pdf'; // Ensure the file has a .pdf extension

  Dio dio = Dio();

  // Show a download progress dialog
  indirmedialoggoster(context, "PDF İndirme", downloadProgressNotifier);

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dosyanız başarıyla indirildi. '),
      ),
    );
    // Show success message
    print('File downloaded to: $filePath');

  } catch (e) {
    // Handle errors
    print('Error downloading file: $e');
  }
}

void indirmedialoggoster(BuildContext context, String title, ValueNotifier<int> progressNotifier) {
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
                    SizedBox(height: 10),
                    LinearProgressIndicator(value: value / 100),
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