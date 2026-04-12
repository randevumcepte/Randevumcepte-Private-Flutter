import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Keep only numeric characters
    String numericString = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure there's a valid number to format
    if (numericString.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Convert the numeric string to a number, then format it
    double value = double.parse(numericString) / 100;

    String newText = formatter.format(value);
    newText = newText.replaceAll("₺", "");
    // Calculate the cursor position
    int newSelectionIndex = newText.length - (oldValue.text.length - oldValue.selection.end);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
  }
}