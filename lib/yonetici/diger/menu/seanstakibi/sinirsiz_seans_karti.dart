import 'package:flutter/material.dart';

import 'package:randevu_sistem/Models/seanstakibi.dart';
import 'package:randevu_sistem/yonetici/dashboard/paket_satis_hizmetleri.dart';

const Color _yesil = Color(0xFF2E7D32);
const Color _kirmizi = Color(0xFFD32F2F);
const Color _turuncu = Color(0xFFFFA000);
const Color _telafi = Color(0xFFFDA172);
const Color _mor = Color(0xFF5C008E);

/// "2026-11-05" -> "05.11.2026"; bos ise "—".
String seansTarihi(dynamic tarih) {
  final t = (tarih ?? '').toString();
  if (t.length < 10) return '—';
  return '${t.substring(8, 10)}.${t.substring(5, 7)}.${t.substring(0, 4)}';
}

({String metin, Color renk}) _seansDurumu(Map s) {
  final geldi = s['geldi'];
  final iptal = s['iptal'] == 1 || s['iptal'] == true;
  if (geldi == 1) return (metin: 'Kullanıldı', renk: _yesil);
  if (geldi == 2) return (metin: 'Telafi', renk: _telafi);
  if (geldi == 0 || iptal) return (metin: 'Kullanılmadı', renk: _kirmizi);
  return (metin: 'Bekliyor', renk: _turuncu);
}

/// Sinirsiz pakette seans daireleri yerine: baslangic, bitis, sayaclar ve seans dokumu.
class SinirsizSeansKarti extends StatelessWidget {
  final SeansTakip paket;
  final String hizmetAdi;
  final List<dynamic> seanslar;
  final VoidCallback onDokum;
  final VoidCallback onYeniKullanim;

  /// Lazerde "Cihaz Bilgileri" butonu.
  final Widget? altButon;

  const SinirsizSeansKarti({
    Key? key,
    required this.paket,
    required this.hizmetAdi,
    required this.seanslar,
    required this.onDokum,
    required this.onYeniKullanim,
    this.altButon,
  }) : super(key: key);

  int _say(String durum) => seanslar
      .whereType<Map>()
      .where((s) => _seansDurumu(s).metin == durum)
      .length;

  @override
  Widget build(BuildContext context) {
    final doldu = paket.suresiDoldu;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hizmetAdi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(child: SinirsizRozet(metin: paket.sinirsizEtiketi)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _tarih('Başlangıç', paket.baslangic)),
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: Colors.black38),
              const SizedBox(width: 10),
              Expanded(child: _tarih('Bitiş', paket.bitis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            paket.kalanSureMetni,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: doldu ? _kirmizi : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(child: _sayac('Kullanıldı', _say('Kullanıldı'), _yesil)),
                Expanded(child: _sayac('Bekleyen', _say('Bekliyor'), _turuncu)),
                Expanded(
                    child: _sayac('Kullanılmadı', _say('Kullanılmadı'), _kirmizi)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDokum,
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('Seans Dökümü',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _mor,
                    side: const BorderSide(color: _mor),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (!doldu) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onYeniKullanim,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Yeni Kullanım',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (altButon != null) ...[
            const SizedBox(height: 8),
            altButon!,
          ],
        ],
      ),
    );
  }

  Widget _tarih(String etiket, String? tarih) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiket,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
        const SizedBox(height: 1),
        Text(
          seansTarihi(tarih),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _sayac(String etiket, int deger, Color renk) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiket,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
        const SizedBox(height: 1),
        Text('$deger',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: renk)),
      ],
    );
  }
}

/// Randevu gecmisi gibi seans listesi, en yeni ustte. Duzenleme secilince pencere kapanir:
/// liste kayit sonrasi kartla birlikte yeniden yuklenir, eski veri ekranda kalmaz.
Future<void> sinirsizSeansDokumuGoster(
  BuildContext context, {
  required String baslik,
  required List<dynamic> seanslar,
  required void Function(Map seans) onDuzenle,
}) {
  final liste = seanslar.whereType<Map>().toList()
    ..sort((a, b) {
      final ta = '${a['seans_tarih'] ?? ''} ${a['seans_saat'] ?? ''}';
      final tb = '${b['seans_tarih'] ?? ''} ${b['seans_saat'] ?? ''}';
      return tb.compareTo(ta);
    });

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder: (ctx, scroll) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seans Dökümü',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _mor)),
                      Text(baslik,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: liste.isEmpty
                ? ListView(
                    controller: scroll,
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Henüz seans yok.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54)),
                      ),
                    ],
                  )
                : ListView.separated(
                    controller: scroll,
                    itemCount: liste.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = liste[i];
                      final durum = _seansDurumu(s);
                      final saat = (s['seans_saat'] ?? '').toString();
                      final personel = (s['personel_adi'] ?? '').toString();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    saat.length >= 5
                                        ? '${seansTarihi(s['seans_tarih'])}  ${saat.substring(0, 5)}'
                                        : seansTarihi(s['seans_tarih']),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    personel.isEmpty ? '—' : personel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: durum.renk.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                durum.metin,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: _mor),
                              tooltip: 'Düzenle',
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                onDuzenle(s);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
