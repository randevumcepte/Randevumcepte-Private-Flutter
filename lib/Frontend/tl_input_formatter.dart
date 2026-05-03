import 'package:flutter/services.dart';

class TurkishLiraInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // Filter: keep digits and at most one comma; strip thousand-separator dots
    final buffer = StringBuffer();
    bool seenComma = false;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == ',' && !seenComma) {
        buffer.write(',');
        seenComma = true;
      } else if (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) {
        buffer.write(c);
      }
    }
    String filtered = buffer.toString();

    // Limit decimals to 2
    if (filtered.contains(',')) {
      final parts = filtered.split(',');
      final intPartRaw = parts[0];
      var decPart = parts.length > 1 ? parts[1] : '';
      if (decPart.length > 2) decPart = decPart.substring(0, 2);
      filtered = '$intPartRaw,$decPart';
    }

    // Split int/dec
    String intPart;
    String decPart;
    if (filtered.contains(',')) {
      final idx = filtered.indexOf(',');
      intPart = filtered.substring(0, idx);
      decPart = filtered.substring(idx);
    } else {
      intPart = filtered;
      decPart = '';
    }

    // Strip leading zeros, but keep at least one digit
    if (intPart.length > 1) {
      intPart = intPart.replaceFirst(RegExp(r'^0+'), '');
      if (intPart.isEmpty) intPart = '0';
    }

    // Apply thousand separators
    if (intPart.isNotEmpty) {
      intPart = _formatThousands(int.tryParse(intPart) ?? 0);
    }

    final formatted = intPart + decPart;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _formatThousands(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

String tlToBackend(String tlValue) {
  final trimmed = tlValue.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.replaceAll('.', '').replaceAll(',', '.');
}

String backendToTl(String backendValue) {
  final trimmed = backendValue.trim();
  if (trimmed.isEmpty) return '';
  final value = double.tryParse(trimmed.replaceAll(',', '.'));
  if (value == null) return '';
  if (value == 0) return '';
  if (value == value.truncateToDouble()) {
    return _formatThousands(value.truncate());
  }
  final cents = (value * 100).round();
  final whole = cents ~/ 100;
  final dec = cents % 100;
  return '${_formatThousands(whole)},${dec.toString().padLeft(2, '0')}';
}
