import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sip_ua/sip_ua.dart';

import '../../Frontend/dialpad.dart';
import '../../Models/user.dart';
import 'sipsrc/about.dart';
import 'sipsrc/callscreen.dart';
import 'sipsrc/dialpad.dart';
import 'sipsrc/register.dart';

typedef PageContentBuilder = Widget Function([SIPUAHelper? helper, Object? arguments]);

class KeyPad extends StatefulWidget {
  final String target;
  final DialPadManager dialPadManager;
  final Kullanici kullanicibilgi;
  final String personelId;
  KeyPad(this.target, this.dialPadManager,this.kullanicibilgi,this.personelId ,{Key? key}) : super(key: key);

  @override
  _KeyPadState createState() => _KeyPadState();
}

class _KeyPadState extends State<KeyPad> {
  late String target;
  final SIPUAHelper _helper = SIPUAHelper(); // SIPUAHelper instance here

  @override
  void initState() {
    super.initState();
    target = widget.target; // Initialize with the initial target
  }

  @override
  void didUpdateWidget(covariant KeyPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update `target` if it has changed
    if (oldWidget.target != widget.target) {
      setState(() {
        target = widget.target;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arama',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Map<String, PageContentBuilder> buildRoutes() {
    return {
      '/': ([SIPUAHelper? helper, Object? arguments]) => DialPadWidget(helper, target, widget.dialPadManager,widget.kullanicibilgi),

      '/about': ([SIPUAHelper? helper, Object? arguments]) => AboutWidget(),
    };
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final pageContentBuilder = buildRoutes()[settings.name!];

    if (pageContentBuilder != null) {
      return MaterialPageRoute<Widget>(
        builder: (context) => pageContentBuilder(_helper, settings.arguments),
      );
    }
    return null;
  }
}