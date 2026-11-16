import 'tts_engine.dart';

/// Bu platformda seslendirme motoru bulunmuyor.
TtsEngine createTtsEngine() {
  throw UnsupportedError(
    'Sesli şu anda yalnızca web ve macOS üzerinde çalışır.',
  );
}
