import 'dart:typed_data';

import 'package:shine_dart/shine_dart.dart';

import 'audio_resampler.dart';

/// Gerçek MP3 (MPEG-1 Layer III) kodlayıcı.
///
/// Shine'ın saf Dart portunu kullanır. Model 24 kHz üretir; MP3 çıktısı
/// 48 kHz / 160 kbps mono olarak hazırlanır. 24 → 48 kHz tam 2× yükseltme
/// olduğu için tarayıcı ve cihazlarda ek yeniden örnekleme gerekmez.
class Mp3Encoder {
  Mp3Encoder._();

  static const int targetSampleRate = 48000;
  static const int defaultBitrate = 160;

  /// Mono float örneklerini MP3 baytlarına çevirir.
  static Uint8List encode(
    Float32List samples, {
    int sampleRate = 24000,
    int bitrate = defaultBitrate,
  }) {
    if (samples.isEmpty) {
      throw ArgumentError.value(samples, 'samples', 'Ses verisi boş.');
    }

    final resampled = AudioResampler.resample(
      samples,
      sampleRate,
      targetSampleRate,
    );

    final pcm = Int16List(resampled.length);
    for (var i = 0; i < resampled.length; i++) {
      final value = (resampled[i] * 32767.0).round();
      pcm[i] = value.clamp(-32768, 32767);
    }

    final config = ShineConfig(
      wave: ShineWave(channels: Channels.pcmMono, samplerate: targetSampleRate),
      mpeg: ShineMpeg(mode: StereoMode.mono, bitr: bitrate),
    );

    final encoder = shineInitialise(config);
    if (encoder == null) {
      throw StateError('MP3 kodlayıcı başlatılamadı.');
    }

    final output = BytesBuilder(copy: false);
    try {
      final samplesPerPass = shineSamplesPerPass(encoder);
      var offset = 0;

      while (offset + samplesPerPass <= pcm.length) {
        final chunk = Int16List.sublistView(
          pcm,
          offset,
          offset + samplesPerPass,
        );
        final result = shineEncodeBufferInterleaved(encoder, chunk);
        if (result.length > 0) {
          output.add(
            Uint8List.fromList(
              Uint8List.sublistView(result.buffer, 0, result.length),
            ),
          );
        }
        offset += samplesPerPass;
      }

      // Son kısa bloğu sıfırla tamamla; son hecenin kesilmesini önler.
      if (offset < pcm.length) {
        final tail = Int16List(samplesPerPass);
        tail.setRange(0, pcm.length - offset, pcm, offset);
        final result = shineEncodeBufferInterleaved(encoder, tail);
        if (result.length > 0) {
          output.add(
            Uint8List.fromList(
              Uint8List.sublistView(result.buffer, 0, result.length),
            ),
          );
        }
      }

      final flush = shineFlush(encoder);
      if (flush.length > 0) {
        output.add(
          Uint8List.fromList(
            Uint8List.sublistView(flush.buffer, 0, flush.length),
          ),
        );
      }
    } finally {
      shineClose(encoder);
    }

    return output.takeBytes();
  }
}
