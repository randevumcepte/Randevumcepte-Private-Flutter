import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// ios/Classes/RcSoftphonePlugin.swift koprusu. iOS disinda no-op.
class IosSes {
  IosSes._();
  static const MethodChannel _kanal = MethodChannel('rc_softphone/ios_ses');

  static Future<void> _cagir(String metod) async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _kanal.invokeMethod<void>(metod);
    } catch (e) {
      if (kDebugMode) debugPrint('[SIP] iOS ses ($metod) hatasi: $e');
    }
  }

  /// Gelen cagri CallKit'te gosterilmeden once.
  static Future<void> callkitIcinHazirla() => _cagir('callkitIcinHazirla');

  /// CallKit ses oturumunu acti (cevaplandi).
  static Future<void> callkitSesAktif() => _cagir('callkitSesAktif');

  /// CallKit ses oturumunu kapatti.
  static Future<void> callkitSesPasif() => _cagir('callkitSesPasif');

  /// CallKit cagrisi bitti; giden aramalar icin WebRTC otomatik moda don.
  static Future<void> otomatikSeseDon() => _cagir('otomatikSeseDon');
}
