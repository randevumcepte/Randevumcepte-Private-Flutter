// Santral konusma dakikasi karti (giden dis hat dakikasi — web Santral sayfasi ile ayni hesap).
// Backend: POST /api/v1/cagri-merkezi/dakika-ozet
//  - Yonetici (rol < 5): tanimli / kullanilan / kalan + doluluk cubugu.
//  - Personel (rol 5): yalniz kendi dahilisinin giden dakikasi; havuz bittiyse uyari.
//  - Salonda santral hatti da tanimli dakika da yoksa hic yer kaplamaz.
// [kompakt]: Cagri Merkezi sekmelerinin ustunde tek satirlik serit.
import 'package:randevu_sistem/dil/material.dart';
import 'package:randevu_sistem/theme/app_tokens.dart';

import '../cagri_api.dart';

class SantralDakikaKarti extends StatefulWidget {
  final String sube;
  final bool kompakt;
  final EdgeInsetsGeometry padding;

  const SantralDakikaKarti({
    super.key,
    required this.sube,
    this.kompakt = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<SantralDakikaKarti> createState() => _SantralDakikaKartiState();
}

class _SantralDakikaKartiState extends State<SantralDakikaKarti> {
  Map<String, dynamic>? _d;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void didUpdateWidget(covariant SantralDakikaKarti old) {
    super.didUpdateWidget(old);
    if (old.sube != widget.sube) _yukle();
  }

  Future<void> _yukle() async {
    final d = await CagriApi.dakikaOzet(widget.sube);
    if (mounted) setState(() => _d = d);
  }

  static double _sayi(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;

  static String _dk(double v, {int ondalik = 1}) {
    final s = v.toStringAsFixed(ondalik).replaceAll('.', ',');
    return ondalik > 0 && s.endsWith(',0') ? s.substring(0, s.length - 2) : s;
  }

  static String _tarih(dynamic v) {
    final s = '${v ?? ''}';
    final p = s.split('-');
    return p.length == 3 ? '${p[2]}.${p[1]}.${p[0]}' : s;
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    if (d == null || d['goster'] != true) return const SizedBox.shrink();
    return Padding(
      padding: widget.padding,
      child: widget.kompakt ? _kompakt(context, d) : _kart(context, d),
    );
  }

  Color _durumRengi(BuildContext context, Map<String, dynamic> d) {
    final ext = context.appTheme;
    if (d['bitti'] == true) return Theme.of(context).colorScheme.error;
    if (d['personel'] == true) return Theme.of(context).colorScheme.primary;
    final yuzde = _sayi(d['yuzde']);
    if (_sayi(d['tanimli']) > 0 && yuzde >= 85) return ext.warningColor;
    return ext.successColor;
  }

  Widget _kompakt(BuildContext context, Map<String, dynamic> d) {
    final renk = _durumRengi(context, d);
    final personel = d['personel'] == true;
    final tanimli = _sayi(d['tanimli']);
    final String metin;
    if (d['bitti'] == true) {
      metin = 'Santral dakikası bitti — santral üzerinden arama yapılamaz';
    } else if (personel) {
      metin = 'Giden konuşmam: ${_dk(_sayi(d['kullanilan']))} dk · ${d['adet'] ?? 0} çağrı';
    } else if (tanimli > 0) {
      metin = 'Kalan santral dakikası: ${_dk(_sayi(d['kalan']))} / ${_dk(tanimli, ondalik: 0)} dk';
    } else {
      metin = 'Kullanılan santral dakikası: ${_dk(_sayi(d['kullanilan']))} dk';
    }
    return InkWell(
      onTap: () => _detay(context, d),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: renk.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(d['bitti'] == true ? Icons.warning_amber_rounded : Icons.timer_outlined,
              size: 18, color: renk),
          const SizedBox(width: 8),
          Expanded(
            child: Text(metin,
                maxLines: 2,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: renk)),
          ),
          if (!personel && tanimli > 0) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_sayi(d['yuzde']) / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  color: renk,
                  backgroundColor: renk.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _kart(BuildContext context, Map<String, dynamic> d) {
    final scheme = Theme.of(context).colorScheme;
    final renk = _durumRengi(context, d);
    final personel = d['personel'] == true;
    final tanimli = _sayi(d['tanimli']);

    Widget sutun(String etiket, String deger, Color c) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(deger,
                style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800, color: c, letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(etiket,
                style: TextStyle(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.55))),
          ]),
        );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _detay(context, d),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: renk.withValues(alpha: 0.22)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: renk.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(Icons.timer_outlined, size: 16, color: renk),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(personel ? 'Giden konuşma sürem' : 'Santral Konuşma Dakikası',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              if (d['bitti'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99)),
                  child: Text('Bitti',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: scheme.error)),
                ),
            ]),
            const SizedBox(height: 12),
            if (personel)
              Row(children: [
                sutun('dk konuşma', _dk(_sayi(d['kullanilan'])), renk),
                sutun('giden çağrı', '${d['adet'] ?? 0}', scheme.onSurface),
              ])
            else
              Row(children: [
                sutun('Tanımlı (dk)', tanimli > 0 ? _dk(tanimli, ondalik: 0) : '—', scheme.onSurface),
                sutun('Kullanılan (dk)', _dk(_sayi(d['kullanilan'])), scheme.onSurface),
                sutun('Kalan (dk)', tanimli > 0 ? _dk(_sayi(d['kalan'])) : '—', renk),
              ]),
            if (!personel && tanimli > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_sayi(d['yuzde']) / 100).clamp(0.0, 1.0),
                  minHeight: 7,
                  color: renk,
                  backgroundColor: renk.withValues(alpha: 0.13),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              d['bitti'] == true
                  ? 'Dakika bittiği için uygulamadan santral araması yapılamaz. Dakika yüklemesi için RandevumCepte ile iletişime geçin.'
                  : (!personel && tanimli <= 0)
                      ? 'Bu işletme için henüz tanımlı dakika girilmemiş.'
                      : '${_tarih(d['sayim_baslangic'])} tarihinden bugüne · ${d['adet'] ?? 0} giden çağrı',
              style: TextStyle(
                  fontSize: 11.5,
                  color: d['bitti'] == true ? scheme.error : scheme.onSurface.withValues(alpha: 0.55)),
            ),
            if (d['hata'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Santral kayıtlarına şu an ulaşılamadı; rakamlar eksik olabilir.',
                    style: TextStyle(fontSize: 11, color: context.appTheme.warningColor)),
              ),
          ]),
        ),
      ),
    );
  }

  void _detay(BuildContext context, Map<String, dynamic> d) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _kart(ctx, d),
            const SizedBox(height: 10),
            Text(
              'Uygulama içi softphone ve Bria aramaları santral dakikasından düşer. '
              'Dahilisi olmayan kullanıcının telefonun kendi uygulamasıyla yaptığı arama santral dakikası harcamaz. '
              'Rakamlar santral kayıtlarından yaklaşık 5 dakikada bir güncellenir.',
              style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6), height: 1.4),
            ),
          ]),
        ),
      ),
    );
  }
}
