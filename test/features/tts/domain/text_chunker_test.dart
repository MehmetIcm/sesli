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
      expect(segments[0].pauseAfterMs, 300);
      expect(segments[1].pauseAfterMs, 340);
      expect(segments[2].pauseAfterMs, 360);
    });

    test('virgül ve iki nokta için daha kısa duraklama verir', () {
      expect(TextChunker.pauseAfter('Merhaba,'), 130);
      expect(TextChunker.pauseAfter('Şöyle:'), 250);
      expect(TextChunker.pauseAfter('Belki;'), 200);
      expect(TextChunker.pauseAfter('Bekle...'), 520);
    });

    test('noktalı virgülü cümle sınırı sayar', () {
      final segments = TextChunker.segments('Bir cümle; ikinci cümle.');
      expect(segments.map((segment) => segment.text).toList(), [
        'Bir cümle;',
        'ikinci cümle.',
      ]);
      expect(segments.first.pauseAfterMs, 200);
    });

    test('uzun cümleyi önce virgülden böler', () {
      final first = List.filled(18, 'kelime').join(' ');
      final second = List.filled(18, 'kelime').join(' ');
      final segments = TextChunker.segments('$first, $second.');

      expect(segments.length, 2);
      expect(segments.first.text.endsWith(','), isTrue);
      expect(segments.last.text.endsWith('.'), isTrue);
      for (final segment in segments) {
        expect(
          segment.text.length,
          lessThanOrEqualTo(TextChunker.defaultMaxChars),
        );
      }
    });

    test('varsayılan sınır modelin cümle sınırını aşmaz', () {
      expect(TextChunker.defaultMaxChars, lessThanOrEqualTo(200));
    });

    test('uzun cümleyi ara nefes payıyla böler', () {
      final text = '${List.filled(30, 'kelime').join(' ')}.';
      final segments = TextChunker.segments(text, maxChars: 40);

      expect(segments.length, greaterThan(1));
      for (final segment in segments.take(segments.length - 1)) {
        expect(segment.pauseAfterMs, 150);
        expect(segment.continuation, isTrue);
      }
      expect(segments.last.pauseAfterMs, 300);
      expect(segments.last.continuation, isFalse);
      for (final segment in segments) {
        expect(segment.text.length, lessThanOrEqualTo(40));
      }
    });
  });
}
