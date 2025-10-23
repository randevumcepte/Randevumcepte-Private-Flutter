import 'dart:io';


import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/dashboard/bildirimler/bildirimler_class.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

import 'package:flutter/cupertino.dart';

import '../../../Backend/backend.dart';
import '../../../Frontend/filedownload.dart';
import '../../diger/menu/randvular/randevularmenu.dart';


class BildirimlerScreen extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const BildirimlerScreen({Key? key,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

  @override
  _BildirimlerScreenState createState() =>
      _BildirimlerScreenState();
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
    // Initialize items with an empty list Future to avoid LateInitializationError
    items = Future.value([]);
    _fetchData();
  }
  Future<void> markAsRead(String notificationId) async {
    Map<String, dynamic> formData = {
      'bildirim_id': notificationId,
    };
    final url = 'https://app.randevumcepte.com.tr/api/v1/bildirimguncelle'; // Adjust the endpoint as needed
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(formData), // Assuming the API accepts this payload
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      log('Error: ${response.statusCode}, ${response.reasonPhrase}');
      throw Exception('Failed to mark notification as read');
    }
  }
  Future<List<SistemBildirimleri>> fetchData(String salonid) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = jsonDecode(localStorage.getString('user')!);
    var personelid;


    // Debugging user information

    log('userinfo : ' + user['yetkili_olunan_isletmeler'].toString());

    var yetkiliolunanisletmeler = jsonDecode(jsonEncode(user['yetkili_olunan_isletmeler']));

    // Fetch personelid and okundu for the given salon
    yetkiliolunanisletmeler.forEach((item) {
      if (item['salon_id'].toString() == salonid.toString()) {

        personelid = item['id'];

      }
    });

    // Check if personelid or okundu is null
    if (personelid == null) {
      throw Exception('Personel ID bulunamadı');
    }


    final url = 'https://app.randevumcepte.com.tr/api/v1/bildirimgetir/$salonid/${personelid.toString()}';


    // Make the API request
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
            return Text("Yükleniyor");
          } else if (snapshot.hasError) {
            return Text("Veri yüklenirken bir hata oluştu. " + snapshot.error.toString());
          } else if (snapshot.hasData) {
            final List<SistemBildirimleri> bildirimListe = snapshot.data!;

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: bildirimListe.length,
              itemBuilder: (BuildContext context, int index) {
                final bildirimData = bildirimListe[index];
                final bool isRead = bildirimData.okundu == '1';  // Check if the notification is read (1) or unread (0)
                log(bildirimData.arsiv.toString());
                return Card(
                  elevation: 3.0,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  color: isRead ? Colors.white : Color(0xFFF9EEFF),  // White for read, purple for unread
                  child: ListTile(
                    leading: Image.network(
                      width: 30,
                      height: 30,
                      'https://app.randevumcepte.com.tr${bildirimData.avatar}',
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          );
                        }
                      },
                      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                        return Image.asset(
                          'images/randevumcepteicon.png',
                          width: 30,
                          height: 30,
                        );
                      },
                    ),
                    subtitle: Text("${bildirimData.aciklama}"),
                    trailing: Icon(Icons.chevron_right),onTap: () async {
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
                          builder: (context) => RandevularMenu( kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi,personelid: "",cihazid: "",personel_adi: "",cihaz_adi: "",),
                        ),
                      );
                    } if (bildirimData.randevuid == "null") {
                      String url='';
                      print(bildirimData.arsiv['uzanti']);
                      print(url);
                      await downloadPdf("https://app.randevumcepte.com.tr/"+bildirimData.arsiv['uzanti'], 'appointment_${bildirimData.id}', context);
                    }
                  },


                  ),
                );
              },
            );

          } else {
            return Text("Bildiriminiz bulunmamaktadır");
          }
        },
      ),
    );
  }
}Future<void> downloadPdf(String url, String fileName, BuildContext context) async {
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