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
import 'package:randevu_sistem/dil/material.dart';

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

  /// Uygulama acilisinda (main) cagrilir: uygulama gelen cagri push'u ile
  /// uyandirildiysa cagriyi karsilar. true: uygulama "Cevapla"ya basilarak
  /// acildi; main splash yerine [cagriAcilisEkrani] gostermeli.
  /// Kapaliyken her zaman false.
  Future<bool> erkenBaslat({GlobalKey<NavigatorState>? navigatorKey});

  /// "Cevapla" ile acilista kok sayfa olarak gosterilen arama ekrani.
  /// Cagri bitince [onBitti] cagrilir (normal acilis akisina gecilir).
  Widget cagriAcilisEkrani({required VoidCallback onBitti});

  /// FCM mesaji softphone gelen cagrisi mi? Oyleyse isler ve true doner;
  /// uygulamanin normal bildirim akisi mesaji atlamali. [arkaPlan]: FCM arka
  /// plan isolate'i. Kapaliyken her zaman false.
  Future<bool> pushIsle(Map<String, dynamic> data, {bool arkaPlan = false});

  /// Logout / sube degisimi / lisans bitimi.
  Future<void> kapat();

  /// Arama butonu icin: softphone'dan aranabilir mi? Kayitliysa hemen true.
  /// Dahili var ama baglanti kopmussa (uygulama arka plandan dondu vb.)
  /// yeniden baglanmayi [bekle] kadar dener. false -> cagiran Bria'ya duser.
  /// Kapaliyken her zaman false.
  Future<bool> aramayaHazir({Duration bekle = const Duration(seconds: 4)});

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
  Future<bool> erkenBaslat({GlobalKey<NavigatorState>? navigatorKey}) async =>
      false;
  @override
  Widget cagriAcilisEkrani({required VoidCallback onBitti}) =>
      const SizedBox.shrink();
  @override
  Future<bool> pushIsle(Map<String, dynamic> data, {bool arkaPlan = false}) async =>
      false;
  @override
  Future<void> kapat() async {}
  @override
  Future<bool> aramayaHazir({Duration bekle = const Duration(seconds: 4)}) async =>
      false;
  @override
  Future<bool> ara(String hedef, {String? gorunenAd}) async => false;
  @override
  Future<void> tusTakimiAc(BuildContext context) async {}
}
