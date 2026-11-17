# Spec — Registrasi Penjual & Toko goCatering

Tanggal: 2026-11-17 · Status: rancangan disetujui lewat dialog; menunggu review berkas ini
Berkas yang diubah: `gocatering-prototype-v4.html` (satu-satunya berkas aplikasi),
`README.md`, `tools/boottest.js`

## 1. Masalah dan tujuan

Prototype sekarang punya empat toko yang ditulis sebagai konstanta `SHOPS` dan dua akun
penjual tetap di `SELLERS`. Registrasi penjual (`doRegister()`) hanya menyimpan string
`shopName` di `state.users[email]` dan tidak pernah membuat toko maupun akun penjual —
saat login, email itu tidak ada di `SELLERS` sehingga orang tersebut masuk sebagai
pembeli. Fitur yang diminta menutup lubang ini: penjual dan tokonya benar-benar
terdaftar, punya identitas (ID + kode restoran), kredensial yang terbit dari sistem,
isolasi akses antar-toko, dan kodenya tampil ke pembeli.

Tujuan yang bisa diuji:

1. Seorang penjual bisa mendaftar dari nol dan langsung bisa berjualan di tokonya sendiri.
2. Pemilik yang sama (NIK sama) bisa menambah restoran kedua, ketiga, dst.
3. Akun A tidak bisa melihat atau mengubah data toko milik akun B.
4. Pembeli melihat kode restoran, bukan ID, dan bisa membuka info pemilik dari kode itu.
5. Data pribadi penjual tidak tersimpan sebagai teks polos di `localStorage`.

## 2. Keputusan desain (sudah disetujui)

| # | Keputusan | Pilihan |
| --- | --- | --- |
| 1 | Model akun | 1 akun = 1 pemilik (NIK), boleh banyak toko; toko kedua lewat form registrasi toko |
| 2 | Identitas pemilik | NIK diketik (16 digit); **upload foto KTP batal** |
| 3 | Pemilik multi-toko | memakai NIK yang sama |
| 4 | Perlindungan data | obfuscation XOR + Base64 dengan kunci per perangkat |
| 5 | Foto (penjual & restoran) | dikompres maks 640 px JPEG q0.7 → data URL (blob) |
| 6 | Alamat Google Maps | tempel link/share, divalidasi URL Google Maps |
| 7 | Popup info restoran | nama pemilik, alamat fisik, tombol Buka Peta, WA CS penuh + Chat WA |
| 8 | Running number kode | 3 digit, **per pemilik**, mulai `001` → `H4567001` |
| 9 | ID restoran | 6 angka acak unik |
| 10 | NIK dipakai email lain | ditolak, diarahkan "login dulu → Tambah Toko" |
| 11 | 4 toko bawaan | dimigrasi dengan data contoh lengkap |
| 12 | Email | tidak boleh ganda antara peran pembeli dan penjual |

**Yang tidak masuk lingkup:** foto/OCR KTP, enkripsi AES sungguhan, OAuth Google asli,
verifikasi dokumen oleh admin, geocoding alamat, penilaian ulasan, dan apa pun yang
membutuhkan server.

## 3. Model data

```js
state.owners = {                       // kunci = ownerKey
  'ow-9f2c1a77': {
    key:'ow-9f2c1a77',                 // fnv-1a 32-bit dari NIK, heksadesimal
    gelar:'Tn',                        // 'Tn' | 'Ny' | 'Nona'
    nama:'e1:…',                       // tersandi
    nik:'e1:…',                        // tersandi, 16 digit
    email:'e1:…',                      // tersandi, lowercase (registrasi baru: @gmail.com)
    phone:'e1:…',                      // tersandi — WA pemilik
    photo:'data:image/jpeg;base64,…',  // polos (lihat risiko §8)
    password:'e1:…',                   // tersandi
    mustReset:false,
    createdAt:'2026-11-17T16:00:00.000Z',
    shops:['100234','100518'],         // ID restoran milik pemilik ini
  }
}
state.shops = [                        // sumber tunggal, termasuk 4 toko bawaan
  { id:'100234',                        // 6 angka — hasil migrasi memakai nilai tetap (§9),
    //                                    sedangkan restoran baru memakai ID acak unik (§6)
    code:'A4567001',                    // inisial nama pemilik + 4 digit akhir NIK + running
    name:'RM Sederhana', tagline:'…', logo:'RS', rating:4.7, sold:120,
    packages:[ {id:'p1', name:'…', price:15000, img:'assets/food/u1.jpg', desc:'…'} ],
    ownerKey:'ow-9f2c1a77',
    addr:'Jl. Tunjungan No. 45, Surabaya',
    mapUrl:'https://maps.app.goo.gl/…',
    csWa:'e1:…',                        // WA customer service, tersandi
    photo:'data:image/jpeg;base64,…',
    builtin:true }                      // true untuk 4 toko migrasi
]
```

Contoh di atas milik pemilik `Andi Ramadhan` (gelar `Tn`, NIK berakhiran `4567`), jadi
kodenya `A4567001` — inisial diambil dari **nama pemilik**, bukan nama restoran.

`SELLERS` dihapus. `SHOPS` konstanta tetap ada hanya sebagai bahan mentah migrasi;
setelah load, semua pembacaan lewat `state.shops`. Fungsi yang dialihkan:
`shopOf(id)` → `state.shops.find(...)`, `allPkgs()`, `pkgOf(id)`, `SHOP_ADDR` (alamat kini
ada di objek toko), `currentSeller()` → `currentOwner()`, `myShopIds()` →
`ownerOf(state.user.email).shops`, `shopNames(s)` → daftar nama toko pemilik ini.

`state.users` (pembeli) tidak berubah bentuknya.

## 4. Aturan validasi

Semua error tampil sebagai teks kecil di bawah field dan satu toast ringkas.

| Field | Aturan | Pesan |
| --- | --- | --- |
| Gelar | wajib pilih Tn / Ny / Nona | "Pilih gelar" |
| Nama lengkap | ≥ 3 karakter, huruf + spasi | "Nama minimal 3 huruf" |
| Email | registrasi penjual wajib `@gmail.com`; belum ada di `state.users` maupun `state.owners` | "Email harus @gmail.com" / "Email sudah dipakai akun pembeli, pakai email lain" |
| NIK | 16 digit angka, bukan email, belum terdaftar | "NIK harus 16 digit" / "NIK sudah terdaftar sebagai pemilik X. Login dulu, lalu Tambah Toko" |
| WA pemilik | `^0\d{8,13}$` atau `+62…` | "Nomor WA tidak valid — contoh 081234567890" |
| Foto | **wajib**, `image/*`, sebelum decode ≤ 8 MB; foto penjual dan foto restoran sama-sama wajib, foto toko kedua pun wajib | "Foto belum diunggah" / "File bukan gambar" / "Foto terlalu besar" |
| Nama restoran | ≥ 3 karakter, belum dipakai nama toko lain | "Nama restoran minimal 3 huruf" / "Nama restoran sudah dipakai" |
| Alamat fisik | ≥ 10 karakter | "Alamat fisik belum lengkap" |
| Link peta | diawali `https://`(maps.google.com \|goo.gl/…maps\|maps.app.goo.gl) | "Tempel link Google Maps" |
| WA CS | wajib, format sama dengan WA pemilik; saat form toko dibuka nilainya terisi dari WA pemilik dan boleh diganti | — |

Lintas peran (butir "akun pembeli tidak boleh duplikasi dengan akun penjual"):

* registrasi penjual dengan email yang sudah ada di `state.users` → ditolak.
* registrasi/login pembeli dengan email yang sudah ada di `state.owners` → ditolak,
  pesan "email ini akun penjual, pilih role Penjual".
* login role Penjual tapi emailnya pembeli → "email ini akun pembeli, pilih role Pembeli";
  sebaliknya login role Pembeli dengan email penjual diarahkan ke role Penjual.
  Role di layar login menentukan kotak data yang dicari, bukan sekadar tampilan.
| Password baru | ≥ 6 karakter, ≠ password sementara, konfirmasi cocok | "Password minimal 6 karakter" / "Tidak boleh sama dengan password sementara" |

Kasus khusus: pemilik yang sudah login menambahkan toko kedua → langkah 1 dilewati,
hanya form toko yang muncul, NIK pemilik dipakai lagi (butir 3).

## 5. Alur dan layar baru

1. **`v-reg-seller-1` — Data Diri Penjual.** Titik masuk: saat role di `v-register` dipilih
   Penjual, tombol SIMPAN berubah menjadi `DAFTARKAN TOKO` yang membawa ke layar ini;
   layar login juga mendapat satu tombol "Daftar sebagai penjual". Enam field di §4 +
   pratinjau foto. Tombol `Sesudah →` memanggil validasi, belum menyimpan apa pun.
2. **`v-reg-seller-2` — Data Toko.** Nama restoran, alamat fisik, link peta, WA CS, foto
   restoran. Tombol `← Sebelum` kembali tanpa menghapus isian (nilai hidup di field yang
   sama seperti wizard checkout). `Sesudah · DAFTARKAN` memanggil `createSellerAccount()`.
3. **`v-reg-done` — Akun terbit.** Menampilkan email, kode restoran, ID restoran
   (hanya di sini dan di dasbor penjual), dan **password sementara satu kali tampilan**.
   Akun sudah tersimpan saat layar ini dibuka, dan sesi di-logout supaya penjual benar-benar
   melewati jalur login (#9). Tombol `LOGIN SEKARANG` membuka `v-login` dengan email
   terisi, role Penjual aktif, dan password kosong (tidak dikembalikan ke layar).
4. **`v-s-reset` — Ganti Password.** Dipaksa bila `mustReset` (butir 8). Setelah sukses →
   `v-seller`.
5. **`sheet-resto` — Popup kode restoran** (butir 12): nama pemilik + gelar, alamat fisik,
   `Buka Peta` (link), WA CS penuh + `Chat WA` (`wa.me/<62…>`), dan kode restoran.
   ID restoran tidak pernah muncul di layar pembeli.
6. Dasbor penjual: chip toko aktif + tombol **Tambah Toko**, header menampilkan
   `kode` dan ID, dan pemilih toko memfilter daftar pesanan/menu.

Registrasi pembeli (`v-register` + `doRegister()`) tetap satu langkah seperti sekarang,
hanya ditambah cek "email sudah dipakai sebagai penjual".

## 6. Pembuatan kode, ID, dan password sementara

* `ownerKey` = `fnv-1a32(nik)` → `'ow-' + hex8`. Deterministik, tanpa salt, supaya NIK
  yang sama selalu jatuh ke pemilik yang sama.
* **Kode** = `inisialNamaPemilik(1 huruf kapital) + 4 digit terakhir NIK + String(run).padStart(3,'0')`,
  `run` = jumlah restoran milik pemilik itu sebelumnya + 1. Nama "Huang", NIK
  `3578090807064567` → `H4567001`, restoran berikutnya `H4567002`. Bila kode sudah dipakai
  (inisial + NIK + running bentrok), running dinaikkan sampai bebas.
* **ID restoran** = `100000 + floor(random()*900000)`, ditolak bila sudah dipakai
  (`state.shops`, termasuk empat ID hasil migrasi di §9); dicoba ulang maks 40 kali,
  lalu jatuh ke pencatatan sekuensial dari penghitung `state.seqId`.
* **Password sementara** = 8 karakter dari alfabet `abcdefghjkmnpqrstuvwxyz23456789`
  (tanpa `i l o 0 1`), dijamin ≥ 4 huruf dan ≥ 2 angka. Disimpan tersandi, `mustReset:true`,
  dan hanya ditampilkan di `v-reg-done`.

## 7. Perlindungan data (obfuscation, bukan enkripsi kepatuhan)

* `state.devKey` = 24 karakter acak, dibuat sekali saat migrasi, disimpan di `localStorage`.
* `enc(str)` = UTF-8 → byte → XOR berulang dengan byte `devKey` → Base64 → diberi
  penanda `e1:`. `dec(val)` mengembalikan nilai bila awalan `e1:` tidak ada, sehingga
  data lama tetap terbaca lalu ikut tersandi pada simpan berikutnya.
* Kolom yang disandi: nama pemilik, NIK, email, WA pemilik, WA CS, password penjual.
  Email dan NIK dibandingkan dengan **dekripsi** (bukan hash) — jumlah pemilik pada
  prototype kecil, jadi tabrakan hash tidak mungkin menimbulkan salah izin.
* Foto disimpan polos: mendekode Base64 + XOR ratusan KB lewat JS hanya memperlambat
  simulasi demo. Konsekuensinya dicatat di README.

## 8. Risiko yang diterima

| Risiko | Mitigasi |
| --- | --- |
| Kuota `localStorage` ±5 MB; 1 toko ≈ 2 foto × 100 KB | kompresi 640 px; tangkap `QuotaExceededError` → batal simpan foto saja, catatan tetap jadi, toast "Penyimpanan penuh — foto tidak tersimpan" |
| Obfuscation disalahartikan sebagai enkripsi | README + header spec menulis eksplisit "bukan enkripsi kepatuhan"; tidak ada klaim UU PDP untuk sisi penjual |
| `crypto.subtle` tidak tersedia di `file://` | tidak dipakai — XOR murni sinkron |
| Pembacaan toko pindah ke `state` bisa merusak alur lama | 4 toko bawaan dimigrasi dengan **ID dan paket yang sama**, plus daftar regresi §10 |
| Owner kedua mengintip order owner pertama | filter `myShopIds()` di semua jalur baca/tulis + uji silang di §10 |

## 9. Migrasi

`state.schema` dinaikkan ke `2`. Saat `load()` dan `schema !== 2`:

1. `state.shops = SHOPS` (deep copy) lalu dilengkapi `ownerKey`, `code`, `id`, `addr`
   (diambil dari `SHOP_ADDR` lama), `mapUrl`, `csWa`, `photo`, `builtin:true`.
2. Dua pemilik contoh dibuat, dan dua restoran terakhir menempel ke pemilik yang sama
   supaya demo multi-toko langsung hidup tanpa registrasi:

   | Pemilik | Gelar | NIK contoh | Email akun | Restoran (id → kode) |
   | --- | --- | --- | --- | --- |
   | Andi Ramadhan | Tn | `3578010203044567` | `rm.sederhana@gocatering.id` | RM Sederhana (`100234` → `A4567001`) · Kekinian Food (`100518` → `A4567002`) |
   | Sari Kumalasari | Ny | `3578020506078812` | `dapur.nusantara@gocatering.id` | Dapur Nusantara (`100742` → `S8812001`) · Catering Sehat (`100930` → `S8812002`) |

   Password kedua akun `seller123` dengan `mustReset:false`; `WA CS` = `082130000101`,
   `082130000102`, `082130000201`, `082130000202`; `mapUrl` memakai
   `https://www.google.com/maps/search/?api=1&query=<alamat>` sehingga tombol Buka Peta
   berfungsi tanpa API key; `photo` memakai gambar paket utama toko itu (mis.
   `assets/food/u1.jpg`) supaya tidak menambah ukuran penyimpanan.
   Email warisan berdomain `gocatering.id` sengaja dipertahankan (pesanan contoh, panel
   akun demo, dan README menunjuk ke sana); aturan `@gmail.com` hanya berlaku untuk
   registrasi baru, dan login penjual tidak memeriksa domain.
3. `state.users`, `state.orders`, `state.antrean`, `state.menuOff` tidak disentuh
   (non-destruktif, sama seperti pola migrasi v4.1).
4. Panel "Akun demo" dan tombol cepat di layar login menunjuk ke email penjual hasil
   migrasi.

## 10. Rencana pengujian

Otomatis (Node, tanpa browser) — `tools/boottest.js` diperluas:

* boot dengan `localStorage` kosong → tidak boleh melempar error, `state.shops.length === 4`,
  tiap toko punya `code` dan `id` 6 angka unik, tiap `ownerKey` ada di `state.owners`.
* regresi nomor: `kode` mengikuti `H4567001`/`H4567002`, tidak bentrok untuk dua pemilik
  dengan inisial dan NIK akhir sama (yang menentukan adalah NIK 16 digit penuh).
* `enc()/dec()` untuk teks unicode (`é`, `—`, emoji) dan nilai kosong.

Manual (browser, klik DOM nyata — bukan panggil fungsi):

1. Registrasi penjual baru "Huang", email `huang.test@gmail.com`, NIK
   `3578090807064567` (empat digit akhirnya sama dengan Andi, tapi 16 digitnya berbeda)
   → layar akun menampilkan kode `H4567001` dan ID 6 angka.
2. Login role Penjual dengan password sementara → terdampar di `v-s-reset`; password
   ditolak kalau = sementara; setelah ganti, masuk dasbor dan hanya tokonya yang muncul.
3. Tambah Toko kedua → `H4567002`; pemilih toko menampilkan dua toko dan pesanan tab
   mengikuti toko aktif.
4. Isolasi: login sebagai pemilik lain (Sari) → tab pesanan dan menu hanya berisi
   Dapur Nusantara + Catering Sehat; order milik Huang tidak muncul sama sekali,
   memaksa `shopId` toko orang lain (lewat tombol Tambah Toko → edit / lewat menu
   on-off) ditolak dengan toast "bukan restoran Anda". Pembeli tetap boleh memesan di
   semua toko — aturan ini hanya mengikat sisi penjual.
5. Duplikasi: email sudah ada → NIK sama tapi email baru ditolak; email sudah dipakai
   pembeli → ditolak.
6. Sisi pembeli: kartu toko menampilkan `kode: H4567001` dan tidak menampilkan ID;
   sentuh kode → popup berisi nama pemilik, alamat, `Buka Peta`, `Chat WA`.
7. Regresi alur lama: order pickup + antrean, delivery + ongkir, cutoff 16.00, bayar
   QRIS/COD, re-pay order pending, Jadwal Saya, profil + masking pembeli.
8. `node --check` skrip hasil ekstraksi, dan tidak ada pesan error di konsol browser.

Kriteria selesai: butir 1–12 permintaan pengguna terpenuhi dan semua langkah di atas hijau.
