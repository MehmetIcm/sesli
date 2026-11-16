// Sesli — Pocket TTS Web Worker
//
// Ağır ONNX/WASM çıkarımını ana iş parçacığından ayırır. Mesaj sözleşmesi
// lib/features/tts/infrastructure/tts_engine_web.dart ile eşleşir.

let Module = null;
let tts = null;
let cancelled = false;

function describeError(error) {
  if (typeof error === 'number') {
    return (
      'Seslendirme motoru bu metni işleyemedi. Metinde rakam veya ' +
      'desteklenmeyen bir karakter varsa kaldırıp tekrar deneyin. ' +
      '(WASM kodu: ' + error + ')'
    );
  }
  if (error && error.message) return error.message;
  return String(error);
}

function getFS() {
  if (Module && Module.FS) return Module.FS;
  if (typeof FS !== 'undefined') return FS;
  throw new Error('Emscripten dosya sistemi bulunamadı.');
}

function mkdirTree(path) {
  const fs = getFS();
  const parts = path.split('/');
  let current = '';
  for (const part of parts) {
    if (!part) continue;
    current += '/' + part;
    try {
      fs.mkdir(current);
    } catch (_) {
      // Klasör zaten var.
    }
  }
}

self.onmessage = async function (event) {
  const message = event.data;

  if (message.type === 'init') {
    try {
      if (message.jsGlueSource) self.eval(message.jsGlueSource);
      if (message.ttsJsSource) self.eval(message.ttsJsSource);

      Module = await SherpaOnnx({
        wasmBinary: new Uint8Array(message.wasmBinary),
        print: (text) => self.postMessage({ type: 'log', message: text }),
        printErr: (text) =>
          self.postMessage({ type: 'log', message: '[stderr] ' + text }),
      });

      const files = message.modelFiles || {};
      for (const path of Object.keys(files)) {
        const dir = path.substring(0, path.lastIndexOf('/'));
        if (dir) mkdirTree(dir);
        getFS().writeFile(path, new Uint8Array(files[path]));
      }

      const config = initSherpaOnnxOfflineTtsConfig(message.config, Module);
      const handle = Module._SherpaOnnxCreateOfflineTts(config.ptr);
      freeConfig(config, Module);

      if (!handle) {
        self.postMessage({
          type: 'error',
          message: 'TTS motoru oluşturulamadı (null handle).',
        });
        return;
      }

      tts = {
        handle,
        sampleRate: Module._SherpaOnnxOfflineTtsSampleRate(handle),
        numSpeakers: Module._SherpaOnnxOfflineTtsNumSpeakers(handle),
      };

      self.postMessage({
        type: 'ready',
        sampleRate: tts.sampleRate,
        numSpeakers: tts.numSpeakers,
      });
    } catch (error) {
      self.postMessage({
        type: 'error',
        message: 'Model yüklenemedi: ' + describeError(error),
      });
    }
    return;
  }

  if (message.type === 'generate') {
    const generationId = message.generationId || 0;
    if (!tts) {
      self.postMessage({
        type: 'error',
        generationId,
        message: 'TTS motoru hazır değil.',
      });
      return;
    }

    try {
      const startedAt = performance.now();
      const generationConfig = {
        // Cümle bazlı sentezde modelin kendi duraklamaları hafifçe uzatılır;
        // cümle arası payı uygulama yönetir.
        silenceScale: message.silenceScale ?? 1.05,
        speed: message.speed || 1.0,
        sid: 0,
        numSteps: message.numSteps || 8,
        referenceSampleRate: message.referenceSampleRate || 0,
        // Modele özgü ayarlar: daha kararlı ses, makul cümle birleştirme.
        extra: message.extra || {
          temperature: 0.45,
          seed: 42,
          max_reference_audio_len: 5,
          min_char_in_sentence: 20,
          max_char_in_sentence: 240,
        },
      };

      if (message.referenceAudio) {
        generationConfig.referenceAudio = new Float32Array(
          message.referenceAudio,
        );
      }

      const config = initSherpaOnnxGenerationConfig(
        generationConfig,
        Module,
      );

      cancelled = false;
      const callback = Module.addFunction(
        (samplesPtr, count, progress) => {
          if (cancelled) return 0;
          self.postMessage({
            type: 'progress',
            generationId,
            progress: Math.max(0, Math.min(1, progress)),
          });
          return 1;
        },
        'iiifi',
      );

      const textLength = Module.lengthBytesUTF8(message.text) + 1;
      const textPtr = Module._malloc(textLength);
      Module.stringToUTF8(message.text, textPtr, textLength);

      const audioPtr = Module._SherpaOnnxOfflineTtsGenerateWithConfig(
        tts.handle,
        textPtr,
        config.ptr,
        callback,
        0,
      );

      Module._free(textPtr);
      freeSherpaOnnxGenerationConfig(config, Module);
      Module.removeFunction(callback);

      if (!audioPtr) {
        self.postMessage({
          type: 'error',
          generationId,
          message: 'Ses üretilemedi.',
        });
        return;
      }

      const base = audioPtr / 4;
      const samplesPtr = Module.HEAPU32[base];
      const sampleCount = Module.HEAP32[base + 1];
      const sampleRate = Module.HEAP32[base + 2];
      const samples = new Float32Array(
        Module.HEAPF32.buffer,
        samplesPtr,
        sampleCount,
      ).slice();

      Module._SherpaOnnxDestroyOfflineTtsGeneratedAudio(audioPtr);

      const elapsed = (performance.now() - startedAt) / 1000;

      self.postMessage(
        {
          type: 'done',
          generationId,
          samples: samples.buffer,
          sampleRate,
          duration: sampleCount / sampleRate,
          elapsed,
        },
        [samples.buffer],
      );
    } catch (error) {
      self.postMessage({
        type: 'error',
        generationId,
        message: 'Seslendirme hatası: ' + describeError(error),
      });
    }
    return;
  }

  if (message.type === 'cancel') {
    cancelled = true;
    return;
  }

  if (message.type === 'dispose') {
    try {
      if (tts) {
        Module._SherpaOnnxDestroyOfflineTts(tts.handle);
        tts = null;
      }
    } catch (_) {
      // Yoksay.
    }
    self.close();
  }
};
