#!/usr/bin/env bash
# Kumpulkan hasil build ke satu folder dist/ dengan nama yang mengandung
# versi, jenis build, dan commit — supaya tidak ada keraguan APK mana yang
# dipakai. Sekalian buat SHA256SUMS.txt untuk verifikasi penerima.
set -euo pipefail

SHA="${1:-unknown}"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST="${DIST_DIR:-$APP_DIR/../dist}"
SHORT="$(printf '%s' "$SHA" | cut -c1-7)"

cd "$APP_DIR"

if [ -f pubspec.yaml ]; then
  VERSION="$(sed -n 's/^version:[[:space:]]*\([0-9][0-9.]*\).*/\1/p' pubspec.yaml | head -1)"
fi
VERSION="${VERSION:-0.0.0}"

APK_DEBUG="build/app/outputs/flutter-apk/app-debug.apk"
APK_RELEASE="build/app/outputs/flutter-apk/app-release.apk"
AAB_RELEASE="build/app/outputs/bundle/release/app-release.aab"

if [ ! -f "$APK_DEBUG" ]; then
  echo "::error::$APK_DEBUG tidak ada — build APK debug gagal" >&2
  exit 1
fi

rm -rf "$DIST"
mkdir -p "$DIST"

cp "$APK_DEBUG" "$DIST/gocatering-$VERSION-debug-$SHORT.apk"
[ -f "$APK_RELEASE" ] && cp "$APK_RELEASE" "$DIST/gocatering-$VERSION-release-$SHORT.apk"
[ -f "$AAB_RELEASE" ] && cp "$AAB_RELEASE" "$DIST/gocatering-$VERSION-release-$SHORT.aab"

(
  cd "$DIST"
  sha256sum ./* > SHA256SUMS.txt
)

echo "Isi dist/ (versi $VERSION, commit $SHORT):"
ls -1 "$DIST"
