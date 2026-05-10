// SIP feature disabled (Apple deprecated-API rejection avoidance)
// Stub DialPadManager — preserves API for callers but performs no SIP operations.
// Original implementation backed up as Frontend/dialpad.dart.bak
import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/user.dart';

class DialPadManager {
  bool _isOpen = false;

  void showDialPad(BuildContext context, bool open, String target, Kullanici kullanici, String personelId) {
    // No-op: SIP feature disabled
  }

  void updateDialPad(BuildContext context, bool open, String target, Kullanici kullanici, [String personelId = ""]) {
    // No-op: SIP feature disabled
  }

  double getHeight() => 0.0;

  void dispose() {
    _isOpen = false;
  }
}
