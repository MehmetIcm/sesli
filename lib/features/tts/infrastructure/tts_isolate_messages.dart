import 'dart:typed_data';

/// Ana isolate ile TTS isolate'i arasındaki mesajlar.
sealed class TtsIsolateMessage {
  const TtsIsolateMessage();
}

class TtsInitMessage extends TtsIsolateMessage {
  const TtsInitMessage({required this.modelPaths, this.numThreads = 4});

  final Map<String, String> modelPaths;
  final int numThreads;
}

class TtsGenerateMessage extends TtsIsolateMessage {
  const TtsGenerateMessage({
    required this.id,
    required this.text,
    required this.referenceSamples,
    required this.referenceSampleRate,
    required this.speed,
    required this.numSteps,
    this.seed = 42,
  });

  final int id;
  final String text;
  final Float32List referenceSamples;
  final int referenceSampleRate;
  final double speed;
  final int numSteps;
  final int seed;
}

class TtsDisposeMessage extends TtsIsolateMessage {
  const TtsDisposeMessage();
}

class TtsReadyMessage extends TtsIsolateMessage {
  const TtsReadyMessage({required this.sampleRate});

  final int sampleRate;
}

class TtsProgressMessage extends TtsIsolateMessage {
  const TtsProgressMessage({required this.id, required this.progress});

  final int id;
  final double progress;
}

class TtsDoneMessage extends TtsIsolateMessage {
  const TtsDoneMessage({
    required this.id,
    required this.samples,
    required this.sampleRate,
    required this.elapsedMicros,
  });

  final int id;
  final Float32List samples;
  final int sampleRate;
  final int elapsedMicros;
}

class TtsErrorMessage extends TtsIsolateMessage {
  const TtsErrorMessage({this.id, required this.message});

  final int? id;
  final String message;
}
