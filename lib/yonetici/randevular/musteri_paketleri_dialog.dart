import 'package:flutter/material.dart';

/// Musterinin aktif paket/hizmetleri icin secim bottom sheet'i.
///
/// Davranis:
/// - Tek hizmet veya tek icerikli paket: tek checkbox (toplu secim).
/// - Coklu icerikli paket: default "toplu" tek satir + "Ozellestir" pill.
///   Ozellestirme acilirsa her hizmet ayri checkbox olur, kullanici subset
///   secebilir. Tum kalemler secilirse paket suresi ilk satira yazilir
///   (editor mantigi); subset secilirse paket_sure gonderilmez ve editor
///   secilen kalem surelerini toplar.
///
/// Donen liste her bir hizmet satiri icin:
///   { hizmet_id, hizmet_adi, sure, paket_adi, paket_sure?,
///     adisyon_paket_id, adisyon_hizmet_id }
/// Vazgec'e basilirsa null doner.
Future<List<Map<String, dynamic>>?> showPaketSecimBottomSheet({
  required BuildContext context,
  required String userName,
  required List<Map<String, dynamic>> paketDetaylari,
  String? onayMetni,
}) {
  // Item basina state
  final bulkSecili = List<bool>.filled(paketDetaylari.length, false);
  final ozellestirAcik = List<bool>.filled(paketDetaylari.length, false);
  final kalemSecili = List<List<bool>>.generate(
    paketDetaylari.length,
    (i) {
      final icerik = (paketDetaylari[i]['icerik'] as List?) ?? [];
      return List<bool>.filled(icerik.length, false);
    },
  );
  // Adet (dusum_miktari) — paketten kac seans dusulecek. Varsayilan 1.
  final dusumMiktari = List<List<int>>.generate(
    paketDetaylari.length,
    (i) {
      final icerik = (paketDetaylari[i]['icerik'] as List?) ?? [];
      return List<int>.filled(icerik.length, 1);
    },
  );

  bool _itemSeciliMi(int i) {
    if (ozellestirAcik[i]) return kalemSecili[i].any((s) => s);
    return bulkSecili[i];
  }

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
              final secilenSayisi =
                  List.generate(paketDetaylari.length, _itemSeciliMi)
                      .where((s) => s)
                      .length;

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
                        return _PaketItemRow(
                          item: paketDetaylari[index],
                          bulkSecili: bulkSecili[index],
                          ozellestirAcik: ozellestirAcik[index],
                          kalemSecili: kalemSecili[index],
                          dusumMiktari: dusumMiktari[index],
                          onAdetChanged: (j, v) {
                            setLocalState(() {
                              dusumMiktari[index][j] = v;
                            });
                          },
                          onBulkChanged: (v) {
                            setLocalState(() {
                              bulkSecili[index] = v;
                            });
                          },
                          onKalemChanged: (j, v) {
                            setLocalState(() {
                              kalemSecili[index][j] = v;
                            });
                          },
                          onOzellestirToggle: () {
                            setLocalState(() {
                              final yeni = !ozellestirAcik[index];
                              ozellestirAcik[index] = yeni;
                              if (yeni) {
                                // Ozellestirme acilirken bulk durumunu kalem
                                // listesine yans
                                for (var j = 0;
                                    j < kalemSecili[index].length;
                                    j++) {
                                  kalemSecili[index][j] = bulkSecili[index];
                                }
                              } else {
                                // Toplu'ya donus: en az bir kalem seciliyse
                                // bulk acik say
                                bulkSecili[index] =
                                    kalemSecili[index].any((s) => s);
                              }
                            });
                          },
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
                                        i < paketDetaylari.length;
                                        i++) {
                                      final item = paketDetaylari[i];
                                      final isPaket =
                                          item['type'] == 'paket';
                                      final icerik =
                                          (item['icerik'] as List?) ?? [];
                                      final ozellestir = ozellestirAcik[i];

                                      // Hangi icerik index'leri eklenecek?
                                      final dahil = <int>[];
                                      if (ozellestir) {
                                        for (int j = 0;
                                            j < icerik.length;
                                            j++) {
                                          if (kalemSecili[i][j]) dahil.add(j);
                                        }
                                      } else if (bulkSecili[i]) {
                                        for (int j = 0;
                                            j < icerik.length;
                                            j++) {
                                          dahil.add(j);
                                        }
                                      }
                                      if (dahil.isEmpty) continue;

                                      final tumKalemler =
                                          dahil.length == icerik.length;
                                      for (final j in dahil) {
                                        final h = icerik[j];
                                        hizmetSatirlari.add({
                                          'hizmet_id': h['id'],
                                          'hizmet_adi':
                                              h['text']?.toString() ?? '',
                                          'sure': h['sure'],
                                          'seans': h['seans'],
                                          'paket_sure': (isPaket && tumKalemler)
                                              ? item['sure']
                                              : null,
                                          'paket_adi': isPaket
                                              ? item['adi']?.toString()
                                              : null,
                                          'adisyon_paket_id':
                                              item['adisyon_paket_id'],
                                          'adisyon_hizmet_id':
                                              item['adisyon_hizmet_id'],
                                          // Web randevu_hizmetler.dusum_miktari
                                          'dusum_miktari':
                                              dusumMiktari[i][j].toString(),
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

class _PaketItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool bulkSecili;
  final bool ozellestirAcik;
  final List<bool> kalemSecili;
  final List<int> dusumMiktari;
  final ValueChanged<bool> onBulkChanged;
  final void Function(int index, bool value) onKalemChanged;
  final void Function(int index, int value) onAdetChanged;
  final VoidCallback onOzellestirToggle;

  const _PaketItemRow({
    required this.item,
    required this.bulkSecili,
    required this.ozellestirAcik,
    required this.kalemSecili,
    required this.dusumMiktari,
    required this.onBulkChanged,
    required this.onKalemChanged,
    required this.onAdetChanged,
    required this.onOzellestirToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isPaket = item['type'] == 'paket';
    final adi = item['adi']?.toString() ?? '';
    final seans = item['seans']?.toString() ?? '0';
    final sure = item['sure']?.toString() ?? '0';
    final icerik = (item['icerik'] as List?) ?? [];
    final ozellestirilebilir = isPaket && icerik.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toplu/baslik satir
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol checkbox — ozellestirme acikken devre disi (kalem
              // checkboxlari kullanilir)
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: ozellestirAcik
                      ? (kalemSecili.every((s) => s) && kalemSecili.isNotEmpty)
                      : bulkSecili,
                  tristate: ozellestirAcik,
                  activeColor: const Color(0xFF6A1B9A),
                  onChanged: (v) {
                    if (ozellestirAcik) {
                      final hepsi = v == true;
                      for (var j = 0; j < kalemSecili.length; j++) {
                        onKalemChanged(j, hepsi);
                      }
                    } else {
                      onBulkChanged(v ?? false);
                    }
                  },
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(isPaket ? '📦 ' : '✨ '),
                        Expanded(
                          child: Text(
                            adi,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (ozellestirilebilir)
                          TextButton.icon(
                            onPressed: onOzellestirToggle,
                            icon: Icon(
                              ozellestirAcik
                                  ? Icons.unfold_less
                                  : Icons.tune,
                              size: 16,
                            ),
                            label: Text(
                              ozellestirAcik ? 'Toplu Seç' : 'Özelleştir',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6A1B9A),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                              minimumSize: const Size(0, 28),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _infoChip('Kalan', '$seans seans'),
                        if (sure != '0' && sure.isNotEmpty)
                          _infoChip('Süre', '$sure dk'),
                        _infoChip('Tür', isPaket ? 'Paket' : 'Tek Hizmet'),
                      ],
                    ),
                    // Kapali (toplu) gorunum: icerik kucuk metin listesi
                    if (!ozellestirAcik && isPaket && icerik.isNotEmpty)
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
              ),
            ],
          ),
          // Acik (ozellestir) gorunum: her hizmet ayri checkbox
          if (ozellestirAcik && icerik.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 6, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(icerik.length, (j) {
                  final h = icerik[j];
                  final int maxAdet =
                      int.tryParse(h['seans']?.toString() ?? '') ?? 1;
                  final int aktifAdet = dusumMiktari[j].clamp(1, maxAdet < 1 ? 1 : maxAdet);
                  final bool secili = kalemSecili[j];
                  return InkWell(
                    onTap: () => onKalemChanged(j, !secili),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Checkbox(
                              value: secili,
                              activeColor: const Color(0xFF6A1B9A),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: (v) =>
                                  onKalemChanged(j, v ?? false),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${h['text']}  ·  ${h['seans']} seans',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          // Adet stepper — sadece kalem seciliyse aktif
                          Opacity(
                            opacity: secili ? 1.0 : 0.4,
                            child: _AdetStepper(
                              value: aktifAdet,
                              min: 1,
                              max: maxAdet < 1 ? 1 : maxAdet,
                              enabled: secili,
                              onChanged: (v) => onAdetChanged(j, v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdetStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _AdetStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool canDec = enabled && value > min;
    final bool canInc = enabled && value < max;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD8C7E5), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(
            icon: Icons.remove,
            enabled: canDec,
            onTap: () => onChanged(value - 1),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A1B9A),
              ),
            ),
          ),
          _stepBtn(
            icon: Icons.add,
            enabled: canInc,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Icon(
          icon,
          size: 14,
          color: enabled
              ? const Color(0xFF6A1B9A)
              : const Color(0xFFB9A6C6),
        ),
      ),
    );
  }
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
