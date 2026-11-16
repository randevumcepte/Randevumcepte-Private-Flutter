import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// ios/Classes/RcSoftphonePlugin.swift PushKit koprusu. iOS disinda no-op.
class IosPush {
  IosPush._();
  static const MethodChannel _kanal = MethodChannel('rc_softphone/ios_push');

  static bool get _ios => !kIsWeb && Platform.isIOS;

  /// Native taraftan gelen olaylari dinle: yeni VoIP token / gelen push.
  static void dinle({
    required void Function(String token) onToken,
    required void Function(Map<String, dynamic> push) onPush,
  }) {
    if (!_ios) return;
    _kanal.setMethodCallHandler((MethodCall c) async {
      switch (c.method) {
        case 'voipToken':
          onToken((c.arguments as String?) ?? '');
          break;
        case 'pushCagrisi':
          final dynamic a = c.arguments;
          if (a is Map) onPush(Map<String, dynamic>.from(a));
          break;
      }
      return null;
    });
  }

  static Future<T?> _cagir<T>(String metod, [dynamic arg]) async {
    if (!_ios) return null;
    try {
      return await _kanal.invokeMethod<T>(metod, arg);
    } catch (e) {
      if (kDebugMode) debugPrint('[SIP] iOS push ($metod) hatasi: $e');
      return null;
    }
  }

  /// PushKit VoIP token (hex). Henuz yoksa bos.
  static Future<String> voipToken() async => (await _cagir<String>('voipToken')) ?? '';

  /// Uygulamanin bundle id'si (APNs topic = bundle + '.voip').
  static Future<String> bundleId() async => (await _cagir<String>('bundleId')) ?? '';

  /// Uygulama push ile uyandirildiysa bekleyen cagri (uuid/numara/arayan).
  static Future<Map<String, dynamic>?> bekleyenPush() async {
    final dynamic m = await _cagir<dynamic>('bekleyenPush');
    return m is Map ? Map<String, dynamic>.from(m) : null;
  }

  static Future<void> pushTuketildi() => _cagir<void>('pushTuketildi');

  /// Dart push olmadan kendi CallKit cagrisini acti (null = bitti).
  static Future<void> dartCagrisi(String? id) =>
      _cagir<void>('dartCagrisi', <String, dynamic>{'id': id});
}
