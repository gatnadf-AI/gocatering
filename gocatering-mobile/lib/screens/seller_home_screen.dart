import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../services/image_storage_service.dart';
import '../widgets/stored_image.dart';
import 'shop_packages_screen.dart';

/// Dashboard penjual: daftar toko miliknya. Logo yang tampil dibaca dari
/// folder shops/{id}/logo.jpg lewat path relatif di SQLite.
class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key, required this.ownerKey});
  final String ownerKey;

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  static const Color _teal = Color(0xFF00897B);
  final DatabaseHelper _db = DatabaseHelper();

  Owner? _owner;
  List<Shop> _shops = const [];
  int _bytes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ownerRow = await _db.getOwnerByKey(widget.ownerKey);
    final shopRows = await _db.getShopsByOwner(widget.ownerKey);
    var total = 0;
    for (final s in shopRows) {
      total += await ImageStorageService.instance.shopBytes(s['id'] as String);
    }
    if (!mounted) return;
    setState(() {
      _owner = ownerRow == null ? null : Owner.fromMap(ownerRow);
      _shops = shopRows.map(Shop.fromMap).toList();
      _bytes = total;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F8),
      appBar: AppBar(
        title: const Text('Dashboard Penjual'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _db.clearSession();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _OwnerCard(owner: _owner, bytes: _bytes),
                  const SizedBox(height: 16),
                  const Text('Toko Saya',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_shops.isEmpty)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.storefront_outlined),
                        title: Text('Belum ada toko terdaftar'),
                      ),
                    )
                  else
                    ..._shops.map((s) => _ShopCard(shop: s)),
                ],
              ),
            ),
    );
  }

  Widget _OwnerCard({required Owner? owner, required int bytes}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2EAE8))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 52,
                height: 52,
                child: StoredImage(
                    relativePath: owner?.photo, placeholder: Icons.person),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(owner?.nama ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(owner?.email ?? '-',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    'Gambar di HP: ${ImageStorageService.formatSize(bytes)}',
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF00897B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ShopCard(Shop shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2EAE8))),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: StoredImage(
                relativePath: shop.logo ?? shop.photo,
                placeholder: Icons.storefront_outlined),
          ),
        ),
        title: Text(shop.name,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(shop.addr ?? '-',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF00897B)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ShopPackagesScreen(shopId: shop.id, shopName: shop.name),
          ),
        ),
      ),
    );
  }
}
