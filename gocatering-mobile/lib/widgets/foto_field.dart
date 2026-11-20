import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_storage_service.dart';
import 'stored_image.dart';

/// Kolom "Ambil / pilih foto" yang hasilnya langsung disimpan ke folder
/// restoran/penjual dan mengembalikan *relative path* untuk ditulis ke SQLite.
///
///   FotoField(
///     scope: 'shops', id: shopId, kind: 'logo',
///     currentPath: shop.logo,
///     onChanged: (path) => db.setShopLogo(shopId, path),
///   )
class FotoField extends StatelessWidget {
  const FotoField({
    super.key,
    required this.label,
    required this.scope,
    required this.id,
    required this.kind,
    required this.onChanged,
    this.currentPath,
    this.height = 132,
    this.icon = Icons.camera_alt_outlined,
  });

  final String label;
  final String scope;
  final String id;
  final String kind;
  final String? currentPath;
  final ValueChanged<String> onChanged;
  final double height;
  final IconData icon;

  static const Color _teal = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD5E1DF)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                StoredImage(relativePath: currentPath, placeholder: icon),
                if (currentPath == null || currentPath!.isEmpty)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: _teal),
                        const SizedBox(height: 6),
                        const Text('Ketuk untuk foto / pilih',
                            style: TextStyle(fontSize: 12, color: _teal)),
                      ],
                    ),
                  ),
                if (currentPath != null && currentPath!.isNotEmpty)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit, size: 14, color: _teal),
                            SizedBox(width: 4),
                            Text('Ganti',
                                style: TextStyle(
                                    fontSize: 12, color: _teal)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: _teal),
              title: const Text('Ambil dengan kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _teal),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    // maxWidth/imageQuality = kompensasi tanpa dependensi tambahan:
    // gambar langsung diturunkan ukurannya saat dibaca dari kamera.
    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 82,
    );
    if (picked == null) return;

    try {
      final relative = await ImageStorageService.instance.save(
        scope: scope,
        id: id,
        kind: kind,
        sourcePath: picked.path,
      );
      onChanged(relative);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tersimpan: $relative'),
          duration: const Duration(seconds: 2),
          backgroundColor: _teal,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan foto: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }
}
