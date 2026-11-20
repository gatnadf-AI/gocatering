import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_storage_service.dart';

/// Menampilkan gambar yang path-nya disimpan di SQLite (mis.
/// `shops/100234/logo.jpg`). Kalau file belum ada, tampil placeholder.
class StoredImage extends StatelessWidget {
  const StoredImage({
    super.key,
    required this.relativePath,
    this.fit = BoxFit.cover,
    this.placeholder = Icons.restaurant,
    this.placeholderColor,
  });

  final String? relativePath;
  final BoxFit fit;
  final IconData placeholder;
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final path = relativePath;
    if (path == null || path.isEmpty) return _ph(context);

    return FutureBuilder<File?>(
      future: ImageStorageService.instance.file(path),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const ColoredBox(
            color: Color(0xFFEEF3F2),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final file = snap.data;
        if (file == null) return _ph(context);
        return Image.file(file, fit: fit, gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _ph(context));
      },
    );
  }

  Widget _ph(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEEF3F2),
      child: Center(
        child: Icon(placeholder,
            color: placeholderColor ?? const Color(0xFF9AA7A5), size: 28),
      ),
    );
  }
}
