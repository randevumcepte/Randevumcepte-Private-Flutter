// arsivdetay.dart
//
// Form Yonetimi listesinde bir karta tiklayinca acilan detay dialog'u.
// Web'deki "..." menusunun mobil karsiligi: Formu Gor (uygulama ici PDF),
// Indir, Formu Tekrar Gonder, Onayla, Iptal Et.
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path/path.dart' as path;

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Models/colorandtext.dart';
import 'package:randevu_sistem/Models/form.dart';
import 'package:randevu_sistem/Frontend/datetimeformatting.dart';
import 'package:randevu_sistem/Frontend/filedownloader.dart';
import 'package:randevu_sistem/Frontend/form_pdf_goster.dart';

// Uretilen form/sozlesme PDF'i statik dosya degildir; backend arsivid'den
// aninda PDF uretir. Web'deki /isletmeyonetim/formgoster session gerektirir,
// bu yuzden mobil session'siz API ucunu kullanir (salon arsivden alinir).
// Harici belgeler de bu uclarin else-dalindan dosyayi doner.
String _formGosterUrl(Arsiv arsiv) =>
    'https://app.randevumcepte.com.tr/api/v1/formgoster?arsivid=${arsiv.id}';

String _formIndirUrl(Arsiv arsiv) =>
    'https://app.randevumcepte.com.tr/api/v1/formindir?arsivid=${arsiv.id}';

String _formBaslik(Arsiv arsiv) {
  final adi = arsiv.form["form_adi"];
  if (adi != null && adi != 'harici' && adi != 'Harici Belge') {
    return adi.toString();
  }
  return arsiv.sozlesme_adi.isNotEmpty ? arsiv.sozlesme_adi : '-';
}

/// "Formu Gör" ile uygulama ici PDF olarak gosterilebilir mi?
/// Uretilen form/sozlesme her zaman PDF olarak doner (formgoster). Harici
/// belge ise yalnizca uzantisi .pdf oldugunda goruntulenebilir (resim vb. degil).
bool _pdfMi(Arsiv arsiv) {
  final adi = arsiv.form["form_adi"]?.toString() ?? '';
  final harici = adi == 'Harici Belge' || adi == 'harici';
  if (harici) {
    return path.extension(arsiv.uzanti).toLowerCase() == '.pdf';
  }
  return true;
}

/// [onDegisti] onayla/iptal/gonder sonrasi listeyi yenilemek icin cagrilir.
void ArsivDetayGosterDialog(BuildContext context, Arsiv arsiv,
    {VoidCallback? onDegisti}) {
  // Snackbar'i dialog kapandiktan sonra gostermek icin disaridaki context.
  final rootContext = context;
  final durumYazi =
      getStatusColorArsiv(arsiv.durum, arsiv.cevapladi, arsiv.cevapladi2).text;
  final onayli = arsiv.durum == '1';
  final iptalli = arsiv.durum == '0';

  void mesaj(String m, {bool hata = false}) {
    if (!rootContext.mounted) return;
    ScaffoldMessenger.of(rootContext).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: hata ? Colors.red[700] : Colors.green[700],
      ),
    );
  }

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      bool yukleniyor = false;

      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> islemYap(
              Future<bool> Function() islem, String basariMesaji) async {
            setState(() => yukleniyor = true);
            bool ok = false;
            try {
              ok = await islem();
            } catch (e) {
              log('Arsiv islem hatasi: $e');
            }
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            if (ok) {
              onDegisti?.call();
              mesaj(basariMesaji);
            } else {
              mesaj('İşlem başarısız oldu, lütfen tekrar deneyin.', hata: true);
            }
          }

          return AlertDialog(
            insetPadding: EdgeInsets.zero,
            content: SizedBox(
              width: 290,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    right: -40,
                    top: -40,
                    child: InkResponse(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: const CircleAvatar(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.close),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 20),
                      Text(
                        arsiv.musteridanisan["name"]?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(color: Colors.black, height: 10),
                      _Satir('Tarih', formatDateTime(arsiv.tarih_saat)),
                      _Satir('Başlık', _formBaslik(arsiv)),
                      _Satir('Durum', durumYazi),
                      _Satir('İşlem Yapan Personel',
                          arsiv.personel["personel_adi"]?.toString() ?? '-'),
                      const Divider(color: Colors.black, height: 20),
                      const SizedBox(height: 6),
                      if (yukleniyor)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        )
                      else
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Formu Gör (uygulama ici PDF)
                            if (_pdfMi(arsiv))
                              _Buton(
                                metin: 'Formu Gör',
                                arkaPlan: const Color(0xFF0EA5E9),
                                onPressed: () {
                                  Navigator.push(
                                    dialogContext,
                                    PageTransition(
                                      type: PageTransitionType.rightToLeft,
                                      child: FormPdfGoster(
                                        url: _formGosterUrl(arsiv),
                                        baslik: _formBaslik(arsiv),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            // Onayla (yalnizca onayli degilse)
                            if (Yetki.varMi('form.gonder') && !onayli)
                              _Buton(
                                metin: 'Onayla',
                                arkaPlan: const Color(0xFF16A34A),
                                onPressed: () => islemYap(
                                  () => arsivOnayla(arsiv.id),
                                  'Form onaylandı.',
                                ),
                              ),
                            // Formu Tekrar Gonder
                            if (Yetki.varMi('form.gonder'))
                              _Buton(
                                metin: 'Tekrar Gönder',
                                arkaPlan: Colors.purple[800]!,
                                onPressed: () => islemYap(
                                  () => arsivFormGonder(arsiv.id),
                                  'Form tekrar gönderildi.',
                                ),
                              ),
                            // Indir
                            _Buton(
                              metin: 'İndir',
                              arkaPlan: Colors.yellow[600]!,
                              metinRengi: Colors.black,
                              onPressed: () async {
                                final formadi = _formBaslik(arsiv);
                                final ext = path
                                        .extension(arsiv.uzanti)
                                        .isNotEmpty
                                    ? path.extension(arsiv.uzanti)
                                    : '.pdf';
                                // Dosya adindaki gecersiz karakterleri ( : / \
                                // * ? " < > | bosluk ) temizle — aksi halde
                                // dosya sistemi yazamaz (PathAccessException).
                                final hamAd =
                                    '${arsiv.musteridanisan["name"]}_${arsiv.tarih_saat}_$formadi';
                                final temizAd = hamAd
                                    .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
                                    .replaceAll(RegExp(r'\s+'), '_');
                                final fileName = '$temizAd$ext';
                                try {
                                  final filePath = await FileDownloader()
                                      .downloadFile(
                                          _formIndirUrl(arsiv), fileName);
                                  log('File downloaded to: $filePath');
                                } catch (e) {
                                  log('Failed to download file: $e');
                                  mesaj('Dosya indirilemedi.', hata: true);
                                }
                              },
                            ),
                            // Iptal Et (yalnizca iptalli degilse)
                            if (Yetki.varMi('form.gonder') && !iptalli)
                              _Buton(
                                metin: 'İptal Et',
                                arkaPlan: Colors.red[700]!,
                                onPressed: () => islemYap(
                                  () => arsivIptal(arsiv.id),
                                  'Form iptal edildi.',
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _Satir extends StatelessWidget {
  final String etiket;
  final String deger;
  const _Satir(this.etiket, this.deger);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket),
          const Text(' : '),
          Expanded(child: Text(deger)),
        ],
      ),
    );
  }
}

class _Buton extends StatelessWidget {
  final String metin;
  final Color arkaPlan;
  final Color metinRengi;
  final VoidCallback onPressed;
  const _Buton({
    required this.metin,
    required this.arkaPlan,
    required this.onPressed,
    this.metinRengi = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // Sabit genislik: Wrap icinde en fazla iki buton yan yana gelir (290 - 8).
    return SizedBox(
      width: 128,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: arkaPlan,
          foregroundColor: metinRengi,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(128, 40),
        ),
        child: Text(
          metin,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
