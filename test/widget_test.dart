import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turkce_ses/app.dart';
import 'package:turkce_ses/features/tts/presentation/tts_controller.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TtsController> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = TtsController(engine: FakeEngine(), audio: FakeAudio());
    await tester.runAsync(controller.initialize);

    await tester.pumpWidget(
      ChangeNotifierProvider<TtsController>.value(
        value: controller,
        child: const SesliApp(),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('uygulama Türkçe ana ekranıyla açılır', (tester) async {
    final controller = await pumpApp(tester);

    expect(find.text('Sesli'), findsWidgets);
    expect(find.text('Metniniz, doğal Türkçe sesle.'), findsWidgets);
    expect(find.text('Seslendir'), findsWidgets);
    expect(controller.engineStatus, EngineStatus.ready);
  });

  testWidgets('metin girildiğinde seslendirme düğmesi etkinleşir', (
    tester,
  ) async {
    final controller = await pumpApp(tester);

    expect(controller.canSynthesize, isFalse);
    await tester.enterText(find.byType(TextField).first, 'Merhaba dünya.');
    await tester.pump();

    expect(controller.canSynthesize, isTrue);
  });

  testWidgets('tema düğmesi karanlık ve aydınlık arasında geçiş yapar', (
    tester,
  ) async {
    final controller = await pumpApp(tester);

    final initial = controller.themeMode;
    await tester.tap(find.byIcon(Icons.dark_mode_outlined).first);
    await tester.pumpAndSettle();

    expect(controller.themeMode, isNot(initial));
  });
}
