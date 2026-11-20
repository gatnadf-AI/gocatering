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
│   │   └── database_helper.dart    # SQLite operations
│   ├── models/                      # Data models
│   ├── screens/                     # UI screens
│   ├── widgets/                     # Reusable widgets
│   └── main.dart                    # App entry point
├── android/                         # Android-specific
├── ios/                            # iOS-specific
├── pubspec.yaml                    # Dependencies
└── LICENSE                         # Restricted license
```

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

# Install dependencies
flutter pub get

# Run app
flutter run
```

### Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

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

### Pembeli
- Browse toko dan paket
- Checkout tanpa login (guest)
- Riwayat pesanan lokal
- Profil pembeli

### Penjual
- Registrasi penjual & toko
- Dashboard dengan widget
- Kelola pesanan (status flow)
- Daftar pelanggan
- Menu on/off

## Next Steps (Phase 2)

- Backend cloud integration
- Sync mechanism
- Object storage for images
- Web admin dashboard

## Contact

For permission to use or distribute this software:

**goCatering**  
Email: contact@gocatering.id

---

**Copyright © 2026 goCatering. All rights reserved.**
