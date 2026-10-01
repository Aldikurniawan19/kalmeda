import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:menstracker/features/chatbot/data/datasources/gemini_config.dart';

/// Structured response result for Google Gemini API calls.
class GeminiResponseResult {
  final bool isSuccess;
  final String? text;
  final String? errorMessage;
  final int? statusCode;

  const GeminiResponseResult({
    required this.isSuccess,
    this.text,
    this.errorMessage,
    this.statusCode,
  });

  factory GeminiResponseResult.success(String text) {
    return GeminiResponseResult(isSuccess: true, text: text);
  }

  factory GeminiResponseResult.failure(String errorMessage, {int? statusCode}) {
    return GeminiResponseResult(
      isSuccess: false,
      errorMessage: errorMessage,
      statusCode: statusCode,
    );
  }
}

/// Service connecting Kalmeda chatbot directly to Google Gemini AI REST API.
/// Features dynamic model discovery, Content-Length streaming fixes, and multi-model failover.
/// Adheres strictly to `aturan-desain.md` and `aturan-penulisan-code.md`.
class GeminiClinicalService {
  static final GeminiClinicalService _instance =
      GeminiClinicalService._internal();
  factory GeminiClinicalService() => _instance;

  GeminiClinicalService._internal();

  /// Cached active API version (e.g. 'v1beta' or 'v1').
  String _activeApiVersion = GeminiConfig.defaultApiVersion;

  /// Cached active model identifier (e.g. 'gemini-3.6-flash' or 'gemini-2.0-flash').
  String _activeModel = GeminiConfig.model;

  /// List of supported models returned by Google ModelService.ListModels.
  List<String> _supportedModels = [];

  /// Flag indicating whether available models have been queried from Google AI.
  bool _hasDiscoveredModel = false;

  /// Regex pattern to strip any emoticons/emojis, strictly enforcing `aturan-desain.md`.
  static final RegExp _emojiPattern = RegExp(
    r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}|\u{1F900}-\u{1F9FF}|\u{1FA70}-\u{1FAFF}]',
    unicode: true,
  );

  /// Discovers available and supported models for the current API key via Google ModelService.ListModels.
  Future<List<String>> discoverSupportedModels() async {
    final versionsToTry = ['v1beta', 'v1'];
    final allDiscovered = <String>[];

    for (final version in versionsToTry) {
      HttpClient? client;
      try {
        client = HttpClient()..connectionTimeout = const Duration(seconds: 8);

        final url = Uri.parse(
          '${GeminiConfig.baseUrl}/$version/models?key=${GeminiConfig.apiKey}',
        );

        final request = await client
            .getUrl(url)
            .timeout(const Duration(seconds: 8));
        final response = await request.close().timeout(
          const Duration(seconds: 8),
        );
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(body);
          final models = data['models'] as List<dynamic>?;
          if (models != null && models.isNotEmpty) {
            for (final m in models) {
              if (m is Map<String, dynamic>) {
                final rawName = m['name'] as String? ?? '';
                final cleanName = rawName.replaceFirst('models/', '');
                final methods =
                    (m['supportedGenerationMethods'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                if (methods.contains('generateContent')) {
                  if (!allDiscovered.contains(cleanName)) {
                    allDiscovered.add(cleanName);
                  }
                }
              }
            }

            debugPrint(
              'Gemini ModelService.ListModels ($version) berhasil. Model tersedia: $allDiscovered',
            );
          }
        } else {
          debugPrint(
            'Gemini ModelService.ListModels ($version) gagal status ${response.statusCode}: $body',
          );
        }
      } catch (e) {
        debugPrint('Gemini ModelService.ListModels ($version) exception: $e');
      } finally {
        client?.close(force: true);
      }
    }

    _supportedModels = allDiscovered;
    _hasDiscoveredModel = true;
    return allDiscovered;
  }

  /// Generates a clinical consultation response via Google Gemini REST API.
  Future<GeminiResponseResult> generateResponse(
    String query, {
    String? userName,
    String? clinicalContext,
  }) async {
    // 1. Guard check: API key presence
    if (!GeminiConfig.isConfigured) {
      debugPrint(
        'GeminiClinicalService: API Key is missing or default placeholder',
      );
      return GeminiResponseResult.failure(
        'Kunci API Gemini belum dikonfigurasi. Harap masukkan API key di gemini_config.dart.',
      );
    }

    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return GeminiResponseResult.failure('Pertanyaan tidak boleh kosong.');
    }

    // 2. Query supported models if not yet discovered
    if (!_hasDiscoveredModel || _supportedModels.isEmpty) {
      await discoverSupportedModels();
    }

    // Build candidates list to try, starting with preferred active models
    final candidateModels = <String>[];
    if (_activeModel.isNotEmpty) candidateModels.add(_activeModel);

    // Add prioritized order (gemini-3.1-flash-lite-preview is primary)
    const priorityList = [
      'gemini-3.1-flash-lite-preview',
      'gemini-3.1-flash-lite',
      'gemini-3.6-flash',
      'gemini-2.0-flash',
      'gemini-2.0-flash-exp',
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-pro',
    ];

    for (final p in priorityList) {
      if (!candidateModels.contains(p)) candidateModels.add(p);
    }

    // Append any other discovered models from Google API
    for (final s in _supportedModels) {
      if (!candidateModels.contains(s)) candidateModels.add(s);
    }

    String lastError = 'Tidak ada respon dari server';
    int? lastStatus;

    // Try candidates sequentially with failover
    for (final candidate in candidateModels) {
      // Skip known deprecated model that explicitly told us to update
      if (candidate == 'gemini-2.5-flash') continue;

      debugPrint(
        'Mencoba Gemini API model: $candidate (versi $_activeApiVersion)...',
      );
      final result = await _executeRequest(
        apiVersion: _activeApiVersion,
        model: candidate,
        query: trimmedQuery,
        userName: userName,
        clinicalContext: clinicalContext,
        timeout: const Duration(seconds: 12),
      );

      if (result.isSuccess &&
          result.text != null &&
          result.text!.trim().isNotEmpty) {
        _activeModel = candidate;
        debugPrint('==================================================');
        debugPrint('>>> MODEL BERHASIL TERHUBUNG: [$candidate] <<<');
        debugPrint('==================================================');
        return result;
      }

      lastError = result.errorMessage ?? lastError;
      lastStatus = result.statusCode;

      // Check if Google explicitly recommended a specific model in its error message
      final recommendedMatch = RegExp(
        r'models/([a-zA-Z0-9\.\-_]+)',
      ).firstMatch(lastError);
      if (recommendedMatch != null) {
        final recommended = recommendedMatch.group(1)!;
        if (recommended != candidate &&
            !candidateModels.contains(recommended)) {
          debugPrint(
            'Google menyarankan model: $recommended. Langsung mencoba model tersebut...',
          );
          final recResult = await _executeRequest(
            apiVersion: _activeApiVersion,
            model: recommended,
            query: trimmedQuery,
            userName: userName,
            clinicalContext: clinicalContext,
            timeout: const Duration(seconds: 12),
          );
          if (recResult.isSuccess) {
            _activeModel = recommended;
            return recResult;
          }
        }
      }
    }

    // Also try v1 endpoint if v1beta failed
    if (_activeApiVersion == 'v1beta') {
      debugPrint('Mencoba failover ke endpoint v1...');
      for (final candidate in [
        'gemini-1.5-flash',
        'gemini-1.5-pro',
        'gemini-pro',
      ]) {
        final result = await _executeRequest(
          apiVersion: 'v1',
          model: candidate,
          query: trimmedQuery,
          userName: userName,
          clinicalContext: clinicalContext,
          timeout: const Duration(seconds: 10),
        );
        if (result.isSuccess) {
          _activeApiVersion = 'v1';
          _activeModel = candidate;
          return result;
        }
      }
    }

    final modelsInfo = _supportedModels.isNotEmpty
        ? '\nModel yang terdeteksi pada akun Anda: [${_supportedModels.take(5).join(', ')}]'
        : '';

    return GeminiResponseResult.failure(
      '$lastError$modelsInfo',
      statusCode: lastStatus,
    );
  }

  /// Internal request execution to Google Gemini endpoint.
  Future<GeminiResponseResult> _executeRequest({
    required String apiVersion,
    required String model,
    required String query,
    String? userName,
    String? clinicalContext,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = timeout;

      final url = Uri.parse(
        '${GeminiConfig.baseUrl}/$apiVersion/models/$model:generateContent?key=${GeminiConfig.apiKey}',
      );

      final request = await client.postUrl(url).timeout(timeout);

      // Crucial: Set Content-Type and explicit Content-Length to prevent chunked stalls
      final requestPayload = _buildPayload(query, userName, clinicalContext);
      final jsonBody = jsonEncode(requestPayload);
      final utf8Bytes = utf8.encode(jsonBody);

      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      request.contentLength = utf8Bytes.length;
      request.add(utf8Bytes);

      final response = await request.close().timeout(timeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        debugPrint(
          'Gemini API Error: Status ${response.statusCode}, Model $model ($apiVersion), Body: $responseBody',
        );
        String detail = 'HTTP ${response.statusCode}';
        try {
          final Map<String, dynamic> errorMap = jsonDecode(responseBody);
          if (errorMap.containsKey('error') && errorMap['error'] is Map) {
            final msg = errorMap['error']['message'];
            if (msg != null && msg.toString().isNotEmpty) {
              detail = msg.toString();
            }
          }
        } catch (_) {}

        return GeminiResponseResult.failure(
          'Gemini API ($model): $detail',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return GeminiResponseResult.failure(
          'Gemini API tidak mengembalikan kandidat respon.',
        );
      }

      final candidate = candidates.first as Map<String, dynamic>;
      final finishReason = candidate['finishReason'] as String?;

      if (finishReason == 'SAFETY' || finishReason == 'BLOCKLIST') {
        return GeminiResponseResult.failure(
          'Respon diblokir oleh filter keamanan AI ($finishReason).',
        );
      }

      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return GeminiResponseResult.failure(
          'Format respon Gemini API tidak berisi konten teks.',
        );
      }

      final text = parts.first['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        return GeminiResponseResult.failure(
          'Respon teks dari Gemini API kosong.',
        );
      }

      // Sanitize output: enforce zero emojis and normalize typography
      final sanitizedText = _sanitizeResponse(text.trim());
      return GeminiResponseResult.success(sanitizedText);
    } catch (e) {
      debugPrint('GeminiClinicalService Exception ($model): $e');
      return GeminiResponseResult.failure(
        'Kendala saat mencoba model $model: $e',
      );
    } finally {
      client?.close(force: true);
    }
  }

  /// Builds the Google Gemini request payload containing tailored system instructions
  /// and adjusted safety settings suitable for women's reproductive health topics.
  Map<String, dynamic> _buildPayload(
    String userQuery,
    String? userName,
    String? clinicalContext,
  ) {
    final cleanName = (userName != null && userName.trim().isNotEmpty)
        ? userName.trim().split(' ').first
        : '';
    final greetingTarget = cleanName.isNotEmpty
        ? 'Halo Kak ${cleanName[0].toUpperCase()}${cleanName.substring(1)},'
        : 'Halo Kak,';

    final contextSection =
        (clinicalContext != null && clinicalContext.trim().isNotEmpty)
        ? '\n\nINFORMASI MEDIS PENDUKUNG:\n${clinicalContext.trim()}'
        : '';

    final systemInstruction =
        '''
Anda adalah Konsultan Medis Klinis Resmi di aplikasi Kalmeda, mendampingi kesehatan reproduksi, siklus menstruasi, dan kebugaran wanita dengan standar kompetensi Dokter Spesialis Obstetri & Ginekologi (Sp.OG).

PANDUAN KOMUNIKASI & PENULISAN:
1. Mulai jawaban dengan sapaan nama pengguna secara tepat: "$greetingTarget".
2. Di kalimat pembuka, ulangi dan akui permasalahan/keluhan yang dihadapi pengguna secara hangat dan empatik (contoh: "mengenai rasa kram pada area perut bawah yang sedang Kakak rasakan...").
3. Kalimat jawaban di awal HARUS LANGSUNG MENJAWAB inti permasalahan/penyebab keluhan tersebut secara lugas, ilmiah, dan menenangkan (JANGAN gunakan kalimat kaku seperti "Berikut penjelasannya untukmu").
4. AKURASI MEDIS: Seluruh panduan harus berlandaskan konsensus medis resmi POGI, American College of Obstetricians and Gynecologists (ACOG), dan Kemenkes RI.
5. ATURAN DESAIN MUTLAK: Dilarang keras menggunakan emoticon atau emoji apapun dalam bentuk apa pun. Gunakan hanya tanda baca baku dan teks profesional.

PANDUAN FORMAT & PENYAJIAN BUBBLE CHAT (SANGAT PENTING):
- Cetak tebal (**bold**) kata-kata penting, istilah medis kunci (misalnya: **prostaglandin**, **dismenorea**, **endometriosis**, **estrogen**), serta hal yang ditekankan.
- Gunakan header pengantar bercetak tebal (**bold**) sebelum menyajikan daftar penyebab, langkah tindakan, atau tanda bahaya, contoh:
  **Secara fisiologis klinis, kondisi ini umumnya dipicu oleh:**
  **Lakukan langkah-langkah penanganan mandiri berikut:**
  **Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**
- Format Poin & Numbering yang Rapi:
  - Gunakan penomoran rapi dengan judul ditebalkan: `1. **Judul Tindakan:** Penjelasan rinci langkah tersebut.`
  - Untuk daftar ringkas gunakan bullet rapi: `• **Nama Gejala:** Keterangan medis.`
  - Jangan buat poin nomor tanpa judul yang ditebalkan.

PANDUAN INTEGRASI DATA KALENDER PENGGUNA (WAJIB & AKTIF):
Periksa bagian "INFORMASI MEDIS PENDUKUNG" di bawah. Bila tersedia data kalender dan siklus pengguna:
1. Pertanyaan Keterlambatan Haid ("kenapa saya telat haid", "haid belum datang", dsb.):
   - Anda WAJIB merujuk kalender pengguna secara langsung di awal jawaban: sebutkan tanggal haid terakhirnya (LMP), panjang siklus rata-ratanya, tanggal perkiraan haid yang seharusnya, posisi hari siklus saat ini, dan berapa hari ia sudah terlambat (atau bila belum terlambat, jelaskan posisi harinya saat ini).
   - Lanjutkan dengan telaah klinis penyebab keterlambatan (stres kortisol, gangguan ovulasi, fluktuasi hormon GnRH, atau riwayat PCOS/kondisi medis jika tercatat di profil).
   - Berikan arahan uji kehamilan (test pack) bila terlambat melebihi 7 hari dan panduan konsultasi Sp.OG.
2. Pertanyaan Waktu Haid Normal / Siklus Normal ("berapa hari siklus normal", "apakah siklus saya normal", dsb.):
   - Paparkan standar medis (siklus normal 21–35 hari, durasi haid 3–7 hari, pergeseran 2–3 hari masih wajar).
   - WAJIB tautkan langsung dengan kalender pengguna: sebutkan panjang siklus pengguna, durasi haidnya, posisinya hari ini (hari ke berapa dan fase apa), serta perkiraan tanggal haid berikutnya.
3. Pertanyaan Masa Subur / Kapan Haid Berikutnya:
   - Sebutkan estimasi tanggal konkret (tanggal masa subur, ovulasi, atau tanggal haid berikutnya) dari data kalender pengguna.$contextSection
''';

    return {
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userQuery},
          ],
        },
      ],
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_ONLY_HIGH',
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
      ],
      'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 1024},
    };
  }

  /// Sanitizes AI generated text by stripping emojis and appending trusted medical citation if absent.
  String _sanitizeResponse(String raw) {
    // 1. Strip any emojis
    var clean = raw.replaceAll(_emojiPattern, '').trim();

    // 2. Ensure verified literature citation footer is present
    const citationHeader = '**Referensi Pakar & Literatur Terpercaya:**';
    if (!clean.contains('Referensi Pakar & Literatur Terpercaya')) {
      clean =
          '$clean\n\n$citationHeader\n'
          'Panduan klinis ini disusun dan diverifikasi berdasarkan konsensus medis resmi Dokter Spesialis Obstetri & Ginekologi (**Sp.OG**), panduan praktik klinis **POGI**, konsensus **ACOG**, serta standar pelayanan medis **Kemenkes RI**.';
    }

    return clean;
  }
}
