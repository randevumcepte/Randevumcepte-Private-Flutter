// Musteri RANDEVU gecmisi (geldi/gelmedi/onayli ozet + randevu listesi).
// Web paneldeki "Randevu Gecmisi" popup'inin mobil karsiligi.
// CAGRI gecmisi (ses/not) ile KARISTIRMA — bu RANDEVU gecmisi.

import 'package:flutter/material.dart';
import '../cagri_api.dart';
import '../cagri_models.dart';

/// Musterinin randevu gecmisini bottom sheet ile acar.
Future<void> randevuGecmisiGoster(
  BuildContext context, {
  required String sube,
  required int userId,
  required String ad,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (_) => _RandevuGecmisiSheet(sube: sube, userId: userId, ad: ad),
  );
}

class _RandevuGecmisiSheet extends StatefulWidget {
  final String sube;
  final int userId;
  final String ad;
  const _RandevuGecmisiSheet(
      {required this.sube, required this.userId, required this.ad});
  @override
  State<_RandevuGecmisiSheet> createState() => _RandevuGecmisiSheetState();
}

class _RandevuGecmisiSheetState extends State<_RandevuGecmisiSheet> {
  bool _yukleniyor = true;
  String? _hata;
  MusteriRandevuGecmisi? _veri;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final v =
          await CagriApi.musteriRandevuGecmisi(widget.sube, widget.userId);
      if (mounted) setState(() { _veri = v; _yukleniyor = false; });
    } catch (e) {
      if (mounted) setState(() {
        _hata = e is CagriApiException ? e.message : 'Geçmiş alınamadı.';
        _yukleniyor = false;
      });
    }
  }

  Color _renk(String hex) {
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFF6D28D9);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: _yukleniyor
            ? const Center(child: CircularProgressIndicator())
            : _hata != null
                ? Center(child: Text(_hata!,
                    style: const TextStyle(color: Colors.red)))
                : ListView(
                    controller: controller,
                    children: [
                      Center(
                        child: Container(width: 40, height: 4,
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3))),
                      ),
                      const SizedBox(height: 12),
                      Text('Randevu Geçmişi — ${widget.ad}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(children: [
                        _ozetKutu('Geldi', _veri!.geldi, const Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        _ozetKutu('Gelmedi', _veri!.gelmedi, Colors.red),
                        const SizedBox(width: 8),
                        _ozetKutu('Onaylı', _veri!.onayli, const Color(0xFF2563EB)),
                      ]),
                      const SizedBox(height: 14),
                      if (_veri!.randevular.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('Randevu geçmişi yok.')),
                        )
                      else
                        for (final r in _veri!.randevular) _gecmisKart(r),
                    ],
                  ),
      ),
    );
  }

  Widget _ozetKutu(String l, int n, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: c.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withOpacity(.25))),
          child: Column(children: [
            Text('$n',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: c)),
            Text(l,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700])),
          ]),
        ),
      );

  Widget _gecmisKart(RandevuGecmisKayit r) {
    final c = _renk(r.renk);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: c, width: 4),
              top: const BorderSide(color: Color(0xFFEEEEEE)),
              right: const BorderSide(color: Color(0xFFEEEEEE)),
              bottom: const BorderSide(color: Color(0xFFEEEEEE)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${r.tarih} ${r.saat}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: c.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(r.durumMetin,
                  style: TextStyle(
                      color: c, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          if (r.hizmet.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.hizmet, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ],
          if (r.personel.isNotEmpty)
            Text(r.personel,
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          if (r.not.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.not, style: const TextStyle(fontSize: 12.5)),
          ],
        ],
      ),
    );
  }
}
