/// Türkçe metin normalizasyonu.
///
/// Orijinal kullanıcı metni **değiştirilmez**; seslendirme için ayrı bir
/// metin üretilir. Sayılar, tarihler, saatler, para birimleri, yüzdeler,
/// ölçü birimleri, kısaltmalar, telefon numaraları ve e-posta adresleri
/// doğal Türkçe okunuşa çevrilir.
library;

import 'english_transliterator.dart';

class TurkishTextNormalizer {
  const TurkishTextNormalizer({this.english});

  /// Testlerde özel bir çevirici enjekte etmek için kullanılabilir.
  final EnglishTransliterator? english;

  EnglishTransliterator get _transliterator =>
      english ?? EnglishTransliterator.instance;

  static const List<String> _ones = [
    '',
    'bir',
    'iki',
    'üç',
    'dört',
    'beş',
    'altı',
    'yedi',
    'sekiz',
    'dokuz',
  ];
  static const List<String> _tens = [
    '',
    'on',
    'yirmi',
    'otuz',
    'kırk',
    'elli',
    'altmış',
    'yetmiş',
    'seksen',
    'doksan',
  ];
  static const List<String> _scales = [
    '',
    'bin',
    'milyon',
    'milyar',
    'trilyon',
    'katrilyon',
  ];
  static const List<String> _months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static const String _protectedOpen = '\uE000';
  static const String _protectedClose = '\uE001';

  /// Metni seslendirmeye hazır hâle getirir.
  String normalize(String input) {
    var text = input.trim();
    if (text.isEmpty) return '';

    text = text
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u2007', ' ')
        .replaceAll('\u202F', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ');

    final protected = <String, String>{};
    var counter = 0;
    String protect(String value) {
      final key = '$_protectedOpen${_alphaId(counter++)}$_protectedClose';
      protected[key] = value;
      return key;
    }

    // 0. HTML etiketlerini ve satır sonlarını temizle.
    text = text
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\r\n?'), '\n');

    // 1. Bağlantılar ve e-posta adresleri.
    text = text.replaceAllMapped(
      RegExp(r'https?://\S+|www\.\S+', caseSensitive: false),
      (m) => protect('bağlantı'),
    );
    text = text.replaceAllMapped(
      RegExp(r'[\w.+\-]+@[\w\-]+(?:\.[\w\-]+)+'),
      (m) => protect(_spellEmail(m.group(0)!)),
    );

    // 2. Ölçü birimleri, kısaltmalar ve semboller.
    text = _replaceUnits(text);
    text = _replaceAbbreviations(text);

    // 3. Tarih ve saatler (sayılardan önce).
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b'),
      (m) => _date(m.group(1)!, m.group(2)!, m.group(3)!),
    );
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{1,2})[./](\d{1,2})[./](\d{2,4})\b'),
      (m) => _date(m.group(3)!, m.group(2)!, m.group(1)!),
    );
    text = text.replaceAllMapped(
      RegExp(
        r'\b(?:saat\s*)?([01]?\d|2[0-3])[:.](\d{2})\b',
        caseSensitive: false,
      ),
      (m) => _time(int.parse(m.group(1)!), int.parse(m.group(2)!)),
    );

    // 4. Telefon numaraları: grup grup oku. Model tekrarlanan rakamlarda
    //    döngüye girebildiği için "0555 123 45 67" tek tek değil,
    //    "sıfır beş yüz elli beş, yüz yirmi üç, ..." biçiminde okunur.
    text = _replacePhoneNumbers(text);

    // 5. Kesirler ve aralıklar (telefonlardan sonra).
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{1,3})\s*/\s*(\d{1,3})\b'),
      (m) => _fraction(int.parse(m.group(1)!), int.parse(m.group(2)!)),
    );
    text = text.replaceAllMapped(
      RegExp(r'\b(\d[\d.,]*)\s*[-–]\s*(\d[\d.,]*)\b'),
      (m) => '${_numberWords(m.group(1)!)} ile ${_numberWords(m.group(2)!)}',
    );

    // 6. Para birimleri ve yüzdeler.
    text = _replaceCurrency(text);
    text = text.replaceAllMapped(
      RegExp(r'%\s*(\d[\d.,]*)'),
      (m) => 'yüzde ${_numberWords(m.group(1)!)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'(\d[\d.,]*)\s*%'),
      (m) => 'yüzde ${_numberWords(m.group(1)!)}',
    );

    // 7. Kesme işaretli sayı ekleri: 2026'da -> iki bin yirmi altıda
    text = text.replaceAllMapped(
      RegExp(r"(\d[\d.,]*)['’]([a-zçğıöşü]+)", caseSensitive: false),
      (m) => _numberWithSuffix(m.group(1)!, m.group(2)!),
    );

    // 8. Romen rakamları: XVI. yüzyıl -> on altıncı yüzyıl.
    text = text.replaceAllMapped(
      RegExp(r'\b([IVXLCDM]{1,7})\.(?=\s+[A-Za-zÇĞİÖŞÜçğıöşü])'),
      (m) {
        final value = _romanToInt(m.group(1)!);
        return value == null ? m.group(0)! : _ordinal(value);
      },
    );

    // 9. Kalan sayılar: sıra sayıları, ondalıklar, binlikler.
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{1,2})\.(?=\s+[a-zçğıöşü]|[,;:])', caseSensitive: false),
      (m) => _ordinal(int.parse(m.group(1)!)),
    );
    text = text.replaceAllMapped(
      RegExp(r'\b(?:\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+,\d+|\d+\.\d+|\d+)\b'),
      (m) => _numberWords(m.group(0)!),
    );

    // 10. Korunan parçaları geri koy.
    for (final entry in protected.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    // 11. Noktalama ve boşluk temizliği.
    text = text
        .replaceAll('…', '...')
        .replaceAll('—', ', ')
        .replaceAll('–', ', ')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll(RegExp(r'[()\[\]{}]'), ' ')
        .replaceAllMapped(RegExp(r'\s+([,.;:!?])'), (m) => m.group(1)!)
        .replaceAllMapped(
          RegExp(r'([,.;:!?])(?=[^\s\d])'),
          (m) => '${m.group(1)} ',
        )
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    text = turkishLowercase(text);

    // 12. Aynı kelimenin üç ve daha fazla tekrarını birleştir. Model
    //     tekrarlanan kelimelerde döngüye girebiliyor.
    text = _mergeRepeats(text);

    // 13. İngilizce kelimeleri Türkçe sesletime çevir. Bu adım, q/w/x gibi
    //     harfler temizlenmeden önce yapılmalıdır; aksi hâlde "webcam"
    //     "vebcam" olarak kalır.
    text = _transliterator.transliterate(text);

    // 14. Model sözlüğünde bulunmayan karakterleri ve kalan rakamları
    //     temizle. Pocket TTS'in SentencePiece sözlüğünde rakam, q/w/x ve
    //     birçok sembol yoktur; bunlardan biri metinde kalırsa model hiç
    //     token üretemez ve seslendirme başarısız olur.
    text = _sanitizeForModel(text);

    // 15. Kesme işaretini kelime içinde kaldır.
    text = text.replaceAll(
      RegExp(r"(?<=[a-zçğıöşüâîû])['’](?=[a-zçğıöşüâîû])"),
      '',
    );
    return text;
  }

  /// Modelin SentencePiece sözlüğünde bulunmayan karakterleri temizler.
  ///
  /// Pocket TTS Türkçe sözlüğünde rakamlar, q/w/x harfleri ve çoğu sembol
  /// yoktur. Metinde bunlardan biri kalırsa tokenizer sıfır token üretir ve
  /// model hata verir. Bu yüzden kalan her şey okunabilir Türkçeye çevrilir.
  String _sanitizeForModel(String text) {
    var result = text;

    // Türkçe alfabesinde bulunmayan Latin harfleri.
    const letterMap = <String, String>{
      'wh': 'v',
      'q': 'k',
      'w': 'v',
      'x': 'ks',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'å': 'a',
      'ã': 'a',
      'æ': 'ae',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ø': 'o',
      'œ': 'oe',
      'ú': 'u',
      'ù': 'u',
      'ñ': 'n',
      'ß': 'ss',
    };
    for (final entry in letterMap.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Sembolleri okunabilir karşılıklarına çevir.
    const symbolMap = <String, String>{
      '#': ' diyez ',
      '@': ' et ',
      '%': ' yüzde ',
      '&': ' ve ',
      '+': ' artı ',
      '=': ' eşittir ',
      '/': ' bölü ',
      '×': ' çarpı ',
      '÷': ' bölü ',
      '°': ' derece ',
      '₺': ' lira ',
      '\$': ' dolar ',
      '€': ' euro ',
      '£': ' sterlin ',
      '_': ' alt çizgi ',
      '~': ' yaklaşık ',
      '*': ' yıldız ',
      '|': ' dikey çizgi ',
      '\\': ' ters bölü ',
      '^': ' şapka ',
      '<': ' küçük ',
      '>': ' büyük ',
    };
    for (final entry in symbolMap.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Harf ile rakam bitişikse ayır: MP3 -> MP 3, B12 -> B 12.
    result = result
        .replaceAllMapped(
          RegExp(r'([a-zçğıöşüâîû])(\d)'),
          (m) => '${m.group(1)} ${m.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'(\d)([a-zçğıöşüâîû])'),
          (m) => '${m.group(1)} ${m.group(2)}',
        );

    // Kalan rakamları Türkçe okunuşa çevir.
    result = result.replaceAllMapped(RegExp(r'\d+'), (m) {
      final raw = m.group(0)!;
      final value = raw.length <= 15 ? int.tryParse(raw) : null;
      return value == null ? _digitsIndividually(raw) : _intWords(value);
    });

    // Model sözlüğünde bulunan karakterler dışındakileri boşluğa çevir.
    result = result.replaceAll(RegExp(r'''[^a-zçğıöşüâîû ,.!?;:'"\-]'''), ' ');

    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ── Sayılar ────────────────────────────────────────────────────────────

  String _numberWords(String raw) {
    final token = raw.replaceAll('\u00A0', '').trim();
    if (token.isEmpty) return token;

    if (token.contains(',')) {
      final index = token.lastIndexOf(',');
      final major = token.substring(0, index).replaceAll('.', '');
      final minor = token.substring(index + 1);
      if (minor.isEmpty) return _intWords(_parseInt(major));
      final minorWords = minor.startsWith('0')
          ? _digitsIndividually(minor)
          : _intWords(_parseInt(minor));
      return '${_intWords(_parseInt(major))} virgül $minorWords';
    }

    if (token.contains('.')) {
      final parts = token.split('.');
      final isThousands =
          parts.length > 1 &&
          parts.skip(1).every((p) => p.length == 3) &&
          parts.first.length <= 3;
      if (isThousands) {
        return _intWords(_parseInt(parts.join()));
      }
      final index = token.indexOf('.');
      final major = token.substring(0, index);
      final minor = token.substring(index + 1);
      if (minor.isEmpty) return _intWords(_parseInt(major));
      final minorWords = minor.startsWith('0')
          ? _digitsIndividually(minor)
          : _intWords(_parseInt(minor));
      return '${_intWords(_parseInt(major))} virgül $minorWords';
    }

    return _intWords(_parseInt(token));
  }

  String _numberWithSuffix(String rawNumber, String suffix) {
    final words = _numberWords(rawNumber);
    final lastWord = words.split(' ').last;
    final endsWithVowel = _isVowel(lastWord.runes.last);
    final suffixStartsVowel = _isVowel(suffix.runes.first);
    final buffer = endsWithVowel && suffixStartsVowel ? 'y' : '';
    return '$words$buffer$suffix';
  }

  int _parseInt(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return int.tryParse(cleaned) ?? 0;
  }

  String _intWords(int n) {
    if (n == 0) return 'sıfır';
    if (n < 0) return 'eksi ${_intWords(-n)}';

    final groups = <int>[];
    var rest = n;
    while (rest > 0) {
      groups.add(rest % 1000);
      rest ~/= 1000;
    }

    final parts = <String>[];
    for (var i = groups.length - 1; i >= 0; i--) {
      final group = groups[i];
      if (group == 0) continue;
      if (i == 1 && group == 1) {
        parts.add('bin');
        continue;
      }
      final words = _threeDigits(group);
      final scale = i < _scales.length ? _scales[i] : '';
      parts.add(scale.isEmpty ? words : '$words $scale');
    }
    return parts.join(' ');
  }

  String _threeDigits(int n) {
    final hundreds = n ~/ 100;
    final tens = (n % 100) ~/ 10;
    final ones = n % 10;
    final parts = <String>[];
    if (hundreds > 0) {
      if (hundreds > 1) parts.add(_ones[hundreds]);
      parts.add('yüz');
    }
    if (tens > 0) parts.add(_tens[tens]);
    if (ones > 0) parts.add(_ones[ones]);
    return parts.join(' ');
  }

  String _digitsIndividually(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final digit = int.tryParse(char);
      if (digit == null) {
        buffer.write(' ');
        continue;
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(_ones[digit].isEmpty ? 'sıfır' : _ones[digit]);
    }
    return buffer.toString().trim();
  }

  /// Kesirleri Türkçe okunuşa çevirir: 3/4 -> dörtte üç.
  String _fraction(int numerator, int denominator) {
    if (denominator == 0) {
      return '${_intWords(numerator)} bölü sıfır';
    }
    if (numerator == 1 && denominator == 2) return 'yarım';
    if (numerator == 1 && denominator == 4) return 'çeyrek';
    if (numerator == 3 && denominator == 4) return 'dörtte üç';
    return '${_locative(denominator)} ${_intWords(numerator)}';
  }

  /// Sayıyı bulunma hâline çevirir: dört -> dörtte, sekiz -> sekizde.
  String _locative(int n) {
    final words = _intWords(n);
    final lastWord = words.split(' ').last;
    final lastChar = lastWord[lastWord.length - 1];
    final vowel = _lastVowel(lastWord);
    final voiceless = 'pçtkfhsş'.contains(lastChar);
    final suffix = switch (vowel) {
      'a' || 'ı' => voiceless ? 'ta' : 'da',
      'e' || 'i' => voiceless ? 'te' : 'de',
      'o' || 'u' => voiceless ? 'ta' : 'da',
      _ => voiceless ? 'te' : 'de',
    };
    return '$words$suffix';
  }

  /// Romen rakamını tam sayıya çevirir; geçersizse `null` döner.
  int? _romanToInt(String roman) {
    const values = {
      'I': 1,
      'V': 5,
      'X': 10,
      'L': 50,
      'C': 100,
      'D': 500,
      'M': 1000,
    };
    var total = 0;
    var previous = 0;
    for (var i = roman.length - 1; i >= 0; i--) {
      final value = values[roman[i]];
      if (value == null) return null;
      if (value < previous) {
        total -= value;
      } else {
        total += value;
        previous = value;
      }
    }
    return total > 0 ? total : null;
  }

  /// Aynı kelimenin üç ve daha fazla tekrarını tek kelimeye indirir.
  String _mergeRepeats(String text) {
    return text.replaceAllMapped(
      RegExp(
        r'(?<![a-zçğıöşüâîû])([a-zçğıöşüâîû]+)(?:\s+\1){2,}'
        r'(?![a-zçğıöşüâîû])',
      ),
      (m) => m.group(1)!,
    );
  }

  String _ordinal(int n) {
    final words = _intWords(n);
    final lastSpace = words.lastIndexOf(' ');
    final head = lastSpace == -1 ? '' : words.substring(0, lastSpace + 1);
    final last = lastSpace == -1 ? words : words.substring(lastSpace + 1);
    if (n == 4) return '${head}dördüncü';
    final vowel = _lastVowel(last);
    final endsWithVowel = _isVowel(last.runes.last);
    final suffix = switch (vowel) {
      'a' || 'ı' => endsWithVowel ? 'ncı' : 'ıncı',
      'e' || 'i' => endsWithVowel ? 'nci' : 'inci',
      'o' || 'u' => endsWithVowel ? 'ncu' : 'uncu',
      _ => endsWithVowel ? 'ncü' : 'üncü',
    };
    return '$head$last$suffix';
  }

  String _lastVowel(String word) {
    const vowels = 'aeıioöuü';
    for (var i = word.length - 1; i >= 0; i--) {
      final char = word[i];
      if (vowels.contains(char)) return char;
    }
    return 'e';
  }

  bool _isVowel(int rune) => 'aeıioöuü'.runes.contains(rune);

  // ── Tarih / saat ───────────────────────────────────────────────────────

  String _date(String yearRaw, String monthRaw, String dayRaw) {
    var year = int.tryParse(yearRaw) ?? 0;
    if (yearRaw.length == 2) {
      year += year < 50 ? 2000 : 1900;
    }
    final month = int.tryParse(monthRaw) ?? 1;
    final day = int.tryParse(dayRaw) ?? 1;
    final monthName = (month >= 1 && month <= 12) ? _months[month - 1] : '';
    if (monthName.isEmpty) {
      return '${_intWords(day)} ${_intWords(month)} ${_intWords(year)}';
    }
    return '${_intWords(day)} $monthName ${_intWords(year)}';
  }

  String _time(int hour, int minute) {
    final minuteWords = minute == 0
        ? ''
        : (minute < 10 ? 'sıfır ${_ones[minute]}' : _intWords(minute));
    final buffer = StringBuffer('saat ${_intWords(hour)}');
    if (minuteWords.isNotEmpty) buffer.write(' $minuteWords');
    return buffer.toString();
  }

  // ── Para ───────────────────────────────────────────────────────────────

  String _replaceCurrency(String text) {
    text = text.replaceAllMapped(
      RegExp(r'(?:₺|TL)\s*(\d[\d.,]*)', caseSensitive: false),
      (m) => _money(m.group(1)!, 'lira', 'kuruş'),
    );
    text = text.replaceAllMapped(
      RegExp(r'(\d[\d.,]*)\s*(?:₺|TL|lira)\b', caseSensitive: false),
      (m) => _money(m.group(1)!, 'lira', 'kuruş'),
    );
    text = text.replaceAllMapped(
      RegExp(r'\$\s*(\d[\d.,]*)'),
      (m) => _money(m.group(1)!, 'dolar', 'sent'),
    );
    text = text.replaceAllMapped(
      RegExp(r'(\d[\d.,]*)\s*(?:USD|dolar)\b', caseSensitive: false),
      (m) => _money(m.group(1)!, 'dolar', 'sent'),
    );
    text = text.replaceAllMapped(
      RegExp(r'€\s*(\d[\d.,]*)'),
      (m) => _money(m.group(1)!, 'euro', 'sent'),
    );
    text = text.replaceAllMapped(
      RegExp(r'(\d[\d.,]*)\s*(?:EUR|euro)\b', caseSensitive: false),
      (m) => _money(m.group(1)!, 'euro', 'sent'),
    );
    text = text.replaceAllMapped(
      RegExp(r'£\s*(\d[\d.,]*)'),
      (m) => _money(m.group(1)!, 'sterlin', 'peni'),
    );
    text = text.replaceAllMapped(
      RegExp(r'(\d[\d.,]*)\s*(?:GBP|sterlin)\b', caseSensitive: false),
      (m) => _money(m.group(1)!, 'sterlin', 'peni'),
    );
    return text;
  }

  String _money(String raw, String majorUnit, String minorUnit) {
    var integerPart = raw;
    var fractionPart = '';
    if (raw.contains(',')) {
      final index = raw.lastIndexOf(',');
      integerPart = raw.substring(0, index).replaceAll('.', '');
      fractionPart = raw.substring(index + 1);
    } else if (raw.contains('.')) {
      final parts = raw.split('.');
      if (parts.skip(1).every((p) => p.length == 3)) {
        integerPart = parts.join();
      } else {
        integerPart = parts.first;
        fractionPart = parts.sublist(1).join();
      }
    }
    final major = _parseInt(integerPart);
    final minor = fractionPart.isEmpty
        ? 0
        : int.tryParse(fractionPart.padRight(2, '0').substring(0, 2)) ?? 0;
    final buffer = StringBuffer('${_intWords(major)} $majorUnit');
    if (minor > 0) buffer.write(' ${_intWords(minor)} $minorUnit');
    return buffer.toString();
  }

  // ── Telefon ────────────────────────────────────────────────────────────

  String _replacePhoneNumbers(String text) {
    // Uluslararası biçim: +90 555 123 45 67
    text = text.replaceAllMapped(RegExp(r'\+\d{1,3}(?:[\s-]?\d){6,}'), (m) {
      final raw = m.group(0)!.replaceAll('+', '');
      return 'artı ${_phoneGroups(raw).join(', ')}';
    });

    // Yerel biçim: 0555 123 45 67 veya 0555-123-45-67
    text = text.replaceAllMapped(
      RegExp(r'\b0\d{3}(?:[\s-]\d{3}[\s-]\d{2}[\s-]\d{2})\b'),
      (m) => _phoneGroups(m.group(0)!).join(', '),
    );

    // Bitişik biçim: 05551234567 veya 5551234567
    text = text.replaceAllMapped(RegExp(r'\b(?:0\d{10}|5\d{9})\b'), (m) {
      final raw = m.group(0)!;
      if (raw.length == 11) {
        return _phoneGroups(
          '${raw.substring(0, 4)} ${raw.substring(4, 7)} '
          '${raw.substring(7, 9)} ${raw.substring(9)}',
        ).join(', ');
      }
      return _phoneGroups(
        '${raw.substring(0, 3)} ${raw.substring(3, 6)} '
        '${raw.substring(6, 8)} ${raw.substring(8)}',
      ).join(', ');
    });
    return text;
  }

  /// Telefon numarasını gruplara ayırır ve her grubu doğal sayı olarak okur.
  ///
  /// Model tekrarlanan rakamlarda döngüye girebildiği için "beş beş beş"
  /// yerine "beş yüz elli beş" tercih edilir.
  List<String> _phoneGroups(String raw) {
    final tokens = raw
        .split(RegExp(r'[\s-]+'))
        .map((token) => token.replaceAll(RegExp(r'\D'), ''))
        .where((token) => token.isNotEmpty)
        .toList();
    return tokens.map(_readPhoneGroup).toList();
  }

  String _readPhoneGroup(String digits) {
    if (digits.length > 1 && digits.startsWith('0')) {
      final rest = digits.substring(1);
      final restWords = _intWords(_parseInt(rest));
      return 'sıfır $restWords';
    }
    return _intWords(_parseInt(digits));
  }

  // ── Birimler / kısaltmalar ─────────────────────────────────────────────

  String _replaceUnits(String text) {
    const units = <String, String>{
      'km/s': 'kilometre bölü saat',
      'm/s': 'metre bölü saniye',
      'km²': 'kilometrekare',
      'm²': 'metrekare',
      'm³': 'metreküp',
      'cm²': 'santimetrekare',
      '°C': 'santigrat derece',
      '°F': 'fahrenhayt derece',
      '° C': 'santigrat derece',
      '° F': 'fahrenhayt derece',
      'kWh': 'kilovatsaat',
      'GHz': 'gigahertz',
      'MHz': 'megahertz',
      'kHz': 'kilohertz',
      'kbps': 'kilobit bölü saniye',
      'Mbps': 'megabit bölü saniye',
      'Gbps': 'gigabit bölü saniye',
      'TB': 'terabayt',
      'GB': 'gigabayt',
      'MB': 'megabayt',
      'KB': 'kilobayt',
      'kg': 'kilogram',
      'mg': 'miligram',
      'km': 'kilometre',
      'cm': 'santimetre',
      'mm': 'milimetre',
      'ml': 'mililitre',
      'lt': 'litre',
      'dk': 'dakika',
      'sn': 'saniye',
      'Hz': 'hertz',
      'kW': 'kilovat',
      'MW': 'megavat',
    };
    var result = text;
    for (final entry in units.entries) {
      result = result.replaceAll(
        RegExp(
          '(?<!\\p{L})${RegExp.escape(entry.key)}(?![\\p{L}\\d])',
          unicode: true,
          caseSensitive: false,
        ),
        ' ${entry.value} ',
      );
    }
    result = result
        .replaceAllMapped(RegExp(r'(\d)\s*°'), (m) => '${m.group(1)} derece ')
        .replaceAll('&', ' ve ')
        .replaceAll(RegExp(r'(?<=\s)[#]'), ' numara ')
        .replaceAll('×', ' çarpı ')
        .replaceAll('÷', ' bölü ')
        .replaceAll('=', ' eşittir ')
        .replaceAll('≥', ' büyük veya eşit ')
        .replaceAll('≤', ' küçük veya eşit ')
        .replaceAll('≠', ' eşit değil ')
        .replaceAll('±', ' artı eksi ')
        .replaceAll('≈', ' yaklaşık ')
        .replaceAll('>', ' büyüktür ')
        .replaceAll('<', ' küçüktür ');
    return result;
  }

  String _replaceAbbreviations(String text) {
    const abbreviations = <String, String>{
      'M.Ö.': 'milattan önce',
      'M.S.': 'milattan sonra',
      'T.C.': 'Türkiye Cumhuriyeti',
      'Prof. Dr.': 'profesör doktor',
      'Prof.': 'profesör',
      'Doç. Dr.': 'doçent doktor',
      'Doç.': 'doçent',
      'Dr.': 'doktor',
      'Av.': 'avukat',
      'Cad.': 'cadde',
      'Sok.': 'sokak',
      'Apt.': 'apartman',
      'No.': 'numara',
      'Tel.': 'telefon',
      'vb.': 've benzeri',
      'vs.': 'vesaire',
      'vd.': 've devamı',
      'yy.': 'yüzyıl',
      'ABD': 'Amerika Birleşik Devletleri',
      'TBMM': 'Türkiye Büyük Millet Meclisi',
      'BM': 'Birleşmiş Milletler',
      'NATO': 'NATO',
      'NASA': 'NASA',
      'UNESCO': 'UNESCO',
      'TL': 'lira',
      'EUR': 'euro',
      'USD': 'dolar',
      'GBP': 'sterlin',
    };
    var result = text;
    for (final entry in abbreviations.entries) {
      result = result.replaceAll(
        RegExp(
          '(?<!\\p{L})${RegExp.escape(entry.key)}(?![\\p{L}\\d])',
          unicode: true,
          caseSensitive: false,
        ),
        ' ${entry.value} ',
      );
    }
    return result;
  }

  // ── E-posta ────────────────────────────────────────────────────────────

  String _spellEmail(String email) {
    final at = email.indexOf('@');
    if (at < 0) return email;
    final local = email.substring(0, at);
    final domain = email.substring(at + 1);
    String spell(String part) => part
        .replaceAllMapped(
          RegExp(r'\d+'),
          (m) => ' ${_digitsIndividually(m.group(0)!)} ',
        )
        .replaceAll('.', ' nokta ')
        .replaceAll('-', ' tire ')
        .replaceAll('_', ' alt çizgi ')
        .replaceAll('+', ' artı ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${spell(local)} et ${spell(domain)}';
  }

  String _alphaId(int value) {
    var n = value;
    final buffer = StringBuffer();
    do {
      buffer.writeCharCode(65 + (n % 26));
      n ~/= 26;
    } while (n > 0);
    return buffer.toString();
  }
}

/// Türkçe'ye duyarlı küçük harfe çevirme.
String turkishLowercase(String value) {
  return value.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
}
