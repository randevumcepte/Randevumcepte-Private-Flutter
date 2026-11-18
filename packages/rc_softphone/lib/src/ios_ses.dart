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

  /// Hoparlor ac/kapat (sadece cikis yonu; CallKit oturumuna dokunmaz).
  /// Gercek durumu dondurur; hata/iOS disi: null.
  static Future<bool?> hoparlor(bool ac) async {
    if (kIsWeb || !Platform.isIOS) return null;
    try {
      return await _kanal.invokeMethod<bool>('hoparlor', ac);
    } catch (e) {
      if (kDebugMode) debugPrint('[SIP] iOS hoparlor hatasi: $e');
      return null;
    }
  }

  /// Ses su an hoparlorden mi cikiyor? iOS disi: null.
  static Future<bool?> hoparlorAcikMi() async {
    if (kIsWeb || !Platform.isIOS) return null;
    try {
      return await _kanal.invokeMethod<bool>('hoparlorAcikMi');
    } catch (_) {
      return null;
    }
  }

  /// Ses cikisi degisince (CallKit sistem ekrani, kulaklik vb.) cagrilir.
  static void yonDinle(void Function(bool hoparlor) dinleyici) {
    if (kIsWeb || !Platform.isIOS) return;
    _kanal.setMethodCallHandler((MethodCall c) async {
      if (c.method == 'hoparlorDegisti' && c.arguments is bool) {
        dinleyici(c.arguments as bool);
      }
    });
  }
}
