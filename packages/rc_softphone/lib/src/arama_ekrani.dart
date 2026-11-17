import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sip_ua/sip_ua.dart';

import 'sip_service.dart';
import 'tus_takimi.dart';

/// Aktif cagri ekrani: karsi taraf, durum/sure, sessiz, hoparlor, beklet,
/// tus takimi (DTMF) ve kapat. SipService tarafindan otomatik acilir; cagri
/// bitince bitis nedenini kisa sure gosterip kendini kapatir.
class AramaEkrani extends StatefulWidget {
  const AramaEkrani({super.key, this.onBitti});

  /// Verilirse cagri bitince ekran kendini kapatmaz, bunu cagirir. Uygulama
  /// "Cevapla" ile acildiginda arama ekrani kok sayfa olur; onBitti normal
  /// acilis akisina (splash/giris) gecer.
  final VoidCallback? onBitti;

  @override
  State<AramaEkrani> createState() => _AramaEkraniState();
}

class _AramaEkraniState extends State<AramaEkrani> {
  final SipService _sip = SipService.instance;
  Timer? _sayac;
  bool _tusTakimiAcik = false;
  bool _kapaniyor = false;
  String _dtmfGecmisi = '';

  @override
  void initState() {
    super.initState();
    _sip.ekranDurumu(true);
    _sip.activeCall.addListener(_cagriDegisti);
    _sip.pushBaglaniyor.addListener(_cagriDegisti);
    _sayac = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Ekran acilmadan cagri bitmis olabilir.
    WidgetsBinding.instance.addPostFrameCallback((_) => _cagriDegisti());
  }

  @override
  void dispose() {
    _sip.activeCall.removeListener(_cagriDegisti);
    _sip.pushBaglaniyor.removeListener(_cagriDegisti);
    _sip.ekranDurumu(false);
    _sayac?.cancel();
    super.dispose();
  }

  /// Cagri yok ve "Cevapla"dan sonra baglanti da beklenmiyor.
  bool get _cagriYok =>
      _sip.activeCall.value == null && !_sip.pushBaglaniyor.value;

  void _cagriDegisti() {
    if (mounted) setState(() {});
    if (!_cagriYok || _kapaniyor) return;
    _kapaniyor = true;
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final VoidCallback? bitti = widget.onBitti;
      if (bitti != null) {
        bitti();
      } else {
        Navigator.of(context).maybePop();
      }
    });
  }

  String _durumMetni() {
    if (_kapaniyor) return _sip.bitisNedeni.value ?? 'Arama sonlandı';
    final DateTime? baslangic = _sip.baglandiZamani.value;
    if (baslangic != null) {
      if (_sip.beklemede.value) return 'Beklemede';
      final Duration d = DateTime.now().difference(baslangic);
      final String dk = d.inMinutes.toString().padLeft(2, '0');
      final String sn = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$dk:$sn';
    }
    switch (_sip.callState.value) {
      case CallStateEnum.PROGRESS:
        return 'Çalıyor...';
      case CallStateEnum.CONNECTING:
      case CallStateEnum.CALL_INITIATION:
        return 'Aranıyor...';
      default:
        return 'Bağlanıyor...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme renk = Theme.of(context).colorScheme;
    final String ad = _sip.karsiTarafAdi?.isNotEmpty == true
        ? _sip.karsiTarafAdi!
        : (_sip.karsiTarafNumara ?? 'Arama');
    final String? altBaslik =
        _sip.karsiTarafAdi?.isNotEmpty == true ? _sip.karsiTarafNumara : null;

    return PopScope(
      // Aktif cagri varken geri tusu ekrani kapatmasin (cagri arka planda kalir).
      canPop: widget.onBitti == null && (_kapaniyor || _cagriYok),
      child: Scaffold(
        backgroundColor: const Color(0xFF101828),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 32),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: renk.primary.withValues(alpha: 0.25),
                  child: const Icon(Icons.person, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  ad,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600),
                ),
                if (altBaslik != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(altBaslik,
                      style: const TextStyle(color: Colors.white70, fontSize: 15)),
                ],
                const SizedBox(height: 12),
                Text(
                  _durumMetni(),
                  style: TextStyle(
                    color: _kapaniyor ? Colors.redAccent.shade100 : Colors.white70,
                    fontSize: 17,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                if (_tusTakimiAcik) ...<Widget>[
                  Text(_dtmfGecmisi,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 24, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  TusIzgarasi(
                    koyu: true,
                    onTus: (String t) {
                      _sip.dtmfGonder(t);
                      setState(() => _dtmfGecmisi += t);
                    },
                  ),
                ] else
                  _kontroller(),
                const SizedBox(height: 28),
                _kapatButonu(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kontroller() {
    final bool aktif = !_kapaniyor && _sip.activeCall.value != null;
    return Wrap(
      spacing: 28,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: <Widget>[
        _ValueButon(
          dinle: _sip.sessiz,
          ikonAcik: Icons.mic_off,
          ikonKapali: Icons.mic,
          etiket: 'Sessiz',
          onTap: aktif ? () => _sip.sessizToggle() : null,
        ),
        _ValueButon(
          dinle: _sip.hoparlor,
          ikonAcik: Icons.volume_up,
          ikonKapali: Icons.volume_down,
          etiket: 'Hoparlör',
          onTap: aktif ? () => _sip.hoparlorToggle() : null,
        ),
        _ValueButon(
          dinle: _sip.beklemede,
          ikonAcik: Icons.play_arrow,
          ikonKapali: Icons.pause,
          etiket: 'Beklet',
          onTap: aktif && _sip.baglandiZamani.value != null
              ? () => _sip.beklemeToggle()
              : null,
        ),
        _YuvarlakButon(
          ikon: Icons.dialpad,
          etiket: 'Tuşlar',
          secili: false,
          onTap: aktif ? () => setState(() => _tusTakimiAcik = true) : null,
        ),
      ],
    );
  }

  Widget _kapatButonu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (_tusTakimiAcik)
          Padding(
            padding: const EdgeInsets.only(right: 32),
            child: TextButton(
              onPressed: () => setState(() => _tusTakimiAcik = false),
              child: const Text('Gizle', style: TextStyle(color: Colors.white70)),
            ),
          ),
        Material(
          color: Colors.red,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _kapaniyor || _cagriYok ? null : _sip.kapatCagri,
            child: const SizedBox(
              width: 72,
              height: 72,
              child: Icon(Icons.call_end, color: Colors.white, size: 34),
            ),
          ),
        ),
        if (_tusTakimiAcik) const SizedBox(width: 80),
      ],
    );
  }
}

class _ValueButon extends StatelessWidget {
  const _ValueButon({
    required this.dinle,
    required this.ikonAcik,
    required this.ikonKapali,
    required this.etiket,
    required this.onTap,
  });

  final ValueNotifier<bool> dinle;
  final IconData ikonAcik;
  final IconData ikonKapali;
  final String etiket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: dinle,
      builder: (_, bool acik, __) => _YuvarlakButon(
        ikon: acik ? ikonAcik : ikonKapali,
        etiket: etiket,
        secili: acik,
        onTap: onTap,
      ),
    );
  }
}

class _YuvarlakButon extends StatelessWidget {
  const _YuvarlakButon({
    required this.ikon,
    required this.etiket,
    required this.secili,
    required this.onTap,
  });

  final IconData ikon;
  final String etiket;
  final bool secili;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool pasif = onTap == null;
    return Opacity(
      opacity: pasif ? 0.4 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: secili ? Colors.white : Colors.white.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 64,
                height: 64,
                child: Icon(ikon,
                    color: secili ? const Color(0xFF101828) : Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(etiket, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
