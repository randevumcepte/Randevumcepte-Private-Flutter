/*// @dart=2.19.5
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:sip_ua/sip_ua.dart';


import 'Frontend/randevuguncellemeprovider.dart';
import 'Frontend/indexedstack.dart';
import 'Login Sayfası/checklogin.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // OneSignal, SharedPreferences vs. için gerekli
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Splash ekranı göster
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // OneSignal kurulumu
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("5e50f84e-2cd8-4532-a765-f2cb82a22ff9");

  await OneSignal.Notifications.requestPermission(true);

  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    // Bildirimi varsayılan şekilde göstermek:
    // Hiçbir şey yapma, bildirim otomatik gösterilir
    // Bildirimi iptal etmek için:
    event.preventDefault(); // Bu bildirimin gösterilmesini engeller
  });

  OneSignal.User.pushSubscription.addObserver((event) async {
    final userId = OneSignal.User.pushSubscription.id;
    if (userId != null && userId.isNotEmpty) {
      log('OneSignal User ID updated: $userId');
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('onesignal_player_id', userId);
    }
  });

  OneSignal.Notifications.addPermissionObserver((state) {
    log("Permission state changed");
  });

  // Burada işlemleri bitirdikten sonra splash ekranını kaldır
  await Future.delayed(Duration(seconds: 3));

  // Splash ekranı sona erdiğinde `FlutterNativeSplash.remove()` ile ekranı kaldırıyoruz
  FlutterNativeSplash.remove();


  // runApp en sona alınmalı
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => IndexedStackState()),
      ],
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('tr'),
      ],
      locale: const Locale('tr'),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _opacity = 0.0;
  @override
  void initState() {

    super.initState();

    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _opacity = 1.0;
      });
    });
    // Widget tree'inin tam olarak yerleşmesini bekleyin ve sonra yönlendirmeyi yapın.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Yönlendirmeyi burada yapabilirsiniz
      // 3 saniye bekleyip splash ekranını kaldır, sonra yönlendir
      Future.delayed(Duration(seconds: 3), () {
        FlutterNativeSplash.remove();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CheckAuth()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          duration: Duration(seconds: 2),
          opacity: _opacity,
          child: Image.asset(
            "images/randevumcepte.png",
            height: 400,
          ),
        ),
      ),
    );
  }
}*/
