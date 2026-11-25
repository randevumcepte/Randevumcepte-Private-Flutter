import 'dart:async';

import 'package:randevu_sistem/dil/material.dart';

/// Süs animasyonları için 0..1 arası yavaş döngü. Tüm animasyonlar TEK saati paylaşır (20 kare/sn),
/// böylece ekran her adımda bir kez çizilir (pil dostu). Sayfa üstte değilken, uygulama arka
/// plandayken ya da sistemde animasyonlar kapalıyken durur.
mixin YavasDongu<T extends StatefulWidget> on State<T> {
  static const _adimMs = 50;
  static final Set<YavasDongu> _kayitli = {};
  static Timer? _saat;

  final ValueNotifier<double> dongu = ValueNotifier<double>(0);
  ModalRoute<dynamic>? _rota;

  Duration get donguSuresi;

  static void _vur(Timer _) {
    final b = WidgetsBinding.instance;
    final durum = b.lifecycleState;
    if (durum != null && durum != AppLifecycleState.resumed) return;
    if (b.platformDispatcher.accessibilityFeatures.disableAnimations) return;
    for (final d in _kayitli) {
      if (d.mounted && (d._rota?.isCurrent ?? true)) {
        d.dongu.value = (d.dongu.value + _adimMs / d.donguSuresi.inMilliseconds) % 1.0;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _kayitli.add(this);
    _saat ??= Timer.periodic(const Duration(milliseconds: _adimMs), _vur);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rota = ModalRoute.of(context);
  }

  @override
  void dispose() {
    _kayitli.remove(this);
    if (_kayitli.isEmpty) {
      _saat?.cancel();
      _saat = null;
    }
    dongu.dispose();
    super.dispose();
  }
}
