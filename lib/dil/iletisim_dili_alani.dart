import 'package:flutter/material.dart';

import 'dil.dart';

/// Personel: müşteri kartında iletişim dili (SMS, WhatsApp ve bildirimler bu dilde gider).
/// Dil seçimi bu markada kapalıysa hiç görünmez. Müşteri kendi seçtiyse sunucu personelin seçimini yok sayar.
class IletisimDiliAlani extends StatelessWidget {
  final String? secili;
  final ValueChanged<String> onSec;
  const IletisimDiliAlani({super.key, required this.secili, required this.onSec});

  @override
  Widget build(BuildContext context) {
    if (!Dil.acik) return const SizedBox.shrink();
    final ana = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('İletişim Dili',
                style: TextStyle(fontSize: 12.5, color: Colors.grey[700], fontWeight: FontWeight.w700, letterSpacing: -0.1)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in Dil.diller)
                ChoiceChip(
                  selected: secili == d.kod,
                  onSelected: (_) => onSec(d.kod),
                  showCheckmark: false,
                  selectedColor: ana.withValues(alpha: 0.14),
                  side: BorderSide(color: secili == d.kod ? ana : Colors.grey.withValues(alpha: 0.3)),
                  label: Text('${d.bayrak} ${d.ad}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secili == d.kod ? ana : Colors.grey[800])),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
