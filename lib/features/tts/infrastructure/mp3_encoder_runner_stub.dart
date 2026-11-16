import 'dart:typed_data';

import 'mp3_encoder.dart';

Future<Uint8List> encodeMp3Async(Float32List samples, int sampleRate) async {
  return Mp3Encoder.encode(samples, sampleRate: sampleRate);
}
