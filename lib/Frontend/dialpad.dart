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
  void showDialPad(BuildContext context, bool open, String target,Kullanici kullanici,String personelId) {
    final overlayState = Overlay.of(context);
    _isOpen = open;
    kullanicibilgi = kullanici;
    _currentHeight = open ? MediaQuery.of(context).size.height : 0.0;
    _target=target;
    // If the overlay entry does not exist, create it
    if (_dialPadOverlayEntry == null) {
      _dialPadOverlayEntry = OverlayEntry(
        builder: (context) => AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          height: _currentHeight,
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            child: KeyPad(_target,this,kullanicibilgi,personelId), // Your KeyPad widget
          ),
        ),
      );
      overlayState.insert(_dialPadOverlayEntry!); // Insert the overlay entry initially
    } else {
      // Update height by calling markNeedsBuild
      _dialPadOverlayEntry!.markNeedsBuild();
    }
  }

  void updateDialPad(BuildContext context, bool open, String target,Kullanici kullanici) {
    _isOpen = open;
    _currentHeight = open ? MediaQuery.of(context).size.height : 0.0;
    _target=target;
    kullanicibilgi = kullanici;
    // Rebuild the overlay to reflect the new height
    _dialPadOverlayEntry?.markNeedsBuild();
  }
  double getHeight(BuildContext context){
    return _currentHeight;
  }
  void dispose() {
    _dialPadOverlayEntry?.remove(); // Clean up the overlay entry
    _dialPadOverlayEntry = null; // Reset the entry reference
  }
}