import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/yonetici/dashboard/bildirimler/bildirimler.dart';
import 'package:randevu_sistem/yonetici/profil/profil_tema.dart';

/// Bildirimlerim: giriş yapan kişi (her rol) kendi uygulama bildirimlerini tür bazında
/// sesli / sessiz yapar (anahtar açık = sesli, kapalı = sessiz). Sessiz bildirim yine gelir ve zil
/// listesinde görünür; yalnız ses ve titreşim yapmaz. Hangi bildirimin gideceğine işletme karar verir;
/// işletmenin kapattığı türler kilitli görünür. Uçlar: /api/v1/bildirimlerim/veri + /kaydet.
class BildirimlerimPage extends StatefulWidget {
  final String salonId;
  /// Verilirse sağ üstte zil (bildirim listesi) düğmesi görünür.
  final dynamic isletmebilgi;
  final int? kullanicirolu;
  const BildirimlerimPage({super.key, required this.salonId, this.isletmebilgi, this.kullanicirolu});

  @override
  State<BildirimlerimPage> createState() => _BildirimlerimPageState();
}

class _BildirimlerimPageState extends State<BildirimlerimPage> {
  static const Map<String, IconData> _ikonlar = {
    'event_available': Icons.event_available_rounded,
    'edit_calendar': Icons.edit_calendar_rounded,
    'event_busy': Icons.event_busy_rounded,
    'alarm': Icons.alarm_rounded,
    'people': Icons.groups_rounded,
    'chat': Icons.sms_rounded,
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
    _liste = (r['kategoriler'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<Map<String, dynamic>> get _acilabilir => _liste.where((k) => k['kilitli'] != true).toList();
  bool get _hepsiSesli => _acilabilir.isNotEmpty && _acilabilir.every((k) => k['sessiz'] != true);

  Future<void> _yukle() async {
    final r = await bildirimlerimVeri(widget.salonId);
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (_ok(r)) {
        _al(r);
        _hata = null;
      } else {
        _hata = (r['hata'] ?? 'Bildirimler yüklenemedi.').toString();
      }
    });
  }

  /// kod = kategori kodu ya da 'tumu'
  Future<void> _degistir(String kod, bool sesli, String ad) async {
    if (_kaydediliyor.contains(kod)) return;
    final yedek = _liste.map((e) => Map<String, dynamic>.from(e)).toList();
    setState(() {
      _kaydediliyor.add(kod);
      for (final k in _liste) {
        if (k['kilitli'] == true) continue;
        if (kod == 'tumu' || k['kod'] == kod) k['sessiz'] = !sesli;
      }
    });
    final r = await bildirimlerimKaydet(widget.salonId, kod, !sesli);
    if (!mounted) return;
    setState(() {
      _kaydediliyor.remove(kod);
      if (_ok(r)) {
        _al(r);
      } else {
        _liste = yedek;
      }
    });
    ptMesaj(
        context,
        _ok(r)
            ? (kod == 'tumu'
                ? (sesli ? 'Tüm bildirimler sesli yapıldı' : 'Tüm bildirimler sessize alındı')
                : '"$ad" ${sesli ? 'sesli yapıldı' : 'sessize alındı'}')
            : (r['hata'] ?? 'Kaydedilemedi.').toString(),
        hata: !_ok(r));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: PT.zemin,
        body: Stack(children: [
          const PTZemin(),
          SafeArea(
            child: _yukleniyor
                ? Column(children: [_ustBar(), const Expanded(child: Center(child: CircularProgressIndicator(color: PT.mor)))])
                : RefreshIndicator(
                    color: PT.mor,
                    onRefresh: _yukle,
                    child: ListView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                      children: [
                        _ustBar(),
                        _hero(),
                        const SizedBox(height: 10),
                        if (_hata != null)
                          PTBos(Icons.cloud_off_rounded, _hata!)
                        else ...[
                          _tumu(),
                          const SizedBox(height: 16),
                          _bolumBaslik('BİLDİRİM TERCİHLERİ'),
                          const SizedBox(height: 10),
                          ..._liste.map(_satir),
                          const SizedBox(height: 8),
                          _bilgi(),
                        ],
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _ustBar() => Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 4),
        child: Row(children: [
          PTDaireDugme(ikon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
          const Spacer(),
          if (widget.isletmebilgi != null && widget.kullanicirolu != null)
            PTDaireDugme(
              ikon: Icons.notifications_none_rounded,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BildirimlerScreen(isletmebilgi: widget.isletmebilgi, kullanicirolu: widget.kullanicirolu!))),
            ),
        ]),
      );

  Widget _hero() => SizedBox(
        height: 116,
        child: Row(children: [
          Container(
            width: 110,
            height: 110,
            // Cam efekti: beyaz parlak kenar + açık mor → lavanta geçiş + zilin arkasında mor parıltı
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF1E9FE), Color(0xFFDCCBFA)],
                stops: [0, 0.45, 1],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.95), width: 3),
              boxShadow: [
                BoxShadow(color: PT.mor.withValues(alpha: 0.16), blurRadius: 24, offset: const Offset(0, 10)),
                BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 10, spreadRadius: -2, offset: const Offset(-3, -3)),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0.1, 0.15),
                  radius: 0.62,
                  colors: [const Color(0xFFB794F6).withValues(alpha: 0.38), const Color(0xFFB794F6).withValues(alpha: 0)],
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Image.asset('images/bildirim_zil.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Bildirimlerim',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF1B1464), letterSpacing: -0.6)),
              ),
              const SizedBox(height: 4),
              const Text('Size gelen bildirimleri dilediğiniz gibi yönetin.',
                  style: TextStyle(fontSize: 13.5, height: 1.3, color: Color(0xFF2E2A4F))),
              const SizedBox(height: 6),
              SizedBox(height: 12, width: double.infinity, child: CustomPaint(painter: _Kavis())),
            ]),
          ),
        ]),
      );

  Widget _anahtar(bool deger, ValueChanged<bool>? degisti) => Transform.scale(
        scale: 1.08,
        child: Switch(
          value: deger,
          onChanged: degisti,
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? PT.mor : const Color(0xFFE2E3EA)),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      );

  Widget _tumu() {
    final mesgul = _kaydediliyor.contains('tumu');
    return PTKart(
      padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
      child: Row(children: [
        const PTIkon(Icons.notifications_rounded, boyut: 52),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Tüm Bildirimler Sesli', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: PT.koyu)),
            ),
            SizedBox(height: 3),
            Text('Kapatırsanız tüm bildirimler sessiz gelir.', style: TextStyle(fontSize: 12.5, height: 1.3, color: PT.gri)),
          ]),
        ),
        _anahtar(_hepsiSesli, mesgul || _acilabilir.isEmpty ? null : (v) => _degistir('tumu', v, '')),
      ]),
    );
  }

  Widget _bolumBaslik(String m) => Row(children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFA78BFA), borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 12),
        Text(m, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PT.koyu, letterSpacing: 3.2)),
      ]);

  Widget _satir(Map<String, dynamic> k) {
    final kilitli = k['kilitli'] == true;
    final sesli = k['sessiz'] != true;
    final kod = k['kod'].toString();
    final mesgul = _kaydediliyor.contains(kod) || _kaydediliyor.contains('tumu');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: kilitli ? 0.55 : 1,
        child: PTKart(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(children: [
            PTIkon(_ikonlar[k['ikon']] ?? Icons.notifications_rounded, boyut: 50),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(k['ad'].toString(), maxLines: 1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PT.koyu)),
                ),
                const SizedBox(height: 3),
                Text(
                  kilitli ? 'İşletme bu bildirimleri kapattı.' : (sesli ? k['aciklama'].toString() : 'Sessiz · ${k['aciklama']}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, height: 1.3, color: PT.gri),
                ),
              ]),
            ),
            const SizedBox(width: 4),
            kilitli
                ? const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 22))
                : _anahtar(sesli, mesgul ? null : (v) => _degistir(kod, v, k['ad'].toString())),
          ]),
        ),
      ),
    );
  }

  Widget _bilgi() => Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(color: PT.lila.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(20)),
        child: Stack(children: [
          Positioned(
            right: -6,
            top: -8,
            bottom: -8,
            child: Icon(Icons.notifications_rounded, size: 76, color: PT.mor.withValues(alpha: 0.08)),
          ),
          Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), shape: BoxShape.circle),
              child: const Icon(Icons.info_rounded, color: PT.mor, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Sessize aldığınız bildirimler yine gelir ve zil listesinde görünür; yalnızca ses ve titreşim yapmaz. '
                'Hangi bildirimin size gönderileceğine işletme karar verir.',
                style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF3B3561)),
              ),
            ),
          ]),
        ]),
      );
}

/// Başlık altındaki mor kavis
class _Kavis extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Path()
      ..moveTo(s.width * 0.12, s.height * 0.95)
      ..quadraticBezierTo(s.width * 0.45, s.height * 0.05, s.width * 0.95, s.height * 0.2);
    c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(colors: [Color(0xFF6A1FD0), Color(0x336A1FD0)])
              .createShader(Rect.fromLTWH(0, 0, s.width, s.height)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
