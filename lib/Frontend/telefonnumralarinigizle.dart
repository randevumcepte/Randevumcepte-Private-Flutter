String hidePhoneNumber(String phoneNumber) {
  if (phoneNumber.length <= 4) {
    // If the phone number is too short, just return it
    return phoneNumber;
  }
  int visibleDigits = 4; // Number of digits to show at the end
  String hiddenPart = '*' * (phoneNumber.length - visibleDigits);
  String visiblePart = phoneNumber.substring(phoneNumber.length - visibleDigits);
  return '$hiddenPart$visiblePart';
}