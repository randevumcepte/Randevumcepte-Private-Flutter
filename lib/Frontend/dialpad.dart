import 'package:flutter/material.dart';
import '../Models/user.dart';

// SIP/softphone tamamen kaldirildi (flutter_webrtc/callkit paketleri yok).
// DialPadManager referanslari (basic_bottom_nav_bar, diger_page) korunuyor ama
// tum metodlar no-op — dialpad/softphone UI artik acilmaz.
class DialPadManager {
  double _currentHeight = 0.0;

  void showDialPad(BuildContext context, bool open, String target, Kullanici kullanici, String personelId) {}

  void updateDialPad(BuildContext context, bool open, String target, Kullanici kullanici, [String personelId = ""]) {}

  double getHeight() => _currentHeight;

  void dispose() {}
}
