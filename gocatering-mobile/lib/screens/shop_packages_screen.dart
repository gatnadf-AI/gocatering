import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../models/package_draft.dart';
import '../services/image_storage_service.dart';
import '../widgets/foto_field.dart';
import '../widgets/stored_image.dart';
import 'batch_packages_screen.dart';

/// Daftar paket menu satu restoran + foto tiap paket.
///
/// Setiap foto paket disimpan ke folder restoran:
///   shops/{shopId}/pkg_{packageId}.jpg
/// dan kolom `img` di tabel packages hanya menyimpan path relatif itu.
class ShopPackagesScreen extends StatefulWidget {
  const ShopPackagesScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  final String shopId;
  final String shopName;

  @override
  State<ShopPackagesScreen> createState() => _ShopPackagesScreenState();
}

class _ShopPackagesScreenState extends State<ShopPackagesScreen> {
  static const Color _teal = Color(0xFF00897B);

  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _rows = const [];
  Set<String> _off = {};
  int _storageBytes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _db.getPackagesByShop(widget.shopId);
    final off = (await _db.getMenuOffByShop(widget.shopId))
        .map((r) => r['packageId'] as String)
        .toSet();
    final bytes = await ImageStorageService.instance.shopBytes(widget.shopId);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _off = off;
      _storageBytes = bytes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paket Menu'),
            Text(widget.shopName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Hapus semua gambar restoran ini',
            icon: const Icon(Icons.image_not_supported_outlined),
            onPressed: _purgeImages,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        onPressed: _showAddMenu,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Tambah Paket'),
      ),
      body: Column(
        children: [
          _StorageBanner(shopId: widget.shopId, bytes: _storageBytes),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const EmptyHint(
                        icon: Icons.no_meals_outlined,
                        title: 'Belum ada paket',
                        body: 'Tambah satu per satu, atau pilih banyak foto '
                            'sekaligus. Semua gambar tersimpan di folder '
                            'restoran ini di HP Anda.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _PackageTile(
                          row: _rows[i],
                          isOff: _off.contains(_rows[i]['id']),
                          onTap: () => _openEditor(_rows[i]),
                          onToggle: () => _toggleOff(_rows[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleOff(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    await _db.toggleMenuOff(id, widget.shopId, !_off.contains(id));
    await _load();
  }

  Future<void> _purgeImages() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus gambar restoran?'),
        content: const Text(
            'Semua file di folder shops/{id} terhapus dari HP ini. '
            'Data paket dan harganya tetap ada.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    final n = await ImageStorageService.instance.deleteShopFolder(widget.shopId);
    // Kosongkan kolom path di database supaya tidak menunjuk file mati.
    for (final row in _rows) {
      if (row['img'] != null) await _db.setPackageImg(row['id'], '');
    }
    final shop = await _db.getShopById(widget.shopId);
    if (shop != null) {
      await _db.updateShop({...shop, 'logo': '', 'photo': ''});
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$n file gambar dihapus dari HP.')));
  }

  // ============ TAMBAH PAKET ============

  /// Dua cara: satu per satu, atau banyak foto sekaligus dari galeri.
  Future<void> _showAddMenu() async {
    final choice = await showModalBottomSheet<String>(
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
              title: const Text('Satu paket'),
              subtitle: const Text('Foto, nama, dan harga diisi bergantian'),
              onTap: () => Navigator.pop(ctx, 'single'),
            ),
            ListTile(
              leading: const Icon(Icons.collections_outlined, color: _teal),
              title: const Text('Banyak foto sekaligus'),
              subtitle: Text(
                  'Pilih sampai $maxPerBatch foto dari galeri, isi nama & harga tiap foto'),
              onTap: () => Navigator.pop(ctx, 'batch'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == 'single') {
      await _openEditor(null);
    } else if (choice == 'batch') {
      final added = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BatchPackagesScreen(
            shopId: widget.shopId,
            shopName: widget.shopName,
          ),
        ),
      );
      if (added == true) await _load();
    }
  }

  Future<void> _openEditor(Map<String, dynamic>? row) async {
    final isNew = row == null;
    // id dibuat dulu supaya folder & nama file gambar stabil sejak awal
    final pkgId = isNew
        ? 'P${DateTime.now().millisecondsSinceEpoch ~/ 1000}'
        : row['id'] as String;

    final name = TextEditingController(text: isNew ? '' : row['name']);
    final price =
        TextEditingController(text: isNew ? '' : '${row['price']}');
    final desc = TextEditingController(text: isNew ? '' : (row['descr'] ?? ''));
    String? img = isNew ? null : row['img'];

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18,
              MediaQuery.of(ctx).viewInsets.bottom + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isNew ? 'Paket Baru' : 'Ubah Paket',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              FotoField(
                label: 'Foto Paket',
                icon: Icons.rice_bowl_outlined,
                scope: 'shops',
                id: widget.shopId,
                kind: 'pkg_$pkgId',
                currentPath: img,
                onChanged: (path) => setSheet(() => img = path),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama paket'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Harga per pax (Rp)', prefixText: 'Rp '),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: desc,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Isi paket'),
              ),
              const SizedBox(height: 6),
              Text('File gambar: shops/${widget.shopId}/pkg_$pkgId.jpg',
                  style: const TextStyle(fontSize: 11, color: Colors.black45)),
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _teal),
                onPressed: () {
                  final p = int.tryParse(
                          price.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                      0;
                  if (name.text.trim().isEmpty || p <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content:
                            Text('Nama dan harga di atas nol wajib diisi.')));
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: Text(isNew ? 'Simpan Paket' : 'Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      final priceVal =
          int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      await _db.upsertPackage(
        id: pkgId,
        shopId: widget.shopId,
        name: name.text.trim(),
        price: priceVal,
        img: img,
        descr: desc.text.trim(),
      );
      await _load();
    }

    name.dispose();
    price.dispose();
    desc.dispose();
  }
}

// ============ WIDGET BANTU ============

class _StorageBanner extends StatelessWidget {
  const _StorageBanner({required this.shopId, required this.bytes});
  final String shopId;
  final int bytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF1F7F6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, size: 18, color: Color(0xFF00897B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'gocatering/shops/$shopId · ${ImageStorageService.formatSize(bytes)}',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.row,
    required this.isOff,
    required this.onTap,
    required this.onToggle,
  });
  final Map<String, dynamic> row;
  final bool isOff;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final pkg = Package.fromMap(row);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2EAE8)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child: StoredImage(
                      relativePath: pkg.img, placeholder: Icons.rice_bowl_outlined),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text('Rp ${pkg.price.toString()}',
                          style: const TextStyle(
                              color: Color(0xFF00897B),
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      if ((pkg.desc ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(pkg.desc!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontSize: 11.5, color: Colors.black54)),
                      ],
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  Switch(value: !isOff, onChanged: (_) => onToggle()),
                  Text(isOff ? 'OFF' : 'ON',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOff ? Colors.redAccent : Colors.green)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(
      {super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: const Color(0xFFB7C6C3)),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
