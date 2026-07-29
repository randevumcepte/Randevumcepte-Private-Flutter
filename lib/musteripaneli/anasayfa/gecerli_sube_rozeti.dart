import 'package:flutter/material.dart';

/// Kazanılan kupon/ödülün hangi şube(ler)de geçerli olduğunu gösteren satır.
/// Backend response alanları: gecerli_coklu (bool), gecerli_tumu (bool),
/// gecerli_salon_adlari (List<String>).
///
/// - gecerli_coklu=false (marka tek şubeli) → hiçbir şey çizilmez.
/// - gecerli_tumu=true → "Tüm şubelerde geçerli".
/// - aksi halde → "Geçerli şubeler: A, B".
class GecerliSubeRozeti extends StatelessWidget {
  final bool coklu;
  final bool tumu;
  final List<String> adlar;
  final Color? renk;

  const GecerliSubeRozeti({
    Key? key,
    required this.coklu,
    required this.tumu,
    required this.adlar,
    this.renk,
  }) : super(key: key);

  factory GecerliSubeRozeti.fromJson(Map<String, dynamic> o, {Color? renk}) {
    return GecerliSubeRozeti(
      coklu: o['gecerli_coklu'] == true,
      tumu: o['gecerli_tumu'] == true,
      adlar: (o['gecerli_salon_adlari'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      renk: renk,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!coklu) return const SizedBox.shrink();
    final c = renk ?? Theme.of(context).colorScheme.primary;
    final metin = tumu
        ? 'Tüm şubelerde geçerli'
        : (adlar.isEmpty
            ? 'Seçili şubelerde geçerli'
            : 'Geçerli şubeler: ${adlar.join(', ')}');

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storefront_rounded, size: 14, color: c.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              metin,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: c.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
