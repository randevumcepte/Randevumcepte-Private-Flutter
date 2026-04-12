import 'package:flutter/material.dart';
import '../Models/user.dart';
import '../yonetici/santral/arama.dart';
import '../yonetici/santral/sipsrc/dialpad.dart';

class DialPadManager {
  OverlayEntry? _dialPadOverlayEntry;
  bool _isOpen = false;
  late double _currentHeight;
  late Kullanici kullanicibilgi;

  String _target = "";

  void showDialPad(BuildContext context, bool open, String target, Kullanici kullanici, String personelId) {
    final overlayState = Overlay.of(context);
    _isOpen = open;
    kullanicibilgi = kullanici;
    _currentHeight = open ? MediaQuery.of(context).size.height : 0.0;
    _target = target;

    if (_dialPadOverlayEntry == null) {
      _dialPadOverlayEntry = OverlayEntry(
        builder: (context) => AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          bottom: 0,
          left: 0,
          right: 0,
          height: _currentHeight,
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            child: KeyPad(_target, this, kullanicibilgi, personelId),
          ),
        ),
      );
      overlayState.insert(_dialPadOverlayEntry!);
    } else {
      _dialPadOverlayEntry!.markNeedsBuild();
    }
  }

  void updateDialPad(BuildContext context, bool open, String target, Kullanici kullanici, [String personelId = ""]) {
    _isOpen = open;
    _currentHeight = open ? MediaQuery.of(context).size.height : 0.0;
    _target = target;
    kullanicibilgi = kullanici;

    if (!_isOpen) {
      // Kapama işlemi
      dispose();
      return;
    }

    // Eğer overlay zaten varsa height ve içeriği güncelle
    if (_dialPadOverlayEntry != null) {
      _dialPadOverlayEntry!.markNeedsBuild();
    } else {
      // Eğer overlay yoksa yeniden oluştur
      showDialPad(context, open, target, kullanicibilgi, personelId);
    }
  }

  double getHeight() => _currentHeight;

  void dispose() {
    _dialPadOverlayEntry?.remove();
    _dialPadOverlayEntry = null;
    _isOpen = false;
  }
}
