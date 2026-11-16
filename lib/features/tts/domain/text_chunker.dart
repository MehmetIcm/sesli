/// Uzun metinleri modelin rahat işleyebileceği parçalara böler.
///
/// Parçalama cümle sınırlarını korur; tek bir cümle sınırı aşarsa kelime
/// sınırından bölünür. Böylece her istek kısa kalır, ilerleme göstergesi
/// anlamlı olur ve duraklatma istekleri parçalar arasında işlenebilir.
class TextChunker {
  TextChunker._();

  static const int defaultMaxChars = 260;

  /// Cümleleri gruplayarak parçalar üretir (eski davranış).
  static List<String> split(String text, {int maxChars = defaultMaxChars}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return [];

    final sentences = RegExp(r'[^.!?…\n]+[.!?…]*\s*')
        .allMatches(trimmed)
        .map((match) => match.group(0)!.trim())
        .where((sentence) => sentence.isNotEmpty)
        .toList();

    if (sentences.isEmpty) {
      sentences.add(trimmed);
    }

    final chunks = <String>[];
    final current = StringBuffer();

    void flush() {
      final value = current.toString().trim();
      if (value.isNotEmpty) chunks.add(value);
      current.clear();
    }

    for (final sentence in sentences) {
      if (sentence.length > maxChars) {
        flush();
        chunks.addAll(_splitLong(sentence, maxChars));
        continue;
      }

      if (current.isNotEmpty &&
          current.length + sentence.length + 1 > maxChars) {
        flush();
      }

      if (current.isNotEmpty) current.write(' ');
      current.write(sentence);
    }
    flush();

    return chunks;
  }

  /// Cümle bazlı sentez için parçalar üretir.
  ///
  /// Her cümle ayrı bir [SpeechSegment] olur; böylece modelin kendi cümle
  /// sonu duraklaması uygulamanın duraklama politikasıyla çakışmaz.
  /// [maxChars] sınırını aşan cümleler kelime sınırından bölünür ve ara
  /// parçalara kısa bir nefes payı verilir.
  static List<SpeechSegment> segments(
    String text, {
    int maxChars = defaultMaxChars,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return [];

    final result = <SpeechSegment>[];
    final matches = RegExp(r'[^.!?…]+[.!?…]*').allMatches(trimmed);
    for (final match in matches) {
      final sentence = match.group(0)!.trim();
      if (sentence.isEmpty) continue;

      if (sentence.length <= maxChars) {
        result.add(
          SpeechSegment(text: sentence, pauseAfterMs: pauseAfter(sentence)),
        );
        continue;
      }

      final parts = _splitLong(sentence, maxChars);
      for (var i = 0; i < parts.length; i++) {
        final isLast = i == parts.length - 1;
        result.add(
          SpeechSegment(
            text: parts[i],
            pauseAfterMs: isLast ? pauseAfter(sentence) : 150,
            continuation: !isLast,
          ),
        );
      }
    }

    if (result.isEmpty) {
      result.add(
        SpeechSegment(text: trimmed, pauseAfterMs: pauseAfter(trimmed)),
      );
    }
    return result;
  }

  /// Bir cümlenin ardından verilecek doğal nefes payı (ms).
  static int pauseAfter(String text) {
    final value = text.trimRight();
    if (value.isEmpty) return 320;
    if (value.endsWith('...') || value.endsWith('…')) return 600;
    if (value.endsWith('?')) return 430;
    if (value.endsWith('!')) return 390;
    if (value.endsWith('.')) return 360;
    if (value.endsWith(':')) return 280;
    if (value.endsWith(';')) return 230;
    if (value.endsWith(',') || value.endsWith('—') || value.endsWith('–')) {
      return 160;
    }
    return 320;
  }

  static List<String> _splitLong(String sentence, int maxChars) {
    final words = sentence.split(RegExp(r'\s+'));
    final chunks = <String>[];
    final current = StringBuffer();

    void flush() {
      final value = current.toString().trim();
      if (value.isNotEmpty) chunks.add(value);
      current.clear();
    }

    for (final word in words) {
      if (word.isEmpty) continue;
      if (current.isNotEmpty && current.length + word.length + 1 > maxChars) {
        flush();
      }
      if (current.isNotEmpty) current.write(' ');
      current.write(word);
    }
    flush();
    return chunks;
  }
}

/// Tek bir cümle (veya uzun cümlenin bir parçası) ve sonrasındaki duraklama.
class SpeechSegment {
  const SpeechSegment({
    required this.text,
    required this.pauseAfterMs,
    this.continuation = false,
  });

  final String text;
  final int pauseAfterMs;

  /// Uzun bir cümlenin devamı mı? Ara parçalarda kısa nefes payı verilir.
  final bool continuation;

  SpeechSegment copyWith({int? pauseAfterMs}) {
    return SpeechSegment(
      text: text,
      pauseAfterMs: pauseAfterMs ?? this.pauseAfterMs,
      continuation: continuation,
    );
  }
}
