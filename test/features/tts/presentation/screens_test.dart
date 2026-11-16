import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turkce_ses/features/tts/data/history_store.dart';
import 'package:turkce_ses/features/tts/data/voice_catalog.dart';
import 'package:turkce_ses/features/tts/domain/speech_emotion.dart';
import 'package:turkce_ses/features/tts/presentation/screens/about_screen.dart';
import 'package:turkce_ses/features/tts/presentation/screens/history_screen.dart';
import 'package:turkce_ses/features/tts/presentation/screens/licenses_screen.dart';
import 'package:turkce_ses/features/tts/presentation/screens/privacy_screen.dart';
import 'package:turkce_ses/features/tts/presentation/screens/settings_screen.dart';
import 'package:turkce_ses/features/tts/presentation/tts_controller.dart';

import '../../../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudio audio;
  late TtsController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    audio = FakeAudio();
    controller = TtsController(engine: FakeEngine(), audio: audio);
    await controller.initialize();
  });

  tearDown(() {
    controller.dispose();
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    TtsController? value,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<TtsController>.value(
        value: value ?? controller,
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Ekranlar', () {
    testWidgets('ayarlar ekranı tüm bölümleri gösterir', (tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpScreen(tester, const SettingsScreen());

      expect(find.text('Ayarlar'), findsOneWidget);
      expect(find.text('Görünüm'), findsOneWidget);
      expect(find.text('Oynatma'), findsOneWidget);
      expect(find.text('Seslendirme'), findsOneWidget);
      expect(find.text('Model'), findsWidgets);
      expect(find.text('Veriler'), findsOneWidget);
      expect(find.text('Uygulama'), findsOneWidget);
      expect(find.text('Hakkında'), findsOneWidget);
    });

    testWidgets('geçmiş ekranı boş durumu açıklar', (tester) async {
      await pumpScreen(tester, const HistoryScreen());

      expect(find.text('Geçmiş'), findsOneWidget);
      expect(find.text('Henüz seslendirme yok'), findsOneWidget);
    });

    testWidgets('geçmiş ekranı kayıtları listeler', (tester) async {
      await HistoryStore.save([
        HistoryEntry(
          id: 'test-1',
          text: 'Geçmişte görünecek kısa metin.',
          normalizedText: 'geçmişte görünecek kısa metin.',
          voiceId: 'female_1',
          emotion: SpeechEmotion.neutral,
          durationMs: 2400,
          createdAtMs: DateTime(2026, 11, 7, 10, 30).millisecondsSinceEpoch,
          sizeBytes: 48000,
        ),
      ]);

      final withHistory = TtsController(engine: FakeEngine(), audio: audio);
      await withHistory.initialize();
      addTearDown(withHistory.dispose);

      await pumpScreen(tester, const HistoryScreen(), value: withHistory);

      expect(find.text('Geçmişte görünecek kısa metin.'), findsWidgets);
      expect(find.text('Henüz seslendirme yok'), findsNothing);
      expect(find.text('Temizle'), findsOneWidget);
    });

    testWidgets('hakkında ekranı sürüm ve çevrimdışı bilgisini gösterir', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpScreen(tester, const AboutScreen());

      expect(find.text('Hakkında'), findsOneWidget);
      expect(find.textContaining('Tamamen çevrimdışı'), findsWidgets);
      expect(find.text('Gizlilik'), findsWidgets);
      expect(find.text('Lisanslar'), findsWidgets);
    });

    testWidgets('gizlilik ekranı veri politikasını açıklar', (tester) async {
      await pumpScreen(tester, const PrivacyScreen());

      expect(find.text('Gizlilik'), findsOneWidget);
      expect(find.textContaining('cihazınızdan çıkmaz'), findsWidgets);
    });

    testWidgets('lisanslar ekranı bileşen lisanslarını listeler', (
      tester,
    ) async {
      await pumpScreen(tester, const LicensesScreen());

      expect(find.text('Lisanslar'), findsOneWidget);
      expect(find.textContaining('sherpa-onnx'), findsWidgets);
      expect(find.textContaining('Apache-2.0'), findsWidgets);
      expect(find.textContaining('CC-BY-4.0'), findsWidgets);
    });
  });

  group('Oynatma ve önizleme', () {
    test('seek konumu günceller ve oynatıcıya iletir', () async {
      controller.setText('Seek için kısa metin.');
      await controller.synthesize();
      audio.calls.clear();

      await controller.seekFraction(0.5);

      expect(audio.calls, contains('seek'));
      expect(controller.position, greaterThan(Duration.zero));
      expect(controller.position, lessThan(controller.duration));
    });

    test('durdurma konumu sıfırlar', () async {
      controller.setText('Durdurma için kısa metin.');
      await controller.synthesize();
      await controller.seekFraction(0.5);
      audio.calls.clear();

      await controller.stopPlayback();

      expect(audio.calls, contains('stop'));
      expect(controller.position, Duration.zero);
      expect(controller.isPlaying, isFalse);
    });

    test('ses önizlemesi WAV dosyasını oynatır', () async {
      await controller.togglePreview(VoiceCatalog.byId('female_1'));

      expect(audio.calls, contains('playPreview'));
      expect(controller.previewingVoiceId, 'female_1');

      await controller.togglePreview(VoiceCatalog.byId('female_1'));
      expect(audio.calls, contains('stopPreview'));
      expect(controller.previewingVoiceId, isNull);
    });
  });
}
