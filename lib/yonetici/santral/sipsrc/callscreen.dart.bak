import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
/*mport 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';*/
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:randevu_sistem/Frontend/telefoncaldir.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../../Frontend/dialpad.dart';
import 'widgets/action_button.dart';
import 'package:randevu_sistem/Models/user.dart';


class CallScreenWidget extends StatefulWidget {
  final SIPUAHelper? _helper;
  final Call? _call;
  final DialPadManager dialPadManager;
  final Kullanici kullanici;
  CallScreenWidget(this._helper, this._call, this.dialPadManager, this.kullanici,{Key? key}) : super(key: key);

  @override
  State<CallScreenWidget> createState() => _MyCallScreenWidget();
}

class _MyCallScreenWidget extends State<CallScreenWidget>
    implements SipUaHelperListener {
  RTCVideoRenderer? _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer? _remoteRenderer = RTCVideoRenderer();
  double? _localVideoHeight;
  double? _localVideoWidth;
  EdgeInsetsGeometry? _localVideoMargin;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  String aramaEylemleri = "";

  bool _showNumPad = false;
  String _timeLabel = '00:00';
  bool _audioMuted = false;
  bool _videoMuted = false;
  bool _speakerOn = false;
  bool _hold = false;
  bool _mirror = true;
  String? _holdOriginator;
  CallStateEnum _state = CallStateEnum.NONE;

  late String _transferTarget;
  late Timer _timer;

  SIPUAHelper? get helper => widget._helper;

  bool get voiceOnly =>
      (_localStream == null || _localStream!.getVideoTracks().isEmpty) &&
          (_remoteStream == null || _remoteStream!.getVideoTracks().isEmpty);

  String? get remoteIdentity => call!.remote_identity;

  String get direction => call!.direction;

  Call? get call => widget._call;

  @override
  initState() {
    super.initState();
    _initRenderers();
    helper!.addSipUaHelperListener(this);
    _startTimer();
    //aramaEylemleriniDinle(aramaEylemi);
  }

  @override
  deactivate() {
    super.deactivate();
    helper!.removeSipUaHelperListener(this);
    _disposeRenderers();
  }
  @override

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      Duration duration = Duration(seconds: timer.tick);
      if (mounted) {
        setState(() {
          _timeLabel = [duration.inMinutes, duration.inSeconds]
              .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
              .join(':');
        });
      } else {
        _timer.cancel();
      }
    });
  }

  void _initRenderers() async {
    if (_localRenderer != null) {
      await _localRenderer!.initialize();
    }
    if (_remoteRenderer != null) {
      await _remoteRenderer!.initialize();
    }
  }

  void _disposeRenderers() {
    if (_localRenderer != null) {
      _localRenderer!.dispose();
      _localRenderer = null;
    }
    if (_remoteRenderer != null) {
      _remoteRenderer!.dispose();
      _remoteRenderer = null;
    }
  }

  @override
  void callStateChanged(Call call, CallState callState) {


    if (callState.state == CallStateEnum.HOLD ||
        callState.state == CallStateEnum.UNHOLD) {
      _hold = callState.state == CallStateEnum.HOLD;
      _holdOriginator = callState.originator;
      setState(() {});
      return;
    }

    if (callState.state == CallStateEnum.MUTED) {
      if (callState.audio!) _audioMuted = true;
      if (callState.video!) _videoMuted = true;
      setState(() {});
      return;
    }

    if (callState.state == CallStateEnum.UNMUTED) {
      if (callState.audio!) _audioMuted = false;
      if (callState.video!) _videoMuted = false;
      setState(() {});
      return;
    }

    // Ensure we update the state
    setState(() {
      _state = callState.state;
    });

    switch (callState.state) {
      case CallStateEnum.STREAM:
        _handelStreams(callState);
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        _backToDialPad();
        break;
    // Handle other states
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONNECTING:
      case CallStateEnum.PROGRESS:
      case CallStateEnum.CONFIRMED:
      case CallStateEnum.CALL_INITIATION:
      case CallStateEnum.REFER:
      case CallStateEnum.NONE:
        break;
      default:
        log("Unhandled call state: ${callState.state}");
        break;
    }
  }

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void registrationStateChanged(RegistrationState state) {}

  void _cleanUp() {
    if (_localStream == null) return;
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream!.dispose();
    _localStream = null;
  }

  void _backToDialPad() {
    _timer.cancel();
    Timer(Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
    _cleanUp();
  }

  void _handelStreams(CallState event) async {
    log("handle streams");
    MediaStream? stream = event.stream;
    if (event.originator == 'local') {
      if (_localRenderer != null) {
        _localRenderer!.srcObject = stream;
      }
      if (!kIsWeb && !WebRTC.platformIsDesktop) {
        event.stream?.getAudioTracks().first.enableSpeakerphone(false);
      }
      _localStream = stream;
    }
    if (event.originator == 'remote') {
      if (_remoteRenderer != null) {
        _remoteRenderer!.srcObject = stream;
      }
      _remoteStream = stream;
    }

    setState(() {
      _resizeLocalVideo();
    });
  }

  void _resizeLocalVideo() {
    _localVideoMargin = _remoteStream != null
        ? EdgeInsets.only(top: 15, right: 15)
        : EdgeInsets.all(0);
    _localVideoWidth = _remoteStream != null
        ? MediaQuery.of(context).size.width / 4
        : MediaQuery.of(context).size.width;
    _localVideoHeight = _remoteStream != null
        ? MediaQuery.of(context).size.height / 4
        : MediaQuery.of(context).size.height;
  }

  void _handleHangup() {
    stopRingtone();
    call!.hangup({'status_code': 603});
    _timer.cancel();
    Navigator.of(context).pop();
  }

  void _handleAccept() async {
    log("Call accepted");
    bool remoteHasVideo = call!.remote_has_video;
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': remoteHasVideo
    };
    MediaStream mediaStream;

    try {
      if (kIsWeb && remoteHasVideo) {
        mediaStream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
        mediaConstraints['video'] = false;
        MediaStream userStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
        mediaStream.addTrack(userStream.getAudioTracks()[0], addToNative: true);
      } else {
        mediaConstraints['video'] = remoteHasVideo;
        mediaStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      }

      // Log that media stream was obtained successfully
      log("Media stream created successfully");

      // Answer the call
      call!.answer(helper!.buildCallOptions(!remoteHasVideo), mediaStream: mediaStream);

      // Log successful call answer
      log("Call answered successfully");

    } catch (e) {
      // Catch any errors and log them
      log("Error during call answering: $e");
    }
  }

  void _switchCamera() {
    if (_localStream != null) {
      Helper.switchCamera(_localStream!.getVideoTracks()[0]);
      setState(() {
        _mirror = !_mirror;
      });
    }
  }

  void _muteAudio() {
    if (_audioMuted) {
      call!.unmute(true, false);
    } else {
      call!.mute(true, false);
    }
  }

  void _muteVideo() {
    if (_videoMuted) {
      call!.unmute(false, true);
    } else {
      call!.mute(false, true);
    }
  }

  void _handleHold() {
    if (_hold) {
      call!.unhold();
    } else {
      call!.hold();
    }
  }

  void _handleTransfer() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter target to transfer.'),
          content: TextField(
            onChanged: (String text) {
              setState(() {
                _transferTarget = text;
              });
            },
            decoration: InputDecoration(
              hintText: 'URI or Username',
            ),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                call!.refer(_transferTarget);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleDtmf(String tone) {
    print('Dtmf tone => $tone');
    call!.sendDTMF(tone);
  }

  void _handleKeyPad() {
    setState(() {
      _showNumPad = !_showNumPad;
    });
  }

  void _toggleSpeaker() {
    if (_localStream != null) {
      _speakerOn = !_speakerOn;
      if (!kIsWeb) {
        _localStream!.getAudioTracks()[0].enableSpeakerphone(_speakerOn);
      }
    }
  }

  List<Widget> _buildNumPad() {
    final labels = [
      [
        {'1': ''},
        {'2': 'abc'},
        {'3': 'def'}
      ],
      [
        {'4': 'ghi'},
        {'5': 'jkl'},
        {'6': 'mno'}
      ],
      [
        {'7': 'pqrs'},
        {'8': 'tuv'},
        {'9': 'wxyz'}
      ],
      [
        {'*': ''},
        {'0': '+'},
        {'#': ''}
      ],
    ];

    return labels
        .map((row) => Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row
                .map((label) => ActionButton(
              title: label.keys.first,
              subTitle: label.values.first,
              onPressed: () => _handleDtmf(label.keys.first),
              number: true,
            ))
                .toList())))
        .toList();
  }

  Widget _buildActionButtons() {
    final hangupBtn = ActionButton(
      title: CallStateEnum.CONFIRMED != null ? "KAPAT" : "REDDET",
      onPressed: () => _handleHangup(),
      icon: Icons.call_end,
      fillColor: Colors.red,
    );

    final hangupBtnInactive = ActionButton(
      title: "KAPAT",
      onPressed: () {},
      icon: Icons.call_end,
      fillColor: Colors.grey,
    );

    final basicActions = <Widget>[];
    final advanceActions = <Widget>[];

    switch (_state) {
      case CallStateEnum.NONE:
      case CallStateEnum.CONNECTING:
        if (direction == 'INCOMING') {

          basicActions.add(ActionButton(
            title: "YANITLA",
            fillColor: Colors.green,
            icon: Icons.phone,
            onPressed: () => _handleAccept(),
          ));
          basicActions.add(hangupBtn);
        } else {
          basicActions.add(hangupBtn);
        }
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        {
          advanceActions.add(ActionButton(
            title: _audioMuted ? 'Sesi aç' : 'Sesi kapat',
            icon: _audioMuted ? Icons.mic_off : Icons.mic,
            checked: _audioMuted,
            onPressed: () => _muteAudio(),
          ));

          if (voiceOnly) {
            advanceActions.add(ActionButton(
              title: "Tuş takımı",
              icon: Icons.dialpad,
              onPressed: () => _handleKeyPad(),
            ));
          } else {
            advanceActions.add(ActionButton(
              title: "switch camera",
              icon: Icons.switch_video,
              onPressed: () => _switchCamera(),
            ));
          }

          if (voiceOnly) {
            advanceActions.add(ActionButton(
              title: _speakerOn ? 'Hoparlörü kapat' : 'Hoparlörü aç',
              icon: _speakerOn ? Icons.volume_off : Icons.volume_up,
              checked: _speakerOn,
              onPressed: () => _toggleSpeaker(),
            ));
          } else {
            advanceActions.add(ActionButton(
              title: _videoMuted ? "camera on" : 'camera off',
              icon: _videoMuted ? Icons.videocam : Icons.videocam_off,
              checked: _videoMuted,
              onPressed: () => _muteVideo(),
            ));
          }

          basicActions.add(ActionButton(
            title: _hold ? 'Bekletme' : 'Beklet',
            icon: _hold ? Icons.play_arrow : Icons.pause,
            checked: _hold,
            onPressed: () => _handleHold(),
          ));

          basicActions.add(hangupBtn);

          if (_showNumPad) {
            basicActions.add(ActionButton(
              title: "Geri",
              icon: Icons.keyboard_arrow_down,
              onPressed: () => _handleKeyPad(),
            ));
          } else {
            basicActions.add(ActionButton(
              title: "Aktar",
              icon: Icons.phone_forwarded,
              onPressed: () => _handleTransfer(),
            ));
          }
        }
        break;
      case CallStateEnum.FAILED:
      case CallStateEnum.ENDED:
        basicActions.add(hangupBtnInactive);
        break;
      case CallStateEnum.PROGRESS:
        basicActions.add(hangupBtn);
        break;
      default:
        print('Other state => $_state');
        break;
    }

    final actionWidgets = <Widget>[];

    if (_showNumPad) {
      actionWidgets.addAll(_buildNumPad());
    } else {
      if (advanceActions.isNotEmpty) {
        actionWidgets.add(
          Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: advanceActions),
          ),
        );
      }
    }

    actionWidgets.add(
      Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: basicActions),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: actionWidgets,
    );
  }

  Widget _buildContent() {
    final stackWidgets = <Widget>[];

    if (!voiceOnly && _remoteStream != null) {
      stackWidgets.add(
        Center(
          child: RTCVideoView(
            _remoteRenderer!,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
      );
    }

    if (!voiceOnly && _localStream != null) {
      stackWidgets.add(
        AnimatedContainer(
          child: RTCVideoView(
            _localRenderer!,
            mirror: _mirror,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          height: _localVideoHeight,
          width: _localVideoWidth,
          alignment: Alignment.topRight,
          duration: Duration(milliseconds: 300),
          margin: _localVideoMargin,
        ),
      );
    }

    stackWidgets.addAll(
      [
        Positioned(
          top: voiceOnly ? 48 : 6,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      (voiceOnly ? 'SESLİ ARAMA' : 'GÖRÜNTÜLÜ ARAMA') +
                          (_hold
                              ? ' DURAKLATILDI ${_holdOriginator!.toUpperCase()}'
                              : ''),
                      style: TextStyle(fontSize: 24, color: Colors.black54),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      '$remoteIdentity',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      _timeLabel,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );

    return Stack(
      children: stackWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _buildContent(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: 320,
        padding: EdgeInsets.only(bottom: 24.0),
        child: _buildActionButtons(),
      ),
    );
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    // NO OP
  }

  @override
  void onNewNotify(Notify ntf) {
    // NO OP
  }
  /*Future<void> aramaEylemleriniDinle(void Function(CallEvent) callback) async {
    try {
      FlutterCallkitIncoming.onEvent.listen((event) async {
        print('HOME: $event');
        switch (event!.event) {
          case Event.actionCallIncoming:
          // TODO: received an incoming call
            break;
          case Event.actionCallStart:
          // TODO: started an outgoing call
          // TODO: show screen calling in Flutter
            break;
          case Event.actionCallAccept:
          // TODO: arama yanıtlama

            _handleAccept();

            break;
          case Event.actionCallDecline:
          // TODO: arama reddetme
            _handleHangup();

            break;
          case Event.actionCallEnded:
          // TODO: ended an incoming/outgoing call
            break;
          case Event.actionCallTimeout:
          // TODO: missed an incoming call
            break;
          case Event.actionCallCallback:
          // TODO: Cevapsız arama bildirimi üzerinden yeniden arama
          //log("Görünen numara : "+ event.body["number"]);
            widget.dialPadManager.updateDialPad(context,true,event.body["number"],widget.kullanici);
            break;
          case Event.actionCallToggleHold:
          // TODO: only iOS
            break;
          case Event.actionCallToggleMute:
          // TODO: only iOS
            break;
          case Event.actionCallToggleDmtf:
          // TODO: only iOS
            break;
          case Event.actionCallToggleGroup:
          // TODO: only iOS
            break;
          case Event.actionCallToggleAudioSession:
          // TODO: only iOS
            break;
          case Event.actionDidUpdateDevicePushTokenVoip:
          // TODO: only iOS
            break;
          case Event.actionCallCustom:
            break;
          case Event.actionCallConnected:
            // TODO: Handle this case.
            throw UnimplementedError();
        }
        callback(event);
      });
    } on Exception catch (e) {
      print(e);
    }
  }*/
  /*void aramaEylemi(CallEvent event) {
    if (!mounted) return;
    setState(() {
      aramaEylemleri += '---\n${event.toString()}\n';
    });
  }*/

  @override
  void onNewReinvite(ReInvite event) {
    // TODO: implement onNewReinvite
  }
}
