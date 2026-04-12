import 'package:flutter/material.dart';
import 'sip_channel.dart';

void main() {
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
  @override
  void initState() {
    super.initState();
    _initializeSIP();
  }

  Future<void> _initializeSIP() async {
    await SipChannel.initialize(port: 5060);
  }

  Future<void> _register() async {
    await SipChannel.register(
      number: '1012',
      host: '34.45.69.65',
      password: '6fca117f65f4d0435f11a3a38c8bb7cc',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CTSoftPhone Test')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
