import 'dart:typed_data';

import 'mp3_encoder.dart';

Future<Uint8List> encodeMp3Async(Float32List samples, int sampleRate) {
  return Future<Uint8List>.delayed(
    Duration.zero,
    () => Mp3Encoder.encode(samples, sampleRate: sampleRate),
  );
}
