/*import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/calls_model.dart';
import 'package:siprix_voip_sdk/logs_model.dart';
import 'package:siprix_voip_sdk/siprix_voip_sdk.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  AccountsModel accountsModel = AccountsModel();
  CallsModel callsModel = CallsModel(accountsModel);
  runApp(
      MultiProvider(providers:[
        ChangeNotifierProvider(create: (context) => accountsModel),
        ChangeNotifierProvider(create: (context) => callsModel),
      ],
        child: const MyApp(),
      ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeSiprix();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Siprix VoIP app',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(body:buildBody())
    );
  }

  Widget buildBody() {
    final accounts = context.watch<AccountsModel>();
    final calls = context.watch<CallsModel>();
    return Column(children: [
      ListView.separated(shrinkWrap: true,
        itemCount: accounts.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          AccountModel acc = accounts[index];
          return
            ListTile(title: Text(acc.uri, style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text(acc.regText),
                tileColor: Colors.blue
            );
        },
      ),
      ElevatedButton(onPressed: _addAccount, child: const Icon(Icons.add_card)),
      const Divider(height: 1),
      ListView.separated(shrinkWrap: true,
        itemCount: calls.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          CallModel call = calls[index];
          return
            ListTile(title: Text(call.nameAndExt,
                style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text(call.state.name), tileColor: Colors.amber,
                trailing: IconButton(
                    onPressed: (){ call.bye(); },
                    icon: const Icon(Icons.call_end))
            );
        },
      ),
      ElevatedButton(onPressed: _addCall, child: const Icon(Icons.add_call)),
      const Spacer(),
    ]);
  }
  Future<void> _initializeFCM() async {
    if(Platform.isAndroid) {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }
  @pragma('vm:entry-point')
  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    try{
      //Siprix initialization same for main and background isolates
      _initializeSiprix();

      //Read accounts to temporary model and register them
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String accJsonStr = prefs.getString('accounts') ?? '';
      if(accJsonStr.isNotEmpty) {
        AppAccountsModel tmpAccsModel = AppAccountsModel();
        tmpAccsModel.loadFromJson(accJsonStr);
        tmpAccsModel.refreshRegistration();
      }
    } on Exception catch (err) {
      debugPrint('Error: ${err.toString()}');
    }
  }
  void _initializeSiprix([LogsModel? logsModel]) async {
    InitData iniData = InitData();
    iniData.license  = "...license-credentials...";
    iniData.logLevelFile = LogLevel.info;
    SiprixVoipSdk().initialize(iniData, logsModel);
  }

  void _addAccount() {
    AccountModel account = AccountModel();
    account.sipServer = "34.45.69.65";
    account.sipExtension = "32";
    account.sipPassword = "randevumcepte";
    account.expireTime = 300;
    context.read<AccountsModel>().addAccount(account)
        .catchError(showSnackBar);
  }

  void _addCall() {
    final accounts = context.read<AccountsModel>();
    if(accounts.selAccountId==null) return;

    CallDestination dest = CallDestination("1012", accounts.selAccountId!, false);

    context.read<CallsModel>().invite(dest)
        .catchError(showSnackBar);
  }

  void showSnackBar(dynamic err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
}
class AppAccountsModel extends AccountsModel {
  AppAccountsModel([this._logs]) : super(_logs);
  final ILogsModel? _logs;

  @override
  Future<void> addAccount(AccountModel acc, {bool saveChanges = true}) async {
    String? token;
    if (Platform.isIOS) {
      token =
      await SiprixVoipSdk().getPushKitToken(); //iOS - get PushKit VoIP token
    } else if (Platform.isAndroid) {
      token = await FirebaseMessaging.instance
          .getToken(); //Android - get Firebase token
    }

    //When resolved - put token into SIP REGISTER request
    if (token != null) {
      _logs?.print('AddAccount with push token: $token');
      acc.xheaders = {"X-Token": token}; //Put token into separate header
      //acc.xContactUriParams = {"X-Token" : token};//OR put token into ContactUriParams
    }
    return super.addAccount(acc, saveChanges: saveChanges);
  }
}
*/
// @dart=2.19.5
import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Backend/backend.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:firebase_core/firebase_core.dart'; // bunu ekle



import 'Frontend/randevuguncellemeprovider.dart';
import 'Frontend/indexedstack.dart';
import 'Login Sayfası/checklogin.dart';
import 'package:randevu_sistem/navigatorkey.dart';

import 'package:provider/provider.dart';

import 'Login Sayfası/tanitim.dart';


late SharedPreferences prefs;

Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    // Android 10 ve öncesi
    await Permission.storage.request();

    // Android 11+ (MANAGE_EXTERNAL_STORAGE)
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }
}
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase initialize etmen gerekebilir
  await Firebase.initializeApp();

  logyaz(200, 'firebase backgorund da dinleniyor');


}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  prefs = await SharedPreferences.getInstance();

  // 🔹 Firebase init
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔹 FCM token al
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      log("✅ Android FCM token: $fcmToken");
      prefs.setString('fcm_token', fcmToken);
    }
  } catch (e) {
    log("❌ FCM token alınamadı: $e");
  }

  // 🔹 OneSignal init
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("78e4ad77-0b73-4837-8a25-d3b69c1e422e");

  if (Platform.isIOS) {
    await OneSignal.Notifications.requestPermission(true);
  }

  // 🔹 Android 13+ notification izni
  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      await Permission.notification.request();
    }
  }

  await ensurePlayerId();


  // 🔹 Bildirim olaylarını dinleme (opsiyonel)
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    log("📩 OneSignal bildirim foreground geldi");
  });
  OneSignal.Notifications.addPermissionObserver((state) {
    log("🔔 OneSignal permission state değişti");
  });

  // ✅ Splash ekranı kaldır
  FlutterNativeSplash.remove();

  // ✅ runApp
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

// Player ID'yi almak için retry mekanizması
Future<void> ensurePlayerId() async {
  String? playerId = OneSignal.User.pushSubscription.id;
  int retries = 0;

  while ((playerId == null || playerId.isEmpty) && retries < 10) {
    await Future.delayed(Duration(seconds: 1));
    playerId = OneSignal.User.pushSubscription.id;
    retries++;
  }

  if (playerId != null && playerId.isNotEmpty) {
    prefs.setString('onesignal_player_id', playerId);
    print("✅ Player ID alındı: $playerId");
  } else {
    print("❌ Player ID alınamadı");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Roboto', // Kullanmak istediğin font
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          // tümünü buradan yönetebilirsin
        ),
      ),
      navigatorKey: navigatorKey,

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
  String? deviceToken;
  double _opacity = 0.0;

  @override
  void initState() {

    super.initState();
    logyaz(200, 'uygulama başlıyor');
    if(Platform.isAndroid)
    {
      print('platform android');
      FirebaseMessaging.instance.getToken().then((token) {
        log("Android FCM token: $token");
        prefs.setString('fcm_token', token!);

      });
    }
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
          MaterialPageRoute(builder: (context) => OnBoardingPage()),
        );
      });
    });
  }
  Future<void> _initFirebaseToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print("✅ Device Token: $token");

      setState(() {
        deviceToken = token;
      });

      // Burada token'ı API'ye de gönderebilirsin
    } catch (e) {
      print("❌ Token alma hatası: $e");
    }
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
            "images/aronshine-land.png",
            height: 200,
          ),
        ),
      ),
    );
  }
}

