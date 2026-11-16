import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:turkce_ses/features/tts/domain/synthesis_result.dart';
import 'package:turkce_ses/features/tts/infrastructure/audio_player_service.dart';
import 'package:turkce_ses/features/tts/infrastructure/tts_engine.dart';

/// Testlerde ses aygıtı yerine kullanılan sahte oynatıcı.
class FakeAudio implements AudioPlayback {
  final List<String> calls = [];
  bool disposed = false;

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration> get durationStream => const Stream.empty();

  @override
  Stream<void> get completeStream => const Stream.empty();

  @override
  Stream<PlayerState> get stateStream => const Stream.empty();

  @override
  Future<void> playMp3(Uint8List bytes) async => calls.add('playMp3');

  @override
  Future<void> playWav(Uint8List bytes) async => calls.add('playWav');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> seek(Duration position) async => calls.add('seek');

  @override
  Future<void> setVolume(double volume) async => calls.add('setVolume');

  @override
  Future<void> playPreview(Uint8List wavBytes) async =>
      calls.add('playPreview');

  @override
  Future<void> stopPreview() async => calls.add('stopPreview');

  @override
  Future<void> dispose() async {
    disposed = true;
    calls.add('dispose');
  }
}

/// Gerçek model yerine kısa bir sinüs dalgası üreten sahte motor.
class FakeEngine implements TtsEngine {
  FakeEngine({this.sampleRate = 24000, this.durationSeconds = 0.25});

  @override
  final int sampleRate;
  final double durationSeconds;

  bool _ready = false;
  bool disposed = false;
  int synthesizeCalls = 0;
  final List<TtsSynthesisRequest> requests = [];

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize({void Function(double progress)? onProgress}) async {
    onProgress?.call(0.5);
    _ready = true;
    onProgress?.call(1);
  }

  @override
  Future<SynthesisResult> synthesize(
    TtsSynthesisRequest request, {
    void Function(double progress)? onProgress,
  }) async {
    synthesizeCalls++;
    requests.add(request);
    onProgress?.call(1);

    final length = (sampleRate * durationSeconds).round();
    final samples = Float32List(length);
    for (var i = 0; i < length; i++) {
      samples[i] = math.sin(2 * math.pi * 440 * i / sampleRate) * 0.4;
    }

    return SynthesisResult(
      samples: samples,
      sampleRate: sampleRate,
      elapsed: const Duration(milliseconds: 10),
      text: request.normalizedText,
      normalizedText: request.normalizedText,
      voiceId: request.voiceId,
    );
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    _ready = false;
  }
}
