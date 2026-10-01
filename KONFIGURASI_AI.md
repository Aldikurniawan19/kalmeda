# Panduan dan Konfigurasi AI Chatbot — Kalmeda (Menstracker)

Dokumen ini adalah petunjuk lengkap mengenai konfigurasi, arsitektur, parameter, dan pengelolaan integrasi Artificial Intelligence (AI) yang digunakan oleh fitur chatbot konsultan klinis pada aplikasi Kalmeda.

---

## 1. Ringkasan Arsitektur AI

Fitur konsultasi klinis pada aplikasi Kalmeda mengadopsi arsitektur **Hybrid AI Engine**:
1. **Primary Engine (Cloud AI)**: Terhubung langsung ke **Google Gemini REST API** (`Google Generative Language API`) menggunakan model generasi terbaru berkecepatan tinggi dan latensi rendah.
2. **Context Engine**: Menyuntikkan data siklus menstruasi *real-time*, tanggal haid terakhir (LMP), fase siklus saat ini, estimasi masa subur, serta riwayat ginekologis pengguna ke dalam *system prompt* untuk menghasilkan jawaban yang dipersonalisasi.
3. **Resilience & Failover Layer**: Sistem memiliki deteksi model dinamis (*Model Discovery*), multi-tier failover antar model Gemini, serta batas waktu respon (*timeout*) 60 detik.
4. **Fallback Engine (Offline Clinical Expert)**: Jika koneksi internet terputus, kuota API habis, atau API tidak merespon, sistem otomatis beralih ke mesin pakar klinis lokal berbasis basis pengetahuan terverifikasi (POGI, ACOG, Kemenkes RI) tanpa menimbulkan error pada antarmuka pengguna.

---

## 2. Struktur File dan Lokasi Kode

Seluruh modul konfigurasi dan logika AI chatbot berada di dalam direktori `lib/features/chatbot/`:

| Komponen | Path File | Deskripsi |
|---|---|---|
| **Konfigurasi Utama** | `lib/features/chatbot/data/datasources/gemini_config.dart` | Menyimpan kredensial API key, model default, endpoint URL, dan timeout. |
| **Service API Gemini** | `lib/features/chatbot/data/datasources/gemini_clinical_service.dart` | Menangani HTTP request ke Google Generative Language API, streaming headers, failover model, sanitasi teks, dan safety settings. |
| **Context Generator** | `lib/features/chatbot/data/models/user_calendar_context.dart` | Menghitung dan memformat parameter siklus pengguna menjadi prompt medis. |
| **State Controller** | `lib/features/chatbot/presentation/controllers/chatbot_controller.dart` | Mengelola *lifecycle* percakapan, status *typing*, orkestrasi pemanggilan AI, dan fallback logic. |
| **Fallback Synthesizer** | `lib/features/chatbot/data/datasources/clinical_expert_synthesizer.dart` | Menghasilkan respon natural berbasis aturan klinis saat AI tidak aktif. |
| **Basis Pengetahuan Lokal** | `lib/features/chatbot/data/datasources/clinical_knowledge_base.dart` | Database pertanyaan dan jawaban klinis terverifikasi untuk pencocokan instan. |

---

## 3. Petunjuk Pengaturan API Key Google Gemini

### Langkah 1: Mendapatkan Kunci API
1. Kunjungi portal resmi **Google AI Studio**: [https://aistudio.google.com/](https://aistudio.google.com/).
2. Masuk menggunakan akun Google Anda.
3. Pilih menu **Get API key**, lalu klik tombol **Create API key**.
4. Salin kunci API yang dibuat (format string diawali dengan `AIzaSy...` atau token otentikasi Google Cloud).

### Langkah 2: Memasang Kunci API ke Proyek
Buka file `lib/features/chatbot/data/datasources/gemini_config.dart` dan perbarui konstanta `apiKey`:

```dart
class GeminiConfig {
  /// Google Gemini API Key dari Google AI Studio
  static const String apiKey = 'TEMPELKAN_API_KEY_ANDA_DI_SINI';

  /// Model identifier utama
  static const String model = 'gemini-3.1-flash-lite-preview';

  /// Endpoint REST API resmi Google Generative Language
  static const String baseUrl = 'https://generativelanguage.googleapis.com';

  /// Versi API default
  static const String defaultApiVersion = 'v1beta';

  /// Batas waktu maksimal menunggu respon (60 detik)
  static const Duration timeoutDuration = Duration(seconds: 60);

  /// Helper untuk memverifikasi apakah API key sudah diisi dengan benar
  static bool get isConfigured =>
      apiKey.trim().isNotEmpty && !apiKey.contains('TEMPELKAN');
}
```

---

## 4. Konfigurasi Model AI dan Mekanisme Failover

### Model Default yang Didukung
Aplikasi dikonfigurasi secara prioritas untuk menggunakan model Google Gemini generasi cepat dan hemat token:
1. `gemini-3.1-flash-lite-preview` (Prioritas Utama — Rekomendasi 2025/2026)
2. `gemini-3.1-flash-lite`
3. `gemini-3.6-flash`
4. `gemini-2.0-flash`
5. `gemini-1.5-flash-latest`
6. `gemini-1.5-flash`
7. `gemini-1.5-pro`
8. `gemini-pro`

### Mekanisme Dynamic Model Discovery & Failover
File `lib/features/chatbot/data/datasources/gemini_clinical_service.dart` mengimplementasikan deteksi otomatis:
1. **Model Discovery**: Memanggil endpoint `ModelService.ListModels` saat inisialisasi awal untuk mendeteksi daftar model yang aktif dan diizinkan pada akun Google Anda.
2. **Sequential Failover**: Jika model utama mengembalikan status error (misalnya HTTP 404/429/503), service akan secara otomatis mencoba kandidat model berikutnya dalam daftar prioritas dalam rentang timeout 10–12 detik per model.
3. **Endpoint Version Fallback**: Jika endpoint `v1beta` gagal, service mencoba beralih ke endpoint `v1`.
4. **Local Fallback**: Jika seluruh endpoint API tidak merespon dalam 60 detik, percakapan otomatis dijawab oleh `ClinicalExpertSynthesizer` lokal.

---

## 5. Pengaturan Parameter Generasi (Hyperparameters)

Parameter inferensi AI diatur pada method `_buildPayload` di file `lib/features/chatbot/data/datasources/gemini_clinical_service.dart`:

```json
{
  "generationConfig": {
    "temperature": 0.3,
    "maxOutputTokens": 1024
  }
}
```

- **`temperature: 0.3`**: Nilai suhu rendah dipilih secara sengaja agar output bersifat deterministik, konsisten secara fakta medis, dan meminimalkan risiko halusinasi.
- **`maxOutputTokens: 1024`**: Cukup untuk menyajikan penjelasan klinis terstruktur (penyebab, penanganan mandiri, tanda bahaya, dan rujukan).

---

## 6. Pengaturan Keamanan (Safety Settings)

Karena aplikasi menangani topik kesehatan reproduksi, menstruasi, dan ginekologi, filter keamanan Gemini disesuaikan agar tidak memblokir terminologi medis penting:

```dart
'safetySettings': [
  {
    'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
    'threshold': 'BLOCK_ONLY_HIGH', // Mencegah pemblokiran istilah anatomi reproduksi medis
  },
  {
    'category': 'HARM_CATEGORY_HATE_SPEECH',
    'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
  },
  {
    'category': 'HARM_CATEGORY_HARASSMENT',
    'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
  },
  {
    'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
    'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
  },
]
```

---

## 7. Format System Prompt & Standar Persona Klinis

*System instruction* yang dikirimkan ke Gemini AI mewajibkan AI bertindak sebagai **Konsultan Medis Klinis Resmi Kalmeda** dengan aturan ketat:

### Standar Penulisan:
1. **Sapaan Personal**: Menyapa nama pengguna di awal pesan (contoh: "Halo Kak [Nama],").
2. **Empati & Validasi**: Mengakui keluhan pengguna secara langsung di paragraf pembuka.
3. **Struktur Bubble Chat**:
   - Judul/header pengantar dicetak tebal (`**...**`).
   - Poin bernomor dengan judul ditebalkan: `1. **Judul Tindakan:** Penjelasan rinci.`
   - Poin daftar: `• **Nama Gejala:** Keterangan medis.`
4. **Kepatuhan Aturan Desain (Tanpa Emoticon)**: Dilarang keras memunculkan emoticon atau emoji apa pun. Sistem dilengkapi fungsi pembersih otomatis (`_emojiPattern`) untuk memastikan kepatuhan mutlak terhadap `aturan-desain.md`.
5. **Sitasi Literatur**: Respon wajib menyertakan rujukan standar konsensus Sp.OG, POGI, ACOG, dan Kemenkes RI di bagian akhir.

### Integrasi Data Kalender Otomatis:
Jika pengguna memiliki data siklus di aplikasi, prompt menyertakan:
- Hari pertama haid terakhir (LMP)
- Panjang siklus dan durasi haid rata-rata
- Posisi siklus hari ini (hari ke-X, fase folikular/luteal/ovulasi)
- Status keterlambatan haid (hari keterlambatan)
- Estimasi masa subur berikutnya
- Riwayat ginekologis dan metode kontrasepsi

---

## 8. Panduan Mengatasi Kendala (Troubleshooting)

| Gejala / Error | Penyebab | Solusi |
|---|---|---|
| **Pesan fallback lokal selalu muncul** | API key belum diisi atau format masih placeholder. | Buka `lib/features/chatbot/data/datasources/gemini_config.dart`, masukkan API key yang valid dari Google AI Studio. |
| **HTTP 400: API key not valid** | Kunci API salah atau dinonaktifkan di Google Cloud Console. | Buat ulang API key baru di [Google AI Studio](https://aistudio.google.com/) dan perbarui `gemini_config.dart`. |
| **HTTP 429: Resource exhausted / Quota exceeded** | Batas limit free-tier Google AI Studio tercapai. | Sistem akan otomatis melakukan fallback ke mesin lokal; pertimbangkan upgrade kuota pada Google Cloud Console jika memerlukan kuota lebih tinggi. |
| **HTTP 404: Model not found** | Nama model di `GeminiConfig.model` sudah usang/deprecated. | Ubah konstanta `GeminiConfig.model` ke model aktif terbaru (contoh: `gemini-3.1-flash-lite-preview` atau `gemini-2.0-flash`). Fitur *Dynamic Model Discovery* akan mencoba mencari alternatif secara otomatis. |
| **Respon terpotong atau macet** | Terjadi chunked transfer stall pada jaringan seluler. | `GeminiClinicalService` telah dilengkapi dengan `Content-Length` eksplisit dan timeout per-koneksi untuk mencegah *hanging*. Pastikan koneksi internet stabil. |

---

## 9. Praktik Terbaik Keamanan (Security Best Practice)

1. **Jangan unggah API Key produksi ke repository publik**:
   - Jika ingin memisahkan API Key saat proses build/CI-CD, gunakan parameter `--dart-define` saat build Flutter:
     ```bash
     flutter run --dart-define=GEMINI_API_KEY=kunci_rahasia_anda
     ```
   - Lalu baca menggunakan `String.fromEnvironment('GEMINI_API_KEY')` di dalam `gemini_config.dart`.
2. **Batasi Scope API Key**:
   - Pada Google Cloud Console / Google AI Studio, batasi hak akses API Key hanya untuk API **Generative Language API**.
3. **Privasi Pengguna**:
   - Riwayat percakapan konsultasi di aplikasi Kalmeda bersifat lokal dan sesi chat otomatis dibersihkan saat sesi berakhir untuk melindungi privasi kesehatan pengguna.

---

## 10. Checklist Verifikasi Konfigurasi

- [ ] Kunci API Google Gemini sudah terisi di `GeminiConfig.apiKey`.
- [ ] Model identifier mengarah ke model aktif yang didukung.
- [ ] Uji coba pengiriman pertanyaan di menu Konsultasi Chatbot:
  - Jawaban muncul dengan format rapi, sapaan nama pengguna, dan tanpa emoticon.
  - Data kalender pengguna terintegrasi saat menanyakan keterlambatan haid atau siklus normal.
  - Saat mode pesawat (offline), sistem tetap memberikan jawaban dari fallback lokal tanpa aplikasi mengalami crash.
