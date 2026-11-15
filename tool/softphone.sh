#!/usr/bin/env bash
# SIP softphone modulunu (packages/rc_softphone) ac / kapat / durum.
#
#   tool/softphone.sh durum
#   tool/softphone.sh ac       [--pod-yok]
#   tool/softphone.sh kapat    [--pod-yok]
#
# Dokunulan dosyalar (hepsi marka bazli lokal dosyalar, bu yuzden marka
# switch'ten sonra o markada istenen duruma gore bir kez calistir):
#   pubspec.yaml                          rc_softphone path bagimliligi
#   lib/telefon/softphone_kayit.dart      KapaliSoftphone <-> SipService adaptoru
#   android/app/src/main/AndroidManifest.xml
#                                         5 FGS/telefon izni: tools:node="remove" <-> normal
#   ios/Runner/Info.plist                 UIBackgroundModes: audio ekle/cikar
# Sonra: flutter pub get + (iOS) pod install.
#
# KAPALI = native webrtc/callkit paketleri build'e hic girmez (Play FGS beyani
# ve Apple 2.5.4 / VoIP gerekcesi gerekmez). ACIK = store'a yollarken Play
# Console'da FGS (microphone/phone_call) beyani + calisan ozellik videosu,
# App Store'da arka plan audio gerekcesi gerekir.
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

durum_oku() {
  if grep -q "^  rc_softphone:" "$PUBSPEC"; then echo "ACIK"; else echo "KAPALI"; fi
}

kayit_yaz() {
  if [[ "$1" == "ac" ]]; then
    cat > "$KAYIT" <<'DART'
// OTOMATIK URETILIR — elle duzenleme, `tool/softphone.sh ac|kapat` kullan.
// Durum: ACIK (rc_softphone paketi pubspec'te, native SIP/WebRTC/CallKit build'de).
import 'package:rc_softphone/rc_softphone.dart';

import 'softphone.dart';

Softphone softphoneOlustur() => _SipSoftphone();

class _SipSoftphone implements Softphone {
  @override
  bool get aktif => true;

  @override
  Future<void> baslat({required String dahili, required String dahiliSifre}) =>
      SipService.instance.init(dahili: dahili, dahiliSifre: dahiliSifre);

  @override
  Future<void> kapat() => SipService.instance.kapat();

  @override
  Future<bool> ara(String hedef) => SipService.instance.cagriBaslat(hedef);
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

# --- Info.plist (UIBackgroundModes: audio) ---
p = open(plist, newline="").read()
bm = re.search(r"(<key>UIBackgroundModes</key>\s*<array>)(.*?)(</array>)", p, flags=re.S)
if not bm:
    sys.exit("Info.plist: UIBackgroundModes bulunamadi")
ic = re.sub(r"\s*<string>audio</string>", "", bm.group(2))
if ac:
    pnl = "\r\n" if "\r\n" in p else "\n"
    ic = ic.rstrip() + pnl + "\t\t<string>audio</string>" + pnl + "\t"
p = p[:bm.start(2)] + ic + p[bm.end(2):]
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
    echo "Softphone: $(durum_oku)"
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
    echo "Kullanim: tool/softphone.sh durum | ac | kapat [--pod-yok]"; exit 1
    ;;
esac
