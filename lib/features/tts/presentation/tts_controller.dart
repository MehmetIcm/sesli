import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/history_store.dart';
import '../data/sample_texts.dart';
import '../data/tts_preferences.dart';
import '../data/voice_catalog.dart';
import '../domain/english_transliterator.dart';
import '../domain/speech_emotion.dart';
import '../domain/synthesis_result.dart';
import '../domain/text_chunker.dart';
import '../domain/turkish_text_normalizer.dart';
import '../domain/voice_profile.dart';
import '../infrastructure/audio_player_service.dart';
import '../infrastructure/audio_post_processor.dart';
import '../infrastructure/audio_resampler.dart';
import '../infrastructure/file_saver.dart';
import '../infrastructure/mp3_encoder_runner.dart';
import '../infrastructure/tts_engine.dart';
import '../infrastructure/wav_codec.dart';

enum EngineStatus { loading, ready, error }

enum SynthesisStatus { idle, synthesizing, ready, error }

/// Uygulamanın tüm durumunu yöneten denetleyici.
class TtsController extends ChangeNotifier {
  TtsController({
    TtsEngine? engine,
    AudioPlayback? audio,
    TurkishTextNormalizer? normalizer,
  }) : _engine = engine ?? createTtsEngine(),
       _audio = audio ?? AudioPlayerService(),
       _normalizer = normalizer ?? const TurkishTextNormalizer();

  static const int maxTextLength = 5000;

  final TtsEngine _engine;
  final AudioPlayback _audio;
  final TurkishTextNormalizer _normalizer;
  final TextEditingController textController = TextEditingController();

  AppSettings _settings = const AppSettings();
  List<HistoryEntry> _history = [];
  bool _initialized = false;

  EngineStatus _engineStatus = EngineStatus.loading;
  double _engineProgress = 0;
  String? _engineError;

  SynthesisStatus _synthesisStatus = SynthesisStatus.idle;
  double _synthesisProgress = 0;
  String? _synthesisError;

  SynthesisResult? _result;
  Uint8List? _mp3;
  Uint8List? _playbackWav;
  bool _isEncodingMp3 = false;

  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _audioLoaded = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  String? _previewingVoiceId;
  Timer? _previewTimer;
  bool _disposed = false;

  final Map<String, WavData> _referenceCache = {};
  final Map<String, Uint8List> _previewCache = {};

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<void>? _completeSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  // ── Genel durum ────────────────────────────────────────────────────────

  bool get isInitialized => _initialized;
  List<VoiceProfile> get voices => VoiceCatalog.all;
  List<HistoryEntry> get history => List.unmodifiable(_history);
  List<SampleText> get samples => SampleTexts.all;

  VoiceProfile get selectedVoice => VoiceCatalog.byId(_settings.voiceId);
  SpeechEmotion get emotion => _settings.emotion;
  double get speed => _settings.speed;
  int get numSteps => _settings.numSteps;
  bool get autoPlay => _settings.autoPlay;
  bool get saveHistory => _settings.saveHistory;
  ThemeMode get themeMode => _settings.themeMode;

  EngineStatus get engineStatus => _engineStatus;
  double get engineProgress => _engineProgress;
  String? get engineError => _engineError;

  SynthesisStatus get synthesisStatus => _synthesisStatus;
  double get synthesisProgress => _synthesisProgress;
  String? get synthesisError => _synthesisError;

  SynthesisResult? get result => _result;
  Uint8List? get mp3 => _mp3;
  bool get isEncodingMp3 => _isEncodingMp3;

  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;

  String? get previewingVoiceId => _previewingVoiceId;

  bool get isSynthesizing => _synthesisStatus == SynthesisStatus.synthesizing;
  bool get hasResult => _result != null && _mp3 != null;

  bool get isResultStale =>
      _result != null && _result!.text != textController.text.trim();

  bool get canSynthesize =>
      _engineStatus == EngineStatus.ready &&
      !isSynthesizing &&
      textController.text.trim().isNotEmpty;

  int get characterCount => textController.text.runes.length;

  // ── Başlatma ───────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    textController.addListener(_onTextChanged);
    _positionSubscription = _audio.positionStream.listen((value) {
      _position = value;
      _safeNotify();
    });
    _durationSubscription = _audio.durationStream.listen((value) {
      if (value > Duration.zero) {
        _duration = value;
        _safeNotify();
      }
    });
    _completeSubscription = _audio.completeStream.listen((_) {
      _isPlaying = false;
      _position = _duration;
      _safeNotify();
    });
    _stateSubscription = _audio.stateStream.listen((state) {
      final playing = state == PlayerState.playing;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        _safeNotify();
      }
    });

    _settings = await TtsPreferences.load();
    _history = await HistoryStore.load();
    _safeNotify();

    // Dil varlıkları modelle paralel yüklenir; sentezleme başlamadan önce
    // İngilizce sözlük hazır olur.
    final languageReady = EnglishTransliterator.instance.ensureLoaded();
    await _initEngine();
    await languageReady;
  }

  Future<void> _initEngine() async {
    _engineStatus = EngineStatus.loading;
    _engineProgress = 0;
    _engineError = null;
    _safeNotify();

    try {
      await _engine.initialize(
        onProgress: (progress) {
          _engineProgress = progress.clamp(0, 1).toDouble();
          _safeNotify();
        },
      );
      _engineStatus = EngineStatus.ready;
      _engineProgress = 1;
    } catch (error) {
      _engineStatus = EngineStatus.error;
      _engineError = _friendlyError(error);
    }
    _safeNotify();
  }

  Future<void> retryEngine() async {
    try {
      await _engine.dispose();
    } catch (_) {
      // Yoksay; yeni deneme yapılacak.
    }
    await _initEngine();
  }

  void _onTextChanged() {
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ── Metin ──────────────────────────────────────────────────────────────

  void setText(String value) {
    textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void clearText() {
    textController.clear();
  }

  void loadSample(SampleText sample) {
    setText(sample.text);
  }

  // ── Ayarlar ────────────────────────────────────────────────────────────

  void selectVoice(VoiceProfile voice) {
    if (_settings.voiceId == voice.id) return;
    _updateSettings(_settings.copyWith(voiceId: voice.id));
    _stopPreview();
  }

  void setEmotion(SpeechEmotion value) {
    _updateSettings(_settings.copyWith(emotion: value));
  }

  void setSpeed(double value) {
    _updateSettings(
      _settings.copyWith(speed: value.clamp(0.7, 1.3).toDouble()),
    );
  }

  void setNumSteps(int value) {
    _updateSettings(_settings.copyWith(numSteps: value.clamp(2, 8).toInt()));
  }

  void setAutoPlay(bool value) {
    _updateSettings(_settings.copyWith(autoPlay: value));
  }

  void setSaveHistory(bool value) {
    _updateSettings(_settings.copyWith(saveHistory: value));
  }

  void setThemeMode(ThemeMode value) {
    _updateSettings(_settings.copyWith(themeMode: value));
  }

  void _updateSettings(AppSettings next) {
    _settings = next;
    _safeNotify();
    unawaited(TtsPreferences.save(next));
  }

  // ── Seslendirme ────────────────────────────────────────────────────────

  Future<void> synthesize() async {
    if (_engineStatus != EngineStatus.ready || isSynthesizing) return;

    final original = textController.text.trim();
    if (original.isEmpty) {
      _synthesisError = 'Seslendirmek için önce bir metin yazın.';
      _synthesisStatus = SynthesisStatus.error;
      _safeNotify();
      return;
    }
    if (original.length > maxTextLength) {
      _synthesisError =
          'Metin çok uzun. En fazla $maxTextLength karakter kullanabilirsiniz.';
      _synthesisStatus = SynthesisStatus.error;
      _safeNotify();
      return;
    }

    await _audio.stop();
    _audioLoaded = false;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;

    _synthesisStatus = SynthesisStatus.synthesizing;
    _synthesisProgress = 0;
    _synthesisError = null;
    _result = null;
    _mp3 = null;
    _playbackWav = null;
    _isEncodingMp3 = false;
    _safeNotify();

    final stopwatch = Stopwatch()..start();

    try {
      // Paragrafları ayrı ayrı normalize et; böylece paragraf sonlarında
      // daha uzun bir nefes payı verilebilir. Tek satır sonları cümle
      // içi boşluk sayılır.
      final normalizedParagraphs = <String>[];
      for (final paragraph in _paragraphs(original)) {
        final value = _normalizer.normalize(paragraph);
        if (value.trim().isNotEmpty) normalizedParagraphs.add(value);
      }
      final normalized = normalizedParagraphs.join(' ');
      if (normalized.trim().isEmpty ||
          !RegExp(r'[a-zçğıöşüâîû]').hasMatch(normalized)) {
        throw const FormatException(
          'Metin seslendirilebilir bir içerik içermiyor.',
        );
      }

      // Cümle bazlı sentez: her cümle ayrı üretilir, böylece modelin kendi
      // cümle sonu sessizliği uygulamanın duraklama politikasıyla çakışmaz.
      final segments = <SpeechSegment>[];
      for (var p = 0; p < normalizedParagraphs.length; p++) {
        final paragraphSegments = TextChunker.segments(normalizedParagraphs[p]);
        for (var s = 0; s < paragraphSegments.length; s++) {
          final isLastOfParagraph = s == paragraphSegments.length - 1;
          final isLastParagraph = p == normalizedParagraphs.length - 1;
          segments.add(
            isLastOfParagraph && !isLastParagraph
                ? paragraphSegments[s].copyWith(pauseAfterMs: 600)
                : paragraphSegments[s],
          );
        }
      }
      if (segments.isEmpty) {
        throw const FormatException('Metin parçalanamadı.');
      }

      final voice = selectedVoice;
      final reference = await _referenceFor(voice);
      final parts = <Float32List>[];
      final gaps = <int>[];
      var sampleRate = reference.sampleRate;

      for (var index = 0; index < segments.length; index++) {
        final segment = segments[index];
        final chunkText = index == 0 && !emotion.isNeutral
            ? '${emotion.tag} ${segment.text}'
            : segment.text;

        final part = await _engine.synthesize(
          TtsSynthesisRequest(
            text: chunkText,
            referenceSamples: reference.samples,
            referenceSampleRate: reference.sampleRate,
            speed: speed,
            numSteps: numSteps,
            normalizedText: normalized,
            voiceId: voice.id,
          ),
          onProgress: (progress) {
            _synthesisProgress =
                ((index + progress.clamp(0, 1)) / segments.length)
                    .clamp(0, 1)
                    .toDouble();
            _safeNotify();
          },
        );

        if (part.samples.isNotEmpty) {
          parts.add(part.samples);
          gaps.add(segment.pauseAfterMs);
          sampleRate = part.sampleRate;
        }
        _synthesisProgress = (index + 1) / segments.length;
        _safeNotify();
      }

      stopwatch.stop();

      if (parts.isEmpty) {
        throw StateError('Model ses üretemedi. Metni kısaltmayı deneyin.');
      }

      // 1. Parçaların kenar sessizliğini kırp, noktalama işaretine göre
      //    değişen doğal nefes paylarıyla birleştir.
      var combined = AudioPostProcessor.joinWithPauses(
        parts,
        sampleRate: sampleRate,
        gapsMs: gaps,
        leadInMs: 120,
        tailMs: 260,
      );

      // 2. Hız kontrolü. Pocket TTS `speed` parametresini yok saydığı için
      //    perdeyi koruyan WSOLA zaman germe uygulanır.
      combined = AudioPostProcessor.timeStretch(
        combined,
        speed,
        sampleRate: sampleRate,
      );

      // 3. Netlik: rumble/DC temizliği, global + ses bazlı EQ, de-esser,
      //    yumuşak kompresör ve −20 LUFS / −1,5 dBTP normalizasyonu.
      combined = AudioPostProcessor.enhance(
        combined,
        sampleRate: sampleRate,
        voiceEq: VoiceCatalog.eqFor(voice.id),
      );

      if (combined.isEmpty) {
        throw StateError('Model ses üretemedi. Metni kısaltmayı deneyin.');
      }

      // 4. Oynatma için 48 kHz kayıpsız WAV hazırlanır. 24 kHz kaynaktan
      //    tam 2× yükseltme yapılır; tarayıcının 44,1 → 48 kHz yeniden
      //    örneklemesi önlenir. MP3 yalnızca indirme içindir.
      const playbackRate = 48000;
      final playbackSamples = AudioResampler.resample(
        combined,
        sampleRate,
        playbackRate,
      );
      final playbackWav = WavCodec.encode(
        playbackSamples,
        sampleRate: playbackRate,
      );

      final synthesis = SynthesisResult(
        samples: combined,
        sampleRate: sampleRate,
        elapsed: stopwatch.elapsed,
        text: original,
        normalizedText: normalized,
        voiceId: voice.id,
        emotion: emotion,
      );

      _result = synthesis;
      _playbackWav = playbackWav;
      _duration = synthesis.duration;
      _synthesisStatus = SynthesisStatus.ready;
      _synthesisProgress = 1;
      _safeNotify();

      // MP3 kodlama ayrı adım: arayüz "MP3 hazırlanıyor" durumunu gösterir.
      _isEncodingMp3 = true;
      _safeNotify();
      final mp3 = await encodeMp3Async(playbackSamples, playbackRate);
      _mp3 = mp3;
      _isEncodingMp3 = false;
      _audioLoaded = false;
      _safeNotify();

      if (autoPlay) {
        await play();
      }
      if (saveHistory) {
        await _addHistory(synthesis, mp3.length);
      }
    } catch (error) {
      _synthesisStatus = SynthesisStatus.error;
      _synthesisError = _friendlyError(error);
      _isEncodingMp3 = false;
      _safeNotify();
    }
  }

  /// Metni paragraflara böler.
  ///
  /// Yalnızca boş satırlar paragraf sayılır; tek satır sonları cümle içi
  /// boşluk olarak ele alınır. Böylece sarılmış metinlerde gereksiz uzun
  /// duraklamalar oluşmaz.
  static List<String> _paragraphs(String text) {
    final normalizedNewlines = text.replaceAll(RegExp(r'\r\n?'), '\n');
    final paragraphs = normalizedNewlines
        .split(RegExp(r'\n\s*\n+'))
        .map((paragraph) => paragraph.replaceAll('\n', ' ').trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();
    return paragraphs.isEmpty ? [text] : paragraphs;
  }

  Future<WavData> _referenceFor(VoiceProfile voice) async {
    final cached = _referenceCache[voice.id];
    if (cached != null) return cached;

    final data = await rootBundle.load(voice.referenceAsset);
    final wav = WavCodec.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    _referenceCache[voice.id] = wav;
    return wav;
  }

  // ── Oynatma ────────────────────────────────────────────────────────────

  /// Baştan oynatır. Sentez sonrası otomatik oynatma için kullanılır.
  Future<void> play() async {
    final wav = _playbackWav;
    if (wav == null) return;

    _isBuffering = true;
    _safeNotify();
    try {
      await _audio.playWav(wav);
      _audioLoaded = true;
      _position = Duration.zero;
    } finally {
      _isBuffering = false;
      _safeNotify();
    }
  }

  Future<void> togglePlay() async {
    final wav = _playbackWav;
    if (wav == null) return;

    if (_isPlaying) {
      await _audio.pause();
      return;
    }

    if (_audioLoaded && _position > Duration.zero && _position < _duration) {
      await _audio.resume();
      return;
    }

    _isBuffering = true;
    _safeNotify();
    try {
      await _audio.playWav(wav);
      _audioLoaded = true;
      _position = Duration.zero;
    } finally {
      _isBuffering = false;
      _safeNotify();
    }
  }

  Future<void> stopPlayback() async {
    await _audio.stop();
    _audioLoaded = false;
    _isPlaying = false;
    _position = Duration.zero;
    _safeNotify();
  }

  Future<void> seekFraction(double fraction) async {
    if (_duration <= Duration.zero) return;
    final target = Duration(
      microseconds: (_duration.inMicroseconds * fraction.clamp(0, 1)).round(),
    );
    _position = target;
    _safeNotify();
    await _audio.seek(target);
  }

  Future<String?> downloadMp3() async {
    final bytes = _mp3;
    if (bytes == null) return null;

    final voice = selectedVoice;
    final stamp = DateTime.now();
    final name =
        'sesli-${_ascii(voice.name)}-${stamp.year}${_two(stamp.month)}${_two(stamp.day)}-${_two(stamp.hour)}${_two(stamp.minute)}.mp3';
    return saveMp3(bytes, name);
  }

  Future<void> copyNormalizedText() async {
    final text = _result?.normalizedText;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
  }

  // ── Önizleme ───────────────────────────────────────────────────────────

  Future<void> togglePreview(VoiceProfile voice) async {
    if (_previewingVoiceId == voice.id) {
      _stopPreview();
      return;
    }

    _previewTimer?.cancel();
    _previewingVoiceId = voice.id;
    _safeNotify();

    try {
      final bytes = _previewCache[voice.id] ??= await _loadPreview(voice);
      final wav = WavCodec.decode(bytes);
      await _audio.playPreview(bytes);
      _previewTimer = Timer(
        wav.duration + const Duration(milliseconds: 250),
        () {
          if (_previewingVoiceId == voice.id) {
            _previewingVoiceId = null;
            _safeNotify();
          }
        },
      );
    } catch (_) {
      _previewingVoiceId = null;
      _safeNotify();
    }
  }

  Future<Uint8List> _loadPreview(VoiceProfile voice) async {
    final data = await rootBundle.load(voice.previewAsset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  void _stopPreview() {
    _previewTimer?.cancel();
    _previewingVoiceId = null;
    unawaited(_audio.stopPreview());
    _safeNotify();
  }

  // ── Geçmiş ─────────────────────────────────────────────────────────────

  Future<void> _addHistory(SynthesisResult synthesis, int sizeBytes) async {
    final now = DateTime.now();
    final entry = HistoryEntry(
      id: '${now.microsecondsSinceEpoch}',
      text: synthesis.text,
      normalizedText: synthesis.normalizedText,
      voiceId: synthesis.voiceId,
      emotion: emotion,
      durationMs: synthesis.duration.inMilliseconds,
      createdAtMs: now.millisecondsSinceEpoch,
      sizeBytes: sizeBytes,
    );

    _history = [entry, ..._history].take(HistoryStore.maxEntries).toList();
    await HistoryStore.save(_history);
    _safeNotify();
  }

  Future<void> deleteHistoryEntry(String id) async {
    _history = _history.where((entry) => entry.id != id).toList();
    await HistoryStore.save(_history);
    _safeNotify();
  }

  Future<void> clearHistory() async {
    _history = [];
    await HistoryStore.clear();
    _safeNotify();
  }

  void loadHistoryEntry(HistoryEntry entry) {
    selectVoice(VoiceCatalog.byId(entry.voiceId));
    setEmotion(entry.emotion);
    setText(entry.text);
  }

  // ── Yardımcılar ────────────────────────────────────────────────────────

  String _friendlyError(Object error) {
    var message = error.toString();
    for (final prefix in const [
      'Exception: ',
      'StateError: ',
      'FormatException: ',
      'TimeoutException: ',
      'ArgumentError: ',
    ]) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length);
      }
    }
    return message.trim().isEmpty
        ? 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.'
        : message;
  }

  String _ascii(String value) {
    const map = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'Ç': 'c',
      'Ğ': 'g',
      'İ': 'i',
      'Ö': 'o',
      'Ş': 's',
      'Ü': 'u',
    };
    var result = value.toLowerCase();
    for (final entry in map.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  void dispose() {
    _disposed = true;
    _previewTimer?.cancel();
    textController.removeListener(_onTextChanged);
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _stateSubscription?.cancel();
    textController.dispose();
    unawaited(_audio.dispose());
    unawaited(_engine.dispose());
    super.dispose();
  }
}
