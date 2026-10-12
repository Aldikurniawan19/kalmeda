import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Structured result returned after voice note recording completes.
class VoiceRecordResult {
  final bool isSuccess;
  final String transcribedText;
  final String? base64Audio;
  final String mimeType;
  final int durationSeconds;
  final String? errorMessage;

  const VoiceRecordResult({
    required this.isSuccess,
    this.transcribedText = '',
    this.base64Audio,
    this.mimeType = 'audio/m4a',
    this.durationSeconds = 1,
    this.errorMessage,
  });

  factory VoiceRecordResult.success({
    String transcribedText = '',
    String? base64Audio,
    String mimeType = 'audio/m4a',
    required int durationSeconds,
  }) {
    return VoiceRecordResult(
      isSuccess: true,
      transcribedText: transcribedText,
      base64Audio: base64Audio,
      mimeType: mimeType,
      durationSeconds: durationSeconds,
    );
  }

  factory VoiceRecordResult.failure(String errorMessage) {
    return VoiceRecordResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// Unified Service managing real-time audio recording and amplitude monitoring for Kalmeda.
/// Captures high-fidelity AAC audio for Google Gemini Multimodal AI.
/// Adheres strictly to `aturan-desain.md` and `aturan-penulisan-code.md`.
class VoiceRecordingService {
  static final VoiceRecordingService _instance =
      VoiceRecordingService._internal();
  factory VoiceRecordingService() => _instance;

  VoiceRecordingService._internal();

  AudioRecorder? _audioRecorder;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  bool _isInitialized = false;
  bool _isRecording = false;
  String? _recordedFilePath;
  DateTime? _recordStartTime;

  /// Reactive notifier for real-time live transcript text or status.
  final ValueNotifier<String> liveTranscriptionNotifier =
      ValueNotifier<String>('');

  /// Reactive notifier for current audio input level (decibels / normalized amplitude 0.0 - 1.0).
  final ValueNotifier<double> soundLevelNotifier = ValueNotifier<double>(0.0);

  /// Returns true if currently recording audio.
  bool get isRecording => _isRecording;

  /// Initializes audio recorder and checks microphone permissions.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _audioRecorder ??= AudioRecorder();
      final hasPerm = await _audioRecorder!.hasPermission();
      _isInitialized = hasPerm;
      return hasPerm;
    } catch (e) {
      debugPrint('VoiceRecordingService initialization exception: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Starts high-fidelity audio file recording with real-time amplitude meter.
  Future<bool> startRecording() async {
    try {
      liveTranscriptionNotifier.value = '';
      soundLevelNotifier.value = 0.0;
      _recordStartTime = DateTime.now();
      _isRecording = true;

      _audioRecorder ??= AudioRecorder();
      final hasPermission = await _audioRecorder!.hasPermission();
      if (!hasPermission) {
        debugPrint('VoiceRecordingService: Izin mikrofon belum diberikan');
        _isRecording = false;
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordedFilePath = '${tempDir.path}/kalmeda_voice_$timestamp.m4a';

      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: _recordedFilePath!,
      );

      // Start real-time hardware microphone amplitude monitor (100ms interval)
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _audioRecorder!
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        // amp.current ranges from ~ -60 dB (silence) to 0 dB (peak)
        final raw = amp.current;
        final normalized = ((raw + 50.0) / 50.0).clamp(0.0, 1.0);
        soundLevelNotifier.value = normalized;
      });

      return true;
    } catch (e) {
      debugPrint('VoiceRecordingService startRecording error: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stops recording and returns the Base64 encoded audio payload.
  Future<VoiceRecordResult> stopRecording({bool isCancelled = false}) async {
    if (!_isRecording) {
      return VoiceRecordResult.failure('Perekaman belum dimulai.');
    }

    _isRecording = false;
    final duration = DateTime.now().difference(
      _recordStartTime ?? DateTime.now(),
    );
    final durationSeconds = duration.inSeconds > 0 ? duration.inSeconds : 1;

    // Stop amplitude monitoring
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    soundLevelNotifier.value = 0.0;

    // Stop audio recorder
    String? audioPath;
    try {
      if (_audioRecorder != null && await _audioRecorder!.isRecording()) {
        audioPath = await _audioRecorder!.stop();
      }
    } catch (e) {
      debugPrint('AudioRecorder stop error: $e');
    }

    if (isCancelled) {
      if (audioPath != null) {
        try {
          final file = File(audioPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      return VoiceRecordResult.failure('Perekaman dibatalkan oleh pengguna.');
    }

    // Read audio file bytes into Base64
    String? base64Audio;
    final targetPath = audioPath ?? _recordedFilePath;
    if (targetPath != null) {
      try {
        final audioFile = File(targetPath);
        if (await audioFile.exists()) {
          final bytes = await audioFile.readAsBytes();
          debugPrint('Voice file size: ${bytes.length} bytes at $targetPath');
          if (bytes.isNotEmpty) {
            base64Audio = base64Encode(bytes);
          }
          await audioFile.delete();
        }
      } catch (e) {
        debugPrint('Error reading audio file to base64: $e');
      }
    }

    if (base64Audio == null || base64Audio.isEmpty) {
      return VoiceRecordResult.failure(
        'File rekaman suara kosong atau tidak ditemukan.',
      );
    }

    return VoiceRecordResult.success(
      transcribedText: '',
      base64Audio: base64Audio,
      mimeType: 'audio/m4a',
      durationSeconds: durationSeconds,
    );
  }

  /// Cancels recording and cleans up temporary resources.
  Future<void> cancelRecording() async {
    await stopRecording(isCancelled: true);
  }

  /// Disposes recorder resources.
  void dispose() {
    _amplitudeSubscription?.cancel();
    _audioRecorder?.dispose();
    _audioRecorder = null;
    _isInitialized = false;
    _isRecording = false;
  }
}

