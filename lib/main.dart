import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Backend/backend.dart';
import 'Frontend/indexedstack.dart';
import 'Frontend/randevuguncellemeprovider.dart';
import 'Login Sayfası/checklogin.dart';
import 'Login Sayfası/tanitim.dart';
import 'navigatorkey.dart';

late SharedPreferences prefs;

// Firebase background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔹 Firebase background mesaj alındı");
}



// FCM token alma
Future<void> _initFCMToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      print("✅ FCM token alındı: $token");
      prefs.setString('fcm_token', token);
    }
  } catch (e) {
    print("❌ FCM token alınamadı: $e");
  }
}

// OneSignal Player ID alma
Future<void> ensurePlayerId() async {
  for (int i = 0; i < 10; i++) {
    final playerId = OneSignal.User.pushSubscription.id;
    if (playerId != null && playerId.isNotEmpty) {
      prefs.setString('onesignal_player_id', playerId);
      print("✅ OneSignal Player ID: $playerId");
      return;
    }
    await Future.delayed(Duration(seconds: 1));
  }
  print("❌ OneSignal Player ID alınamadı");
}

// Main
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) SharedPreferences MUST come first
  prefs = await SharedPreferences.getInstance();

  // 2) Firebase init
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3) OneSignal init
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("6242e410-2d78-4ec9-9ea5-14e63be12bb7");

  // 4) iOS push permission
  await OneSignal.Notifications.requestPermission(true);


  // 5) Player ID alma
  await ensurePlayerId();

  // 6) Android 13+ izin
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }

  // 7) Uygulamayı başlat
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => IndexedStackState()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        navigatorKey: navigatorKey,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [const Locale('tr')],
        locale: const Locale('tr'),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _opacity = 0.0;
  bool _forceUpdateShown = false;
  @override
  @override
  void initState() {
    super.initState();
    print("1️⃣ initState çalıştı"); // Bu logu görmelisiniz

    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print("2️⃣ addPostFrameCallback çalıştı"); // Bu logu görüyor musunuz?

      print("3️⃣ checkVersion çağrılıyor...");
      await checkVersion(context);
      print("4️⃣ checkVersion tamamlandı");

      if (!_forceUpdateShown) {
        print("5️⃣ Splash timer başlıyor");
        Future.delayed(Duration(seconds: 3), () {
          print("6️⃣ Navigate to CheckAuth");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CheckAuth()),
          );
        });
      }
    });
  }
  Future<void> checkVersion(BuildContext context) async {
    print("🚀🚀🚀 checkVersion METODUNA GİRİLDİ 🚀🚀🚀");

    try {
      print("Step 1: PackageInfo alınıyor...");
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String appBundle = await appBundleAl();
      String localVersion = packageInfo.version;

      print("Step 2: Local versiyon = '$localVersion'");
      print("Step 3: App Bundle = '$appBundle'");

      Map<String, dynamic> formData = {
        'appBundle': appBundle,
      };

      print("Step 4: HTTP isteği atılıyor...");
      final response = await http.post(
        Uri.parse("https://app.randevumcepte.com.tr/api/v1/versiyonAppKontrol"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      );

      print("Step 5: HTTP yanıt kodu = ${response.statusCode}");
      print("Step 6: HTTP yanıt body = ${response.body}");

      if (response.statusCode != 200) {
        print("❌ HTTP hatası: ${response.statusCode}");
        return;
      }

      final data = jsonDecode(response.body);
      print("Step 7: Parsed data = $data");

      // Platform kontrolü - DOĞRU YOL
      bool isAndroid = Platform.isAndroid;
      print("Step 8: Platform = ${isAndroid ? 'Android' : 'iOS'}");

      String latest = isAndroid ? data["android_latest"] : data["ios_latest"];
      print("Step 9: Latest versiyon = '$latest'");

      if (latest == null || latest.isEmpty) {
        print("❌ Latest versiyon boş veya null!");
        return;
      }

      String forceMessage = "Uygulamamızın güncellenmiş sürümü mevcut. Devam edebilmeniz için lütfen güncelleyiniz.";

      print("Step 10: Versiyon karşılaştırma yapılıyor...");
      print("Local: '$localVersion' vs Latest: '$latest'");

      bool needsUpdate = _isLower(localVersion, latest);
      print("Step 11: Güncelleme gerekli mi? = $needsUpdate");

      if (needsUpdate) {
        print("⚠️ GÜNCELLEME GEREKLİ! Dialog gösteriliyor...");
        _forceUpdateShown = true;
        _showForceUpdate(
            context,
            forceMessage,
            data['play_store'],
            data['app_store'],
            data['app_gallery']
        );
      } else {
        print("✅ Versiyon güncel, güncelleme gerekmez");
      }

    } catch (e, stackTrace) {
      print("❌ Version check error: $e");
      print("Stack trace: $stackTrace");
    }

    print("🚀🚀🚀 checkVersion METODU TAMAMLANDI 🚀🚀🚀");
  }
  bool _isLower(String v1, String v2) {
    print("🔍 _isLower: '$v1' < '$v2' ?");

    List<String> a = v1.split(".");
    List<String> b = v2.split(".");

    print("Split a: $a");
    print("Split b: $b");

    for (int i = 0; i < 3; i++) {
      int x = int.parse(a[i]);
      int y = int.parse(b[i]);
      print("Karşılaştırma $i: $x < $y = ${x < y}");

      if (x < y) {
        print("✅ $v1 < $v2 -> true");
        return true;
      }
      if (x > y) {
        print("❌ $v1 > $v2 -> false");
        return false;
      }
    }
    print("❌ Versiyonlar eşit -> false");
    return false;
  }

  // ZORUNLU (KAPAT YOK)
  _showForceUpdate(BuildContext context, String message,String androidURL, String iosURL, String huaweiURL) {
    showDialog(
      barrierDismissible: false, // dışa tıklamayla kapanmayı engelle
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // geri tuşunu engelle
        child: AlertDialog(
          title: Text("Güncelleme Gerekli"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                _openStore(androidURL, iosURL, huaweiURL);
              },
              child: Text("GÜNCELLE"),
            ),
          ],
        ),
      ),
    );
  }
  // İSTEĞE BAĞLI
  /*void _showOptionalUpdate(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Yeni Sürüm Mevcut"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("DAHA SONRA"),
          ),
          TextButton(
            onPressed: () {
              _openStore();
            },
            child: Text("GÜNCELLE"),
          ),
        ],
      ),
    );
  }*/

  Future<void> _openStore(String androidURL,String iosURL, String huaweiURL) async {
    if (Platform.isAndroid) {
      String packageName = await appBundleAl();

      final Uri marketUri = Uri.parse("market://details?id=$packageName");
      final Uri webUri = Uri.parse(androidURL);

      // Önce market:// açmayı dene
      /*if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else {*/
      // market:// çalışmazsa web fallback
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      // }
    }

    else if (Platform.isIOS) {
      final Uri iosUri = Uri.parse(iosURL);
      await launchUrl(iosUri, mode: LaunchMode.externalApplication);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          duration: Duration(seconds: 3),
          opacity: _opacity,
          child: Image.asset(
            "images/bercislina.png",
            height: 200,
          ),
        ),
      ),
    );
  }
}
