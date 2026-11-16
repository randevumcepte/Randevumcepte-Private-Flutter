#!/usr/bin/env bash
# SIP softphone modulunu (packages/rc_softphone) ac / kapat / durum.
#
#   tool/softphone.sh durum            ACIK / KAPALI / KARISIK (dosya dosya detay)
#   tool/softphone.sh yayin-kontrol    Store build'i oncesi: KAPALI ve native
#                                      kalinti yoksa exit 0, degilse exit 1
#   tool/softphone.sh ac       [--pod-yok]
#   tool/softphone.sh kapat    [--pod-yok]
#
# Dokunulan dosyalar (hepsi marka bazli lokal dosyalar, bu yuzden marka
# switch'ten sonra o markada istenen duruma gore bir kez calistir):
#   pubspec.yaml                          rc_softphone path bagimliligi
#   lib/telefon/softphone_kayit.dart      KapaliSoftphone <-> SipService adaptoru
#   android/app/src/main/AndroidManifest.xml
#                                         5 FGS/telefon izni: tools:node="remove" <-> normal
#   ios/Runner/Info.plist                 UIBackgroundModes: audio + voip ekle/cikar
# Sonra: flutter pub get + (iOS) pod install.
#
# KAPALI = native webrtc/callkit paketleri build'e hic girmez (Play FGS beyani
# ve Apple 2.5.4 / VoIP gerekcesi gerekmez). ACIK = store'a yollarken Play
# Console'da FGS (microphone/phone_call) beyani + calisan ozellik videosu,
# App Store'da arka plan audio + voip (PushKit) gerekcesi gerekir.
set -euo pipefail

KOK="$(cd "$(dirname "$0")/.." && pwd)"
cd "$KOK"

KOMUT="${1:-durum}"
POD=1
[[ "${2:-}" == "--pod-yok" ]] && POD=0

PUBSPEC="pubspec.yaml"
KAYIT="lib/telefon/softphone_kayit.dart"
MANIFEST="android/app/src/main/AndroidManifest.xml"
PLIST="ios/Runner/Info.plist"

# Dort ayar dosyasini ayri ayri okur. Her biri "1" (acik) / "0" (kapali).
# Hepsi ayni -> ACIK/KAPALI, farkli -> KARISIK. KARISIK en tehlikelisi:
# ornegin pubspec'te paket kalip kayit kapali ise native webrtc/callkit
# hicbir ise yaramadan build'e girer (Apple/Play red sebebi).
D_PUBSPEC=0; D_KAYIT=0; D_MANIFEST=0; D_PLIST=0
durum_hesapla() {
  D_PUBSPEC=0; D_KAYIT=0; D_MANIFEST=0; D_PLIST=0
  grep -q "^  rc_softphone:" "$PUBSPEC" && D_PUBSPEC=1
  grep -q "package:rc_softphone/" "$KAYIT" && D_KAYIT=1
  # FGS_PHONE_CALL izni remove'suz duruyorsa acik say
  grep -E 'android\.permission\.FOREGROUND_SERVICE_PHONE_CALL"' "$MANIFEST" | grep -vq 'tools:node="remove"' && D_MANIFEST=1
  python3 -I -c '
import re,sys
p=open(sys.argv[1]).read()
m=re.search(r"<key>UIBackgroundModes</key>\s*<array>(.*?)</array>",p,re.S)
sys.exit(0 if m and ("<string>audio</string>" in m.group(1) or "<string>voip</string>" in m.group(1)) else 1)' "$PLIST" && D_PLIST=1
  true
}

durum_oku() {
  durum_hesapla
  local t=$((D_PUBSPEC + D_KAYIT + D_MANIFEST + D_PLIST))
  if [[ $t -eq 4 ]]; then echo "ACIK"; elif [[ $t -eq 0 ]]; then echo "KAPALI"; else echo "KARISIK"; fi
}

durum_detay() {
  durum_hesapla
  local e; e() { [[ $1 -eq 1 ]] && echo "acik  " || echo "kapali"; }
  echo "  pubspec.yaml (rc_softphone)        : $(e $D_PUBSPEC)"
  echo "  lib/telefon/softphone_kayit.dart   : $(e $D_KAYIT)"
  echo "  AndroidManifest (FGS izinleri)     : $(e $D_MANIFEST)"
  echo "  Info.plist (audio+voip background) : $(e $D_PLIST)"
}

# Kapali gorunse bile pub get / pod install calistirilmadiysa native paket
# kalintisi build'e girebilir. Bunlari ayrica yakala.
native_kalinti() {
  local bulunan=""
  for f in .flutter-plugins-dependencies ios/Podfile.lock; do
    [[ -f "$f" ]] || continue
    if grep -Eq "flutter_webrtc|flutter_callkit_incoming|sip_ua" "$f"; then
      bulunan="$bulunan $f"
    fi
  done
  if [[ -f ios/Runner.xcodeproj/project.pbxproj ]] && grep -Eqi "siprix|WebRTC\.xcframework" ios/Runner.xcodeproj/project.pbxproj; then
    bulunan="$bulunan ios/Runner.xcodeproj/project.pbxproj"
  fi
  echo "$bulunan"
}

kayit_yaz() {
  if [[ "$1" == "ac" ]]; then
    cat > "$KAYIT" <<'DART'
// OTOMATIK URETILIR — elle duzenleme, `tool/softphone.sh ac|kapat` kullan.
// Durum: ACIK (rc_softphone paketi pubspec'te, native SIP/WebRTC/CallKit build'de).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rc_softphone/rc_softphone.dart';

import 'softphone.dart';

Softphone softphoneOlustur() => _SipSoftphone();

class _SipSoftphone implements Softphone {
  final SipService _sip = SipService.instance;

  @override
  bool get aktif => true;

  @override
  ValueListenable<bool> get kayitli => _sip.kayitli;

  @override
  Future<void> baslat({
    required String dahili,
    required String dahiliSifre,
    GlobalKey<NavigatorState>? navigatorKey,
  }) =>
      _sip.init(dahili: dahili, dahiliSifre: dahiliSifre, navigatorKey: navigatorKey);

  @override
  Future<void> erkenBaslat({GlobalKey<NavigatorState>? navigatorKey}) =>
      _sip.erkenBaslat(navigatorKey: navigatorKey);

  @override
  Future<void> kapat() => _sip.kapat();

  @override
  Future<bool> ara(String hedef, {String? gorunenAd}) =>
      _sip.cagriBaslat(hedef, gorunenAd: gorunenAd);

  @override
  Future<void> tusTakimiAc(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const TusTakimiEkrani()));
}
DART
  else
    cat > "$KAYIT" <<'DART'
// OTOMATIK URETILIR — elle duzenleme, `tool/softphone.sh ac|kapat` kullan.
// Durum: KAPALI (rc_softphone paketi pubspec'te yok, native paket girmez).
import 'softphone.dart';

Softphone softphoneOlustur() => const KapaliSoftphone();
DART
  fi
}

# pubspec / manifest / plist duzenlemeleri (python: sed'in BSD/GNU farkindan kacmak icin)
dosyalari_duzenle() {
  python3 -I - "$1" "$PUBSPEC" "$MANIFEST" "$PLIST" <<'PY'
import re, sys
mod, pubspec, manifest, plist = sys.argv[1:5]
ac = mod == "ac"

# --- pubspec ---
s = open(pubspec, newline="").read()
nl = "\r\n" if "\r\n" in s else "\n"
blok = ("  # >>> softphone (tool/softphone.sh yonetir) >>>\n"
        "  rc_softphone:\n"
        "    path: packages/rc_softphone\n"
        "  # <<< softphone <<<\n").replace("\n", nl)
s = re.sub(r"  # >>> softphone.*?# <<< softphone <<<\r?\n", "", s, flags=re.S)
if ac:
    m = re.search(r"^dependencies:\r?\n  flutter:\r?\n    sdk: flutter\r?\n", s, flags=re.M)
    if not m:
        sys.exit("pubspec.yaml: 'dependencies: / flutter: / sdk: flutter' blogu bulunamadi")
    s = s[:m.end()] + blok + s[m.end():]
open(pubspec, "w", newline="").write(s)

# --- AndroidManifest ---
izinler = ["FOREGROUND_SERVICE_MICROPHONE", "FOREGROUND_SERVICE_PHONE_CALL",
           "MANAGE_OWN_CALLS", "READ_PHONE_NUMBERS", "USE_FULL_SCREEN_INTENT"]
m = open(manifest, newline="").read()
for izin in izinler:
    desen = re.compile(r'<uses-permission android:name="android\.permission\.%s"[^>]*/>' % izin)
    yeni = ('<uses-permission android:name="android.permission.%s" />' % izin if ac else
            '<uses-permission android:name="android.permission.%s" tools:node="remove" />' % izin)
    if desen.search(m):
        m = desen.sub(yeni, m, count=1)
    else:
        print("UYARI: manifestte %s satiri yok, atlandi." % izin)
open(manifest, "w", newline="").write(m)

# --- Info.plist (UIBackgroundModes: audio + voip) ---
p = open(plist, newline="").read()
bm = re.search(r"(<key>UIBackgroundModes</key>\s*<array>)(.*?)(</array>)", p, flags=re.S)
if not bm:
    sys.exit("Info.plist: UIBackgroundModes bulunamadi")
# audio: arka planda gorusme sesi; voip: PushKit (kapaliyken gelen cagri).
MODLAR = ["audio", "voip"]
ic = bm.group(2)
for mod_ in MODLAR:
    ic = re.sub(r"\s*<string>%s</string>" % mod_, "", ic)
if ac:
    pnl = "\r\n" if "\r\n" in p else "\n"
    ic = ic.rstrip() + "".join(pnl + "\t\t<string>%s</string>" % mod_ for mod_ in MODLAR) + pnl + "\t"
p = p[:bm.start(2)] + ic + p[bm.end(2):]

# --- Info.plist (NSMicrophoneUsageDescription) ---
# Apple 5.1.1: izin metni gercek kullanimi anlatmali. ACIK'ta softphone metni
# yazilir, markanin orijinal metni base64 olarak yorum satirinda saklanir;
# KAPALI'da birebir geri konur. Anahtar hic yoksa ACIK'ta eklenir (mikrofon
# erisiminde iOS uygulamayi kapatir), KAPALI'da isaretli eklenen silinir.
import base64
pnl = "\r\n" if "\r\n" in p else "\n"
SP_METIN = ("Uygulama içinden müşterilerinizi sesli arayabilmeniz, gelen aramaları "
            "cevaplayabilmeniz ve alanları sesle doldurabilmeniz için mikrofon erişimi gerekiyor.")
ISARET = "softphone-orijinal-mikrofon"
EKLENDI = "softphone-eklendi-mikrofon"
mk = re.search(r"(<key>NSMicrophoneUsageDescription</key>\s*<string>)(.*?)(</string>)"
               r"(\r?\n\t<!-- (%s): (\S*) -->)?" % "|".join([ISARET, EKLENDI]), p, flags=re.S)
if mk:
    # Once eski haline getir (idempotent).
    if mk.group(5) == EKLENDI:
        bas = p.rfind(pnl, 0, mk.start(1)) if p.rfind(pnl, 0, mk.start(1)) >= 0 else mk.start(1)
        p = p[:bas] + p[mk.end(4):]
        mk = None
    elif mk.group(5) == ISARET:
        orijinal = base64.b64decode(mk.group(6)).decode("utf-8")
        p = p[:mk.start(2)] + orijinal + mk.group(3) + p[mk.end(4):]
        mk = re.search(r"(<key>NSMicrophoneUsageDescription</key>\s*<string>)(.*?)(</string>)", p, flags=re.S)
if ac:
    if mk:
        kod = base64.b64encode(mk.group(2).encode("utf-8")).decode("ascii")
        p = (p[:mk.start(2)] + SP_METIN + mk.group(3) + pnl
             + "\t<!-- %s: %s -->" % (ISARET, kod) + p[mk.end(3):])
    else:
        ek = re.search(r"<key>UIBackgroundModes</key>", p)
        if not ek:
            sys.exit("Info.plist: mikrofon anahtari eklenecek yer bulunamadi")
        satir = ("<key>NSMicrophoneUsageDescription</key>" + pnl + "\t<string>" + SP_METIN
                 + "</string>" + pnl + "\t<!-- %s:  -->" % EKLENDI + pnl + "\t")
        p = p[:ek.start()] + satir + p[ek.start():]

open(plist, "w", newline="").write(p)
PY
}

bagimliliklari_guncelle() {
  flutter pub get
  if [[ $POD -eq 1 && "$(uname)" == "Darwin" && -f ios/Podfile ]]; then
    (cd ios && pod install) || echo "UYARI: pod install basarisiz; elle 'cd ios && pod install' calistir."
  fi
}

case "$KOMUT" in
  durum)
    D="$(durum_oku)"
    echo "Softphone: $D"
    durum_detay
    K="$(native_kalinti)"
    if [[ "$D" == "KAPALI" && -n "$K" ]]; then
      echo "UYARI: ayarlar kapali ama native kalinti var:$K"
      echo "       -> tool/softphone.sh kapat  (pub get + pod install yeniden calisir)"
    fi
    [[ "$D" == "KARISIK" ]] && { echo "HATA: dosyalar tutarsiz -> 'tool/softphone.sh kapat' veya 'ac' ile duzelt."; exit 2; }
    true
    ;;
  yayin-kontrol)
    D="$(durum_oku)"
    K="$(native_kalinti)"
    if [[ "$D" == "KAPALI" && -z "$K" ]]; then
      echo "OK: softphone KAPALI, native SIP/WebRTC/CallKit kalintisi yok. Build alinabilir."
      exit 0
    fi
    echo "DUR: store build'i icin softphone tamamen kapali olmali."
    echo "Softphone: $D"
    durum_detay
    [[ -n "$K" ]] && echo "  native kalinti:$K"
    echo "-> tool/softphone.sh kapat  (bilerek ACIK yayinlanacaksa: Play FGS beyani+video, App Store audio gerekcesi)"
    exit 1
    ;;
  ac|kapat)
    dosyalari_duzenle "$KOMUT"
    kayit_yaz "$KOMUT"
    bagimliliklari_guncelle
    echo
    echo "Softphone: $(durum_oku)"
    if [[ "$KOMUT" == "ac" ]]; then
      echo "Hatirlatma: store'a yollamadan once Play FGS beyani + video, App Store audio background gerekcesi."
    fi
    ;;
  *)
    echo "Kullanim: tool/softphone.sh durum | yayin-kontrol | ac | kapat [--pod-yok]"; exit 1
    ;;
esac
