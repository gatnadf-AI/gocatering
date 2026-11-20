#!/usr/bin/env bash
# Sambungkan signing rilis ke modul Android tanpa mengedit templat aslinya.
#
# Cara kerjanya: menambahkan satu blok `android { ... }` lagi di akhir
# build.gradle(.kts) milik app. Gradle membolehkan blok konfigurasi yang sama
# ditulis berulang, jadi blok ini cukup menimpa signingConfig build "release".
#
# Aman untuk build tanpa kunci: selama android/key.properties belum ada,
# semuanya dilewati dan Flutter memakai signing debug seperti biasa.
set -euo pipefail

APP_GRADLE_KTS="android/app/build.gradle.kts"
APP_GRADLE_GROOVY="android/app/build.gradle"
MARKER="goCatering: signing rilis"

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
val gcProps = java.util.Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val gcHasKeys = gcProps.getProperty("storeFile") != null

android {
    signingConfigs {
        create("gocatering") {
            if (gcHasKeys) {
                keyAlias = gcProps.getProperty("keyAlias")
                keyPassword = gcProps.getProperty("keyPassword")
                storePassword = gcProps.getProperty("storePassword")
                storeFile = file(gcProps.getProperty("storeFile"))
            }
        }
    }
    buildTypes {
        getByName("release") {
            if (gcHasKeys) {
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
