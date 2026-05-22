import 'package:flutter/material.dart';

/// Randevuya "Geldi" butonuna basildiginda, randevu paketli ise hangi
/// seanslarin paketten dusulecegini salon manuel olarak isaretler.
/// Donus: secilen [AdisyonPaketSeanslar.id] listesi (int). null = vazgec.
Future<List<int>?> seansDusumPopupGoster(
  BuildContext context, {
  required String musteriAdi,
  required String tarih,
  required String saat,
  required List<Map<String, dynamic>> seanslar,
}) {
  return showModalBottomSheet<List<int>?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _SeansDusumSheet(
      musteriAdi: musteriAdi,
      tarih: tarih,
      saat: saat,
      seanslar: seanslar,
    ),
  );
}

class _SeansDusumSheet extends StatefulWidget {
  final String musteriAdi;
  final String tarih;
  final String saat;
  final List<Map<String, dynamic>> seanslar;

  const _SeansDusumSheet({
    required this.musteriAdi,
    required this.tarih,
    required this.saat,
    required this.seanslar,
  });

  @override
  State<_SeansDusumSheet> createState() => _SeansDusumSheetState();
}

class _SeansDusumSheetState extends State<_SeansDusumSheet> {
  late final Set<int> _secili;

  @override
  void initState() {
    super.initState();
    // Varsayilan: hepsi secili (eski davranisi koru — kaydet basinca direkt
    // tam dusulur). Salon istemedigini birakir.
    _secili = widget.seanslar
        .map((s) => _parseInt(s['id']))
        .where((id) => id != 0)
        .toSet();
  }

  int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _formatTarih(String raw) {
    if (raw.isEmpty) return '';
    try {
      final parts = raw.split('-');
      if (parts.length == 3) {
        return '${parts[2]}.${parts[1]}.${parts[0]}';
      }
    } catch (_) {}
    return raw;
  }

  String _formatSaat(String raw) {
    if (raw.isEmpty) return '';
    final parts = raw.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.45,
      expand: false,
      builder: (ctx, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              _buildHero(scheme),
              const SizedBox(height: 14),
              _buildToolbar(scheme),
              Expanded(
                child: widget.seanslar.isEmpty
                    ? _buildEmpty(scheme)
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        itemCount: widget.seanslar.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _buildSeansRow(scheme, widget.seanslar[i]),
                      ),
              ),
              _buildBottomActions(scheme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: scheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seans Düşümü',
                  style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.88),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.musteriAdi.isEmpty ? '-' : widget.musteriAdi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: 12,
                      color: scheme.onPrimary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTarih(widget.tarih),
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.88),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: scheme.onPrimary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatSaat(widget.saat),
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.88),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(ColorScheme scheme) {
    final hepsiSecili = widget.seanslar.isNotEmpty &&
        widget.seanslar.every((s) => _secili.contains(_parseInt(s['id'])));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 13, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${_secili.length} / ${widget.seanslar.length} seçili',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_secili.isNotEmpty && widget.seanslar.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _secili.clear()),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Hiçbirini düşme',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          if (!hepsiSecili)
            TextButton(
              onPressed: () => setState(() {
                _secili.clear();
                for (final s in widget.seanslar) {
                  final id = _parseInt(s['id']);
                  if (id != 0) _secili.add(id);
                }
              }),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Tümünü seç',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeansRow(ColorScheme scheme, Map<String, dynamic> s) {
    final id = _parseInt(s['id']);
    final isSelected = _secili.contains(id);
    final hizmetAdi = (s['hizmet_adi'] ?? '').toString();
    final paketAdi = (s['paket_adi'] ?? '').toString();
    final kalan = _parseInt(s['kalan_seans']);
    final toplam = _parseInt(s['toplam_seans']);
    final seansNo = _parseInt(s['seans_no']);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _secili.remove(id);
            } else {
              _secili.add(id);
            }
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.55)
                  : scheme.outline.withValues(alpha: 0.20),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary
                    .withValues(alpha: isSelected ? 0.14 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? scheme.primary
                        : scheme.outline.withValues(alpha: 0.45),
                    width: 1.6,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded,
                        color: scheme.onPrimary, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.18),
                      scheme.tertiary.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.spa_rounded,
                    size: 16, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hizmetAdi.isEmpty ? '-' : hizmetAdi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (paketAdi.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        paketAdi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (seansNo > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Seans #$seansNo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (toplam > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF15803D)
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Kalan $kalan/$toplam',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Bu randevuya bağlı paket seansı yok.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(ColorScheme scheme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(null),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: scheme.outline.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Vazgeç',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () =>
                    Navigator.of(context).pop(_secili.toList()),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: scheme.onPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _secili.isEmpty
                            ? 'Geldi (düşüm yok)'
                            : 'Geldi ve Düş (${_secili.length})',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
