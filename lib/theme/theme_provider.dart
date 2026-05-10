import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:randevu_sistem/theme/app_theme.dart';
import 'package:randevu_sistem/theme/salon_tema_api.dart';

class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'salon_tema_config_v1';

  final SharedPreferences _prefs;

  ThemeProvider({required SharedPreferences prefs}) : _prefs = prefs {
    _loadFromCache();
  }

  AppThemeConfig _config = AppThemeConfig.defaults;
  AppThemeConfig get config => _config;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _activeSalonId;
  String? get activeSalonId => _activeSalonId;

  void _loadFromCache() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        _config = AppThemeConfig.fromJson(json);
      }
    } catch (_) {
      // ignore — defaults kalsın
    }
  }

  Future<void> _persistLocal() async {
    await _prefs.setString(_prefsKey, jsonEncode(_config.toJson()));
  }

  /// Salon değiştiğinde / login sonrası çağrılır.
  /// Lokal cache anında kullanılır, server'dan paralel sync yapılır.
  Future<void> bindSalon(String salonId) async {
    _activeSalonId = salonId;
    if (salonId.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    final remote = await SalonTemaApi.fetch(salonId);
    if (remote != null && remote != _config) {
      _config = remote;
      await _persistLocal();
    }
    _isSyncing = false;
    notifyListeners();
  }

  /// Kullanıcı tema seçtiğinde. canEditServer == true ise sahibi/yönetici;
  /// false ise sadece lokal değişir (çalışan/müşteri).
  Future<void> setConfig(
    AppThemeConfig newConfig, {
    bool canEditServer = false,
  }) async {
    if (newConfig == _config) return;
    _config = newConfig;
    await _persistLocal();
    notifyListeners();

    final salonId = _activeSalonId;
    if (canEditServer && salonId != null && salonId.isNotEmpty) {
      // Arka planda server'a yaz, hata olursa sessizce geç (lokal zaten kaydedildi)
      unawaited(SalonTemaApi.push(salonId, newConfig));
    }
  }

  Future<void> setPreset(
    AppThemePreset preset, {
    bool canEditServer = false,
  }) async {
    await setConfig(
      _config.copyWith(preset: preset, resetCustomSeed: true),
      canEditServer: canEditServer,
    );
  }

  Future<void> setCustomSeed(
    int argb, {
    bool canEditServer = false,
  }) async {
    await setConfig(
      _config.copyWith(
        preset: AppThemePreset.ozel,
        customSeedArgb: argb,
      ),
      canEditServer: canEditServer,
    );
  }

  Future<void> setBrightnessMode(
    AppBrightnessMode mode, {
    bool canEditServer = false,
  }) async {
    await setConfig(
      _config.copyWith(brightnessMode: mode),
      canEditServer: canEditServer,
    );
  }
}

void unawaited(Future<void> future) {
  // ignore: unused_local_variable
  future.then((_) {}, onError: (_) {});
}
