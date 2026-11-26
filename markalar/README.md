# Markalar

Her klasör bir marka. Tek kaynak `marka.json`; marka değiştirmek için:

    tool/marka.sh gec <kod>

Klasörde: `marka.json`, `google-services.json`, `GoogleService-Info.plist`, ikon/logo/splash görselleri.
Alanlar: kod, ad, paket (Android applicationId; iOS bundle id aynıysa ios_paket gerekmez),
surum, build, ios_profil (App Store provisioning profile), ikon, logo (uygulama içi), splash,
ikon_arka_plan_ios, splash_renk, softphone (true/false).

Yeni marka: `tool/marka.sh yeni <kod>` → doldur → `tool/marka.sh kontrol <kod>` → `tool/marka.sh gec <kod>`.
