import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turkce_ses/features/tts/data/voice_catalog.dart';
import 'package:turkce_ses/features/tts/domain/voice_eq_profile.dart';
import 'package:turkce_ses/features/tts/infrastructure/audio_post_processor.dart';

const int sampleRate = 24000;

Float32List tone({
  double seconds = 0.5,
  double frequency = 440,
  double amplitude = 0.4,
  double leadingSilence = 0,
  double trailingSilence = 0,
}) {
  final lead = (sampleRate * leadingSilence).round();
  final body = (sampleRate * seconds).round();
  final tail = (sampleRate * trailingSilence).round();
  final samples = Float32List(lead + body + tail);
  for (var i = 0; i < body; i++) {
    samples[lead + i] =
        math.sin(2 * math.pi * frequency * i / sampleRate) * amplitude;
  }
  return samples;
}

double peakOf(Float32List samples) {
  var peak = 0.0;
  for (final value in samples) {
    final magnitude = value.abs();
    if (magnitude > peak) peak = magnitude;
  }
  return peak;
}

double meanOf(Float32List samples) {
  var sum = 0.0;
  for (final value in samples) {
    sum += value;
  }
  return sum / samples.length;
}

double rmsOf(Float32List samples) {
  var sum = 0.0;
  for (final value in samples) {
    sum += value * value;
  }
  return math.sqrt(sum / samples.length);
}

/// Goertzel ile tek bir frekansın genliğini ölçer.
double goertzelMagnitude(Float32List samples, double frequency) {
  final k = (samples.length * frequency / sampleRate).round();
  final omega = 2 * math.pi * k / samples.length;
  final coefficient = 2 * math.cos(omega);
  var s0 = 0.0;
  var s1 = 0.0;
  var s2 = 0.0;
  for (final sample in samples) {
    s0 = sample + coefficient * s1 - s2;
    s2 = s1;
    s1 = s0;
  }
  final real = s1 - s2 * math.cos(omega);
  final imaginary = s2 * math.sin(omega);
  return 2 * math.sqrt(real * real + imaginary * imaginary) / samples.length;
}

void main() {
  group('trimSilence', () {
    test('baş ve sondaki sessizliği kırpar', () {
      final input = tone(
        seconds: 0.2,
        leadingSilence: 0.1,
        trailingSilence: 0.1,
      );
      final output = AudioPostProcessor.trimSilence(
        input,
        sampleRate: sampleRate,
      );

      expect(output.length, lessThan(input.length));
      expect(output.length, greaterThan((sampleRate * 0.2).round()));
    });

    test('tamamen sessiz girdide boş dizi döner', () {
      final output = AudioPostProcessor.trimSilence(
        Float32List(1000),
        sampleRate: sampleRate,
      );
      expect(output, isEmpty);
    });
  });

  group('joinWithPauses', () {
    test('parçalar arasına duraklama ekler', () {
      final first = tone(seconds: 0.2, leadingSilence: 0.05);
      final second = tone(seconds: 0.2, frequency: 660);

      final output = AudioPostProcessor.joinWithPauses(
        [first, second],
        sampleRate: sampleRate,
        gapMs: 200,
        leadInMs: 50,
        tailMs: 100,
      );

      final trimmedFirst = AudioPostProcessor.trimSilence(
        first,
        sampleRate: sampleRate,
      ).length;
      final trimmedSecond = AudioPostProcessor.trimSilence(
        second,
        sampleRate: sampleRate,
      ).length;

      final expected =
          trimmedFirst +
          trimmedSecond +
          (sampleRate * 0.05).round() +
          (sampleRate * 0.1).round() +
          (sampleRate * 0.2).round();
      expect(output.length, expected);
    });

    test('boş parça listesinde boş dizi döner', () {
      expect(
        AudioPostProcessor.joinWithPauses(const [], sampleRate: sampleRate),
        isEmpty,
      );
    });

    test('parça başına farklı duraklama kullanır', () {
      final first = tone(seconds: 0.2);
      final second = tone(seconds: 0.2, frequency: 660);
      final third = tone(seconds: 0.2, frequency: 880);

      final output = AudioPostProcessor.joinWithPauses(
        [first, second, third],
        sampleRate: sampleRate,
        gapsMs: const [100, 400],
        leadInMs: 0,
        tailMs: 0,
      );

      final each = AudioPostProcessor.trimSilence(
        first,
        sampleRate: sampleRate,
      ).length;
      final expected =
          each * 3 + (sampleRate * 0.1).round() + (sampleRate * 0.4).round();
      expect(output.length, expected);
    });

    test('eksik duraklama listesinde varsayılana döner', () {
      final first = tone(seconds: 0.1);
      final second = tone(seconds: 0.1, frequency: 660);

      final output = AudioPostProcessor.joinWithPauses(
        [first, second],
        sampleRate: sampleRate,
        gapsMs: const [],
        gapMs: 250,
        leadInMs: 0,
        tailMs: 0,
      );

      final each = AudioPostProcessor.trimSilence(
        first,
        sampleRate: sampleRate,
      ).length;
      expect(output.length, each * 2 + (sampleRate * 0.25).round());
    });
  });

  group('enhance', () {
    test('uzunluğu korur ve hedef yüksekliğe normalize eder', () {
      final input = tone(seconds: 1.5, amplitude: 0.1);
      final output = AudioPostProcessor.enhance(input, sampleRate: sampleRate);

      expect(output.length, input.length);
      expect(
        AudioPostProcessor.integratedLufs(output, sampleRate),
        closeTo(-18, 1.0),
      );
      expect(AudioPostProcessor.truePeakDb(output), lessThanOrEqualTo(-1.4));
    });

    test('hedef yükseklik verilmezse tepe noktasını normalize eder', () {
      final input = tone(seconds: 0.5, amplitude: 0.1);
      final output = AudioPostProcessor.enhance(
        input,
        sampleRate: sampleRate,
        targetLufs: null,
      );

      expect(output.length, input.length);
      expect(peakOf(output), closeTo(0.91, 0.02));
    });

    test('DC bileşenini temizler', () {
      final input = Float32List.fromList(List<double>.filled(sampleRate, 0.2));
      final output = AudioPostProcessor.enhance(input, sampleRate: sampleRate);
      final middle = Float32List.fromList(
        output.sublist(1000, output.length - 1000),
      );
      expect(meanOf(middle).abs(), lessThan(0.01));
    });

    test('boş girdiyi olduğu gibi döndürür', () {
      final output = AudioPostProcessor.enhance(
        Float32List(0),
        sampleRate: sampleRate,
      );
      expect(output, isEmpty);
    });
  });

  group('normalizeLoudness', () {
    test('farklı genlikteki sesleri aynı yüksekliğe getirir', () {
      final quiet = AudioPostProcessor.normalizeLoudness(
        tone(seconds: 1.5, amplitude: 0.04),
        sampleRate: sampleRate,
      );
      final loud = AudioPostProcessor.normalizeLoudness(
        tone(seconds: 1.5, amplitude: 0.5),
        sampleRate: sampleRate,
      );

      final quietLufs = AudioPostProcessor.integratedLufs(quiet, sampleRate);
      final loudLufs = AudioPostProcessor.integratedLufs(loud, sampleRate);

      expect(quietLufs, closeTo(-20, 1.0));
      expect(loudLufs, closeTo(-20, 1.0));
      expect((quietLufs - loudLufs).abs(), lessThan(0.8));
    });

    test('gerçek tepeyi sınırın altında tutar', () {
      final input = tone(seconds: 1.5, amplitude: 0.95);
      final output = AudioPostProcessor.normalizeLoudness(
        input,
        sampleRate: sampleRate,
      );
      expect(AudioPostProcessor.truePeakDb(output), lessThanOrEqualTo(-1.4));
    });
  });

  group('limitTruePeak', () {
    test('tepe noktasını sınırlar ve uzunluğu korur', () {
      final input = tone(seconds: 0.5, amplitude: 0.9);
      input[input.length ~/ 2] = 2.5;
      final output = AudioPostProcessor.limitTruePeak(
        input,
        sampleRate: sampleRate,
      );

      expect(output.length, input.length);
      expect(AudioPostProcessor.truePeakDb(output), lessThanOrEqualTo(-1.4));
      expect(peakOf(output), lessThanOrEqualTo(1.0));
    });
  });

  group('ses bazlı EQ ve de-esser', () {
    test('de-esser yüksek bandı düşük banda göre azaltır', () {
      final length = (sampleRate * 0.8).round();
      final input = Float32List(length);
      for (var i = 0; i < length; i++) {
        input[i] =
            math.sin(2 * math.pi * 500 * i / sampleRate) * 0.25 +
            math.sin(2 * math.pi * 7000 * i / sampleRate) * 0.25;
      }

      final neutral = AudioPostProcessor.enhance(
        input,
        sampleRate: sampleRate,
        targetLufs: null,
        compressor: false,
      );
      final deessed = AudioPostProcessor.enhance(
        input,
        sampleRate: sampleRate,
        targetLufs: null,
        compressor: false,
        voiceEq: const VoiceEqProfile(deEsser: 1.0),
      );

      final neutralRatio =
          goertzelMagnitude(neutral, 7000) / goertzelMagnitude(neutral, 500);
      final deessedRatio =
          goertzelMagnitude(deessed, 7000) / goertzelMagnitude(deessed, 500);

      expect(deessedRatio, lessThan(neutralRatio * 0.9));
    });

    test('her ses için profil tanımlıdır', () {
      expect(VoiceCatalog.eqFor('female_1').deEsser, 0);
      expect(VoiceCatalog.eqFor('female_1').presenceDb, -1.5);
      // Yeni sentetik referanslar dengeli geldiği için ek EQ uygulanmaz.
      expect(VoiceCatalog.eqFor('female_2').isNeutral, isTrue);
      expect(VoiceCatalog.eqFor('female_3').isNeutral, isTrue);
      expect(VoiceCatalog.eqFor('male_1').isNeutral, isTrue);
      expect(VoiceCatalog.eqFor('male_2').presenceDb, 3.0);
      expect(VoiceCatalog.eqFor('male_2').lowShelfDb, -2.0);
      expect(VoiceCatalog.eqFor('male_3').lowShelfDb, -2.5);
      expect(VoiceCatalog.eqFor('bilinmeyen').isNeutral, isTrue);
    });
  });

  group('timeStretch', () {
    test('1,0× girdiyi kopyalar', () {
      final input = tone(seconds: 0.3);
      final output = AudioPostProcessor.timeStretch(
        input,
        1.0,
        sampleRate: sampleRate,
      );
      expect(output, input);
      expect(identical(output, input), isFalse);
    });

    test('1,25× daha kısa çıktı üretir', () {
      final input = tone(seconds: 1);
      final output = AudioPostProcessor.timeStretch(
        input,
        1.25,
        sampleRate: sampleRate,
      );
      expect(output.length, closeTo(input.length / 1.25, 2));
    });

    test('0,8× daha uzun çıktı üretir', () {
      final input = tone(seconds: 1);
      final output = AudioPostProcessor.timeStretch(
        input,
        0.8,
        sampleRate: sampleRate,
      );
      expect(output.length, closeTo(input.length / 0.8, 2));
    });

    test('perdeyi korur', () {
      const frequency = 440.0;
      final input = tone(seconds: 1, frequency: frequency);
      final output = AudioPostProcessor.timeStretch(
        input,
        1.25,
        sampleRate: sampleRate,
      );

      // Kenarlardaki geçişleri atlayarak sıfır geçişlerinden frekans kestir.
      final start = output.length ~/ 10;
      final end = output.length - start;
      var crossings = 0;
      for (var i = start + 1; i < end; i++) {
        if ((output[i - 1] < 0 && output[i] >= 0) ||
            (output[i - 1] >= 0 && output[i] < 0)) {
          crossings++;
        }
      }
      final seconds = (end - start) / sampleRate;
      final measured = crossings / 2 / seconds;
      expect(measured, closeTo(frequency, frequency * 0.05));
    });
  });
}
