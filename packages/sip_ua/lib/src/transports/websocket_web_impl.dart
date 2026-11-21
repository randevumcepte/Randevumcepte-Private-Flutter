import 'dart:js_interop';

import 'package:sip_ua/src/sip_ua_helper.dart';
import 'package:web/web.dart' as web;
import '../logger.dart';

typedef OnMessageCallback = void Function(dynamic msg);
typedef OnCloseCallback = void Function(int? code, String? reason);
typedef OnOpenCallback = void Function();

class SIPUAWebSocketImpl {
  SIPUAWebSocketImpl(this._url, this.messageDelay);

  final String _url;
  web.WebSocket? _socket;
  OnOpenCallback? onOpen;
  OnMessageCallback? onMessage;
  OnCloseCallback? onClose;
  final int messageDelay;

  void connect(
      {Iterable<String>? protocols,
      required WebSocketSettings webSocketSettings}) async {
    logger.i('connect $_url, ${webSocketSettings.extraHeaders}, $protocols');
    try {
      _socket = web.WebSocket(_url, 'sip'.toJS);
      _socket!.onopen = ((web.Event e) {
        onOpen?.call();
      }).toJS;

      _socket!.onmessage = ((web.MessageEvent e) {
        _handleMessage(e.data);
      }).toJS;

      _socket!.onclose = ((web.CloseEvent e) {
        onClose?.call(e.code, e.reason);
      }).toJS;
    } catch (e) {
      onClose?.call(0, e.toString());
    }
  }

  Future<void> _handleMessage(JSAny? data) async {
    if (data == null) return;
    if (data.isA<web.Blob>()) {
      final JSArrayBuffer buffer =
          await (data as web.Blob).arrayBuffer().toDart;
      onMessage?.call(String.fromCharCodes(buffer.toDart.asUint8List()));
    } else if (data.isA<JSString>()) {
      onMessage?.call((data as JSString).toDart);
    } else {
      onMessage?.call(data.dartify());
    }
  }

  void send(dynamic data) {
    if (_socket != null && _socket!.readyState == web.WebSocket.OPEN) {
      _socket!.send((data as String).toJS);
      logger.d('send: \n\n$data');
    } else {
      logger.e('WebSocket not connected, message $data not sent');
    }
  }

  bool isConnecting() {
    return _socket != null &&
        _socket!.readyState == web.WebSocket.CONNECTING;
  }

  void close() {
    _socket!.close();
  }
}
