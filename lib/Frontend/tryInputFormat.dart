import 'package:flutter/services.dart';

class TurkishLiraFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Sadece rakamlar ve nokta/virgül kalacak şekilde temizle
    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9,.]'), '');

    // Virgülü noktaya çevir (tek tip ondalık ayırıcı)
    cleaned = cleaned.replaceAll(',', '.');

    // Birden fazla nokta varsa düzelt
    if (cleaned.split('.').length > 2) {
      cleaned = oldValue.text;
    }

    // Ondalık kısmı 2 haneyle sınırla
    if (cleaned.contains('.')) {
      var parts = cleaned.split('.');
      if (parts[1].length > 2) {
        parts[1] = parts[1].substring(0, 2);
        cleaned = parts.join('.');
      }
    }

    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}