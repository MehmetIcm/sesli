import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../data/pocket_tts_model.dart';
import '../data/pocket_tts_params.dart';
import '../domain/synthesis_result.dart';
import 'model_installer.dart';
import 'tts_engine.dart';
import 'tts_isolate_messages.dart';

/// macOS ve diğer masaüstü platformlarda arka plan isolate'inde çalışan motor.
class NativeTtsEngine implements TtsEngine {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  Completer<void> _readyCompleter = Completer<void>();
  final Map<int, _PendingRequest> _pending = {};

  bool _initialized = false;
  int _sampleRate = 24000;
  int _nextRequestId = 1;

  @override
  bool get isReady => _initialized;

  @override
  int get sampleRate => _sampleRate;

  @override
  Future<void> initialize({void Function(double progress)? onProgress}) async {
    if (_initialized) return;
    if (_readyCompleter.isCompleted) {
      _readyCompleter = Completer<void>();
    }

    final paths = await ModelInstaller.ensureInstalled(
      onProgress: (value) => onProgress?.call(value * 0.65),
    );

    final receivePort = ReceivePort();
    _receivePort = receivePort;

    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final portCompleter = Completer<SendPort>();

    _isolate = await Isolate.spawn(
      _isolateEntry,
      receivePort.sendPort,
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
      debugName: 'sesli-tts',
    );

    receivePort.listen((message) {
      if (message is SendPort && !portCompleter.isCompleted) {
        portCompleter.complete(message);
      } else {
        _handleMessage(message);
      }
    });
    errorPort.listen((message) {
      _failAll('TTS isolate hatası: $message');
    });
    exitPort.listen((_) {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(
          StateError('TTS isolate beklenmeden kapandı.'),
        );
      }
      _failAll('TTS isolate kapandı.');
    });

    _sendPort = await portCompleter.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('TTS isolate başlatılamadı.'),
    );
    _sendPort!.send(TtsInitMessage(modelPaths: paths, numThreads: 4));

    await _readyCompleter.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () =>
          throw TimeoutException('Model yüklenmesi zaman aşımına uğradı.'),
    );
    onProgress?.call(1);
  }

  @override
  Future<SynthesisResult> synthesize(
    TtsSynthesisRequest request, {
    void Function(double progress)? onProgress,
  }) async {
    if (!_initialized) {
      throw StateError('TTS motoru henüz hazır değil.');
    }
    final port = _sendPort;
    if (port == null) {
      throw StateError('TTS isolate bağlantısı kurulamadı.');
    }

    final id = _nextRequestId++;
    final completer = Completer<SynthesisResult>();
    _pending[id] = _PendingRequest(
      completer: completer,
      onProgress: onProgress,
      request: request,
    );

    port.send(
      TtsGenerateMessage(
        id: id,
        text: request.text,
        referenceSamples: request.referenceSamples,
        referenceSampleRate: request.referenceSampleRate,
        speed: request.speed,
        numSteps: request.numSteps,
      ),
    );

    return completer.future;
  }

  void _handleMessage(Object? message) {
    if (message is TtsReadyMessage) {
      _sampleRate = message.sampleRate;
      _initialized = true;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      return;
    }

    if (message is TtsProgressMessage) {
      _pending[message.id]?.onProgress?.call(message.progress);
      return;
    }

    if (message is TtsDoneMessage) {
      final pending = _pending.remove(message.id);
      if (pending == null) return;
      pending.completer.complete(
        SynthesisResult(
          samples: message.samples,
          sampleRate: message.sampleRate,
          elapsed: Duration(microseconds: message.elapsedMicros),
          text: pending.request.text,
          normalizedText: pending.request.normalizedText,
          voiceId: pending.request.voiceId,
        ),
      );
      return;
    }

    if (message is TtsErrorMessage) {
      if (message.id == null) {
        if (!_readyCompleter.isCompleted) {
          _readyCompleter.completeError(StateError(message.message));
        }
        _failAll(message.message);
      } else {
        final pending = _pending.remove(message.id);
        pending?.completer.completeError(StateError(message.message));
      }
    }
  }

  void _failAll(String message) {
    for (final pending in _pending.values) {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(StateError(message));
      }
    }
    _pending.clear();
  }

  @override
  Future<void> dispose() async {
    _sendPort?.send(const TtsDisposeMessage());
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
    _initialized = false;
  }
}

class _PendingRequest {
  _PendingRequest({
    required this.completer,
    required this.onProgress,
    required this.request,
  });

  final Completer<SynthesisResult> completer;
  final void Function(double progress)? onProgress;
  final TtsSynthesisRequest request;
}

/// Arka plan isolate'inin giriş noktası.
void _isolateEntry(SendPort mainPort) {
  final receivePort = ReceivePort();
  mainPort.send(receivePort.sendPort);

  sherpa.initBindings();

  sherpa.OfflineTts? engine;

  receivePort.listen((message) {
    if (message is TtsInitMessage) {
      try {
        final paths = message.modelPaths;
        final config = sherpa.OfflineTtsConfig(
          model: sherpa.OfflineTtsModelConfig(
            pocket: sherpa.OfflineTtsPocketModelConfig(
              lmFlow: paths[PocketTtsModel.lmFlow] ?? '',
              lmMain: paths[PocketTtsModel.lmMain] ?? '',
              encoder: paths[PocketTtsModel.encoder] ?? '',
              decoder: paths[PocketTtsModel.decoder] ?? '',
              textConditioner: paths[PocketTtsModel.textConditioner] ?? '',
              vocabJson: paths[PocketTtsModel.vocab] ?? '',
              tokenScoresJson: paths[PocketTtsModel.tokenScores] ?? '',
            ),
            numThreads: message.numThreads,
            debug: false,
            provider: 'cpu',
          ),
          maxNumSentences: 1,
          silenceScale: PocketTtsParams.silenceScale,
        );
        final created = sherpa.OfflineTts(config);
        engine = created;
        mainPort.send(TtsReadyMessage(sampleRate: created.sampleRate));
      } catch (error, stack) {
        debugPrint('TTS init error: $error\n$stack');
        mainPort.send(TtsErrorMessage(message: '$error'));
      }
      return;
    }

    if (message is TtsGenerateMessage) {
      final activeEngine = engine;
      if (activeEngine == null) {
        mainPort.send(
          TtsErrorMessage(id: message.id, message: 'TTS motoru hazır değil.'),
        );
        return;
      }

      final stopwatch = Stopwatch()..start();
      try {
        final audio = activeEngine.generateWithConfig(
          text: message.text,
          config: sherpa.OfflineTtsGenerationConfig(
            speed: message.speed,
            numSteps: message.numSteps,
            referenceAudio: message.referenceSamples,
            referenceSampleRate: message.referenceSampleRate,
            silenceScale: PocketTtsParams.silenceScale,
            extra: PocketTtsParams.extra,
          ),
          onProgress: (samples, progress) {
            mainPort.send(
              TtsProgressMessage(id: message.id, progress: progress),
            );
            return 1;
          },
        );
        stopwatch.stop();

        if (audio.samples.isEmpty) {
          mainPort.send(
            TtsErrorMessage(
              id: message.id,
              message: 'Model ses üretemedi. Metni kısaltmayı deneyin.',
            ),
          );
          return;
        }

        mainPort.send(
          TtsDoneMessage(
            id: message.id,
            samples: Float32List.fromList(audio.samples),
            sampleRate: audio.sampleRate,
            elapsedMicros: stopwatch.elapsedMicroseconds,
          ),
        );
      } catch (error, stack) {
        debugPrint('TTS generate error: $error\n$stack');
        mainPort.send(TtsErrorMessage(id: message.id, message: '$error'));
      }
      return;
    }

    if (message is TtsDisposeMessage) {
      engine?.free();
      engine = null;
      receivePort.close();
    }
  });
}
