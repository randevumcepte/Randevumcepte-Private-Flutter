import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Modern, full-screen "internet bağlantınız yok" ekrani.
///
/// - connectivity_plus stream'i dinler, bağlantı geri gelince otomatik retry
///   tetikler.
/// - "Tekrar Dene" butonuna basıldığında [onRetry] cagrilir; retry sirasinda
///   buton loading state'e gecer.
class NoInternetScreen extends StatefulWidget {
  final Future<void> Function() onRetry;
  final String? title;
  final String? message;

  const NoInternetScreen({
    Key? key,
    required this.onRetry,
    this.title,
    this.message,
  }) : super(key: key);

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _retrying = false;
  bool _autoRetryInFlight = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    // Bağlantı geri gelince otomatik retry.
    _connSub = Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn);
      if (online && !_autoRetryInFlight && !_retrying) {
        _autoRetryInFlight = true;
        // Kucuk bir gecikme ile gercek DNS check yapalim — bazen sistem
        // baglantili gozukur ama paket henuz akmaz.
        await Future.delayed(const Duration(milliseconds: 600));
        if (await _hasRealInternet()) {
          if (mounted) _handleRetry();
        }
        _autoRetryInFlight = false;
      }
    });
  }

  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('apptest.randevumcepte.com.tr')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleRetry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF6F7FB);
    final cardBg = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final accent = cs.primary;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1D24);
    final textSecondary =
        isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing icon
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) {
                            return Container(
                              width: 140 + (_pulse.value * 30),
                              height: 140 + (_pulse.value * 30),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent
                                    .withOpacity(0.06 + (1 - _pulse.value) * 0.05),
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) {
                            return Container(
                              width: 110 + (_pulse.value * 15),
                              height: 110 + (_pulse.value * 15),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withOpacity(0.10),
                              ),
                            );
                          },
                        ),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cardBg,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                    isDark ? 0.35 : 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            size: 46,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    widget.title ?? 'İnternet bağlantınız yok',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.message ??
                        'Lütfen Wi-Fi veya mobil veri bağlantınızı kontrol edip tekrar deneyin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Tips card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      children: [
                        _tipRow(Icons.wifi_rounded, 'Wi-Fi açık mı kontrol edin',
                            textPrimary, textSecondary),
                        const SizedBox(height: 10),
                        _tipRow(Icons.signal_cellular_alt_rounded,
                            'Mobil verinizin aktif olduğundan emin olun',
                            textPrimary, textSecondary),
                        const SizedBox(height: 10),
                        _tipRow(Icons.airplanemode_inactive_rounded,
                            'Uçak modu kapalı olmalı',
                            textPrimary, textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _retrying ? null : _handleRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: accent.withOpacity(0.7),
                      ),
                      child: _retrying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Tekrar Dene',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tipRow(IconData icon, String text, Color textPrimary,
      Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              color: textPrimary.withOpacity(0.85),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// Cihazın gercekten internete erisebildigini kontrol eder.
/// connectivity_plus tek başına yeterli degil (Wi-Fi'a bagli olup internet
/// olmayabilir), bu yuzden DNS lookup ile dogruluyoruz.
Future<bool> hasInternetConnection() async {
  try {
    final conn = await Connectivity().checkConnectivity();
    final online = conn.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
    if (!online) return false;
    final result = await InternetAddress.lookup('apptest.randevumcepte.com.tr')
        .timeout(const Duration(seconds: 4));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Uygulama agacinin uzerine yerlestirilen global connectivity watcher.
/// Internet kesildiginde [NoInternetScreen]'i tam ekran overlay olarak
/// gosterir; geri gelince otomatik kapanir.
///
/// MaterialApp.builder icinden cocuk widget'i sararak kullanin.
class ConnectivityWatcher extends StatefulWidget {
  final Widget child;
  const ConnectivityWatcher({Key? key, required this.child}) : super(key: key);

  @override
  State<ConnectivityWatcher> createState() => _ConnectivityWatcherState();
}

class _ConnectivityWatcherState extends State<ConnectivityWatcher>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;
  bool _checking = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      _scheduleCheck(results: results);
    });
    // Ilk durumu da kontrol et (gec gelen ilk event icin).
    _scheduleCheck(initialDelay: const Duration(milliseconds: 800));
  }

  void _scheduleCheck({
    List<ConnectivityResult>? results,
    Duration initialDelay = const Duration(milliseconds: 400),
  }) {
    _debounce?.cancel();
    _debounce = Timer(initialDelay, () => _verify(results));
  }

  Future<void> _verify(List<ConnectivityResult>? results) async {
    if (_checking) return;
    _checking = true;
    try {
      // Hizli yol: connectivity_plus 'none' diyorsa direk offline.
      if (results != null &&
          results.isNotEmpty &&
          results.every((r) => r == ConnectivityResult.none)) {
        _setOffline(true);
        return;
      }
      // Gercek DNS check.
      final online = await hasInternetConnection();
      _setOffline(!online);
    } finally {
      _checking = false;
    }
  }

  void _setOffline(bool value) {
    if (!mounted || _offline == value) return;
    setState(() => _offline = value);
  }

  Future<void> _retry() async {
    final online = await hasInternetConnection();
    _setOffline(!online);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama on plana donunce yeniden kontrol et — sistem bazen baglanti
    // event'i atmadan internet geri gelebilir.
    if (state == AppLifecycleState.resumed) {
      _scheduleCheck(initialDelay: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline)
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: NoInternetScreen(onRetry: _retry),
            ),
          ),
      ],
    );
  }
}
