// Şimdilik kaldırıldı.
//rial.dart';

/// Müşterinin bekleyen paket/hizmetlerini listeler.
/// Kullanıcı seçimleri onaylarsa seçili paket detaylarını döner; vazgeçerse null.
/*Future<List<Map<String, dynamic>>?> showMusteriPaketleriDialog({
  required BuildContext context,
  required String userName,
  required List<Map<String, dynamic>> paketDetaylari,
}) {
  final secimler = List<bool>.filled(paketDetaylari.length, false);

  return showDialog<List<Map<String, dynamic>>>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setLocalState) {
          final secilenSayisi = secimler.where((s) => s).length;
          return AlertDialog(
            insetPadding: const EdgeInsets.all(16),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Müşteri Paket/Hizmetleri',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  '$userName için bekleyen paket/hizmetler',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.normal),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: paketDetaylari.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              _info('Kalan', '$seans seans'),
                              if (sure != '0' && sure.isNotEmpty)
                                _info('Süre', '$sure dk'),
                              _info('Tür', isPaket ? 'Paket' : 'Tek Hizmet'),
                            ],
                          ),
                        ),
                        if (isPaket && icerik.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              icerik
                                  .map((h) => '• ${h['text']} (${h['seans']})')
                                  .join('\n'),
                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton(
                onPressed: secilenSayisi == 0
                    ? null
                    : () {
                        final secilenler = <Map<String, dynamic>>[];
                        for (int i = 0; i < secimler.length; i++) {
                          if (secimler[i]) {
                            secilenler.add(Map<String, dynamic>.from(paketDetaylari[i]));
                          }
                        }
                        Navigator.of(ctx).pop(secilenler);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                ),
                child: Text('Seçilenleri Ekle ($secilenSayisi)'),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _info(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      '$label: $value',
      style: const TextStyle(fontSize: 11),
    ),
  );
}*/
