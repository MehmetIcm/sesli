import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/tts/presentation/tts_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider<TtsController>(
      create: (_) => TtsController()..initialize(),
      child: const SesliApp(),
    ),
  );
}
