import 'package:flutter_test/flutter_test.dart';
import 'package:turkce_ses/features/tts/domain/text_chunker.dart';

void main() {
  group('TextChunker', () {
    test('boş metin için parça üretmez', () {
      expect(TextChunker.split(''), isEmpty);
      expect(TextChunker.split('   \n '), isEmpty);
    });

    test('kısa metni tek parça olarak döndürür', () {
      expect(TextChunker.split('Merhaba dünya.'), ['Merhaba dünya.']);
    });

    test('cümle sınırlarını korur', () {
      final chunks = TextChunker.split(
        'Birinci cümle. İkinci cümle! Üçüncü cümle?',
        maxChars: 20,
      );
      expect(chunks, ['Birinci cümle.', 'İkinci cümle!', 'Üçüncü cümle?']);
    });

    test('uzun cümleyi kelime sınırından böler', () {
      final text = List.filled(30, 'kelime').join(' ');
      final chunks = TextChunker.split(text, maxChars: 40);

      expect(chunks.length, greaterThan(1));
      for (final chunk in chunks) {
        expect(chunk.length, lessThanOrEqualTo(40));
        expect(chunk.trim(), chunk);
      }
      expect(chunks.join(' ').split(' ').length, 30);
    });

    test('parçalar birleşince metin korunur', () {
      const text =
          'Bu uzun bir metindir. Birden fazla cümle içerir. Her cümle kendi '
          'içinde anlamlıdır. Parçalama işlemi bu anlamı bozmamalıdır.';
      final chunks = TextChunker.split(text, maxChars: 45);
      expect(chunks.join(' '), text);
      for (final chunk in chunks) {
        expect(chunk.length, lessThanOrEqualTo(45));
      }
    });

    test('her cümleyi ayrı parça ve duraklama olarak döndürür', () {
      final segments = TextChunker.segments(
        'Birinci cümle. İkinci cümle! Üçüncü cümle?',
      );

      expect(segments.map((segment) => segment.text).toList(), [
        'Birinci cümle.',
        'İkinci cümle!',
        'Üçüncü cümle?',
      ]);
      expect(segments[0].pauseAfterMs, 360);
      expect(segments[1].pauseAfterMs, 390);
      expect(segments[2].pauseAfterMs, 430);
    });

    test('virgül ve iki nokta için daha kısa duraklama verir', () {
      expect(TextChunker.pauseAfter('Merhaba,'), 160);
      expect(TextChunker.pauseAfter('Şöyle:'), 280);
      expect(TextChunker.pauseAfter('Belki;'), 230);
      expect(TextChunker.pauseAfter('Bekle...'), 600);
    });

    test('uzun cümleyi ara nefes payıyla böler', () {
      final text = '${List.filled(30, 'kelime').join(' ')}.';
      final segments = TextChunker.segments(text, maxChars: 40);

      expect(segments.length, greaterThan(1));
      for (final segment in segments.take(segments.length - 1)) {
        expect(segment.pauseAfterMs, 150);
        expect(segment.continuation, isTrue);
      }
      expect(segments.last.pauseAfterMs, 360);
      expect(segments.last.continuation, isFalse);
      for (final segment in segments) {
        expect(segment.text.length, lessThanOrEqualTo(40));
      }
    });
  });
}
