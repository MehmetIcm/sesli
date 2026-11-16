import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/speech_emotion.dart';
import 'pocket_tts_params.dart';

/// Kullanıcının kalıcı tercihleri.
class AppSettings {
  const AppSettings({
    this.voiceId = 'female_1',
    this.emotion = SpeechEmotion.neutral,
    this.speed = 1.0,
    this.numSteps = PocketTtsParams.defaultNumSteps,
    this.autoPlay = true,
    this.saveHistory = true,
    this.themeMode = ThemeMode.system,
  });

  final String voiceId;
  final SpeechEmotion emotion;
  final double speed;
  final int numSteps;
  final bool autoPlay;
  final bool saveHistory;
  final ThemeMode themeMode;

  AppSettings copyWith({
    String? voiceId,
    SpeechEmotion? emotion,
    double? speed,
    int? numSteps,
    bool? autoPlay,
    bool? saveHistory,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      voiceId: voiceId ?? this.voiceId,
      emotion: emotion ?? this.emotion,
      speed: speed ?? this.speed,
      numSteps: numSteps ?? this.numSteps,
      autoPlay: autoPlay ?? this.autoPlay,
      saveHistory: saveHistory ?? this.saveHistory,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// SharedPreferences üzerinde ayar okuma/yazma.
class TtsPreferences {
  TtsPreferences._();

  static const _voiceKey = 'settings.voiceId';
  static const _emotionKey = 'settings.emotion';
  static const _speedKey = 'settings.speed';
  static const _stepsKey = 'settings.numSteps';
  static const _autoPlayKey = 'settings.autoPlay';
  static const _historyKey = 'settings.saveHistory';
  static const _themeKey = 'settings.themeMode';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);
    return AppSettings(
      voiceId: prefs.getString(_voiceKey) ?? 'female_1',
      emotion: SpeechEmotion.byName(prefs.getString(_emotionKey)),
      speed: (prefs.getDouble(_speedKey) ?? 1.0).clamp(0.7, 1.3).toDouble(),
      numSteps: (prefs.getInt(_stepsKey) ?? PocketTtsParams.defaultNumSteps)
          .clamp(2, 8)
          .toInt(),
      autoPlay: prefs.getBool(_autoPlayKey) ?? true,
      saveHistory: prefs.getBool(_historyKey) ?? true,
      themeMode: switch (themeName) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
    );
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_voiceKey, settings.voiceId),
      prefs.setString(_emotionKey, settings.emotion.name),
      prefs.setDouble(_speedKey, settings.speed),
      prefs.setInt(_stepsKey, settings.numSteps),
      prefs.setBool(_autoPlayKey, settings.autoPlay),
      prefs.setBool(_historyKey, settings.saveHistory),
      prefs.setString(_themeKey, switch (settings.themeMode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      }),
    ]);
  }
}
