# Portofolio — Rochman Ramadhani Chiefto Irawan

Dua dokumen yang saling menopang:

- **`index.html`** — deck *Sembilan Tahun Berkarya*. 39 slide, satu file HTML, tanpa dependensi.
  Lapisan dokumentasi: linimasa lengkap 2017–2026, produk yang dipegang, konsultansi, dan bukti kerjanya.
- **`cv/cv.html`** → **`assets/CV_Rochman_Ramadhani_Product_Owner.pdf`** — CV tiga halaman, fokus ke hasil.

Aturan yang mengikat keduanya: **CV menyebut angkanya, deck menunjukkan artefaknya.** Tidak boleh ada
angka di CV yang tidak punya slide pendukung, dan sebaliknya.

Hosting: [oman-porto.skolain.id](https://oman-porto.skolain.id) (Cloudflare Pages).

## Menjalankan

Buka `index.html` di browser mana pun. Tidak perlu build, tidak perlu npm.

Navigasi: `→` / `←` / `Space` / `PageUp`–`PageDown`, scroll, atau geser di layar sentuh.
`Home` dan `End` melompat ke slide pertama dan terakhir.

Tekan `E` (atau arahkan kursor ke pojok kiri atas) untuk menyunting teks langsung di slide.
Perubahan tersimpan di `localStorage`; `Ctrl/⌘+S` mengekspor salinan HTML baru.

### Deep link

Nomor slide tersimpan di hash URL (`#15`), tapi untuk ditulis di CV pakai **alias**, bukan angka:

```
#peta  #angka  #skolain  #primasejahtera  #siloam  #qlola  #oca  #bri
#frames  #klhk  #dokter  #advisory  #hegemoni  #seminar  #pdc  #peringkat  #carakerja  #kontak
```

Hash posisional putus begitu ada satu slide disisipkan, sementara PDF CV yang sudah beredar tidak bisa
ditarik lagi. Alias tidak ikut bergeser.

## Membangun ulang

```bash
./scripts/build-assets.sh   # foto & video: sips + ffmpeg (butuh: brew install ffmpeg)
./cv/build.sh               # CV -> PDF via Chrome headless, plus cek regresi ATS
```

`build-assets.sh` mengambil sumber dari `~/Downloads` dan dari repo `slide-kka-smk`, lalu
mengonversi video 4K HEVC ke H.264. Bukan sekadar optimasi: **HEVC tidak jalan di Firefox sama sekali.**
Audio dibuang (`-an`) — semua klip diputar `muted`, dan audio rapat internal tidak perlu ikut terbit.

`cv/build.sh` menutup dengan `pdftotext -layout` dan memeriksa nama, nomor telepon, URL, serta judul
bagian masih terbaca dalam urutan yang benar. Kalau ada yang hilang, build gagal — itu regresi ATS.

## Keputusan yang perlu diketahui sebelum mengubah

**Font di-host sendiri di `assets/fonts/` (~128 KB), bukan lewat Google Fonts CDN.** Deck harus tetap
tampil sama di jaringan yang memblokir CDN, dan headless Chrome bisa mencetak sebelum webfont selesai
dimuat — PDF-nya jadi diam-diam beda dari preview. Bricolage dan Familjen itu variable font, satu berkas
untuk semua weight.

**`.pos` di-deklarasikan ulang setelah semua komponen** (bagian 24 di stylesheet). Hampir setiap arketipe
(`.cards`, `.maptable`, `.flow`, `.linkcard`, `.hbox`, `.rail`, `.lanes`, …) menyetel `position:relative`
di bagian setelah `.pos`. Specificity-nya sama, jadi yang belakangan menang dan `--x`/`--y` berubah arti
diam-diam: bukan koordinat dari tepi slide, tapi geseran dari posisi aliran. Gejalanya menipu karena
elemen pertama tiap slide tetap mendarat di tempat yang benar. `transform` sengaja **tidak** ikut diulang —
itu akan meratakan semua kemiringan hand-drawn; untuk kotak yang ingin lurus, pakai `.rot-0`.

**Nomor halaman dan isi rail digenerate JS saat boot**, bukan ditulis tangan. Menyisipkan slide tidak
perlu penomoran ulang manual. Urutannya mengikat: `buildChrome()` harus jalan **sebelum** `restoreEdits()`,
karena `restoreEdits` mengunci teks berdasarkan posisi elemen.

**`STORE_PREFIX` = `portofolio-rrci:v1:`.** Kunci `localStorage` di deck lama tidak memuat identitas deck
sama sekali, jadi dua deck di satu origin akan saling menimpa isi editnya. Naikkan ke `v2` kalau slide
ditata ulang besar-besaran.

**`@page` dan `print-color-adjust:exact` wajib ada.** Papan tulisnya 100% gradient CSS; tanpa keduanya
PDF keluar jadi teks hitam di atas putih dengan orientasi potret.

## Linimasa

`.rail` (enam bab, lebar sama) dan `.lanes` (Gantt berskala) adalah dua tingkat dari komponen yang sama.
Jendela waktunya di-set di container — `--from` / `--to` — dan tiap bar membawa `--y0`/`--y1` dalam
**tahun desimal** (`2022.92` = Desember 2022), supaya bisa dicek mata waktu review.

Segmen rail dibuat sama lebar, bukan proporsional waktu: pada skala sebenarnya Bab 4 cuma dapat 6,6%
dan tidak terbaca, padahal tahun-tahun padat itu yang isinya paling banyak. Karena tiap segmen diberi
label rentang tanggal aslinya, tidak ada klaim skala yang perlu dibantah — dan grafik yang benar-benar
berskala ada tepat di bawahnya.

Bar di bawah ~0,9 tahun pada jendela 10 tahun terlalu sempit untuk label di dalam; pakai `.lbl-out`.
Dua penugasan yang benar-benar tumpang tindih di satu jalur pakai `.up` / `.dn` supaya tumpang tindihnya
terlihat, bukan tersembunyi — itu justru isi ceritanya.

## Batas yang dipegang soal privasi

Deck ini publik, jadi aturannya sama seperti deck KKA SMK: **dokumentasi yang memang sudah diterbitkan
resmi boleh tampil; dokumen internal yang memuat nama, wajah, atau skor rekan kerja tidak.**

Konkretnya: papan peringkat "Support System" Maret 2025 **tidak** ditampilkan sebagai gambar — prestasinya
tetap diklaim penuh, hanya bentuk buktinya jadi teks. Foto tim BRI dan rekaman acara internal tidak dipakai.
Screenshot percakapan di slide 34 sudah dipotong sampai nama dan nomor pengirimnya hilang.
