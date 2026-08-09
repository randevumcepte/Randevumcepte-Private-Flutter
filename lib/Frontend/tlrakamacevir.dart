double tlyirakamacevir(String tl)
{
  // Bos ya da gecersiz -> 0 (double.parse boş string icin FormatException firlatiyordu)
  final trimmed = tl.trim();
  if (trimmed.isEmpty) return 0;
  final normalized = trimmed.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}
