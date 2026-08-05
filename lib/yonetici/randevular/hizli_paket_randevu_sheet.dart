import 'package:flutter/material.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/odalar.dart';
import 'package:randevu_sistem/Models/cihazlar.dart';
import 'package:randevu_sistem/Models/isletmehizmetleri.dart';
import 'package:randevu_sistem/Models/randevuhizmetleri.dart';
import 'package:randevu_sistem/Frontend/aramali_dropdown.dart';

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

    final pAdi = s['paket_adi']?.toString();
    final isPaket = pAdi != null && pAdi.isNotEmpty;
    final adetVar = int.tryParse(s['dusum_miktari']?.toString() ?? '');
    final maxAdet = int.tryParse(s['seans']?.toString() ?? '') ?? 99;
    return _SatirDurum(
      hizmetId: s['hizmet_id']?.toString() ?? '',
      hizmetAdi: s['hizmet_adi']?.toString() ?? '',
      paketAdi: pAdi,
      adisyonPaketId: s['adisyon_paket_id'],
      adisyonHizmetId: s['adisyon_hizmet_id'],
      personel: basePersonel,
      oda: baseOda,
      cihaz: baseCihaz,
      sure: sureCoz(),
      birlestir: false,
      dusumMiktari: (adetVar != null && adetVar > 0) ? adetVar : 1,
      paketSatiri: isPaket,
      maxAdet: maxAdet < 1 ? 1 : maxAdet,
    );
  }).toList();

  final bool gosterPersonel = true; // her zaman
  final bool gosterCihaz = takvimTuru == 0 || takvimTuru == 2;
  final bool gosterOda = takvimTuru == 0 || takvimTuru == 3;

  // Toplu mod state (web 'Tum hizmetlere uygula' karsiligi).
  // Default: ozellestir=false -> tek panel; tum hizmetlere uygulanir.
  bool ozellestir = false;
  Personel? toplulPersonel = basePersonel;
  Oda? toplulOda = baseOda;
  Cihaz? toplulCihaz = baseCihaz;
  int toplulPaketSure = secimler.fold(0, (t, s) => t + s.sure);

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
              int toplamSure = ozellestir
                  ? secimler.fold(0, (t, s) => t + s.sure)
                  : toplulPaketSure;

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
                  // Body
                  Expanded(
                    child: !ozellestir
                        ? _topluBody(
                            context: ctx,
                            scrollController: scrollController,
                            secimler: secimler,
                            gosterPersonel: gosterPersonel,
                            gosterOda: gosterOda,
                            gosterCihaz: gosterCihaz,
                            personelliste: personelliste,
                            odaliste: odaliste,
                            cihazliste: cihazliste,
                            toplulPersonel: toplulPersonel,
                            toplulOda: toplulOda,
                            toplulCihaz: toplulCihaz,
                            toplulPaketSure: toplulPaketSure,
                            onPersonel: (v) =>
                                setLocalState(() => toplulPersonel = v),
                            onOda: (v) => setLocalState(() => toplulOda = v),
                            onCihaz: (v) =>
                                setLocalState(() => toplulCihaz = v),
                            onPaketSure: (v) =>
                                setLocalState(() => toplulPaketSure = v),
                            onOzellestir: () {
                              setLocalState(() {
                                // Toplu degerleri tum satirlara uygula, sonra
                                // ozellestirme aciliyor
                                for (int i = 0; i < secimler.length; i++) {
                                  secimler[i].personel = toplulPersonel;
                                  secimler[i].oda = toplulOda;
                                  secimler[i].cihaz = toplulCihaz;
                                  secimler[i].sure = i == 0
                                      ? toplulPaketSure
                                      : 0;
                                }
                                ozellestir = true;
                              });
                            },
                          )
                        : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: secimler.length + 1,
                      itemBuilder: (context, indexRaw) {
                        if (indexRaw == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Hizmet başına özelleştirme',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => setLocalState(
                                      () => ozellestir = false),
                                  icon: const Icon(Icons.unfold_less,
                                      size: 16),
                                  label: const Text('Toplu Seç',
                                      style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 0),
                                    minimumSize: const Size(0, 28),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final index = indexRaw - 1;
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
                              // Sure + Adet (paket satirinda)
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
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
                                  ),
                                  if (d.paketSatiri) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Adet',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              onTap: d.dusumMiktari > 1
                                                  ? () => setLocalState(() =>
                                                      d.dusumMiktari--)
                                                  : null,
                                              child: Icon(
                                                Icons.remove,
                                                size: 18,
                                                color: d.dusumMiktari > 1
                                                    ? const Color(0xFF6A1B9A)
                                                    : const Color(0xFFB9A6C6),
                                              ),
                                            ),
                                            Text(
                                              '${d.dusumMiktari}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF6A1B9A),
                                                fontSize: 14,
                                              ),
                                            ),
                                            InkWell(
                                              onTap:
                                                  d.dusumMiktari < d.maxAdet
                                                      ? () => setLocalState(
                                                          () =>
                                                              d.dusumMiktari++)
                                                      : null,
                                              child: Icon(
                                                Icons.add,
                                                size: 18,
                                                color: d.dusumMiktari <
                                                        d.maxAdet
                                                    ? const Color(0xFF6A1B9A)
                                                    : const Color(0xFFB9A6C6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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
                                  // Toplu modda toplu degerleri satirlara uygula
                                  if (!ozellestir) {
                                    for (int i = 0;
                                        i < secimler.length;
                                        i++) {
                                      secimler[i].personel = toplulPersonel;
                                      secimler[i].oda = toplulOda;
                                      secimler[i].cihaz = toplulCihaz;
                                      secimler[i].sure =
                                          i == 0 ? toplulPaketSure : 0;
                                    }
                                  }
                                  // Eksik secim kontrolu
                                  String? hata;
                                  if (!ozellestir) {
                                    if (takvimTuru == 1 &&
                                        toplulPersonel == null) {
                                      hata = 'Personel seçin.';
                                    } else if (takvimTuru == 2 &&
                                        toplulCihaz == null) {
                                      hata = 'Cihaz seçin.';
                                    } else if (takvimTuru == 3 &&
                                        toplulOda == null) {
                                      hata = 'Oda seçin.';
                                    }
                                  } else {
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
                                      // birlestir bayragi 2. pass'te onceki
                                      // hizmete yazilir (API semantigi).
                                      birusttekiileaynisaat: '',
                                      paket_adi: d.paketAdi,
                                      adisyon_paket_id:
                                          d.adisyonPaketId,
                                      adisyon_hizmet_id:
                                          d.adisyonHizmetId,
                                      dusum_miktari:
                                          d.dusumMiktari.toString(),
                                      groupId: grupId,
                                    ));
                                  }
                                  // Birlestir bayragi: API'de hizmetler[i].birlestir=='1'
                                  // => hizmet[i+1] hizmet[i] ile paralel olur.
                                  // Kullanici i. satirda "ustteki ile birlestir"
                                  // isaretlemisse => onceki hizmete (i-1) bayrak yaz.
                                  for (int i = 1; i < secimler.length; i++) {
                                    if (secimler[i].birlestir) {
                                      sonuc[i - 1].birusttekiileaynisaat = '1';
                                    }
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

/// Toplu mod gövdesi: tek personel/oda/cihaz/sure + bilgi + hizmet listesi
/// + "Hizmetleri Özelleştir" butonu (web 'Tum hizmetlere uygula' karsiligi).
Widget _topluBody({
  required BuildContext context,
  required ScrollController scrollController,
  required List<_SatirDurum> secimler,
  required bool gosterPersonel,
  required bool gosterOda,
  required bool gosterCihaz,
  required List<Personel> personelliste,
  required List<Oda> odaliste,
  required List<Cihaz> cihazliste,
  required Personel? toplulPersonel,
  required Oda? toplulOda,
  required Cihaz? toplulCihaz,
  required int toplulPaketSure,
  required ValueChanged<Personel?> onPersonel,
  required ValueChanged<Oda?> onOda,
  required ValueChanged<Cihaz?> onCihaz,
  required ValueChanged<int> onPaketSure,
  required VoidCallback onOzellestir,
}) {
  return ListView(
    controller: scrollController,
    padding: const EdgeInsets.all(12),
    children: [
      // Bilgi seridi
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF7DD3FC), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.info_outline, size: 18, color: Color(0xFF0369A1)),
            SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF0C4A6E), height: 1.35),
                  children: [
                    TextSpan(
                      text: 'Tüm hizmetlere uygula',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text:
                          ' — buradan seçtikleriniz tüm hizmet satırlarına uygulanır; tek bir hizmeti ayrı ayarlamak için Özelleştir\'e tıklayın.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      // Toplu form
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (gosterPersonel)
              _dropdown<Personel>(
                label: 'Personel',
                value: toplulPersonel,
                items: personelliste,
                itemLabel: (p) => p.personel_adi,
                onChanged: onPersonel,
              ),
            if (gosterOda) ...[
              const SizedBox(height: 10),
              _dropdown<Oda>(
                label: 'Oda',
                value: toplulOda,
                items: odaliste,
                itemLabel: (o) => o.oda_adi,
                onChanged: onOda,
              ),
            ],
            if (gosterCihaz) ...[
              const SizedBox(height: 10),
              _dropdown<Cihaz>(
                label: 'Cihaz',
                value: toplulCihaz,
                items: cihazliste,
                itemLabel: (c) => c.cihaz_adi,
                onChanged: onCihaz,
              ),
            ],
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey('toplul-sure-$toplulPaketSure'),
              initialValue: toplulPaketSure.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Paket Süresi (dk)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n >= 0) onPaketSure(n);
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      // Onay seridi + Ozellestir butonu
      Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCD34D), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${secimler.length} hizmet pakete eklendi — hepsi yukarıdaki personel/oda/cihaz ile uygulanır.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF78350F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onOzellestir,
              icon: const Icon(Icons.tune, size: 16),
              label: const Text(
                'Hizmetleri özelleştir',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF92400E),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      // Hizmet listesi (sadece okunur preview)
      ...secimler.asMap().entries.map((e) {
        final i = e.key;
        final d = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFFE0F2FE),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  d.hizmetAdi,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (d.paketAdi != null && d.paketAdi!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '📦 ${d.paketAdi}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    ],
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
  return AramaliDropdownFormField<T>(
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
  // Paketten dusulen seans miktari (web randevu_hizmetler.dusum_miktari)
  int dusumMiktari;
  // Pakete ait satir mi (Adet UI'sini sadece bunlarda goster)
  final bool paketSatiri;
  // UI stepper maks degeri — paketteki kalan seans (s['seans']).
  final int maxAdet;

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
    required this.dusumMiktari,
    required this.paketSatiri,
    required this.maxAdet,
  });
}
