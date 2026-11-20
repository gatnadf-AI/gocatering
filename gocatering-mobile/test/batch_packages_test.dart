import 'package:flutter_test/flutter_test.dart';
import 'package:gocatering_mobile/models/package_draft.dart';

/// Logika impor banyak foto diuji tanpa IO: nama & harga wajib terisi supaya
/// pembeli tidak melihat foto tanpa keterangan di katalog.
void main() {
  PackageDraft draft({String name = '', int price = 0}) => PackageDraft(
        tempPath: '/tmp/cache/${price}_$name.jpg',
        packageId: 'P1700000000-0',
        name: name,
        price: price,
      );

  group('PackageDraft', () {
    test('kosong tidak valid', () {
      final d = draft();
      expect(d.isValid, isFalse);
      expect(d.nameError, 'Nama paket wajib diisi');
      expect(d.priceError, 'Harga wajib diisi');
    });

    test('nama terlalu pendek ditolak', () {
      final d = draft(name: 'A', price: 25000);
      expect(d.nameOk, isFalse);
      expect(d.nameError, 'Nama minimal 3 huruf');
      expect(d.priceOk, isTrue);
    });

    test('harga nol ditolak walau nama sudah diisi', () {
      final d = draft(name: 'Nasi Box Ayam Bakar');
      expect(d.priceOk, isFalse);
      expect(d.priceError, 'Harga wajib diisi');
      expect(d.isValid, isFalse);
    });

    test('nama + harga lengkap = valid', () {
      expect(draft(name: 'Nasi Box Ayam Bakar', price: 25000).isValid, isTrue);
    });

    test('nama hanya spasi dianggap kosong', () {
      final d = draft(name: '   ', price: 25000);
      expect(d.nameOk, isFalse);
      expect(d.nameError, 'Nama paket wajib diisi');
    });
  });

  group('validateBatch', () {
    test('tanpa baris tidak bisa disimpan', () {
      final r = validateBatch(const []);
      expect(r.canSave, isFalse);
      expect(r.message, contains('Belum ada foto'));
    });

    test('menyebut jumlah baris yang kurang nama', () {
      final r = validateBatch([
        draft(name: 'Nasi Uduk', price: 15000),
        draft(price: 20000),
        draft(price: 30000),
      ]);
      expect(r.canSave, isFalse);
      expect(r.message, contains('2 nama'));
      expect(r.message, isNot(contains('2 harga')));
    });

    test('menyebut nama dan harga yang kurang sekaligus', () {
      // Baris 1 punya nama tapi belum ada harga; baris 2 belum ada keduanya.
      final r = validateBatch([
        draft(name: 'Nasi Rendang'),
        draft(name: 'Tumpeng'),
      ]);
      expect(r.canSave, isFalse);
      expect(r.message, contains('2 harga'));
      expect(r.message, isNot(contains('2 nama')));
    });

    test('baris dengan nama dan harga kurang disebut keduanya', () {
      final r = validateBatch([
        draft(name: 'Nasi Box', price: 25000),
        draft(name: ''),
      ]);
      expect(r.canSave, isFalse);
      expect(r.message, contains('1 nama'));
      expect(r.message, contains('1 harga'));
    });

    test('semua lengkap -> siap simpan', () {
      final r = validateBatch([
        draft(name: 'Nasi Box', price: 25000),
        draft(name: 'Tumpeng Mini', price: 150000),
      ]);
      expect(r.canSave, isTrue);
      expect(r.message, contains('2 paket'));
    });
  });

  group('takeBatch', () {
    test('memotong sampai batas 12', () {
      final picked = List<int>.generate(20, (i) => i);
      final trimmed = takeBatch(picked);
      expect(trimmed.length, maxPerBatch);
      expect(trimmed.first, 0);
      expect(trimmed.last, maxPerBatch - 1);
    });

    test('di bawah batas tidak diubah', () {
      final picked = [1, 2, 3];
      expect(takeBatch(picked), [1, 2, 3]);
    });
  });

  group('packageIdFor', () {
    test('satu id unik per posisi supaya tidak saling menimpa', () {
      final a = packageIdFor(1700000000, 0);
      final b = packageIdFor(1700000000, 1);
      expect(a, 'P1700000000-0');
      expect(b, 'P1700000000-1');
      expect(a, isNot(b));
    });
  });

  group('parsePrice', () {
    test('menerima angka murni dan angka bertitik', () {
      expect(parsePrice('25000'), 25000);
      expect(parsePrice('25.000'), 25000);
      expect(parsePrice('Rp 25 000'), 25000);
    });

    test('kosong atau tanpa angka jadi nol (tidak valid)', () {
      expect(parsePrice(''), 0);
      expect(parsePrice('abc'), 0);
    });
  });

  group('formatRupiah', () {
    test('pemisah ribuan', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(999), 'Rp 999');
      expect(formatRupiah(1000), 'Rp 1.000');
      expect(formatRupiah(25000), 'Rp 25.000');
      expect(formatRupiah(100000), 'Rp 100.000');
      expect(formatRupiah(1234567), 'Rp 1.234.567');
      expect(formatRupiah(1000000), 'Rp 1.000.000');
    });
  });
}
