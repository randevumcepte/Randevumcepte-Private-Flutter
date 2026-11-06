import 'package:flutter/material.dart';

import 'package:randevu_sistem/Models/paket_hizmetleri.dart';
import 'package:randevu_sistem/Models/paketler.dart';
import 'package:randevu_sistem/yonetici/diger/menu/ayarlar/paketler/birhizmetdaha.dart';

/// Satilan paketin hizmetleri katalogdan hazir gelir; bu satis icin eklenip
/// cikarilabilir. Katalog paketi degismez: liste farkliysa sunucu o satisa ozel kopya acar.
List<PaketHizmetleri> paketSatisHizmetleri(Paket paket) => paket.hizmetler
    .whereType<Map>()
    .map((h) => PaketHizmetleri.fromJson(Map<String, dynamic>.from(h)))
    .toList();

List<String> paketSatisHizmetIdleri(List<PaketHizmetleri> hizmetler) =>
    hizmetler.map((h) => h.hizmet_id).toList();

class PaketSatisHizmetSecimi extends StatelessWidget {
  final List<PaketHizmetleri> hizmetler;
  final dynamic isletmebilgi;
  final ValueChanged<List<PaketHizmetleri>> onChanged;

  const PaketSatisHizmetSecimi({
    Key? key,
    required this.hizmetler,
    required this.isletmebilgi,
    required this.onChanged,
  }) : super(key: key);

  Future<void> _hizmetSec(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final List<PaketHizmetleri>? secilen = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BirHizmetDaha(
          secilihizmetler: hizmetler,
          isletmebilgi: isletmebilgi,
        ),
      ),
    );
    if (secilen != null && secilen.isNotEmpty) onChanged(secilen);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Paket hizmetsiz satilamaz: son hizmet cikarilamaz.
    final cikarilabilir = hizmetler.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bu satıştaki hizmetler',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final h in hizmetler)
              InputChip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: Text(
                    _hizmetAdi(h),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: cikarilabilir
                    ? () => onChanged(
                        hizmetler.where((x) => x.hizmet_id != h.hizmet_id).toList())
                    : null,
              ),
            ActionChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: Icon(Icons.add_rounded, size: 16, color: scheme.primary),
              label: Text(
                'Hizmet Ekle',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              onPressed: () => _hizmetSec(context),
            ),
          ],
        ),
      ],
    );
  }

  String _hizmetAdi(PaketHizmetleri h) {
    final hizmet = h.hizmet;
    return hizmet is Map ? (hizmet['hizmet_adi'] ?? '').toString() : '';
  }
}

/// Seans adedi yerine gosterilen rozet: "Sınırsız · 1 Yıl".
class SinirsizRozet extends StatelessWidget {
  final String metin;
  const SinirsizRozet({Key? key, required this.metin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EEFE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        metin,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5C008E),
        ),
      ),
    );
  }
}
