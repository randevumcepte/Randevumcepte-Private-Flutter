import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/odalar.dart';
import 'package:randevu_sistem/Models/cihazlar.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/randevuhizmetleri.dart';

/// Hizli Paket Randevu bottom sheet'i — web'deki "Hizli Paket Randevu" modalinin
/// Flutter karsiligi. Pakette birden fazla hizmet varsa her hizmet icin tek
/// pencerede personel/oda/cihaz/sure secimi yapilir ve "Randevu Olustur" ile
/// dogrudan RandevuHizmet listesi dondurulur (editor randevuEkleGuncelle cagirir).
///
/// secilenler: showPaketSecimBottomSheet ciktisi (her eleman bir hizmet satiri).
/// takvimTuru: 0=Hizmete, 1=Personele, 2=Cihaza, 3=Odaya gore.
/// Vazgec'e basilirsa null doner.
Future<List<RandevuHizmet>?> showHizliPaketRandevuSheet({
  required BuildContext context,
  required List<Map<String, dynamic>> secilenler,
  required List<Personel> personelliste,
  required List<Oda> odaliste,
  required List<Cihaz> cihazliste,
  required List<IsletmeHizmet> isletmehizmetliste,
  required int takvimTuru,
  required String musteriAdi,
  required String tarih,
  required String saat,
  Personel? basePersonel,
  Oda? baseOda,
  Cihaz? baseCihaz,
}) {
  // Her satir icin secim durumu
  final secimler = secilenler.map((s) {
    // Sure cozumle: secim['sure'] -> salon hizmet listesi -> 30
    int sureCoz() {
      final s1 = int.tryParse(s['sure']?.toString() ?? '');
      if (s1 != null && s1 > 0) return s1;
      final hid = s['hizmet_id']?.toString() ?? '';
      for (final h in isletmehizmetliste) {
        if (h.hizmet_id == hid) {
          final s2 = int.tryParse(h.sure.toString());
          if (s2 != null && s2 > 0) return s2;
        }
      }
      return 30;
    }

    return _SatirDurum(
      hizmetId: s['hizmet_id']?.toString() ?? '',
      hizmetAdi: s['hizmet_adi']?.toString() ?? '',
      paketAdi: s['paket_adi']?.toString(),
      adisyonPaketId: s['adisyon_paket_id'],
      adisyonHizmetId: s['adisyon_hizmet_id'],
      personel: basePersonel,
      oda: baseOda,
      cihaz: baseCihaz,
      sure: sureCoz(),
      birlestir: false,
    );
  }).toList();

  final bool gosterPersonel = true; // her zaman
  final bool gosterCihaz = takvimTuru == 0 || takvimTuru == 2;
  final bool gosterOda = takvimTuru == 0 || takvimTuru == 3;

  return showModalBottomSheet<List<RandevuHizmet>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return StatefulBuilder(
            builder: (ctx, setLocalState) {
              int toplamSure = secimler.fold(0, (t, s) => t + s.sure);

              return Column(
                children: [
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.bolt, color: Color(0xFF10B981)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hızlı Paket Randevu',
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
                          '$musteriAdi — $tarih $saat • ${secimler.length} hizmet',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Liste
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: secimler.length,
                      itemBuilder: (context, index) {
                        final d = secimler[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Baslik
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${index + 1}. ${d.hizmetAdi}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5),
                                    ),
                                  ),
                                  if (d.paketAdi != null &&
                                      d.paketAdi!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '📦 ${d.paketAdi}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Personel
                              if (gosterPersonel)
                                _dropdown<Personel>(
                                  label: 'Personel',
                                  value: d.personel,
                                  items: personelliste,
                                  itemLabel: (p) => p.personel_adi,
                                  onChanged: (v) => setLocalState(
                                      () => d.personel = v),
                                ),
                              if (gosterOda) ...[
                                const SizedBox(height: 8),
                                _dropdown<Oda>(
                                  label: 'Oda',
                                  value: d.oda,
                                  items: odaliste,
                                  itemLabel: (o) => o.oda_adi,
                                  onChanged: (v) =>
                                      setLocalState(() => d.oda = v),
                                ),
                              ],
                              if (gosterCihaz) ...[
                                const SizedBox(height: 8),
                                _dropdown<Cihaz>(
                                  label: 'Cihaz',
                                  value: d.cihaz,
                                  items: cihazliste,
                                  itemLabel: (c) => c.cihaz_adi,
                                  onChanged: (v) =>
                                      setLocalState(() => d.cihaz = v),
                                ),
                              ],
                              const SizedBox(height: 8),
                              // Sure
                              TextFormField(
                                initialValue: d.sure.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Süre (dk)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) {
                                  final n = int.tryParse(v);
                                  if (n != null && n >= 0) {
                                    setLocalState(() => d.sure = n);
                                  }
                                },
                              ),
                              // Ustteki ile birlestir (ilk satir haric)
                              if (index > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: CheckboxListTile(
                                    value: d.birlestir,
                                    onChanged: (v) => setLocalState(
                                        () => d.birlestir = v ?? false),
                                    activeColor: const Color(0xFF6366F1),
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    dense: true,
                                    title: const Text(
                                      'Üstteki hizmetle aynı saatte (paralel)',
                                      style: TextStyle(fontSize: 12),
                                    ),
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
                      8,
                      16,
                      12 + MediaQuery.of(ctx).viewPadding.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Toplam: ${secimler.length} hizmet',
                                  style: const TextStyle(fontSize: 12)),
                              Text('$toplamSure dk',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(null),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                child: const Text('Vazgeç'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Eksik secim kontrolu
                                  String? hata;
                                  for (int i = 0;
                                      i < secimler.length;
                                      i++) {
                                    final d = secimler[i];
                                    if (takvimTuru == 1 &&
                                        d.personel == null) {
                                      hata =
                                          '${i + 1}. hizmet için personel seçin.';
                                      break;
                                    }
                                    if (takvimTuru == 2 &&
                                        d.cihaz == null) {
                                      hata =
                                          '${i + 1}. hizmet için cihaz seçin.';
                                      break;
                                    }
                                    if (takvimTuru == 3 &&
                                        d.oda == null) {
                                      hata =
                                          '${i + 1}. hizmet için oda seçin.';
                                      break;
                                    }
                                  }
                                  if (hata != null) {
                                    ScaffoldMessenger.of(ctx)
                                        .showSnackBar(SnackBar(
                                      content: Text(hata),
                                      backgroundColor: Colors.orange,
                                    ));
                                    return;
                                  }
                                  // RandevuHizmet listesi olustur
                                  final grupId =
                                      'g-${DateTime.now().millisecondsSinceEpoch}';
                                  final sonuc = <RandevuHizmet>[];
                                  for (int i = 0;
                                      i < secimler.length;
                                      i++) {
                                    final d = secimler[i];
                                    // Hizmet objesi bul/uret
                                    IsletmeHizmet hizmetObj;
                                    final eslesen = isletmehizmetliste
                                        .where((h) =>
                                            h.hizmet_id == d.hizmetId)
                                        .toList();
                                    if (eslesen.isNotEmpty) {
                                      hizmetObj = eslesen.first;
                                    } else {
                                      hizmetObj = IsletmeHizmet(
                                        hizmet_id: d.hizmetId,
                                        hizmet: {
                                          'hizmet_adi': d.hizmetAdi
                                        },
                                        hizmet_kategorisi: null,
                                        sure: d.sure.toString(),
                                        fiyat: '0',
                                        bolum: '',
                                      );
                                    }
                                    sonuc.add(RandevuHizmet(
                                      hizmetler: hizmetObj,
                                      hizmet_id: d.hizmetId,
                                      personel_id:
                                          d.personel?.id ?? '',
                                      personeller: d.personel,
                                      oda_id: d.oda?.id ?? '',
                                      oda: d.oda,
                                      cihaz_id: d.cihaz?.id ?? '',
                                      cihaz: d.cihaz,
                                      fiyat: '0',
                                      sure_dk: d.sure.toString(),
                                      saat: '',
                                      saat_bitis: '',
                                      yardimci_personel: '',
                                      // birlestir='1' => paralel (ust ile ayni saat)
                                      birusttekiileaynisaat:
                                          (i > 0 && d.birlestir)
                                              ? '1'
                                              : '',
                                      paket_adi: d.paketAdi,
                                      adisyon_paket_id:
                                          d.adisyonPaketId,
                                      adisyon_hizmet_id:
                                          d.adisyonHizmetId,
                                      groupId: grupId,
                                    ));
                                  }
                                  Navigator.of(ctx).pop(sonuc);
                                },
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text(
                                  'Randevu Oluştur',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                              ),
                            ),
                          ],
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

/// Generic dropdown helper
Widget _dropdown<T>({
  required String label,
  required T? value,
  required List<T> items,
  required String Function(T) itemLabel,
  required ValueChanged<T?> onChanged,
}) {
  return DropdownButtonFormField<T>(
    value: items.contains(value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      border: const OutlineInputBorder(),
    ),
    hint: Text('$label seçin'),
    items: items
        .map((e) => DropdownMenuItem<T>(
              value: e,
              child: Text(itemLabel(e), overflow: TextOverflow.ellipsis),
            ))
        .toList(),
    onChanged: onChanged,
  );
}

/// Bir satirin secim durumu (mutable)
class _SatirDurum {
  final String hizmetId;
  final String hizmetAdi;
  final String? paketAdi;
  final dynamic adisyonPaketId;
  final dynamic adisyonHizmetId;
  Personel? personel;
  Oda? oda;
  Cihaz? cihaz;
  int sure;
  bool birlestir;

  _SatirDurum({
    required this.hizmetId,
    required this.hizmetAdi,
    required this.paketAdi,
    required this.adisyonPaketId,
    required this.adisyonHizmetId,
    required this.personel,
    required this.oda,
    required this.cihaz,
    required this.sure,
    required this.birlestir,
  });
}
