// Uygulamanin softphone ile tek temas noktasi.
//
// Softphone acik/kapali bilgisini bilen tek yer softphone_kayit.dart'tir;
// o dosya `tool/softphone.sh ac|kapat` tarafindan yeniden yazilir. Uygulama
// kodu yalnizca bu arayuzu kullanir, boylece softphone kapaliyken hicbir
// native SIP/WebRTC/CallKit paketi build'e girmez.
//
// KURAL: bu dosya ve paket disindaki her cagri, kapaliyken no-op olmali ve
// her zaman derlenebilir kalmali. Yarim is yalnizca packages/rc_softphone'da.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'softphone_kayit.dart';

abstract class Softphone {
  /// Bu build'de softphone modulu var mi?
  bool get aktif;

  /// Santrale kayitli mi (arama yapilabilir mi)?
  ValueListenable<bool> get kayitli;

  /// Dahili ile santrale register ol. [navigatorKey] arama ekraninin
  /// otomatik acilmasi icin. Kapaliyken no-op.
  Future<void> baslat({
    required String dahili,
    required String dahiliSifre,
    GlobalKey<NavigatorState>? navigatorKey,
  });

  /// Logout / sube degisimi / lisans bitimi.
  Future<void> kapat();

  /// Uygulama icinden giden cagri; arama ekrani kendiliginden acilir.
  /// Kapaliyken veya kayitli degilken false.
  Future<bool> ara(String hedef, {String? gorunenAd});

  /// Numara cevirme ekranini ac. Kapaliyken no-op.
  Future<void> tusTakimiAc(BuildContext context);

  static final Softphone instance = softphoneOlustur();
}

/// Softphone modulu olmayan build'lerin kullandigi bos uygulama.
class KapaliSoftphone implements Softphone {
  const KapaliSoftphone();
  static final ValueNotifier<bool> _hayir = ValueNotifier<bool>(false);
  @override
  bool get aktif => false;
  @override
  ValueListenable<bool> get kayitli => _hayir;
  @override
  Future<void> baslat({
    required String dahili,
    required String dahiliSifre,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {}
  @override
  Future<void> kapat() async {}
  @override
  Future<bool> ara(String hedef, {String? gorunenAd}) async => false;
  @override
  Future<void> tusTakimiAc(BuildContext context) async {}
}
