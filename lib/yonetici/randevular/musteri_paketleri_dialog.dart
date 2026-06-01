import 'package:flutter/material.dart';

/// Musterinin aktif paket/hizmetleri icin secim bottom sheet'i.
/// Backend'in paketVarmiKontrolu response'undaki paketDetaylari listesini alir,
/// secim sonucunda her bir hizmet icin tek bir satir (Map) doner:
///   { hizmet_id, hizmet_adi, sure, paket_adi (null olabilir),
///     adisyon_paket_id (null olabilir), adisyon_hizmet_id (null olabilir) }
/// Vazgec'e basilirsa null doner.
Future<List<Map<String, dynamic>>?> showPaketSecimBottomSheet({
  required BuildContext context,
  required String userName,
  required List<Map<String, dynamic>> paketDetaylari,
  String? onayMetni,
}) {
  final secimler = List<bool>.filled(paketDetaylari.length, false);

  return showModalBottomSheet<List<Map<String, dynamic>>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return StatefulBuilder(
            builder: (ctx, setLocalState) {
              final secilenSayisi = secimler.where((s) => s).length;

              return Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.card_giftcard, color: Color(0xFF6A1B9A)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Müşteri Paket/Hizmetleri',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$userName için bekleyen paket/hizmetlerden seçim yap:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (onayMetni != null && onayMetni.trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFE0C16A), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 18, color: Color(0xFFB07B00)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              // HTML iceriklerini kaba bicimde temizle.
                              onayMetni
                                  .replaceAll(RegExp(r'<[^>]*>'), '')
                                  .replaceAll('&nbsp;', ' ')
                                  .trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7A5300),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Liste
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: paketDetaylari.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final item = paketDetaylari[index];
                        final isPaket = item['type'] == 'paket';
                        final adi = item['adi']?.toString() ?? '';
                        final seans = item['seans']?.toString() ?? '0';
                        final sure = item['sure']?.toString() ?? '0';
                        final icerik = (item['icerik'] as List?) ?? [];

                        return CheckboxListTile(
                          value: secimler[index],
                          onChanged: (val) {
                            setLocalState(() {
                              secimler[index] = val ?? false;
                            });
                          },
                          activeColor: const Color(0xFF6A1B9A),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Row(
                            children: [
                              Text(isPaket ? '📦 ' : '✨ '),
                              Expanded(
                                child: Text(
                                  adi,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _infoChip('Kalan', '$seans seans'),
                                    if (sure != '0' && sure.isNotEmpty)
                                      _infoChip('Süre', '$sure dk'),
                                    _infoChip(
                                        'Tür', isPaket ? 'Paket' : 'Tek Hizmet'),
                                  ],
                                ),
                              ),
                              if (isPaket && icerik.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    icerik
                                        .map((h) =>
                                            '• ${h['text']} (${h['seans']} seans)')
                                        .join('\n'),
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[700]),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Footer
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      12 + MediaQuery.of(ctx).viewPadding.bottom,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(null),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Vazgeç'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: secilenSayisi == 0
                                ? null
                                : () {
                                    final hizmetSatirlari =
                                        <Map<String, dynamic>>[];
                                    for (int i = 0;
                                        i < secimler.length;
                                        i++) {
                                      if (!secimler[i]) continue;
                                      final item = paketDetaylari[i];
                                      final isPaket = item['type'] == 'paket';
                                      final icerik =
                                          (item['icerik'] as List?) ?? [];
                                      // Her paket icindeki her hizmet ayri satir.
                                      // Tek hizmet ise icerik 1 elemanlidir.
                                      for (final h in icerik) {
                                        hizmetSatirlari.add({
                                          'hizmet_id': h['id'],
                                          'hizmet_adi':
                                              h['text']?.toString() ?? '',
                                          'sure': h['sure'],
                                          // Paketin TOPLAM suresi (listede
                                          // gosterilen item['sure']). Editor
                                          // bunu pakete ait ilk satira
                                          // yazip kalan satirlari 0 yapar.
                                          'paket_sure':
                                              isPaket ? item['sure'] : null,
                                          'paket_adi': isPaket
                                              ? item['adi']?.toString()
                                              : null,
                                          'adisyon_paket_id':
                                              item['adisyon_paket_id'],
                                          'adisyon_hizmet_id':
                                              item['adisyon_hizmet_id'],
                                        });
                                      }
                                    }
                                    Navigator.of(ctx).pop(hizmetSatirlari);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A1B9A),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              secilenSayisi == 0
                                  ? 'Seçilenleri Ekle'
                                  : 'Seçilenleri Ekle ($secilenSayisi)',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

Widget _infoChip(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '$label: $value',
      style: const TextStyle(fontSize: 11),
    ),
  );
}
