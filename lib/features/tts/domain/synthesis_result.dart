import 'dart:typed_data';

import 'speech_emotion.dart';

/// Bir seslendirme isteğinin sonucu.
class SynthesisResult {
  SynthesisResult({
    required this.samples,
    required this.sampleRate,
    required this.elapsed,
    required this.text,
    required this.normalizedText,
    required this.voiceId,
    this.emotion = SpeechEmotion.neutral,
  });

  /// Mono PCM örnekleri, [-1, 1] aralığında.
  final Float32List samples;
  final int sampleRate;

  /// Modelin sesi üretmesi için geçen süre.
  final Duration elapsed;

  /// Kullanıcının yazdığı özgün metin.
  final String text;

  /// Modele gönderilen normalize edilmiş metin (duygu etiketi hariç).
  final String normalizedText;

  final String voiceId;
  final SpeechEmotion emotion;

  Duration get duration => Duration(
    microseconds: sampleRate == 0
        ? 0
        : (samples.length / sampleRate * 1000000).round(),
  );

  bool get isEmpty => samples.isEmpty;
}
