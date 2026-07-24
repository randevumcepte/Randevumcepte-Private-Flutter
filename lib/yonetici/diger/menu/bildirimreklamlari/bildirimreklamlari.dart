import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'bildirimreklamlari_form.dart';

/// Salon yöneticisi tarafında Bildirim Reklamları yönetim ekranı.
/// Web paneli (bildirim-reklamlari) ile AYNI backend — eş zamanlı.
class BildirimReklamlariPage extends StatefulWidget {
  final dynamic isletmebilgi;
  const BildirimReklamlariPage({Key? key, this.isletmebilgi}) : super(key: key);

  @override
  State<BildirimReklamlariPage> createState() => _BildirimReklamlariPageState();
}

class _BildirimReklamlariPageState extends State<BildirimReklamlariPage> {
  static const _mor = Color(0xFF7C3AED);
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _reklamlar = [];

  String get _salonId => '${widget.isletmebilgi?['id'] ?? ''}';

  final Map<String, List<dynamic>> _tur = {
    'kampanya': ['Kampanya / İndirim', Icons.local_offer, Color(0xFF7C3AED)],
    'bos_slot': ['Boş Slot', Icons.access_time_filled, Color(0xFF0EA5E9)],
    'yeni_hizmet': ['Yeni Hizmet', Icons.star, Color(0xFFF59E0B)],
    'geri_kazanim': ['Yeniden Kazanım', Icons.favorite, Color(0xFFEF4444)],
    'ozel_gun': ['Özel Gün', Icons.card_giftcard, Color(0xFFEC4899)],
    'sadakat': ['Sadakat / Puan', Icons.diamond, Color(0xFF10B981)],
    'etkinlik': ['Etkinlik / Duyuru', Icons.campaign, Color(0xFF6366F1)],
  };

  final Map<String, List<dynamic>> _durumEt = {
    'taslak': ['Taslak', Color(0xFF64748B)],
    'aktif': ['Aktif', Color(0xFF16A34A)],
    'pasif': ['Pasif', Color(0xFF94A3B8)],
    'bitti': ['Bitti', Color(0xFFDC2626)],
  };

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final res = await reklamAdminListe(_salonId);
      if (!mounted) return;
      setState(() {
        _reklamlar = ((res['data'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _yukleniyor = false;
      });
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _formAc([Map<String, dynamic>? r]) async {
    final sonuc = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BildirimReklamiForm(isletmebilgi: widget.isletmebilgi, reklam: r),
      ),
    );
    if (sonuc == true) _yukle();
  }

  Future<void> _durumDegistir(Map r, String yeni) async {
    try {
      await reklamAdminDurum(_salonId, r['id'], yeni);
      _yukle();
    } catch (_) {}
  }

  Future<void> _sil(Map r) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reklamı Sil'),
        content: Text('"${r['baslik']}" reklamı silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (onay == true) {
      try {
        await reklamAdminSil(_salonId, r['id']);
        _yukle();
      } catch (_) {}
    }
  }

  Future<void> _pushGonder(Map r) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Push Gönder'),
        content: Text('"${r['baslik']}" hedef kitleye anlık bildirim olarak gönderilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Gönder')),
        ],
      ),
    );
    if (onay != true) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final res = await reklamAdminGonder(_salonId, r['id']);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Gönderildi')),
      );
      _yukle();
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gönderilemedi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FB),
      appBar: AppBar(
        backgroundColor: _mor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Bildirim Reklamları', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _mor,
        onPressed: () => _formAc(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Reklam'),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: _mor))
          : RefreshIndicator(
              color: _mor,
              onRefresh: _yukle,
              child: _reklamlar.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      const Icon(Icons.campaign_outlined, size: 64, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      const Center(child: Text('Henüz reklam yok', style: TextStyle(color: Color(0xFF64748B), fontSize: 15))),
                      const SizedBox(height: 8),
                      Center(child: TextButton(onPressed: () => _formAc(), child: const Text('İlk reklamı oluştur'))),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                      itemCount: _reklamlar.length,
                      itemBuilder: (_, i) => _kart(_reklamlar[i]),
                    ),
            ),
    );
  }

  Widget _kart(Map<String, dynamic> r) {
    final t = _tur[r['tur']] ?? ['Reklam', Icons.campaign, _mor];
    final d = _durumEt[r['durum']] ?? ['—', const Color(0xFF64748B)];
    final gorsel = r['gorsel_url']?.toString();
    final kuponDeger = r['kupon_deger'];
    String? rozet;
    if (kuponDeger != null && kuponDeger is num && kuponDeger > 0) {
      rozet = (r['kupon_indirim_tipi'] == 'tutar')
          ? '${kuponDeger % 1 == 0 ? kuponDeger.toInt() : kuponDeger} ₺'
          : '%${kuponDeger.toInt()}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // görsel / başlık alanı
          Stack(
            children: [
              if (gorsel != null && gorsel.isNotEmpty)
                Image.network(gorsel, height: 120, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(height: 120, color: (t[2] as Color).withValues(alpha: 0.1)))
              else
                Container(
                  height: 90,
                  color: (t[2] as Color).withValues(alpha: 0.10),
                  child: Icon(t[1] as IconData, color: t[2] as Color, size: 34),
                ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: d[1] as Color, borderRadius: BorderRadius.circular(20)),
                  child: Text(d[0] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
              if (rozet != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Text(rozet, style: TextStyle(color: _mor, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: (t[2] as Color).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(t[0] as String, style: TextStyle(color: t[2] as Color, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Text(r['baslik']?.toString() ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                if ((r['mesaj']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(r['mesaj'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 4, children: [
                  if (r['kanal_push'] == true) _mini(Icons.notifications, 'Push'),
                  if (r['kanal_inapp'] == true) _mini(Icons.smartphone, 'Uygulama içi'),
                  if (r['tam_ekran'] == true) _mini(Icons.fullscreen, 'Tam ekran'),
                ]),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              _islem(Icons.edit, 'Düzenle', () => _formAc(r)),
              if (r['kanal_push'] == true) _islem(Icons.send, 'Gönder', () => _pushGonder(r)),
              r['durum'] == 'aktif'
                  ? _islem(Icons.pause, 'Duraklat', () => _durumDegistir(r, 'pasif'))
                  : _islem(Icons.play_arrow, 'Yayınla', () => _durumDegistir(r, 'aktif')),
              _islem(Icons.delete_outline, 'Sil', () => _sil(r), renk: const Color(0xFFDC2626)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(IconData ic, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 14, color: _mor),
        const SizedBox(width: 3),
        Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
      ]);

  Widget _islem(IconData ic, String t, VoidCallback onTap, {Color renk = const Color(0xFF64748B)}) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(children: [
              Icon(ic, size: 19, color: renk),
              const SizedBox(height: 2),
              Text(t, style: TextStyle(fontSize: 11, color: renk)),
            ]),
          ),
        ),
      );
}
