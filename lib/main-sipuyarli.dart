import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'sip_channel.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: SipTestScreen());
  }
}

class SipTestScreen extends StatefulWidget {
  @override
  State<SipTestScreen> createState() => _SipTestScreenState();
}

class _SipTestScreenState extends State<SipTestScreen> {
  String? deviceToken;

  @override
  void initState() {
    super.initState();
    _initializeSIP();
    _initFirebaseToken();
  }

  Future<void> _initializeSIP() async {
    await SipChannel.initialize(port: 5060);
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

  Future<void> _register() async {
    await SipChannel.register(
      number: '12',
      host: '34.45.69.65',
      password: 'RandevumCepte35..',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CTSoftPhone Test')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (deviceToken != null)
            Text("Token: $deviceToken")
          else
            CircularProgressIndicator(),
          ElevatedButton(onPressed: _register, child: const Text('Register')),
          ElevatedButton(onPressed: SipChannel.hangup, child: const Text('Hang Up')),
          ElevatedButton(onPressed: SipChannel.mute, child: const Text('Mute')),
          ElevatedButton(onPressed: SipChannel.unmute, child: const Text('Unmute')),
          ElevatedButton(onPressed: SipChannel.speakerOn, child: const Text('Speaker On')),
          ElevatedButton(onPressed: SipChannel.speakerOff, child: const Text('Speaker Off')),
          ElevatedButton(onPressed: SipChannel.destroy, child: const Text('Unregister')),
        ]),
      ),
    );
  }
}
