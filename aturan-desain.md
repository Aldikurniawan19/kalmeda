# Aturan Desain — Modern, Simpel, Tidak "AI Slop"

Dokumen ini adalah panduan wajib dipatuhi setiap kali membuat atau mengubah tampilan (UI). Tujuannya: desain terasa dibuat dengan sengaja oleh seseorang yang paham konteksnya — bukan hasil template generik yang langsung dikenali sebagai buatan AI.

---

## 1. Prinsip Utama

- **Modern & simpel**, bukan minim usaha. Simpel berarti setiap elemen punya alasan untuk ada, bukan karena "yang penting kosong".
- **Konsisten**: satu bahasa visual di seluruh halaman — spacing, warna, tipografi, dan komponen harus terasa berasal dari satu sistem yang sama.
- **Fungsi dulu, hiasan belakangan**. Dekorasi hanya dipakai jika memperjelas, bukan memperindah tanpa tujuan.
- Hindari pola "template AI" yang sudah terlalu sering muncul: latar krem + font serif kontras + aksen terracotta; latar hitam pekat + satu aksen neon; atau layout ala koran dengan garis tipis di mana-mana tanpa alasan konten. Boleh dipakai **hanya** jika memang cocok dengan konteks produk, bukan default otomatis.

---

## 2. Warna

- **Jangan mencampur banyak warna sekaligus.** Gunakan sistem warna terbatas dan disiplin:
  - 1 warna dasar/netral (background)
  - 1 warna teks/kontras utama
  - 1–2 warna aksen (untuk CTA, highlight, status)
  - Maksimal 1 warna tambahan untuk state (misalnya error/success), itu pun secukupnya.
- Tentukan palet di awal dalam bentuk hex value yang jelas, jangan asal pilih warna saat proses styling berjalan.
- Pastikan kontras teks vs background memenuhi standar aksesibilitas (rasio kontras AA minimum).
- Warna aksen dipakai secukupnya untuk menuntun perhatian (CTA, link, ikon aktif) — bukan disebar ke banyak elemen sekaligus sehingga semuanya "berteriak".
- Hindari gradient yang tidak punya alasan konten (gradient dekoratif generik = ciri khas tampilan AI-generated).

---

## 3. Tipografi

- Gunakan maksimal 2 jenis font: 1 untuk heading/display, 1 untuk body text. Tambahkan font ke-3 hanya jika benar-benar perlu (misalnya untuk data/monospace).
- Buat skala tipografi yang jelas dan konsisten (misalnya: 12/14/16/20/24/32/48px), jangan ukuran acak per komponen.
- Perhatikan line-height dan letter-spacing agar teks nyaman dibaca, bukan sekadar default browser.
- Hierarki visual harus jelas hanya dari tipografi (ukuran, berat, jarak) tanpa perlu warna berlebihan untuk membedakan mana judul, mana isi.

---

## 4. Ikon, Bukan Emoticon

- **Dilarang menggunakan emoticon/emoji** (😀, 🚀, ✅, dsb) di dalam UI, copywriting, tombol, atau notifikasi.
- Gunakan **icon set** yang konsisten (satu keluarga ikon saja, jangan campur beberapa library ikon berbeda dalam satu tampilan).
- Rekomendasi icon library yang perlu di-install sesuai kebutuhan proyek:
  - **Lucide Icons** — `npm install lucide-react` (ringan, modern, cocok untuk web app)
  - **Heroicons** — `npm install @heroicons/react` (cocok dengan Tailwind)
  - **Phosphor Icons** — `npm install @phosphor-icons/react` (banyak varian: thin, regular, bold, fill)
  - **Font Awesome** — jika butuh ikon yang sangat lengkap/legacy support
- Semua ikon harus:
  - Punya ukuran & stroke-width yang konsisten di seluruh halaman.
  - Selaras secara optik dengan teks di sebelahnya (jangan terlalu besar/kecil).
  - Digunakan untuk memperjelas fungsi (navigasi, status, aksi), bukan sekadar hiasan.

---

## 5. Layout & Spacing

- Gunakan sistem spacing berbasis skala (misal kelipatan 4px atau 8px: 4, 8, 12, 16, 24, 32, 48, 64px). Jangan pakai angka acak seperti 13px atau 27px.
- Beri ruang kosong (whitespace) yang cukup — jangan memadatkan elemen hanya karena "biar keliatan penuh".
- Grid harus rapi dan responsif: pastikan tampilan tetap enak dilihat dari mobile sampai desktop.
- Hindari border-radius yang tidak konsisten antar komponen (pilih satu radius standar untuk card/button/input, misalnya 8px, lalu pakai konsisten).

---

## 6. Komponen & Interaksi

- Semua tombol, input, card harus punya state yang jelas: default, hover, focus, disabled — dan terlihat konsisten di seluruh halaman.
- Fokus keyboard (focus ring) wajib terlihat jelas untuk aksesibilitas, jangan dihilangkan demi estetika.
- Animasi/transisi dipakai secukupnya dan bertujuan (contoh: transisi hover, transisi buka/tutup modal). Hindari animasi berlebihan di banyak elemen sekaligus — ini justru membuat tampilan terasa "generic AI demo".
- Gunakan library UI/animasi sesuai kebutuhan, contoh:
  - **Tailwind CSS** — `npm install tailwindcss` (utility-first, cepat untuk styling konsisten)
  - **Framer Motion** — `npm install framer-motion` (animasi halus, dipakai secukupnya)
  - **shadcn/ui** — kumpulan komponen siap pakai yang bisa disesuaikan (bukan library, tapi kode yang di-copy ke project)

---

## 7. Copywriting di UI

- Tulisan singkat, jelas, dan aktif. Contoh: "Simpan perubahan", bukan "Kirim" atau "Submit data anda sekarang".
- Nama aksi harus konsisten dari tombol sampai notifikasi hasilnya (tombol "Terbitkan" → notifikasi "Berhasil diterbitkan", bukan "Published").
- Pesan error harus jelas menyebutkan apa yang salah dan cara memperbaikinya — bukan permintaan maaf generik ("Terjadi kesalahan, coba lagi nanti" tanpa konteks).
- Tanpa emoticon di seluruh microcopy (tombol, toast, tooltip, error message).

---

## 8. Checklist Sebelum Selesai

- [ ] Palet warna maksimal sesuai batas di atas, tidak campur aduk
- [ ] Hanya 1–2 font dipakai secara konsisten
- [ ] Tidak ada emoticon di manapun, semua indikator visual pakai ikon
- [ ] Satu icon library saja, ukuran & style konsisten
- [ ] Spacing mengikuti skala yang konsisten
- [ ] Tidak terlihat seperti 3 pola default "AI-generated" yang disebut di atas
- [ ] Ada 1 elemen signature/khas yang membuat desain ini mudah diingat dan relevan dengan produknya
- [ ] Responsif di mobile, focus state terlihat, kontras warna memenuhi standar aksesibilitas
