#!/usr/bin/env bash
# Sambungkan signing rilis ke modul Android tanpa mengedit templat aslinya.
#
# Cara kerjanya: menambahkan satu blok `android { ... }` lagi di akhir
# build.gradle(.kts) milik app. Gradle membolehkan blok konfigurasi yang sama
# ditulis berulang, jadi blok ini cukup menimpa signingConfig build "release".
#
# Aman untuk build tanpa kunci: langkah ini hanya jalan kalau workflow menyetel
# RELEASE_SIGNING=1 (yaitu saat secret keystore terisi). Tanpa itu APK debug
# memakai signing bawaan Flutter dan berkas gradle tetap seperti templat.
#
# Jangan pakai `java.util.Properties()` di berkas .kts: nama `java` di skrip
# modul Gradle menunjuk ekstensi plugin Java, jadi kompilasi skrip gagal
# ("Unresolved reference 'util'"). Karena itu kunci dibaca manual lewat
# readLines(). Belum teruji dengan keystore sungguhan — baru teruji bahwa
# dilewati tanpa kunci.
set -euo pipefail

APP_GRADLE_KTS="android/app/build.gradle.kts"
APP_GRADLE_GROOVY="android/app/build.gradle"
MARKER="goCatering: signing rilis"

if [ -z "${RELEASE_SIGNING:-}" ]; then
  echo "RELEASE_SIGNING tidak diset -> signing rilis dilewati (APK debug memakai signing bawaan Flutter)"
  exit 0
fi

if [ -f "$APP_GRADLE_KTS" ]; then
  target="$APP_GRADLE_KTS"
  flavor=kts
elif [ -f "$APP_GRADLE_GROOVY" ]; then
  target="$APP_GRADLE_GROOVY"
  flavor=groovy
else
  echo "::error::build.gradle app tidak ditemukan — langkah scaffolding belum jalan?" >&2
  exit 1
fi

if grep -q "$MARKER" "$target"; then
  echo "signing rilis sudah tersambung di $target (lewati)"
  exit 0
fi

{
  echo ""
  echo "// >>> $MARKER (dibaca dari android/key.properties bila ada)"
  if [ "$flavor" = "kts" ]; then
    cat <<'BLOCK'
val gcKeyFile = rootProject.file("key.properties")
val gcProps: Map<String, String> =
    if (gcKeyFile.exists()) {
        gcKeyFile.readLines()
            .map { it.trim() }
            .filter { it.isNotEmpty() && !it.startsWith("#") && it.contains("=") }
            .associate { it.substringBefore("=") to it.substringAfter("=") }
    } else {
        emptyMap()
    }
val gcStoreFile = gcProps["storeFile"]

if (gcStoreFile != null) {
    android {
        signingConfigs {
            register("gocatering") {
                keyAlias = gcProps["keyAlias"]
                keyPassword = gcProps["keyPassword"]
                storePassword = gcProps["storePassword"]
                storeFile = file(gcStoreFile)
            }
        }
        buildTypes {
            named("release") {
                signingConfig = signingConfigs.getByName("gocatering")
            }
        }
    }
}
BLOCK
  else
    cat <<'BLOCK'
def gcProps = new Properties()
def gcPropsFile = rootProject.file("key.properties")
if (gcPropsFile.exists()) {
    gcPropsFile.withInputStream { gcProps.load(it) }
}

android {
    signingConfigs {
        gocatering {
            if (gcProps.getProperty("storeFile")) {
                keyAlias = gcProps.getProperty("keyAlias")
                keyPassword = gcProps.getProperty("keyPassword")
                storePassword = gcProps.getProperty("storePassword")
                storeFile = file(gcProps.getProperty("storeFile"))
            }
        }
    }
    buildTypes {
        release {
            if (gcProps.getProperty("storeFile")) {
                signingConfig = signingConfigs.gocatering
            }
        }
    }
}
BLOCK
  fi
  echo "// <<< akhir $MARKER"
} >> "$target"

echo "signing rilis disambungkan ke $target ($flavor)"
