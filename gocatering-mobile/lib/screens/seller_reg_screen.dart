import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/image_storage_service.dart';
import '../widgets/foto_field.dart';
import 'shop_packages_screen.dart';

/// Registrasi penjual 2 halaman, sama seperti prototipe web:
///   1. Data penjual  — gelar, nama, email, NIK, WA, password
///   2. Data toko     — nama, alamat, WA CS, foto penjual, foto restoran
///
/// ID penjual & ID toko sudah dibuat di awal supaya folder gambar
/// (owners/{key}/, shops/{id}/) sudah pasti sejak foto pertama dipilih.
class SellerRegScreen extends StatefulWidget {
  const SellerRegScreen({super.key});

  @override
  State<SellerRegScreen> createState() => _SellerRegScreenState();
}

class _SellerRegScreenState extends State<SellerRegScreen> {
  static const Color _teal = Color(0xFF00897B);

  final _form1 = GlobalKey<FormState>();
  final _form2 = GlobalKey<FormState>();

  final _gelar = TextEditingController();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _nik = TextEditingController();
  final _wa = TextEditingController();
  final _pass = TextEditingController();

  final _toko = TextEditingController();
  final _alamat = TextEditingController();
  final _waCs = TextEditingController();
  final _maps = TextEditingController();

  /// Dibuat sekali di awal — jadi path folder gambar stabil.
  late final String ownerKey;
  late final String shopId;

  int _page = 0;
  bool _saving = false;

  String? _ownerPhoto;
  String? _shopLogo;
  String? _shopPhoto;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    ownerKey = 'O${now.millisecondsSinceEpoch}';
    shopId = '${now.millisecondsSinceEpoch ~/ 1000}';
    ImageStorageService.instance.init();
  }

  @override
  void dispose() {
    for (final c in [
      _gelar, _nama, _email, _nik, _wa, _pass, _toko, _alamat, _waCs, _maps
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static final RegExp _reEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
  static final RegExp _rePhone = RegExp(r'^(\+62|62|0)8[1-9][0-9\s-]{6,14}$');
  static final RegExp _reNik = RegExp(r'^[0-9]{16}$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_page == 0 ? 'Daftar Penjual · Data Diri' : 'Daftar Penjual · Data Toko'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: _page == 0 ? _buildPage1() : _buildPage2(),
        ),
      ),
    );
  }

  // ============ PAGE 1 ============

  Widget _buildPage1() {
    return Form(
      key: _form1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepBar(current: 0),
          const SizedBox(height: 16),
          const Text('Nama lengkap', style: _label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nama,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'mis. Budi Santoso'),
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'Nama minimal 3 huruf'
                : null,
          ),
          const SizedBox(height: 12),
          const Text('Gelar (opsional)', style: _label),
          const SizedBox(height: 6),
          TextFormField(
              controller: _gelar,
              decoration: const InputDecoration(hintText: 'mis. S.E.')),
          const SizedBox(height: 12),
          const Text('Email', style: _label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'warung@email.com'),
            validator: (v) =>
                _reEmail.hasMatch((v ?? '').trim()) ? null : 'Email tidak valid',
          ),
          const SizedBox(height: 12),
          const Text('NIK (16 digit)', style: _label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nik,
            keyboardType: TextInputType.number,
            maxLength: 16,
            decoration: const InputDecoration(counterText: ''),
            validator: (v) =>
                _reNik.hasMatch((v ?? '').trim()) ? null : 'NIK harus 16 digit',
          ),
          const SizedBox(height: 12),
          const Text('Nomor WhatsApp', style: _label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _wa,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '08xx xxxx xxxx'),
            validator: (v) =>
                _rePhone.hasMatch((v ?? '').trim()) ? null : 'Nomor tidak valid',
          ),
          const SizedBox(height: 12),
          const Text('Password akun penjual', style: _label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _pass,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'minimal 6 karakter'),
            validator: (v) => (v == null || v.length < 6)
                ? 'Password minimal 6 karakter'
                : null,
          ),
          const SizedBox(height: 10),
          const Text(
            'Data disimpan hanya di HP ini (SQLite) dan tidak dikirim ke server.',
            style: TextStyle(fontSize: 11.5, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (_form1.currentState?.validate() ?? false) {
                setState(() => _page = 1);
              }
            },
            child: const Text('Selanjutnya  →'),
          ),
        ],
      ),
    );
  }

  // ============ PAGE 2 ============

  Widget _buildPage2() {
    return Form(
      key: _form2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepBar(current: 1),
          const SizedBox(height: 16),
          const Text('Nama restoran / katering', style: _label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _toko,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'mis. Rasa Bunda Catering'),
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'Nama toko minimal 3 huruf'
                : null,
          ),
          const SizedBox(height: 12),
          const Text('Alamat', style: _label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _alamat,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Jalan, kelurahan, kota'),
            validator: (v) =>
                (v == null || v.trim().length < 8) ? 'Alamat terlalu pendek' : null,
          ),
          const SizedBox(height: 12),
          const Text('WhatsApp CS (opsional)', style: _label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _waCs,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'kosongkan bila sama dgn WA di atas'),
          ),
          const SizedBox(height: 12),
          const Text('Tautan Maps (opsional)', style: _label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _maps,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(hintText: 'https://maps.app.goo.gl/...'),
          ),
          const SizedBox(height: 18),
          FotoField(
            label: 'Foto Penjual',
            icon: Icons.person_outline,
            scope: 'owners',
            id: ownerKey,
            kind: 'profile',
            currentPath: _ownerPhoto,
            onChanged: (path) => setState(() => _ownerPhoto = path),
          ),
          const SizedBox(height: 16),
          FotoField(
            label: 'Logo / Foto Restoran',
            icon: Icons.storefront_outlined,
            scope: 'shops',
            id: shopId,
            kind: 'logo',
            currentPath: _shopLogo,
            onChanged: (path) => setState(() => _shopLogo = path),
          ),
          const SizedBox(height: 16),
          FotoField(
            label: 'Foto Tampilan Restoran',
            icon: Icons.photo_camera_outlined,
            scope: 'shops',
            id: shopId,
            kind: 'storefront',
            currentPath: _shopPhoto,
            onChanged: (path) => setState(() => _shopPhoto = path),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => setState(() => _page = 0),
                  child: const Text('← Sebelumnya'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Selanjutnya · DAFTARKAN'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ SUBMIT ============

  Future<void> _submit() async {
    if (!(_form2.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final db = DatabaseHelper();
    final now = DateTime.now().toIso8601String();
    final email = _email.text.trim().toLowerCase();
    final wa = _wa.text.trim();

    try {
      if (await db.getOwnerByEmail(email) != null) {
        _fail('Email sudah terdaftar sebagai penjual lain.');
        return;
      }
      if (await db.getOwnerByNik(_nik.text.trim()) != null) {
        _fail('NIK sudah terdaftar.');
        return;
      }

      await db.insertOwner({
        'key': ownerKey,
        'gelar': _gelar.text.trim(),
        'nama': _nama.text.trim(),
        'nik': _nik.text.trim(),
        'email': email,
        'phone': wa,
        'photo': _ownerPhoto,
        'password': _pass.text,
        'mustReset': 0,
        'createdAt': now,
      });

      await db.insertShop({
        'id': shopId,
        'code': 'TOKO$shopId',
        'name': _toko.text.trim(),
        'tagline': '',
        'logo': _shopLogo,
        'rating': 0,
        'sold': 0,
        'ownerKey': ownerKey,
        'addr': _alamat.text.trim(),
        'mapUrl': _maps.text.trim(),
        'csWa': _waCs.text.trim().isEmpty ? wa : _waCs.text.trim(),
        'photo': _shopPhoto,
        'builtin': 0,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Restoran terdaftar. Silakan isi paket menu.'),
        backgroundColor: _teal,
      ));

      // Lanjut ke halaman menu: di sinilah foto tiap paket disimpan ke
      // folder shops/{shopId}/pkg_{paketId}.jpg
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ShopPackagesScreen(
            shopId: shopId,
            shopName: _toko.text.trim(),
          ),
        ),
      );
    } catch (e) {
      _fail('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _fail(String msg) {
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  static const TextStyle _label =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87);
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    Widget dot(int i, String label) {
      final active = i <= current;
      return Expanded(
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? const Color(0xFF00897B) : const Color(0xFFDDE6E4),
              ),
              child: Center(
                child: Text('${i + 1}',
                    style: TextStyle(
                        color: active ? Colors.white : Colors.black45,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11.5)),
          ],
        ),
      );
    }

    return Row(children: [
      dot(0, 'Data Penjual'),
      dot(1, 'Data Toko'),
    ]);
  }
}
