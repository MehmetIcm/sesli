import 'dart:typed_data';

import '../domain/synthesis_result.dart';
import 'tts_engine_factory_stub.dart'
    if (dart.library.io) 'tts_engine_factory_native.dart'
    if (dart.library.js_interop) 'tts_engine_factory_web.dart'
    as engine_factory;

/// Tek bir seslendirme isteği.
class TtsSynthesisRequest {
  const TtsSynthesisRequest({
    required this.text,
    required this.referenceSamples,
    required this.referenceSampleRate,
    required this.speed,
    required this.numSteps,
    required this.normalizedText,
    required this.voiceId,
  });

  final String text;
  final Float32List referenceSamples;
  final int referenceSampleRate;
  final double speed;
  final int numSteps;
  final String normalizedText;
  final String voiceId;
}

/// Platformdan bağımsız seslendirme motoru sözleşmesi.
abstract class TtsEngine {
  /// Modeli yükler. Web'de WASM ve model dosyaları worker'a aktarılır;
  /// macOS'ta model dosyaları uygulama desteği klasörüne kopyalanır.
  Future<void> initialize({void Function(double progress)? onProgress});

  bool get isReady;

  int get sampleRate;

  /// Metni seslendirir. Aynı anda tek istek desteklenir.
  Future<SynthesisResult> synthesize(
    TtsSynthesisRequest request, {
    void Function(double progress)? onProgress,
  });

  Future<void> dispose();
}

/// Seçili platforma uygun motoru oluşturur.
TtsEngine createTtsEngine() => engine_factory.createTtsEngine();
