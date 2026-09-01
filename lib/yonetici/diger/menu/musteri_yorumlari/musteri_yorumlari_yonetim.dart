import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// Isletme sahibi/yoneticileri icin musteri yorumlari moderasyon ekrani.
/// Apple 1.2 UGC uyumu: bildirilen yorumlar en uste alinir, sil butonu ile
/// isletme sahibi 24 saat icinde uygunsuz iceriği kaldirabilir.
class MusteriYorumlariYonetim extends StatefulWidget {
  final String salonId;
  const MusteriYorumlariYonetim({super.key, required this.salonId});

  @override
  State<MusteriYorumlariYonetim> createState() => _MusteriYorumlariYonetimState();
}

class _MusteriYorumlariYonetimState extends State<MusteriYorumlariYonetim> {
  bool _loading = true;
  List<Map<String, dynamic>> _yorumlar = [];
  int _bildirilenSayi = 0;
  bool _sadeceBildirilen = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _loading = true);
    final r = await musteriYorumlariAdmin(widget.salonId);
    if (!mounted) return;
    setState(() {
      if (r != null && r['success'] == true) {
        _yorumlar = ((r['yorumlar'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _bildirilenSayi = (r['bildirilen_sayi'] as num?)?.toInt() ?? 0;
      } else {
        _yorumlar = [];
      }
      _loading = false;
    });
  }

  Future<void> _sil(Map<String, dynamic> yorum) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yorumu Sil'),
        content: Text(
          'Bu yorumu kalıcı olarak silmek istediğinize emin misiniz?\n\n'
          '"${yorum['yorum'] ?? ''}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (onay != true) return;

    final ok = await musteriYorumSil((yorum['id'] as num).toInt());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Yorum silindi' : 'Silme başarısız'),
        backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFDC2626),
      ),
    );
    if (ok) _yukle();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gosterilen = _sadeceBildirilen
        ? _yorumlar.where((y) => ((y['bildirilen_sayisi'] as num?) ?? 0) > 0).toList()
        : _yorumlar;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        title: const Text('Müşteri Yorumları', style: TextStyle(color: Colors.white)),
        backgroundColor: scheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _yukle,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre + rozet
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Row(
              children: [
                if (_bildirilenSayi > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.report_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Text(
                          '$_bildirilenSayi bildirilen',
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  '${gosterilen.length} yorum',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Text('Sadece bildirilen', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _sadeceBildirilen,
                      onChanged: (v) => setState(() => _sadeceBildirilen = v),
                      activeColor: const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : gosterilen.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rate_review_outlined,
                                size: 56, color: scheme.onSurface.withValues(alpha: 0.25)),
                            const SizedBox(height: 10),
                            Text(
                              _sadeceBildirilen
                                  ? 'Bildirilen yorum yok'
                                  : 'Henüz yorum yok',
                              style: TextStyle(fontSize: 14, color: scheme.onSurface.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _yukle,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: gosterilen.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _yorumKart(gosterilen[i], scheme),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _yorumKart(Map<String, dynamic> y, ColorScheme scheme) {
    final bildirilenSayi = (y['bildirilen_sayisi'] as num?)?.toInt() ?? 0;
    final sebep = (y['bildirim_sebep'] ?? '').toString();
    final ad = (y['kullanici_adi'] ?? 'Müşteri').toString();
    final yorum = (y['yorum'] ?? '').toString();
    final puan = (y['puan'] as num?)?.toInt() ?? 0;
    final tarih = (y['tarih'] ?? '').toString();
    final harf = ad.isNotEmpty ? ad.substring(0, 1).toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: bildirilenSayi > 0
            ? Border.all(color: const Color(0xFFDC2626), width: 2)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bildirilenSayi > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.report_rounded, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$bildirilenSayi kez bildirildi${sebep.isNotEmpty ? ' — Son sebep: $sebep' : ''}',
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [scheme.primary, Color.lerp(scheme.primary, scheme.tertiary, 0.5)!],
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(harf, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (tarih.isNotEmpty)
                      Text(tarih.substring(0, tarih.length >= 16 ? 16 : tarih.length),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              if (puan > 0)
                Row(
                  children: List.generate(
                    puan,
                    (_) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB400)),
                  ),
                ),
            ],
          ),
          if (yorum.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              yorum,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: scheme.onSurface.withValues(alpha: 0.85)),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _sil(y),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Sil'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
