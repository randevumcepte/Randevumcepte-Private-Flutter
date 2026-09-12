// Studyo modu (fiyat gizleme): adisyon icin ikili odeme durumu.
// Tutar yerine "odeme alindi/alinmadi" -> adisyonlar.odendi.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:randevu_sistem/Backend/backend.dart' show appBundleAl;

// GEÇİCİ: studyo ikili odeme once TEST sunucusunda (apptest). Canliya cikinca
// 'app.randevumcepte.com.tr' yap. DB ortak, veri ayni yere duser.
const String _kBase = 'https://apptest.randevumcepte.com.tr/api/v1';

Future<bool> adisyonOdemeIsaretle({
  required String salonId,
  required String adisyonId,
  required bool alindi,
}) async {
  final r = await http
      .post(Uri.parse('$_kBase/adisyon-odeme-isaretle'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({
            'salon_id': salonId,
            'adisyon_id': adisyonId,
            'alindi': alindi,
            'appBundle': await appBundleAl(),
          }))
      .timeout(const Duration(seconds: 30));
  final j = (r.body.isNotEmpty) ? jsonDecode(r.body) : {};
  return j is Map && j['durum'] == 'ok';
}
