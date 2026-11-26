#!/usr/bin/env bash
# Marka degistirme: tek config = markalar/<kod>/marka.json. Ayrinti: tool/marka.py
#   tool/marka.sh liste | durum | kontrol [kod] | yeni <kod> | gec <kod> [--hizli]
# Bul-degistir YAPMA: kodda ve gradle/pbxproj'da marka degeri yok.
set -euo pipefail
cd "$(dirname "$0")/.."
exec python3 -I tool/marka.py "$@"
