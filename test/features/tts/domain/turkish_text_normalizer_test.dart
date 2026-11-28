import 'package:flutter_test/flutter_test.dart';
import 'package:turkce_ses/features/tts/domain/english_transliterator.dart';
import 'package:turkce_ses/features/tts/domain/turkish_text_normalizer.dart';

void main() {
  const normalizer = TurkishTextNormalizer();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EnglishTransliterator.instance.ensureLoaded();
  });

  String normalize(String input) => normalizer.normalize(input);

  group('TurkishTextNormalizer', () {
    test('boş ve boşluk metinlerini temizler', () {
      expect(normalize(''), '');
      expect(normalize('   '), '');
      expect(normalize('  Merhaba   dünya  '), 'merhaba dünya');
    });

    test('tam sayıları Türkçe okunuşa çevirir', () {
      expect(normalize('0'), 'sıfır');
      expect(normalize('7'), 'yedi');
      expect(normalize('42'), 'kırk iki');
      expect(normalize('100'), 'yüz');
      expect(normalize('1000'), 'bin');
      expect(normalize('2026'), 'iki bin yirmi altı');
      expect(normalize('1000000'), 'bir milyon');
    });

    test('ondalık ve binlik ayırıcılarını ayırt eder', () {
      expect(normalize('3,5'), 'üç virgül beş');
      expect(normalize('0,5'), 'sıfır virgül beş');
      expect(normalize('3.5'), 'üç virgül beş');
      expect(normalize('1.250'), 'bin iki yüz elli');
      expect(normalize('1.250,75'), 'bin iki yüz elli virgül yetmiş beş');
    });

    test('tarihleri ay adlarıyla okur', () {
      expect(normalize('14.03.2026'), 'on dört mart iki bin yirmi altı');
      expect(normalize('2026-03-14'), 'on dört mart iki bin yirmi altı');
      expect(normalize('1.9.2026'), 'bir eylül iki bin yirmi altı');
    });

    test('saatleri okur', () {
      expect(normalize('09:30'), 'saat dokuz otuz');
      expect(normalize('5:05'), 'saat beş sıfır beş');
      expect(normalize('12.00'), 'saat on iki');
      expect(normalize('23:59'), 'saat yirmi üç elli dokuz');
    });

    test('para birimlerini okur', () {
      expect(normalize('25 TL'), 'yirmi beş lira');
      expect(
        normalize('1.250,75 TL'),
        'bin iki yüz elli lira, yetmiş beş kuruş',
      );
      expect(normalize('₺25'), 'yirmi beş lira');
      expect(normalize('\$10'), 'on dolar');
    });

    test('para birimine bağlanan eki tutara ekler', () {
      expect(normalize("100 TL'lik"), 'yüz liralık');
      expect(
        normalize("1.234.567,89 TL'lik"),
        'bir milyon iki yüz otuz dört bin beş yüz altmış yedi lira, '
        'seksen dokuz kuruşluk',
      );
      expect(normalize("10 €'luk"), 'on euroluk');
      expect(normalize(r"$250'lik"), r'iki yüz elli dolarlık');
    });

    test('yüzdeleri okur', () {
      expect(normalize('%25'), 'yüzde yirmi beş');
      expect(normalize('25%'), 'yüzde yirmi beş');
      expect(normalize('oran %3,5'), 'oran yüzde üç virgül beş');
    });

    test('telefon numaralarını grup grup okur', () {
      expect(
        normalize('0555 123 45 67'),
        'sıfır beş yüz elli beş, yüz yirmi üç, kırk beş, altmış yedi',
      );
      expect(
        normalize('+90 555 123 45 67'),
        'artı doksan, beş yüz elli beş, yüz yirmi üç, kırk beş, '
        'altmış yedi',
      );
      expect(
        normalize('05551234567'),
        'sıfır beş yüz elli beş, yüz yirmi üç, kırk beş, altmış yedi',
      );
      expect(
        normalize('5551234567'),
        'beş yüz elli beş, yüz yirmi üç, kırk beş, altmış yedi',
      );
    });

    test('kesirleri Türkçe okunuşa çevirir', () {
      expect(normalize('3/4'), 'dörtte üç');
      expect(normalize('1/2'), 'yarım');
      expect(normalize('1/4'), 'çeyrek');
      expect(normalize('2/3'), 'üçte iki');
      expect(normalize('5/8'), 'sekizde beş');
    });

    test('sayı aralıklarını "ile" ile okur', () {
      expect(normalize('10-15'), 'on ile on beş');
      expect(normalize('10–15'), 'on ile on beş');
      expect(normalize('1.250-1.500'), 'bin iki yüz elli ile bin beş yüz');
    });

    test('Romen rakamlarını sıra sayısı olarak okur', () {
      expect(normalize('XVI. yüzyıl'), 'on altıncı yüzyıl');
      expect(normalize('II. Dünya Savaşı'), 'ikinci dünya savaşı');
    });

    test('matematik sembollerini okur', () {
      expect(normalize('5 ≥ 3'), 'beş büyük veya eşit üç');
      expect(normalize('5 ≤ 3'), 'beş küçük veya eşit üç');
      expect(normalize('5 ≠ 3'), 'beş eşit değil üç');
      expect(normalize('5 ± 2'), 'beş artı eksi iki');
      expect(normalize('7 > 3'), 'yedi büyüktür üç');
      expect(normalize('3 < 7'), 'üç küçüktür yedi');
    });

    test('HTML etiketlerini ve tekrarlanan kelimeleri temizler', () {
      expect(normalize('<b>Merhaba</b> dünya'), 'merhaba dünya');
      expect(normalize('çok çok çok güzel'), 'çok güzel');
      expect(normalize('test test test'), 'test');
    });

    test('e-posta adreslerini okur', () {
      expect(
        normalize('ali.veli@example.com'),
        'ali nokta veli et eksample nokta com',
      );
    });

    test('ölçü birimlerini ve kısaltmaları açar', () {
      expect(normalize('120 km/s'), 'yüz yirmi kilometre bölü saat');
      expect(normalize('5 kg'), 'beş kilogram');
      expect(normalize('24 kHz'), 'yirmi dört kilohertz');
      expect(normalize('128 kbps'), 'yüz yirmi sekiz kilobit bölü saniye');
      expect(normalize('23°C'), 'yirmi üç santigrat derece');
      expect(normalize('23° C'), 'yirmi üç santigrat derece');
      expect(
        normalize('Prof. Dr. Ayşe Yılmaz Cad. No. 5'),
        'profesör doktor ayşe yılmaz cadde numara beş',
      );
      expect(
        normalize('ABD ve TBMM'),
        'amerika birleşik devletleri ve türkiye büyük millet meclisi',
      );
    });

    test('sıra sayılarını okur', () {
      expect(normalize('1. sıra'), 'birinci sıra');
      expect(normalize('2. sıra'), 'ikinci sıra');
      expect(normalize('4. sıra'), 'dördüncü sıra');
      expect(
        normalize('1., 2. ve 4. sıradaki'),
        'birinci, ikinci ve dördüncü sıradaki',
      );
    });

    test('kesme işaretli sayı eklerini birleştirir', () {
      expect(normalize("2026'da"), 'iki bin yirmi altıda');
      expect(normalize('5\'te'), 'beşte');
    });

    test('cümle sonundaki noktayı sıra sayısı sanmaz', () {
      expect(normalize('Yarın 25.'), 'yarın yirmi beş.');
    });

    test('Türkçe küçük harfe çevirir', () {
      expect(normalize('İSTANBUL IĞDIR'), 'istanbul ığdır');
    });

    test('harfe bitişik rakamları ve model dışı harfleri okur', () {
      expect(normalize('MP3'), 'em pi üç');
      expect(normalize('B12 vitamini'), 'be on iki vitamini');
      expect(normalize('5G'), 'beş ge');
      expect(normalize('3D'), 'üç di');
      expect(normalize('WhatsApp'), 'vatsap');
      expect(normalize('taxi'), 'taksi');
      expect(normalize('q'), 'k');
    });

    test('model sözlüğünde olmayan sembolleri ve emojiyi temizler', () {
      expect(normalize('#etiket'), 'diyez etiket');
      expect(normalize('@kullanici'), 'et kullanici');
      expect(normalize('Merhaba 😀'), 'merhaba');
      expect(normalize('a\nb'), 'a b');
      expect(normalize('a & b'), 'a ve b');
      expect(normalize('50 %'), 'yüzde elli');
    });

    test('e-postadaki rakamları tek tek okur', () {
      expect(
        normalize('user123@example.com'),
        'yuzır bir iki üç et eksample nokta com',
      );
    });

    test('örnek metinlerde rakam ve model dışı karakter bırakmaz', () {
      const samples = [
        'Merhaba! Bugün 6 Kasım 2026, saat 14.30. Hava 18°C ve hafif '
            'yağmurlu. Saat 19.00\'da arkadaşlarımla buluşacağım. '
            'Yolculuk yaklaşık 25 dakika sürecek.',
        'Türkiye Büyük Millet Meclisi\'nde yeni yasa tasarısı kabul edildi. '
            'Bakanlık, 2027 yılı için 1.250.000 TL\'lik yatırım planını '
            'açıkladı. Projenin yüzde 65\'i tamamlandı; kalan kısmın '
            'gelecek yıl bitirilmesi bekleniyor.',
        'Sesli, 24 kHz örnekleme hızında çalışan bir Pocket TTS modeli '
            'kullanır. Model tamamen cihaz üzerinde çalışır; metinler '
            'sunucuya gönderilmez. Çıktı, 44,1 kHz ve 128 kbps mono MP3 '
            'olarak kaydedilir.',
      ];

      for (final sample in samples) {
        final result = normalize(sample);
        expect(
          RegExp(r'\d').hasMatch(result),
          isFalse,
          reason: 'Rakam kaldı: $result',
        );
        expect(
          RegExp(r'''[^a-zçğıöşüâîû ,.!?;:'"\-]''').hasMatch(result),
          isFalse,
          reason: 'Model dışı karakter kaldı: $result',
        );
      }
    });

    test('modelin yanlış seslendirdiği kelimeleri okunuş karşılığıyla verir', () {
      expect(normalize("Québec'e"), 'kebeke');
      expect(
        normalize('yapay zekâ, nöroloji, psikoloji ve senkronizasyon üzerine'),
        'yapay zekâ, nöroloji, psikoloji ve eşgüdüm üzerine',
      );
      expect(
        normalize('mükemmel sonuçlanabilecek miydi?'),
        'mükemmel sonuçlanır mıydı?',
      );
    });

    test('kullanıcı stres metnini yutulmuş kelime bırakmadan okur', () {
      const text =
          "Bir günlüğüne 1.234.567,89 TL'lik bütçeyle Zürih'ten Québec'e, "
          "oradan da Johannesburg'a uçacak olan mühendis; yapay zekâ, "
          'nöroloji, psikoloji ve senkronizasyon üzerine şaşırtıcı derecede '
          'karmaşık bir sunum hazırlamıştı. Peki, 29 Şubat 2028 Salı günü '
          "saat 23.59'da başlayan bu olağanüstü yolculuk, gerçekten "
          'düşünüldüğü kadar mükemmel sonuçlanabilecek miydi?';

      final result = normalize(text);

      expect(result, contains('yedi lira, seksen dokuz kuruşluk bütçeyle'));
      expect(result, isNot(contains("'lik")));
      expect(result, contains('kebeke'));
      expect(result, contains('eşgüdüm üzerine'));
      expect(result, contains('sonuçlanır mıydı?'));
      expect(RegExp(r'\d').hasMatch(result), isFalse);
    });

    test('orijinal metni değiştirmez', () {
      const original = '2026 yılında 3.5 milyar TL bütçe ayrıldı.';
      normalize(original);
      expect(original, '2026 yılında 3.5 milyar TL bütçe ayrıldı.');
    });
  });
}
