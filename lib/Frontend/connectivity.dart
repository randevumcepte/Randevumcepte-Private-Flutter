import 'package:flutter/material.dart';

class ConnectivityService with ChangeNotifier {
/*  final Connectivity _connectivity = Connectivity();
  bool _hasConnection = false;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnection();
  }

  bool get hasConnection => _hasConnection;

  Future<void> _checkInitialConnection() async {
    var status = await _connectivity.checkConnectivity();
    _updateConnectionStatus(status);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _hasConnection = result != ConnectivityResult.none;
    notifyListeners();
  }*/
}