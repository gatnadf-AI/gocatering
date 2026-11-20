import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Tempat gambar disimpan:
///
///   <Documents>/gocatering/
///     ├── shops/{shopId}/logo.jpg
///     ├── shops/{shopId}/storefront.jpg
///     ├── shops/{shopId}/pkg_<id>.jpg
///     └── owners/{ownerKey}/profile.jpg
///
/// SQLite hanya menyimpan *relative path* (mis. `shops/100234/logo.jpg`),
/// jadi database tetap ringan dan folder tiap restoran terpisah rapi.
/// Phase 2 (backup Google Drive) tinggal menyalin folder ini apa adanya.
class ImageStorageService {
  ImageStorageService._internal();

  static final ImageStorageService instance = ImageStorageService._internal();

  factory ImageStorageService() => instance;

  Directory? _root;

  /// Nama folder induk di dalam Documents.
  static const String rootFolder = 'gocatering';

  /// Inisialisasi (idempotent). Aman dipanggil berkali-kali.
  Future<void> init() async {
    if (_root != null) return;
    final docs = await getApplicationDocumentsDirectory();
    _root = Directory(p.join(docs.path, rootFolder));
    if (!await _root!.exists()) {
      await _root!.create(recursive: true);
    }
  }

  // ============ PATH ============

  /// Path relatif yang disimpan ke kolom SQLite. Murni, tanpa IO, jadi bisa
  /// diuji langsung.
  ///
  ///   relativePath(scope: 'shops', id: '100234', kind: 'logo')
  ///   // => 'shops/100234/logo.jpg'
  static String relativePath({
    required String scope,
    required String id,
    required String kind,
  }) {
    return '$scope/$id/$kind.jpg';
  }

  /// Path absolut dari path relatif di database.
  Future<String> absolutePath(String relative) async {
    await init();
    return p.join(_root!.path, relative);
  }

  /// File untuk widget Image.file / FileImage. Null kalau belum ada.
  Future<File?> file(String? relative) async {
    if (relative == null || relative.isEmpty) return null;
    final f = File(await absolutePath(relative));
    return await f.exists() ? f : null;
  }

  // ============ SAVE ============

  /// Simpan hasil pilih kamera/galeri ke folder [scope]/[id]/[kind].jpg.
  ///
  /// [sourcePath] = `pickedFile.path` dari image_picker.
  /// Mengembalikan path relatif yang siap ditulis ke SQLite.
  Future<String> save({
    required String scope,
    required String id,
    required String kind,
    required String sourcePath,
  }) async {
    await init();
    final relative = relativePath(scope: scope, id: id, kind: kind);
    final dest = File(await absolutePath(relative));

    if (!await dest.parent.exists()) {
      await dest.parent.create(recursive: true);
    }

    await File(sourcePath).copy(dest.path);
    return relative;
  }

  // ---- Convenience wrapper sesuai pemakaian di aplikasi ----

  /// Foto profil penjual -> owners/{ownerKey}/profile.jpg
  Future<String> saveOwnerPhoto({
    required String ownerKey,
    required String sourcePath,
  }) =>
      save(scope: 'owners', id: ownerKey, kind: 'profile', sourcePath: sourcePath);

  /// Logo restoran -> shops/{shopId}/logo.jpg
  Future<String> saveShopLogo({
    required String shopId,
    required String sourcePath,
  }) =>
      save(scope: 'shops', id: shopId, kind: 'logo', sourcePath: sourcePath);

  /// Foto tampilan restoran -> shops/{shopId}/storefront.jpg
  Future<String> saveShopPhoto({
    required String shopId,
    required String sourcePath,
  }) =>
      save(
          scope: 'shops',
          id: shopId,
          kind: 'storefront',
          sourcePath: sourcePath);

  /// Foto paket menu -> shops/{shopId}/pkg_{packageId}.jpg
  Future<String> savePackageImage({
    required String shopId,
    required String packageId,
    required String sourcePath,
  }) =>
      save(
        scope: 'shops',
        id: shopId,
        kind: 'pkg_$packageId',
        sourcePath: sourcePath,
      );

  // ============ DELETE ============

  Future<bool> delete(String? relative) async {
    if (relative == null || relative.isEmpty) return false;
    await init();
    final f = File(await absolutePath(relative));
    if (await f.exists()) {
      await f.delete();
      return true;
    }
    return false;
  }

  /// Hapus seluruh folder satu restoran. Return jumlah file yang dihapus.
  Future<int> deleteShopFolder(String shopId) async =>
      _deleteDir(p.join('shops', shopId));

  Future<int> _deleteDir(String relative) async {
    await init();
    final dir = Directory(p.join(_root!.path, relative));
    if (!await dir.exists()) return 0;

    var count = 0;
    await for (final e in dir.list(recursive: true)) {
      if (e is File) {
        await e.delete();
        count++;
      }
    }
    if (await dir.exists()) await dir.delete(recursive: true);
    return count;
  }

  // ============ UKURAN ============

  /// Total ukuran semua gambar (bytes).
  Future<int> totalBytes() async {
    await init();
    return _dirBytes(_root!);
  }

  /// Ukuran folder satu restoran (bytes).
  Future<int> shopBytes(String shopId) async {
    await init();
    return _dirBytes(Directory(p.join(_root!.path, 'shops', shopId)));
  }

  Future<int> _dirBytes(Directory dir) async {
    await init();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final e in dir.list(recursive: true)) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
