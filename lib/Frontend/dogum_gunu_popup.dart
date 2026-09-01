import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// Bugun dogum gunu olan musteriler icin sirali kutlama popup'i.
/// Web'deki dashboard popup'inin mobil karsiligi: veriler yuklendikten
/// sonra bir kez cagrilir (fire-and-forget). Backend zaten yetkiyi
/// (musteri.liste_gor) dogrular; yetkisi olmayanlara bos liste doner.
Future<void> dogumGunuPopupBaslat(BuildContext context, String salonId) async {
  if (salonId.isEmpty) return;
  final liste = await dogumGunuBugunListesi(salonId);
  // Bugun zaten gonderilen / "Hayir" ile atlanan (gonderildi=true) elenir.
  final sirada = liste.where((m) => m['gonderildi'] != true).toList();
  if (sirada.isEmpty) return;

  for (final m in sirada) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DogumGunuDialog(
        salonId: salonId,
        musteriId: (m['id'] ?? '').toString(),
        ad: (m['name'] ?? 'Müşteri').toString(),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 250));
  }
}

class _DogumGunuDialog extends StatefulWidget {
  final String salonId;
  final String musteriId;
  final String ad;
  const _DogumGunuDialog({
    required this.salonId,
    required this.musteriId,
    required this.ad,
  });

  @override
  State<_DogumGunuDialog> createState() => _DogumGunuDialogState();
}

class _DogumGunuDialogState extends State<_DogumGunuDialog> {
  bool _gonderiliyor = false;
  String? _sonuc;
  bool _sonucOk = false;

  Future<void> _gonder() async {
    setState(() => _gonderiliyor = true);
    final out =
        await dogumGunuMesajGonderMobil(widget.salonId, widget.musteriId);
    if (!mounted) return;
    setState(() {
      _gonderiliyor = false;
      _sonucOk = out['ok'] == true;
      _sonuc = (out['mesaj'] ??
              (_sonucOk ? 'Gönderildi.' : 'Hata oluştu.'))
          .toString();
    });
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) Navigator.of(context).pop();
  }

  void _hayir() {
    // Sunucuya kalici "atlandi" isareti — diger cihazlarda da cikmasin.
    dogumGunuAtlaMobil(widget.salonId, widget.musteriId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎂', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            const Text('Bugün',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888))),
            const SizedBox(height: 4),
            Text(
              widget.ad,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE63B6E),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Müşterinize doğum günü mesajı göndermek ister misiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF444444)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Önce WhatsApp denenecek, başarısız olursa SMS gönderilecek.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 18),
            _altKisim(),
          ],
        ),
      ),
    );
  }

  Widget _altKisim() {
    if (_sonuc != null) {
      final bg = _sonucOk ? const Color(0xFFE8F8EE) : const Color(0xFFFDE8EC);
      final fg = _sonucOk ? const Color(0xFF1A7F47) : const Color(0xFFA01035);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          (_sonucOk ? '✅ ' : '⚠️ ') + _sonuc!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: fg),
        ),
      );
    }

    if (_gonderiliyor) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Gönderiliyor…', style: TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _gonder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1FBF6F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('✉️  Evet, Gönder',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _hayir,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hayır',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
