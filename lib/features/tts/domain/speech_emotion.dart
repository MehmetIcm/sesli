import 'package:flutter/material.dart';

/// Pocket TTS Türkçe modelinin desteklediği duygu etiketleri.
///
/// Etiket, seslendirilecek metnin ilk cümlesinin başına köşeli parantez
/// içinde eklenir. `nötr` seçildiğinde etiket eklenmez.
enum SpeechEmotion {
  neutral('Nötr', '', Icons.auto_awesome_outlined),
  calm('Sakin', '[sakin]', Icons.spa_outlined),
  happy('Mutlu', '[mutlu]', Icons.sentiment_very_satisfied_outlined),
  sad('Üzgün', '[üzgün]', Icons.sentiment_dissatisfied_outlined),
  angry('Kızgın', '[kızgın]', Icons.local_fire_department_outlined),
  surprised('Şaşkın', '[şaşkın]', Icons.emoji_emotions_outlined);

  const SpeechEmotion(this.label, this.tag, this.icon);

  final String label;
  final String tag;
  final IconData icon;

  bool get isNeutral => this == SpeechEmotion.neutral;

  static SpeechEmotion byName(String? name) {
    return SpeechEmotion.values.firstWhere(
      (emotion) => emotion.name == name,
      orElse: () => SpeechEmotion.neutral,
    );
  }
}
