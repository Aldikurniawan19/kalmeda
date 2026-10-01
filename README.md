# Kalmeda (Menstracker)

Aplikasi pelacak siklus menstruasi, kesehatan reproduksi wanita, dan konsultasi klinis cerdas berbasis Flutter.

## Dokumentasi & Panduan

- [Panduan Konfigurasi AI Chatbot](KONFIGURASI_AI.md)
- [Aturan Desain UI](aturan-desain.md)
- [Aturan Penulisan Kode](aturan-penulisan-code.md)
- [Instruksi Agent AI](AGENTS.md)

## Memulai Proyek

Pastikan Flutter SDK sudah terpasang di sistem Anda.

1. Jalankan `flutter pub get` untuk mengunduh seluruh dependensi.
2. Siapkan konfigurasi API key Google Gemini di `lib/features/chatbot/data/datasources/gemini_config.dart` (lihat [Panduan Konfigurasi AI](KONFIGURASI_AI.md)).
3. Jalankan aplikasi di emulator atau perangkat:
   ```bash
   flutter run
   ```

