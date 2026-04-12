import 'package:flutter/material.dart';

class IndexedStackState with ChangeNotifier {
  int _selectedIndex = 0; // Private variable to hold the current index

  // Getter to access the current selected index
  int get selectedIndex => _selectedIndex;

  // Method to update the selected index and notify listeners about the change
  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners(); // Notifies all the listeners about the change
  }
  void resetSelectedIndex() {
    _selectedIndex = 0;
    notifyListeners();
  }
}