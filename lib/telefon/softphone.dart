// Uygulamanin softphone ile tek temas noktasi.
//
// Softphone acik/kapali bilgisini bilen tek yer softphone_kayit.dart'tir;
// o dosya `tool/softphone.sh ac|kapat` tarafindan yeniden yazilir. Uygulama
// kodu yalnizca bu arayuzu kullanir, boylece softphone kapaliyken hicbir
// native SIP/WebRTC/CallKit paketi build'e girmez.
import 'softphone_kayit.dart';

abstract class Softphone {
  /// Bu build'de softphone modulu var mi?
  bool get aktif;

  /// Dahili ile santrale register ol. Kapaliyken no-op.
  Future<void> baslat({required String dahili, required String dahiliSifre});

  /// Logout / sube degisimi / lisans bitimi.
  Future<void> kapat();

  /// Uygulama icinden giden cagri. Kapaliyken veya register degilken false.
  Future<bool> ara(String hedef);

  static final Softphone instance = softphoneOlustur();
}

/// Softphone modulu olmayan build'lerin kullandigi bos uygulama.
class KapaliSoftphone implements Softphone {
  const KapaliSoftphone();
  @override
  bool get aktif => false;
  @override
  Future<void> baslat({required String dahili, required String dahiliSifre}) async {}
  @override
  Future<void> kapat() async {}
  @override
  Future<bool> ara(String hedef) async => false;
}
