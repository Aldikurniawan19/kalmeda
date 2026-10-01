# Coding Standards & Project Structure — Flutter (Android)

Dokumen ini berisi aturan penulisan kode dan struktur folder untuk proyek aplikasi Android berbasis Flutter. Tujuannya: kode konsisten, mudah dibaca, mudah di-maintain, dan efisien secara performa.

---

## 1. Prinsip Utama

1. **Konsisten** — satu gaya penulisan untuk seluruh tim/kode.
2. **Simple & Readable** — kode ditulis untuk dibaca manusia, bukan hanya dijalankan mesin.
3. **Single Responsibility** — satu class/function hanya melakukan satu tugas.
4. **DRY (Don't Repeat Yourself)** — hindari duplikasi logic, buat widget/function reusable.
5. **Testable** — pisahkan logic bisnis dari UI agar mudah di-unit test.
6. **Scalable** — struktur folder harus tetap rapi walau fitur bertambah banyak.

---

## 2. Struktur Folder Proyek

Gunakan pendekatan **Feature-First** (bukan layer-first), karena lebih scalable untuk aplikasi besar.

```
lib/
├── core/                        # Hal-hal umum, dipakai di seluruh app
│   ├── constants/                # App constants, string, ukuran, dsb
│   ├── theme/                    # Warna, text style, tema aplikasi
│   ├── utils/                    # Helper function, extension, formatter
│   ├── network/                  # Dio/Http client, interceptor, api config
│   ├── error/                    # Exception & failure handling
│   ├── widgets/                  # Widget reusable/global (button, loading, dsb)
│   └── routes/                   # App routing / navigation config
│
├── features/                    # Setiap fitur berdiri sendiri
│   └── auth/
│       ├── data/
│       │   ├── models/            # Model data (DTO), fromJson/toJson
│       │   ├── datasources/       # Remote & local data source
│       │   └── repositories/      # Implementasi repository
│       ├── domain/
│       │   ├── entities/          # Entity murni (tanpa dependency luar)
│       │   ├── repositories/      # Kontrak/interface repository
│       │   └── usecases/          # Business logic per use case
│       └── presentation/
│           ├── screens/           # Halaman/page
│           ├── widgets/           # Widget khusus fitur ini
│           └── controllers/       # State management (Bloc/Cubit/Riverpod/Provider)
│
├── services/                    # Service pihak ketiga (firebase, notifikasi, dsb)
├── config/                      # Environment config (dev/staging/prod)
└── main.dart                    # Entry point aplikasi
```

**Aturan folder:**
- 1 fitur = 1 folder di `features/`. Jangan campur logic fitur A di fitur B.
- Widget yang dipakai lebih dari 1 fitur → pindahkan ke `core/widgets/`.
- Jangan taruh business logic di dalam folder `presentation/`.
- File model **wajib** dipisah dari entity jika menggunakan Clean Architecture.

---

## 3. Penamaan (Naming Convention)

| Elemen | Aturan | Contoh |
|---|---|---|
| File & folder | `snake_case` | `login_screen.dart`, `user_repository.dart` |
| Class, Enum, Extension | `PascalCase` | `LoginScreen`, `UserModel` |
| Variable & function | `camelCase` | `userName`, `getUserData()` |
| Constant | `camelCase` dengan prefix `k` (opsional) atau `SCREAMING_SNAKE_CASE` untuk global | `kDefaultPadding`, `API_BASE_URL` |
| Private member | prefix underscore `_` | `_controller`, `_fetchData()` |

**Aturan tambahan:**
- Nama file widget/screen harus mencerminkan isinya: `login_screen.dart` → berisi `LoginScreen`.
- Nama harus deskriptif, hindari singkatan ambigu (`btn`, `usr`, `tmp`).
- Boolean diawali `is`, `has`, `should` → `isLoading`, `hasError`, `shouldRefresh`.

---

## 4. Aturan Widget & UI

1. **Pecah widget besar menjadi widget kecil.** Jangan buat 1 method `build()` sepanjang 300+ baris.
2. Gunakan **`const` constructor** sebisa mungkin untuk widget statis → meningkatkan performa rendering.
   ```dart
   // Baik
   const SizedBox(height: 16);

   // Hindari
   SizedBox(height: 16);
   ```
3. Hindari **nested widget terlalu dalam** (>4-5 level). Ekstrak ke widget/function terpisah.
4. Gunakan `Key` pada widget dalam `List`/`ListView.builder` untuk mencegah rebuild tidak perlu.
5. Pisahkan **UI (dumb widget)** dari **logic (state management)**. UI tidak boleh langsung memanggil API.
6. Gunakan `SafeArea`, `MediaQuery`, dan layout responsif — hindari ukuran hardcode (`width: 320`).
7. Style/warna/teks **wajib** dari `core/theme/`, jangan hardcode warna (`Color(0xFF123456)`) berulang di banyak file.

---

## 5. State Management

- Tentukan **satu** state management di awal project (Bloc/Cubit, Riverpod, atau Provider) — jangan campur beberapa dalam satu proyek tanpa alasan kuat.
- Business logic **tidak boleh** berada di dalam widget (`StatefulWidget`/`build()`), harus di controller/bloc/notifier.
- Gunakan pattern yang jelas untuk state: `Loading`, `Success`, `Error`, `Empty` (bukan sekadar `bool isLoading`).
- Hindari `setState()` untuk state yang kompleks atau dipakai lintas widget.

---

## 6. Manajemen Data & API

1. Semua request API melalui satu `ApiClient`/`Dio` instance di `core/network/`.
2. Gunakan **Repository Pattern** — UI tidak boleh memanggil datasource langsung.
3. Parsing JSON wajib pakai model dengan `fromJson`/`toJson` (boleh manual atau `freezed`/`json_serializable`).
4. Tangani error dengan `try-catch` + custom `Failure`/`Exception` class, jangan biarkan error mentah sampai ke UI.
5. Gunakan `Either<Failure, Data>` (package `dartz`/`fpdart`) atau pola serupa untuk penanganan error yang eksplisit (opsional tapi disarankan).

---

## 7. Efisiensi & Performa

1. Gunakan `ListView.builder`/`GridView.builder`, **jangan** `ListView(children: [...])` untuk data banyak/dinamis.
2. Hindari rebuild widget yang tidak perlu — gunakan `const`, `Selector`, `Consumer` dengan scope kecil, atau `BlocBuilder` dengan `buildWhen`.
3. Gunakan `cached_network_image` untuk gambar dari internet agar tidak fetch berulang.
4. Hindari operasi berat (loop besar, parsing besar) di main thread → gunakan `compute()`/isolate jika perlu.
5. Dispose semua `Controller`, `AnimationController`, `StreamSubscription` di method `dispose()`.
6. Lazy load data (pagination) untuk list panjang, jangan fetch semua data sekaligus.
7. Gunakan `flutter analyze` dan `flutter pub run build_runner` (bila pakai codegen) sebelum commit.

---

## 8. Aturan Penulisan Kode Umum

- Ikuti **Effective Dart** (official Dart style guide) sebagai baseline.
- Jalankan `dart format .` sebelum commit — format kode wajib konsisten.
- Aktifkan **`flutter_lints`**/`very_good_analysis` di `analysis_options.yaml`, dan pastikan tidak ada warning sebelum push.
- Function idealnya < 30-40 baris. Jika lebih, pertimbangkan untuk dipecah.
- Hindari magic number/string — pindahkan ke `constants/`.
  ```dart
  // Hindari
  if (status == 2) { ... }

  // Baik
  if (status == OrderStatus.completed) { ... }
  ```
- Tambahkan komentar **hanya untuk logic yang tidak jelas/kompleks**, bukan menjelaskan hal yang sudah jelas dari kode.
- Gunakan `//TODO:` untuk pekerjaan yang belum selesai, sertakan nama/tanggal jika perlu.

---

## 9. Import & Dependency

- Urutan import: **Dart SDK → Flutter → package eksternal → project internal**, dipisah baris kosong.
  ```dart
  import 'dart:async';

  import 'package:flutter/material.dart';

  import 'package:bloc/bloc.dart';
  import 'package:dio/dio.dart';

  import 'package:myapp/core/theme/app_colors.dart';
  ```
- Gunakan **relative import** hanya dalam 1 fitur yang sama; gunakan **package import** (`package:myapp/...`) untuk lintas folder.
- Jangan import package baru tanpa alasan jelas — cek dulu apakah bisa pakai yang sudah ada.

---

## 10. Testing

- Setiap `usecase`/`repository`/`helper function` penting wajib memiliki **unit test**.
- Widget kompleks/reusable sebaiknya punya **widget test**.
- Struktur folder test mengikuti struktur `lib/`:
  ```
  test/
  └── features/
      └── auth/
          ├── data/
          ├── domain/
          └── presentation/
  ```

---

## 11. Git & Commit

- Commit message singkat, jelas, gunakan format: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`.
  - Contoh: `feat: add login screen with validation`
- Satu commit = satu perubahan logis, jangan gabung banyak fitur berbeda dalam satu commit.
- Buat branch per fitur: `feature/login-screen`, `fix/token-expired`.

---

## 12. Checklist Sebelum Pull Request

- [ ] Kode sudah di-`dart format`
- [ ] Tidak ada warning dari `flutter analyze`
- [ ] Tidak ada `print()` yang tertinggal (gunakan `debugPrint`/logger)
- [ ] Widget besar sudah dipecah
- [ ] Tidak ada hardcoded string/warna/angka
- [ ] Controller/Stream sudah di-dispose
- [ ] Sudah ditest secara manual di device/emulator
- [ ] Unit test (bila ada logic baru) sudah ditambahkan & lulus

---

*Dokumen ini bersifat living document — boleh disesuaikan/diperbarui seiring perkembangan tim dan kebutuhan proyek.*
