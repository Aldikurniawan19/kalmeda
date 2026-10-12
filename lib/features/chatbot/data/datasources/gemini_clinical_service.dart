import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:menstracker/features/chatbot/data/datasources/gemini_config.dart';
import 'package:menstracker/features/chatbot/data/models/chat_message_model.dart';

/// Structured response result for Google Gemini API calls.
class GeminiResponseResult {
  final bool isSuccess;
  final String? text;
  final List<String> relatedQuestions;
  final String? errorMessage;
  final int? statusCode;

  const GeminiResponseResult({
    required this.isSuccess,
    this.text,
    this.relatedQuestions = const [],
    this.errorMessage,
    this.statusCode,
  });

  factory GeminiResponseResult.success(
    String text, {
    List<String> relatedQuestions = const [],
  }) {
    return GeminiResponseResult(
      isSuccess: true,
      text: text,
      relatedQuestions: relatedQuestions,
    );
  }

  factory GeminiResponseResult.failure(String errorMessage, {int? statusCode}) {
    return GeminiResponseResult(
      isSuccess: false,
      errorMessage: errorMessage,
      statusCode: statusCode,
    );
  }
}

/// Structured response result for Voice Note multimodal audio analysis.
class GeminiVoiceResponseResult {
  final bool isSuccess;
  final String transcript;
  final String responseText;
  final List<String> relatedQuestions;
  final String? errorMessage;
  final int? statusCode;

  const GeminiVoiceResponseResult({
    required this.isSuccess,
    this.transcript = '',
    this.responseText = '',
    this.relatedQuestions = const [],
    this.errorMessage,
    this.statusCode,
  });

  factory GeminiVoiceResponseResult.success({
    required String transcript,
    required String responseText,
    List<String> relatedQuestions = const [],
  }) {
    return GeminiVoiceResponseResult(
      isSuccess: true,
      transcript: transcript,
      responseText: responseText,
      relatedQuestions: relatedQuestions,
    );
  }

  factory GeminiVoiceResponseResult.failure(
    String errorMessage, {
    int? statusCode,
  }) {
    return GeminiVoiceResponseResult(
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
    List<ChatMessageModel>? conversationHistory,
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
        conversationHistory: conversationHistory,
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
            conversationHistory: conversationHistory,
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
          conversationHistory: conversationHistory,
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

  /// Generates a clinical consultation response from an audio voice note via Google Gemini REST API.
  Future<GeminiVoiceResponseResult> generateVoiceResponse({
    required String base64Audio,
    required String mimeType,
    List<ChatMessageModel>? conversationHistory,
    String? speechHint,
    String? userName,
    String? clinicalContext,
  }) async {
    if (!GeminiConfig.isConfigured) {
      return GeminiVoiceResponseResult.failure(
        'Kunci API Gemini belum dikonfigurasi. Harap masukkan API key di gemini_config.dart.',
      );
    }

    if (base64Audio.trim().isEmpty) {
      return GeminiVoiceResponseResult.failure(
        'Rekaman audio tidak boleh kosong.',
      );
    }

    // Discover supported models if not yet discovered
    if (!_hasDiscoveredModel || _supportedModels.isEmpty) {
      await discoverSupportedModels();
    }

    // Prioritized list of audio-capable Gemini models
    final candidateModels = <String>[];
    const preferredAudioModels = [
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-2.0-flash-exp',
      'gemini-1.5-flash-latest',
      'gemini-1.5-pro',
      'gemini-2.5-flash',
    ];

    for (final p in preferredAudioModels) {
      if (!candidateModels.contains(p)) candidateModels.add(p);
    }

    for (final s in _supportedModels) {
      if (!candidateModels.contains(s) &&
          (s.contains('flash') || s.contains('pro'))) {
        candidateModels.add(s);
      }
    }

    String lastError = 'Tidak ada model Gemini yang merespons audio';
    int? lastStatus;

    for (final candidate in candidateModels) {
      final result = await _executeVoiceRequest(
        apiVersion: _activeApiVersion,
        model: candidate,
        base64Audio: base64Audio,
        mimeType: mimeType,
        conversationHistory: conversationHistory,
        speechHint: speechHint,
        userName: userName,
        clinicalContext: clinicalContext,
        timeout: const Duration(seconds: 18),
      );

      if (result.isSuccess && result.responseText.trim().isNotEmpty) {
        _activeModel = candidate;
        return result;
      }

      lastError = result.errorMessage ?? lastError;
      lastStatus = result.statusCode;
    }

    return GeminiVoiceResponseResult.failure(
      lastError,
      statusCode: lastStatus,
    );
  }

  /// Internal request execution for Voice Note audio payloads.
  Future<GeminiVoiceResponseResult> _executeVoiceRequest({
    required String apiVersion,
    required String model,
    required String base64Audio,
    required String mimeType,
    List<ChatMessageModel>? conversationHistory,
    String? speechHint,
    String? userName,
    String? clinicalContext,
    Duration timeout = const Duration(seconds: 18),
  }) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = timeout;

      final url = Uri.parse(
        '${GeminiConfig.baseUrl}/$apiVersion/models/$model:generateContent?key=${GeminiConfig.apiKey}',
      );

      final request = await client.postUrl(url).timeout(timeout);

      final requestPayload = _buildVoicePayload(
        base64Audio,
        mimeType,
        conversationHistory: conversationHistory,
        speechHint: speechHint,
        userName: userName,
        clinicalContext: clinicalContext,
      );
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
        return GeminiVoiceResponseResult.failure(
          'HTTP ${response.statusCode}: $responseBody',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> jsonMap = jsonDecode(responseBody);
      final candidates = jsonMap['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return GeminiVoiceResponseResult.failure(
          'Tidak ada kandidat jawaban dari Gemini.',
        );
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final rawText = parts?[0]['text'] as String?;

      if (rawText == null || rawText.trim().isEmpty) {
        return GeminiVoiceResponseResult.failure(
          'Respon teks kosong dari Gemini.',
        );
      }

      // Try parsing JSON block if Gemini returned structured JSON
      String transcript = speechHint?.trim().isNotEmpty == true
          ? speechHint!.trim()
          : 'Pesan Suara Konsultasi';
      String clinicalReply = rawText;
      List<String> relatedQuestions = [];

      try {
        final cleanJson = rawText
            .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
            .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
            .trim();
        final parsedMap = jsonDecode(cleanJson);
        if (parsedMap is Map) {
          if (parsedMap['transkrip'] != null &&
              parsedMap['transkrip'].toString().trim().isNotEmpty) {
            transcript = parsedMap['transkrip'].toString().trim();
          }
          if (parsedMap['jawaban_klinis'] != null &&
              parsedMap['jawaban_klinis'].toString().trim().isNotEmpty) {
            clinicalReply = parsedMap['jawaban_klinis'].toString().trim();
          }
          if (parsedMap['pertanyaan_terkait'] is List) {
            relatedQuestions = (parsedMap['pertanyaan_terkait'] as List)
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        }
      } catch (_) {
        final splitMatch = RegExp(
          r'(?:Transkrip|TRANSKRIP):\s*(.*?)\n+(?:Jawaban|JAWABAN|Respon):\s*(.*)',
          dotAll: true,
        ).firstMatch(rawText);
        if (splitMatch != null) {
          transcript = splitMatch.group(1)?.trim() ?? transcript;
          clinicalReply = splitMatch.group(2)?.trim() ?? rawText;
        }
      }

      final sanitizedReply = _sanitizeResponse(clinicalReply.trim());
      return GeminiVoiceResponseResult.success(
        transcript: transcript,
        responseText: sanitizedReply,
        relatedQuestions: relatedQuestions,
      );
    } catch (e) {
      return GeminiVoiceResponseResult.failure(
        'Kendala memproses pesan suara: $e',
      );
    } finally {
      client?.close(force: true);
    }
  }

  /// Builds the Google Gemini multimodal audio request payload
  /// Builds the Google Gemini multimodal audio request payload
  Map<String, dynamic> _buildVoicePayload(
    String base64Audio,
    String mimeType, {
    List<ChatMessageModel>? conversationHistory,
    String? speechHint,
    String? userName,
    String? clinicalContext,
  }) {
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

    final hintSection = (speechHint != null && speechHint.trim().isNotEmpty)
        ? '\n\nPETUNJUK REKAMAN UCAPAN DARI PERANGKAT: "${speechHint.trim()}" (Gunakan audio untuk memastikan transkripsi verbatim yang persis sama dengan apa yang diucapkan).'
        : '';

    final systemInstruction =
        '''
Anda adalah Konsultan Medis Klinis Resmi di aplikasi Kalmeda, mendampingi kesehatan reproduksi, siklus menstruasi, dan kebugaran wanita dengan standar kompetensi Dokter Spesialis Obstetri & Ginekologi (Sp.OG).

PANDUAN PEMROSESAN PESAN SUARA & TRANSKRIPSI VERBATIM:
1. TRANSKRIPSI PERSIS SAMA (VERBATIM):
   - Dengarkan rekaman suara pengguna dengan seksama.
   - Tuliskan kata demi kata apa yang diucapkan pengguna dalam Bahasa Indonesia secara PERSIS SAMA (VERBATIM) pada field "transkrip".
   - DILARANG merangkum, DILARANG menyederhanakan, DILARANG mengubah gaya kalimat, dan DILARANG mengarang. Tampilkan persis kalimat atau pertanyaan yang diucapkan pengguna.
   - Jika audio hening, tidak ada kata yang terucap, atau hanya bunyi desah/noise tanpa kalimat bermakna, isi field "transkrip" dengan: "Suara tidak terdengar jelas".

2. EVALUASI KONTEKS TOPIK & PERCAKAPAN BERANTAI:
   - Sesi konsultasi ini mendukung percakapan berantai (multi-turn). Jika pengguna menanyakan pertanyaan lanjutan yang merujuk pada pesan sebelumnya (contoh: "apakah itu aman?", "kenapa begitu?", "apa solusinya?"), hubungkan secara langsung kata rujukan ("itu", "kondisi tadi") dengan keluhan/topik kesehatan yang sedang dibahas sebelumnya.
   - JIKA PERTANYAAN DI LUAR KESEHATAN REPRODUKSI WANITA (misalnya: topik otomotif, game, matematika, coding/teknologi, politik, gosip, resep makanan umum di luar nutrisi haid, lelucon/cerita acak):
     * JANGAN MEMAKSAKAN JAWABAN MEDIS ATAU MENGHUBUNG-HUBUNGKAN SECARA TIDAK MASUK AKAL.
     * Jawab di field "jawaban_klinis" dengan bahasa yang sangat natural, ramah, sopan, dan hangat bahwa peran Anda di Kalmeda khusus membantu konsultasi seputar kesehatan reproduksi wanita dan siklus menstruasi.
     * Contoh respon:
       "$greetingTarget terima kasih atas pertanyaannya. Sebagai konsultan klinis Kalmeda, fokus utama saya adalah membantu konsultasi seputar kesehatan reproduksi wanita, siklus menstruasi, masa subur, kehamilan, dan keluhan kewanitaan. Pertanyaan yang Kakak sampaikan tampaknya di luar ruang lingkup kesehatan kewanitaan. Apakah ada keluhan atau pertanyaan terkait siklus haid atau kesehatan tubuh yang ingin Kakak tanyakan?"
   - JIKA PERTANYAAN SEPUTAR KESEHATAN REPRODUKSI WANITA:
     * Berikan penjelasan klinis medis yang empatik, ilmiah, terstruktur, menenangkan, dan berstandar Sp.OG, POGI, ACOG, dan Kemenkes RI.
     * Awali dengan sapaan: "$greetingTarget".
     * Ikuti susunan 6 Bagian Wajib:
       - Bagian 1 (Sapaan & Penjelasan Biologis Langsung): DITULIS SEBAGAI PARAGRAF DESKRIPSI TANPA POIN.
       - Bagian 2 (Data Kalender Kesehatan): DITULIS SEBAGAI PARAGRAF DESKRIPSI TANPA POIN.
       - Bagian 3 (Langkah Penanganan Mandiri): Diawali header tebal `**Secara fisiologis klinis, langkah-langkah penanganan mandiri berikut dapat membantu meredakan [keluhan]:**` diikuti POIN NOMOR (1. **Judul:** Isi).
       - Bagian 4 (Tanda-tanda Bahaya): Diawali header tebal `**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**` diikuti POIN BULLET (• **Judul:** Isi).
       - Bagian 5 (Evaluasi Lanjutan & Pantauan Kalender): DITULIS SEBAGAI PARAGRAF DESKRIPSI TANPA POIN.
       - Bagian 6 (Referensi Pakar): Header `**Referensi Pakar & Literatur Terpercaya:**` diikuti paragraf referensi Sp.OG, ACOG, POGI, Kemenkes RI.

4. PANDUAN REKOMENDASI PERTANYAAN TERKAIT (DARI SUDUT PANDANG PENGGUNA):
   - Buat 3 sampai 4 butir rekomendasi pertanyaan lanjutan ("pertanyaan_terkait") yang DAPAT DITANYAKAN OLEH PENGGUNA KEPADA KONSULTAN MEDIS selanjutnya.
   - PENTING: Pertanyaan ini BUKAN pertanyaan chatbot kepada pengguna. Format pertanyaan WAJIB dari sudut pandang PENGGUNA yang bertanya kepada DOKTER / KONSULTAN MEDIS.
   - Pertanyaan harus singkat, padat, relevan secara klinis, dan tanpa nomor/bullet.

5. FORMAT OUTPUT WAJIB JSON:
{
  "transkrip": "<kalimat persis yang diucapkan pengguna kata demi kata>",
  "jawaban_klinis": "<jawaban konsultasi medis lengkap dan terstruktur rapi dengan markdown>",
  "pertanyaan_terkait": [
    "<pertanyaan dari sudut pandang pengguna 1>",
    "<pertanyaan dari sudut pandang pengguna 2>",
    "<pertanyaan dari sudut pandang pengguna 3>"
  ]
}$contextSection$hintSection
''';

    return {
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': _buildMultiTurnVoiceContents(
        base64Audio,
        mimeType,
        conversationHistory: conversationHistory,
        speechHint: speechHint,
      ),
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
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 1500,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'transkrip': {
              'type': 'STRING',
              'description':
                  'Transkripsi kata demi kata apa yang diucapkan pengguna secara persis sama (verbatim).',
            },
            'jawaban_klinis': {
              'type': 'STRING',
              'description':
                  'Jawaban konsultasi medis lengkap atau respon sopan keluar konteks jika di luar topik.',
            },
            'pertanyaan_terkait': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
              'description':
                  '3-4 pertanyaan lanjutan/terkait yang sangat kontekstual dan spesifik dengan topik.',
            },
          },
          'required': ['transkrip', 'jawaban_klinis', 'pertanyaan_terkait'],
        },
      },
    };
  }

  /// Internal request execution to Google Gemini endpoint.
  Future<GeminiResponseResult> _executeRequest({
    required String apiVersion,
    required String model,
    required String query,
    List<ChatMessageModel>? conversationHistory,
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
      final requestPayload = _buildPayload(
        query,
        conversationHistory: conversationHistory,
        userName: userName,
        clinicalContext: clinicalContext,
      );
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

      String clinicalReply = text.trim();
      List<String> relatedQuestions = [];

      // Extract Pertanyaan Terkait section if present at the end of the text
      final relatedMatch = RegExp(
        r'\n*\*{0,2}Pertanyaan Terkait:?\*{0,2}\s*\n+([\s\S]+)$',
        caseSensitive: false,
      ).firstMatch(clinicalReply);

      if (relatedMatch != null) {
        final block = relatedMatch.group(1)!;
        final lines = block
            .split('\n')
            .map(
              (l) => l
                  .replaceFirst(RegExp(r'^\s*(?:\d+[\.\)]|[•\-\*])\s*'), '')
                  .trim(),
            )
            .where((l) => l.isNotEmpty && l.length > 5)
            .toList();
        if (lines.isNotEmpty) {
          relatedQuestions = lines;
        }
        clinicalReply = clinicalReply.substring(0, relatedMatch.start).trim();
      } else {
        // Also support JSON parse if any model returned JSON format
        try {
          final cleanJson = clinicalReply
              .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
              .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
              .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
              .trim();
          final parsed = jsonDecode(cleanJson);
          if (parsed is Map) {
            if (parsed['jawaban_klinis'] != null &&
                parsed['jawaban_klinis'].toString().trim().isNotEmpty) {
              clinicalReply = parsed['jawaban_klinis'].toString().trim();
            }
            if (parsed['pertanyaan_terkait'] is List) {
              relatedQuestions = (parsed['pertanyaan_terkait'] as List)
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
          }
        } catch (_) {}
      }

      // Sanitize output: enforce zero emojis and normalize typography
      final sanitizedText = _sanitizeResponse(clinicalReply.trim());
      return GeminiResponseResult.success(
        sanitizedText,
        relatedQuestions: relatedQuestions,
      );
    } catch (e) {
      debugPrint('GeminiClinicalService Exception ($model): $e');
      return GeminiResponseResult.failure(
        'Kendala saat mencoba model $model: $e',
      );
    } finally {
      client?.close(force: true);
    }
  }

  /// Builds the Google Gemini request payload containing tailored system instructions,
  /// multi-turn conversation history chaining, and adjusted safety settings suitable for women's reproductive health topics.
  Map<String, dynamic> _buildPayload(
    String userQuery, {
    List<ChatMessageModel>? conversationHistory,
    String? userName,
    String? clinicalContext,
  }) {
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
2. Di kalimat pembuka, ulangi dan akui permasalahan/keluhan yang dihadapi pengguna secara hangat dan empatik.
3. Kalimat jawaban di awal HARUS LANGSUNG MENJAWAB inti permasalahan/penyebab keluhan tersebut secara ilmiah, lugas, dan menenangkan.
4. AKURASI MEDIS: Seluruh panduan harus berlandaskan konsensus medis resmi POGI, American College of Obstetricians and Gynecologists (ACOG), dan Kemenkes RI.
5. ATURAN DESAIN MUTLAK: Dilarang keras menggunakan emoticon atau emoji apapun dalam bentuk apa pun. Gunakan hanya tanda baca baku dan teks profesional.

PANDUAN PERCAKAPAN BERANTAI & PERTANYAAN LANJUTAN (MULTI-TURN / FOLLOW-UP):
- Sesi konsultasi ini mendukung percakapan berantai secara berkelanjutan. Pengguna dapat menanyakan pertanyaan lanjutan yang singkat, padat, atau menggunakan kata rujukan (contoh: "apakah itu aman?", "kenapa bisa begitu?", "apa bahayanya?", "bagaimana solusinya?", "apakah boleh minum obat?").
- Pahami bahwa kata rujukan ("itu", "hal tersebut", "kondisi tadi", "keluhan ini") merujuk secara langsung pada topik medis / keluhan siklus haid yang sedang dibahas pada pesan-pesan sebelumnya dalam percakapan ini.
- Pada pertanyaan lanjutan (follow-up):
  * JANGAN mengulang sapaan formal pembuka yang kaku atau mengenalkan diri dari awal seolah-olah baru pertama kali bertemu. Sapa secara natural atau langsung fokus menjawab inti pertanyaan lanjutan tersebut.
  * Hubungkan penjelasan medis secara langsung dengan topik/keluhan sebelumnya (misalnya: jika sebelumnya membahas telat haid karena stres, maka 'apakah itu aman?' dijawab dengan analisis medis mendalam apakah keterlambatan haid karena stres tersebut aman atau berbahaya, batasan waktu toleransinya, dan kapan harus waspada).
  * Pertahankan penjelasan yang terstruktur, tenang, solutif, dan berbasis konsensus medis resmi (Sp.OG, POGI, ACOG).

ATURAN FORMAT PENYAJIAN (SANGAT KETAT):
- Bagian 1, Bagian 2, Bagian 5, dan Bagian 6 WAJIB ditulis sebagai PARAGRAF DESKRIPSI YANG MENGALIR (FLUID PARAGRAPH). DILARANG KERAS MEMBUAT POIN-POIN ATAU BULLET PADA BAGIAN-BAGIAN TERSEBUT.
- HANYA Bagian 3 yang menggunakan Poin Nomor (1. **Judul:** Isi).
- HANYA Bagian 4 yang menggunakan Poin Bullet (• **Judul:** Isi).
- Judul Header Bagian 3, Bagian 4, dan Bagian 6 WAJIB dicetak tebal dengan format `**Judul Header:**`.

PANDUAN BATASAN TOPIK & RESPON JIKA KELUAR DARI KONTEKS:
- Jika pertanyaan pengguna berada di LUAR RUANG LINGKUP kesehatan reproduksi wanita (misalnya: otomotif, komputer, politik, dsb.) DAN tidak berkaitan dengan pesan sebelumnya:
  * Sampaikan secara natural, ramah, dan sopan bahwa Anda di Kalmeda fokus mendampingi kesehatan reproduksi dan siklus menstruasi wanita, lalu ajak pengguna untuk bertanya seputar topik siklus haid atau keluhan kewanitaan yang sedang dirasakan.
  * Tetap gunakan sapaan "$greetingTarget" dan nada bersahabat.

TEMPLATE STRUKTUR JAWABAN KLINIS WAJIB (6 BAGIAN TERSTRUKTUR):
Setiap jawaban konsultasi medis WAJIB mengikuti susunan 6 bagian berikut secara konsisten dan rapi:

Bagian 1 - Sapaan & Penjelasan Biologis Langsung (PARAGRAF DESKRIPSI TANPA POIN):
$greetingTarget mengenai [akui keluhan yang sedang dirasakan], kondisi ini umumnya merupakan manifestasi dari [penjelasan fisiologis/biologis langsung] yang dipicu oleh [mekanisme/zat kimia tubuh, cetak tebal istilah kunci seperti **prostaglandin**].

Bagian 2 - Integrasi Data Kalender Siklus (PARAGRAF DESKRIPSI TANPA POIN):
(Bila tersedia data kalender di INFORMASI MEDIS PENDUKUNG):
Berdasarkan data kalender kesehatan Kakak, saat ini Kakak berada di hari ke-[X] dari siklus [Y] hari, yang berarti Kakak sedang berada di **[fase siklus]** menuju periode menstruasi berikutnya pada [Tanggal perkiraan]. [Korelasi klinis keluhan dengan fase tersebut] akibat fluktuasi hormon **progesteron** dan **estrogen** yang [efek fisiologis].

Bagian 3 - Langkah Penanganan Mandiri (POIN NOMOR):
**Secara fisiologis klinis, langkah-langkah penanganan mandiri berikut dapat membantu meredakan [keluhan]:**
1. **[Judul Tindakan 1]:** [Penjelasan tindakan mandiri praktis dan rasional klinisnya].
2. **[Judul Tindakan 2]:** [Penjelasan tindakan mandiri praktis dan rasional klinisnya].
3. **[Judul Tindakan 3]:** [Penjelasan tindakan mandiri praktis dan rasional klinisnya].

Bagian 4 - Tanda-tanda Bahaya (POIN BULLET):
**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**
• **[Judul Gejala Bahaya 1]:** [Deskripsi kapan harus waspada/periksa].
• **[Judul Gejala Bahaya 2]:** [Deskripsi kapan harus waspada/periksa].
• **[Judul Gejala Bahaya 3]:** [Deskripsi kapan harus waspada/periksa].

Bagian 5 - Evaluasi Lanjutan & Pantauan Kalender (PARAGRAF DESKRIPSI TANPA POIN):
Jika [keluhan] yang Kakak alami terasa semakin memberat di siklus-siklus berikutnya, hal ini perlu dievaluasi lebih lanjut untuk menyingkirkan kemungkinan adanya **[kondisi klinis sekunder, misal dismenorea sekunder / endometriosis / PCOS]**. Tetap pantau siklus Kakak melalui aplikasi Kalmeda hingga tanggal perkiraan haid [Tanggal perkiraan haid] mendatang.

Bagian 6 - Referensi Pakar & Literatur Terpercaya:
**Referensi Pakar & Literatur Terpercaya:**
Panduan klinis ini disusun dan diverifikasi berdasarkan konsensus medis resmi Dokter Spesialis Obstetri & Ginekologi (**Sp.OG**), American College of Obstetricians and Gynecologists (**ACOG**), Perkumpulan Obstetri dan Ginekologi Indonesia (**POGI**), dan Standar Pelayanan Medis Kemenkes RI.

PANDUAN REKOMENDASI PERTANYAAN TERKAIT (DI AKHIR JAWABAN):
Di bagian paling akhir setelah Bagian 6, sediakan 3 hingga 4 butir rekomendasi pertanyaan yang BISA DITANYAKAN PENGGUNA KEPADA KONSULTAN MEDIS selanjutnya (BUKAN pertanyaan bot ke pengguna, WAJIB format pertanyaan dari sudut pandang pengguna):
**Pertanyaan Terkait:**
• <Pertanyaan dari sudut pandang pengguna 1, contoh: "Bagaimana cara meredakan kram perut tanpa obat?">
• <Pertanyaan dari sudut pandang pengguna 2, contoh: "Kenapa darah haid berwarna hitam atau gelap?">
• <Pertanyaan dari sudut pandang pengguna 3, contoh: "Kapan kram haid perlu diperiksa ke dokter?">$contextSection
''';

    return {
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': _buildMultiTurnContents(
        userQuery,
        conversationHistory: conversationHistory,
      ),
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
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 1500,
      },
    };
  }

  /// Builds Gemini multi-turn 'contents' array preserving alternating user and model turns.
  List<Map<String, dynamic>> _buildMultiTurnContents(
    String currentQuery, {
    List<ChatMessageModel>? conversationHistory,
  }) {
    final contents = <Map<String, dynamic>>[];

    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final validTurns = conversationHistory.where((msg) {
        if (msg.id == 'welcome_msg') return false;
        final clean = _sanitizeHistoryText(msg.text);
        return clean.isNotEmpty;
      }).toList();

      // Keep the last 8 messages for rich context depth within reasonable token usage
      final recentTurns = validTurns.length > 8
          ? validTurns.sublist(validTurns.length - 8)
          : validTurns;

      for (final turn in recentTurns) {
        final role = turn.isUser ? 'user' : 'model';
        final text = _sanitizeHistoryText(turn.text);

        if (contents.isNotEmpty && contents.last['role'] == role) {
          final parts = contents.last['parts'] as List<dynamic>;
          parts.add({'text': text});
        } else {
          contents.add({
            'role': role,
            'parts': [
              {'text': text},
            ],
          });
        }
      }
    }

    // Gemini API requires the conversation contents to start with a 'user' role
    while (contents.isNotEmpty && contents.first['role'] != 'user') {
      contents.removeAt(0);
    }

    // Append the current turn
    if (contents.isNotEmpty && contents.last['role'] == 'user') {
      final parts = contents.last['parts'] as List<dynamic>;
      parts.add({'text': currentQuery});
    } else {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': currentQuery},
        ],
      });
    }

    return contents;
  }

  /// Builds Gemini multi-turn 'contents' array with audio data in the final user turn.
  List<Map<String, dynamic>> _buildMultiTurnVoiceContents(
    String base64Audio,
    String mimeType, {
    List<ChatMessageModel>? conversationHistory,
    String? speechHint,
  }) {
    final contents = <Map<String, dynamic>>[];

    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final validTurns = conversationHistory.where((msg) {
        if (msg.id == 'welcome_msg') return false;
        final clean = _sanitizeHistoryText(msg.text);
        return clean.isNotEmpty;
      }).toList();

      final recentTurns = validTurns.length > 8
          ? validTurns.sublist(validTurns.length - 8)
          : validTurns;

      for (final turn in recentTurns) {
        final role = turn.isUser ? 'user' : 'model';
        final text = _sanitizeHistoryText(turn.text);

        if (contents.isNotEmpty && contents.last['role'] == role) {
          final parts = contents.last['parts'] as List<dynamic>;
          parts.add({'text': text});
        } else {
          contents.add({
            'role': role,
            'parts': [
              {'text': text},
            ],
          });
        }
      }
    }

    while (contents.isNotEmpty && contents.first['role'] != 'user') {
      contents.removeAt(0);
    }

    final promptText = speechHint != null && speechHint.trim().isNotEmpty
        ? 'Dengarkan rekaman suara pengguna: "${speechHint.trim()}". Berikan konsultasi medis yang kontekstual dan transkrip verbatim.'
        : 'Dengarkan rekaman suara pengguna di atas. Transkripsikan kalimat secara persis ke field "transkrip" dan berikan konsultasi medis klinis pada "jawaban_klinis".';

    contents.add({
      'role': 'user',
      'parts': [
        {
          'inlineData': {
            'mimeType': mimeType,
            'data': base64Audio,
          },
        },
        {
          'text': promptText,
        },
      ],
    });

    return contents;
  }

  /// Cleans history text for API context payloads, stripping chips and trailing question blocks.
  String _sanitizeHistoryText(String text) {
    var clean = text.replaceAll(_emojiPattern, '').trim();
    clean = clean.replaceAll(
      RegExp(
        r'\n*\*{0,2}Pertanyaan Terkait:?\*{0,2}[\s\S]*$',
        caseSensitive: false,
      ),
      '',
    ).trim();
    return clean;
  }

  /// Sanitizes AI generated text by stripping emojis and extracting trailing related questions.
  String _sanitizeResponse(String raw) {
    // 1. Normalize escaped newlines
    var clean = raw.replaceAll(r'\n', '\n');

    // 2. Strip any emojis
    clean = clean.replaceAll(_emojiPattern, '').trim();

    // 3. Strip any trailing Pertanyaan Terkait text block (rendered separately as chips)
    clean = clean.replaceAll(
      RegExp(
        r'\n*\*{0,2}Pertanyaan Terkait:?\*{0,2}[\s\S]*$',
        caseSensitive: false,
      ),
      '',
    ).trim();

    return clean;
  }
}
