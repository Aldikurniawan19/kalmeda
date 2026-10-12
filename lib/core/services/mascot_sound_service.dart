import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available cute sound effect types for mascot reactions and animations.
enum MascotSoundType {
  pop,
  boop,
  sparkle,
  happy,
  giggle,
  greeting,
  swoop,
  dizzy,
}

/// Sound event emitted whenever a sound is played for synchronized component visual reactions.
class MascotSoundEvent {
  final MascotSoundType type;
  final Duration duration;
  final DateTime timestamp;

  const MascotSoundEvent({
    required this.type,
    required this.duration,
    required this.timestamp,
  });
}

/// Robust Service managing cute sound effects, asset playback, file cache fallback,
/// dynamic procedural audio synthesis, and synchronous haptic feedback for all mascot interactions.
class MascotSoundService {
  static final MascotSoundService _instance = MascotSoundService._internal();
  factory MascotSoundService() => _instance;

  MascotSoundService._internal() {
    _initAudioContext();
    _initAudioPlayers();
    _loadPreference();
    _prepareSoundCache();
  }

  static const String _prefSoundEnabledKey = 'kalmeda_mascot_sound_enabled';

  // Multi-channel player pool for zero-clipping simultaneous playback
  static const int _poolSize = 4;
  final List<AudioPlayer> _playerPool = [];
  int _currentPlayerIndex = 0;

  bool _isSoundEnabled = true;
  bool _isInitialized = false;

  final StreamController<MascotSoundEvent> _soundEventController =
      StreamController<MascotSoundEvent>.broadcast();
  Stream<MascotSoundEvent> get soundEvents => _soundEventController.stream;

  final Map<MascotSoundType, Uint8List> _soundBytesCache = {};
  final Map<MascotSoundType, String> _diskFileCache = {};
  final math.Random _random = math.Random();

  bool get isSoundEnabled => _isSoundEnabled;

  /// Global audio routing and stream configuration for Android & iOS.
  Future<void> _initAudioContext() async {
    try {
      AudioCache.instance.prefix = 'assets/';
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.defaultToSpeaker,
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('MascotSoundService AudioContext initialization note: $e');
    }
  }

  void _initAudioPlayers() {
    try {
      _playerPool.clear();
      for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer(playerId: 'mascot_sound_channel_$i');
        player.setPlayerMode(PlayerMode.mediaPlayer);
        player.setReleaseMode(ReleaseMode.stop);
        player.setVolume(1.0);
        _playerPool.add(player);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing MascotSoundService AudioPlayers: $e');
      _isInitialized = false;
    }
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool(_prefSoundEnabledKey) ?? true;
    } catch (_) {
      _isSoundEnabled = true;
    }
  }

  /// Toggles mascot sound effects on or off.
  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefSoundEnabledKey, enabled);
    } catch (_) {}
  }

  /// Asynchronously caches synthesized WAV files to disk as a 100% resilient fallback.
  Future<void> _prepareSoundCache() async {
    for (final type in MascotSoundType.values) {
      final fileName = _getAssetFileName(type);
      try {
        final data = await rootBundle.load('assets/sounds/$fileName');
        _soundBytesCache[type] = data.buffer.asUint8List();
      } catch (_) {
        _soundBytesCache[type] = _generateSoundBytes(type);
      }
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/mascot_sounds');
      if (!cacheDir.existsSync()) {
        await cacheDir.create(recursive: true);
      }

      for (final entry in _soundBytesCache.entries) {
        final fileName = _getAssetFileName(entry.key);
        final file = File('${cacheDir.path}/$fileName');
        if (!file.existsSync() || file.lengthSync() != entry.value.length) {
          await file.writeAsBytes(entry.value, flush: true);
        }
        _diskFileCache[entry.key] = file.path;
      }
    } catch (e) {
      debugPrint('MascotSoundService disk cache preparation note: $e');
    }
  }

  String _getAssetFileName(MascotSoundType type) {
    switch (type) {
      case MascotSoundType.pop:
        return 'mascot_pop.wav';
      case MascotSoundType.boop:
        return 'mascot_boop.wav';
      case MascotSoundType.sparkle:
        return 'mascot_sparkle.wav';
      case MascotSoundType.happy:
        return 'mascot_happy.wav';
      case MascotSoundType.giggle:
        return 'mascot_giggle.wav';
      case MascotSoundType.greeting:
        return 'mascot_greeting.wav';
      case MascotSoundType.swoop:
        return 'mascot_swoop.wav';
      case MascotSoundType.dizzy:
        return 'mascot_dizzy.wav';
    }
  }

  /// Exact acoustic duration for each sound effect to ensure perfect animation synchronization.
  Duration getSoundDuration(MascotSoundType type) {
    switch (type) {
      case MascotSoundType.pop:
        return const Duration(milliseconds: 140);
      case MascotSoundType.boop:
        return const Duration(milliseconds: 300);
      case MascotSoundType.sparkle:
        return const Duration(milliseconds: 380);
      case MascotSoundType.happy:
        return const Duration(milliseconds: 440);
      case MascotSoundType.giggle:
        return const Duration(milliseconds: 320);
      case MascotSoundType.greeting:
        return const Duration(milliseconds: 400);
      case MascotSoundType.swoop:
        return const Duration(milliseconds: 350);
      case MascotSoundType.dizzy:
        return const Duration(milliseconds: 480);
    }
  }

  /// Plays a specific cute mascot sound effect with high-fidelity,
  /// 5-tier fallback cascade (Disk File -> Asset -> Full Asset Path -> Memory Bytes -> System Click),
  /// and tactile haptics.
  Future<void> playSound(MascotSoundType type) async {
    // 1. Tactile haptic feedback synchronized with sound effect
    try {
      switch (type) {
        case MascotSoundType.pop:
        case MascotSoundType.boop:
          HapticFeedback.lightImpact();
          break;
        case MascotSoundType.sparkle:
        case MascotSoundType.greeting:
        case MascotSoundType.happy:
          HapticFeedback.mediumImpact();
          break;
        case MascotSoundType.giggle:
        case MascotSoundType.swoop:
        case MascotSoundType.dizzy:
          HapticFeedback.selectionClick();
          break;
      }
    } catch (_) {}

    // 2. Broadcast sound event for smooth, synchronized component visual reaction
    _soundEventController.add(
      MascotSoundEvent(
        type: type,
        duration: getSoundDuration(type),
        timestamp: DateTime.now(),
      ),
    );

    if (!_isSoundEnabled) return;

    if (!_isInitialized || _playerPool.isEmpty) {
      _initAudioPlayers();
    }

    if (_playerPool.isEmpty) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
      return;
    }

    // Pick next available player from pool for smooth multi-shot audio
    final player = _playerPool[_currentPlayerIndex];
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _playerPool.length;

    final fileName = _getAssetFileName(type);

    // Tier 1: DeviceFileSource from local application storage (fastest on SoundPool)
    try {
      final diskPath = _diskFileCache[type];
      if (diskPath != null && File(diskPath).existsSync()) {
        await player.stop();
        await player.play(
          DeviceFileSource(diskPath),
          volume: 1.0,
        );
        return;
      }
    } catch (diskError) {
      debugPrint('MascotSoundService Tier 1 (DeviceFileSource) note: $diskError');
    }

    // Tier 2: AssetSource with standard audio player
    try {
      await player.stop();
      await player.play(
        AssetSource('sounds/$fileName'),
        volume: 1.0,
      );
      return;
    } catch (assetError) {
      debugPrint('MascotSoundService Tier 2 (AssetSource sounds/) note: $assetError');
    }

    // Tier 3: AssetSource with explicit assets/ prefix
    try {
      await player.stop();
      await player.play(
        AssetSource('assets/sounds/$fileName'),
        volume: 1.0,
      );
      return;
    } catch (assetError2) {
      debugPrint('MascotSoundService Tier 3 (AssetSource assets/sounds/) note: $assetError2');
    }

    // Tier 4: BytesSource in-memory playback with explicit WAV mimeType
    try {
      final bytes = _soundBytesCache[type] ?? _generateSoundBytes(type);
      await player.stop();
      await player.play(
        BytesSource(bytes, mimeType: 'audio/wav'),
        volume: 1.0,
      );
      return;
    } catch (bytesError) {
      debugPrint('MascotSoundService Tier 4 (BytesSource) error: $bytesError');
    }

    // Tier 5: Emergency system click sound
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Plays a random cute sound from the collection (great for general mascot taps).
  Future<void> playRandomCuteSound() async {
    const types = [
      MascotSoundType.pop,
      MascotSoundType.boop,
      MascotSoundType.sparkle,
      MascotSoundType.happy,
      MascotSoundType.giggle,
    ];
    final selected = types[_random.nextInt(types.length)];
    await playSound(selected);
  }

  // Convenience helper methods
  Future<void> playPop() => playSound(MascotSoundType.pop);
  Future<void> playBoop() => playSound(MascotSoundType.boop);
  Future<void> playSparkle() => playSound(MascotSoundType.sparkle);
  Future<void> playHappy() => playSound(MascotSoundType.happy);
  Future<void> playGiggle() => playSound(MascotSoundType.giggle);
  Future<void> playGreeting() => playSound(MascotSoundType.greeting);
  Future<void> playSwoop() => playSound(MascotSoundType.swoop);
  Future<void> playDizzy() => playSound(MascotSoundType.dizzy);

  Uint8List _generateSoundBytes(MascotSoundType type) {
    const sampleRate = 44100;
    List<double> samples;

    switch (type) {
      case MascotSoundType.pop:
        samples = _generatePopSamples(sampleRate);
        break;
      case MascotSoundType.boop:
        samples = _generateBoopSamples(sampleRate);
        break;
      case MascotSoundType.sparkle:
        samples = _generateSparkleSamples(sampleRate);
        break;
      case MascotSoundType.happy:
        samples = _generateHappySamples(sampleRate);
        break;
      case MascotSoundType.giggle:
        samples = _generateGiggleSamples(sampleRate);
        break;
      case MascotSoundType.greeting:
        samples = _generateGreetingSamples(sampleRate);
        break;
      case MascotSoundType.swoop:
        samples = _generateSwoopSamples(sampleRate);
        break;
      case MascotSoundType.dizzy:
        samples = _generateDizzySamples(sampleRate);
        break;
    }

    return _createWavHeaderAndPcm(samples, sampleRate: sampleRate);
  }

  /// Generates a cute bubble "Pop!" sound.
  List<double> _generatePopSamples(int sampleRate) {
    const durationSec = 0.12;
    final totalSamples = (sampleRate * durationSec).toInt();
    final samples = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final freq = 440.0 + (680.0 * math.pow(progress, 0.65));
      final env = (progress < 0.06)
          ? (progress / 0.06)
          : math.exp(-7.5 * (progress - 0.06));

      final wave = 0.85 * math.sin(2 * math.pi * freq * t) +
          0.15 * math.sin(4 * math.pi * freq * t);
      samples[i] = (wave * env).clamp(-1.0, 1.0);
    }
    return samples;
  }

  /// Generates a cute bouncy & chewy "Boop!" jelly/mochi sound (Suara kenyal).
  List<double> _generateBoopSamples(int sampleRate) {
    const durationSec = 0.30;
    final totalSamples = (sampleRate * durationSec).toInt();
    final samples = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      // Chewy elastic pitch envelope (upward spring then gentle settling)
      final freq = 460.0 + (340.0 * math.sin(math.pi * math.pow(progress, 0.65)));
      final attack = (progress < 0.04) ? (progress / 0.04) : 1.0;
      final decay = math.exp(-4.5 * progress);
      final env = attack * decay * (1.0 - progress);

      final wave = 0.86 * math.sin(2 * math.pi * freq * t) +
          0.14 * math.sin(4 * math.pi * freq * t);
      samples[i] = (wave * env * 0.90).clamp(-1.0, 1.0);
    }
    return samples;
  }

  /// Generates a magical "Sparkle / Twinkle" sound.
  List<double> _generateSparkleSamples(int sampleRate) {
    const durationSec = 0.36;
    final totalSamples = (sampleRate * durationSec).toInt();
    final samples = List<double>.filled(totalSamples, 0.0);

    const freqs = [1567.98, 2093.00, 2637.02, 3135.96]; // G6, C7, E7, G7
    const delays = [0.0, 0.06, 0.12, 0.18];

    for (int k = 0; k < freqs.length; k++) {
      final f = freqs[k];
      final delay = delays[k];
      final startIdx = (delay * sampleRate).toInt();

      for (int i = startIdx; i < totalSamples; i++) {
        final localT = (i - startIdx) / sampleRate;
        final env = math.exp(-9.5 * localT);
        final chime = math.sin(2 * math.pi * f * localT) +
            0.25 * math.sin(4 * math.pi * f * localT) +
            0.1 * math.sin(6 * math.pi * f * localT);

        samples[i] += (chime * env * 0.32);
      }
    }
    return samples.map((s) => s.clamp(-1.0, 1.0)).toList();
  }

  /// Generates a joyful "Happy" melody (C6 -> E6 -> G6 -> C7).
  List<double> _generateHappySamples(int sampleRate) {
    const durationSec = 0.42;
    final totalSamples = (sampleRate * durationSec).toInt();
    final samples = List<double>.filled(totalSamples, 0.0);

    const notes = [1046.50, 1318.51, 1567.98, 2093.00]; // C6, E6, G6, C7
    const noteDuration = 0.09;

    for (int k = 0; k < notes.length; k++) {
      final f = notes[k];
      final startT = k * noteDuration;
      final startIdx = (startT * sampleRate).toInt();
      final endIdx = math.min(totalSamples, ((startT + 0.18) * sampleRate).toInt());

      for (int i = startIdx; i < endIdx; i++) {
        final localT = (i - startIdx) / sampleRate;
        final env = math.sin(math.pi * (localT / 0.18)) * math.exp(-4.5 * localT);
        final wave = 0.8 * math.sin(2 * math.pi * f * localT) +
            0.2 * math.sin(4 * math.pi * f * localT);

        samples[i] += (wave * env * 0.38);
      }
    }
    return samples.map((s) => s.clamp(-1.0, 1.0)).toList();
  }

  /// Generates a playful "Giggle" sound.
  List<double> _generateGiggleSamples(int sampleRate) {
    const durationSec = 0.30;
    final totalSamples = (sampleRate * durationSec).toInt();
    final samples = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final pulse = math.sin(3 * 2 * math.pi * progress).abs();
      final freq = 800.0 + (320.0 * math.sin(2 * math.pi * 8.0 * t));
      final env = pulse * math.exp(-2.2 * progress);

      final wave = math.sin(2 * math.pi * freq * t);
      samples[i] = (wave * env * 0.65).clamp(-1.0, 1.0);
    }
    return samples;
  }

  /// Generates a welcoming "Greeting" sound (F6 -> A6 -> C7).
  List<double> _generateGreetingSamples(int sampleRate) {
    const durationSec = 0.38;
    final totalSamples = (sampleRate * durationSec).toInt();
    final samples = List<double>.filled(totalSamples, 0.0);

    const freqs = [1396.91, 1760.00, 2093.00]; // F6, A6, C7
    const delays = [0.0, 0.10, 0.20];

    for (int k = 0; k < freqs.length; k++) {
      final f = freqs[k];
      final delay = delays[k];
      final startIdx = (delay * sampleRate).toInt();

      for (int i = startIdx; i < totalSamples; i++) {
        final localT = (i - startIdx) / sampleRate;
        final env = math.exp(-7.0 * localT);
        final chime = 0.85 * math.sin(2 * math.pi * f * localT) +
            0.15 * math.sin(4 * math.pi * f * localT);

        samples[i] += (chime * env * 0.35);
      }
    }
    return samples.map((s) => s.clamp(-1.0, 1.0)).toList();
  }

  /// Generates an aerodynamic "Swoop" flight sound.
  List<double> _generateSwoopSamples(int sampleRate) {
    const durationSec = 0.32;
    final totalSamples = (sampleRate * durationSec).toInt();
    final samples = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final freq = 520.0 + (900.0 * math.sin(math.pi * progress));
      final env = math.sin(math.pi * progress) *
          (0.8 + 0.2 * math.sin(math.pi * progress));

      final wave = 0.8 * math.sin(2 * math.pi * freq * t) +
          0.2 * math.sin(4 * math.pi * freq * t);
      samples[i] = (wave * env * 0.70).clamp(-1.0, 1.0);
    }
    return samples;
  }

  /// Generates a cute cartoon "Dizzy / Pusing" sound with wobbly spiral pitch modulation and star chimes.
  List<double> _generateDizzySamples(int sampleRate) {
    const durationSec = 0.48;
    final totalSamples = (sampleRate * durationSec).toInt();
    final samples = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final baseFreq = 720.0 - (240.0 * progress);
      final wobble = 160.0 * math.sin(2 * math.pi * 18.0 * t);
      final freq = baseFreq + wobble;

      final env = math.sin(math.pi * math.pow(progress, 0.6)) *
          math.exp(-1.8 * progress);
      final wave = 0.75 * math.sin(2 * math.pi * freq * t) +
          0.25 * math.sin(4 * math.pi * freq * t);

      final sparkleChime = (math.sin(2 * math.pi * 2400.0 * t) * 0.15) *
          math.pow(math.sin(2 * math.pi * 6.0 * t).abs(), 4);

      samples[i] = ((wave + sparkleChime) * env * 0.68).clamp(-1.0, 1.0);
    }
    return samples;
  }

  /// Encodes normalized float samples into a valid 16-bit PCM RIFF/WAVE header and byte array.
  Uint8List _createWavHeaderAndPcm(List<double> samples, {required int sampleRate}) {
    final numSamples = samples.length;
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    const blockAlign = numChannels * (bitsPerSample ~/ 8);
    final dataSize = numSamples * (bitsPerSample ~/ 8);
    final chunkSize = 36 + dataSize;

    final byteData = ByteData(44 + dataSize);

    // "RIFF"
    byteData.setUint8(0, 0x52);
    byteData.setUint8(1, 0x49);
    byteData.setUint8(2, 0x46);
    byteData.setUint8(3, 0x46);
    byteData.setUint32(4, chunkSize, Endian.little);

    // "WAVE"
    byteData.setUint8(8, 0x57);
    byteData.setUint8(9, 0x41);
    byteData.setUint8(10, 0x56);
    byteData.setUint8(11, 0x45);

    // "fmt "
    byteData.setUint8(12, 0x66);
    byteData.setUint8(13, 0x6D);
    byteData.setUint8(14, 0x74);
    byteData.setUint8(15, 0x20);
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, byteRate, Endian.little);
    byteData.setUint16(32, blockAlign, Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // "data"
    byteData.setUint8(36, 0x64);
    byteData.setUint8(37, 0x61);
    byteData.setUint8(38, 0x74);
    byteData.setUint8(39, 0x61);
    byteData.setUint32(40, dataSize, Endian.little);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final int16 = (samples[i].clamp(-1.0, 1.0) * 32767).toInt();
      byteData.setInt16(offset, int16, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}
