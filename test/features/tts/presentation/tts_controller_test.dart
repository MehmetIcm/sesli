import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turkce_ses/features/tts/data/voice_catalog.dart';
import 'package:turkce_ses/features/tts/domain/speech_emotion.dart';
import 'package:turkce_ses/features/tts/presentation/tts_controller.dart';

import '../../../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeEngine engine;
  late FakeAudio audio;
  late TtsController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    engine = FakeEngine();
    audio = FakeAudio();
    controller = TtsController(engine: engine, audio: audio);
    await controller.initialize();
  });

  tearDown(() {
    controller.dispose();
  });

  group('TtsController', () {
    test('başlatma moturu hazırlar ve altı sesi sunar', () {
      expect(controller.engineStatus, EngineStatus.ready);
      expect(controller.voices, hasLength(6));
      expect(controller.voices.map((voice) => voice.name).toSet(), {
        'Elif',
        'Zeynep',
        'Defne',
        'Emre',
        'Kerem',
        'Mert',
      });
    });

    test('ses, duygu, hız ve kalite ayarlarını günceller', () {
      controller.selectVoice(VoiceCatalog.byId('male_2'));
      controller.setEmotion(SpeechEmotion.happy);
      controller.setSpeed(1.2);
      controller.setNumSteps(8);

      expect(controller.selectedVoice.id, 'male_2');
      expect(controller.emotion, SpeechEmotion.happy);
      expect(controller.speed, 1.2);
      expect(controller.numSteps, 8);
    });

    test('hız ve kalite değerlerini güvenli aralıkta tutar', () {
      controller.setSpeed(5);
      expect(controller.speed, 1.3);
      controller.setSpeed(0.1);
      expect(controller.speed, 0.7);
      controller.setNumSteps(99);
      expect(controller.numSteps, 8);
      controller.setNumSteps(0);
      expect(controller.numSteps, 2);
    });

    test('boş metinde seslendirme başlatmaz', () async {
      await controller.synthesize();

      expect(engine.synthesizeCalls, 0);
      expect(controller.synthesisStatus, SynthesisStatus.error);
      expect(controller.synthesisError, contains('metin'));
    });

    test('metni normalize eder, MP3 üretir ve otomatik oynatır', () async {
      controller.setText('2026 yılında 25 TL.');
      await controller.synthesize();

      expect(engine.synthesizeCalls, 1);
      expect(controller.synthesisStatus, SynthesisStatus.ready);
      expect(controller.result, isNotNull);
      expect(controller.result!.normalizedText, contains('iki bin yirmi altı'));
      expect(controller.result!.normalizedText, contains('yirmi beş lira'));
      expect(controller.mp3, isNotNull);
      expect(controller.mp3!.length, greaterThan(1000));
      expect(controller.duration, greaterThan(Duration.zero));
      expect(audio.calls, contains('playWav'));
    });

    test('uzun metni parçalara bölerek seslendirir', () async {
      final sentence = 'Bu cümle seslendirme için yeterince uzundur. ';
      controller.setText(sentence * 12);

      await controller.synthesize();

      expect(engine.synthesizeCalls, greaterThan(1));
      expect(controller.synthesisStatus, SynthesisStatus.ready);
      expect(controller.mp3, isNotNull);
    });

    test('hız ayarı çıktı süresini gerçekten değiştirir', () async {
      controller.setText('Kısa bir metin.');

      controller.setSpeed(0.8);
      await controller.synthesize();
      final slow = controller.duration;

      controller.setSpeed(1.2);
      await controller.synthesize();
      final fast = controller.duration;

      expect(slow, greaterThan(Duration.zero));
      expect(fast, lessThan(slow));
    });

    test('duran sonuç metin değişince bayatlar', () async {
      controller.setText('Kısa bir metin.');
      await controller.synthesize();
      expect(controller.isResultStale, isFalse);

      controller.setText('Değişen metin.');
      expect(controller.isResultStale, isTrue);
    });

    test('geçmişe kayıt ekler ve temizler', () async {
      controller.setSaveHistory(true);
      controller.setText('Geçmişe eklenecek metin.');
      await controller.synthesize();

      expect(controller.history, hasLength(1));
      expect(controller.history.first.text, 'Geçmişe eklenecek metin.');

      await controller.clearHistory();
      expect(controller.history, isEmpty);
    });

    test('duygu etiketi yalnızca ilk parçaya eklenir', () async {
      controller.setEmotion(SpeechEmotion.happy);
      final first = 'Birinci cümle ${'kelime ' * 24}.';
      final second = 'İkinci cümle ${'sözcük ' * 24}.';
      controller.setText('$first $second');
      await controller.synthesize();

      expect(engine.requests.length, greaterThan(1));
      expect(engine.requests.first.text, startsWith(SpeechEmotion.happy.tag));
      expect(engine.requests[1].text, isNot(contains(SpeechEmotion.happy.tag)));
    });

    test('modele rakam ve desteklenmeyen karakter göndermez', () async {
      controller.setEmotion(SpeechEmotion.happy);
      controller.setText(
        'MP3 B12 5G 3D WhatsApp #etiket @kullanici user123@example.com 😀',
      );
      await controller.synthesize();

      expect(controller.synthesisStatus, SynthesisStatus.ready);
      expect(engine.requests, isNotEmpty);
      for (final request in engine.requests) {
        expect(
          RegExp(r'\d').hasMatch(request.text),
          isFalse,
          reason: 'Rakam kaldı: ${request.text}',
        );
        expect(
          RegExp(r'''[^a-zçğıöşüâîû ,.!?;:'"\-\[\]]''').hasMatch(request.text),
          isFalse,
          reason: 'Model dışı karakter kaldı: ${request.text}',
        );
      }
      expect(engine.requests.first.text, startsWith('[mutlu]'));
    });
  });
}
