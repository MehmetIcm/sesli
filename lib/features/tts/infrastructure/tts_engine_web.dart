import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/pocket_tts_model.dart';
import '../data/pocket_tts_params.dart';
import '../domain/synthesis_result.dart';
import 'tts_engine.dart';

/// Tarayıcıda Web Worker içinde çalışan WASM motoru.
///
/// Ağır ONNX çıkarımı ana iş parçacığından ayrı tutulur; böylece arayüz
/// seslendirme sırasında donmaz.
class WebTtsEngine implements TtsEngine {
  _WebWorker? _worker;
  Completer<void> _ready = Completer<void>();
  final Map<int, _PendingRequest> _pending = {};
  int _nextId = 1;
  int _sampleRate = 24000;
  bool _initialized = false;

  @override
  bool get isReady => _initialized;

  @override
  int get sampleRate => _sampleRate;

  @override
  Future<void> initialize({void Function(double progress)? onProgress}) async {
    if (_initialized) return;
    if (_ready.isCompleted) {
      _ready = Completer<void>();
    }

    // Model dosyaları ilk açılışta service worker üzerinden önbelleğe
    // alınmalı. Aksi hâlde uygulama, service worker etkinleşmeden önce
    // ilk model dosyasını ağdan çeker ve dosya çevrimdışı kullanım için
    // önbellekte kalmaz.
    await _waitForServiceWorker();

    final worker = _WebWorker(Uri.base.resolve('tts-worker.js').toString());
    _worker = worker;
    worker.onmessage = _handleMessage.toJS;
    worker.onerror = ((JSAny? event) {
      final message = event == null
          ? 'Web Worker yüklenemedi.'
          : event.toString();
      if (!_ready.isCompleted) {
        _ready.completeError(StateError(message));
      }
      _failAll(message);
    }).toJS;

    onProgress?.call(0.02);

    final glue = await _loadText(
      'packages/sherpa_onnx_web/assets/sherpa-onnx-wasm-web.js',
    );
    final ttsJs = await _loadText(
      'packages/sherpa_onnx_web/assets/sherpa-onnx-tts.js',
    );
    onProgress?.call(0.08);

    final wasmData = await rootBundle.load(
      'packages/sherpa_onnx_web/assets/sherpa-onnx-wasm-web.wasm',
    );
    final wasmBytes = Uint8List.fromList(
      wasmData.buffer.asUint8List(
        wasmData.offsetInBytes,
        wasmData.lengthInBytes,
      ),
    );
    final wasmBuffer = wasmBytes.buffer.toJS;

    final modelFiles = JSObject();
    final transfer = <JSAny>[wasmBuffer];

    for (var index = 0; index < PocketTtsModel.files.length; index++) {
      final fileName = PocketTtsModel.files[index];
      final data = await rootBundle.load(PocketTtsModel.assetPath(fileName));
      final bytes = Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final buffer = bytes.buffer.toJS;
      modelFiles['/models/$fileName'] = buffer;
      transfer.add(buffer);
      onProgress?.call(
        0.08 + 0.82 * ((index + 1) / PocketTtsModel.files.length),
      );
    }

    final config = {
      'model': {
        'pocket': {
          'lmFlow': '/models/${PocketTtsModel.lmFlow}',
          'lmMain': '/models/${PocketTtsModel.lmMain}',
          'encoder': '/models/${PocketTtsModel.encoder}',
          'decoder': '/models/${PocketTtsModel.decoder}',
          'textConditioner': '/models/${PocketTtsModel.textConditioner}',
          'vocabJson': '/models/${PocketTtsModel.vocab}',
          'tokenScoresJson': '/models/${PocketTtsModel.tokenScores}',
          'voiceEmbeddingCacheCapacity': 50,
        },
        'numThreads': 2,
        'debug': false,
        'provider': 'cpu',
      },
      'maxNumSentences': 1,
      'silenceScale': PocketTtsParams.silenceScale,
    };

    final message = JSObject();
    message['type'] = 'init'.toJS;
    message['jsGlueSource'] = glue.toJS;
    message['ttsJsSource'] = ttsJs.toJS;
    message['wasmBinary'] = wasmBuffer;
    message['modelFiles'] = modelFiles;
    message['config'] = _parseJson(jsonEncode(config));

    worker.postMessage(message, transfer.toJS);

    await _ready.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => throw TimeoutException(
        'Model tarayıcıda yüklenemedi. Sayfayı yenileyip tekrar deneyin.',
      ),
    );
    onProgress?.call(1);
  }

  @override
  Future<SynthesisResult> synthesize(
    TtsSynthesisRequest request, {
    void Function(double progress)? onProgress,
  }) async {
    if (!_initialized || _worker == null) {
      throw StateError('TTS motoru henüz hazır değil.');
    }

    final id = _nextId++;
    final completer = Completer<SynthesisResult>();
    _pending[id] = _PendingRequest(
      completer: completer,
      onProgress: onProgress,
      request: request,
    );

    final message = JSObject();
    message['type'] = 'generate'.toJS;
    message['text'] = request.text.toJS;
    message['speed'] = request.speed.toJS;
    message['numSteps'] = request.numSteps.toJS;
    message['generationId'] = id.toJS;
    message['silenceScale'] = PocketTtsParams.silenceScale.toJS;
    message['extra'] = _extraToJs(PocketTtsParams.extra);
    message['referenceSampleRate'] = request.referenceSampleRate.toJS;
    message['referenceAudio'] = _toFloat32(request.referenceSamples);
    _worker!.postMessage(message);

    return completer.future;
  }

  void _handleMessage(JSAny? event) {
    if (event == null) return;
    final data = (event as JSObject).getProperty('data'.toJS) as JSObject;
    final type = (data.getProperty('type'.toJS) as JSString).toDart;

    switch (type) {
      case 'ready':
        _sampleRate =
            (data.getProperty('sampleRate'.toJS) as JSNumber).toDartInt;
        _initialized = true;
        if (!_ready.isCompleted) _ready.complete();
        break;
      case 'progress':
        final id =
            (data.getProperty('generationId'.toJS) as JSNumber).toDartInt;
        final progress =
            (data.getProperty('progress'.toJS) as JSNumber).toDartDouble;
        _pending[id]?.onProgress?.call(progress);
        break;
      case 'done':
        final id =
            (data.getProperty('generationId'.toJS) as JSNumber).toDartInt;
        final pending = _pending.remove(id);
        if (pending == null) return;
        final buffer =
            (data.getProperty('samples'.toJS) as JSArrayBuffer).toDart;
        final samples = Float32List.view(buffer);
        final rate =
            (data.getProperty('sampleRate'.toJS) as JSNumber).toDartInt;
        final elapsed =
            (data.getProperty('elapsed'.toJS) as JSNumber).toDartDouble;
        pending.completer.complete(
          SynthesisResult(
            samples: samples,
            sampleRate: rate,
            elapsed: Duration(microseconds: (elapsed * 1000000).round()),
            text: pending.request.text,
            normalizedText: pending.request.normalizedText,
            voiceId: pending.request.voiceId,
          ),
        );
        break;
      case 'error':
        final idValue = data.getProperty('generationId'.toJS);
        final id = (idValue != null && idValue.isA<JSNumber>())
            ? (idValue as JSNumber).toDartInt
            : null;
        final message = (data.getProperty('message'.toJS) as JSString).toDart;
        if (id == null) {
          if (!_ready.isCompleted) {
            _ready.completeError(StateError(message));
          }
          _failAll(message);
        } else {
          final pending = _pending.remove(id);
          pending?.completer.completeError(StateError(message));
        }
        break;
      case 'log':
        debugPrint(
          '[tts-worker] ${(data.getProperty('message'.toJS) as JSString).toDart}',
        );
        break;
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
    try {
      final message = JSObject();
      message['type'] = 'dispose'.toJS;
      _worker?.postMessage(message);
    } catch (_) {
      // Worker zaten kapanmış olabilir.
    }
    _worker?.terminate();
    _worker = null;
    _initialized = false;
  }

  /// Service worker'ın sayfayı kontrol etmesini bekler.
  ///
  /// Çevrimdışı çalışma için model dosyalarının önbelleğe alınması gerekir;
  /// bu da ancak service worker etkinleştikten sonra yapılan isteklerde
  /// garanti edilir. Desteklenmeyen ortamlarda sessizce devam edilir.
  static Future<void> _waitForServiceWorker() async {
    try {
      final navigator =
          globalContext.getProperty('navigator'.toJS) as JSObject?;
      final container =
          navigator?.getProperty('serviceWorker'.toJS) as JSObject?;
      if (container == null) return;

      final ready = container.getProperty('ready'.toJS) as JSPromise<JSAny?>?;
      if (ready != null) {
        await ready.toDart.timeout(const Duration(seconds: 15));
      }

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        final controller = container.getProperty('controller'.toJS);
        if (controller != null && !controller.isUndefinedOrNull) return;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    } catch (_) {
      // Service worker yoksa normal yükleme sürer.
    }
  }

  static Future<String> _loadText(String path) async {
    final data = await rootBundle.load(path);
    return utf8.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  static JSObject _parseJson(String source) {
    final json = globalContext.getProperty('JSON'.toJS) as JSObject;
    final parse = json.getProperty('parse'.toJS) as JSFunction;
    return parse.callAsFunction(null, source.toJS) as JSObject;
  }

  static JSObject _toFloat32(Float32List samples) {
    return samples.toJS as JSObject;
  }

  /// Model parametrelerini Worker'a JS nesnesi olarak aktarır.
  static JSObject _extraToJs(Map<String, Object> extra) {
    final object = JSObject();
    for (final entry in extra.entries) {
      final value = entry.value;
      if (value is int) {
        object[entry.key] = value.toJS;
      } else if (value is double) {
        object[entry.key] = value.toJS;
      } else {
        object[entry.key] = value.toString().toJS;
      }
    }
    return object;
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

@JS('Worker')
extension type _WebWorker._(JSObject _) implements JSObject {
  external factory _WebWorker(String scriptUrl);

  external void postMessage(JSAny message, [JSArray<JSAny> transfer]);

  external void terminate();

  external set onmessage(JSFunction? handler);

  external set onerror(JSFunction? handler);
}
