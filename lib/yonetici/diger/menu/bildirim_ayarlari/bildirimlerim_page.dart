import 'package:flutter/material.dart';
import 'package:randevu_sistem/Backend/backend.dart';

/// Diğer > Bildirimlerim: giriş yapan kişi (her rol) kendi uygulama bildirimlerini tür bazında
/// sesli / sessiz yapar. Sessiz bildirim yine gelir ve zil listesinde görünür; yalnız ses ve
/// titreşim yapmaz. Hangi bildirimin gideceğine işletme sahibi karar verir (Bildirim Ayarları);
/// işletmenin kapattığı türler gri ve kilitli görünür. Uçlar: /api/v1/bildirimlerim/veri + /kaydet.
class BildirimlerimPage extends StatefulWidget {
  final String salonId;
  const BildirimlerimPage({super.key, required this.salonId});

  @override
  State<BildirimlerimPage> createState() => _BildirimlerimPageState();
}

class _BildirimlerimPageState extends State<BildirimlerimPage> {
  static const Color _mor = Color(0xFF5C008E);
  static const Color _mor2 = Color(0xFF7B2FB8);
  static const Color _yesil = Color(0xFF16A34A);
  static const Color _gri = Color(0xFF94A3B8);
  static const Color _zemin = Color(0xFFF7F5FB);

  static const Map<String, IconData> _ikonlar = {
    'event_available': Icons.event_available_rounded,
    'edit_calendar': Icons.edit_calendar_rounded,
    'event_busy': Icons.event_busy_rounded,
    'alarm': Icons.alarm_rounded,
    'people': Icons.people_alt_rounded,
    'chat': Icons.chat_rounded,
    'campaign': Icons.campaign_rounded,
  };

  bool _yukleniyor = true;
  String? _hata;
  List<Map<String, dynamic>> _liste = [];
  final Set<String> _kaydediliyor = {};

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  bool _ok(Map r) => r['ok'] == 1 || r['ok'] == true || r['ok'] == '1';

  void _al(Map r) {
    _liste = (r['kategoriler'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    final r = await bildirimlerimVeri(widget.salonId);
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (_ok(r)) {
        _al(r);
      } else {
        _hata = (r['hata'] ?? 'Bildirimler yüklenemedi.').toString();
      }
    });
  }

  Future<void> _degistir(Map<String, dynamic> k, bool sessiz) async {
    final kod = k['kod'].toString();
    if (_kaydediliyor.contains(kod)) return;
    final eski = k['sessiz'] == true;
    setState(() {
      k['sessiz'] = sessiz;
      _kaydediliyor.add(kod);
    });
    final r = await bildirimlerimKaydet(widget.salonId, kod, sessiz);
    if (!mounted) return;
    setState(() {
      _kaydediliyor.remove(kod);
      if (_ok(r)) {
        _al(r);
      } else {
        k['sessiz'] = eski;
      }
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ok(r) ? const Color(0xFF1E293B) : Colors.red.shade700,
        content: Text(_ok(r)
            ? '"${k['ad']}" ${sessiz ? 'sessize alındı' : 'sesli yapıldı'}'
            : (r['hata'] ?? 'Kaydedilemedi.').toString()),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final aktif = _liste.where((k) => k['kilitli'] != true).toList();
    final kilitli = _liste.where((k) => k['kilitli'] == true).toList();
    return Scaffold(
      backgroundColor: _zemin,
      appBar: AppBar(
        title: const Text('Bildirimlerim',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_mor, _mor2])),
        ),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: _mor))
          : _hata != null
              ? _hataGorunumu()
              : RefreshIndicator(
                  color: _mor,
                  onRefresh: _yukle,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                    children: [
                      _bilgiKarti(),
                      const SizedBox(height: 14),
                      ...aktif.map(_satir),
                      if (kilitli.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text('İşletme kapattığı için gelmeyenler',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B))),
                        ),
                        ...kilitli.map(_satir),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _hataGorunumu() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 46, color: _gri),
            const SizedBox(height: 10),
            Text(_hata!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _mor),
              onPressed: _yukle,
              child: const Text('Tekrar dene'),
            ),
          ]),
        ),
      );

  Widget _bilgiKarti() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9D5FF)),
        ),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, color: _mor2, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bildirimler yine gelir ve zil listesinde görünür; sessize aldıklarınız ses ve titreşim yapmaz. '
              'Hangi bildirimin size gönderileceğine işletme karar verir.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF4C1D95)),
            ),
          ),
        ]),
      );

  Widget _satir(Map<String, dynamic> k) {
    final kilitli = k['kilitli'] == true;
    final sessiz = k['sessiz'] == true;
    final kaydediliyor = _kaydediliyor.contains(k['kod'].toString());
    final renk = kilitli ? _gri : (sessiz ? const Color(0xFF64748B) : _mor2);
    return Opacity(
      opacity: kilitli ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDE9F6)),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(_ikonlar[k['ikon']] ?? Icons.notifications_rounded,
                color: renk, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k['ad'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF1E1B2E))),
              const SizedBox(height: 2),
              Text(
                kilitli ? 'İşletme bu bildirimleri kapattı' : k['aciklama'].toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.3, color: Color(0xFF64748B)),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          kilitli
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.lock_rounded, color: _gri, size: 20),
                )
              : _secici(k, sessiz, kaydediliyor),
        ]),
      ),
    );
  }

  /// Tek dokunuşla Sesli <-> Sessiz değişen hap
  Widget _secici(Map<String, dynamic> k, bool sessiz, bool kaydediliyor) {
    final renk = sessiz ? const Color(0xFF64748B) : _yesil;
    return GestureDetector(
      onTap: kaydediliyor ? null : () => _degistir(k, !sessiz),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: sessiz ? 0.12 : 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(sessiz ? Icons.notifications_off_rounded : Icons.notifications_active_rounded,
              size: 16, color: sessiz ? renk : Colors.white),
          const SizedBox(width: 5),
          Text(sessiz ? 'Sessiz' : 'Sesli',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: sessiz ? renk : Colors.white)),
        ]),
      ),
    );
  }
}
