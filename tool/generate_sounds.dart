import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final outDir = Directory('assets/sounds');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  const sampleRate = 44100;

  final sounds = <String, List<double>>{
    'mascot_pop.wav': generatePop(sampleRate),
    'mascot_boop.wav': generateBoop(sampleRate),
    'mascot_sparkle.wav': generateSparkle(sampleRate),
    'mascot_happy.wav': generateHappy(sampleRate),
    'mascot_giggle.wav': generateGiggle(sampleRate),
    'mascot_greeting.wav': generateGreeting(sampleRate),
    'mascot_swoop.wav': generateSwoop(sampleRate),
    'mascot_dizzy.wav': generateDizzy(sampleRate),
  };

  for (final entry in sounds.entries) {
    final wavBytes = createWav(entry.value, sampleRate: sampleRate);
    final file = File('${outDir.path}/${entry.key}');
    file.writeAsBytesSync(wavBytes);
    stdout.writeln('Generated: ${file.path} (${wavBytes.length} bytes)');
  }
}

List<double> generatePop(int sampleRate) {
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

List<double> generateBoop(int sampleRate) {
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

List<double> generateSparkle(int sampleRate) {
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

List<double> generateHappy(int sampleRate) {
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

List<double> generateGiggle(int sampleRate) {
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

List<double> generateGreeting(int sampleRate) {
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

List<double> generateSwoop(int sampleRate) {
  const durationSec = 0.32;
  final totalSamples = (sampleRate * durationSec).toInt();
  final samples = List<double>.filled(totalSamples, 0.0);

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    final progress = i / totalSamples;

    // Smooth frequency curve: starts 520Hz, rises to 1420Hz then soft decline to 780Hz
    final freq = 520.0 + (900.0 * math.sin(math.pi * progress));
    final env = math.sin(math.pi * progress) * (0.8 + 0.2 * math.sin(math.pi * progress));

    final wave = 0.8 * math.sin(2 * math.pi * freq * t) +
        0.2 * math.sin(4 * math.pi * freq * t);
    samples[i] = (wave * env * 0.70).clamp(-1.0, 1.0);
  }
  return samples;
}

List<double> generateDizzy(int sampleRate) {
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

Uint8List createWav(List<double> samples, {required int sampleRate}) {
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
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little); // PCM
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
