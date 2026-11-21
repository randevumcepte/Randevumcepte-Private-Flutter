# sip_ua 1.0.1 — yerel yamali kopya

pub.dev sip_ua 1.0.1'in birebir kopyasi; TEK degisiklik:

- `lib/src/rtc_session.dart` `_sendReinvite` (2619) ve `_sendUpdate` (2883):
  `if (succeeded != null)` -> `if (succeeded)`.
  Orijinalde kosul hep dogru oldugu icin re-INVITE/UPDATE cevabindaki SDP
  hic `setRemoteDescription` edilmiyordu -> Beklet/Devam (hold/unhold) bozuk.

Surum yukseltilecekse: yeni surumde bu hata duzelmis mi bak, duzelmisse bu
klasoru sil ve rc_softphone/pubspec.yaml'da tekrar pub.dev surumune don.
