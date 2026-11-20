# goCatering Mobile

Aplikasi mobile goCatering untuk Pembeli dan Penjual catering.

## ⚠️ LICENSE RESTRICTIONS

**This repository is PRIVATE and RESTRICTED.**

- ❌ No unauthorized downloading
- ❌ No unauthorized distribution
- ❌ No unauthorized use
- ✅ Written permission required from goCatering

See [LICENSE](LICENSE) file for complete terms.

## Architecture

This project implements **Local Storage** (Arsitektur #1):

- **SQLite Database**: Semua data disimpan lokal di perangkat
- **Image Folder**: Foto disimpan di folder aplikasi HP
- **Offline-First**: Aplikasi berfungsi penuh tanpa internet
- **Sync Ready**: Struktur siap untuk sinkronisasi backend (tahap berikutnya)

## Tech Stack

- **Flutter** - Cross-platform (Android & iOS)
- **SQLite (sqflite)** - Local database
- **path_provider** - File storage
- **image_picker** - Camera & gallery access

## Project Structure

```
gocatering-mobile/
├── lib/
│   ├── database/
│   │   └── database_helper.dart         # SQLite (7 tabel, v2) + upsert paket
│   ├── models/
│   │   ├── models.dart                  # Owner, Shop, Package, Order, Customer, Session
│   │   └── package_draft.dart           # Validasi impor batch (murni, tanpa IO)
│   ├── services/
│   │   └── image_storage_service.dart   # Simpan/baca gambar per restoran
│   ├── screens/
│   │   ├── seller_reg_screen.dart       # Daftar penjual 2 halaman (+3 foto)
│   │   ├── seller_home_screen.dart      # Dashboard penjual & daftar toko
│   │   ├── shop_packages_screen.dart    # Kelola paket + foto paket
│   │   └── batch_packages_screen.dart   # Impor sampai 12 foto sekaligus
│   ├── widgets/
│   │   ├── foto_field.dart              # Ketuk → kamera/galeri → simpan ke folder
│   │   └── stored_image.dart            # Baca gambar dari path relatif di SQLite
│   └── main.dart                        # Splash, login penjual, rute
├── scripts/
│   ├── enable-release-signing.sh        # Sambungkan key.properties ke Gradle
│   ├── collect-artifacts.sh             # Kumpulkan APK/AAB + SHA256SUMS
│   └── publish-release.sh               # GitHub Release + tempel LICENSE
├── test/
│   ├── image_storage_test.dart          # Uji pembentuk path & format ukuran
│   └── batch_packages_test.dart         # Uji nama/harga wajib & batas batch
├── android/                             # dibuat oleh CI / `flutter create .`
├── ios/                                 # dibuat oleh `flutter create .`
├── pubspec.yaml
└── LICENSE
```

## Image Storage (Fase 1 — selesai)

Gambar **tidak** disimpan sebagai BLOB di SQLite. Kolom `photo`, `logo`, dan
`img` hanya berisi *path relatif*; file aslinya hidup di folder aplikasi,
terpisah per restoran:

```
<Documents>/gocatering/
├── shops/
│   ├── 100234/
│   │   ├── logo.jpg              # logo toko        → shops.logo
│   │   ├── storefront.jpg        # foto restoran    → shops.photo
│   │   ├── pkg_P1700000000.jpg   # foto paket       → packages.img
│   │   └── proof_ORD123.jpg      # bukti pengambilan→ orders
│   └── 100235/ ...
└── owners/
    └── O1700000000000/profile.jpg                   → owners.photo
```

Yang tersimpan di database, contoh:

| kolom    | nilai                       |
|----------|-----------------------------|
| logo     | `shops/100234/logo.jpg`     |
| img      | `shops/100234/pkg_P17.jpg`  |
| photo    | `owners/O17000/profile.jpg` |

Sifat yang dikejar:

- **Satu folder per restoran** — gampang diaudit, gampang dihapus
  (`ImageStorageService.deleteShopFolder(shopId)`), dan siap disalin apa adanya
  ke Google Drive pada Fase 2.
- **Ringan untuk SQLite** — database tetap kecil meski foto banyak.
- **Kompres otomatis** — `image_picker` dipanggil dengan
  `maxWidth/maxHeight: 1280, imageQuality: 82`, jadi hasil kamera (4–8 MB)
  turun jadi ±200–400 KB tanpa dependensi tambahan.
- **Aman untuk uninstall** — semua file ada di sandbox aplikasi, ikut terhapus
  saat aplikasi di-uninstall.
- **ID dibuat lebih dulu** — `ownerKey` dan `shopId` dihasilkan saat halaman
  registrasi dibuka, sehingga nama folder sudah pasti sebelum foto pertama
  dipilih.

### API singkat

```dart
final store = ImageStorageService.instance;

// simpan → mengembalikan path relatif untuk ditulis ke SQLite
final path = await store.savePackageImage(
  shopId: '100234', packageId: 'P1700000000', sourcePath: picked.path);
await db.setPackageImg('P1700000000', path);

// baca
final file = await store.file(path);          // File? (null bila belum ada)

// ukuran
final bytes = await store.shopBytes('100234'); // untuk info "Gambar di HP: 12.4 MB"
```

### Catatan izin platform

Jalankan `flutter create .` di folder ini untuk men-generate folder `android/`
dan `ios/`, lalu:

- **Android** — tidak perlu izin runtime tambahan; `image_picker` memakai
  intent kamera/galeri bawaan. Tambahkan hanya bila nanti butuh kamera manual.
- **iOS** — isi `ios/Runner/Info.plist`:
  `NSCameraUsageDescription` dan `NSPhotoLibraryUsageDescription`
  (mis. "goCatering memakai kamera untuk foto paket menu Anda.").

## Impor Banyak Foto Sekali Gusur (Fase 1b — selesai)

Tombol **Tambah Paket** membuka dua pilihan:

| Cara | Alur | Cocok untuk |
|------|------|-------------|
| Satu paket | kamera / galeri → isi nama & harga → simpan | menambah 1 menu |
| Banyak foto sekaligus | pilih sampai **12** foto galeri → tabel nama & harga → simpan semua | mengisi katalog pertama kali |

Satu foto = satu paket (bukan satu paket dengan banyak foto), supaya tidak
perlu mengubah skema `packages`. Kamera tidak bisa memilih banyak berkas, jadi
mode ini memakai galeri (`pickMultiImage`).

Aturan yang dijaga: **nama dan harga wajib diisi**, karena pembeli harus tahu
apa yang ia beli. Tampilan impornya (`screens/batch_packages_screen.dart`):

- tiap baris menampilkan foto + kolom **Nama \***, **Harga/pax \***, dan
  **Isi paket** (opsional);
- tombol *Simpan* tetap mati dan bilah atas menyebutkan jumlahnya, mis.
  "Lengkapi 2 nama & 1 harga — pembeli harus tahu isi dan harganya.";
- memilih lebih dari 12 foto dipotong otomatis (`takeBatch`);
- id paket dibuat per posisi — `P{timestamp}-{urutan}` — supaya tidak saling
  menimpa (`packageIdFor`);
- berkas baru disalin ke `shops/{shopId}/pkg_{id}.jpg` **setelah** validasi
  lolos, karena path hasil `image_picker` bersifat sementara.

Logika validasi, pemotong batch, `parsePrice`, dan `formatRupiah` hidup di
`lib/models/package_draft.dart` tanpa IO, sehingga bisa diuji murni di
`test/batch_packages_test.dart`.


## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode
- Device or emulator

### Installation

```bash
# Clone repository (with permission only)
git clone [repository-url]

# Navigate to project
cd gocatering-mobile

# Generate folder android/ & ios/ (hanya sekali, karena repo menyimpan lib/ saja)
flutter create . --org id.gocatering --project-name gocatering_mobile

# Install dependencies
flutter pub get

# Analisis statis + unit test
flutter analyze
flutter test

# Run app
flutter run
```

Alur uji Fase 1 di perangkat: **Daftar sebagai penjual** → isi data diri →
unggah 3 foto di halaman 2 → simpan → tambah paket beserta fotonya. Buka
folder aplikasi lewat Device File Explorer (Android) dan pastikan file muncul
di `.../app_flutter/gocatering/shops/{id}/`, sementara kolom `logo`/`img` di
`gocatering.db` hanya berisi path relatifnya.

## Build APK (GitHub Actions)

Repo ini hanya menyimpan sumbernya (`lib/`, `test/`, `pubspec.yaml`). Kerangka
`android/` **dibangkitkan saat build**, sehingga tidak ada berkas Gradle yang
beredar. Alur build ada di `.github/workflows/build-apk.yml` di akar repo:

```
push tag v* / Run workflow manual
   └─ gerbang lisensi  : root LICENSE + LICENSE aplikasi harus ada & utuh
   └─ flutter create   : bangkitkan android/ di runner
   └─ dart analyze     : gagal bila ada error/warning
   └─ flutter test     : unit test path gambar & validasi batch
   └─ flutter build apk --debug      → artifact + Release (terpasang, siap di HP)
   └─ flutter build appbundle (ops.) → hanya bila secret keystore diisi
```

Cara memicu: **Actions → Build Android APK → Run workflow**, atau
`git tag v0.1.0 && git push origin v0.1.0`. Hasilnya berupa artifact
`gocatering-apk-debug` dan, kalau Release diterbitkan, berkas APK yang **sudah
menempel LICENSE** + `SHA256SUMS.txt`.

Supaya APK rilis Play Store ikut terbit, isi secret di
**Settings → Secrets and variables → Actions**:

| Secret | Isi |
|--------|-----|
| `RELEASE_KEYSTORE_BASE64` | `base64 -w0 gocatering.jks` |
| `RELEASE_KEYSTORE_PASSWORD` | sandi keystore |
| `RELEASE_KEY_PASSWORD` | sandi kunci |
| `RELEASE_KEY_ALIAS` | nama alias |

`scripts/enable-release-signing.sh` menyambungkan key.properties ke Gradle;
kalau secret-nya kosong, build tetap jalan dengan signing debug.

> ⚠️ **Artifact dan Release pada repo PUBLIC dapat diunduh siapa saja** —
> termasuk oleh orang yang tidak diberi izin. Selama klausul "tidak boleh
> diunduh tanpa izin tertulis" berlaku, jalankan workflow ini di repo privat
> (atau repo privat terpisah untuk aplikasi mobile), bukan di repo yang
> tampilannya dipublikasikan lewat GitHub Pages.

## Build manual di Android Studio (opsi lain)

```bash
cd gocatering-mobile
flutter create . --org id.gocatering --project-name gocatering_mobile --platforms=android
flutter pub get && flutter test && flutter build apk --debug
```

APK debug ada di `build/app/outputs/flutter-apk/app-debug.apk`.


## Database Schema

### Tables

1. **owners** - Data penjual/pemilik
2. **shops** - Data toko/restoran
3. **packages** - Paket menu per toko
4. **orders** - Pesanan pembeli
5. **customers** - Daftar pelanggan per toko
6. **menu_off** - Paket yang di-off-kan
7. **user_session** - Sesi login aktif

## Features (Local Storage Phase)

### Penjual (sudah jalan di Fase 1)
- Registrasi penjual 2 halaman + foto penjual, logo, dan foto restoran
- Login penjual (divalidasi dari tabel `owners`), sesi tersimpan di
  `user_session` dan dipulihkan saat aplikasi dibuka
- Dashboard: kartu penjual (foto profil) + daftar tokonya
- Kelola paket: tambah/ubah paket, ON/OFF menu, foto per paket
- Impor katalog: sampai 12 foto galeri sekaligus, tiap foto jadi satu paket
  (nama & harga wajib sebelum bisa disimpan)
- Indikator pemakaian penyimpanan per restoran

### Pembeli (fase berikutnya)
- Browse toko dan paket
- Checkout tanpa login (guest)
- Riwayat pesanan lokal

## Next Steps (Phase 2)

- **Backup otomatis ke Google Drive per restoran** — struktur folder
  `gocatering/shops/{shopId}/` sudah dibuat agar bisa disalin apa adanya.
  Yang perlu ditambahkan: OAuth login Gmail restoran (`google_sign_in`),
  unggah folder via Google Drive API, dan kolom sinkron di SQLite
  (`syncedAt`, `driveId`) untuk tahu file mana yang belum terunggah.
- Backend cloud + sinkronisasi dua arah
- Alur pembeli (browse, troli, checkout guest)
- Web admin dashboard

## Contact

For permission to use or distribute this software:

**goCatering**  
Email: contact@gocatering.id

---

**Copyright © 2026 goCatering. All rights reserved.**
