import 'package:flutter/services.dart';

class SipChannel {
  static const MethodChannel _channel = MethodChannel('ctsoftphone');

  static Future<void> initialize({required int port}) async {
    await _channel.invokeMethod('initialize', {
      'port': port,
    });
  }

  static Future<void> register({
    required String number,
    required String host,
    required String password,
  }) async {
    await _channel.invokeMethod('register', {
      'number': number,
      'host': host,
      'password': password,
    });
  }

  static Future<void> hangup() async {
    await _channel.invokeMethod('hangup');
  }

  static Future<void> destroy() async {
    await _channel.invokeMethod('destroy');
  }

  static Future<void> mute() async {
    await _channel.invokeMethod('mute');
  }

  static Future<void> unmute() async {
    await _channel.invokeMethod('unmute');
  }

  static Future<void> speakerOn() async {
    await _channel.invokeMethod('speakeron');
  }

  static Future<void> speakerOff() async {
    await _channel.invokeMethod('speakeroff');
  }
}
