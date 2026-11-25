import 'package:randevu_sistem/dil/material.dart';

import 'profil_api.dart';
import 'profil_tema.dart';

/// Müsaitlik durumu seçimi.
/// - Personel: Müsait / Molada. Molada = yöneticiye talep (onay gelene kadar durum değişmez); Müsait = onaysız dönüş.
///   İzinli seçilemez (Profil > İzinlerim).
/// - Yönetici (kendisi ya da Ekibim'den bir personel için): Müsait / Molada / İzinli, onaysız uygulanır.
/// Dönüş: değişiklik yapıldıysa true.
Future<bool> durumSec(
  BuildContext context, {
  required String sube,
  required bool yonetici,
  required Map detay,
  int? personelId,
  String? personelAdi,
}) async {
  final secim = await showModalBottomSheet<_Secim>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (c) => _DurumSayfasi(yonetici: yonetici, detay: detay, personelAdi: personelAdi),
  );
  if (secim == null || !context.mounted) return false;
  final govde = <String, dynamic>{'durum': secim.durum, if (personelId != null) 'personel_id': personelId};
  if (secim.dakika != null) govde['dakika'] = secim.dakika;
  if (secim.saat != null) govde['bitis_saat'] = secim.saat;
  if (secim.tarih != null) govde['bitis_tarih'] = secim.tarih;
  final r = await ProfilApi.post('durum', sube, govde);
  if (!context.mounted) return false;
  if (!ProfilApi.ok(r)) {
    ptMesaj(context, (r['hata'] ?? 'Kaydedilemedi.').toString(), hata: true);
    return false;
  }
  ptMesaj(
      context,
      r['talep'] == true
          ? 'Mola talebiniz yöneticinize gönderildi. Onaylanınca durumunuz değişecek.'
          : (secim.durum == 'musait' ? 'Durum: Müsait' : 'Durum güncellendi, takvim kapatıldı.'));
  return true;
}

class _Secim {
  final String durum;
  final int? dakika;
  final String? saat;
  final String? tarih;
  _Secim(this.durum, {this.dakika, this.saat, this.tarih});
}

class _DurumSayfasi extends StatefulWidget {
  final bool yonetici;
  final Map detay;
  final String? personelAdi;
  const _DurumSayfasi({required this.yonetici, required this.detay, this.personelAdi});
  @override
  State<_DurumSayfasi> createState() => _DurumSayfasiState();
}

class _DurumSayfasiState extends State<_DurumSayfasi> {
  String? _acik; // 'molada' | 'izinli' alt seçim açık

  String get _durum => (widget.detay['durum'] ?? 'musait').toString();
  Map? get _bekleyen => widget.detay['bekleyen_mola'] is Map ? widget.detay['bekleyen_mola'] as Map : null;

  String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _saatSec() async {
    final simdi = TimeOfDay.now();
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (simdi.hour + 1) % 24, minute: 0),
      helpText: 'Mola bitiş saati',
      builder: (c, w) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: w!),
    );
    if (t == null || !mounted) return;
    Navigator.pop(context, _Secim('molada', saat: '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'));
  }

  Future<void> _tarihSec() async {
    final bugun = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(bugun.year, bugun.month, bugun.day),
      lastDate: bugun.add(const Duration(days: 60)),
      initialDate: DateTime(bugun.year, bugun.month, bugun.day),
      helpText: 'Hangi tarihe kadar izinli?',
      locale: const Locale('tr', 'TR'),
    );
    if (d == null || !mounted) return;
    Navigator.pop(context, _Secim('izinli', tarih: _ymd(d)));
  }

  Widget _secenek(String kod, String ad, String alt, {VoidCallback? onTap, bool secili = false, bool pasif = false}) => Opacity(
        opacity: pasif ? 0.45 : 1,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Container(width: 14, height: 14, decoration: BoxDecoration(color: PT.durumRenk(kod), shape: BoxShape.circle)),
          title: Text(ad, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: PT.koyu)),
          subtitle: alt.isEmpty ? null : Text(alt, style: const TextStyle(fontSize: 12.5, color: PT.gri)),
          trailing: secili ? const Icon(Icons.check_circle_rounded, color: PT.mor) : (onTap != null ? const Icon(Icons.chevron_right_rounded, color: PT.mor) : null),
          onTap: pasif ? null : onTap,
        ),
      );

  Widget _sureler() => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final dk in const [15, 30, 45, 60])
            ActionChip(
              label: Text('$dk dk'),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: PT.mor),
              backgroundColor: PT.lila,
              side: BorderSide.none,
              onPressed: () => Navigator.pop(context, _Secim('molada', dakika: dk)),
            ),
          ActionChip(
            avatar: const Icon(Icons.schedule_rounded, size: 18, color: PT.mor),
            label: const Text('Saate kadar'),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: PT.mor),
            backgroundColor: PT.lila,
            side: BorderSide.none,
            onPressed: _saatSec,
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final baskasi = widget.personelAdi != null;
    final izinli = _durum == 'izinli';
    final molada = _durum == 'molada';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(baskasi ? '${widget.personelAdi} · durum' : 'Durumum',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PT.koyu)),
          const SizedBox(height: 4),
          Text(
            widget.yonetici
                ? 'Seçtiğiniz durum hemen uygulanır; mola ve izin süresince takvim randevuya kapanır.'
                : 'Mola için yöneticinizin onayı gerekir. Onaylanınca takvim o süre randevuya kapanır.',
            style: const TextStyle(fontSize: 13, height: 1.35, color: PT.gri),
          ),
          if ((widget.detay['metin'] ?? '').toString().isNotEmpty && _durum != 'musait') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: PT.durumRenk(_durum).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Text('Şu an: ${widget.detay['metin']}', style: TextStyle(fontWeight: FontWeight.w700, color: PT.durumKoyu(_durum))),
            ),
          ],
          if (_bekleyen != null && !widget.yonetici) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFFEA580C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Mola talebi (${_bekleyen!['sure']}) onay bekliyor',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFC2410C))),
                ),
                TextButton(onPressed: () => Navigator.pop(context, _Secim('musait')), child: const Text('Geri çek')),
              ]),
            ),
          ],
          const SizedBox(height: 8),
          // Personel izinliyken kendisi değiştiremez
          if (izinli && !widget.yonetici)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('İzin süresi bitince kendiliğinden Müsait olursunuz. Erken dönmek için yöneticinize başvurun.',
                  style: TextStyle(fontSize: 13.5, color: PT.koyu)),
            )
          else ...[
            _secenek('musait', 'Müsait', molada ? 'Moladan dön (onay gerekmez)' : (izinli ? 'İzni bugünden bitir' : ''),
                secili: _durum == 'musait' && _bekleyen == null,
                onTap: _durum == 'musait' && _bekleyen == null ? null : () => Navigator.pop(context, _Secim('musait'))),
            _secenek('molada', 'Molada', widget.yonetici ? 'Süre seçin' : 'Süre seçin, yöneticinize talep gider',
                secili: molada,
                pasif: molada || izinli || (_bekleyen != null && !widget.yonetici),
                onTap: () => setState(() => _acik = _acik == 'molada' ? null : 'molada')),
            if (_acik == 'molada') _sureler(),
            if (widget.yonetici)
              _secenek('izinli', 'İzinli', 'Bitiş tarihini seçin; o güne kadar takvim kapanır',
                  secili: izinli, pasif: izinli, onTap: _tarihSec),
          ],
        ]),
      ),
    );
  }
}
