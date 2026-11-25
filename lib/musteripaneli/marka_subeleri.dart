import 'package:randevu_sistem/Models/musteri_danisanlar.dart';

/// Müşterinin portföyünden YALNIZ bu uygulamanın markasına (app_bundle) ait şubeler
/// ({salon_id, salonlar: {...}}). Uygulama yeniden açılınca sunucu portföyün tamamını
/// döndürür; başka işletmeler müşteriye gösterilmemelidir. Ortak (master) uygulamada ya da
/// marka bilinmiyorsa yalnız seçili işletme döner.
List<Map<String, dynamic>> markaSubeleri(MusteriDanisan md, dynamic isletmebilgi) {
  String bundle(dynamic s) => s is Map ? (s['app_bundle'] ?? '').toString().trim() : '';
  final marka = bundle(isletmebilgi);
  final out = <Map<String, dynamic>>[];
  if (marka.isNotEmpty && marka != 'com.randevumcepte.randevumcepte') {
    for (final e in md.musteri_olunan_salonlar ?? const []) {
      if (e is Map && e['salonlar'] is Map && bundle(e['salonlar']) == marka) out.add(Map<String, dynamic>.from(e));
    }
  }
  if (out.isEmpty && isletmebilgi is Map) {
    out.add({'salon_id': isletmebilgi['id'], 'salonlar': Map<String, dynamic>.from(isletmebilgi)});
  }
  return out;
}
