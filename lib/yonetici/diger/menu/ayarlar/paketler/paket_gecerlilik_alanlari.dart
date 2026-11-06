import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:randevu_sistem/Models/paketler.dart';

/// Paket formunun tur/sure degerleri (Yeni Paket + Paket Duzenle ortak).
/// Sure ilk gelis tarihinden baslar; bitis sunucuda hesaplanir, saklanmaz.
class PaketGecerlilikDegeri {
  PaketGecerlilikDegeri({Paket? paket})
      : sinirsiz = paket?.sinirsiz ?? false,
        birim = paket?.gecerlilikBirim == 'ay' ? 'ay' : 'yil',
        sayi = TextEditingController(text: paket?.gecerlilikSayi ?? ''),
        limit = TextEditingController(text: paket?.gunlukLimit ?? '');

  bool sinirsiz;
  String birim;
  final TextEditingController sayi;
  final TextEditingController limit;

  /// Sinirsiz secilip sure bos birakilirsa sunucu da 1 yil kabul eder.
  void sinirsizYap(bool deger) {
    sinirsiz = deger;
    if (deger && sayi.text.trim().isEmpty) {
      sayi.text = '1';
      birim = 'yil';
    }
  }

  Map<String, dynamic> formVerisi() => {
        'sinirsiz': sinirsiz ? 1 : 0,
        'gecerlilik_sayi': sayi.text.trim(),
        'gecerlilik_birim': birim,
        'gunluk_limit': limit.text.trim(),
      };

  void dispose() {
    sayi.dispose();
    limit.dispose();
  }
}

class PaketGecerlilikAlanlari extends StatelessWidget {
  final PaketGecerlilikDegeri deger;
  final VoidCallback onChanged;

  const PaketGecerlilikAlanlari({
    Key? key,
    required this.deger,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiket(scheme, 'Paket Türü'),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Seanslı')),
              ButtonSegment(value: true, label: Text('Sınırsız')),
            ],
            selected: {deger.sinirsiz},
            onSelectionChanged: (s) {
              deger.sinirsizYap(s.first);
              onChanged();
            },
          ),
        ),
        const SizedBox(height: 12),
        _etiket(scheme,
            deger.sinirsiz ? 'Geçerlilik Süresi' : 'Geçerlilik Süresi (opsiyonel)'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _sayiAlani(scheme, deger.sayi, 'Süre')),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'ay', label: Text('Ay')),
                ButtonSegment(value: 'yil', label: Text('Yıl')),
              ],
              selected: {deger.birim},
              onSelectionChanged: (s) {
                deger.birim = s.first;
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        _ipucu(scheme, 'Müşterinin ilk geliş tarihinden itibaren başlar.'),
        if (deger.sinirsiz) ...[
          const SizedBox(height: 12),
          _etiket(scheme, 'Günlük Limit (opsiyonel)'),
          const SizedBox(height: 6),
          _sayiAlani(scheme, deger.limit, 'Limitsiz'),
          const SizedBox(height: 4),
          _ipucu(scheme, 'Boş bırakılırsa süre bitene kadar her randevu seansa yazılır.'),
        ],
      ],
    );
  }

  Widget _etiket(ColorScheme scheme, String metin) => Text(
        metin,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.65),
        ),
      );

  Widget _ipucu(ColorScheme scheme, String metin) => Text(
        metin,
        style: TextStyle(
          fontSize: 11,
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
      );

  Widget _sayiAlani(
      ColorScheme scheme, TextEditingController controller, String ipucu) {
    final kenar = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
    );
    return SizedBox(
      height: 44,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: ipucu,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: kenar,
          enabledBorder: kenar,
        ),
      ),
    );
  }
}
