import 'dart:isolate';
import 'dart:typed_data';

import 'mp3_encoder.dart';

Future<Uint8List> encodeMp3Async(Float32List samples, int sampleRate) {
  return Isolate.run(
    () => Mp3Encoder.encode(samples, sampleRate: sampleRate),
    debugName: 'sesli-mp3',
  );
}
