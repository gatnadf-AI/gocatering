import 'package:flutter_test/flutter_test.dart';
import 'package:gocatering_mobile/services/image_storage_service.dart';

/// Fase 1 hanya menguji logika murni (pembentuk path & format ukuran).
/// Bagian IO (copy file ke folder) diuji di perangkat karena path_provider
/// tidak tersedia di lingkungan unit test.
void main() {
  group('ImageStorageService.relativePath', () {
    test('logo toko memakai pola shops/{shopId}/logo.jpg', () {
      expect(
        ImageStorageService.relativePath(
            scope: 'shops', id: '100234', kind: 'logo'),
        'shops/100234/logo.jpg',
      );
    });

    test('foto paket masuk ke folder tokonya sendiri', () {
      expect(
        ImageStorageService.relativePath(
            scope: 'shops', id: '100234', kind: 'pkg_P1700000000'),
        'shops/100234/pkg_P1700000000.jpg',
      );
    });

    test('foto penjual dipisah dari folder toko', () {
      expect(
        ImageStorageService.relativePath(
            scope: 'owners', id: 'O1700000000000', kind: 'profile'),
        'owners/O1700000000000/profile.jpg',
      );
    });

    test('selalu memakai garis miring (bukan backslash Windows)', () {
      final path = ImageStorageService.relativePath(
          scope: 'shops', id: '9', kind: 'storefront');
      expect(path.contains('\\'), isFalse);
    });
  });

  group('ImageStorageService.formatSize', () {
    test('bawah 1 KB tampil dalam byte', () {
      expect(ImageStorageService.formatSize(512), '512 B');
    });

    test('ratusan kilobyte', () {
      expect(ImageStorageService.formatSize(1024 * 350), '350.0 KB');
    });

    test('gambar hasil kompresi 1280px masuk ordo megabyte', () {
      expect(ImageStorageService.formatSize(1024 * 1024 * 2), '2.0 MB');
    });
  });
}
