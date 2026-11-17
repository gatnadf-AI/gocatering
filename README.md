# goCatering — Prototype Aplikasi Mobile (Memakai Qoder AI Alibaba

Prototipe interaktif (single-file HTML) untuk aplikasi pemesanan katering **goCatering**:
pembeli memilih paket, menentukan ambil di outlet atau diantar, membayar, lalu penjual
memproses pesanan sampai selesai.

Semua alur berjalan tanpa server — cocok untuk demo, user testing, atau presentasi.

## Menjalankan

Tidak perlu install atau build. Cukup:

1. Download / clone repo ini (folder `assets/food/` harus ikut, isinya foto menu).
2. Buka **`gocatering-prototype-v4.html`** di browser (Chrome/Edge/Firefox).
   Di desktop tampilan sudah dibingkai seperti layar HP 380 × 800.

Alternatif: aktifkan **Settings → Pages → GitHub Actions / Deploy from branch** pada repo ini,
lalu buka `https://gatnadf-AI.github.io/gocatering/gocatering-prototype-v4.html`.

## Versi

| Berkas | Isi |
| --- | --- |
| `gocatering-prototype-v5.html` | **Basis pekerjaan berikutnya** — salinan persis v4, tempat fitur registrasi penjual & toko dibangun |
| `gocatering-prototype-v4.html` | **Versi utama yang dipublikasi** — checkout 4 halaman, pembayaran, login Google, profil + UU PDP, dashboard pesanan per toko |
| `gocatering-prototype-v3.html` | Bottom sheet "+ Tambah Pesanan" dengan carousel paket |
| `gocatering-prototype-v2.html` | Dummy data, foto makanan, pembayaran digital |
| `gocatering-prototype.html` | Versi dasar (v1) |

## Fitur di v4

**Checkout 4 halaman** dengan tombol *Sebelum / Sesudah* dan stepper di setiap langkah:

1. **Paket** — satu pesanan = satu toko, jumlah tiap paket bebas.
2. **Pengambilan** — ambil di outlet atau diantar; slot waktu, kurir, jarak.
3. **Profil** — nama, no. WA, alamat (hanya wajib bila diantar), jumlah orang.
4. **Pembayaran** — QRIS / virtual account / e-wallet / COD, rincian total.

Aturan bisnis yang diterapkan:

- **Nomor antre** per toko per hari (prefiks A/B/C/D) untuk pesanan ambil di outlet.
- **Slot ambil 11.00 – 18.00 WIB** saja.
- **Jumlah orang otomatis** = total paket dari semua jenis paket.
- **Batas jam 16.00 WIB** — order hari ini yang lewat jam tersebut digeser diproses besok,
  dengan peringatan dan tombol "Geser ke besok".
- **Ongkir per km** (Rp 8.000/km, ada minimum) langsung masuk total; **COD tidak tersedia**
  untuk pengantaran.
- **Gerbang bayar**: pesanan belum masuk dapur penjual sebelum pembayaran lunas
  (bisa ditunda, lalu dibayar ulang dari tab Pesanan).
- **Jadwal Saya** — pesanan dikelompokkan per tanggal pengambilan/pengantaran.
- **Share via WhatsApp** memakai `wa.me` dengan ringkasan pesanan.

**Dashboard pesanan penjual** (satu akun = banyak toko, semua hitungan mengikuti toko yang dipilih):

- Pemilih toko muncul hanya bila akun punya lebih dari satu toko.
- 4 widget: **Antrean Pesanan**, **Batal · Kedaluarsa**, **Batal · Tidak Diambil**,
  **Pesanan Selesai** — lengkap dengan nilai rupiahnya.
- Setiap widget membuka daftar detail; satu baris memuat id restoran, id pesanan, rincian
  paket, nama & no. WA pemesan, alamat, metode ambil, nomor antre, dan total pembayaran.
  Bisa dicari berdasarkan id pesanan, nomor antre, nama, atau nomor pemesan.
- **Kedaluarsa dihitung otomatis**: order yang belum lunas lewat 2 jam dibatalkan sistem saat
  dasbor dibuka, sehingga terpisah dari pesanan yang **dibatalkan CS** karena tidak diambil.
- CS menandai **Sudah Diambil** beserta **nama pengambil dan foto buktinya** (dikompres ke
  480 px; kalau kuota penyimpanan penuh, status tetap tersimpan dan foto dilepas).
- Status **Selesai** langsung terlihat di sisi pembeli: badge "Diambil oleh …", foto bukti,
  dan riwayat di halaman Profil.
- Penjual hanya melihat tokonya sendiri — permintaan akses ke toko lain diabaikan.

Akun dan data pembeli:

- **Masuk dengan Google** (simulasi OAuth): pilih akun, nama & email diambil otomatis.
  Karena Google tidak membagikan no. WA, kontak diminta satu kali lalu disimpan ke
  database pembeli; akun yang sudah lengkap masuk langsung tanpa form.
- **Profil pembeli**: total pesanan, total dibayar, pesanan selesai, dan riwayat belanja.
- **Perlindungan data pribadi (UU PDP No. 27/2022)**: di halaman Profil nomor WA disamarkan
  4 digit terakhir (`08129876****`) dan email disamarkan (`****@gmail.com`), dengan tombol
  Lihat / Samarkan untuk membuka data diri sendiri. Nomor asli tetap tampil di sisi penjual
  dan di tombol WA supaya kurir bisa menghubungi.

## Akun demo

| Peran | Email | Password |
| --- | --- | --- |
| Pembeli | `budi@mail.com` | `1234` |
| Penjual (RM Sederhana) | `rm.sederhana@gocatering.id` | `seller123` |
| Penjual (Dapur Nusantara) | `dapur.nusantara@gocatering.id` | `seller123` |

Tombol **Masuk dengan Google** menampilkan 3 akun bawaan (`sari.wijaya@`, `andiraen@`,
`maya.kusuma@gmail.com`). Semua nama, nomor, dan alamat di aplikasi ini fiktif.

## Struktur

```
gocatering-prototype-v4.html   aplikasi utama (HTML + CSS + JS, satu berkas)
assets/food/                   foto menu + attribusi.json (sumber & lisensi tiap foto)
LICENSE                        MIT untuk kode prototype
```

## Catatan teknis

- Data tersimpan di `localStorage` peramban dengan key `gocatering_v4` — tidak ada jaringan,
  tidak ada database sungguhan. Reset lewat DevTools: `localStorage.removeItem('gocatering_v4')`.
- Pembayaran (QRIS/VA/e-wallet/COD) dan login Google **disimulasikan**, tidak memakai
  Midtrans atau OAuth asli.
- Jam WIB bisa digeser lewat panel catatan di aplikasi untuk menguji aturan 16.00.
- Prototipe ini untuk demo alur, bukan kerangka aplikasi produksi.

## Lisensi & atribusi

Kode pada repo ini berlisensi **MIT** (lihat `LICENSE`).

Foto makanan di `assets/food/` **tidak** termasuk lisensi MIT: gambar-gambar itu berasal dari
Wikimedia Commons dengan lisensi CC dan nama penciptanya tercatat pada
[`assets/food/attribusi.json`](assets/food/attribusi.json). Gunakan berkas tersebut sebagai
sumber atribusi bila foto ikut dipublikasi.
