/// Logika murni di balik "Impor banyak foto" — tanpa IO & tanpa Flutter,
/// supaya bisa diuji sebagai unit test biasa.
library;

/// Maksimal foto yang ditangani satu batch. Di atas ini layar tinjau jadi berat
/// dan penjual biasanya memang perlu memisahkan sesi unggah.
const int maxPerBatch = 12;

/// Satu baris tinjauan: file hasil pilih + keterangan yang harus diisi penjual.
///
/// [tempPath] masih menunjuk ke file sementara milik image_picker dan **tidak
/// boleh** disimpan ke database — baru dipindah ke folder restoran setelah
/// penjual menekan Simpan.
class PackageDraft {
  PackageDraft({
    required this.tempPath,
    required this.packageId,
    String name = '',
    int price = 0,
    String descr = '',
  });

  final String tempPath;
  final String packageId;

  String name;
  int price;
  String descr;

  bool get nameOk => name.trim().length >= 3;

  /// Harga harus ada nilainya; nol berarti belum diisi.
  bool get priceOk => price > 0;

  bool get isValid => nameOk && priceOk;

  String? get nameError {
    if (name.trim().isEmpty) return 'Nama paket wajib diisi';
    if (!nameOk) return 'Nama minimal 3 huruf';
    return null;
  }

  String? get priceError {
    if (price <= 0) return 'Harga wajib diisi';
    return null;
  }
}

class BatchValidation {
  const BatchValidation(this.canSave, this.message);

  final bool canSave;
  final String message;
}

/// Pesan tunggal untuk tombol simpan: sebut berapa baris yang kurang nama
/// dan/atau harga, karena keduanya wajib agar pembeli tahu yang dijual.
BatchValidation validateBatch(List<PackageDraft> rows) {
  if (rows.isEmpty) {
    return const BatchValidation(
        false, 'Belum ada foto. Kembali lalu pilih ulang.');
  }

  final noName = rows.where((r) => !r.nameOk).length;
  final noPrice = rows.where((r) => !r.priceOk).length;

  if (noName == 0 && noPrice == 0) {
    return BatchValidation(true, 'Siap disimpan: ${rows.length} paket.');
  }

  final missing = <String>[];
  if (noName > 0) missing.add('$noName nama');
  if (noPrice > 0) missing.add('$noPrice harga');
  return BatchValidation(
    false,
    'Lengkapi ${missing.join(' & ')} — pembeli harus tahu isi dan harganya.',
  );
}

/// Potong hasil pilih galeri ke [maxPerBatch]. Sebagian platform sudah
/// menghormati `limit`, tapi tidak semua, jadi sisi aplikasi yang memastikan.
List<T> takeBatch<T>(List<T> picked, {int max = maxPerBatch}) {
  if (picked.length <= max) return picked;
  return picked.sublist(0, max);
}

/// Id paket untuk posisi [index] dalam batch. [stamp] waktu buka layar
/// (millisecondsSinceEpoch) dan sama untuk seluruh batch, jadi urutan yang
/// membedakan — folder restoran pun menerima nama file berbeda tiap foto.
String packageIdFor(int stamp, int index) => 'P$stamp-$index';

/// Uraikan teks harga dari field (boleh "25.000", "Rp 25000", "25 000").
int parsePrice(String raw) =>
    int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// 25000 -> "Rp 25.000"
String formatRupiah(int value) {
  final digits = value.toString();
  final buf = StringBuffer('Rp ');
  final firstGroup = digits.length % 3;
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (i - firstGroup) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return buf.toString();
}
