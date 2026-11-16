import 'package:flutter_test/flutter_test.dart';
import 'package:turkce_ses/features/tts/domain/english_transliterator.dart';
import 'package:turkce_ses/features/tts/domain/turkish_text_normalizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const normalizer = TurkishTextNormalizer();

  setUpAll(() async {
    await EnglishTransliterator.instance.ensureLoaded();
  });

  group('İngilizce kelimeler Türkçe sesletime çevrilir', () {
    const cases = <String, String>{
      'webcam': 'vebkem',
      'Webcam': 'vebkem',
      'update': 'apdeyt',
      'online': 'onlayn',
      'download': 'daunloud',
      'browser': 'brauzır',
      'WhatsApp': 'vatsap',
      'YouTube': 'yutub',
      'software': 'softveır',
      'keyboard': 'kibord',
      'message': 'mesic',
      'image': 'imic',
      'package': 'pekic',
      'language': 'lenguic',
      'manage': 'menic',
      'computer': 'kompyutır',
      'cache': 'keş',
      'file': 'fayl',
      'backend': 'bekend',
      'frontend': 'frantend',
      'blockchain': 'blokçeyn',
      'ethereum': 'eteryum',
      'startup': 'startap',
      'typescript': 'taypskript',
      'javascript': 'cavaskript',
      'kubernetes': 'kubernitis',
      'Cambridge': 'kembriç',
      'cambridge': 'kembriç',
      'Cambrigde': 'kembriç',
    };

    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value}', () {
        expect(normalizer.normalize(entry.key), entry.value);
      });
    }
  });

  group('Yabancı yer ve marka adları Türkçe sesletimle okunur', () {
    const cases = <String, String>{
      'Oxford': 'oksford',
      'Google': 'gugıl',
      'Amazon': 'amazın',
      'Microsoft': 'maykrosoft',
      'Windows': 'vindouz',
      'iPhone': 'ayfon',
      'Samsung': 'samsung',
      'LinkedIn': 'linkdın',
      'Netflix': 'netfliks',
      'Spotify': 'spotifay',
      'Starbucks': 'starbaks',
    };

    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value}', () {
        expect(normalizer.normalize(entry.key), entry.value);
      });
    }

    test('cümle içinde Cambridge', () {
      expect(
        normalizer.normalize('Cambridge Üniversitesi çok eski.'),
        'kembriç üniversitesi çok eski.',
      );
    });
  });

  group('Kısaltmalar ve teknoloji etiketleri', () {
    const cases = <String, String>{
      'MP3': 'em pi üç',
      'B12': 'be on iki',
      '5G': 'beş ge',
      '3D': 'üç di',
      'chatgpt': 'çet ci pi ti',
      'openai': 'oupın ey ay',
    };

    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value}', () {
        expect(normalizer.normalize(entry.key), entry.value);
      });
    }
  });

  group('Türkçe ekler korunur', () {
    test('apostroflu ek', () {
      expect(normalizer.normalize("webcam'den"), 'vebkemden');
    });

    test('apostrofsuz ek', () {
      expect(normalizer.normalize('webcamden'), 'vebkemden');
    });
  });

  group('Karışık cümleler', () {
    test('Türkçe cümle içindeki İngilizce kelime', () {
      expect(normalizer.normalize('Bu webcam çok iyi.'), 'bu vebkem çok iyi.');
    });

    test('tamamen İngilizce cümle', () {
      expect(
        normalizer.normalize('The webcam is very good.'),
        'dı vebkem is veri gud.',
      );
    });

    test('Türkçe cümledeki İngilizce marka adı', () {
      expect(normalizer.normalize('Yarın meeting var.'), 'yarın miting var.');
    });
  });

  group('Türkçe kelimeler yanlışlıkla İngilizce okunmaz', () {
    const turkishWords = [
      'site',
      'ithal',
      'müthiş',
      'ishal',
      'reaksiyon',
      'koalisyon',
      'organize',
      'realite',
      'teatral',
      'kooperatif',
      'model',
      'normal',
      'test',
    ];

    for (final word in turkishWords) {
      test(word, () {
        expect(normalizer.normalize(word), word);
      });
    }
  });

  test('sözlük yüklendiğinde yüz binlerce kelime içerir', () {
    expect(EnglishTransliterator.instance.isLoaded, isTrue);
  });
}
