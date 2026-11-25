import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turkce_ses/features/tts/infrastructure/audio_resampler.dart';

Float32List sine({
  required int sampleRate,
  required double seconds,
  double frequency = 440,
  double amplitude = 0.5,
}) {
  final length = (sampleRate * seconds).round();
  final samples = Float32List(length);
  for (var i = 0; i < length; i++) {
    samples[i] = math.sin(2 * math.pi * frequency * i / sampleRate) * amplitude;
  }
  return samples;
}

double rms(Float32List samples) {
  var sum = 0.0;
  for (final value in samples) {
    sum += value * value;
  }
  return math.sqrt(sum / samples.length);
}

/// Belirli bir frekanstaki sinüsün genliğini (tepe değeri) döndürür.
double toneAmplitude(Float32List samples, double frequency, int sampleRate) {
  var real = 0.0;
  var imaginary = 0.0;
  for (var i = 0; i < samples.length; i++) {
    final phase = 2 * math.pi * frequency * i / sampleRate;
    real += samples[i] * math.cos(phase);
    imaginary -= samples[i] * math.sin(phase);
  }
  return 2 * math.sqrt(real * real + imaginary * imaginary) / samples.length;
}

double toDb(double ratio) => 20 * math.log(ratio) / math.ln10;

void main() {
  group('AudioResampler', () {
    test('boş girdiyi reddeder', () {
      expect(AudioResampler.resample(Float32List(0), 24000, 44100), isEmpty);
    });

    test('aynı oranda girdiyi kopyalar', () {
      final input = sine(sampleRate: 24000, seconds: 0.1);
      final output = AudioResampler.resample(input, 24000, 24000);
      expect(output, input);
      expect(identical(output, input), isFalse);
    });

    test('24 kHz → 44,1 kHz uzunluğu doğru üretir', () {
      final input = sine(sampleRate: 24000, seconds: 1);
      final output = AudioResampler.resample(input, 24000, 44100);
      expect(output.length, inInclusiveRange(44099, 44101));
    });

    test('44,1 kHz → 24 kHz uzunluğu doğru üretir', () {
      final input = sine(sampleRate: 44100, seconds: 1);
      final output = AudioResampler.resample(input, 44100, 24000);
      expect(output.length, inInclusiveRange(23999, 24001));
    });

    test('yukarı örneklemede genliği korur', () {
      final input = sine(sampleRate: 24000, seconds: 1);
      final output = AudioResampler.resample(input, 24000, 44100);

      final inputRms = rms(input);
      final outputRms = rms(output);
      expect(outputRms, closeTo(inputRms, inputRms * 0.05));
    });

    test('DC bileşenini bozmaz', () {
      final input = Float32List.fromList(List<double>.filled(1000, 0.5));
      final output = AudioResampler.resample(input, 24000, 44100);
      final middle = output.sublist(200, output.length - 200);
      for (final value in middle) {
        expect(value, closeTo(0.5, 0.01));
      }
    });

    test('frekansı korur', () {
      const frequency = 1000.0;
      final input = sine(sampleRate: 24000, seconds: 0.5, frequency: frequency);
      final output = AudioResampler.resample(input, 24000, 44100);

      var crossings = 0;
      for (var i = 1; i < output.length; i++) {
        if ((output[i - 1] < 0 && output[i] >= 0) ||
            (output[i - 1] >= 0 && output[i] < 0)) {
          crossings++;
        }
      }
      final seconds = output.length / 44100;
      final measured = crossings / 2 / seconds;
      expect(measured, closeTo(frequency, frequency * 0.03));
    });

    test('6–10 kHz bölgesini düz korur', () {
      for (final frequency in [6000.0, 8000.0, 10000.0]) {
        final input = sine(
          sampleRate: 24000,
          seconds: 1,
          frequency: frequency,
        );
        final output = AudioResampler.resample(input, 24000, 48000);
        final middle = output.sublist(2400, output.length - 2400);
        final amplitude = toneAmplitude(middle, frequency, 48000);
        final gainDb = toDb(amplitude / 0.5);
        expect(
          gainDb,
          greaterThan(-1.0),
          reason: '$frequency Hz beklenenden fazla zayıfladı ($gainDb dB)',
        );
      }
    });

    test('yukarı örneklemede görüntüleri bastırır', () {
      const frequency = 6000.0;
      final input = sine(
        sampleRate: 24000,
        seconds: 1,
        frequency: frequency,
      );
      final output = AudioResampler.resample(input, 24000, 48000);
      final middle = output.sublist(2400, output.length - 2400);
      final pass = toneAmplitude(middle, frequency, 48000);
      final image = toneAmplitude(middle, 24000 - frequency, 48000);
      expect(toDb(image / pass), lessThan(-40));
    });
  });
}
