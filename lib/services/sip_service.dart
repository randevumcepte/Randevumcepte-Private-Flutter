// Feature flag'leri. SIP softphone bundle'dan tamamen cikarildi
// (Google policy + Apple 5.1.1 uyumu; "calisan sistem videosu" talebine
// girmemek icin). Arama 3. parti Bria Mobile ile yapilir; uygulama
// sadece santral raporu, CDR, arama listesi gosterir — kendi icinde
// SIP register/call YOK.
//
// Geri acilacaksa:
//   - pubspec.yaml: sip_ua, flutter_webrtc, flutter_callkit_incoming paketlerini geri ekle
//   - Android: ilgili FGS/PHONE_CALL/USE_FULL_SCREEN_INTENT permission'larin tools:node="remove" satirlarini kaldir
//   - iOS: Info.plist NSMicrophoneUsageDescription + UIBackgroundModes:audio geri ekle
//   - basic_bottom_nav_bar.dart: SipService init/kapat cagrilarini geri koy
//   - Bu dosyaya SipService class'ini git log'tan geri getir (commit 7ffb88e oncesi)

// Sesli Asistan (Patron Asistani + Sesli Randevu). Kapali iken home
// ekranindaki "Asistan" FAB gizlenir, MIC/Speech permission istenmez.
const bool kAsistanEnabled = false;

// Cagri Merkezi menusu (Diger > Cagri Merkezi). CDR raporu + arama listesi
// + randevu takvimi gosterir; dis arama Bria Mobile ile yapilir. Markada
// santral/dahili kullanilmayacaksa false yap.
const bool kCagriMerkeziEnabled = true;
