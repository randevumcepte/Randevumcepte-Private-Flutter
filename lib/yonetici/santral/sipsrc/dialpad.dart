import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';

/*import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';*/

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:uuid/uuid.dart';
import '../../../Frontend/dialpad.dart';
import '../../../Frontend/telefoncaldir.dart';
import '../../../Models/user.dart';
import 'callscreen.dart';
import 'widgets/action_button.dart';

class DialPadWidget extends StatefulWidget {
  final SIPUAHelper? _helper;
  final String target;
  final DialPadManager dialPadManager;
  final Kullanici kullanicibilgi;
  DialPadWidget(this._helper,this.target,this.dialPadManager, this.kullanicibilgi,{Key? key, }) : super(key: key);

  @override
  State<DialPadWidget> createState() => _MyDialPadWidget();
}

class _MyDialPadWidget extends State<DialPadWidget> implements SipUaHelperListener {
  late String _currentTarget;
  late final FirebaseMessaging _firebaseMessaging;
  late String _currentUuid;
  late final Uuid _uuid;

  var dahili = "";
  var dahilisifre = "";
  String? seciliisletme;
  late String bildirimkimligi;
  final FocusNode _focusNode = FocusNode();
  late RegistrationState _registerState;
  TextEditingController _sipUriController = TextEditingController();
  TextEditingController _wsUriController = TextEditingController();
  TextEditingController _authorizationUserController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _displayNameController = TextEditingController();
  String? _dest;
  SIPUAHelper? get helper => widget._helper;
  TextEditingController? _textController;
  late SharedPreferences _preferences;

  String? receivedMsg;

  @override
  initState() {
    super.initState();
    _currentTarget = widget.target; // Initialize the target value

    _registerState = helper!.registerState;
    receivedMsg = "";
    _bindEventListeners();
    _loadSettings();
    //initFirebase();
    santralayarlariniyukle();


  }



  Future<void> initFirebase() async {
    await Firebase.initializeApp();
    _firebaseMessaging = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
      logyaz(200, 'firebase dinleniyor');
      //santralayarlariniyukle();
      //_currentUuid = _uuid.v4();
      //gelenaramayigoster(_currentUuid!,"");
    });
    _firebaseMessaging.getToken().then((token) {
      print('Device Token FCM: $token');
    });
  }
  @override
  void didUpdateWidget(covariant DialPadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the target has changed
    if (oldWidget.target != widget.target) {
      setState(() {

        _currentTarget = widget.target;
        _textController?.text = widget.target;
        _handleCall(context,true);// Update the current target
      });

    }
  }
  void _loadSettings() async {
    _preferences = await SharedPreferences.getInstance();
    _dest = _preferences.getString('dest') ?? '';
    _textController = TextEditingController(text: _dest);
    _textController!.text = _dest!;


  }
  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {
      _registerState = state;
      if(widget.target != "" && (EnumHelper.getName(_registerState.state)=="Registered")){
        log("widget.target boş değil");
        setState(() {

          _textController?.text = widget.target;
          _handleCall(context,true);
        });

      }
    });
  }
  void _bindEventListeners() {
    helper!.addSipUaHelperListener(this);
  }

  Future<Widget?> _handleCall(BuildContext context,
      [bool voiceOnly = false]) async {
    final dest = _textController?.text;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {

      await Permission.microphone.request();
      //await Permission.camera.request();
    }
    if (dest == null || dest.isEmpty) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Aranacak numara boş olamaz.'),
            content: Text('Lütfen aranacak dahili veya numarayı giriniz!'),
            actions: <Widget>[
              TextButton(
                child: Text('TAMAM'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return null;
    }

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'width': '1280',
        'height': '720',
        'facingMode': 'user',
      }
    };

    MediaStream mediaStream;

    if (kIsWeb && !voiceOnly) {
      mediaStream =
      await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      mediaConstraints['video'] = false;
      MediaStream userStream =
      await navigator.mediaDevices.getUserMedia(mediaConstraints);
      final audioTracks = userStream.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        mediaStream.addTrack(audioTracks.first, addToNative: true);
      }
    } else {
      if (voiceOnly) {
        mediaConstraints['video'] = !voiceOnly;
      }
      mediaStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    }

    helper!.call(dest,  mediaStream: mediaStream);
    _preferences.setString('dest', dest);
    return null;
  }

  void _handleNum(String number) {
    setState(() {
      _textController!.text += number;  // Add the number to the existing text
    });
  }

  void _handleBackSpace([bool deleteAll = false]) {
    var text = _textController!.text;
    if (text.isNotEmpty) {
      setState(() {
        text = deleteAll ? '' : text.substring(0, text.length - 1);
        _textController!.text = text;
      });
    }
  }

  List<Widget> _buildNumPad() {
    final labels = [
      [
        {'1': ''},
        {'2': ''},
        {'3': ''}
      ],
      [
        {'4': ''},
        {'5': ''},
        {'6': ''}
      ],
      [
        {'7': ''},
        {'8': ''},
        {'9': ''}
      ],
      [
        {'*': ''},
        {'0': ''},
        {'#': ''}
      ],
    ];

    return labels
        .map((row) => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row
                .map((label) => ActionButton(
              title: label.keys.first,
              subTitle: label.values.first,
              onPressed: () => _handleNum(label.keys.first),
              number: true,
            ))
                .toList())))
        .toList();
  }

  List<Widget> _buildDialPad() {
    return [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text('Aranacak Numara'),
      ),
      const SizedBox(height: 8),
      Container(
        width: 500,
        child: TextField(
          readOnly: true,  // Disable the keyboard
          textAlign: TextAlign.center,
          maxLength: 13,
          style: TextStyle(fontSize: 30, color: Colors.black54),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            counterText: "", // MaxLength için kalan karakter sayısını gizler
            suffixIcon: GestureDetector(
              onTap : () => _handleBackSpace(),
              onLongPress: () => _handleBackSpace(true),
              child: Icon(Icons.backspace),
            ),
          ),
          controller: _textController,
        ),
      ),
      Container(
        width: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildNumPad(),
        ),
      ),
      Container(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              /*ActionButton(
                icon: Icons.videocam,
                onPressed: () => _handleCall(context),
              ),*/
              ActionButton(
                icon: Icons.phone,
                fillColor: Colors.green,
                onPressed: () => _handleCall(context, true),
              ),
              /*ActionButton(
                icon: Icons.keyboard_arrow_left,
                onPressed: () => _handleBackSpace(),
                onLongPress: () => _handleBackSpace(true),
              ),*/
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(

      onWillPop: () async {

        widget.dialPadManager.updateDialPad(context, false, "",widget.kullanicibilgi);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {

                widget.dialPadManager.updateDialPad(context, false, "",widget.kullanicibilgi);

              }
          ),
          backgroundColor: Colors.white,

          title: Text("Arama", style: TextStyle(color: Colors.black, fontSize: 18),),
          actions: <Widget>[

          ],
        ),


        body:  GestureDetector(
          onTap: () {
            // Manually control what happens when the TextField is tapped
            print("TextField tapped but keyboard won't show.");
          },
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 12),
            children: <Widget>[
              SizedBox(height: 20),

              Center(
                child: Text(
                  'Dahili : '+dahili+'  Durum: '+((EnumHelper.getName(_registerState.state)=="Registered") ? "AKTİF" : "PASİF"),
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ),

              SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildDialPad(),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void transportStateChanged(TransportState state) {}

  @override
  void callStateChanged(Call call, CallState callState) {
    if (callState.state == CallStateEnum.CALL_INITIATION) {

      log("arayan "+(call!.remote_identity ?? ""));
      if(call!.direction=="INCOMING"){
        //gelenaramayigoster(const Uuid().v4(),call!.remote_identity ?? "");
        //gelenaramagoster(bildirimkimligi);

        widget.dialPadManager.updateDialPad(context, true, "",widget.kullanicibilgi);
        //playRingtone();
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CallScreenWidget(
            widget._helper,call,widget.dialPadManager,widget.kullanicibilgi
        )),
      );

      //Navigator.pushNamed(context, '/callscreen', arguments: call);

      //showCallkitIncoming(const Uuid().v4());
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    //Save the incoming message to DB
    String? msgBody = msg.request.body as String?;
    setState(() {
      receivedMsg = msgBody;
    });
  }
  /*Future<dynamic> mevcutArama() async {
    //check current call from pushkit if possible
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        print('DATA: $calls');
        _currentUuid = calls[0]['id'];
        return calls[0];
      } else {
        _currentUuid = "";
        return null;
      }
    }
  }
  Future<void> checkAndNavigationCallingPage() async {
    log("check calling");
    var mevcutarama = await mevcutArama();
    if (mevcutarama != null) {
      log("gelen arama cevaplandı bildirim üzerinden");

    }
  }
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    log("app lifecycle state");
    print(state);
    if (state == AppLifecycleState.resumed) {
      //Check call when open app from background
      checkAndNavigationCallingPage();
    }
  }

  Future<void> gelenaramayigoster(String uuid,String arayan) async {
    print('Gelen Arama Gösteriliyor');
    String? seciliisletme = await secilisalonid();
    dynamic caller = await arayanbilgi(arayan, seciliisletme!);
    await Future.delayed(const Duration(seconds: 2), () async {

      _currentUuid = uuid;

      final params = CallKitParams(
        id: _currentUuid,
        nameCaller: caller["musteri_adi"],
        appName: 'Callkit',
        avatar: caller["avatar"],
        handle: arayan,
        type: 0,
        duration: 15000,
        textAccept: 'YANITLA',
        textDecline: 'REDDET',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: 'Cevapsız Arama',
          callbackText: 'Geri Ara',
        ),

        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          backgroundUrl: 'assets/test.png',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
          incomingCallNotificationChannelName: 'Gelen Arama',
          missedCallNotificationChannelName: 'Cevapsız Arama',
          isImportant: true,
          isBot: false,
        ),
        ios: const IOSParams(
          iconName: 'CallKitLogo',
          handleType: '',
          supportsVideo: true,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: true,
          supportsHolding: true,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    });
  }*/

  @override
  void onNewNotify(Notify ntf) {}
  void _handleSave(BuildContext context) {
    try{
      if (_wsUriController.text == '') {

      } else if (_sipUriController.text == '') {

      }
      ;
      UaSettings settings = UaSettings();



      settings.webSocketSettings.allowBadCertificate = true;
      //settings.webSocketSettings.userAgent = 'Dart/2.8 (dart:io) for OpenSIPS.';


      settings.uri = _sipUriController.text;
      settings.webSocketUrl = _wsUriController.text;
      settings.transportType = TransportType.WS;
      settings.register = true;
      settings.authorizationUser = _authorizationUserController.text;
      settings.password = _passwordController.text;
      settings.displayName = _displayNameController.text;
      settings.userAgent = 'Dart SIP Client v1.0.0';
      settings.dtmfMode = DtmfMode.RFC2833;


      helper!.start(settings);

    }
    catch(e)
    {
      log("SIPUAHelper başlatılamadı: $e");
    }



  }
  void santralayarlariniyukle() async {
    _preferences = await SharedPreferences.getInstance();

    var user = jsonDecode(_preferences.getString('user')!);
    seciliisletme = await secilisalonid();



    setState(() {
      bildirimkimligi = _preferences.getString('onesignal_player_id')!;
      widget.kullanicibilgi.yetkili_olunan_isletmeler.forEach((item) {
        if(item['salon_id'].toString()==seciliisletme.toString()){
          log("personel item "+item.toString());
          dahili=item['dahili_no_webrtc'].toString();
          dahilisifre = item["dahili_sifre_webrtc"];
          //log(dahili.toString() + " "+dahilisifre.toString());
        }

      });
      _wsUriController.text =  'wss://santral.randevumcepte.com.tr:8089/ws';
      _sipUriController.text =  'sip:'+dahili.toString()+'@santral.randevumcepte.com.tr';
      _displayNameController.text =  dahili.toString();
      _passwordController.text =   dahilisifre.toString();
      _authorizationUserController.text =   dahili.toString();
      _handleSave(context);
    });
  }

  @override
  void onNewReinvite(ReInvite event) {
    // TODO: implement onNewReinvite
  }



}
