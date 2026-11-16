import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/speech_emotion.dart';

/// Geçmişteki bir seslendirme kaydı. Ses verisi saklanmaz; yalnızca metin
/// ve üst veriler tutulur.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.text,
    required this.normalizedText,
    required this.voiceId,
    required this.emotion,
    required this.durationMs,
    required this.createdAtMs,
    required this.sizeBytes,
  });

  final String id;
  final String text;
  final String normalizedText;
  final String voiceId;
  final SpeechEmotion emotion;
  final int durationMs;
  final int createdAtMs;
  final int sizeBytes;

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'normalizedText': normalizedText,
    'voiceId': voiceId,
    'emotion': emotion.name,
    'durationMs': durationMs,
    'createdAtMs': createdAtMs,
    'sizeBytes': sizeBytes,
  };

  static HistoryEntry fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      normalizedText: json['normalizedText'] as String? ?? '',
      voiceId: json['voiceId'] as String? ?? 'female_1',
      emotion: SpeechEmotion.byName(json['emotion'] as String?),
      durationMs: json['durationMs'] as int? ?? 0,
      createdAtMs: json['createdAtMs'] as int? ?? 0,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
    );
  }
}

/// Geçmişi cihazda (web'de localStorage) saklar.
class HistoryStore {
  HistoryStore._();

  static const String _key = 'history.v1';
  static const int maxEntries = 40;

  static Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(HistoryEntry.fromJson)
          .where((entry) => entry.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = entries.take(maxEntries).toList();
    await prefs.setString(
      _key,
      jsonEncode(trimmed.map((entry) => entry.toJson()).toList()),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
