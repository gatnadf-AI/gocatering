#!/usr/bin/env bash
# Terbitkan APK/AAB sebagai GitHub Release, dengan LICENSE ikut ditempel dan
# klausul pembatas ditulis paling atas di catatan rilis.
#
# Perlu: GH_TOKEN (secrets.GITHUB_TOKEN) + permissions contents: write.
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$APP_DIR/.." && pwd)"
DIST="${DIST_DIR:-$ROOT/dist}"
SHA="${GITHUB_SHA:-unknown}"
SHORT="$(printf '%s' "$SHA" | cut -c1-7)"
REPO="${GITHUB_REPOSITORY:-}"

if [ ! -d "$DIST" ]; then
  echo "::error::$DIST tidak ada — jalankan collect-artifacts.sh dulu" >&2
  exit 1
fi

REF="${GITHUB_REF_NAME:-}"
case "$REF" in
  v*) TAG="$REF"; PRERELEASE=false ;;
  *)  TAG="build-$SHORT"; PRERELEASE=true ;;
esac

if [ -f "$APP_DIR/pubspec.yaml" ]; then
  VERSION="$(sed -n 's/^version:[[:space:]]*\([0-9][0-9.]*\).*/\1/p' "$APP_DIR/pubspec.yaml" | head -1)"
fi
VERSION="${VERSION:-0.0.0}"

NOTES="$DIST/release-notes.md"
{
  echo "## goCatering $VERSION — build $SHORT"
  echo ""
  echo "**Lisensi berlaku untuk berkas-berkas di rilis ini.**"
  echo ""
  echo "Aplikasi dan kode sumber goCatering adalah milik goCatering. Mengunduh,"
  echo "menyalin, menyebarluaskan, memodifikasi, atau memakai berkas ini tanpa izin"
  echo "tertulis dari goCatering **tidak diizinkan**. See \`LICENSE.txt\` and"
  echo "\`LICENSE-mobile.txt\` attached to this release."
  echo ""
  echo "Kontak izin: **contact@gocatering.id**"
  echo ""
  echo "---"
  echo ""
  echo "### Isi rilis"
  echo ""
  if ls "$DIST"/*.apk "$DIST"/*.aab >/dev/null 2>&1; then
    ls -1 "$DIST" | grep -E '\.(apk|aab)$' | sed 's/^/- /'
  else
    echo "- (tidak ada berkas aplikasi)"
  fi
  echo "- \`SHA256SUMS.txt\` — cek keutuhan berkas"
  echo ""
  echo "### Memasang APK debug di HP"
  echo ""
  echo "1. Buka **Setelan → Keamanan → Instal aplikasi tidak dikenal** untuk browser"
  echo "   atau pengelola berkas yang dipakai (sekali saja)."
  echo "2. Unduh berkas \`.apk\` bertanda \`-debug-\` lalu buka berkasnya."
  echo "3. APK debug hanya untuk uji coba. Untuk Google Play yang dibutuhkan adalah"
  echo "   berkas \`.aab\` hasil build dengan keystore rilis (secret"
  echo "   \`RELEASE_KEYSTORE_BASE64\` dan tiga temannya di Settings → Secrets)."
  echo ""
  echo "### Verifikasi"
  echo ""
  echo '```'
  echo "sha256sum -c SHA256SUMS.txt"
  echo '```'
  echo ""
  echo "Commit: \`$SHA\` · Branch/tag: \`$REF\` · Dibangun oleh GitHub Actions"
  echo "(\`.github/workflows/build-apk.yml\`)."
} > "$NOTES"

# LICENSE disalin ke dist dengan nama tegas: `gh release upload` tidak
# mendukung sintaks penggantian nama `berkas#label`, hanya `gh release create`.
[ -f "$ROOT/LICENSE" ] && cp "$ROOT/LICENSE" "$DIST/LICENSE.txt"
[ -f "$APP_DIR/LICENSE" ] && cp "$APP_DIR/LICENSE" "$DIST/LICENSE-mobile.txt"

ASSETS=()
for f in "$DIST"/*.apk "$DIST"/*.aab "$DIST"/SHA256SUMS.txt "$DIST"/LICENSE*.txt "$NOTES"; do
  [ -e "$f" ] && ASSETS+=("$f")
done

if [ "${#ASSETS[@]}" -eq 0 ]; then
  echo "::error::tidak ada aset untuk diterbitkan" >&2
  exit 1
fi

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "Release $TAG sudah ada — menimpa asetnya."
  gh release upload "$TAG" --clobber "${ASSETS[@]}"
else
  gh release create "$TAG" \
    --title "goCatering $VERSION (build $SHORT)" \
    --notes-file "$NOTES" \
    --prerelease="$PRERELEASE" \
    --target "$SHA" \
    "${ASSETS[@]}"
fi

echo "Rilis $TAG terbit di https://github.com/$REPO/releases/tag/$TAG"
