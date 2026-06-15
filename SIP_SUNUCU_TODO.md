# SIP Softphone — Sunucu Tarafı Yapılacaklar (Laravel + FreePBX/agi-bin)

Uygulama tarafı (Flutter) Faz 1–2'de hazır: dahili register oluyor, giden arama
ve **ön planda** gelen çağrı çalışıyor; **arka plan/kilitli ekran** gelen çağrı
için CallKit/ConnectionService altyapısı kuruldu. Bunun uçtan uca çalışması için
santral + Laravel tarafında aşağıdakiler gerekir.

## Mimari özet (arka plan gelen çağrı handshake)
1. Santrale dahiliye çağrı düşer.
2. Dialplan, `Dial()` etmeden **önce** o dahilinin kayıtlı cihaz token'larına
   push gönderir (iOS: APNs **VoIP** push; Android: yüksek öncelikli **FCM data**
   mesajı), payload: `{"type":"sip_incoming","caller":"<arayan>","call_id":"<uuid>"}`.
3. Cihaz push'u alır → CallKit/ConnectionService çağrı ekranı çıkar; uygulama
   `SipService.baslat()` ile WSS REGISTER olur.
4. Dialplan, dahilinin register olmasını **bekler** (~5 sn PJSIP contact yoklama),
   sonra `Dial(PJSIP/<dahili>,30)`.
5. INVITE gelir → uygulama otomatik yanıtlar (kullanıcı Kabul'e bastıysa).

> Uygulama, kullanıcı CallKit'te **Kabul**'e basınca otomatik register + yanıtlama
> yapar (`SipService._pendingAutoAnswer`). Santral INVITE'ı register'dan sonra
> göndermezse çağrı düşer — bu yüzden 4. adımdaki bekleme şart.

## 1) Laravel: token saklama API'si (`/api/v1/voipTokenKaydet`)
Mevcut uygulama çağrısı: `POST {voipToken, personelId}`. Gerekenler:
- **`platform` alanı ekle**: `ios_voip` | `android_fcm`. (Uygulama Faz 3'te bu alanı
  gönderecek şekilde güncellenecek; şimdilik server iki tipi de saklayabilmeli.)
- Token'ı **dahili (`dahili_no_webrtc`) bazında** sakla — dialplan dahiliyle eşler.
  `personelId → dahili` eşlemesi `musteri_portfoy`/işletme tablosundan çözülür.
- **Çoklu cihaz**: aynı dahili birden çok cihazda olabilir → token **listesi** tut
  (cihaz başına bir satır, `son_gorulme` ile eskileri ayıkla).

Önerilen tablo: `sip_push_tokens(id, dahili, platform, token, personel_id, updated_at)`
(UNIQUE: `platform+token`).

## 2) agi-bin: `pushGonder.js` üretime alma
Mevcut hali tek cihazlık, `production:false`, sadece **alert** push (VoIP değil).
Gerekenler:
- Token'ları CLI argümanı yerine **DB'den** (dahiliye göre) oku.
- **iOS VoIP push**: `apn.Notification` yerine VoIP — `pushType: 'voip'`,
  `topic: '<BUNDLE_ID>.voip'` (alert topic değil!). Aynı `.p8`
  (`AuthKey_SVN64Y89VU.p8`, Team `24DZ882DDK`) VoIP için de geçerli.
  Payload `aps` yerine custom data: `{type, caller, call_id}`.
- **Android FCM data push**: ayrı gönderici (firebase-admin) ile
  `{ data: {type:'sip_incoming', caller, call_id}, android:{priority:'high'} }`
  — **notification bloğu OLMADAN** (data-only ki arka plan isolate çalışsın).
- `production: true` (App Store/Play build'leri için).
- Beyaz-etiket: her markanın kendi `BUNDLE_ID`'si var → token kaydıyla birlikte
  bundle/marka bilgisini de sakla veya dahili→marka eşlemesinden çöz.

## 3) agi-bin/extensions_custom.conf: dialplan
WebRTC dahilisine çağrı düşen context'te, `Dial()` öncesi:
```
; 1) Push gönder (arka plandaki cihazları uyandır)
exten => _X.,n,System(node /var/lib/asterisk/agi-bin/pushGonder.js "${EXTEN}" "${CALLERID(num)}")
; 2) Dahilinin register olmasını bekle (~5 sn), sonra çağır
exten => _X.,n,Set(i=0)
exten => _X.,n(wait_reg),GotoIf($["${PJSIP_AOR(${EXTEN},contact)}" != ""]?do_dial)
exten => _X.,n,Wait(1)
exten => _X.,n,Set(i=$[${i}+1])
exten => _X.,n,GotoIf($[${i}<5]?wait_reg)
exten => _X.,n(do_dial),Dial(PJSIP/${EXTEN},30)
```
> Gerçek FreePBX'te bu, ilgili dahilinin custom-context'ine veya
> `[macro-dial...]` öncesi bir hook'a yerleştirilir; yapı PBX kurulumuna göre
> uyarlanmalı. AMI ile `pjsip show contacts` yoklaması da alternatif.

## 4) iOS APNs VoIP (Faz 3 ile birlikte)
- Apple Developer'da her beyaz-etiket bundle ID için **Push Notifications**
  capability + APNs Key (`SVN64Y89VU`) etkin olmalı.
- VoIP push topic: `<bundleid>.voip`.
- Uygulama PushKit token'ını `com.randevumcepte.voiptoken` MethodChannel ile alıp
  `voipTokenKaydet`'e `platform=ios_voip` ile gönderiyor (mevcut).

## Test (uçtan uca)
- **Android**: cihaz kilitliyken başka telefondan dahiliyi ara → tam ekran gelen
  çağrı (lock screen) → Kabul → ses. 15+ dk idle (Doze) sonrası tekrar dene.
- **iOS** (Faz 3 sonrası, gerçek cihaz): kilitli iPhone'a çağrı → native CallKit
  → Kabul → ses.
