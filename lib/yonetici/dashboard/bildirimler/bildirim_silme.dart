import 'package:randevu_sistem/dil/material.dart';
import 'package:randevu_sistem/yonetici/profil/profil_api.dart';

import 'bildirimler_class.dart';

const _kirmizi = Color(0xFFEF4444);

/// Bildirimler ekranında silme (müşteri ve personel ortak): kartı sola kaydır / çöp simgesi tek siler,
/// "Sil" düğmesi okunmuşları ya da tümünü. Silinenler [silinen] ile listeden hemen düşer.
mixin BildirimSilme<T extends StatefulWidget> on State<T> {
  /// Müşteri: '/musteri-profil/bildirim-sil', personel: '/bildirimlerim/sil'
  String get silYolu;
  String get silSube;
  void silindi();

  final Set<String> silinen = {};
  bool _siliniyor = false;

  List<SistemBildirimleri> kalanlar(List<SistemBildirimleri> l) =>
      silinen.isEmpty ? l : l.where((b) => !silinen.contains(b.id)).toList();

  Future<void> _sil(Set<String> idler, Map<String, dynamic> govde) async {
    setState(() => silinen.addAll(idler));
    final r = await ProfilApi.post(silYolu, silSube, govde);
    if (!mounted) return;
    if (ProfilApi.ok(r)) {
      silindi();
      return;
    }
    setState(() => silinen.removeAll(idler));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _kirmizi,
      behavior: SnackBarBehavior.floating,
      content: Text((r['hata'] ?? r['message'] ?? 'Bildirim silinemedi.').toString(),
          style: const TextStyle(color: Colors.white)),
    ));
  }

  Future<void> bildirimSil(SistemBildirimleri b) => _sil({b.id}, {
        'kapsam': 'secili',
        'idler': [b.id]
      });

  Future<void> bildirimSilSor(SistemBildirimleri b) async {
    if (await _onay('Bildirim silinsin mi?', 'Bu bildirim listenizden kaldırılacak.')) bildirimSil(b);
  }

  Future<void> topluSil(List<SistemBildirimleri> hepsi) async {
    if (_siliniyor || hepsi.isEmpty) return;
    final okunmus = hepsi.where((b) => b.okundu == '1').toList();
    final yeni = hepsi.length - okunmus.length;
    final kapsam = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Bildirimleri Sil', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _secenek(ctx, 'okunmus', Icons.mark_email_read_outlined, 'Okunmuşları sil',
                okunmus.isEmpty ? 'Okunmuş bildiriminiz yok' : '${okunmus.length} bildirim silinir, yeniler kalır',
                aktif: okunmus.isNotEmpty),
            _secenek(ctx, 'tumu', Icons.delete_sweep_outlined, 'Tümünü sil',
                yeni > 0 ? '${hepsi.length} bildirim silinir, $yeni tanesi okunmamış' : '${hepsi.length} bildirim silinir',
                renk: _kirmizi),
            _secenek(ctx, null, Icons.close_rounded, 'Vazgeç', null),
          ]),
        ),
      ),
    );
    if (kapsam == null || !mounted) return;
    if (kapsam == 'tumu' &&
        !await _onay('Tüm bildirimler silinsin mi?', '${hepsi.length} bildirim silinecek. Bu işlem geri alınamaz.')) {
      return;
    }
    if (!mounted) return;
    final son = hepsi.map((b) => int.tryParse(b.id) ?? 0).fold<int>(0, (a, b) => a > b ? a : b);
    _siliniyor = true;
    await _sil((kapsam == 'tumu' ? hepsi : okunmus).map((b) => b.id).toSet(), {'kapsam': kapsam, 'son_id': son});
    _siliniyor = false;
  }

  Widget _secenek(BuildContext ctx, String? deger, IconData ikon, String yazi, String? alt,
      {bool aktif = true, Color renk = const Color(0xFF1A1A1A)}) {
    return ListTile(
      enabled: aktif,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(ikon, color: aktif ? renk : null),
      title: Text(yazi, style: TextStyle(fontWeight: FontWeight.w700, color: aktif ? renk : null)),
      subtitle: alt == null ? null : Text(alt),
      onTap: () => Navigator.pop(ctx, deger),
    );
  }

  Future<bool> _onay(String baslik, String metin) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(baslik, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          content: Text(metin),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kirmizi, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sil'),
            ),
          ],
        ),
      ) ??
      false;

  /// Sola kaydırınca silinen kart sarmalayıcısı
  Widget kaydirSil(SistemBildirimleri b, Widget kart) => Dismissible(
        key: ValueKey('bildirim_${b.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => bildirimSil(b),
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(right: 22),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(color: _kirmizi, borderRadius: BorderRadius.circular(16)),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            Text('Sil', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
        child: kart,
      );

  /// Karttaki çöp simgesi
  Widget copDugme(SistemBildirimleri b) => IconButton(
        tooltip: 'Sil',
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
        padding: EdgeInsets.zero,
        icon: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.black.withValues(alpha: 0.40)),
        onPressed: () => bildirimSilSor(b),
      );

  /// Filtre satırının sağındaki toplu silme düğmesi
  Widget topluSilDugme(List<SistemBildirimleri> hepsi) => Material(
        color: Colors.white.withValues(alpha: 0.85),
        shape: StadiumBorder(side: BorderSide(color: _kirmizi.withValues(alpha: 0.30))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => topluSil(hepsi),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.delete_outline_rounded, size: 15, color: _kirmizi),
              SizedBox(width: 4),
              Text('Sil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kirmizi)),
            ]),
          ),
        ),
      );
}
