import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../Backend/yetki.dart';

/// Musteri iletisim yardimcilari (WhatsApp / Anket gonder).
/// Web /isletmeyonetim/musteridetay/ ve takvim randevu detay kartindaki
/// .whatsapp-mesaj-ac ve .anket-hizli-gonder-btn butonlarinin mobil karsiligi.
/// Ortak helper — 3 yerden ayni akis cagrilir: takvim, musteri detay, musteri listesi.
class IletisimHelper {
  static const String _api = 'https://app.randevumcepte.com.tr/api/v1';

  static String _sadeTelefon(String? raw) {
    if (raw == null) return '';
    final d = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty || d == 'null') return '';
    return d;
  }

  static String _waNumber(String tel) {
    var num = _sadeTelefon(tel);
    if (num.startsWith('0')) num = num.substring(1);
    if (!num.startsWith('90')) num = '90' + num;
    return num;
  }

  /// Salonun WhatsApp durumu + hazir linkler (konum/instagram/web) + musteri onay.
  /// Response: {ok, bagli, konum_linki, instagram_linki, web_linki, musteri_onay}
  static Future<Map<String, dynamic>> _durumAl(String salonId, {String? userId}) async {
    try {
      final q = <String, String>{'salon_id': salonId};
      if ((userId ?? '').isNotEmpty) q['user_id'] = userId!;
      final uri = Uri.parse('$_api/musteri-whatsapp-durum').replace(queryParameters: q);
      final r = await http.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return {'ok': false, 'bagli': false};
      final j = jsonDecode(r.body);
      if (j is Map) return Map<String, dynamic>.from(j);
      return {'ok': false, 'bagli': false};
    } catch (_) {
      return {'ok': false, 'bagli': false};
    }
  }

  /// WhatsApp hazir link ayarlarini sunucuya kaydeder (web ile senkron).
  /// Basarili ise {ok:true, konum_linki, instagram_linki, web_linki,
  /// instagram_baslik, web_baslik} doner.
  static Future<Map<String, dynamic>?> _ayarKaydet({
    required String salonId,
    required String konumLinki,
    required String instaLinki,
    required String instaBaslik,
    required String webLinki,
    required String webBaslik,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse('$_api/whatsapp-ayar-kaydet'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'salon_id': salonId,
              'konum_linki': konumLinki,
              'instagram_linki': instaLinki,
              'instagram_baslik': instaBaslik,
              'web_linki': webLinki,
              'web_baslik': webBaslik,
            }),
          )
          .timeout(const Duration(seconds: 15));
      final j = jsonDecode(r.body);
      if (j is Map) return Map<String, dynamic>.from(j);
      return {'ok': false, 'mesaj': 'Sunucu yaniti okunamadi.'};
    } catch (e) {
      return {'ok': false, 'mesaj': 'Baglanti hatasi: $e'};
    }
  }

  /// Salon WhatsApp hazir link ayarlarini (link + baslik) duzenleme dialogu.
  /// Kaydedilirse guncel degerleri (Map) doner, iptalde null.
  static Future<Map<String, dynamic>?> _linkAyarDuzenle(
    BuildContext context, {
    required String salonId,
    required String konumLinki,
    required String instaLinki,
    required String webLinki,
    required String instaBaslik,
    required String webBaslik,
  }) {
    final konumC = TextEditingController(text: konumLinki);
    final instaLinkC = TextEditingController(text: instaLinki);
    final instaBaslikC =
        TextEditingController(text: instaBaslik == 'Instagram' ? '' : instaBaslik);
    final webLinkC = TextEditingController(text: webLinki);
    final webBaslikC =
        TextEditingController(text: webBaslik == 'Web Sitesi' ? '' : webBaslik);
    bool kaydediliyor = false;

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          Widget alan(String label, TextEditingController c,
              {String? hint, TextInputType? tip}) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: c,
                keyboardType: tip,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  isDense: true,
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Baglantilari Duzenle', style: TextStyle(fontSize: 16)),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    alan('Konum linki', konumC,
                        hint: 'https://maps.app.goo.gl/...',
                        tip: TextInputType.url),
                    const Divider(),
                    alan('Instagram baslik', instaBaslikC, hint: 'Instagram'),
                    alan('Instagram linki', instaLinkC,
                        hint: 'https://instagram.com/...',
                        tip: TextInputType.url),
                    const Divider(),
                    alan('Web baslik', webBaslikC, hint: 'Web Sitesi'),
                    alan('Web linki', webLinkC,
                        hint: 'https://...', tip: TextInputType.url),
                    const Text(
                      'Not: Bos birakilan link kaldirilir. Degisiklikler web ile senkron calisir.',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: kaydediliyor ? null : () => Navigator.pop(ctx, null),
                child: const Text('Vazgec'),
              ),
              ElevatedButton(
                onPressed: kaydediliyor
                    ? null
                    : () async {
                        setSt(() => kaydediliyor = true);
                        final sonuc = await _ayarKaydet(
                          salonId: salonId,
                          konumLinki: konumC.text.trim(),
                          instaLinki: instaLinkC.text.trim(),
                          instaBaslik: instaBaslikC.text.trim(),
                          webLinki: webLinkC.text.trim(),
                          webBaslik: webBaslikC.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        if (sonuc != null && sonuc['ok'] == true) {
                          Navigator.pop(ctx, sonuc);
                        } else {
                          setSt(() => kaydediliyor = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text(sonuc?['mesaj']?.toString() ??
                                    'Kaydedilemedi.')),
                          );
                        }
                      },
                child: kaydediliyor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Kaydet'),
              ),
            ],
          );
        });
      },
    );
  }

  /// WhatsApp mesaj gonder akisi (web whatsapp_mesaj_modal ile ayni).
  /// - Salon WhatsApp bagliysa: mesaj yaz dialog (hazir link chip'leri + karakter sayaci)
  ///   -> sistemden gonder
  /// - Bagli degilse: uyari + "Ayarlara Git" onerisi; kullanici isterse wa.me fallback
  static Future<void> gonderWhatsapp(
    BuildContext context, {
    required String salonId,
    required String userId,
    required String musteriAdi,
    required String telefon,
  }) async {
    final tel = _sadeTelefon(telefon);
    if (tel.isEmpty) {
      _snack(context, 'Musteri telefon numarasi kayitli degil.');
      return;
    }

    // Durumu ve linkleri al
    final durum = await _durumAl(salonId, userId: userId);
    final bagli = durum['bagli'] == true;
    // Guncellenebilir (Duzenle sonrasi setSt ile tazelenir).
    String konumLinki = (durum['konum_linki']?.toString() ?? '');
    String instaLinki = (durum['instagram_linki']?.toString() ?? '');
    String webLinki   = (durum['web_linki']?.toString() ?? '');
    // Ozel basliklar sunucudan (salon web'den degistirebiliyor) — web modal ile ayni.
    String basAl(String key, String vars) {
      final v = (durum[key]?.toString() ?? '').trim();
      return v.isEmpty ? vars : v;
    }
    String konumBaslik = basAl('konum_baslik', 'Konumumuz');
    String instaBaslik = basAl('instagram_baslik', 'Instagram');
    String webBaslik   = basAl('web_baslik', 'Web Sitesi');
    final musteriOnay = durum['musteri_onay'] is int
        ? durum['musteri_onay'] as int
        : (int.tryParse(durum['musteri_onay']?.toString() ?? '0') ?? 0);

    if (!context.mounted) return;

    if (!bagli) {
      final devam = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('WhatsApp Bagli Degil'),
          content: const Text(
              'Musterilerinize sistemden WhatsApp mesaji gonderebilmek icin salon WhatsApp hesabini baglamaniz gerekiyor. Simdilik telefonunuzdaki WhatsApp uygulamasi acilsin mi?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text("WhatsApp'ta Ac"),
            ),
          ],
        ),
      );
      if (devam == true) {
        try {
          await launchUrl(
            Uri.parse('https://wa.me/${_waNumber(tel)}'),
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          _snack(context, 'WhatsApp acilirken hata: $e');
        }
      }
      return;
    }

    // Bagli -> mesaj yaz dialog
    final controller = TextEditingController();

    void ekleLink(String emoji, String etiket, String link) {
      final cur = controller.text;
      if (cur.contains(link)) return;
      final prefix = cur.isNotEmpty && !cur.endsWith('\n') ? '\n' : '';
      var next = cur + prefix + '$emoji $etiket: $link';
      if (next.length > 1000) next = next.substring(0, 1000);
      controller.text = next;
      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final int len = controller.text.length;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              title: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WhatsApp Mesaji',
                            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          musteriAdi.isNotEmpty
                              ? '$musteriAdi (${Yetki.telefonGoster(tel)})'
                              : Yetki.telefonGoster(tel),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (musteriOnay != 1)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.info_outline, size: 18, color: Color(0xFFB57E00)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Musterinin WhatsApp bildirim onayi yok. Yine de gonderilebilir; kanuni sorumluluk salon isletmecisine aittir.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF7A5300)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: controller,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 1000,
                      onChanged: (_) => setSt(() {}),
                      decoration: InputDecoration(
                        hintText: 'Mesajinizi yazin...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        counterText: '$len / 1000',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Hazir Baglantilar:',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final yeni = await _linkAyarDuzenle(
                              context,
                              salonId: salonId,
                              konumLinki: konumLinki,
                              instaLinki: instaLinki,
                              webLinki: webLinki,
                              instaBaslik: instaBaslik,
                              webBaslik: webBaslik,
                            );
                            if (yeni != null) {
                              konumLinki = (yeni['konum_linki']?.toString() ?? '');
                              instaLinki = (yeni['instagram_linki']?.toString() ?? '');
                              webLinki = (yeni['web_linki']?.toString() ?? '');
                              instaBaslik = ((yeni['instagram_baslik']?.toString().trim().isNotEmpty ?? false)
                                  ? yeni['instagram_baslik'].toString()
                                  : 'Instagram');
                              webBaslik = ((yeni['web_baslik']?.toString().trim().isNotEmpty ?? false)
                                  ? yeni['web_baslik'].toString()
                                  : 'Web Sitesi');
                              setSt(() {});
                            }
                          },
                          icon: const Icon(Icons.edit, size: 15),
                          label: const Text('Duzenle', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 30),
                          ),
                        ),
                      ],
                    ),
                    if (konumLinki.isEmpty && instaLinki.isEmpty && webLinki.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Text(
                          'Henuz baglanti yok. "Duzenle" ile konum / Instagram / web ekleyin.',
                          style: TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                      ),
                    if (konumLinki.isNotEmpty || instaLinki.isNotEmpty || webLinki.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (konumLinki.isNotEmpty)
                            _linkChip(
                              icon: '📍',
                              label: '$konumBaslik Ekle',
                              bg: const Color(0xFFEFF6FF),
                              fg: const Color(0xFF1D4ED8),
                              onTap: () {
                                // Web ile ayni: emoji 📍, etiket ozel baslik
                                ekleLink('📍', konumBaslik, konumLinki);
                                setSt(() {});
                              },
                            ),
                          if (instaLinki.isNotEmpty)
                            _linkChip(
                              icon: '📷',
                              label: '$instaBaslik Ekle',
                              bg: const Color(0xFFFDF2F8),
                              fg: const Color(0xFFBE185D),
                              onTap: () {
                                // Web ile ayni: emoji 🔗, etiket salonun ozel basligi
                                ekleLink('🔗', instaBaslik, instaLinki);
                                setSt(() {});
                              },
                            ),
                          if (webLinki.isNotEmpty)
                            _linkChip(
                              icon: '🌐',
                              label: '$webBaslik Ekle',
                              bg: const Color(0xFFECFDF5),
                              fg: const Color(0xFF047857),
                              onTap: () {
                                ekleLink('🔗', webBaslik, webLinki);
                                setSt(() {});
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Vazgec'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  onPressed: controller.text.trim().isEmpty
                      ? null
                      : () async {
                          final mesaj = controller.text.trim();
                          Navigator.of(ctx).pop();
                          await _gonderApi(context,
                              salonId: salonId, userId: userId, mesaj: mesaj);
                        },
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Gonder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _linkChip({
    required String icon,
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  static Future<void> _gonderApi(BuildContext context,
      {required String salonId,
      required String userId,
      required String mesaj}) async {
    try {
      final r = await http.post(
        Uri.parse('$_api/musteri-manuel-whatsapp'),
        body: {'salon_id': salonId, 'user_id': userId, 'mesaj': mesaj},
      ).timeout(const Duration(seconds: 20));
      final j = jsonDecode(r.body);
      final ok = j is Map && j['ok'] == true;
      final msg = (j is Map && (j['mesaj']?.toString() ?? '').isNotEmpty)
          ? j['mesaj'].toString()
          : (ok ? 'Mesaj gonderildi.' : 'Mesaj gonderilemedi.');
      _snack(context, msg);
    } catch (e) {
      _snack(context, 'Sunucuya baglanilamadi: $e');
    }
  }

  /// Musteriye tek-tik memnuniyet anketi gonder.
  /// Web'deki .anket-hizli-gonder-btn ile ayni akis (POST /anket-hizli-gonder).
  static Future<void> gonderAnket(
    BuildContext context, {
    required String salonId,
    required String userId,
    required String musteriAdi,
  }) async {
    if (userId.isEmpty) {
      _snack(context, 'Musteri bulunamadi.');
      return;
    }
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Memnuniyet Anketi Gonder'),
        content: Text('$musteriAdi adli musteriye memnuniyet anketi WhatsApp veya SMS ile gonderilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF17A589),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gonder'),
          ),
        ],
      ),
    );
    if (onay != true) return;
    try {
      final r = await http.post(
        Uri.parse('$_api/anket-hizli-gonder'),
        body: {'salon_id': salonId, 'user_id': userId},
      ).timeout(const Duration(seconds: 20));
      final j = jsonDecode(r.body);
      final ok = j is Map && j['basarili'] == true;
      final kanal = j is Map ? (j['kanal']?.toString() ?? 'sms') : 'sms';
      final kText = kanal == 'whatsapp' ? 'WhatsApp' : 'SMS';
      if (ok) {
        _snack(context, 'Anket $kText ile gonderildi.');
      } else {
        _snack(context, (j is Map ? (j['mesaj']?.toString() ?? 'Gonderilemedi.') : 'Gonderilemedi.'));
      }
    } catch (e) {
      _snack(context, 'Sunucuya baglanilamadi: $e');
    }
  }

  static void _snack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
