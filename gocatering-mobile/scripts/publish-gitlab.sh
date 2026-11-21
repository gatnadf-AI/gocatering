#!/usr/bin/env bash
# Salin hasil build ke project GitLab sebagai generic package + Release.
#
# Mesin build tetap GitHub Actions (menit gratis, tanpa duplikasi pipeline);
# GitLab hanya menampung berkas supaya pemegang akses ke sana bisa mengunduh
# APK/AAB yang sama. Pola ini terbukti: berkas diunggah lewat
#   PUT /projects/:id/packages/generic/:pkg/:version/:file
# lalu ditautkan ke release. Endpoint aset release yang biasa (POST
# /projects/:id/uploads) menolak berkas besar — HTTP 413 pada 145 MB — jadi
# paket generik adalah satu-satunya jalan untuk APK.
#
# Perlu: GITLAB_TOKEN ber-scope api. Tanpa token itu langkah ini dilewati.
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$APP_DIR/.." && pwd)"
DIST="${DIST_DIR:-$ROOT/dist}"

GITLAB_API="${GITLAB_API:-https://gitlab.com/api/v4}"
GITLAB_WEB="${GITLAB_WEB:-https://gitlab.com}"
GITLAB_PROJECT="${GITLAB_PROJECT:-89262296}"
GITLAB_PATH="${GITLAB_PATH:-clr657/gocatering}"
GITLAB_PKG="${GITLAB_PKG:-gocatering-apk}"
# Rilis GitLab harus menunjuk tag GitLab. SHA commit GitHub tidak ada di sana,
# jadi default-nya ujung branch main GitLab; ubah lewat GITLAB_REF bila perlu.
GITLAB_REF="${GITLAB_REF:-main}"

BODY="$(mktemp)"
trap 'rm -f "$BODY"' EXIT

# gl <METODE> <url> [args curl...]  ->  $CODE = status, $BODY = respons.
# Header token selalu ditempel di sini supaya tidak ada panggilan yang lupa.
gl() {
  local method="$1"; shift
  case "$method" in
    HEAD) CODE="$(curl -sS --head -o /dev/null -D "$BODY" -w '%{http_code}' \
                    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$@")" ;;
    *)    CODE="$(curl -sS -o "$BODY" -w '%{http_code}' -X "$method" \
                    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$@")" ;;
  esac
}

ok() { case "$CODE" in 2*) return 0 ;; *) return 1 ;; esac; }

# json_escape_str: backslash, tanda kutip, lalu baris baru -> \n (urutan penting).
json_escape_str() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\r' \
    | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'
}

# ------------------------------------------------------------------ prasyarat --
if [ -z "${GITLAB_TOKEN:-}" ]; then
  echo "::notice::GITLAB_TOKEN kosong - penyalinan ke GitLab dilewati"
  exit 0
fi

if [ ! -d "$DIST" ]; then
  echo "::error::folder dist hasil build tidak ada ($DIST) - jalankan collect-artifacts.sh dulu" >&2
  exit 1
fi

SHA="${GITHUB_SHA:-unknown}"
SHORT="$(printf '%s' "$SHA" | cut -c1-7)"
if [ -f "$APP_DIR/pubspec.yaml" ]; then
  VERSION="$(sed -n 's/^version:[[:space:]]*\([0-9][0-9.]*\).*/\1/p' "$APP_DIR/pubspec.yaml" | head -1)"
fi
VERSION="${VERSION:-0.0.0}"

# Nama tag di GitLab meniru perilakunya di GitHub: tag v* dipakai apa adanya,
# build manual/diagnostik memakai build-<sha> supaya tidak menimpa rilis resmi.
REF="${GITHUB_REF_NAME:-}"
case "$REF" in
  v*) TAG="$REF" ;;
  *)  TAG="build-$SHORT" ;;
esac

# Segmen "versi" paket memakai nama tag, bukan VERSION dari pubspec. Tiap build
# menghasilkan berkas bernama sama (SHA256SUMS.txt, LICENSE.txt), jadi tanpa
# pembeda ini build diagnostik berikutnya menimpa checksum rilis resmi.
PKGVER="$TAG"

# LICENSE wajib menempel pada rilis: klausulnya harus sampai bersamaan dengan
# aplikasinya. publish-release.sh sudah menyalinnya ke dist/, tapi kalau skrip
# itu belum jalan kita salin sendiri.
[ -f "$DIST/LICENSE.txt" ] || { [ -s "$ROOT/LICENSE" ] && cp "$ROOT/LICENSE" "$DIST/LICENSE.txt"; }
[ -f "$DIST/LICENSE-mobile.txt" ] || { [ -s "$APP_DIR/LICENSE" ] && cp "$APP_DIR/LICENSE" "$DIST/LICENSE-mobile.txt"; }

FILES=()
for f in "$DIST"/*.apk "$DIST"/*.aab "$DIST"/SHA256SUMS.txt "$DIST"/LICENSE*.txt; do
  [ -e "$f" ] && FILES+=("$f")
done
if [ "${#FILES[@]}" -eq 0 ]; then
  echo "::error::tidak ada berkas untuk disalin dari $DIST" >&2
  exit 1
fi

echo "Menyalin ${#FILES[@]} berkas ke $GITLAB_PATH (paket $GITLAB_PKG/$PKGVER)"

# ---------------------------------------------------------------- tag GitLab ---
gl GET "$GITLAB_API/projects/$GITLAB_PROJECT/repository/tags/$TAG"
if ok; then
  echo "tag $TAG sudah ada di GitLab - dipakai ulang"
else
  gl POST "$GITLAB_API/projects/$GITLAB_PROJECT/repository/tags" \
     --data-urlencode "tag_name=$TAG" --data-urlencode "ref=$GITLAB_REF"
  if ! ok; then
    echo "::error::tag $TAG gagal dibuat di GitLab (HTTP $CODE): $(head -c 300 "$BODY")" >&2
    exit 1
  fi
  echo "tag $TAG dibuat di GitLab menunjuk $GITLAB_REF"
fi

# -------------------------------------------------------------------- unggah ---
LINKS=""
for f in "${FILES[@]}"; do
  name="$(basename "$f")"
  gl PUT --upload-file "$f" \
     "$GITLAB_API/projects/$GITLAB_PROJECT/packages/generic/$GITLAB_PKG/$PKGVER/$name"
  if ! ok; then
    echo "::error::unggah $name gagal (HTTP $CODE): $(head -c 300 "$BODY")" >&2
    exit 1
  fi
  url="$GITLAB_API/projects/$GITLAB_PROJECT/packages/generic/$GITLAB_PKG/$PKGVER/$name"
  [ -n "$LINKS" ] && LINKS="$LINKS,"
  LINKS="$LINKS{\"name\":\"$(json_escape_str "$name")\",\"url\":\"$url\"}"
done

# ------------------------------------------------------------------ deskripsi --
NOTES="$DIST/gitlab-release-notes.md"
{
  echo "## goCatering $VERSION - build $SHORT"
  echo ""
  echo "**Lisensi berlaku untuk berkas-berkas di rilis ini.**"
  echo ""
  echo "Aplikasi dan kode sumber goCatering adalah milik goCatering. Mengunduh,"
  echo "menyalin, menyebarluaskan, memodifikasi, atau memakai berkas ini tanpa izin"
  echo "tertulis dari goCatering **tidak diizinkan**. Lihat \`LICENSE.txt\` dan"
  echo "\`LICENSE-mobile.txt\` pada rilis ini."
  echo ""
  echo "Kontak izin: **contact@gocatering.id**"
  echo ""
  echo "---"
  echo ""
  echo "### Isi rilis"
  echo ""
  for f in "${FILES[@]}"; do
    printf -- '- `%s` (%s byte) · SHA-256 `%s`\n' \
      "$(basename "$f")" "$(wc -c < "$f" | tr -d ' ')" \
      "$( (cd "$DIST" && sha256sum "$(basename "$f")") | cut -d' ' -f1)"
  done
  echo ""
  echo "### Verifikasi"
  echo ""
  echo '```'
  echo "sha256sum -c SHA256SUMS.txt"
  echo '```'
  echo ""
  echo "Dibangun oleh GitHub Actions (\`.github/workflows/build-apk.yml\`) dari"
  echo "commit \`$SHA\`, lalu disalin ke sini oleh \`scripts/publish-gitlab.sh\`."
} > "$NOTES"

PAYLOAD="{\"tag_name\":\"$TAG\",\"name\":\"goCatering $VERSION (build $SHORT)\",\"description\":\"$(json_escape_str "$(cat "$NOTES")")\",\"assets\":{\"links\":[$LINKS]}}"

# --------------------------------------------------------------- rilis GitLab --
# Release lama dihapus lalu dibuat ulang supaya daftar asetnya persis seperti
# hasil build terbaru (menambah tautan tidak mengganti tautan lama).
gl GET "$GITLAB_API/projects/$GITLAB_PROJECT/releases/$TAG"
if ok; then
  echo "rilis $TAG sudah ada - diganti"
  gl DELETE "$GITLAB_API/projects/$GITLAB_PROJECT/releases/$TAG"
  ok || echo "::warning::rilis lama $TAG tidak terhapus (HTTP $CODE) - $(head -c 200 "$BODY")"
fi

gl POST "$GITLAB_API/projects/$GITLAB_PROJECT/releases" \
   --header "Content-Type: application/json" --data "$PAYLOAD"
if ! ok; then
  echo "::error::rilis $TAG gagal dibuat (HTTP $CODE): $(head -c 300 "$BODY")" >&2
  exit 1
fi

# ---------------------------------------------------------------- verifikasi ---
FAIL=0
for f in "${FILES[@]}"; do
  name="$(basename "$f")"
  size="$(wc -c < "$f" | tr -d ' ')"
  gl HEAD "$GITLAB_API/projects/$GITLAB_PROJECT/packages/generic/$GITLAB_PKG/$PKGVER/$name"
  remote="$(grep -i -a '^content-length:' "$BODY" | tr -dc '0-9')"
  if [ "$CODE" = "200" ] && [ "$remote" = "$size" ]; then
    printf '  OK  %-44s %s byte\n' "$name" "$remote"
  else
    printf '  GAG %-44s HTTP %s · remote=%s lokal=%s\n' "$name" "$CODE" "${remote:-?}" "$size"
    FAIL=1
  fi
done
if [ "$FAIL" -ne 0 ]; then
  echo "::error::verifikasi aset GitLab gagal" >&2
  exit 1
fi

echo "Rilis GitLab: $GITLAB_WEB/$GITLAB_PATH/-/releases/$TAG"
echo "Paket:        $GITLAB_WEB/$GITLAB_PATH/-/packages"
