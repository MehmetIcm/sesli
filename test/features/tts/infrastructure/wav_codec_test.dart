import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turkce_ses/features/tts/infrastructure/wav_codec.dart';

Uint8List buildWav({
  required List<int> samples,
  int channels = 1,
  int sampleRate = 24000,
  int bitsPerSample = 16,
  bool float = false,
}) {
  final bytesPerSample = bitsPerSample ~/ 8;
  final dataLength = samples.length * bytesPerSample;
  final byteData = ByteData(44 + dataLength);

  void writeAscii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      byteData.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  byteData.setUint32(4, 36 + dataLength, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, float ? 3 : 1, Endian.little);
  byteData.setUint16(22, channels, Endian.little);
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * channels * bytesPerSample, Endian.little);
  byteData.setUint16(32, channels * bytesPerSample, Endian.little);
  byteData.setUint16(34, bitsPerSample, Endian.little);
  writeAscii(36, 'data');
  byteData.setUint32(40, dataLength, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    final offset = 44 + i * bytesPerSample;
    if (float) {
      byteData.setFloat32(offset, samples[i] / 32768.0, Endian.little);
    } else if (bitsPerSample == 8) {
      byteData.setUint8(offset, samples[i] + 128);
    } else {
      byteData.setInt16(offset, samples[i], Endian.little);
    }
  }

  return byteData.buffer.asUint8List();
}

void main() {
  group('WavCodec', () {
    test('WAV imzasını tanır', () {
      final wav = buildWav(samples: [0, 1000]);
      expect(WavCodec.looksLikeWav(wav), isTrue);
      expect(WavCodec.looksLikeWav(Uint8List.fromList([1, 2, 3])), isFalse);
    });

    test('16-bit mono PCM çözer', () {
      final wav = buildWav(samples: [0, 16384, -32768]);
      final data = WavCodec.decode(wav);

      expect(data.sampleRate, 24000);
      expect(data.channels, 1);
      expect(data.bitsPerSample, 16);
      expect(data.samples.length, 3);
      expect(data.samples[0], closeTo(0, 0.0001));
      expect(data.samples[1], closeTo(0.5, 0.0001));
      expect(data.samples[2], closeTo(-1.0, 0.0001));
    });

    test('stereo kanalları mono ortalamaya indirger', () {
      final wav = buildWav(samples: [32767, 0, 16384, 16384], channels: 2);
      final data = WavCodec.decode(wav);

      expect(data.channels, 2);
      expect(data.samples.length, 2);
      expect(data.samples[0], closeTo(0.5, 0.001));
      expect(data.samples[1], closeTo(0.5, 0.001));
    });

    test('8-bit işaretsiz PCM çözer', () {
      final wav = buildWav(samples: [0, 64, -64], bitsPerSample: 8);
      final data = WavCodec.decode(wav);

      expect(data.samples.length, 3);
      expect(data.samples[0], closeTo(0, 0.001));
      expect(data.samples[1], closeTo(0.5, 0.01));
      expect(data.samples[2], closeTo(-0.5, 0.01));
    });

    test('32-bit float PCM çözer', () {
      final wav = buildWav(
        samples: [0, 16384, -16384],
        bitsPerSample: 32,
        float: true,
      );
      final data = WavCodec.decode(wav);

      expect(data.samples.length, 3);
      expect(data.samples[1], closeTo(0.5, 0.001));
      expect(data.samples[2], closeTo(-0.5, 0.001));
    });

    test('süreyi örnek sayısından hesaplar', () {
      final wav = buildWav(samples: List.filled(24000, 0));
      final data = WavCodec.decode(wav);
      expect(data.duration, const Duration(seconds: 1));
    });

    test('geçersiz veride anlaşılır hata verir', () {
      expect(
        () => WavCodec.decode(Uint8List.fromList(List.filled(20, 0))),
        throwsFormatException,
      );
    });

    test('float örnekleri 16-bit WAV olarak kodlar', () {
      final samples = Float32List.fromList([0, 0.5, -0.5]);
      final encoded = WavCodec.encode(samples, sampleRate: 44100);

      expect(WavCodec.looksLikeWav(encoded), isTrue);
      expect(encoded.length, 44 + samples.length * 2);

      final decoded = WavCodec.decode(encoded);
      expect(decoded.sampleRate, 44100);
      expect(decoded.channels, 1);
      expect(decoded.bitsPerSample, 16);
      expect(decoded.samples.length, 3);
      expect(decoded.samples[0], closeTo(0, 0.0001));
      expect(decoded.samples[1], closeTo(0.5, 0.0001));
      expect(decoded.samples[2], closeTo(-0.5, 0.0001));
    });

    test('kodlamada aralık dışı örnekleri kırpar', () {
      final samples = Float32List.fromList([2.0, -2.0]);
      final decoded = WavCodec.decode(
        WavCodec.encode(samples, sampleRate: 24000),
      );
      expect(decoded.samples[0], closeTo(1.0, 0.0001));
      expect(decoded.samples[1], closeTo(-1.0, 0.0001));
    });

    test('dither kapalıyken örnekleri tam nicemler', () {
      final samples = Float32List.fromList([0, 0.5, -0.5]);
      final decoded = WavCodec.decode(
        WavCodec.encode(samples, sampleRate: 24000, dither: false),
      );
      expect(decoded.samples[0], closeTo(0, 0.0001));
      expect(decoded.samples[1], closeTo(0.5, 0.0001));
      expect(decoded.samples[2], closeTo(-0.5, 0.0001));
    });

    test('TPDF dither sıfır sinyalde çok küçük gürültü üretir', () {
      final decoded = WavCodec.decode(
        WavCodec.encode(Float32List(256), sampleRate: 24000),
      );
      expect(decoded.samples.any((sample) => sample != 0), isTrue);
      expect(
        decoded.samples.every((sample) => sample.abs() <= 1 / 32767),
        isTrue,
      );
    });
  });
}
