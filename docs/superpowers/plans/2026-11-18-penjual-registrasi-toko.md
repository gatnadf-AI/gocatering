# Registrasi Penjual & Toko goCatering — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membuat penjual bisa mendaftar dari nol (data diri + toko), menerima akun & password sementara, punya kode restoran yang tampil ke pembeli, dan terisolasi dari toko milik penjual lain.

**Architecture:** Semua dikerjakan di satu berkas aplikasi baru `gocatering-prototype-v5.html` (salinan `gocatering-prototype-v4.html` yang lalu disunting; v4 dibiarkan utuh). Konstanta `SHOPS`/`SELLERS`/`SHOP_ADDR` turun kelas menjadi bahan mentah migrasi; sumber kebenaran tunggal saat runtime menjadi `state.shops` + `state.owners` yang dipaksa ada oleh `ensureSchema()` di dalam `load()`. Data pribadi disandikan XOR+Base64 dengan kunci per perangkat saat ditulis ke `localStorage` dan didekode saat dibaca, sehingga di memori selalu teks polos.

**Tech Stack:** HTML + CSS + JS vanilla satu berkas (tanpa build, tanpa CDN, tanpa server), Node.js v24 hanya untuk harness uji (`vm`), browser via MCP `browser-use`.

**Spec:** `docs/superpowers/specs/2026-11-17-penjual-registrasi-toko-design.md` — baca sebelum mengerjakan tugas mana pun; rencana ini hanya menerjemahkan butirnya menjadi langkah.

## Global Constraints

- Berkas aplikasi yang disunting: **`gocatering-prototype-v5.html`**. `gocatering-prototype-v4.html` **tidak boleh disentuh** (pembanding versi).
- Tidak ada dependensi jaringan, tidak ada `import`/`require`, tidak ada build step. Berkas harus tetap jalan saat dibuka lewat `file://`.
- Kunci penyimpanan: `const KEY='gocatering_v5'`; `state.schema = 2`.
- Data pribadi penjual (nama, NIK, email, WA pemilik, WA CS, password penjual) tidak boleh tersimpan sebagai teks polos di `localStorage`.
- Foto **opsional** di semua form; tidak ada satu pun field wajib yang berupa berkas gambar.
- ID restoran (6 angka) **tidak pernah** muncul di layar pembeli. Yang muncul hanya `code`.
- Tidak memakai `crypto.subtle` (tidak tersedia di `file://`), tidak memakai `escape()`/`unescape()`.
- Bahasa UI Indonesia; format uang lewat `rp()`; semua pesan error singkat dan tampil di bawah field (`<id>-err`) plus satu toast.
- **Aturan TDZ (penyebab situs publik mati di v4):** setiap `const`/`let` tingkat atas yang disentuh rantai `load()` — `rndKey`, `DEV_KEY`, `DEMO_OWNER`, `DEMO_SHOP`, `nextShopCode`, `newShopId`, `ensureSchema` — wajib berada **di atas** baris `let state = load();`. Fungsi baru sebaiknya `function` declaration (hoisted) supaya aman ditaruh di bagian mana pun.
- Commit di akhir **setiap** task. `git add <berkas>` eksplisit, jangan `git add -A`. Jangan `--no-verify`, jangan `git push` sebelum Task 10 (keputusan publikasi `docs/` masih menunggu jawaban pengguna).
- Gerbang selesai satu task = `node tools/test.js` hijau **dan** tidak ada pesan error di konsol browser.

## File Structure

| Berkas | Peran | Tugas |
| --- | --- | --- |
| `gocatering-prototype-v5.html` | aplikasi; satu-satunya berkas yang disunting Task 2–9 | 1–9 |
| `tools/harness.js` | mem-boot HTML apa pun di `vm` Node dengan stub `document`/`localStorage`/`window.open`, mengembalikan `run(expr)` yang bisa membaca binding tingkat atas skrip | 1 |
| `tools/test.js` | seluruh assertion (regresi v4 + fitur baru). Ditambah blok per task, dijalankan `node tools/test.js` | 1–9 |
| `tools/serve.js` | server statis `http://127.0.0.1:8848` supaya `browser-use` bisa menguji berkas lokal tanpa push ke GitHub Pages | 1 |
| `tools/boottest.js` | dibiarkan ter-gitignore, isinya diganti jadi 2 baris yang memanggil harness | 1 |
| `.gitignore` | `tools/` → `tools/*` + tiga re-include supaya harness ikut ke repo | 1 |
| `index.html`, `README.md`, `<title>`/`<h1>`/panel catatan v5 | label versi & dokumentasi | 10 |

Dalam berkas HTML, urutan blok yang dipakai rencana ini (nama bagian mengikuti komentar yang sudah ada di v4): `DATA` (konstanta + `KEY` + `state`), `UTIL`, `AUTH`, `PEMBELI: TOKO & KATALOG`, `CHECKOUT`, `PENJUAL`, `INIT`.

## Protokol Uji

**Otomatis (setiap task).** `node tools/test.js` dari akar repo. Harness mengeksekusi skrip inline HTML di sandbox `vm`; `run('...')` mengevaluasi ekspresi pada scope global skrip sehingga binding `let/const` tingkat atas bisa dibaca.

**Browser (task yang menyentuh DOM).** Jalankan `node tools/serve.js` (biarkan di latar), lalu:

```js
// 1) buka
mcp_call({toolName:'mcp__browser-use__navigate_page',
  arguments:{type:'url', url:'http://127.0.0.1:8848/gocatering-prototype-v5.html', timeout:15000}})
// 2) database bersih (penting: bug v4 dulu hanya muncul di penyimpanan kosong)
mcp_call({toolName:'mcp__browser-use__evaluate_script',
  arguments:{function:'() => { localStorage.clear(); return Object.keys(localStorage).length }'}})
mcp_call({toolName:'mcp__browser-use__navigate_page', arguments:{type:'reload', ignoreCache:true}})
// 3) klik nyata, jangan panggil fungsi aplikasi langsung
mcp_call({toolName:'mcp__browser-use__evaluate_script',
  arguments:{function:'() => { document.getElementById("Y").click(); return document.querySelector(".view.on").id }'}})
// 4) wajib kosong
mcp_call({toolName:'mcp__browser-use__list_console_messages', arguments:{}})
```

---

### Task 1: Salinan v5 + kerangka uji yang bisa dipakai ulang

**Files:**
- Create: `gocatering-prototype-v5.html` (salinan persis `gocatering-prototype-v4.html`)
- Create: `tools/harness.js`, `tools/serve.js`, `tools/test.js`
- Modify: `tools/boottest.js`, `.gitignore`

**Interfaces:**
- Consumes: tidak ada (task pertama).
- Produces: `boot(file, storage?) → { run, store, els, opened, errors, ctx }`; `run(expr) → nilai ekspresi pada scope skrip`; `store` (Map isi `localStorage`); `els` (Map elemen yang pernah disentuh); `opened` (array URL dari `window.open`). Untuk shell: `node tools/test.js` mencetak `n passed, 0 failed` dan exit 1 bila ada yang gagal.

- [ ] **Step 1: Salin v4 → v5 dan pastikan identik**

```bash
cd "C:/Users/USER/Documents/Qoder/2026-11-17/7e8556c0"
cp gocatering-prototype-v4.html gocatering-prototype-v5.html
cmp gocatering-prototype-v4.html gocatering-prototype-v5.html && echo "SALINAN IDENTIK"
```

Catatan: pada tahap ini `KEY` masih `'gocatering_v4'` dan isinya masih punya `SELLERS` — memang disengaja, supaya Task 2–4 bekerja di atas berkas yang sudah bisa diboot.

- [ ] **Step 2: Tulis `tools/harness.js`**

```js
'use strict';
/* Menjalankan skrip inline sebuah berkas HTML di sandbox Node (vm) dengan
   stub DOM secukupnya. Dipakai tools/test.js dan tools/boottest.js.
   Kenapa vm: prototype ini satu berkas tanpa modul, jadi satu-satunya cara
   mengujinya di Node adalah mengevaluasi skripnya apa adanya. */
const fs = require('fs'), path = require('path'), vm = require('vm');
const ROOT = path.join(__dirname, '..');

function extract(file) {
  const src = fs.readFileSync(path.join(ROOT, file), 'utf8').replace(/^\uFEFF/, '');
  const i = src.lastIndexOf('<script>'), j = src.lastIndexOf('</script>');
  if (i < 0 || j < 0 || j < i) throw new Error('blok <script> inline tidak ditemukan di ' + file);
  return src.slice(i + 8, j);
}

function mkEl(tag, id) {
  const el = {
    tagName: (tag || 'div').toUpperCase(), id: id || '', textContent: '', innerHTML: '',
    value: '', checked: false, type: '', href: '', src: '', files: [], dataset: {},
    style: { setProperty() {} },
    classList: { add() {}, remove() {}, toggle() {}, contains: () => false },
    addEventListener() {}, removeEventListener() {}, appendChild() {}, removeChild() {},
    insertAdjacentHTML(pos, html) { this.innerHTML += html; },
    click() {}, focus() {}, blur() {}, remove() {}, closest: () => null,
    getBoundingClientRect: () => ({ top: 0, left: 0, width: 380, height: 800, bottom: 800, right: 380 }),
    getAttribute(k) { return this['_a_' + k] === undefined ? null : this['_a_' + k]; },
    setAttribute(k, v) { this['_a_' + k] = String(v); },
    removeAttribute(k) { delete this['_a_' + k]; },
    querySelector: (sel) => getEl(sel),
    querySelectorAll: () => []
  };
  return el;
}

function boot(file, storage) {
  const store = new Map(Object.entries(storage || {}));
  const els = new Map();
  const getEl = (id) => { if (!els.has(id)) els.set(id, mkEl('div', id)); return els.get(id); };
  const document = {
    getElementById: getEl,
    querySelector: (sel) => getEl(sel),
    querySelectorAll: () => [],
    createElement: (tag) => mkEl(tag, ''),
    addEventListener() {}, removeEventListener() {},
    body: mkEl('body', 'body'), documentElement: mkEl('html', 'html'),
    title: '', visibilityState: 'visible'
  };
  const localStorage = {
    getItem: (k) => (store.has(k) ? store.get(k) : null),
    setItem: (k, v) => { store.set(k, String(v)); },
    removeItem: (k) => { store.delete(k); },
    key: (i) => Array.from(store.keys())[i] || null,
    get length() { return store.size; }
  };
  const opened = [], errors = [];
  const ctx = {
    console, document, localStorage,
    setTimeout: () => 0, clearTimeout() {}, setInterval: () => 0, clearInterval() {},
    requestAnimationFrame: () => 0, cancelAnimationFrame() {},
    navigator: { userAgent: 'node-harness' },
    location: { href: 'http://127.0.0.1:8848/', reload() {} },
    alert() {}, prompt: () => 'x'.repeat(12), confirm: () => true,
    open: (u) => { opened.push(u); return null; },
    TextEncoder, TextDecoder, Uint8Array, btoa: globalThis.btoa, atob: globalThis.atob,
    JSON, Math, Date, Object, Array, String, Number, Boolean, RegExp, Error, TypeError,
    Map, Set, Promise, Symbol, isNaN, isFinite, parseInt, parseFloat,
    encodeURIComponent, decodeURIComponent, encodeURI, decodeURI
  };
  ctx.window = ctx; ctx.globalThis = ctx; ctx.self = ctx;
  vm.createContext(ctx);
  try {
    vm.runInContext(extract(file), ctx, { filename: file });
  } catch (e) { errors.push(e); }
  return {
    ctx, store, els, opened, errors,
    run: (expr) => vm.runInContext('(function(){return (' + expr + ')})()', ctx, { filename: 'run' })
  };
}

module.exports = { boot, extract, ROOT };
```

`btoa`/`atob` dan `TextEncoder` wajib diekspos eksplisit: konteks `vm` tidak mewarisi seluruh global Node, dan `enc()` di Task 2 membutuhkannya.

- [ ] **Step 3: Tulis `tools/serve.js`**

```js
'use strict';
/* Server statis tanpa dependensi untuk uji browser di berkas lokal.
   Jalankan: node tools/serve.js [port]   (default 8848) */
const http = require('http'), fs = require('fs'), path = require('path');
const root = path.join(__dirname, '..'), port = Number(process.argv[2]) || 8848;
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png',
  '.svg': 'image/svg+xml', '.json': 'application/json', '.webp': 'image/webp' };
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/') p = '/index.html';
  const f = path.join(root, p);
  if (!f.startsWith(root)) { res.writeHead(403); return res.end('403'); }
  fs.readFile(f, (e, b) => {
    if (e) { res.writeHead(404); return res.end('404'); }
    res.writeHead(200, { 'Content-Type': types[path.extname(f).toLowerCase()] || 'application/octet-stream' });
    res.end(b);
  });
}).listen(port, () => console.log('goCatering: http://127.0.0.1:' + port + '/gocatering-prototype-v5.html'));
```

- [ ] **Step 4: Tulis `tools/test.js` dengan kerangka + uji karaterisasi v4**

```js
'use strict';
const { boot, extract } = require('./harness');
const V4 = 'gocatering-prototype-v4.html', V5 = 'gocatering-prototype-v5.html';
let pass = 0; const fails = [];
function t(name, fn) {
  try { fn(); pass++; console.log('  ok   ' + name); }
  catch (e) { fails.push(name + ' :: ' + e.message); console.log('  GAGAL ' + name + '\n         ' + e.message); }
}
function eq(a, b, lbl) { if (a !== b) throw new Error((lbl || 'nilai') + ': dapat ' + JSON.stringify(a) + ', harus ' + JSON.stringify(b)); }
function ok(v, msg) { if (!v) throw new Error(msg || 'harusnya benar'); }
function has(str, needle, lbl) { if (String(str).indexOf(needle) < 0) throw new Error((lbl || 'teks') + ' tidak memuat ' + JSON.stringify(needle)); }
function hasnt(str, needle, lbl) { if (String(str).indexOf(needle) >= 0) throw new Error((lbl || 'teks') + ' masih memuat ' + JSON.stringify(needle)); }
function fresh(seed) { const b = boot(V5, seed || {}); if (b.errors.length) throw new Error('boot melempar: ' + b.errors[0].message); return b; }

console.log('\n== REGRESI v4 (data seed bawaan) ==');
t('seed punya 9 pesanan contoh', () => {
  const b = boot(V4, {}); if (b.errors.length) throw new Error(b.errors[0].message);
  eq(b.run('state.orders.length'), 9, 'order');
});
t('seed v5 (salinan) punya 9 pesanan contoh', () => {
  const b = fresh(); eq(b.run('state.orders.length'), 9, 'order');
});
t('nomor antrean memakai awalan per toko', () => {
  const b = fresh();
  has(b.run('nextQueueNo("rm-sederhana","2099-01-01")'), 'A-', 'nomor');
});
t('ongkir memakai tarif minimum', () => {
  const b = fresh();
  eq(b.run('fulfillment="delivery", deliveryService="gosend", distanceKm=1, deliveryFee()'), 12000, 'ongkir 1 km');
});
t('cutoff 16.00 terdeteksi lewat jam simulasi', () => {
  const b = fresh();
  b.run('setSimHour(17)');
  eq(b.run('pastCutoff()'), true, 'lewat cutoff');
  b.run('setSimHour(10)');
  eq(b.run('pastCutoff()'), false, 'sebelum cutoff');
});
t('WA share memakai nomor toko & wa.me', () => {
  const b = fresh();
  b.run('waOrder("GC-2411-00A1")');
  has(b.opened[0], 'https://wa.me/6281234567801', 'link WA');
});
t('skrip terbaca utuh oleh harness', () => {
  has(extract(V5), 'function load()', 'script');
});

console.log('\n' + pass + ' passed, ' + fails.length + ' failed');
if (fails.length) { fails.forEach(f => console.log(' - ' + f)); process.exit(1); }
```

Uji di atas adalah **uji karakterisasi**: diharapkan langsung PASS. Fungsinya membuktikan harness benar sebelum ada satu pun baris aplikasi yang diubah. Kalau ada yang GAGAL, perbaiki stub di harness (atau nama fungsi di test) — jangan mengubah berkas HTML, dan jangan menghapus uji hanya karena gagal. Nama fungsi yang dipakai di sini sudah diverifikasi ada di v4: `nextQueueNo` (v4:760), `deliveryFee` (v4:880), `setSimHour` (v4:1177), `pastCutoff` (v4:1161), `waOrder` (v4:1667).


- [ ] **Step 5: Jalankan test, pastikan hijau**

Run: `node tools/test.js`
Expected: `7 passed, 0 failed` (atau 6 bila satu uji karakterisasi harus disesuaikan dengan nama fungsi yang sebenarnya — lihat Catatan Step 4).

- [ ] **Step 6: Rampingkan `tools/boottest.js`**

```js
'use strict';
/* Boot cepat satu berkas di Node untuk melihat apakah skripnya mati di tengah.
   Pemakaian: node tools/boottest.js [berkas.html] */
const { boot } = require('./harness');
const file = process.argv[2] || 'gocatering-prototype-v5.html';
const b = boot(file);
if (b.errors.length) { console.error('GAGAL SAAT LOAD: ' + b.errors[0].message); process.exit(1); }
console.log('BOOT OK ' + file + ' · orders=' + b.run('state.orders.length') + ' · key=' + b.run('KEY'));
```

- [ ] **Step 7: Ubah `.gitignore` supaya harness ikut ke repo**

Ganti baris `tools/` menjadi:

```gitignore
tools/*
!tools/harness.js
!tools/serve.js
!tools/test.js
```

Run: `git check-ignore -v tools/harness.js tools/boottest.js`
Expected: hanya `tools/boottest.js` yang dilaporkan terabaikan.

- [ ] **Step 8: Cek lewat browser (baseline, sebelum ada perubahan aplikasi)**

```bash
node tools/serve.js    # biarkan berjalan di latar
```

Buka `http://127.0.0.1:8848/gocatering-prototype-v5.html` dengan protokol uji; setelah `localStorage.clear()` + reload, assert:

```js
() => ({ view: document.querySelector('.view.on').id, shops: document.querySelectorAll('#shop-list .shopcard').length })
```

Expected: `{view:'v-login', shops:0}` (0 karena belum login) dan konsol bersih.

- [ ] **Step 9: Commit**

```bash
git add gocatering-prototype-v5.html tools/harness.js tools/serve.js tools/test.js .gitignore
git commit -m "chore(v5): salinan v4 + harness uji vm, server statis, dan test regresi awal"
```

---

### Task 2: Kunci perangkat + `enc()`/`dec()` (spec §7)

**Files:**
- Modify: `gocatering-prototype-v5.html` — blok `const KEY='gocatering_v4';` (v4:702), `load()` (v4:766), `save()` (v4:782), `resetData()` (v4:783)
- Modify: `tools/test.js` — blok baru sebelum baris ringkasan

**Interfaces:**
- Consumes: `boot()/run()` dari Task 1.
- Produces: `DEV_KEY` (string, binding `let` di atas `state`), `rndKey() → 24 char`, `enc(v) → 'e1:'+base64 | ''`, `dec(v) → teks polos | nilai asal bila tanpa awalan`, `CRYPT = {owners:[...], shops:['csWa']}`, `cryptRows(rows, fields, fn)`. `save()` mengembalikan `true`/`false` dan menyimpan **salinan** yang sudah disandikan; `state` di memori selalu polos.

- [ ] **Step 1: Tulis uji yang gagal**

Tambahkan ke `tools/test.js` sebelum `console.log('\n' + pass + ...)`:

```js
console.log('\n== TASK 2 — penyandian data penjual ==');
t('enc/dec bolak-balik untuk teks unicode & emoji', () => {
  const b = fresh();
  ['Andi Ramadhan', 'Sari Kumalasari é—', 'Menu 🍽️ Sehat', 'a@b.co', '081234567890', 'p1'].forEach(s => {
    eq(b.run('dec(enc(' + JSON.stringify(s) + '))'), s, 'roundtrip ' + s);
  });
});
t('hasil enc tidak memuat teks aslinya dan berawalan e1:', () => {
  const b = fresh();
  const e = b.run('enc("3578090807064567")');
  has(e, 'e1:', 'awalan'); hasnt(e, '3578', 'plaintext bocor');
});
t('nilai lama tanpa awalan tetap terbaca, string kosong aman', () => {
  const b = fresh();
  eq(b.run('dec("teks-lama-polos")'), 'teks-lama-polos', 'passthrough');
  eq(b.run('enc("")'), '', 'kosong'); eq(b.run('dec("")'), '', 'kosong');
  eq(b.run('dec(null)'), '', 'null');
});
t('save() menyandikan kolom penjual dan membiarkan kolom pembeli', () => {
  const b = fresh();
  b.run('state.owners={zz:{key:"zz",nama:"Andi é🍽",nik:"3578090807064567",email:"a@b.co",phone:"081234567890",password:"rahasiaSekali",shops:[]}}');
  b.run('state.shops=[{id:"100234",name:"RM X",csWa:"082130000101",photo:"data:image/jpeg;base64,AAA"}]');
  ok(b.run('save()'), 'save sukses');
  const raw = b.store.get(b.run('KEY'));
  hasnt(raw, 'rahasiaSekali', 'password polos'); hasnt(raw, '3578090807064567', 'NIK polos');
  hasnt(raw, 'a@b.co', 'email penjual polos'); hasnt(raw, '082130000101', 'WA CS polos');
  has(raw, 'e1:', 'penanda sandi');
  has(raw, 'data:image/jpeg;base64,AAA', 'foto ikut tersimpan (memang tidak disandi)');
  has(raw, 'budi@mail.com', 'akun pembeli tidak berubah bentuk');
});
t('boot ulang membaca kembali data yang sama', () => {
  const b1 = fresh();
  b1.run('state.owners={zz:{key:"zz",nama:"Sari é",nik:"3578010203044567",email:"s@gocatering.id",phone:"0812",password:"seller123",shops:[]}}');
  b1.run('save()');
  const raw = b1.store.get(b1.run('KEY'));
  const b2 = boot(V5, (() => { const o = {}; o[b1.run('KEY')] = raw; return o; })());
  if (b2.errors.length) throw new Error(b2.errors[0].message);
  eq(b2.run('state.owners.zz.nama'), 'Sari é', 'nama pulih');
  eq(b2.run('state.owners.zz.password'), 'seller123', 'password pulih');
  eq(b2.run('dec(state.owners.zz.nik)'), '3578010203044567', 'nik pulih');
});
t('devKey dibuat sekali dan dipertahankan', () => {
  const b1 = fresh(); const k1 = b1.run('state.devKey');
  eq(k1.length, 24, 'panjang kunci');
  b1.run('save()');
  const raw = b1.store.get(b1.run('KEY'));
  const b2 = boot(V5, (() => { const o = {}; o[b1.run('KEY')] = raw; return o; })());
  eq(b2.run('state.devKey'), k1, 'kunci stabil');
});
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `node tools/test.js`
Expected: `GAGAL enc/dec bolup-balik … enc is not defined` (binding `enc` memang belum ada). Kalau malah `boot melempar`, berarti stub Task 1 belum benar — perbaiki harness lebih dulu.

- [ ] **Step 3: Implementasi — letakkan tepat di bawah `const KEY=...` dan di ATAS `let state = load();`**

```js
/* ================= KEAMANAN DATA (obfuscation, BUKAN enkripsi kepatuhan) =================
   XOR + Base64 dengan kunci acak per perangkat. Tujuannya supaya NIK/email/password tidak
   terbaca mata saat localStorage dibuka di DevTools — bukan untuk kepatuhan UU PDP.
   DEV_KEY dipakai oleh dec() yang berjalan DI DALAM load(), jadi ia tidak boleh membaca
   state.devKey: state belum terikat saat load() dieksekusi ( TDZ — bug yang dulu mematikan
   situs publik ). Kunci disalin ke DEV_KEY begitu nilainya diketahui. */
const CRYPT = { owners:['nama','nik','email','phone','password'], shops:['csWa'] };
let DEV_KEY = 'gocatering-devkey-cadangan';
function rndKey(){ const A='abcdefghjkmnpqrstuvwxyz23456789'; let s=''; for(let i=0;i<24;i++) s+=A[Math.floor(Math.random()*A.length)]; return s; }
function keyBytes(){ return Array.from(new TextEncoder().encode(DEV_KEY)); }
function enc(v){
  if(v===null||v===undefined||v==='') return '';
  const s=String(v); if(s.indexOf('e1:')===0) return s;
  const bytes=Array.from(new TextEncoder().encode(s)), k=keyBytes(); let bin='';
  for(let i=0;i<bytes.length;i++) bin+=String.fromCharCode(bytes[i]^k[i%k.length]);
  return 'e1:'+btoa(bin);
}
function dec(v){
  if(v===null||v===undefined||v==='') return '';
  const s=String(v); if(s.indexOf('e1:')!==0) return s;
  try{
    const bin=atob(s.slice(3)), k=keyBytes(), bytes=new Uint8Array(bin.length);
    for(let i=0;i<bin.length;i++) bytes[i]=bin.charCodeAt(i)^k[i%k.length];
    return new TextDecoder().decode(bytes);
  }catch(e){ return s; }
}
function cryptRows(rows,fields,fn){
  if(!rows) return;
  (Array.isArray(rows)?rows:Object.values(rows)).forEach(r=>{
    if(!r||typeof r!=='object') return;
    fields.forEach(f=>{ if(typeof r[f]==='string'&&r[f]!=='') r[f]=fn(r[f]); });
  });
}
```

XOR dilakukan pada **byte UTF-8**, bukan pada code unit UTF-16. Kalau tidak, emoji (surrogate pair) menghasilkan code unit di luar 0–255 dan `btoa` melempar.

- [ ] **Step 4: Pasang ke `save()`**

Ganti `function save(){ try{localStorage.setItem(KEY,JSON.stringify(state));}catch(e){} }` menjadi:

```js
function save(){
  const copy=JSON.parse(JSON.stringify(state));
  cryptRows(copy.owners,CRYPT.owners,enc); cryptRows(copy.shops,CRYPT.shops,enc);
  try{ localStorage.setItem(KEY,JSON.stringify(copy)); return true; }
  catch(e){
    /* kuota penuh: ulangi tanpa foto (foto memang opsional, lihat spec §8) */
    const slim=JSON.parse(JSON.stringify(state));
    (slim.shops||[]).forEach(s=>{ if(String(s.photo||'').indexOf('data:')===0) s.photo=''; });
    Object.values(slim.owners||{}).forEach(o=>{ if(String(o.photo||'').indexOf('data:')===0) o.photo=''; });
    cryptRows(slim.owners,CRYPT.owners,enc); cryptRows(slim.shops,CRYPT.shops,enc);
    try{ localStorage.setItem(KEY,JSON.stringify(slim)); toast('Penyimpanan penuh — foto tidak tersimpan','err'); }
    catch(e2){ toast('Gagal menyimpan data','err'); }
    return false;
  }
}
```

- [ ] **Step 5: Pasang ke `load()`**

Di dalam `load()`, tepat setelah `if(!s){ ... }` (blok pembentuk seed) dan sebelum baris `s.users=s.users||{};`, sisipkan:

```js
  /* kunci perangkat + dekripsi data penjual (data lama tanpa awalan tetap terbaca) */
  if(!s.devKey) s.devKey=rndKey();
  DEV_KEY=s.devKey;
  cryptRows(s.owners,CRYPT.owners,dec); cryptRows(s.shops,CRYPT.shops,dec);
```

`resetData()` tidak diubah (ia menghapus kunci lama, lalu `load()` membuat kunci baru).

- [ ] **Step 6: Jalankan test sampai hijau**

Run: `node tools/test.js`
Expected: semua uji Task 1 (regresi) **tetap** hijau + 6 uji Task 2 hijau.

- [ ] **Step 7: Cek konsol browser**

Protokol uji browser (clear + reload + klik dua tombol) → `list_console_messages` harus kosong.

- [ ] **Step 8: Commit**

```bash
git add gocatering-prototype-v5.html tools/test.js
git commit -m "feat(v5): kunci perangkat + penyandian kolom pribadi penjual saat disimpan"
```

---

### Task 3: Generator murni — ownerKey, kode restoran, ID, password sementara (spec §6)

**Files:**
- Modify: `gocatering-prototype-v5.html` (blok baru, tetap **di atas** `let state = load();`)
- Modify: `tools/test.js`

**Interfaces:**
- Consumes: harness Task 1.
- Produces:
  - `fnv32(str) → hex 8 karakter` ; `ownerKeyOf(nik) → 'ow-'+hex8`
  - `letterOf(nama) → 'H'` ; `nextShopCode({name,nik,shops}) → 'H4567001'` (naikkan running sampai bebas bentrok)
  - `newShopId(taken, opt?) → '100234'` (`opt={tries,rand}` untuk uji; jatuh ke `state.seqId`)
  - `tempPassword(opt?) → 8 char` (≥4 huruf, ≥2 angka, tanpa `i l o 0 1`)
  - `toIntl('0812…') → '62812…'` ; `waLink(n) → 'https://wa.me/62…'`
  - Regex: `RE_EMAIL`, `RE_GMAIL`, `RE_NIK`, `RE_PHONE`, `RE_MAP`, `NAME_OK`

- [ ] **Step 1: Tulis uji yang gagal**

```js
console.log('\n== TASK 3 — generator ==');
t('ownerKeyOf deterministik dan stabil', () => {
  const b = fresh();
  eq(b.run('ownerKeyOf("3578090807064567")'), b.run('ownerKeyOf("3578090807064567")'), 'stabil');
  ok(/^ow-[0-9a-f]{8}$/.test(b.run('ownerKeyOf("3578090807064567")')), 'bentuk ow-hex8');
  ok(b.run('ownerKeyOf("3578010203044567")') !== b.run('ownerKeyOf("3578090807064567")'), 'beda untuk NIK beda');
});
t('kode = inisial nama pemilik + 4 digit akhir NIK + running per pemilik', () => {
  const b = fresh();
  const mk = (n, nik, shops, key) => 'nextShopCode({name:' + JSON.stringify(n) + ',nik:' + JSON.stringify(nik)
    + ',shops:' + JSON.stringify(shops) + (key ? ',ownerKey:' + JSON.stringify(key) : '') + '})';
  eq(b.run(mk('Huang', '3578090807064567', [])), 'H4567001', 'toko pertama');
  eq(b.run(mk('Huang', '3578090807064567', [{ code: 'H4567001', ownerKey: 'K' }], 'K')), 'H4567002', 'toko kedua pemilik sama');
  eq(b.run(mk('sari kumalasari', '3578020506078812', [])), 'S8812001', 'huruf besar & nama dua kata');
  eq(b.run(mk('Ng We Ling', '3578090807064567', [])), 'N4567001', 'huruf pertama, bukan suku kata');
  /* dua pemilik berbeda dengan inisial & 4 digit akhir sama: kode tetap unik secara global
     (spec §6: "bila kode sudah dipakai, running dinaikkan sampai bebas") */
  eq(b.run(mk('Hendra', '3578111111114567', [{ code: 'H4567001', ownerKey: 'ow-A' }], 'ow-B')), 'H4567002', 'bentrok global dinaikkan');
});
t('kode bentrok dinaikkan running-nya sampai bebas', () => {
  const b = fresh();
  const shops = [{ code: 'H4567001', ownerKey: 'ow-A' }, { code: 'H4567002', ownerKey: 'ow-A' }];
  eq(b.run('nextShopCode({name:"Huang",nik:"3578090807064567",shops:' + JSON.stringify(shops) + ',ownerKey:"ow-A"})'), 'H4567003', 'running naik');
});
t('newShopId: 6 angka, unik terhadap daftar taken, bisa dipaksa fallback', () => {
  const b = fresh();
  const taken = Array.from({ length: 50 }, (_, i) => String(100000 + i));
  const ids = b.run('(function(){var t=' + JSON.stringify(taken) + ',o=[];for(var i=0;i<50;i++)o.push(newShopId(t));return o})()');
  eq(ids.length, 50, 'jumlah'); eq(new Set(ids).size, 50, 'unik antar hasil');
  ids.forEach(id => ok(/^\d{6}$/.test(id) && taken.indexOf(id) < 0, 'ID cacat: ' + id));
  eq(b.run('state.seqId=100000; newShopId(["100000","100001"],{tries:1,rand:function(){return 0}})'), '100002', 'fallback sekuensial');
  eq(b.run('state.seqId'), 100002, 'penghitung ikut maju');
});
t('tempPassword: 8 char, aman dibaca, minimal 4 huruf & 2 angka', () => {
  const b = fresh();
  const list = b.run('(function(){var o=[];for(var i=0;i<300;i++)o.push(tempPassword());return o})()');
  list.forEach(p => {
    eq(p.length, 8, 'panjang ' + p);
    ok(!/[ilo01]/.test(p), 'mengandung huruf/angka terlarang: ' + p);
    ok((p.match(/[a-z]/g) || []).length >= 4, 'kurang huruf: ' + p);
    ok((p.match(/[0-9]/g) || []).length >= 2, 'kurang angka: ' + p);
  });
  eq(new Set(list).size > 250, true, 'terlalu mudah berulang');
  eq(b.run('tempPassword({rand:function(){return 0.5}}).length'), 8, 'rand tersuntik');
});
t('toIntl & waLink menormalkan nomor WA', () => {
  const b = fresh();
  eq(b.run('toIntl("082130000101")'), '6282130000101', 'nol depan');
  eq(b.run('toIntl("+62 821-3000-0101")'), '6282130000101', 'format internasional');
  eq(b.run('toIntl("6281234567801")'), '6281234567801', 'sudah 62');
  eq(b.run('waLink("082130000101")'), 'https://wa.me/6282130000101', 'link');
});
t('regex validasi berperilaku sesuai spec §4', () => {
  const b = fresh();
  const yes = (re, s) => ok(b.run(re + '.test(' + JSON.stringify(s) + ')'), re + ' harus cocok dengan ' + s);
  const no = (re, s) => ok(!b.run(re + '.test(' + JSON.stringify(s) + ')'), re + ' harus menolak ' + s);
  yes('RE_NIK', '3578090807064567'); no('RE_NIK', '357809080706456'); no('RE_NIK', 'huang@test@gmail.com');
  yes('RE_GMAIL', 'huang.test@gmail.com'); no('RE_GMAIL', 'huang@yahoo.com'); no('RE_GMAIL', 'huang@gmail.co');
  yes('RE_PHONE', '081234567890'); yes('RE_PHONE', '+6281234567890'); no('RE_PHONE', '12345'); no('RE_PHONE', '08');
  yes('RE_MAP', 'https://maps.app.goo.gl/abc'); yes('RE_MAP', 'https://www.google.com/maps/search/?api=1&query=x');
  no('RE_MAP', 'http://maps.app.goo.gl/abc'); no('RE_MAP', 'Jl. Tunjungan No 45');
  yes('NAME_OK', 'Andi Ramadhan'); no('NAME_OK', 'RM 45'); no('NAME_OK', "ab"); no('NAME_OK', 'nama{jahat}');
});
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `node tools/test.js` → uji Task 3 `GAGAL ... ownerKeyOf is not defined`, uji Task 1–2 tetap hijau.

- [ ] **Step 3: Implementasi (tetap di atas `let state = load();`, setelah blok Task 2)**

```js
/* ================= GENERATOR IDENTITAS (spec §6) ================= */
const RE_EMAIL=/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const RE_GMAIL=/^[a-z0-9](?:[a-z0-9._%+-]*[a-z0-9])?@gmail\.com$/i;
const RE_NIK=/^\d{16}$/;
const RE_PHONE=/^(?:0\d{8,13}|\+?62\d{8,13})$/;
const RE_MAP=/^https:\/\/(?:www\.google\.com\/maps|maps\.google\.com|maps\.app\.goo\.gl|goo\.gl\/)/;
const NAME_OK=/^[A-Za-z .'-]{3,}$/;
const GELAR=['Tn','Ny','Nona'];

function fnv32(str){
  let h=0x811c9dc5;
  for(let i=0;i<str.length;i++){ h^=str.charCodeAt(i); h=Math.imul(h,0x01000193)>>>0; }
  return ('00000000'+(h>>>0).toString(16)).slice(-8);
}
function ownerKeyOf(nik){ return 'ow-'+fnv32(String(nik).replace(/\D/g,'')); }
function letterOf(nama){
  const s=String(nama||'').replace(/[^A-Za-z]/g,'');
  return (s[0]||'R').toUpperCase();
}
/* kode = inisial nama PEMILIK + 4 digit akhir NIK + running per pemilik (mulai 001) */
function nextShopCode(o){
  const ownerKey=o.ownerKey||ownerKeyOf(o.nik||'');
  const head=letterOf(o.name)+String(o.nik||'0000').replace(/\D/g,'').slice(-4);
  const used=new Set((o.shops||[]).filter(s=>s.ownerKey===ownerKey).map(s=>s.code));
  let run=used.size+1, code=head+String(run).padStart(3,'0');
  while((o.shops||[]).some(s=>s.code===code)) { run++; code=head+String(run).padStart(3,'0'); }
  return code;
}
function newShopId(taken,opt){
  opt=opt||{}; const tries=opt.tries==null?40:opt.tries, rand=opt.rand||Math.random;
  const used=new Set((taken||[]).map(String));
  for(let i=0;i<tries;i++){
    const id=String(100000+Math.floor(rand()*900000));
    if(/^\d{6}$/.test(id)&&!used.has(id)) return id;
  }
  let n=Math.max(100000,Number(state&&state.seqId||100000)+1);
  while(used.has(String(n))) n++;
  if(state) state.seqId=n;
  return String(n);
}
function tempPassword(opt){
  opt=opt||{}; const r=opt.rand||Math.random;
  const L='abcdefghjkmnpqrstuvwxyz', D='23456789', c=[];
  for(let i=0;i<6;i++) c.push(L[Math.floor(r()*L.length)]);
  for(let i=0;i<2;i++) c.push(D[Math.floor(r()*D.length)]);
  for(let i=c.length-1;i>0;i--){ const j=Math.floor(r()*(i+1)), t=c[i]; c[i]=c[j]; c[j]=t; }
  return c.join('');
}
function toIntl(n){
  n=String(n||'').replace(/[^0-9+]/g,'');
  if(n.charAt(0)==='0') return '62'+n.slice(1);
  if(n.indexOf('+62')===0) return n.slice(1);
  return n;
}
function waLink(n){ return 'https://wa.me/'+toIntl(n); }
```

- [ ] **Step 4: Jalankan test sampai hijau**

Run: `node tools/test.js` → uji Task 1–3 hijau semua.

- [ ] **Step 5: Commit**

```bash
git add gocatering-prototype-v5.html tools/test.js
git commit -m "feat(v5): generator ownerKey, kode restoran, ID unik, dan password sementara"
```

---

### Task 4: Model data, migrasi v4→v5, dan pembacaan lewat `state.shops` (spec §3, §9)

**Files:**
- Modify: `gocatering-prototype-v5.html` — `const KEY` (v4:702), hapus `const SELLERS` (v4:665-668), `load()` (v4:766-781), `shopOf/pkgOf/allPkgs` (v4:791-793), `SHOP_ADDR` pemakai (v4:1441, 1652, 1677), `currentSeller/shopNames` (v4:889-890), `fillDemo` (v4:1008-1013), `renderChrome` (v4:872), `myShopIds/sellerOrders` (v4:1707-1708), `waOrder` (v4:1668), `orderSuccess` (v4:1677)
- Modify: `tools/test.js`

**Interfaces:**
- Consumes: Task 2 (`rndKey`, `cryptRows`, `DEV_KEY`, `CRYPT`), Task 3 (`buildShops` memanggil `nextShopCode`/`ownerKeyOf`, `newShopId`).
- Produces:
  - `state.owners` (map), `state.shops` (array), `state.devKey`, `state.seqId`, `state.sellerShop`, `state.schema=2`
  - `DEMO_OWNER` (2 pemilik contoh), `DEMO_SHOP` (`[id6, ownerKey, csWa]` **seposisional** dengan `SHOPS`)
  - `buildShops() → shop[]`, `indexOwners(owners, shops) → owners`, `ensureSchema(s) → s`, `remapShopIds(s) → s`
  - `shopOf(id)`, `shopAddr(id)`, `pkgOf(id)`, `allPkgs()`, `findOwner(field, value)`, `currentOwner()`, `currentSeller()` ( shim ), `myShopIds()`, `sellerOrders()`, `activeShop()`, `ensureSellerShop()`, `shopNames(s)`

- [ ] **Step 1: Tulis uji yang gagal**

```js
console.log('\n== TASK 4 — model data & migrasi ==');
const SLUGS = ['rm-sederhana', 'dapur-nusantara', 'catering-sehat', 'kekinian-food'];
t('DEMO_SHOP sejajar posisi dengan SHOPS (invarian yang dipakai buildShops)', () => {
  const b = fresh();
  eq(JSON.stringify(b.run('SHOPS.map(s=>s.id)')), JSON.stringify(SLUGS), 'urutan slug');
  eq(b.run('DEMO_SHOP.length'), 4, 'jumlah baris DEMO_SHOP');
});
t('4 toko bawaan punya id 6 angka unik, kode, dan pemilik', () => {
  const b = fresh();
  eq(b.run('state.shops.length'), 4, 'jumlah toko');
  const ids = b.run('state.shops.map(s=>s.id)'), codes = b.run('state.shops.map(s=>s.code)');
  ids.forEach(id => ok(/^\d{6}$/.test(id), 'id ' + id));
  eq(new Set(ids).size, 4, 'id unik'); eq(new Set(codes).size, 4, 'kode unik');
  eq(b.run('state.shops.every(s=>!!state.owners[s.ownerKey])'), true, 'setiap toko punya pemilik terindeks');
  eq(b.run('Object.keys(state.owners).length'), 2, 'jumlah pemilik contoh');
});
t('kode pemilik contoh persis seperti spec §9', () => {
  const b = fresh();
  const want = { 'rm-sederhana': ['100234', 'A4567001'], 'kekinian-food': ['100518', 'A4567002'],
                 'dapur-nusantara': ['100742', 'S8812001'], 'catering-sehat': ['100930', 'S8812002'] };
  Object.keys(want).forEach(slug => {
    const i = SLUGS.indexOf(slug);
    eq(b.run('state.shops[' + i + '].id'), want[slug][0], 'id ' + slug);
    eq(b.run('state.shops[' + i + '].code'), want[slug][1], 'kode ' + slug);
  });
});
t('satu pemilik memegang dua toko dan pemilik tidak berbagi antar akun', () => {
  const b = fresh();
  const andi = b.run('findOwner("nik","3578010203044567")');
  ok(andi, 'Andi ditemukan lewat NIK');
  eq(b.run('findOwner("nik","3578010203044567").shops.length'), 2, 'dua toko');
  eq(b.run('findOwner("email","rm.sederhana@gocatering.id").key'), b.run('findOwner("nik","3578010203044567").key'), 'email & nik pemilik sama');
  ok(b.run('!!findOwner("email","DAPUR.NUSANTARA@GOCATERING.ID")'), 'perbandingan email tidak peka huruf');
});
t('pesan seed memakai id 6 angka dan tetap terhubung ke tokonya', () => {
  const b = fresh();
  eq(b.run('state.orders.every(o=>/^\\d{6}$/.test(String(o.shopId)))'), true, 'shopId');
  eq(b.run('state.orders.every(o=>!!shopOf(o.shopId))'), true, 'shopOf tidak undefined');
  eq(b.run('sellerOrdersFor("100234").length'), 5, 'order RM Sederhana');
});
t('toko tidak lagi punya field phone/seller warisan, alamat ikut di objek toko', () => {
  const b = fresh();
  eq(b.run('state.shops.every(s=>!("phone" in s)&&!("seller" in s)&&!!s.csWa&&!!s.addr&&RE_MAP.test(s.mapUrl))'), true, 'bentuk toko');
});
t('WA share pembeli memakai nomor customer service toko', () => {
  const b = fresh();
  b.run('waOrder("GC-2411-00A1")');
  has(b.opened[0], 'https://wa.me/6282130000101', 'link ke csWa toko 100234');
});
t('impor dari gocatering_v4: order bertahan, id dipetakan, kunci lama tidak dihapus', () => {
  const old = boot(V4, {});
  const raw = JSON.stringify(old.run('state'));
  const key = old.run('KEY');
  const seedStore = {}; seedStore[key] = raw;
  const b = boot(V5, seedStore);
  if (b.errors.length) throw new Error(b.errors[0].message);
  eq(b.run('state.orders.length'), 9, 'jumlah order warisan');
  eq(b.run('state.orders.every(o=>/^\\d{6}$/.test(String(o.shopId)))'), true, 'shopId sudah dipetakan');
  eq(b.run('Object.keys(state.owners).length'), 2, 'pemilik contoh terbentuk');
  eq(b.run('state.shops.length'), 4, 'toko');
  eq(b.store.get(key), raw, 'salinan v4 dibiarkan utuh');
  eq(b.store.has(b.run('KEY')), false, 'v5 belum ditulis sampai save() pertama (memang begitu)');
});
t('SELLERS dan SELLERS.xxx tidak ada lagi di berkas', () => {
  const src = extract(V5);
  hasnt(src, 'const SELLERS', 'konstanta lama');
  hasnt(src, 'SELLERS.seller1', 'acuan lama');
  hasnt(src, 'SHOP_ADDR[', 'alamat masih via peta konstanta lama');
});
t('akun demo penjual menunjuk ke email pemilik hasil migrasi', () => {
  const b = fresh();
  b.run('fillDemo("seller1")');
  eq(b.els.get('li-email').value, 'rm.sederhana@gocatering.id', 'email penjual 1');
  b.run('fillDemo("seller2")');
  eq(b.els.get('li-email').value, 'dapur.nusantara@gocatering.id', 'email penjual 2');
});
```

Catatan uji impor: `load()` **tidak** menulis kunci `gocatering_v5` saat boot — penyimpanan v5 baru terbentuk pada `save()` pertama, dan salinan `gocatering_v4` dibiarkan utuh supaya v4 masih bisa dibuka. Yang tidak boleh dilonggarkan: jumlah order tetap 9, `shopId` sudah dipetakan ke 6 angka, dan `gocatering_v4` tidak dihapus.

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `node tools/test.js` → semua uji Task 4 GAGAL (`state.shops is undefined` / `DEMO_SHOP is not defined`), Task 1–3 tetap hijau.

- [ ] **Step 3: Naikkan kunci & skema**

```js
const KEY='gocatering_v5', KEY_OLD='gocatering_v4', SCHEMA=2;
```

(menggantikan `const KEY='gocatering_v4';`). Semua rujukan `'gocatering_v4'` di `resetData()` tidak berubah — ia menghapus `KEY`.

- [ ] **Step 4: Ganti isi `load()` dan tambahkan `ensureSchema`/`buildShops`/`indexOwners`/`remapShopIds`**

Konstanta bahan mentah (letakkan **di atas** `let state = load();`, misalnya setelah blok Task 3):

```js
/* ================= DATA PEMILIK CONTOH (spec §9) =================
   SHOPS + SHOP_ADDR tetap dipakai, tapi hanya sebagai bahan mentah migrasi.
   DEMO_SHOP seposisikan dengan SHOPS: baris ke-i = id 6 angka & pemilik toko ke-i. */
const DEMO_OWNER=[
  {key:'ow-seller1',gelar:'Tn',nama:'Andi Ramadhan',nik:'3578010203044567',
   email:'rm.sederhana@gocatering.id',phone:'081234567801',photo:'',
   password:'seller123',mustReset:false,createdAt:'2026-11-01T02:00:00.000Z'},
  {key:'ow-seller2',gelar:'Ny',nama:'Sari Kumalasari',nik:'3578020506078812',
   email:'dapur.nusantara@gocatering.id',phone:'081234567802',photo:'',
   password:'seller123',mustReset:false,createdAt:'2026-11-01T02:00:00.000Z'}
];
const DEMO_SHOP=[
  ['100234','ow-seller1','082130000101'],   /* RM Sederhana    */
  ['100742','ow-seller2','082130000201'],   /* Dapur Nusantara */
  ['100930','ow-seller2','082130000202'],   /* Catering Sehat  */
  ['100518','ow-seller1','082130000102']    /* Kekinian Food   */
];
function buildShops(){
  const out=[];
  SHOPS.forEach((raw,i)=>{
    const {phone,seller,...s}=raw;                      /* field lama dibuang, csWa menggantikan phone */
    const [id,ownerKey,csWa]=DEMO_SHOP[i];
    const ow=DEMO_OWNER.find(o=>o.key===ownerKey)||{};
    const addr=SHOP_ADDR[s.id]||'';
    const shop=Object.assign({},s,{id,ownerKey,csWa,addr,
      mapUrl:'https://www.google.com/maps/search/?api=1&query='+encodeURIComponent(addr),
      photo:(s.packages[0]||{}).img||'',builtin:true});
    shop.code=nextShopCode({name:ow.nama||shop.name,nik:ow.nik||'0000',ownerKey,shops:out});
    out.push(shop);
  });
  return out;
}
function indexOwners(owners,shops){
  shops.forEach(sh=>{
    if(owners[sh.ownerKey]) return;
    const d=DEMO_OWNER.find(o=>o.key===sh.ownerKey);
    owners[sh.ownerKey]=d
      ? {key:d.key,gelar:d.gelar,nama:d.nama,nik:d.nik,email:d.email,phone:d.phone,photo:d.photo,
         password:d.password,mustReset:d.mustReset,createdAt:d.createdAt,shops:[sh.id]}
      : {key:sh.ownerKey,gelar:'Tn',nama:'Pemilik '+(sh.code||sh.id),nik:'',email:'',phone:'',
         photo:'',password:'',mustReset:false,createdAt:new Date().toISOString(),shops:[sh.id]};
  });
  Object.values(owners).forEach(o=>{ if(!Array.isArray(o.shops)) o.shops=[] });
  shops.forEach(sh=>{ const o=owners[sh.ownerKey]; if(o&&o.shops.indexOf(sh.id)<0) o.shops.push(sh.id) });
  return owners;
}
/* toko lama yang belum punya kode / alamat / peta dilengkapi, tanpa membangun ulang
   toko buatan pengguna (registrasi baru) */
function ensureSchema(s){
  s.owners=s.owners||{};
  s.shops=(Array.isArray(s.shops)&&s.shops.length)?s.shops:buildShops();
  const taken=s.shops.map(x=>x.id);
  s.shops.forEach(sh=>{
    if(!/^\d{6}$/.test(String(sh.id))) sh.id=newShopId(taken);
    if(!sh.ownerKey) sh.ownerKey=ownerKeyOf(sh.nik||sh.id);
    if(!sh.csWa) sh.csWa='';
    if(sh.addr==null) sh.addr='';
    if(!sh.mapUrl) sh.mapUrl='';
    if(sh.photo==null) sh.photo='';
    if(sh.builtin==null) sh.builtin=false;
    if(!sh.code) sh.code=nextShopCode({name:(s.owners[sh.ownerKey]||{}).nama||sh.name,nik:(s.owners[sh.ownerKey]||{}).nik||sh.id,ownerKey:sh.ownerKey,shops:s.shops});
  });
  indexOwners(s.owners,s.shops);
  if(!s.devKey) s.devKey=rndKey();
  DEV_KEY=s.devKey;
  cryptRows(s.owners,CRYPT.owners,dec); cryptRows(s.shops,CRYPT.shops,dec);
  s.seqId=s.seqId||100000;
  if(!s.sellerShop||!s.shops.some(x=>x.id===s.sellerShop)) s.sellerShop=s.shops[0].id;
  s.schema=SCHEMA;
  return s;
}
/* pesanan & antrean lama menunjuk slug toko; toko sekarang memakai id 6 angka */
function remapShopIds(s){
  const map={}; DEMO_SHOP.forEach((row,i)=>{ map[SHOPS[i].id]=row[0] });
  const fix=id=>map[id]||id;
  (s.orders||[]).forEach(o=>{ if(map[o.shopId]) o.shopId=map[o.shopId] });
  if(s.antrean) s.antrean=Object.keys(s.antrean).reduce((m,k)=>{
    const i=k.indexOf('|'); m[fix(k.slice(0,i))+k.slice(i)]=s.antrean[k]; return m;
  },{});
  return s;
}
```

Lalu `load()` menjadi (baris `s.users`/Google warisan dipertahankan apa adanya):

```js
function load(){
  let s=null, imported=false;
  try{ const raw=localStorage.getItem(KEY); if(raw){ s=JSON.parse(raw); } }catch(e){}
  if(!s){
    /* impor sekali dari gocatering_v4: pesanan yang dibuat selama demo tidak hilang */
    try{ const old=localStorage.getItem(KEY_OLD); if(old){ s=JSON.parse(old); imported=true; } }catch(e){}
  }
  if(!s){
    const orders=seed();
    s={users:{'budi@mail.com':{password:'1234',name:'Budi Santoso',phone:'081234567899',role:'buyer'}},
       orders, queue:[], menuOff:{}, antrean:seedAntrean(orders)};
  }
  if(!s.antrean) s.antrean=seedAntrean(s.orders||[]);
  s.users=s.users||{};
  if(!s.users['maya.kusuma@gmail.com'])
    s.users['maya.kusuma@gmail.com']={password:'',name:'Maya Kusuma',phone:'081234567009',
      addr:'Jl. Ngagel Jaya Selatan B-14, Surabaya',role:'buyer',google:true,ava:'MK',tone:'#c53929'};
  if(s.user){ const r=s.users[s.user.email]; if(r&&r.google){ s.user.google=true; s.user.ava=r.ava; s.user.tone=r.tone; } }
  if(imported) remapShopIds(s);
  /* tiga baris penyandian Task 2 dipindah ke dalam ensureSchema() — di sana DEV_KEY
     sudah diketahui sebelum dec() dijalankan */
  return ensureSchema(s);
}
```

**Penting:** hapus tiga baris penyandian yang Task 2 sisipkan di `load()` (`if(!s.devKey)…`, `DEV_KEY=…`, `cryptRows(…dec)`), karena `ensureSchema()` sudah melakukannya pada waktu yang benar.

- [ ] **Step 5: Hapus `const SELLERS` dan alihkan pembacanya**

Hapus blok `const SELLERS = { seller1:…, seller2:… };` (v4:665-668). Ganti fungsi berikut:

```js
function shopOf(id){ return state.shops.find(s=>s.id===id) }
function shopAddr(id){ const s=shopOf(id); return (s&&s.addr)||'ambil di toko' }
function pkgOf(id){ return state.shops.flatMap(s=>s.packages).find(p=>p.id===id) }
function allPkgs(){ return state.shops.flatMap(s=>s.packages.map(p=>({...p,shopId:s.id,shopName:s.name}))) }
function findOwner(field,value){
  const v=String(value||'').trim().toLowerCase(); if(!v) return null;
  return Object.values(state.owners).find(o=>String(o[field]||'').trim().toLowerCase()===v)||null;
}
function currentOwner(){
  if(!state.user||state.user.role!=='seller') return null;
  return state.owners[state.user.ownerKey]||null;
}
/* shim: tetap mengembalikan objek pemilik agar pemakai lama tidak perlu ditulis ulang */
function currentSeller(){ const o=currentOwner(); return o?{name:o.nama,key:o.key}:null }
function shopNames(){ const o=currentOwner(); if(!o) return ''; return o.shops.map(id=>(shopOf(id)||{}).name||id).join(' • ') }
function myShopIds(){ const o=currentOwner(); return o?o.shops.slice():[] }
function sellerOrders(){ const ids=myShopIds(); return state.orders.filter(o=>ids.indexOf(o.shopId)>=0) }
function sellerOrdersFor(id){ return state.orders.filter(o=>o.shopId===id) }
function activeShop(){ return shopOf(state.sellerShop) }
function ensureSellerShop(){ const o=currentOwner(); if(!o) return; if(o.shops.indexOf(state.sellerShop)<0) state.sellerShop=o.shops[0]||null }
```

Perhatikan: `currentSeller()` sekarang mengembalikan **objek**, bukan kunci toko — semua pemakainya (`shopNames(currentSeller())`, `SELLERS[s].shops`) ikut diganti di langkah ini dan di Task 8.

- [ ] **Step 6: Perbaiki pemakai `SHOP_ADDR[...]` dan `s.phone`**

| Lokasi (v4) | Dari | Menjadi |
| --- | --- | --- |
| 1441 | `(SHOP_ADDR[currentShop.id]||'ambil di toko')` | `shopAddr(currentShop.id)` |
| 1652 | `'Diambil di toko: '+s.name+' ('+(SHOP_ADDR[s.id]||'-')+')'` | `'Diambil di toko: '+s.name+' ('+(s.addr||'-')+')'` |
| 1668 | `window.open('https://wa.me/'+s.phone+'?text='+…)` | `window.open(waLink(s.csWa)+'?text='+…)` |
| 1677 | `${SHOP_ADDR[s.id]||s.name}` | `${s.addr||s.name}` |

Run: `grep -n "SHOP_ADDR\[\|\.phone+'?text\|SELLERS" gocatering-prototype-v5.html`
Expected: hanya baris komentar bahan mentah (`/* SHOPS + SHOP_ADDR tetap dipakai … */`) yang tersisa, tidak ada rujukan aktif.

- [ ] **Step 7: Akun demo & judul dashboard**

```js
function fillDemo(w){
  if(w==='buyer'){ pickRole('buyer'); $('li-email').value='budi@mail.com'; $('li-pass').value='1234'; }
  if(w==='seller1'){ pickRole('seller'); $('li-email').value=DEMO_OWNER[0].email; $('li-pass').value=DEMO_OWNER[0].password; }
  if(w==='seller2'){ pickRole('seller'); $('li-email').value=DEMO_OWNER[1].email; $('li-pass').value=DEMO_OWNER[1].password; }
  go('v-login',false); toast('Form terisi — tinggal klik LOGIN');
}
```

Di `renderChrome`, entri judul penjual (v4:872) menjadi:

```js
  'v-seller':['Dashboard Penjual',currentOwner()?shopNames():'']};
```

- [ ] **Step 8: Perbarui uji karakterisasi Task 1 yang berubah perilakunya**

Uji `'WA share memakai nomor toko & wa.me'` di Task 1 kini **salah** (nomor csWa menggantikan `shop.phone`). Ganti nilai yang diharapkan menjadi `'https://wa.me/6282130000101'` dan judulnya menjadi `'WA share memakai nomor WA toko'`. (Uji Task 4 sudah memuat versi barunya — cukup hapus duplikatnya bila Anda lebih suka satu.)

Run: `node tools/test.js`
Expected: seluruh blok Task 1–4 hijau.

- [ ] **Step 9: Cek browser — aplikasi lama harus masih utuh**

Protokol uji browser. Klik: role Pembeli → `Isi pembeli` → LOGIN → buka kartu toko pertama → tambah paket → `Sesudah` ×2. Expected: katalog tampil, tidak ada error konsol, dan panel penjual (`Isi penjual` → LOGIN) menampilkan 5 pesanan untuk Andi.

- [ ] **Step 10: Commit**

```bash
git add gocatering-prototype-v5.html tools/test.js
git commit -m "feat(v5): state.owners & state.shops sebagai sumber tunggal + migrasi dari v4"
```

---

### Task 5: Dua layar registrasi + validasi + foto opsional (spec §4, §5.1–5.2)

**Files:**
- Modify: `gocatering-prototype-v5.html` — markup baru sesudah view `<!-- REGISTER -->` (v4:396-408), CSS baru sebelum `</style>`, fungsi validasi & navigasi diletakkan setelah `doRegister()` (v4:903-909), `pickRole`/`rg-role` handler di `DOMContentLoaded` (v4:1015)
- Modify: `tools/test.js`

**Interfaces:**
- Consumes: `RE_*`/`GELAR`/`NAME_OK` (Task 3), `findOwner`/`state.shops` (Task 4), `ownerKeyOf` (Task 3).
- Produces:
  - View `v-reg-seller-1` (field `rs-gelar`,`rs-nama`,`rs-email`,`rs-nik`,`rs-phone`,`rs-photo` + preview `rs-photo-prev`,`rs-photo-btn`) dan `v-reg-seller-2` (`rs-shop`,`rs-addr`,`rs-map`,`rs-cs`,`rs-shop-photo` + `rs-shop-photo-prev`,`rs-shop-photo-btn`); tiap field punya `<id>-err`.
  - `fv(id)`, `setErr(id,msg)`, `validateIdentity() → {ok,first,values}`, `validateShop() → {ok,first,values}`, `readPhoto(id)`, `photoErr(file)`, `compressImage(file,opt?) → Promise<dataURL>`, `pickPhoto(inpId,prevId,btnId)`, `nextIdentity()`, `toSellerReg()`, `regCta()`, `buyerFormOk()`
  - `PHOTO_MAX_PX=640`, `PHOTO_Q=0.7`, `PHOTO_MAX_BYTES=8*1024*1024`
  - `state.tmpSeller`, `state.tmpShop` (tempat singgah antar langkah, tidak pernah disimpan)

- [x] **Step 1: Tulis uji yang gagal**

> **Catatan rekonsiliasi Task 5 (ditemukan saat eksekusi, sudah diperbaiki):**
> 1. `const PHOTO_MAX_PX=640, PHOTO_Q=0.7` di Step 5 tidak bisa dipakai apa adanya — v5
>    sudah punya `const PHOTO_MAX=480, PHOTO_Q=0.6` untuk foto bukti ambil (B.4). Redeklarasi
>    `const` adalah SyntaxError, dan menaikkan `PHOTO_Q` diam-diam mengubah fitur itu.
>    Yang dibuat: `PHOTO_MAX_PX=640`, `PHOTO_MAX_BYTES=8MB`, dan kualitas baru bernama
>    `REG_PHOTO_Q=0.7`. Uji `photoErr` kini menegaskan kedua pasang angka: registrasi
>    `640:0.7`, bukti ambil tetap `480:0.6`.
> 2. `compressImage()` tidak menggambar canvas sendiri; ia memanggil `shrinkImage(img,max,q)`
>    yang sudah ada (satu jalur kompresi untuk seluruh aplikasi).
> 3. Blok uji Step 1 punya dua cacat:
>    - contoh alamat "terlalu pendek" `'Jl. Singkat'` panjangnya 11 karakter sehingga justru
>      LOLOS di ambang spec §4 (min. 10). Diganti `'Jl.'`.
>    - `form(b, {...}); has(b.els.get('rs-shop-err')...)` tanpa memanggil `validateShop()`
>      di antaranya membaca pesan **sisa** validasi sebelumnya. Setiap kasus sekarang direset
>      ke `GOOD_SHOP` lalu divalidasi, sehingga `r.first` juga ikut teruji.
> 4. Uji "email milik pembeli ditolak" memakai `budi@mail.com`, yang tertahan di aturan Gmail
>    lebih dulu sehingga pesan "akun pembeli" tidak pernah muncul. Sekarang akun Gmail dibuat
>    lebih dulu sebelum validasi; cabang email penjual (`login saja`) juga diuji. Konsekuensi
>    yang perlu diputuskan Task 6/7: selama registrasi wajib Gmail, cabang "email sudah
>    terdaftar sebagai penjual" tidak terjangkau data contoh beralamat `@gocatering.id`.
> 5. Klaim "tmpSeller/tmpShop tidak pernah disimpan" (baris 949) belum ada penjagaannya:
>    `save()`/`saveOr()` menulis `state` apa adanya, sehingga isian wizard dan `newUser`
>    (berisi password) ikut masuk `localStorage`. Ditambahkan `stripTemp()` yang membuang
>    `tmpSeller`, `tmpShop`, `newUser` dari salinan sebelum ditulis, plus uji yang membacanya
>    langsung dari `localStorage`.
> 6. Judul layar `v-reg-seller-1`/`v-reg-seller-2` dan tombol `ab-back` ditambah di Task 5
>    (rencana menundanya ke Task 6) karena Task 5-lah yang memperkenalkan layarnya, dan
>    Step 8 meminta layar itu dicek di browser.
> 7. Harness lokal (`tools/harness.js`) kini merekam `document.addEventListener` dan
>    menyediakan `b.fire(type)`, supaya handler `DOMContentLoaded` (Step 6) bisa diuji.

```js
console.log('\n== TASK 5 — validasi form registrasi ==');
function form(b, vals) { Object.keys(vals).forEach(k => b.run('$(\'' + k + '\').value=' + JSON.stringify(vals[k]))); }
const GOOD = { 'rs-gelar': 'Tn', 'rs-nama': 'Huang Budi', 'rs-email': 'huang.test@gmail.com',
               'rs-nik': '3578090807064567', 'rs-phone': '081234567890' };
const GOOD_SHOP = { 'rs-shop': 'Warung Huang', 'rs-addr': 'Jl. Kertajaya Indah Timur 5, Surabaya',
                    'rs-map': 'https://maps.app.goo.gl/abc123', 'rs-cs': '082190000101' };
t('form kosong ditolak dan tiap field memberi pesan sendiri', () => {
  const b = fresh();
  const v = b.run('validateIdentity()');
  eq(v.ok, false, 'harusnya gagal');
  ['rs-gelar', 'rs-nama', 'rs-email', 'rs-nik', 'rs-phone'].forEach(id =>
    ok(b.els.get(id + '-err') && b.els.get(id + '-err').textContent, 'pesan error ' + id + ' kosong'));
  eq(v.first, 'rs-gelar', 'fokus field pertama');
});
t('email selain gmail dan email milik pembeli ditolak', () => {
  const b = fresh();
  form(b, Object.assign({}, GOOD, { 'rs-email': 'huang@yahoo.com' }));
  b.run('validateIdentity()'); has(b.els.get('rs-email-err').textContent, '@gmail.com', 'pesan gmail');
  form(b, Object.assign({}, GOOD, { 'rs-email': 'budi@mail.com' }));
  b.run('validateIdentity()'); has(b.els.get('rs-email-err').textContent, 'akun pembeli', 'pesan lintas peran');
});
t('NIK 16 digit milik pemilik lain ditolak dengan arahan login', () => {
  const b = fresh();
  form(b, Object.assign({}, GOOD, { 'rs-nik': '3578010203044567' }));
  eq(b.run('validateIdentity().ok'), false, 'NIK duplikat harus ditolak');
  has(b.els.get('rs-nik-err').textContent, 'Tambah Toko', 'pesan mengarahkan Tambah Toko');
  has(b.els.get('rs-nik-err').textContent, 'Andi Ramadhan', 'menyebut nama pemilik');
});
t('NIK akhiran sama tapi 16 digit berbeda diterima; form lengkap lolos tanpa foto', () => {
  const b = fresh();
  form(b, GOOD);
  eq(b.run('validateIdentity().ok'), true, 'harusnya lolos (foto tidak diminta)');
  eq(b.run('validateIdentity().values.email'), 'huang.test@gmail.com', 'email dinormalkan');
});
t('validasi toko: nama pendek, nama ganda, alamat pendek, peta bukan google, WA salah', () => {
  const b = fresh();
  form(b, GOOD_SHOP);
  eq(b.run('validateShop().ok'), true, 'form toko bagus harus lolos');
  form(b, { 'rs-shop': 'ab' }); ok(!b.run('validateShop().ok'), 'nama 2 huruf');
  form(b, { 'rs-shop': 'RM Sederhana' }); has(b.els.get('rs-shop-err').textContent, 'sudah dipakai', 'nama ganda');
  form(b, { 'rs-addr': 'Jl. Singkat' }); has(b.els.get('rs-addr-err').textContent, 'belum lengkap', 'alamat pendek');
  form(b, { 'rs-map': 'http://maps.app.goo.gl/x' }); has(b.els.get('rs-map-err').textContent, 'Google Maps', 'peta http');
  form(b, { 'rs-cs': '12345' }); has(b.els.get('rs-cs-err').textContent, 'customer service', 'WA cs');
});
t('nextIdentity menyimpan langkah 1 danpra-isi WA CS dari WA pemilik', () => {
  const b = fresh();
  form(b, GOOD); b.run("$('rs-cs').value=''");
  b.run('nextIdentity()');
  eq(b.run('state.tmpSeller.nama'), 'Huang Budi', 'nilai tertahan');
  eq(b.els.get('rs-cs').value, '081234567890', 'WA CS terisi otomatis dan boleh diganti');
});
t('regCta mengirim penjual ke langkah 1, pembeli tetap doRegister', () => {
  const b = fresh();
  form(b, { 'rg-name': 'Huang', 'rg-phone': '081234567890', 'rg-email': 'huang.test@gmail.com',
            'rg-pass': 'rahasia123', 'rg-role': 'seller' });
  b.run('regCta()');
  eq(b.run('state.newUser.email'), 'huang.test@gmail.com', 'biodata dibawa');
  eq(b.els.get('rs-nama').value, 'Huang', 'nama terisi ulang di langkah 1');
  form(b, { 'rg-name': 'Budi Baru', 'rg-phone': '081234560000', 'rg-email': 'budi.baru@gmail.com',
            'rg-pass': 'rahasia123', 'rg-role': 'buyer' });
  b.run('regCta()');
  eq(b.run('!!state.users["budi.baru@gmail.com"]'), true, 'pembeli tersimpan seperti dulu');
});
t('photoErr menolak berkas cacat sebelum membaca isinya', () => {
  const b = fresh();
  eq(b.run('photoErr({type:"application/pdf",size:1000})'), 'File bukan gambar', 'tipe');
  eq(b.run('photoErr({type:"image/jpeg",size:9*1024*1024})'), 'Foto terlalu besar', 'ukuran');
  eq(b.run('photoErr({type:"image/png",size:200000})'), '', 'yang valid tidak punya pesan');
  eq(b.run('photoErr(null)'), 'Tidak ada file dipilih', 'kosong');
  eq(b.run('PHOTO_MAX_PX+":"+PHOTO_Q'), '640:0.7', 'kompres 640 px q0.7 (spec §2 butir 5)');
});
```

- [x] **Step 2: Jalankan, pastikan gagal**

Run: `node tools/test.js` → blok Task 5 GAGAL (`validateIdentity is not defined`), Task 1–4 hijau.

- [x] **Step 3: Markup dua layar (sisipkan setelah blok `<!-- REGISTER -->` penutup `</div>`-nya, v4:408)**

```html
    <!-- PENJUAL: DAFTAR 1 · DATA DIRI -->
    <div class="view" id="v-reg-seller-1">
      <div class="pad">
        <div class="stepbar"><span class="on"></span><span></span></div>
        <div class="hint" style="margin-bottom:10px"><b>Langkah 1 dari 2</b> · Data Diri Penjual</div>
        <div class="field"><label>Gelar</label>
          <select id="rs-gelar"><option value="">— pilih gelar —</option><option value="Tn">Tn</option><option value="Ny">Ny</option><option value="Nona">Nona</option></select>
          <div class="ferr" id="rs-gelar-err"></div></div>
        <div class="field"><label>Nama lengkap (sesuai KTP)</label><input id="rs-nama" placeholder="cth: Huang Budi"><div class="ferr" id="rs-nama-err"></div></div>
        <div class="field"><label>Email Gmail</label><input id="rs-email" type="email" placeholder="nama@gmail.com"><div class="ferr" id="rs-email-err"></div></div>
        <div class="field"><label>No. KTP (NIK)</label><input id="rs-nik" inputmode="numeric" maxlength="16" placeholder="16 digit angka"><div class="ferr" id="rs-nik-err"></div></div>
        <div class="field"><label>No. WhatsApp pemilik</label><input id="rs-phone" placeholder="0812xxxxxxxx"><div class="ferr" id="rs-phone-err"></div></div>
        <div class="field"><label>Foto penjual <span class="hint">(opsional)</span></label>
          <input class="filein" id="rs-photo" type="file" accept="image/*" onchange="pickPhoto('rs-photo','rs-photo-prev','rs-photo-btn')">
          <div><img class="photoprev" id="rs-photo-prev" alt="Pratinjau foto penjual"></div>
          <button class="btn-sm btn-grey" id="rs-photo-btn" type="button" onclick="$('rs-photo').click()">Pilih Foto</button>
          <div class="ferr" id="rs-photo-err"></div></div>
        <div class="formnav"><button class="btn btn-grey" style="flex:1" onclick="go('v-login')">Batal</button>
          <button class="btn btn-tosca" style="flex:1.5" onclick="nextIdentity()">Sesudah &rarr;</button></div>
        <div class="hint" style="margin-top:10px">NIK menjadi penanda pemilik dan tidak dikirim ke mana pun — prototype ini hanya menyimpannya di perangkat ini. Punya lebih dari satu restoran? <b>Login dulu, lalu pilih Tambah Toko.</b></div>
      </div>
    </div>

    <!-- PENJUAL: DAFTAR 2 · DATA TOKO -->
    <div class="view" id="v-reg-seller-2">
      <div class="pad">
        <div class="stepbar"><span class="on"></span><span class="on"></span></div>
        <div class="hint" style="margin-bottom:10px"><b>Langkah 2 dari 2</b> · Data Toko</div>
        <div class="field"><label>Nama restoran</label><input id="rs-shop" placeholder="cth: Warung Huang"><div class="ferr" id="rs-shop-err"></div></div>
        <div class="field"><label>Alamat fisik restoran</label><textarea id="rs-addr" rows="2" placeholder="Jalan, nomor, kelurahan, kota"></textarea><div class="ferr" id="rs-addr-err"></div></div>
        <div class="field"><label>Alamat di Google Maps</label><input id="rs-map" type="url" placeholder="https://maps.app.goo.gl/…"><div class="ferr" id="rs-map-err"></div></div>
        <div class="field"><label>No. WhatsApp customer service</label><input id="rs-cs" placeholder="0821xxxxxxxx"><div class="ferr" id="rs-cs-err"></div></div>
        <div class="field"><label>Foto restoran <span class="hint">(opsional)</span></label>
          <input class="filein" id="rs-shop-photo" type="file" accept="image/*" onchange="pickPhoto('rs-shop-photo','rs-shop-photo-prev','rs-shop-photo-btn')">
          <div><img class="photoprev" id="rs-shop-photo-prev" alt="Pratinjau foto restoran"></div>
          <button class="btn-sm btn-grey" id="rs-shop-photo-btn" type="button" onclick="$('rs-shop-photo').click()">Pilih Foto</button>
          <div class="ferr" id="rs-shop-photo-err"></div></div>
        <div class="formnav"><button class="btn btn-grey" style="flex:1" onclick="go('v-reg-seller-1')">&larr; Sebelum</button>
          <button class="btn btn-tosca" style="flex:1.5" onclick="submitSellerForm()">Sesudah · DAFTARKAN</button></div>
        <div class="hint" style="margin-top:10px">Nomor customer service boleh berbeda dari nomor pemilik. Ini yang terlihat pembeli saat menyentuh kode restoran.</div>
      </div>
    </div>

    <!-- PENJUAL: AKUN TERBIT (dipakai Task 6) -->
    <div class="view" id="v-reg-done"><div class="pad"><div id="reg-done-body"></div></div></div>
```

`submitSellerForm()` belum ada di task ini — biarkan tombolnya menunjuk ke sana; Task 6 yang membuatnya. Supaya aplikasi tidak error kalau ada yang mengklik lebih dulu, tambahkan stub di Task 5 dan hapus di Task 6:

```js
function submitSellerForm(){ toast('Menyelesaikan registrasi… (Task 6)'); }
```

- [x] **Step 4: CSS (tepat sebelum `</style>`)**

```css
/* ===== v5: registrasi penjual ===== */
.ferr{color:#c53929;font-size:11.5px;margin-top:3px;min-height:14px}
.filein{width:100%;font-size:12px;margin-top:4px}
.photoprev{display:none;width:76px;height:76px;object-fit:cover;border-radius:10px;border:1px solid #eceff1;margin:6px 0}
.formnav{display:flex;gap:8px;margin-top:14px}
.formnav .btn{margin-top:0}
.stepbar{display:flex;gap:6px;margin-bottom:8px}
.stepbar span{flex:1;height:4px;border-radius:4px;background:#e0e6ea}
.stepbar span.on{background:#00a08a}
```

- [x] **Step 5: Fungsi validasi & navigasi (setelah `doRegister()`, v4:909)**

```js
/* ================= REGISTRASI PENJUAL ================= */
const PHOTO_MAX_PX=640, PHOTO_Q=0.7, PHOTO_MAX_BYTES=8*1024*1024;
function fv(id){ const el=$(id); return el?String(el.value||'').trim():'' }
function setErr(id,msg){ const e=$(id+'-err'); if(e) e.textContent=msg||''; return !!msg }
function readPhoto(id){ const el=$(id); return (el&&el.dataset&&el.dataset.photo)||'' }
function photoErr(file){
  if(!file) return 'Tidak ada file dipilih';
  if(!/^image\//.test(file.type||'')) return 'File bukan gambar';
  if(file.size>PHOTO_MAX_BYTES) return 'Foto terlalu besar';
  return '';
}
function validateIdentity(){
  const e={};
  const gelar=fv('rs-gelar'); if(GELAR.indexOf(gelar)<0) e.gelar='Pilih gelar (Tn / Ny / Nona)';
  const nama=fv('rs-nama'); if(!NAME_OK.test(nama)) e.nama='Nama minimal 3 huruf, tanpa angka atau tanda khusus';
  const email=fv('rs-email').toLowerCase();
  if(!RE_GMAIL.test(email)) e.email='Email harus berakhiran @gmail.com';
  else if(state.users[email]) e.email='Email sudah dipakai akun pembeli, pakai email lain';
  else if(findOwner('email',email)) e.email='Email sudah terdaftar sebagai penjual — login saja';
  const nik=fv('rs-nik');
  if(!RE_NIK.test(nik)) e.nik='NIK harus 16 digit angka';
  else { const o=findOwner('nik',nik); if(o) e.nik='NIK sudah terdaftar atas nama '+o.nama+'. Login dulu, lalu pilih Tambah Toko'; }
  const phone=fv('rs-phone').replace(/[\s-]/g,'');
  if(!RE_PHONE.test(phone)) e.phone='Nomor WA tidak valid — contoh 081234567890';
  const order=[['rs-gelar',e.gelar],['rs-nama',e.nama],['rs-email',e.email],['rs-nik',e.nik],['rs-phone',e.phone]];
  order.forEach(p=>setErr(p[0],p[1]||''));
  const first=order.find(p=>p[1]);
  return {ok:!first, first:first?first[0]:'', values:{gelar,nama,email,nik,phone}};
}
function validateShop(){
  const e={};
  const name=fv('rs-shop');
  if(name.length<3) e.shop='Nama restoran minimal 3 huruf';
  else if(state.shops.some(s=>String(s.name).toLowerCase()===name.toLowerCase())) e.shop='Nama restoran sudah dipakai';
  const addr=fv('rs-addr'); if(addr.length<10) e.addr='Alamat fisik belum lengkap (min. 10 karakter)';
  const mapUrl=fv('rs-map'); if(!RE_MAP.test(mapUrl)) e.map='Tempel link Google Maps (https://maps…)';
  const csWa=fv('rs-cs').replace(/[\s-]/g,''); if(!RE_PHONE.test(csWa)) e.cs='No. WhatsApp customer service tidak valid';
  const order=[['rs-shop',e.shop],['rs-addr',e.addr],['rs-map',e.map],['rs-cs',e.cs]];
  order.forEach(p=>setErr(p[0],p[1]||''));
  const first=order.find(p=>p[1]);
  return {ok:!first, first:first?first[0]:'', values:{name,addr,mapUrl,csWa,photo:readPhoto('rs-shop-photo')}};
}
function buyerFormOk(){
  const n=fv('rg-name'),p=fv('rg-phone'),e=fv('rg-email').toLowerCase(),pw=($('rg-pass').value||'');
  if(!n||!p||!e||!pw){ toast('Lengkapi semua biodata','err'); return false }
  if(pw.length<6){ toast('Password minimal 6 karakter','err'); return false }
  if(state.users[e]){ toast('Email sudah terdaftar, silakan login','err'); return false }
  if(findOwner('email',e)){ toast('Email ini akun penjual — pilih role Penjual saat login','err'); return false }
  state.newUser={name:n,phone:p,email:e,password:pw};
  return true;
}
function regCta(){
  if($('rg-role').value!=='seller') return doRegister();
  if(!buyerFormOk()) return;
  toSellerReg();
}
function toSellerReg(){
  pickRole('seller');
  const u=state.newUser||{};
  go('v-reg-seller-1');
  if(!fv('rs-nama')){
    $('rs-nama').value=u.name||''; $('rs-email').value=u.email||''; $('rs-phone').value=u.phone||'';
  }
}
function nextIdentity(){
  const v=validateIdentity();
  if(!v.ok){ toast('Periksa lagi isian Data Diri Penjual','err'); $(v.first).focus(); return }
  v.values.photo=readPhoto('rs-photo');
  state.tmpSeller=v.values;
  if(!fv('rs-cs')) $('rs-cs').value=v.values.phone;      /* default, boleh diganti (spec §2 butir 7) */
  go('v-reg-seller-2');
}
/* pratinjau & kompresi foto (spec §2 butir 5) */
function pickPhoto(inpId,prevId,btnId){
  const inp=$(inpId), file=(inp.files||[])[0];
  const msg=photoErr(file);
  if(msg){ inp.value=''; setErr(inpId,msg); toast(msg,'err'); return }
  setErr(inpId,'');
  compressImage(file).then(url=>{
    inp.dataset.photo=url;
    const p=$(prevId); p.src=url; p.style.display='block';
    $(btnId).textContent='Ganti Foto';
    toast('Foto siap (dikompres '+PHOTO_MAX_PX+' px)','ok');
  }).catch(err=>{ inp.value=''; delete inp.dataset.photo; setErr(inpId,err.message); toast(err.message,'err'); });
}
function compressImage(file,opt){
  opt=opt||{}; const max=opt.max||PHOTO_MAX_PX, q=opt.q||PHOTO_Q;
  return new Promise((resolve,reject)=>{
    const bad=photoErr(file); if(bad) return reject(new Error(bad));
    const fr=new FileReader();
    fr.onerror=()=>reject(new Error('Gagal membaca berkas'));
    fr.onload=()=>{
      const img=new Image();
      img.onerror=()=>reject(new Error('File bukan gambar'));
      img.onload=()=>{
        const w=img.naturalWidth||img.width||max, h=img.naturalHeight||img.height||max;
        const r=Math.min(1,max/Math.max(w,h));
        const cv=document.createElement('canvas');
        cv.width=Math.max(1,Math.round(w*r)); cv.height=Math.max(1,Math.round(h*r));
        cv.getContext('2d').drawImage(img,0,0,cv.width,cv.height);
        resolve(cv.toDataURL('image/jpeg',q));
      };
      img.src=fr.result;
    };
    fr.readAsDataURL(file);
  });
}
```

- [x] **Step 6: Tombol daftar & role**

Ganti tombol SIMPAN di `v-register` (v4:406):

```html
        <button class="btn btn-tosca" id="rg-cta" onclick="regCta()">SIMPAN</button>
```

Ganti handler `DOMContentLoaded` (v4:1015) supaya penjual diarahkan ke wizard:

```js
  $('rg-role').onchange=e=>{
    const seller=e.target.value==='seller';
    $('rg-shopfield').style.display='none';                 /* nama toko diisi di langkah 2 */
    $('rg-cta').textContent=seller?'DAFTARKAN TOKO':'SIMPAN';
  };
```

Tambahkan satu tautan di layar login, sesudah tombol `Daftar` (v4:384):

```html
        <button class="btn btn-grey" style="margin-top:8px" onclick="toSellerReg()">Daftar sebagai penjual</button>
```

- [x] **Step 7: Jalankan test sampai hijau**

Run: `node tools/test.js` → Task 1–5 hijau.

- [x] **Step 8: Cek browser (klik nyata)**

Clear storage → muat → klik `Daftar` → pilih Role `Penjual (buka toko)` (label tombol harus berubah jadi `DAFTARKAN TOKO`) → isi 4 biodata → `DAFTARKAN TOKO` → layar `v-reg-seller-1` tampil dengan nama/email/WA sudah terisi → kosongkan NIK lalu klik `Sesudah →` → pesan "NIK harus 16 digit" muncul di bawah field → isi NIK demo Andi `3578010203044567` → pesan "sudah terdaftar … Tambah Toko". `list_console_messages` kosong.

- [x] **Step 9: Commit**

```bash
git add gocatering-prototype-v5.html tools/test.js
git commit -m "feat(v5): layar registrasi penjual 2 langkah, validasi, dan foto opsional terkompresi"
```

---

### Task 6: Kirim registrasi → akun terbit + login lintas peran (spec §5.3, §6)

**Files:**
- Modify: `gocatering-prototype-v5.html` — `doLogin()` (v4:891-902), `doRegister()` (v4:903-909), `renderChrome` titles (v4:871-875), `onEnter` (v4:859), stub `submitSellerForm` dari Task 5
- Modify: `tools/test.js`

**Interfaces:**
- Consumes: `validateShop`/`validateIdentity`/`readPhoto`/`nextIdentity` (Task 5), `ownerKeyOf`/`newShopId`/`nextShopCode`/`tempPassword` (Task 3), `state.owners`/`state.shops`/`findOwner`/`ensureSellerShop` (Task 4).
- Produces:
  - `addShop(ownerKey, form) → shop` (mendorong `owner.shops` dan `state.shops`)
  - `submitSellerForm()` (dispatcher: registrasi penuh vs tambah toko), `submitRegistration()`, `renderRegDone()`, `gotoLoginAsSeller()`, `state.regCreds`
  - `doLogin()` berbasis role; `state.user = {email,name,role:'seller',ownerKey}`
  - View `v-reg-done` dengan `#reg-done-body` diisi oleh `renderRegDone()`

**Catatan rekonsiliasi Task 6 (dibaca dari berkas, bukan dari asumsi):**

1. `renderShops()` ternyata masih memetakan konstanta lama `SHOPS`, bukan
   `state.shops` — tanpa diubah, uji "toko baru tampil di katalog pembeli" mustahil
   hijau. Sumber daftar dipindah ke `_shopList()` (satu baris; `Files:` rencana
   tidak menyebutnya).
2. Cabang `if(o.mustReset){ … go('v-s-reset') }` pada `doLogin()` sengaja **mundur
   ke Task 7**. Layar `v-s-reset` dan `#np-hint` baru ditulis di sana, jadi
   memanggilnya sekarang menghasilkan layar kosong + `TypeError` dan langkah 7
   cek browser tidak bisa diselesaikan. Task 6 mengunci flag `mustReset`,
   Task 7 yang membacanya.
3. `state.regCreds` membawa password plaintext, jadi ikut dibuang `stripTemp()`
   bersama `tmpSeller`/`tmpShop`/`newUser`; uji menambah `hasnt(raw, 'regCreds')`.
4. `ensureSchema()` menormalkan `s.user = s.user || null` supaya "tidak ada sesi"
   punya satu bentuk (uji mengharapkan `null`, bukan kunci yang hilang).
5. Bug warisan v4 yang ketutup lewat jalur ini: `logout()` tidak `save()`, sehingga
   sesi lama bangkit lagi setelah muat ulang (terbukti di browser: `state.user`
   pembeli masih ada padahal layar login). Sekarang `logout()` menyimpan.
6. `renderRegDone()` memakai ikon `✅` 44px seperti layar "Terima Kasih" (v5:2171);
   `<div class="logo">` pada rencana adalah wordmark oranye 52px, bukan medali.
   Semua sisipan lewat `esc()`.
7. `currentShop=shopOf(o.shops[0])` tetap dipertahankan saat login penjual karena
   sheet "＋ Tambah Pesanan" di dashboard membaca `currentShop` (v5:1778).
   Sinkronisasi dengan toko aktif baru terjadi di Task 8 (`setSellerShop`).
8. `v-reg-done` sengaja tidak diberi tombol back: kembali ke wizard setelah akun
   terbit hanya menghasilkan validasi yang sudah pasti gagal.
9. `nextShopCode()` (Task 3) menyaring dengan `s.ownerOwnerKey` yang tidak pernah
   ada di objek toko, jadi running selalu mulai dari 1 dan baru naik lewat loop
   tumbukan. Hasilnya tetap benar untuk semua kasus yang diuji (`H4567001`,
   `A4567001`→`A4567002`); dibiarkan sampai Task 8 menuntutnya.

- [x] **Step 1: Tulis uji yang gagal**

```js
console.log('\n== TASK 6 — akun terbit & login ==');
function fillReg(b, over) {
  form(b, Object.assign({}, GOOD, GOOD_SHOP, over || {}));
  b.run('state.tmpSeller=validateIdentity().values; state.tmpSeller.photo=""');
  return b.run('validateShop().values');
}
t('registrasi baru: pemilik + toko + kode H4567001 + ID 6 angka', () => {
  const b = fresh(); fillReg(b);
  b.run('submitSellerForm()');
  eq(b.run('Object.keys(state.owners).length'), 3, 'satu pemilik baru');
  eq(b.run('state.shops.length'), 5, 'satu toko baru');
  const o = b.run('findOwner("nik","3578090807064567")');
  ok(o, 'pemilik Huang ditemukan');
  const s = b.run('JSON.parse(JSON.stringify(state.shops.find(x=>x.ownerKey==='+JSON.stringify(o.key)+')))');
  eq(s.code, 'H4567001', 'kode'); ok(/^\d{6}$/.test(s.id), 'id ' + s.id);
  eq(JSON.stringify(b.run('findOwner("nik","3578090807064567").shops')), JSON.stringify([s.id]), 'toko menempel ke pemilik');
  eq(s.builtin, false, 'toko baru bukan bawaan');
});
t('password sementara sah, tersimpan, dan hanya tampil di layar akun terbit', () => {
  const b = fresh(); fillReg(b); b.run('submitSellerForm()');
  const pw = b.run('state.regCreds.password');
  eq(pw.length, 8, 'panjang'); ok(!/[ilo01]/.test(pw), 'karakter terlarang');
  eq(b.run('findOwner("email","huang.test@gmail.com").password'), pw, 'yang tampil = yang dipakai login');
  eq(b.run('findOwner("email","huang.test@gmail.com").mustReset'), true, 'wajib ganti');
  has(b.els.get('reg-done-body').innerHTML, pw, 'layar menampilkan password');
  has(b.els.get('reg-done-body').innerHTML, 'H4567001', 'layar menampilkan kode');
  has(b.els.get('reg-done-body').innerHTML, 'hanya tampil sekali', 'ada peringatan sekali tampil');
});
t('sesi di-logout dan tidak ada password yang bocor ke form login', () => {
  const b = fresh(); fillReg(b); b.run('submitSellerForm()');
  eq(b.run('state.user'), null, 'harus login ulang (spec §5.3)');
  b.run('gotoLoginAsSeller()');
  eq(b.els.get('li-email').value, 'huang.test@gmail.com', 'email terisi');
  eq(b.els.get('li-pass').value, '', 'password TIDAK dikembalikan ke layar');
  eq(b.run('role'), 'seller', 'role penjual aktif');
});
t('toko baru langsung bisa dipesan: paket contoh & tampil di katalog pembeli', () => {
  const b = fresh(); fillReg(b); b.run('submitSellerForm()');
  const id = b.run('findOwner("nik","3578090807064567").shops[0]');
  eq(b.run('shopOf(' + JSON.stringify(id) + ').packages.length'), 1, 'satu paket awal');
  eq(b.run('allPkgs().some(p=>p.shopId===' + JSON.stringify(id) + ')'), true, 'terdaftar di allPkgs');
  eq(b.run('typeof pkgOf(allPkgs().find(p=>p.shopId===' + JSON.stringify(id) + ').id).price'), 'number', 'bisa dibeli');
  b.run('renderShops()'); has(b.els.get('shop-list').innerHTML, 'Warung Huang', 'muncul di daftar toko');
});
t('menyimpan ulang tidak mengulang registrasi (NIK tetap ditolak)', () => {
  const b = fresh(); fillReg(b); b.run('submitSellerForm()');
  const raw = b.store.get(b.run('KEY'));
  const b2 = boot(V5, (() => { const o = {}; o[b.run('KEY')] = raw; return o; })());
  if (b2.errors.length) throw new Error(b2.errors[0].message);
  eq(b2.run('state.shops.length'), 5, 'toko baru ikut dipulihkan');
  eq(b2.run('findOwner("nik","3578090807064567").nama'), 'Huang Budi', 'nama pulih dari sandi');
  form(b2, Object.assign({}, GOOD, GOOD_SHOP, { 'rs-shop': 'Warung Dua' }));
  b2.run('state.tmpSeller=validateIdentity().values');
  eq(b2.run('validateIdentity().ok'), false, 'NIK kini ditolak');
  b2.run('submitSellerForm()'); eq(b2.run('state.shops.length'), 5, 'tidak ada toko baru');
});
t('login: email/password penjual, arah role yang salah, dan sesi pemilik', () => {
  const b = fresh();
  b.run('pickRole("seller"); $("li-email").value="budi@mail.com"; $("li-pass").value="1234"; doLogin()');
  has(b.els.get('toast').textContent, 'akun pembeli', 'email pembeli di role penjual');
  eq(b.run('state.user'), null, 'tidak ada sesi');
  b.run('pickRole("buyer"); $("li-email").value="rm.sederhana@gocatering.id"; $("li-pass").value="seller123"; doLogin()');
  has(b.els.get('toast').textContent, 'penjual', 'email penjual di role pembeli');
  b.run('pickRole("seller"); $("li-pass").value="salah"; doLogin()');
  has(b.els.get('toast').textContent, 'password', 'password salah');
  eq(b.run('state.user'), null, 'tetap tanpa sesi');
  b.run('pickRole("seller"); $("li-pass").value="seller123"; doLogin()');
  eq(b.run('state.user.role'), 'seller', 'masuk sebagai penjual');
  eq(b.run('state.user.ownerKey'), b.run('findOwner("email","rm.sederhana@gocatering.id").key'), 'kunci pemilik');
  eq(b.run('state.sellerShop'), '100234', 'toko aktif default');
  eq(b.run('myShopIds().length'), 2, 'Andi memegang dua toko');
  /* domain warisan @gocatering.id diterima untuk login (spec §9) */
});
```

- [x] **Step 2: Jalankan, pastikan gagal**

Run: `node tools/test.js` → blok Task 6 GAGAL (`submitRegistration is not defined` dsb.).

- [x] **Step 3: `addShop` + `submitRegistration` + dispatcher (setelah `nextIdentity()`)**

```js
function addShop(ownerKey,form){
  const o=state.owners[ownerKey]; if(!o) return null;
  const id=newShopId(state.shops.map(s=>s.id));
  const shop={ id, code:nextShopCode({name:o.nama,nik:o.nik,ownerKey,shops:state.shops}),
    name:form.name, tagline:'Restoran baru di goCatering', logo:'🍽️', rating:0, sold:0,
    /* satu paket awal supaya toko baru bisa langsung dipesan & diuji alurnya */
    packages:[{id:'p-'+id+'-1',name:'Paket perkenalan',price:15000,img:'assets/food/nasi-kotak.jpg',
               desc:'Paket bawaan hasil registrasi — atur lewat Menu Saya.'}],
    ownerKey, addr:form.addr, mapUrl:form.mapUrl, csWa:form.csWa||o.phone,
    photo:form.photo||'', builtin:false };
  state.shops.push(shop); o.shops.push(id);
  return shop;
}
function submitSellerForm(){
  if(currentOwner()&&!state.tmpSeller) return submitAddShop();   /* jalur Tambah Toko (Task 8) */
  return submitRegistration();
}
function submitRegistration(){
  const sv=validateShop();
  if(!sv.ok){ toast('Periksa lagi isian Data Toko','err'); $(sv.first).focus(); return }
  const id=state.tmpSeller;
  if(!id){ toast('Mulai ulang dari Data Diri Penjual','err'); go('v-reg-seller-1'); return }
  const key=ownerKeyOf(id.nik);
  if(state.owners[key]){ toast('NIK sudah terdaftar. Login dulu, lalu pilih Tambah Toko','err'); state.tmpSeller=null; go('v-reg-seller-1'); return }
  const pw=tempPassword();
  state.owners[key]={key,gelar:id.gelar,nama:id.nama,nik:id.nik,email:id.email,phone:id.phone,
    photo:id.photo||'',password:pw,mustReset:true,createdAt:new Date().toISOString(),shops:[]};
  const shop=addShop(key,sv.values);
  state.tmpSeller=null; state.tmpShop=null; state.user=null;
  state.regCreds={email:id.email,code:shop.code,id:shop.id,password:pw};
  save(); renderRegDone(); go('v-reg-done');
}
function renderRegDone(){
  const c=state.regCreds||{};
  $('reg-done-body').innerHTML=`<div class="center" style="padding:16px 0 10px">
      <div class="logo" style="background:#00a08a">GO</div>
      <h3 style="margin:10px 0 2px">Akun penjual Anda sudah terbit</h3>
      <div class="hint">Simpan password di bawah ini — tidak ditampilkan dua kali.</div></div>
    <div class="card" style="box-shadow:none;background:#f5f7f9">
      <div class="oline"><span>Email</span><b>${c.email||'—'}</b></div>
      <div class="oline"><span>Kode restoran</span><b>${c.code||'—'}</b></div>
      <div class="oline"><span>ID restoran</span><b>${c.id||'—'}</b></div>
      ${c.password
        ? `<div class="oline"><span>Password sementara</span><b style="font-family:ui-monospace,monospace;letter-spacing:1px">${c.password}</b></div>
           <div class="hint" style="margin-top:6px">Password ini hanya tampil sekali dan wajib diganti setelah login.</div>`
        : `<div class="hint" style="margin-top:6px">Toko bertambah. Password akun Anda tetap seperti biasa.</div>`}
    </div>
    <button class="btn btn-tosca" style="margin-top:12px" onclick="gotoLoginAsSeller()">LOGIN SEKARANG</button>
    <div class="hint center" style="margin-top:8px">ID restoran hanya untuk Anda; pembeli hanya melihat kode.</div>`;
}
function gotoLoginAsSeller(){
  pickRole('seller');
  $('li-email').value=(state.regCreds&&state.regCreds.email)||'';
  $('li-pass').value='';
  state.regCreds=null;
  go('v-login',false); toast('Email terisi — tempel password sementara Anda');
}
```

`submitAddShop()` dibuat di Task 8; supaya Task 6 tetap bisa dijalankan sendiri, tambahkan stub sementara di langkah ini dan hapus saat Task 8:

```js
function submitAddShop(){ toast('Tambah toko tersedia setelah Task 8','err'); }
```

- [x] **Step 4: Ganti `doRegister()` dan `doLogin()`**

`doRegister()` (pemanggilnya sekarang `regCta()`):

```js
function doRegister(){
  if(!buyerFormOk()) return;
  const u=state.newUser;
  state.users[u.email]={password:u.password,name:u.name,phone:u.phone,role:'buyer'}; save();
  state.newUser=null;
  toast('Registrasi berhasil. Silakan login.','ok');
  $('li-email').value=u.email; $('li-pass').value=u.password; pickRole('buyer'); go('v-login',false);
}
```

`doLogin()` — role menentukan kotak data yang dicari (spec §4):

```js
function doLogin(){
  const email=fv('li-email').toLowerCase(), pass=$('li-pass').value||'';
  if(!email||!pass) return toast('Isi email dan password dulu','err');
  const o=findOwner('email',email), isBuyer=!!state.users[email];
  if(role==='seller'){
    if(!o) return toast(isBuyer?'Email ini akun pembeli — pilih role Pembeli':'Email atau password penjual salah','err');
    if(pass!==o.password) return toast('Email atau password penjual salah','err');
    state.user={email,name:o.nama,role:'seller',ownerKey:o.key,phone:o.phone};
    state.sellerShop=o.shops[0]; save();
    if(o.mustReset){ $('np-hint').textContent='Password sementara wajib diganti sebelum masuk dashboard.'; go('v-s-reset'); return }
    go('v-seller',false); ensureSellerShop(); renderSeller();
    toast('Selamat datang, '+o.nama,'ok'); return;
  }
  if(o) return toast('Email ini akun penjual — pilih role Penjual','err');
  if(!state.users[email]){ state.users[email]={password:pass||'1234',name:email.split('@')[0],phone:'',role:'buyer'}; save(); toast('Akun pembeli dibuat otomatis','ok'); }
  if(state.users[email].password!==pass) return toast('Password salah','err');
  const r=state.users[email];
  state.user={email,name:r.name,phone:r.phone||'',addr:r.addr||'',role:'buyer',google:!!r.google,ava:r.ava,tone:r.tone};
  save(); history=[]; go('v-shops',false); renderShops(); toast('Login berhasil','ok');
}
```

- [x] **Step 5: Judul layar untuk view baru (di `renderChrome`, tambahkan entri)**

```js
    'v-reg-seller-1':['Daftar Penjual','1 · Data Diri Penjual'],
    'v-reg-seller-2':['Daftar Penjual','2 · Data Toko'],
    'v-reg-done':['Akun Penjual Terbit','Simpan password sementara'],
    'v-s-reset':['Ganti Password','Wajib untuk penjual baru'],
```

Tambahkan juga `'v-reg-seller-1','v-reg-seller-2','v-s-reset'` ke daftar view yang menampilkan tombol back (`$('ab-back').style.display=…`, v4:870).

- [x] **Step 6: Jalankan test sampai hijau**

Run: `node tools/test.js` → Task 1–6 hijau. Bila uji `'registrasi baru: …'` gagal karena `state.shops.length` 5 tapi kode bukan `H4567001`, periksa apakah `findOwner('nik',…)` ikut membandingkan pemilik hasil `buildShops` (NIK contoh `3578010203044567`) — NIK uji `3578090807064567` harus berbeda.

- [x] **Step 7: Cek browser penuh**

Clear storage → `Daftar` → role Penjual → isi biodata → `DAFTARKAN TOKO` → lengkapi langkah 1 (NIK `3578090807064567`) → `Sesudah →` → isi toko (`Warung Huang`, alamat panjang, `https://maps.app.goo.gl/abc`, WA `082190000101`) → `Sesudah · DAFTARKAN` → layar akun menampilkan `H4567001` + ID 6 angka + password 8 karakter → `LOGIN SEKARANG` → email terisi, password kosong → tempel password → LOGIN. Konsol bersih.

- [x] **Step 8: Commit**

```bash
git add gocatering-prototype-v5.html tools/test.js
git commit -m "feat(v5): submit registrasi, layar akun terbit, dan login berbasis role"
```

---

### Task 7: Reset password wajib setelah login pertama (spec §2 butir 8, §5.4)

**Files:**
- Modify: `gocatering-prototype-v5.html` — markup baru sesudah `v-reg-done`, fungsi `applyReset()` sesudah `gotoLoginAsSeller()`
- Modify: `tools/test.js`

**Interfaces:**
- Consumes: `currentOwner()` (Task 4), `fv`/`setErr`/`toast`/`go` (v4), `mustReset` (Task 6).
- Produces: view `v-s-reset` (`np-pass`,`np-pass2`,`np-hint` + `-err`), `applyReset()`, `skipResetLogout()`

**Catatan rekonsiliasi Task 7:**

1. Cabang `if(o.mustReset){ … }` di `doLogin()` pindah dari Task 6 ke Task 7
   (lihat catatan Task 6 butir 2). Flag `mustReset` sudah ditulis di Task 6, di
   sini baru dibaca.
2. Step 5 rencana minta `v-s-reset` ikut dipasang di daftar tombol back — **tidak
   dilakukan**. Riwayat saat gerbang terbuka masih berisi `v-reg-done`, jadi tombol
   back membuka lagi layar yang menampilkan password sekali-pakai. Penggantinya:
   tombol `Keluar dulu` (sudah ada di markup) dan `gotoLoginAsSeller()` mengosongkan
   `#reg-done-body` sebelum pindah layar. Uji: "gerbang ganti password tidak punya
   tombol back" + "layar akun terbit dikosongkan saat ditinggal ke login".
3. Harness tidak punya DOM sungguhan (`document.querySelectorAll` mengembalikan `[]`),
   jadi uji tidak bisa membaca `.view.on`. Penanda layar yang dipakai: judul/sub dari
   `renderChrome` (`ab-title`, `ab-sub`) dan `ab-back.style.display`.
4. `applyReset()` membandingkan dengan `o.password` (password sementara) dan
   menyimpan lewat `save()` → kolom `password` ikut tersandikan; uji memastikan
   `hujan28` tidak tertulis polos.
5. `skipResetLogout()` memanggil `logout()` yang sejak Task 6 menyimpan sesi kosong,
   jadi "keluar dulu" juga hilang dari penyimpanan — diuji.


- [x] **Step 1: Tulis uji yang gagal**

```js
console.log('\n== TASK 7 — ganti password paksa ==');
function loginNewSeller(b) { fillReg(b); b.run('submitSellerForm()'); const pw = b.run('state.regCreds.password');
  b.run('pickRole("seller"); $("li-email").value="huang.test@gmail.com"; $("li-pass").value=' + JSON.stringify(pw) + '; doLogin()'); return pw; }
t('penjual baru terdampar di layar ganti password', () => {
  const b = fresh(); const pw = loginNewSeller(b);
  eq(b.run('currentOwner().mustReset'), true, 'penanda wajib ganti');
  has(b.els.get('np-hint').textContent, 'wajib', 'petunjuk tampil');
});
t('password baru ditolak bila pendek, sama dengan sementara, atau tidak cocok', () => {
  const b = fresh(); const pw = loginNewSeller(b);
  b.run('$("np-pass").value="abc"; $("np-pass2").value="abc"; applyReset()');
  has(b.els.get('np-pass-err').textContent, 'minimal 6', 'terlalu pendek');
  b.run('$("np-pass").value=' + JSON.stringify(pw) + '; $("np-pass2").value=' + JSON.stringify(pw) + '; applyReset()');
  has(b.els.get('np-pass-err').textContent, 'sementara', 'sama dengan sementara');
  b.run('$("np-pass").value="hujan28"; $("np-pass2").value="hujan29"; applyReset()');
  has(b.els.get('np-pass2-err').textContent, 'tidak sama', 'konfirmasi beda');
  eq(b.run('currentOwner().mustReset'), true, 'belum berganti');
});
t('password baru tersimpan, wajib ganti hilang, dan penjual masuk dashboard', () => {
  const b = fresh(); loginNewSeller(b);
  b.run('$("np-pass").value="hujan28"; $("np-pass2").value="hujan28"; applyReset()');
  eq(b.run('currentOwner().password'), 'hujan28', 'password baru dipakai');
  eq(b.run('currentOwner().mustReset'), false, 'tidak lagi wajib');
  has(b.store.get(b.run('KEY')), 'e1:', 'password baru tersimpan tersandikan');
  ok(b.run('state.user.role') === 'seller', 'sesi tetap hidup');
  /* login ulang memakai password baru */
  b.run('logout(); pickRole("seller"); $("li-email").value="huang.test@gmail.com"; $("li-pass").value="hujan28"; doLogin()');
  eq(b.run('myShopIds().length'), 1, 'langsung ke dashboard, hanya tokonya');
  eq(b.run('currentOwner().mustReset'), false, 'tidak diminta ganti lagi');
});
t('menutup layar ganti password mengakhiri sesi', () => {
  const b = fresh(); loginNewSeller(b);
  b.run('skipResetLogout()');
  eq(b.run('state.user'), null, 'harus login lagi');
});
```

- [x] **Step 2: Jalankan, pastikan gagal**

Run: `node tools/test.js` → `applyReset is not defined`.

- [x] **Step 3: Markup (sesudah view `v-reg-done`)**

```html
    <!-- PENJUAL: GANTI PASSWORD -->
    <div class="view" id="v-s-reset">
      <div class="pad">
        <div class="hint" style="margin-bottom:10px" id="np-hint">Demi keamanan, password sementara harus diganti sebelum memakai dashboard.</div>
        <div class="field"><label>Password baru</label><input id="np-pass" type="password" placeholder="min. 6 karakter"><div class="ferr" id="np-pass-err"></div></div>
        <div class="field"><label>Ulangi password baru</label><input id="np-pass2" type="password" placeholder="sama seperti di atas"><div class="ferr" id="np-pass2-err"></div></div>
        <button class="btn btn-tosca" onclick="applyReset()">GANTI PASSWORD</button>
        <button class="btn btn-grey" style="margin-top:8px" onclick="skipResetLogout()">Keluar dulu</button>
      </div>
    </div>
```

- [x] **Step 4: Fungsi**

```js
function applyReset(){
  const o=currentOwner(); if(!o){ toast('Login sebagai penjual dulu','err'); go('v-login'); return }
  const a=$('np-pass').value||'', b2=$('np-pass2').value||'';
  let bad='';
  if(a.length<6) bad='Password minimal 6 karakter';
  else if(a===o.password) bad='Tidak boleh sama dengan password sementara';
  setErr('np-pass',bad); if(bad){ toast(bad,'err'); $('np-pass').focus(); return }
  if(a!==b2){ setErr('np-pass2','Konfirmasi password tidak sama'); toast('Konfirmasi password tidak sama','err'); $('np-pass2').focus(); return }
  setErr('np-pass2','');
  o.password=a; o.mustReset=false; save();
  $('np-pass').value=''; $('np-pass2').value='';
  toast('Password baru tersimpan','ok');
  go('v-seller',false); ensureSellerShop(); renderSeller();
}
function skipResetLogout(){
  $('np-pass').value=''; $('np-pass2').value=''; setErr('np-pass',''); setErr('np-pass2','');
  toast('Sesi ditutup — login lagi untuk mengganti password','err'); logout();
}
```

(`logout()` milik v4, v4:1007 — ia membersihkan `state.user` dan membawa ke `v-login`.)

- [x] **Step 5: Bersihkan stub Task 6**

Pastikan tidak ada lagi `function submitAddShop(){ toast('Tambah toko tersedia setelah Task 8','err'); }` bila Task 8 sudah dikerjakan; bila Task 8 belum, biarkan.

- [x] **Step 6: Jalankan test sampai hijau**

Run: `node tools/test.js` → Task 1–7 hijau.

- [x] **Step 7: Cek browser**

Registrasi baru (Task 6 Step 7) → setelah LOGIN penjual, layar yang muncul adalah **Ganti Password**, bukan dashboard. Coba password 3 karakter → error di bawah field. Ganti dengan `hujan28` → dashboard tampil. Logout, login lagi dengan `hujan28` → langsung dashboard.

- [x] **Step 8: Commit**

```bash
git add gocatering-prototype-v5.html tools/test.js
git commit -m "feat(v5): ganti password wajib bagi penjual baru sebelum masuk dashboard"
```

---

### Task 8: Dashboard penjual — persistensi, tombol Tambah Toko, dan isolasi (spec §7.3–§7.6, §B.1)

**Files:**
- Modify: `gocatering-prototype-v5.html` — fungsi `setSellerShop`, `renderShopSwitch`, `restaurantId`, `sellerOrders`, `advance`, `cancelOrder`, `toggleMenu`, `onEnter`; tambah `codeChip`, `guardShop`, `startAddShop`, `submitAddShop`; markup `v-seller` (tombol Tambah Toko), sheet `sheet-shops`
- Modify: `tools/test.js`

**Interfaces:**
- Consumes: `currentOwner`/`myShopIds`/`activeShopId`/`ensureSellerShop` (Task 4), `validateShop`/`addShop`/`renderRegDone` (Task 5–6), `setSellerShop`/`renderShopSwitch`/`sellerOrders` (v5 existing).
- Produces: `codeChip(id)` (HTML chip kode restoran), `guardShop(shopId)` (penjaga isolasi), `startAddShop()`/`submitAddShop()` (alur tambah toko), persistensi `sellerShopId` di `state.sellerShop`, tombol `+ Tambah Toko` di dashboard, sheet `sheet-shops` untuk pilih toko.

**Catatan:** v5 sudah punya `setSellerShop`, `renderShopSwitch`, `activeShopId`, `sellerOrders`, `dashBucket`, `rcodeOf`, `restaurantId`, `sweepExpired`, `cancelOrder(id,reason,note)`, `markCollected`, dll. Task ini tidak mengganti nama-nama itu, hanya menambahkan persistensi, tombol Tambah Toko, dan penjaga isolasi.

**Catatan rekonsiliasi Task 8:**

1. `codeChip()` memanggil `copyText()` yang **tidak pernah didefinisikan** di task
   mana pun (dcek: nol kemunculan di rencana). Helper dibuat di sini:
   `navigator.clipboard.writeText` + fallback textarea/`execCommand`. Catatan
   verifikasi: di tab otomatisasi janjinya resolve `false` karena dokumen tidak
   punya user activation; isi clipboard sungguhan baru bisa dibuktikan dengan klik
   nyata (Task 9).
2. `rcodeOf()` masih `s.rcode||RCODE[s.id]`. Sejak Task 4 id toko numerik, jadi
   RCODE slug tidak pernah cocok dan **semua kode tampil `—`** — termasuk baris
   "Kode restoran" di detail order (v5:2241) yang sudah ada sejak Task 4. Diperbaiki
   menjadi `s.code||s.rcode||RCODE[s.id]`.
3. Regresi lain warisan Task 4: `renderSellerList()` tab `menu` masih memetakan
   konstanta `SHOPS`, sehingga "Menu Saya" penjual kosong. Dipindah ke
   `[shopOf(id)].filter(Boolean)` + uji regresi.
4. `doLogin()`原先 memaksa `state.sellerShop=o.shops[0]` — bertentangan dengan
   §7.3. Kini nilai tersimpan dipulihkan selama masih milik akun itu; pindah akun
   tetap jatuh ke `shops[0]`.
5. Uji rencana kurang kuat di dua tempat: (a) uji persistensi memakai toko *pertama*
   Sari (`100742`) yang kebetulan sama dengan `shops[0]` → lolos tanpa fungsinya
   benar, diganti ke `100930`; (b) uji guardShop memakai `GC-2411-00A2` yang
   statusnya `completed` sehingga `advance()` memang tidak mengubah apa pun walau
   tanpa penjaga, diganti `GC-2411-00A6` (status `new`, punya Sari) plus kontrol
   positif bahwa Sari boleh.
6. Rencana tidak membahas tombol "← Sebelum" langkah 2. Untuk jalur Tambah Toko
   langkah 1 harus dilompati (NIK sudah terdaftar), jadi tombolnya diberi id
   `#rs2-back`, disembunyikan `startAddShop()` dan dipulihkan `nextIdentity()`.
7. `renderRegDone()` butuh CTA kedua: penjual yang sudah login tidak boleh disuruh
   "LOGIN SEKARANG". Ditambah cabang `afterAddShop()` ("KEMBALI KE DASHBOARD") dan
   judul/teks kepala yang mengikuti.
8. Penjaga ditambah satu langkah dari rencana: `markCollected()` dan
   `setSellerShop()` juga lewat `guardShop()`; `tab` direset ke `all` saat login
   supaya penjual berikutnya tidak membuka tab terakhir penjual sebelumnya.
9. Helper `reload(b)` dipakai uji Task 8 tapi belum ada → ditambahkan di
   `tools/test.js`.
10. Stub `submitAddShop()` penunda Task 6 sudah diganti yang sebenarnya.


- [x] **Step 1: Tulis uji yang gagal**

```js
console.log('\n== TASK 8 — persistensi, tambah toko, isolasi ==');
function loginAs(b, email) {
  b.run('pickRole("seller"); $("li-email").value=' + JSON.stringify(email) + '; $("li-pass").value="seller123"; doLogin()');
  if (b.run('state.user&&state.user.role') !== 'seller') throw new Error('gagal login ' + email);
}
t('sellerShopId disimpan di state dan dipulihkan setelah reload', () => {
  const b = fresh(); loginAs(b, 'dapur.nusantara@gocatering.id');
  b.run('setSellerShop("100742")');
  eq(b.run('state.sellerShop'), '100742', 'tersimpan di state');
  const b2 = reload(b);
  loginAs(b2, 'dapur.nusantara@gocatering.id');
  eq(b2.run('sellerShopId'), '100742', 'dipulihkan dari state');
});
t('codeChip mengembalikan HTML dengan onclick dan kode restoran', () => {
  const b = fresh(); loginAs(b, 'rm.sederhana@gocatering.id');
  const html = b.run('codeChip("100234")');
  has(html, 'A4567001', 'kode restoran');
  has(html, 'onclick', 'bisa diklik');
  has(html, '100234', 'ID toko');
});
t('renderShopSwitch menampilkan tombol Tambah Toko', () => {
  const b = fresh(); loginAs(b, 'dapur.nusantara@gocatering.id');
  b.run('renderShopSwitch()');
  const html = b.els.get('dash-shop').innerHTML;
  has(html, 'Tambah Toko', 'tombol ada');
  has(html, 'startAddShop', 'onclick benar');
});
t('guardShop menolak order toko orang lain', () => {
  const b = fresh(); loginAs(b, 'rm.sederhana@gocatering.id');
  const before = b.run('state.orders.find(o=>o.id==="GC-2411-00A2").status');
  b.run('advance("GC-2411-00A2")');
  eq(b.run('state.orders.find(o=>o.id==="GC-2411-00A2").status'), before, 'status tidak berubah');
  has(b.els.get('toast').textContent, 'Bukan restoran Anda', 'toast');
});
t('Tambah Toko memakai NIK pemilik yang sedang login dan menaikkan running', () => {
  const b = fresh(); loginAs(b, 'dapur.nusantara@gocatering.id');
  b.run('startAddShop()');
  eq(b.els.get('rs-cs').value, '081234567802', 'WA CS default dari WA pemilik');
  eq(b.run('state.tmpSeller'), null, 'tidak dianggap registrasi baru');
  form(b, { 'rs-shop': 'Dapur Nusantara 2', 'rs-addr': 'Jl. Raya Kertajaya No 8, Surabaya',
            'rs-map': 'https://maps.app.goo.gl/zzz', 'rs-cs': '082130000203' });
  b.run('submitAddShop()');
  eq(b.run('findOwner("email","dapur.nusantara@gocatering.id").shops.length'), 3, 'toko bertambah');
  eq(b.run('state.shops.filter(s=>s.ownerKey===state.user.ownerKey).map(s=>s.code).pop()'), 'S8812003', 'kode berjalan');
  eq(b.run('state.regCreds.password'), '', 'tanpa password baru');
  has(b.els.get('reg-done-body').innerHTML, 'Password akun Anda tetap', 'bahwa tidak ada password baru');
  eq(b.run('state.sellerShop'), b.run('state.shops[state.shops.length-1].id'), 'toko baru jadi aktif');
  eq(b.run('Object.keys(state.owners).length'), 2, 'tidak ada pemilik baru');
});
```

- [x] **Step 2: Jalankan, pastikan gagal**

Run: `node tools/test.js` → `codeChip is not defined`.

- [x] **Step 3: Persistensi sellerShopId (modifikasi `setSellerShop` yang sudah ada di v5)**

```js
function setSellerShop(id){
  sellerShopId=id;
  state.sellerShop=id; save();
  tab='all'; renderSeller(); renderChrome('v-seller');
  toast('Dashboard: '+shopOf(id).name,'ok');
}
```

dan di `onEnter` (v5:859) tambahkan pemulihan:

```js
  if(view==='v-seller'){
    if(state.sellerShop && myShopIds().includes(state.sellerShop)){
      sellerShopId=state.sellerShop;
    }
    ensureSellerShop(); renderSeller();
  }
```

- [x] **Step 4: Fungsi codeChip (sisipkan setelah `rcodeOf` di v5)**

```js
/* codeChip: chip HTML yang menampilkan kode restoran dan ID toko, bisa diklik untuk menyalin */
function codeChip(id){
  const s=shopOf(id); if(!s) return '<span class="hint">—</span>';
  const code=rcodeOf(id);
  return `<span class="rcode-chip" onclick="copyText('${code}');toast('Kode disalin: ${code}','ok')" title="Klik untuk menyalin">${code}<span class="rid">${id}</span></span>`;
}
```

CSS (sebelum `</style>`):

```css
.rcode-chip{display:inline-flex;align-items:center;gap:6px;background:#e8f5e9;border:1px solid #c8e6c9;border-radius:8px;padding:4px 10px;font-size:12px;font-weight:700;color:#2e7d32;cursor:pointer}
.rcode-chip:hover{background:#c8e6c9}
.rcode-chip .rid{font-size:10px;font-weight:500;color:#558b2f}
```

- [x] **Step 5: Tombol Tambah Toko di renderShopSwitch (modifikasi fungsi yang sudah ada di v5)**

```js
function renderShopSwitch(){
  const ids=myShopIds(), box=$('dash-shop');
  if(ids.length<1){ box.innerHTML=''; return; }
  box.innerHTML=`<div class="shopswitch"><span class="sl">TOKO</span><div class="swrap">`
    +ids.map(id=>{
      const s=shopOf(id);
      return `<button type="button" class="swchip${id===activeShopId()?' on':''}" onclick="setSellerShop('${id}')">${s.logo} ${s.name}<span class="rc">${rcodeOf(id)}</span></button>`;
    }).join('')
    +`<button type="button" class="swchip" style="background:#e8f5e9;border-color:#c8e6c9;color:#2e7d32" onclick="startAddShop()">+ Tambah Toko</button>`
    +`</div></div>`;
}
```

- [x] **Step 6: Fungsi guardShop, startAddShop, submitAddShop (sisipkan di blok PENJUAL)**

```js
function guardShop(shopId){
  const o=currentOwner();
  if(!o){ toast('Login sebagai penjual dulu','err'); return false }
  if(o.shops.indexOf(shopId)<0){ toast('Bukan restoran Anda','err'); return false }
  return true;
}
function startAddShop(){
  const o=currentOwner(); if(!o){ toast('Login sebagai penjual dulu','err'); go('v-login'); return }
  state.tmpSeller=null;
  ['rs-shop','rs-addr','rs-map'].forEach(id=>$(id).value='');
  $('rs-cs').value=o.phone; setErr('rs-shop',''); setErr('rs-addr',''); setErr('rs-map',''); setErr('rs-cs','');
  go('v-reg-seller-2');
}
function submitAddShop(){
  const o=currentOwner(); if(!o){ go('v-login'); return }
  const v=validateShop();
  if(!v.ok){ toast('Periksa lagi isian Data Toko','err'); $(v.first).focus(); return }
  const shop=addShop(o.key,v.values);
  state.tmpShop=null; state.sellerShop=shop.id; sellerShopId=shop.id; save();
  state.regCreds={email:o.email,code:shop.code,id:shop.id,password:''};
  renderRegDone(); go('v-reg-done');
}
```

- [x] **Step 7: Pakai guardShop di advance, cancelOrder, toggleMenu**

di `advance` (v5 existing) tambahkan di awal:

```js
function advance(id){
  const o=state.orders.find(x=>x.id===id); if(!o) return;
  if(!guardShop(o.shopId)) return;
  … /* sisa isi fungsi tidak berubah */
}
```

di `cancelOrder` (v5 existing, sudah punya parameter `reason,note`) tambahkan:

```js
function cancelOrder(id,reason,note){
  const o=state.orders.find(x=>x.id===id); if(!o) return;
  if(!guardShop(o.shopId)) return;
  … /* sisa isi fungsi tidak berubah */
}
```

di `toggleMenu` (v5 existing) tambahkan:

```js
function toggleMenu(pid){
  const sh=state.shops.find(s=>s.packages.some(p=>p.id===pid)); if(!sh) return;
  if(!guardShop(sh.id)) return;
  … /* sisa isi fungsi tidak berubah */
}
```

- [x] **Step 8: Jalankan test sampai hijau**

Run: `node tools/test.js` → Task 1–8 hijau.

- [x] **Step 9: Cek browser**

`Isi penjual` (Andi) → LOGIN → dashboard: header menyebut `A4567001`/`100234`, tombol `+ Tambah Toko` tampil di pemilih toko → klik → langkah 2 tampil tanpa langkah 1 → isi → DAFTARKAN → muncul `A4567003` dan **tidak ada** password sementara. Klik kode restoran di kartu pesanan → disalin ke clipboard. Login sebagai Sari → daftar pesanan tidak memuat satu pun order Andi (cari teks "RM Sederhana": tidak ada). Konsol bersih.

- [x] **Step 10: Commit**

```bash
git add gocatering-prototype-v5.html tools/test.js
git commit -m "feat(v5): persistensi sellerShopId, tombol Tambah Toko, dan penjaga isolasi"
```

---
### Task 9: Sisi pembeli — kode di samping nama restoran + popup info (spec §2 butir 11–12, §5.5)

**Files:**
- Modify: `gocatering-prototype-v5.html` — `renderShops` (v4:1033-1040), markup `v-catalog` (v4:452-456), `renderCatalog` (v4:1045), `openDetail` (v4:1625), sheet baru sesudah `sheet-menu`, CSS sebelum `</style>`
- Modify: `tools/test.js`

**Interfaces:**
- Consumes: `state.shops` (`code`,`addr`,`mapUrl`,`csWa`,`photo`) dari Task 4, `owner.nama`/`gelar`/`photo`, `waLink` (Task 3), `openSheet` (v4:883).
- Produces: `codeChip(shopId) → html`, `openRestoSheet(shopId)`, view sheet `sheet-resto` dengan `resto-init`,`resto-photo`,`resto-name`,`resto-code`,`resto-owner`,`resto-addr`,`resto-wa`,`resto-map`,`resto-chat`, header katalog `cat-name`,`cat-code`.
- Aturan keras: **`shop.id` tidak boleh muncul di elemen sisi pembeli mana pun.**

- [ ] **Step 1: Tulis uji yang gagal**

```js
console.log('\n== TASK 9 — kode restoran di sisi pembeli ==');
const ANDI = 'rm.sederhana@gocatering.id';
t('kartu toko menampilkan kode, bukan ID', () => {
  const b = fresh();
  b.run('renderShops()');
  const html = b.els.get('shop-list').innerHTML;
  ['A4567001', 'A4567002', 'S8812001', 'S8812002'].forEach(c => has(html, 'kode: ' + c, 'chip ' + c));
  const visible = html.replace(/on\w+="[^"]*"/g, '');   /* id memang ada di onclick, tapi tidak tampil */
  ['100234', '100518', '100742', '100930'].forEach(i => hasnt(visible, i, 'ID ' + i));
  has(html, "openRestoSheet('100234')", 'chip bisa disentuh');
  has(html, 'event.stopPropagation()', 'menyentuh chip tidak membuka toko');
});
t('header katalog menampilkan nama toko + kode', () => {
  const b = fresh();
  b.run('openShop("100234"); renderCatalog()');
  eq(b.els.get('cat-name').textContent, 'RM Sederhana', 'nama');
  has(b.els.get('cat-code').innerHTML, 'kode: A4567001', 'chip katalog');
});
t('detail pesanan menampilkan kode, bukan ID', () => {
  const b = fresh();
  b.run('openDetail("GC-2411-00A1")');
  const html = b.els.get('sheet-order-body').innerHTML;
  has(html, 'kode: A4567001', 'kode');
  hasnt(html.replace(/on\w+="[^"]*"/g, ''), '100234', 'ID');
});
t('popup info restoran: pemilik, alamat, peta, WA CS lengkap', () => {
  const b = fresh();
  b.run('openRestoSheet("100234")');
  eq(b.els.get('resto-owner').textContent, 'Tn Andi Ramadhan', 'pemilik + gelar');
  eq(b.els.get('resto-addr').textContent, 'Jl. Tunjungan No. 45, Surabaya', 'alamat');
  has(b.els.get('resto-map').href, 'google.com/maps', 'tombol peta');
  eq(b.els.get('resto-wa').textContent, 'WA CS 082130000101', 'nomor penuh, tidak disamarkan');
  eq(b.els.get('resto-chat').href, 'https://wa.me/6282130000101', 'link chat');
  eq(b.els.get('resto-code').textContent, 'kode: A4567001', 'kode');
  const all = ['resto-owner', 'resto-addr', 'resto-wa', 'resto-code', 'resto-name']
    .map(i => String(b.els.get(i).textContent) + String(b.els.get(i).innerHTML)).join(' ');
  hasnt(all, '100234', 'ID bocor ke popup');
});
t('tanpa foto, popup memakai inisial nama pemilik', () => {
  const b = fresh(); loginAs2(b, 'huang');
  b.run('openRestoSheet(findOwner("email","huang.test@gmail.com").shops[0])');
  eq(b.els.get('resto-photo').style.display, 'none', 'foto disembunyikan');
  eq(b.els.get('resto-init').textContent, 'H', 'inisial pemilik');
  eq(b.els.get('resto-owner').textContent, 'Tn Huang Budi', 'pemilik');
});
```

Test ini memakai `loginAs2(b,'huang')` sebagai ringkasan "registrasi Huang lewat form lalu logout". Tambahkan definisinya di bagian atas `tools/test.js` (sebelum blok uji):

```js
function loginAs2(b, who) {
  if (who !== 'huang') throw new Error('helper ini hanya untuk Huang');
  form(b, Object.assign({}, GOOD, GOOD_SHOP));
  b.run('state.tmpSeller=validateIdentity().values; state.tmpSeller.photo=""');
  b.run('submitSellerForm()');
  b.run('state.tmpSeller=null; pickRole("seller"); $("li-email").value="huang.test@gmail.com"; $("li-pass").value=state.regCreds.password; doLogin()');
  b.run('currentOwner().mustReset=false; applyResetForTest()');
  return b.run('state.user');
}
```

`applyResetForTest()` adalah satu baris di berkas HTML, di bawah `applyReset()`, yang meniru hasil ganti password tanpa lewat layar:

```js
/* hanya untuk harness uji: menandai password sudah diganti tanpa menyentuh layar */
function applyResetForTest(){ const o=currentOwner(); if(o){ o.mustReset=false; o.password='hujan28'; } }
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `node tools/test.js` → `codeChip is not defined` / `cat-name` kosong.

- [ ] **Step 3: CSS (sebelum `</style>`)**

```css
/* ===== v5: kode restoran (sisi pembeli) ===== */
.code-chip{display:inline-block;margin-left:6px;padding:2px 8px;border-radius:999px;background:#e9f7f4;
  color:#00796b;font-size:11px;font-weight:700;cursor:pointer;border:1px solid #bfe5dd;vertical-align:middle}
.shophead{display:flex;align-items:center;gap:6px;padding:10px 12px 2px}
.resto-row{display:flex;gap:10px;align-items:center;margin-bottom:12px}
.resto-init{width:52px;height:52px;border-radius:50%;background:#e8f5f2;color:#00796b;flex:0 0 auto;
  display:flex;align-items:center;justify-content:center;font-weight:800;font-size:20px}
#resto-photo{width:52px;height:52px;border-radius:12px;object-fit:cover;flex:0 0 auto;display:none}
```

- [ ] **Step 4: Chip + header katalog**

```js
function codeChip(id){
  const s=shopOf(id); if(!s||!s.code) return '';
  return `<span class="code-chip" role="button" tabindex="0" title="Lihat info restoran" `
       + `onclick="event.stopPropagation();openRestoSheet('${s.id}')" `
       + `onkeydown="if(event.key==='Enter'){event.stopPropagation();openRestoSheet('${s.id}')}">kode: ${s.code}</span>`;
}
```

Di `renderShops` (v4:1037) ganti baris nama toko menjadi:

```js
    <div style="flex:1"><div class="shopname">${s.name}${codeChip(s.id)}</div><div class="shopmeta">${s.tagline}</div>
```

Sisipkan header katalog di dalam `v-catalog` (v4:452, tepat sesudah `<div class="view" id="v-catalog">`):

```html
      <div class="shophead"><div class="shopname" id="cat-name" style="font-size:15px">—</div><span id="cat-code"></span></div>
```

dan di awal `renderCatalog()` (setelah `const ent=consumeAdded();`, v4:1046):

```js
  $('cat-name').textContent=currentShop?currentShop.name:'—';
  $('cat-code').innerHTML=currentShop?codeChip(currentShop.id):'';
```

Di `openDetail` (v4:1625) ganti `${shopOf(o.shopId).name} · ${it.length} jenis paket` menjadi `${shopOf(o.shopId).name}${codeChip(o.shopId)} · ${it.length} jenis paket`.

- [ ] **Step 5: Sheet info restoran**

Markup, sesudah `sheet-shops` (Task 8):

```html
  <div class="overlay" id="sheet-resto" onclick="if(event.target===this)closeSheet('sheet-resto')">
    <div class="sheet">
      <div class="resto-row">
        <div class="resto-init" id="resto-init">R</div>
        <img id="resto-photo" alt="Foto restoran">
        <div style="flex:1;min-width:0"><h3 style="margin:0 0 2px" id="resto-name">—</h3>
          <div class="hint" id="resto-code"></div></div>
      </div>
      <div class="oline"><span>Pemilik</span><b id="resto-owner">—</b></div>
      <div class="oline" style="align-items:flex-start"><span>Alamat</span><b id="resto-addr" style="text-align:right;max-width:62%">—</b></div>
      <div class="hint" id="resto-wa" style="margin:10px 0 8px"></div>
      <div style="display:flex;gap:8px">
        <a class="btn btn-grey" id="resto-map" target="_blank" rel="noopener" style="flex:1;text-align:center;text-decoration:none">Buka Peta</a>
        <a class="btn btn-wa" id="resto-chat" target="_blank" rel="noopener" style="flex:1;text-align:center;text-decoration:none">Chat WA</a>
      </div>
      <div class="hint center" style="margin-top:10px">Kode restoran identitas publik toko. ID 6 angka hanya dilihat penjual.</div>
    </div>
  </div>
```

Fungsi (di bawah `codeChip`):

```js
/* popup info restoran (spec §2 butir 12) — sengaja tidak pernah menampilkan ID */
function openRestoSheet(id){
  const s=shopOf(id); if(!s) return;
  const o=state.owners[s.ownerKey]||{};
  const photo=s.photo||'';
  $('resto-photo').src=photo; $('resto-photo').style.display=photo?'block':'none';
  const init=String((o.nama||s.name||'?').trim().charAt(0)||'?').toUpperCase();
  $('resto-init').textContent=init; $('resto-init').style.display=photo?'none':'flex';
  $('resto-name').textContent=s.name;
  $('resto-code').textContent='kode: '+(s.code||'—');
  $('resto-owner').textContent=((o.gelar?o.gelar+' ':'')+(o.nama||'Pemilik belum terisi'));
  $('resto-addr').textContent=s.addr||'Alamat belum diisi';
  const map=$('resto-map'); map.href=s.mapUrl||''; map.style.display=s.mapUrl?'inline-flex':'none';
  $('resto-wa').textContent=s.csWa?('WA CS '+s.csWa):'WA customer service belum diisi';
  const chat=$('resto-chat'); chat.href=s.csWa?waLink(s.csWa):''; chat.style.display=s.csWa?'inline-flex':'none';
  openSheet('sheet-resto');
}
```

- [ ] **Step 6: Jalankan test sampai hijau**

Run: `node tools/test.js` → Task 1–9 hijau.

- [ ] **Step 7: Cek browser**

Clear storage → login pembeli → daftar toko: tiap kartu punya pil `kode: …`; klik pil → **yang terbuka adalah popup info**, bukan halaman toko. Popup menyebut "Tn Andi Ramadhan", alamat, tombol `Buka Peta` (href google.com/maps) dan `Chat WA` (href `https://wa.me/6282130000101`). `document.body.innerText` di layar toko tidak memuat `100234` (cek lewat konsol: `[...document.querySelectorAll('#shop-list,#pkg-grid,.appbar')].map(e=>e.innerText).join(' ').includes('100234')` → `false`). Masuk katalog, checkout 1 paket sampai selesai, buka detail pesanan → chip kode ada di bawah nomor order. Konsol bersih.

- [ ] **Step 8: Commit**

```bash
git add gocatering-prototype-v5.html tools/test.js
git commit -m "feat(v5): chip kode restoran, popup info pemilik/peta/WA CS untuk pembeli"
```

---

### Task 10: Label versi, README, pengalihan `index.html`, dan regresi menyeluruh

**Files:**
- Modify: `gocatering-prototype-v5.html` — `<title>` (v4:6), `<h1>` (v4:305), panel catatan (`<h2>Baru di v4</h2>` v4:307)
- Modify: `index.html`, `README.md`
- Read-only: `tools/test.js` (tidak ditambah uji baru)

**Interfaces:**
- Consumes: seluruh Task 1–9.
- Produces: v5 sebagai tautan default situs; dokumentasi sesuai kenyataan.

- [ ] **Step 1: Label versi di dalam aplikasi**

```html
<title>goCatering v5 — Prototype Interaktif (Registrasi Penjual & Toko + Kode Restoran)</title>
```

`<h1>goCatering v4</h1>` (v4:305) → `<h1>goCatering v5</h1>`. Sisipkan blok ini **tepat sebelum** `<h2>Baru di v4</h2>` (v4:307), jangan menghapus daftar v4:

```html
  <h2>Baru di v5</h2>
  <ul>
    <li><b>Registrasi penjual 2 langkah.</b> Data diri (gelar, nama, email Gmail, NIK, WA, foto opsional) lalu data toko (nama, alamat, link Google Maps, WA customer service, foto opsional).</li>
    <li><b>Akun terbit otomatis.</b> Sistem membuat email login, <b>password sementara satu kali tampil</b>, dan mewajibkannya diganti setelah login pertama.</li>
    <li><b>Kode restoran</b> = inisial nama pemilik + 4 digit akhir NIK + nomor urut per pemilik (contoh <code>H4567001</code>), tampil di samping nama toko untuk pembeli. <b>ID restoran 6 angka hanya terlihat penjual.</b></li>
    <li><b>Sentuh kode</b> &rarr; popup berisi nama pemilik, alamat fisik, tombol <b>Buka Peta</b>, dan nomor WA customer service lengkap dengan <b>Chat WA</b>.</li>
    <li><b>Satu pemilik, banyak restoran.</b> Tombol <b>Tambah Toko</b> di dashboard memakai NIK yang sama dan menaikkan nomor urut kode.</li>
    <li><b>Isolasi antar-akun.</b> Dashboard, pesanan, dan menu hanya menampilkan toko milik akun yang login; memaksa id toko orang lain ditolak.</li>
    <li><b>Data pribadi disandikan</b> (XOR + Base64, kunci acak per perangkat) sebelum masuk <code>localStorage</code>. Ini penyamaran nilai, <b>bukan</b> enkripsi untuk kepatuhan.</li>
  </ul>
```

- [ ] **Step 2: Pengalihan `index.html` ke v5**

Ganti tiga rujukan `gocatering-prototype-v4.html` menjadi `gocatering-prototype-v5.html` (baris `meta http-equiv="refresh"`, `location.replace(...)`, dan teks tautan cadangan).

Run: `grep -n "prototype-v[45]" index.html`
Expected: tiga baris, semuanya `v5`.

- [ ] **Step 3: README**

Perbaiki `README.md` agar cocok dengan kenyataan (empat suntingan, tanpa menambah bagian baru):

1. Tabel versi — tambah baris:

```markdown
| v5 | `gocatering-prototype-v5.html` | Registrasi penjual & toko: wizard 2 langkah, akun + password sementara, kode restoran, multi-toko per pemilik, isolasi antar-akun, popup info restoran untuk pembeli |
```

2. Ganti judul "Cara menjalankan" supaya berkas default disebut v5, dan tambahkan cara menjalankan uji:

```markdown
Node dipakai untuk harness uji, bukan untuk menjalankan aplikasinya.

    node tools/test.js     # seluruh assertion (regresi v4 + fitur v5)
    node tools/serve.js    # serve di http://127.0.0.1:8848 untuk uji lewat browser
```

3. Akun demo — tambah tabel penjual:

```markdown
| Peran | Email | Password | Catatan |
| --- | --- | --- | --- |
| Penjual 1 | `rm.sederhana@gocatering.id` | `seller123` | Andi Ramadhan, NIK `…4567`, 2 restoran: RM Sederhana `A4567001`, Kekinian Food `A4567002` |
| Penjual 2 | `dapur.nusantara@gocatering.id` | `seller123` | Sari Kumalasari, NIK `…8812`, 2 restoran: Dapur Nusantara `S8812001`, Catering Sehat `S8812002` |

Akun penjual hasil registrasi memakai password sementara yang terbit sekali di layar "Akun terbit".
```

4. Catatan teknis — tambah butir jujur soal batas prototype:

```markdown
- Data penjual (nama, NIK, email, WA, password) disandikan XOR + Base64 dengan kunci acak per
  perangkat (`state.devKey`) sebelum masuk `localStorage`. Tujuannya supaya tidak terbaca mata di
  DevTools — **bukan** enkripsi untuk kepatuhan UU PDP. Foto disimpan apa adanya (data URL JPEG
  640 px) supaya kuota 5 MB tidak cepat habis; saat kuota penuh, `save()` mengulang tanpa foto.
- Tidak ada server: NIK tidak diverifikasi ke Dukcapil, link peta tidak di-geocode, dan nomor WA
  hanya tautan `wa.me`.
- Membuka `gocatering-prototype-v4.html` setelah v5 masih aman: v4 memakai kunci penyimpanan
  sendiri (`gocatering_v4`) dan tidak diubah oleh migrasi v5.
```

- [ ] **Step 4: Uji statis**

```bash
node tools/test.js
node -e "const{extract}=require('./tools/harness');require('fs').writeFileSync('.v5.js',extract('gocatering-prototype-v5.html'))" && node --check .v5.js && rm .v5.js && echo "SINTAKS OK"
```

Expected: semua uji hijau lalu `SINTAKS OK`.

- [ ] **Step 5: Regresi menyeluruh di browser (spesifikasi §10, langkah 1–8)**

Clear storage dulu. Jalankan berurutan dan catat hasilnya; satu pun kegagalan berarti task terkait belum selesai:

1. Registrasi penjual "Huang" `huang.test@gmail.com` NIK `3578090807064567` **tanpa satu foto pun** → akun terbit `H4567001` + ID 6 angka; kartu tokonya memakai tile emoji 🍽️; popup menampilkan inisial `H`.
2. Login role Penjual dengan password sementara → terdampar di Ganti Password; password = sementara ditolak; setelah ganti → dashboard hanya berisi tokonya.
3. `+ Tambah Toko` → `H4567002`; `Ganti Toko` memuat dua toko + "Semua toko saya"; tab pesanan ikut berpindah.
4. Isolasi: login Sari → tab pesanan/menu hanya Dapur Nusantara & Catering Sehat; tidak ada teks "Warung Huang"; coba `advance()` order toko lain dari konsol → toast "Bukan restoran Anda".
5. Duplikasi: registrasi dengan email `budi@mail.com` → "sudah dipakai akun pembeli"; NIK `3578010203044567` → "sudah terdaftar … Tambah Toko".
6. Pembeli: chip `kode: H44567…`/`A4567001` tampil; `document.body.innerText` di layar toko tidak memuat satu pun ID 6 angka; sentuh chip → popup dengan Buka Peta & Chat WA.
7. Alur lama: order pickup (nomor antre & Jadwal Saya), delivery (ongkir per km), cutoff 16.00 lewat tombol Jam simulasi, bayar QRIS & COD, re-pay order `pending`, profil + penyamaran nomor pembeli, mode offline + flush queue.
8. Reset Data → aplikasi kembali ke 4 toko bawaan tanpa error konsol.

- [ ] **Step 6: Putuskan publikasi, baru push (JANGAN push tanpa jawaban pengguna)**

Dua hal yang menunggu keputusan pemilik repo:

1. Apakah `docs/` (spec + rencana ini) ikut di-push ke repo publik, atau `docs/` masuk `.gitignore`.
2. Apakah `assets/` foto bawaan tetap dipakai untuk toko hasil migrasi (README sudah mencatatnya CC).

Setelah dijawab:

```bash
git log --oneline origin/main..HEAD          # periksa isi sebelum publish
git push origin main                          # Pages memakai branch main, tanpa langkah build
```

Lalu verifikasi live (Pages butuh ±30–60 detik): `https://gatnadf-ai.github.io/gocatering/` harus mengalih ke `gocatering-prototype-v5.html`, dan `https://gatnadf-ai.github.io/gocatering/gocatering-prototype-v5.html` harus boot dengan penyimpanan kosong tanpa error konsol.

- [ ] **Step 7: Commit**

```bash
git add gocatering-prototype-v5.html index.html README.md
git commit -m "docs(v5): label versi, README, dan pengalihan index ke prototype v5"
```

---

## Peta cakupan spec (untuk reviewer)

| Spec | Task |
| --- | --- |
| §1 tujuan 1–5 | 6, 7, 8, 9 (terbuka langsung oleh penjual), 8 (isolasi), 9 (kode ke pembeli), 2 (penyandian) |
| §2 butir 1–3 (model akun, NIK, multi-toko) | 3 (`ownerKeyOf`), 5 (validasi NIK), 8 (`startAddShop`/`submitAddShop`) |
| §2 butir 4 (obfuscation) | 2 |
| §2 butir 5 (foto & kompresi) | 5 |
| §2 butir 6 (link Maps) | 3 (`RE_MAP`), 5 (validasi), 9 (tombol Buka Peta) |
| §2 butir 7 (popup) | 9 |
| §2 butir 8 (running per pemilik, mulai 001) | 3, 4, 8 |
| §2 butir 9 (ID 6 angka acak) | 3, 6 |
| §2 butir 10 (NIK ganda ditolak) | 5, 6 |
| §2 butir 11 (4 toko migrasi lengkap) | 4 |
| §2 butir 12 (email tidak ganda lintas peran) | 5 (`regCta`/`validateIdentity`), 6 (`doLogin`) |
| §3 model data | 4 |
| §4 aturan validasi | 5 |
| §5 layar baru 1–6 | 5, 6, 7, 8, 9 |
| §6 generator | 3 |
| §7 perlindungan data | 2 |
| §8 risiko (kuota, `crypto.subtle`, isolasi) | 2 (`save()` fallback), 3 (tanpa subtle), 8 (penjaga) |
| §9 berkas v5 & kunci | 1, 4 |
| §10 rencana uji | setiap task Step "jalankan test"; uji manual di Task 10 Step 5 |






