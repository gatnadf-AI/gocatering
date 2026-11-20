import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';
import '../models/package_draft.dart';
import '../services/image_storage_service.dart';

/// Impor banyak foto makanan sekaligus.
///
/// Aturan yang dijaga di sini: **satu foto = satu paket**, dan tidak ada
/// paket yang masuk katalog tanpa nama + harga — pembeli harus tahu apa yang
/// dijual. Karena itu file hasil galeri tidak langsung disimpan; penjual
/// mengisi keterangannya dulu di layar tinjau ini.
///
/// File baru dipindah ke gocatering/shops/{shopId}/pkg_{packageId}.jpg pada
/// tahap [_save], karena path dari pickMultiImage bersifat sementara.
class BatchPackagesScreen extends StatefulWidget {
  const BatchPackagesScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  final String shopId;
  final String shopName;

  @override
  State<BatchPackagesScreen> createState() => _BatchPackagesScreenState();
}

class _BatchPackagesScreenState extends State<BatchPackagesScreen> {
  static const Color _teal = Color(0xFF00897B);

  final DatabaseHelper _db = DatabaseHelper();
  final List<_DraftRow> _rows = [];

  bool _picking = true;
  bool _saving = false;
  String? _pickError;
  bool _trimmed = false;

  @override
  void initState() {
    super.initState();
    // Galeri dibuka setelah frame pertama supaya layar tidak terlihat mati.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openGallery());
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _openGallery() async {
    List<XFile> picked;
    try {
      // pickMultiImage = galeri saja; kamera tidak bisa memilih banyak file.
      picked = await ImagePicker().pickMultiImage(
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 82,
        limit: maxPerBatch,
        requestFullMetadata: false,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _pickError = _describePickError(e);
      });
      return;
    }

    final kept = takeBatch(picked);
    if (!mounted) return;

    if (kept.isEmpty) {
      // Pembatalan: kembali tanpa mengubah apa pun.
      Navigator.pop(context, false);
      return;
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      for (var i = 0; i < kept.length; i++) {
        _rows.add(_DraftRow(PackageDraft(
          tempPath: kept[i].path,
          packageId: packageIdFor(stamp, i),
        )));
      }
      _trimmed = picked.length > kept.length;
      _picking = false;
    });
  }

  String _describePickError(PlatformException e) {
    final msg = e.message ?? e.code;
    if (msg.toLowerCase().contains('permission')) {
      return 'Izin akses galeri belum diberikan. Buka setelan HP, izinkan '
          'goCatering mengakses foto, lalu coba lagi.';
    }
    if (msg.toLowerCase().contains('cancel')) {
      return 'Pemilihan foto dibatalkan.';
    }
    return 'Gagal membuka galeri: $msg';
  }

  @override
  Widget build(BuildContext context) {
    final drafts = _rows.map((r) => r.draft).toList();
    final validation = validateBatch(drafts);

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F8),
        appBar: AppBar(
          title: const Text('Impor Banyak Foto'),
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(38),
            child: Container(
              color: const Color(0xFFE7F0EE),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.shopName} · ${drafts.length} foto · tiap foto jadi 1 paket',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ),
        ),
        body: _buildBody(),
        bottomNavigationBar: _picking || _pickError != null
            ? null
            : _buildBottomBar(validation),
      ),
    );
  }

  Widget _buildBody() {
    if (_picking) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Menunggu pilihan foto…',
                style: TextStyle(fontSize: 12.5, color: Colors.black54)),
          ],
        ),
      );
    }

    if (_pickError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_library_outlined,
                  size: 48, color: Color(0xFFB7C6C3)),
              const SizedBox(height: 12),
              Text(_pickError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _picking = true;
                    _pickError = null;
                  });
                  _openGallery();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Pilih ulang'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        if (_trimmed)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _NoteBar(
              icon: Icons.info_outline,
              text:
                  'Batch dibatasi $maxPerBatch foto sekali jalan. Sisanya silakan '
                  'impor pada batch berikutnya.',
            ),
          ),
        for (var i = 0; i < _rows.length; i++) _buildCard(i),
      ],
    );
  }

  Widget _buildCard(int index) {
    final row = _rows[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2EAE8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: Image.file(
                      File(row.draft.tempPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFEEF3F2),
                        child: Icon(Icons.broken_image_outlined,
                            color: Color(0xFF9AA7A5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: row.name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Nama paket *',
                            isDense: true,
                            errorText:
                                row.nameTouched ? row.draft.nameError : null,
                          ),
                          onChanged: (v) {
                            row.nameTouched = true;
                            row.draft.name = v;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: row.descr,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Isi paket (opsional)',
                            isDense: true,
                          ),
                          onChanged: (v) => row.draft.descr = v,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                controller: row.price,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Harga/pax *',
                                  isDense: true,
                                  prefixText: 'Rp ',
                                ),
                                onChanged: (v) {
                                  row.draft.price = parsePrice(v);
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              tooltip: 'Buang foto ini',
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent, size: 22),
                              onPressed: _saving ? null : () => _removeRow(index),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (row.draft.priceOk)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tampil ke pembeli: ${row.draft.name.trim().isEmpty ? '(nama belum diisi)' : row.draft.name.trim()}'
                    ' · ${formatRupiah(row.draft.price)}',
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF00695C)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _removeRow(int index) {
    final removed = _rows.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Widget _buildBottomBar(BatchValidation validation) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2EAE8))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              validation.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: validation.canSave ? const Color(0xFF00695C) : Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: validation.canSave && !_saving ? _save : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving
                        ? 'Menyimpan…'
                        : 'Simpan ${_rows.length} Paket'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final store = ImageStorageService.instance;
    var saved = 0;
    final failures = <String>[];

    for (final row in _rows) {
      final d = row.draft;
      try {
        final rel = await store.save(
          scope: 'shops',
          id: widget.shopId,
          kind: 'pkg_${d.packageId}',
          sourcePath: d.tempPath,
        );
        await _db.upsertPackage(
          id: d.packageId,
          shopId: widget.shopId,
          name: d.name.trim(),
          price: d.price,
          img: rel,
          descr: d.descr.trim(),
        );
        saved++;
      } catch (e) {
        failures.add('${d.name.trim()} — $e');
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    final msg = failures.isEmpty
        ? '$saved paket masuk katalog.'
        : '$saved tersimpan, ${failures.length} gagal: ${failures.first}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: failures.isEmpty ? _teal : Colors.orange.shade800,
    ));

    Navigator.pop(context, saved > 0);
  }
}

/// Satu baris tinjauan = [PackageDraft] (logika) + controller (UI).
class _DraftRow {
  _DraftRow(this.draft)
      : name = TextEditingController(text: ''),
        price = TextEditingController(text: ''),
        descr = TextEditingController(text: '');

  final PackageDraft draft;
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController descr;
  bool nameTouched = false;

  void dispose() {
    name.dispose();
    price.dispose();
    descr.dispose();
  }
}

class _NoteBar extends StatelessWidget {
  const _NoteBar({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3DFB8)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
