import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:randevu_sistem/dil/material.dart';
import 'package:randevu_sistem/navigatorkey.dart';
import 'package:randevu_sistem/services/notification_types.dart';
import 'package:randevu_sistem/yonetici/profil/profil_api.dart';

/// Randevu hatirlatmasina musteri cevabi: "Geliyorum" / "Gecikecegim".
///  - Android: hatirlatma bildiriminde iki dugme (uygulama kendisi cizer, sunucu yalniz-veri yollar)
///  - Her platform: bildirime dokununca acilan randevu detayinda ayni dugmeler ([RandevuYanitKarti])
/// Cevap salona (atanan personel + yoneticiler) bildirim olarak gider.
class RandevuYanit {
  static const geliyorum = 'geliyorum';
  static const gecikecegim = 'gecikecegim';

  /// Bildirimde gosterilen dugmeler. Basinca uygulama acilir ve cevap gonderilir.
  static const aksiyonlar = <AndroidNotificationAction>[
    AndroidNotificationAction(geliyorum, 'Geliyorum', showsUserInterface: true, cancelNotification: true),
    AndroidNotificationAction(gecikecegim, 'Gecikeceğim', showsUserInterface: true, cancelNotification: true),
  ];

  /// Bu bildirimde dugme olsun mu (sunucu yalniz musteri randevu hatirlatmasinda isaretler)
  static bool dugmeli(Map<String, dynamic> veri) =>
      Platform.isAndroid && veri['aksiyonlar']?.toString() == 'randevu_yanit';

  /// Randevuya ait bildirimin sabit numarasi: ayni randevunun bildirimi birikmez, dugmeden sonra kapanir
  static int bildirimNo(String? randevuId) {
    final n = int.tryParse(randevuId ?? '');
    return n == null ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : n % 2147483647;
  }

  /// Arka plan isleyicisi (uygulama acik degilken): sunucunun yalniz-veri hatirlatmasini dugmeli goster.
  static Future<void> arkaPlandaGoster(Map<String, dynamic> veri) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      ));
      final baslik = veri['title']?.toString() ?? 'Randevu Hatırlatma';
      final metin = veri['body']?.toString() ?? '';
      final kanal = (veri['kanal']?.toString() ?? '').isNotEmpty ? veri['kanal'].toString() : 'rmc_important_v2';
      await plugin.show(
        bildirimNo(veri['randevu_id']?.toString()),
        baslik,
        metin,
        NotificationDetails(
          android: AndroidNotificationDetails(
            kanal,
            'Önemli Bildirimler',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(metin, contentTitle: baslik),
            actions: aksiyonlar,
          ),
        ),
        payload: jsonEncode(veri),
      );
    } catch (e) {
      log('RandevuYanit arka plan gosterim hatasi: $e');
    }
  }

  /// Bildirimdeki dugmeye basildi (uygulama acildi). Gecikecegim'de kac dakika sorulur.
  static Future<void> dugmeyeBasildi(String aksiyon, NotificationPayload p) async {
    final ctx = await _baglam();
    if (ctx == null) return;
    int? dakika;
    if (aksiyon == gecikecegim) {
      if (!ctx.mounted) return;
      dakika = await dakikaSor(ctx);
      if (dakika == null) return;
    }
    final sonuc = await gonder(randevuId: p.randevuId, salonId: p.salonId, yanit: aksiyon, dakika: dakika, kaynak: 'bildirim');
    final c = navigatorKey.currentContext;
    if (c != null && c.mounted) bildir(c, sonuc);
  }

  static Future<Map<String, dynamic>> gonder({
    required String? randevuId,
    required String? salonId,
    required String yanit,
    int? dakika,
    String kaynak = 'uygulama',
  }) async {
    if ((randevuId ?? '').isEmpty || (salonId ?? '').isEmpty) {
      return {'ok': 0, 'hata': 'Randevu bilgisi eksik.'};
    }
    return ProfilApi.post('/musteri-profil/randevu-yanit', salonId!, {
      'randevu_id': randevuId,
      'yanit': yanit,
      if (dakika != null) 'dakika': dakika,
      'kaynak': kaynak,
    });
  }

  /// Musteri bildirime dokundu (once-bildirim SMS yedegi iptal olsun). Sessiz, beklenmez.
  static void acildiBildir(NotificationPayload p) {
    final r = p.randevuId, s = p.salonId;
    if ((r ?? '').isEmpty || (s ?? '').isEmpty) return;
    ProfilApi.post('/musteri-profil/bildirim-acildi', s!, {'randevu_id': r, 'tip': p.type ?? ''})
        .catchError((_) => <String, dynamic>{});
  }

  static void bildir(BuildContext c, Map<String, dynamic> sonuc) {
    final ok = ProfilApi.ok(sonuc);
    ScaffoldMessenger.maybeOf(c)?.showSnackBar(SnackBar(
      backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
      content: Text((sonuc[ok ? 'mesaj' : 'hata'] ?? (ok ? 'Salona iletildi.' : 'Gönderilemedi.')).toString(),
          style: const TextStyle(color: Colors.white)),
    ));
  }

  /// "Kaç dakika gecikeceksiniz?" (iptal edilirse null)
  static Future<int?> dakikaSor(BuildContext ctx) => showModalBottomSheet<int>(
        context: ctx,
        showDragHandle: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (c) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Kaç dakika gecikeceksiniz?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Salon bilgilendirilir, randevunuz iptal olmaz.',
                  style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.55))),
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final d in const [5, 10, 15, 20, 30, 45])
                  ChoiceChip(
                    label: Text('$d dk', style: const TextStyle(fontWeight: FontWeight.w600)),
                    selected: false,
                    onSelected: (_) => Navigator.pop(c, d),
                  ),
              ]),
            ]),
          ),
        ),
      );

  /// Uygulama yeni acildiysa ekranin hazir olmasini bekle
  static Future<BuildContext?> _baglam() async {
    for (var i = 0; i < 40; i++) {
      final c = navigatorKey.currentContext;
      if (c != null) {
        if (i > 0) await Future.delayed(const Duration(milliseconds: 600));
        return navigatorKey.currentContext;
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }
}

/// Randevu detayinda "Geliyorum / Gecikeceğim" karti: son cevabi gosterir, degistirilebilir.
class RandevuYanitKarti extends StatefulWidget {
  final String randevuId;
  final String salonId;
  const RandevuYanitKarti({super.key, required this.randevuId, required this.salonId});

  @override
  State<RandevuYanitKarti> createState() => _RandevuYanitKartiState();
}

class _RandevuYanitKartiState extends State<RandevuYanitKarti> {
  Map? _son;
  bool _gonderiliyor = false;

  @override
  void initState() {
    super.initState();
    ProfilApi.get('/musteri-profil/randevu-yanit', widget.salonId, {'randevu_id': widget.randevuId}).then((r) {
      if (mounted && ProfilApi.ok(r) && r['yanit'] is Map) setState(() => _son = r['yanit'] as Map);
    });
  }

  Future<void> _cevapla(String yanit) async {
    int? dakika;
    if (yanit == RandevuYanit.gecikecegim) {
      dakika = await RandevuYanit.dakikaSor(context);
      if (dakika == null) return;
    }
    setState(() => _gonderiliyor = true);
    final r = await RandevuYanit.gonder(randevuId: widget.randevuId, salonId: widget.salonId, yanit: yanit, dakika: dakika);
    if (!mounted) return;
    setState(() {
      _gonderiliyor = false;
      if (ProfilApi.ok(r)) _son = {'yanit': yanit, 'gecikme_dk': dakika};
    });
    RandevuYanit.bildir(context, r);
  }

  @override
  Widget build(BuildContext context) {
    final yanit = _son?['yanit']?.toString();
    final durum = yanit == RandevuYanit.geliyorum
        ? 'Salona geleceğinizi bildirdiniz ✓'
        : yanit == RandevuYanit.gecikecegim
            ? 'Salona yaklaşık ${_son?['gecikme_dk'] ?? ''} dk gecikeceğinizi bildirdiniz'
            : 'Salona haber verin';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(durum, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _gonderiliyor ? null : () => _cevapla(RandevuYanit.geliyorum),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Geliyorum'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _gonderiliyor ? null : () => _cevapla(RandevuYanit.gecikecegim),
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: const Text('Gecikeceğim'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB45309),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
