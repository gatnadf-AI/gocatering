# goCatering — Prototype Aplikasi Mobile (Memakai Qoder AI Alibaba)

Prototipe interaktif (single-file HTML) untuk aplikasi pemesanan katering **goCatering**:
pembeli memilih paket, menentukan ambil di outlet atau diantar, membayar, lalu penjual
memproses pesanan sampai selesai.

Semua alur berjalan tanpa server — cocok untuk demo, user testing, atau presentasi.

## Menjalankan

Tidak perlu install atau build. Cukup:

1. Download / clone repo ini (folder `assets/food/` harus ikut, isinya foto menu).
2. Buka **`gocatering-prototype-v5.html`** di browser (Chrome/Edge/Firefox — atau langsung
   dari HP/iPad) — atau `index.html`, yang otomatis mengalihkan ke v5. Tampilannya mengikuti
   lebar layar: **≤ 500 px** satu layar penuh tanpa bingkai (safe-area poni & home indicator
   dihormati), **501–1024 px** satu kolom maks 680 px tetap berbingkai, **> 1024 px** seperti
   demo desktop (bingkai 380 × 800 + panel catatan di samping). Di HP/tablet, panel catatan
   pengembang berpindah ke laci bawah lewat tombol **ℹ**.

Alternatif: aktifkan **Settings → Pages → GitHub Actions / Deploy from branch** pada repo ini,
lalu buka `https://gatnadf-AI.github.io/gocatering/gocatering-prototype-v5.html`.

Node dipakai untuk harness uji, bukan untuk menjalankan aplikasinya. Harness (`tools/`) adalah
scratch lokal dan **tidak ikut di-push**, jadi perintah di bawah hanya berlaku di mesin tempat
prototype ini dikembangkan:

    node tools/test.js     # seluruh assertion (regresi v4 + fitur v5)
    node tools/serve.js    # serve di http://127.0.0.1:8848 untuk uji lewat browser

## Versi

| Berkas | Isi |
| --- | --- |
| `gocatering-prototype-v5.html` | **Versi utama yang dipublikasi** — registrasi penjual & toko: wizard 2 langkah, akun + password sementara, kode restoran, multi-toko per pemilik, isolasi antar-akun, popup info restoran untuk pembeli |
| `gocatering-prototype-v4.html` | Checkout 4 halaman, pembayaran, login Google, profil + UU PDP, dashboard pesanan per toko — dipakai v5 sebagai basis, isinya tidak diubah |
| `gocatering-prototype-v3.html` | Bottom sheet "+ Tambah Pesanan" dengan carousel paket |
| `gocatering-prototype-v2.html` | Dummy data, foto makanan, pembayaran digital |
| `gocatering-prototype.html` | Versi dasar (v1) |

## Fitur di v4 — tetap ada di v5

**Checkout 4 halaman** dengan tombol *Sebelum / Sesudah* dan stepper di setiap langkah:

1. **Paket** — satu pesanan = satu toko, jumlah tiap paket bebas.
2. **Pengambilan** — ambil di outlet atau diantar; slot waktu, kurir, jarak.
3. **Profil** — nama, no. WA, alamat (hanya wajib bila diantar), jumlah orang.
4. **Pembayaran** — QRIS / virtual account / e-wallet / COD, rincian total.

Aturan bisnis yang diterapkan:

- **Nomor antre** per toko per hari (prefiks A/B/C/D untuk empat outlet bawaan, outlet hasil
  registrasi melanjutkan huruf berikutnya) untuk pesanan ambil di outlet.
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

| Peran | Email | Password | Catatan |
| --- | --- | --- | --- |
| Pembeli | `budi@mail.com` | `1234` | Checkout 4 halaman + riwayat |
| Penjual 1 | `rm.sederhana@gocatering.id` | `seller123` | Andi Ramadhan, NIK `…4567`, 2 restoran: RM Sederhana `A4567001`, Kekinian Food `A4567002` |
| Penjual 2 | `dapur.nusantara@gocatering.id` | `seller123` | Sari Kumalasari, NIK `…8812`, 2 restoran: Dapur Nusantara `S8812001`, Catering Sehat `S8812002` |

Akun penjual hasil registrasi memakai password sementara yang terbit sekali di layar
"Akun Penjual Terbit" dan wajib diganti saat login pertama.

Tombol **Masuk dengan Google** menampilkan 3 akun bawaan (`sari.wijaya@`, `andiraen@`,
`maya.kusuma@gmail.com`). Semua nama, nomor, dan alamat di aplikasi ini fiktif.

## Struktur

```
gocatering-prototype-v5.html   aplikasi utama (HTML + CSS + JS, satu berkas)
gocatering-prototype-v4.html   basis v5, disimpan apa adanya sebagai pembanding
gocatering-mobile/             aplikasi Flutter (SQLite + foto per restoran) — lihat README-nya
.github/workflows/             build-apk.yml: bangun APK di GitHub Actions
assets/food/                   foto menu + attribusi.json (sumber & lisensi tiap foto)
LICENSE                        Terbatas — perlu izin tertulis goCatering
```

## Catatan teknis

- Data tersimpan di `localStorage` peramban dengan key `gocatering_v5` — tidak ada jaringan,
  tidak ada database sungguhan. Reset lewat DevTools: `localStorage.removeItem('gocatering_v5')`.
  Saat pertama kali dibuka, v5 mengambil isi `gocatering_v4` (kalau ada) lalu menaikkannya ke
  skema 2; kunci v4 tidak ditulis ulang.
- Pembayaran (QRIS/VA/e-wallet/COD) dan login Google **disimulasikan**, tidak memakai
  Midtrans atau OAuth asli.
- Jam WIB bisa digeser lewat panel catatan di aplikasi untuk menguji aturan 16.00.
- Data penjual (nama, NIK, email, WA, password) disandikan XOR + Base64 dengan kunci acak per
  perangkat (`state.devKey`) sebelum masuk `localStorage`. Tujuannya supaya tidak terbaca mata di
  DevTools — **bukan** enkripsi untuk kepatuhan UU PDP. Foto disimpan apa adanya (data URL JPEG
  640 px) supaya kuota 5 MB tidak cepat habis; saat kuota penuh, `save()` mengulang tanpa foto.
- Tidak ada server: NIK tidak diverifikasi ke Dukcapil, link peta tidak di-geocode, dan nomor WA
  hanya tautan `wa.me`.
- Membuka `gocatering-prototype-v4.html` setelah v5 masih aman: v4 memakai kunci penyimpanan
  sendiri (`gocatering_v4`) dan tidak diubah oleh migrasi v5.
- Prototipe ini untuk demo alur, bukan kerangka aplikasi produksi.

## Lisensi & atribusi

Kode pada repo ini berlisensi **terbatas** (lihat [`LICENSE`](LICENSE)): tidak boleh diunduh,
disalin, disebarluaskan, atau dipakai tanpa **izin tertulis** dari goCatering. Berlaku untuk
prototipe HTML, aplikasi Flutter di `gocatering-mobile/`, dan dokumentasi di `docs/`.

Foto makanan di `assets/food/` **tidak** termasuk klausul tersebut: gambar-gambar itu berasal dari
Wikimedia Commons dengan lisensi CC dan nama penciptanya tercatat pada
[`assets/food/attribusi.json`](assets/food/attribusi.json). Gunakan berkas tersebut sebagai
sumber atribusi bila foto ikut dipublikasi.

> Catatan jujur: selama repo ini **public**, teks lisensi hanya berlaku sebagai pemberitahuan
> hukum — siapa pun masih bisa meng-*clone* atau mengunduh artifact/Release dari tab Actions.
> Kalau yang dikejar adalah perlindungan teknis (bukan sekadar klausul), satu-satunya jalan
> adalah menjadikan repo privat, atau memindahkan `gocatering-mobile/` ke repo privat tersendiri
> sementara prototipe Pages tetap publik.

Hubungi **androvich97@gmail.com** / **contact@gocatering.id** untuk meminta izin tertulis.

