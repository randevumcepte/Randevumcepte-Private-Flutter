import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Çoklu şube seçici — çark / sadakat ödülü / bildirim reklamı kaydederken
/// "tümü veya belirli şubeler" seçimi için ortak bileşen.
///
/// Şube listesi login'de SharedPreferences('user')'a yazılan
/// `yetkili_olunan_isletmeler`'den okunur (her eleman: salon_id + salonlar.salon_adi).
/// Tek şubeli işletmede (liste ≤ 1) hiçbir şey çizilmez — seçim gizli kalır.
///
/// Seçim değiştikçe [onChanged] ile seçili salon_id listesi bildirilir.
/// İlk yüklemede [aktifSalonId] seçili başlar.
class SubeCokluSecici extends StatefulWidget {
  final String aktifSalonId;
  final ValueChanged<List<String>> onChanged;
  final String baslik;

  const SubeCokluSecici({
    Key? key,
    required this.aktifSalonId,
    required this.onChanged,
    this.baslik = 'Uygulanacak şubeler',
  }) : super(key: key);

  @override
  State<SubeCokluSecici> createState() => _SubeCokluSeciciState();
}

class _SubeCokluSeciciState extends State<SubeCokluSecici> {
  final List<Map<String, String>> _subeler = []; // {id, ad}
  final Set<String> _secili = {};
  bool _yuklendi = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final ls = await SharedPreferences.getInstance();
      final raw = ls.getString('user');
      if (raw != null) {
        final u = jsonDecode(raw);
        final list = (u['yetkili_olunan_isletmeler'] as List?) ?? const [];
        final seen = <String>{};
        for (final e in list) {
          final id = (e is Map ? e['salon_id'] : null)?.toString() ?? '';
          if (id.isEmpty || seen.contains(id)) continue;
          seen.add(id);
          final ad = (e['salonlar'] is Map
                  ? (e['salonlar']['salon_adi'] ?? 'Şube')
                  : 'Şube')
              .toString();
          _subeler.add({'id': id, 'ad': ad});
        }
      }
    } catch (_) {}

    // Varsayılan: aktif (bulunulan) şube seçili.
    if (widget.aktifSalonId.isNotEmpty) _secili.add(widget.aktifSalonId);
    if (_secili.isEmpty && _subeler.isNotEmpty) _secili.add(_subeler.first['id']!);
    _yuklendi = true;
    if (mounted) setState(() {});
    widget.onChanged(_secili.toList());
  }

  void _bildir() => widget.onChanged(_secili.toList());

  bool get _hepsiSecili => _subeler.isNotEmpty && _secili.length == _subeler.length;

  void _tumunuToggle() {
    setState(() {
      if (_hepsiSecili) {
        // En az bir şube kalmalı — aktif olanı bırak.
        _secili
          ..clear()
          ..add(widget.aktifSalonId.isNotEmpty
              ? widget.aktifSalonId
              : _subeler.first['id']!);
      } else {
        _secili
          ..clear()
          ..addAll(_subeler.map((s) => s['id']!));
      }
    });
    _bildir();
  }

  void _toggle(String id) {
    setState(() {
      if (_secili.contains(id)) {
        if (_secili.length > 1) _secili.remove(id); // en az bir seçili kalmalı
      } else {
        _secili.add(id);
      }
    });
    _bildir();
  }

  @override
  Widget build(BuildContext context) {
    // Tek şube veya henüz yüklenmedi → gizli.
    if (!_yuklendi || _subeler.length <= 1) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.baslik,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Text(
                '${_secili.length}/${_subeler.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              FilterChip(
                label: const Text('Tümü'),
                selected: _hepsiSecili,
                onSelected: (_) => _tumunuToggle(),
                showCheckmark: true,
              ),
              ..._subeler.map((s) {
                final id = s['id']!;
                return FilterChip(
                  label: Text(s['ad'] ?? 'Şube'),
                  selected: _secili.contains(id),
                  onSelected: (_) => _toggle(id),
                  showCheckmark: true,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
