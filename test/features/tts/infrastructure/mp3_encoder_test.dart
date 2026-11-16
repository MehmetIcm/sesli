import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turkce_ses/features/tts/infrastructure/mp3_encoder.dart';

Float32List tone({int sampleRate = 24000, double seconds = 0.2}) {
  final length = (sampleRate * seconds).round();
  final samples = Float32List(length);
  for (var i = 0; i < length; i++) {
    samples[i] = math.sin(2 * math.pi * 440 * i / sampleRate) * 0.5;
  }
  return samples;
}

void main() {
  group('Mp3Encoder', () {
    test('gerçek MP3 çerçevesi üretir', () {
      final bytes = Mp3Encoder.encode(tone());

      expect(bytes.length, greaterThan(1000));
      // MPEG-1 Layer III çerçeve eşleşmesi: 11 bit senkron + sürüm/katman.
      final header = (bytes[0] << 8) | bytes[1];
      expect(header & 0xFFE0, 0xFFE0);
      expect((bytes[1] >> 1) & 0x03, isNot(0));
    });

    test('24 kHz girişi 48 kHz çıkışa yeniden örnekler', () {
      expect(Mp3Encoder.targetSampleRate, 48000);
      final bytes = Mp3Encoder.encode(tone(sampleRate: 24000, seconds: 1));
      // 160 kbps mono ≈ 20 kB/s; 1 saniyelik ses için makul aralık.
      expect(bytes.length, inInclusiveRange(16000, 28000));
    });

    test('boş ses verisini reddeder', () {
      expect(() => Mp3Encoder.encode(Float32List(0)), throwsArgumentError);
    });

    test('aynı giriş için tutarlı çıktı üretir', () {
      final samples = tone(seconds: 0.1);
      final first = Mp3Encoder.encode(samples);
      final second = Mp3Encoder.encode(samples);
      expect(first, second);
    });
  });
}
