# flutter_callkit_incoming 2.5.8 — yerel yamali kopya

pub.dev flutter_callkit_incoming 2.5.8'in kopyasi (example/, images/, test/
alinmadi). Degisiklikler yalniz Android tarafinda:

- `android/src/main/AndroidManifest.xml`: `CallkitNotificationService`
  `foregroundServiceType="phoneCall|microphone"` + `FOREGROUND_SERVICE_MICROPHONE`.
- `CallkitNotificationService.kt`:
  - Mikrofon izni varsa (Android 11+) on plan servisi
    `PHONE_CALL | MICROPHONE` tipiyle baslar; reddedilirse `PHONE_CALL`'a duser.
    Orijinalde yalniz `PHONE_CALL` vardi -> uygulama arka plana gecince
    Android mikrofonu susturuyor, karsi taraf personeli duymuyordu.
  - `ACTION_CALL_CONNECTED` islenir: gorusme baglaninca servis mikrofon
    tipiyle yeniden on plana alinir (arka planda kabul edilen cagri icin).
  - Action karsilastirmalari `===` yerine `==`.
- `CallkitIncomingBroadcastReceiver.kt`: `ACTION_CALL_CONNECTED` gelince
  servise de iletilir (try/catch; servis yoksa atlanir).

Giden aramada "suren arama" bildirimi Dart tarafinda
`FlutterCallkitIncoming.startCall` ile acilir (rc_softphone sip_service.dart).

Surum yukseltilecekse: yeni surumde microphone tipi eklenmis mi bak; eklenmisse
bu klasoru sil ve rc_softphone/pubspec.yaml'da pub.dev surumune don.
