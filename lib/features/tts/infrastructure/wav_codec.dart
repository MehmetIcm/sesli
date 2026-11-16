import 'dart:math' as math;
import 'dart:typed_data';

/// Basit, bağımlılıksız WAV çözücü.
///
/// Uygulamada yalnızca 16-bit PCM referans kayıtları kullanılsa da, farklı
/// WAV biçimlerinin ileride eklenebilmesi için 8/16/24/32-bit PCM ve 32-bit
/// float desteği bulunur. Çok kanallı dosyalar mono'ya indirgenir.
class WavCodec {
  WavCodec._();

  static bool looksLikeWav(Uint8List bytes) {
    if (bytes.length < 12) return false;
    return String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE';
  }

  /// Mono float örneklerini 16-bit PCM WAV baytlarına çevirir.
  ///
  /// Oynatma için kullanılır; MP3 kodlamasından önceki ara adımda yeniden
  /// örneklenmiş sesi kayıpsız olarak çalar.
  ///
  /// [dither] açıkken TPDF (üçgen) dither eklenir. 16-bit kuantizasyonda
  /// çok düşük seviyeli bozulmayı maskeler; sabit tohum sayesinde aynı
  /// girdi her zaman aynı çıktıyı üretir.
  static Uint8List encode(
    Float32List samples, {
    required int sampleRate,
    bool dither = true,
  }) {
    final noise = math.Random(0x5EED);
    final dataLength = samples.length * 2;
    final bytes = Uint8List(44 + dataLength);
    final data = ByteData.sublistView(bytes);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes[offset + i] = value.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    data.setUint32(4, 36 + dataLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    data.setUint32(40, dataLength, Endian.little);

    var offset = 44;
    for (final sample in samples) {
      final scaled = sample.clamp(-1.0, 1.0) * 32767.0;
      final ditherValue = dither
          ? noise.nextDouble() - noise.nextDouble()
          : 0.0;
      final value = (scaled + ditherValue).round().clamp(-32768, 32767);
      data.setInt16(offset, value, Endian.little);
      offset += 2;
    }
    return bytes;
  }

  /// WAV baytlarını mono float örneklerine çözer.
  static WavData decode(Uint8List bytes) {
    if (!looksLikeWav(bytes)) {
      throw const FormatException('Geçerli bir WAV dosyası değil.');
    }

    final data = ByteData.sublistView(bytes);
    var offset = 12;
    int? format;
    int? channels;
    int? sampleRate;
    int? bitsPerSample;
    int? blockAlign;
    int? dataOffset;
    int? dataLength;

    while (offset + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final size = data.getUint32(offset + 4, Endian.little);
      final chunkStart = offset + 8;

      if (id == 'fmt ') {
        format = data.getUint16(chunkStart, Endian.little);
        channels = data.getUint16(chunkStart + 2, Endian.little);
        sampleRate = data.getUint32(chunkStart + 4, Endian.little);
        blockAlign = data.getUint16(chunkStart + 12, Endian.little);
        bitsPerSample = data.getUint16(chunkStart + 14, Endian.little);
      } else if (id == 'data') {
        dataOffset = chunkStart;
        dataLength = math.min(size, bytes.length - chunkStart);
      }

      offset = chunkStart + size + (size.isOdd ? 1 : 0);
      if (dataOffset != null && format != null) break;
    }

    if (format == null ||
        channels == null ||
        sampleRate == null ||
        bitsPerSample == null ||
        dataOffset == null ||
        dataLength == null) {
      throw const FormatException('WAV başlığı eksik veya bozuk.');
    }

    final isFloat = format == 3;
    if (format != 1 && !isFloat) {
      throw FormatException('Desteklenmeyen WAV kodlaması: $format');
    }

    final bytesPerSample = bitsPerSample ~/ 8;
    if (bytesPerSample < 1 || bytesPerSample > 4) {
      throw FormatException('Desteklenmeyen örnek boyutu: $bitsPerSample bit');
    }

    final frameCount =
        dataLength ~/ (blockAlign ?? (bytesPerSample * channels));
    final samples = Float32List(frameCount);

    for (var frame = 0; frame < frameCount; frame++) {
      var sum = 0.0;
      final frameStart = dataOffset + frame * (blockAlign ?? 0);
      for (var channel = 0; channel < channels; channel++) {
        final sampleOffset = frameStart + channel * bytesPerSample;
        if (sampleOffset + bytesPerSample > bytes.length) break;
        sum += _readSample(data, sampleOffset, bitsPerSample, isFloat);
      }
      samples[frame] = (sum / channels).clamp(-1.0, 1.0);
    }

    return WavData(
      samples: samples,
      sampleRate: sampleRate,
      channels: channels,
      bitsPerSample: bitsPerSample,
    );
  }

  static double _readSample(
    ByteData data,
    int offset,
    int bitsPerSample,
    bool isFloat,
  ) {
    if (isFloat && bitsPerSample == 32) {
      return data.getFloat32(offset, Endian.little);
    }
    switch (bitsPerSample) {
      case 8:
        // 8-bit WAV işaretsizdir; 128 merkez kabul edilir.
        return (data.getUint8(offset) - 128) / 128.0;
      case 16:
        return data.getInt16(offset, Endian.little) / 32768.0;
      case 24:
        var value =
            data.getUint8(offset) |
            (data.getUint8(offset + 1) << 8) |
            (data.getUint8(offset + 2) << 16);
        if (value & 0x800000 != 0) value |= ~0xFFFFFF;
        return value / 8388608.0;
      case 32:
        return data.getInt32(offset, Endian.little) / 2147483648.0;
      default:
        return 0.0;
    }
  }
}

class WavData {
  const WavData({
    required this.samples,
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
  });

  final Float32List samples;
  final int sampleRate;
  final int channels;
  final int bitsPerSample;

  Duration get duration => Duration(
    microseconds: sampleRate == 0
        ? 0
        : (samples.length / sampleRate * 1000000).round(),
  );
}
