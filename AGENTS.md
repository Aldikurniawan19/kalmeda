# AGENTS.md

Dokumen ini adalah instruksi wajib untuk AI agent (Claude, Copilot, Cursor, atau agent lain) setiap kali bekerja di repository ini — baik untuk membuat desain/UI maupun menulis kode. Baca dokumen ini **sebelum** memulai task apapun, dan patuhi sepanjang sesi kerja, bukan hanya di awal.

---

## 1. Aturan Wajib Dibaca Lebih Dulu

Sebelum membuat/mengubah tampilan atau menulis/mengubah kode, agent **wajib membaca isi lengkap** dua file berikut di root repository ini:

- **`aturan-desain.md`** — aturan visual: warna, tipografi, ikon, layout, komponen, copywriting UI.
- **`aturan-penulisan-code.md`** — aturan kode: struktur folder, SEO, token warna/font, database & query, best practice.

Kedua file itu adalah **sumber kebenaran (source of truth)** untuk project ini. Jika ada instruksi dari user yang tidak menyebutkan detail teknis/visual, agent tetap harus mengikuti standar di kedua file tersebut sebagai default — bukan menebak atau memakai kebiasaan generik.

Jika suatu saat isi kedua file itu direvisi, agent harus membaca ulang versi terbaru sebelum melanjutkan pekerjaan, karena versi lama tidak lagi berlaku.

---

## 2. Kapan Aturan Ini Diterapkan

| Jenis task                                          | Baca `aturan-desain.md` | Baca `aturan-penulisan-kode.md` |
| --------------------------------------------------- | ----------------------- | ------------------------------- |
| Membuat/ubah UI, halaman, komponen, styling         | Ya                      | Ya                              |
| Menulis/ubah logika bisnis, API, service            | Tidak wajib             | Ya                              |
| Query/akses database (read, create, update, delete) | Tidak                   | Ya (bagian Database & Query)    |
| Menentukan struktur folder/file baru                | Tidak                   | Ya (bagian Struktur Folder)     |
| Menulis copy/teks di UI (tombol, error, notifikasi) | Ya (bagian Copywriting) | Tidak                           |
| Setup meta tag, sitemap, performance halaman publik | Tidak                   | Ya (bagian SEO)                 |

Jika sebuah task menyentuh lebih dari satu area (misalnya membuat halaman baru lengkap dengan tampilan, kode, dan query), **kedua file wajib diikuti sekaligus**, bukan salah satu saja.

---

## 3. Prinsip Kerja Agent di Project Ini

- Posisikan diri sebagai **senior developer sekaligus design lead**, bukan sekadar menjalankan instruksi literal. Jika user meminta sesuatu yang bertentangan dengan aturan (misalnya "tambahkan emoji di tombol" atau "langsung query pakai `SELECT *`"), agent harus **mengingatkan** bahwa itu melanggar aturan project dan menawarkan alternatif yang sesuai — bukan diam-diam menuruti atau diam-diam mengabaikan.
- **Jangan berasumsi bahasa/framework tertentu.** `aturan-penulisan-kode.md` bersifat universal (PHP Laravel/CodeIgniter, Next.js, dsb). Deteksi dulu stack yang dipakai di repository ini (cek file konfigurasi seperti `composer.json`, `package.json`, struktur folder yang sudah ada) sebelum menerapkan contoh yang relevan.
- **Jangan buat token warna/font baru di luar file pusat** yang sudah diatur di `aturan-penulisan-kode.md` bagian 4. Jika file token belum ada di project ini, buat sesuai contoh di sana, jangan hardcode warna/font di file lain.
- **Jangan tulis query database langsung** di Controller/Route handler/Component. Selalu lewat layer Service/Repository sesuai bagian 5 `aturan-penulisan-kode.md`.
- **Jangan gunakan emoticon** di UI, copy, commit message, atau komentar kode yang ditulis untuk project ini.
- Sebelum menyatakan sebuah task selesai, **cocokkan hasil kerja dengan checklist** di akhir masing-masing file (`aturan-desain.md` bagian 8, `aturan-penulisan-kode.md` bagian 6).

---

## 4. Urutan Kerja yang Disarankan

1. Baca `aturan-desain.md` dan `aturan-penulisan-kode.md` (jika belum pernah dibaca di sesi ini).
2. Pahami task dari user, tentukan area mana yang tersentuh (lihat tabel bagian 2).
3. Cek konteks project yang sudah ada (struktur folder, token warna/font yang sudah didefinisikan, konvensi penamaan yang sudah dipakai) — ikuti pola yang sudah ada, jangan buat standar baru yang bertentangan.
4. Kerjakan task sambil menerapkan aturan yang relevan.
5. Sebelum menyampaikan hasil ke user, review ulang terhadap checklist di kedua file.

---

## 5. Catatan

- File ini (`AGENTS.md`) tidak menggantikan isi `aturan-desain.md` dan `aturan-penulisan-kode.md` — ia hanya penunjuk agar agent tahu kapan dan bagaimana menerapkannya.
- Jika ketiga file ini disalin ke repository lain, pastikan ikut disalin bersama-sama agar konteksnya tetap utuh.
