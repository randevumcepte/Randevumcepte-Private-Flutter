import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/indexedstack.dart';
import 'package:randevu_sistem/Frontend/no_internet_screen.dart';
import 'package:randevu_sistem/Frontend/route_observer.dart';
import 'package:randevu_sistem/Frontend/randevuguncellemeprovider.dart';
import 'package:randevu_sistem/Login Sayfası/checklogin.dart';
import 'package:randevu_sistem/navigatorkey.dart';
import 'package:randevu_sistem/services/notification_service.dart';
import 'package:randevu_sistem/theme/app_theme.dart';
import 'package:randevu_sistem/theme/theme_provider.dart';

late SharedPreferences prefs;

// Main
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) SharedPreferences MUST come first
  prefs = await SharedPreferences.getInstance();

  // 2) Firebase init
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(rmcNotificationBackgroundHandler);

  // 3) Bildirim altyapısı (FCM + local + foreground + tıklama + popup)
  await NotificationService.instance.init();

  // 4) Yetki cache'ini disktan belege yukle (varsa). Personeller sayfasi
  //    acilirken tazelenecek; bu sadece onceki oturumun ayarlarini yukler.
  await Yetki.baslat();

  // 5) Uygulamayı başlat
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => IndexedStackState()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs: prefs)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final platformBrightness =
              MediaQuery.platformBrightnessOf(context);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.fromConfig(
              themeProvider.config,
              platformBrightness: platformBrightness,
            ),
            navigatorKey: navigatorKey,
            navigatorObservers: [appRouteObserver],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('tr')],
            locale: const Locale('tr'),
            home: MyHomePage(),
          );
        },
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
  bool _offline = false;
  @override
  void initState() {
    super.initState();
    print("1️⃣ initState çalıştı"); // Bu logu görmelisiniz

    Future.delayed(Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _opacity = 1.0;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    print("2️⃣ addPostFrameCallback çalıştı");

    // Once internet baglantisini dogrula. Yoksa preloader'i kes, modern
    // "internet yok" ekranini goster.
    final online = await hasInternetConnection();
    if (!online) {
      print("📡 Internet yok — NoInternetScreen gosteriliyor");
      if (mounted) setState(() => _offline = true);
      return;
    }

    print("3️⃣ checkVersion çağrılıyor...");
    await checkVersion(context);
    print("4️⃣ checkVersion tamamlandı");

    if (!_forceUpdateShown) {
      print("5️⃣ Splash timer başlıyor");
      Future.delayed(Duration(seconds: 3), () {
        if (!mounted) return;
        print("6️⃣ Navigate to CheckAuth");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CheckAuth()),
        );
      });
    }
  }

  Future<void> _retryFromOffline() async {
    final online = await hasInternetConnection();
    if (!online) return; // hala yok — NoInternetScreen acik kalsin
    if (!mounted) return;
    setState(() => _offline = false);
    // Splash akisini bastan baslat (opacity tekrar fade in olsun).
    setState(() => _opacity = 0.0);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() => _opacity = 1.0);
    });
    await _bootstrap();
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
        Uri.parse("https://apptest.randevumcepte.com.tr/api/v1/versiyonAppKontrol"),
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
    if (_offline) {
      return NoInternetScreen(onRetry: _retryFromOffline);
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          duration: Duration(seconds: 3),
          opacity: _opacity,
          child: Image.asset(
            "images/randevumcepte.png",
            height: 200,
          ),
        ),
      ),
    );
  }
}
