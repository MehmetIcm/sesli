import 'dart:typed_data';

import 'mp3_encoder_runner_stub.dart'
    if (dart.library.io) 'mp3_encoder_runner_native.dart'
    if (dart.library.js_interop) 'mp3_encoder_runner_web.dart'
    as impl;

/// MP3 kodlamayı platforma göre yürütür.
///
/// macOS'ta ayrı bir isolate kullanılır; web'de kodlama ana iş parçacığında
/// kısa bir görev olarak çalışır.
Future<Uint8List> encodeMp3Async(Float32List samples, int sampleRate) {
  return impl.encodeMp3Async(samples, sampleRate);
}
