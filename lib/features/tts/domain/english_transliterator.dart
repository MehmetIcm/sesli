/// İngilizce kelimeleri Türkçe sesletime çeviren çevrimdışı katman.
///
/// Türkçe TTS modeli İngilizce harfleri Türkçe kurallarıyla okur; bu yüzden
/// "webcam" gibi kelimeler "vebcam" olur. Bu sınıf, yaygın İngilizce
/// kelimeleri ve teknoloji terimlerini Türkçe fonetiğe yakın biçimde yazar:
///
///     webcam   -> vebkem
///     update   -> apdeyt
///     online   -> onlayn
///     browser  -> brauzır
///
/// Kaynaklar:
///  * `assets/data/english_lexicon.json` — CMUdict tabanlı, 120 bin kelime.
///  * `assets/data/turkish_words.txt` — yanlış pozitifleri önleyen Türkçe
///    kelime listesi.
///  * Gömülü küçük sözlük — en sık kullanılan kelimeler için elle seçilmiş
///    doğru okunuşlar.
///  * Kural tabanlı G2P — sözlükte bulunmayan yeni kelimeler için yedek.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import 'turkish_text_normalizer.dart';

class EnglishTransliterator {
  EnglishTransliterator._();

  static final EnglishTransliterator instance = EnglishTransliterator._();

  static const String lexiconAsset = 'assets/data/english_lexicon.json';
  static const String turkishWordsAsset = 'assets/data/turkish_words.txt';

  Map<String, String>? _lexicon;
  Set<String>? _turkishWords;
  Future<void>? _loading;

  bool get isLoaded => _lexicon != null && _turkishWords != null;

  /// Sözlükleri yükler. Uygulama açılışında bir kez çağrılır.
  Future<void> ensureLoaded() {
    if (isLoaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final loaded = await Future.wait([
        rootBundle.loadString(lexiconAsset),
        rootBundle.loadString(turkishWordsAsset),
      ]);
      final decoded = jsonDecode(loaded[0]) as Map<String, dynamic>;
      _lexicon = {
        for (final entry in decoded.entries) entry.key: entry.value as String,
      };
      _turkishWords = loaded[1]
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toSet();
    } catch (_) {
      // Varlıklar eksikse yalnızca gömülü sözlük ve kurallar kullanılır.
      _lexicon = const {};
      _turkishWords = const {};
    }
  }

  /// Metindeki İngilizce kelimeleri Türkçe okunuşlarına çevirir.
  ///
  /// Girdi zaten Türkçe küçük harfe çevrilmiş olmalıdır. Noktalama ve
  /// boşluklar korunur.
  String transliterate(String text) {
    if (text.isEmpty) return text;

    final buffer = StringBuffer();
    final parts = RegExp(r'[^.!?\n]+|[.!?\n]+').allMatches(text);
    for (final part in parts) {
      final chunk = part.group(0)!;
      if (RegExp(r'[.!?\n]').hasMatch(chunk)) {
        buffer.write(chunk);
      } else {
        buffer.write(
          _transliterateSegment(chunk, forceEnglish: _isEnglishSentence(chunk)),
        );
      }
    }
    return buffer.toString();
  }

  // ── Cümle / kelime işleme ──────────────────────────────────────────────

  static final RegExp _wordPattern = RegExp(
    r"[A-Za-zÇĞİÖŞÜçğıöşü0-9]+(?:['’][A-Za-zÇĞİÖŞÜçğıöşü]+)*",
  );

  String _transliterateSegment(String segment, {required bool forceEnglish}) {
    final buffer = StringBuffer();
    var index = 0;
    for (final match in _wordPattern.allMatches(segment)) {
      buffer.write(segment.substring(index, match.start));
      buffer.write(
        _transliterateToken(match.group(0)!, forceEnglish: forceEnglish),
      );
      index = match.end;
    }
    buffer.write(segment.substring(index));
    return buffer.toString();
  }

  String _transliterateToken(String token, {required bool forceEnglish}) {
    final apostrophe = token.indexOf(RegExp("['’]"));
    final base = apostrophe >= 0 ? token.substring(0, apostrophe) : token;
    final suffix = apostrophe >= 0 ? token.substring(apostrophe) : '';
    if (base.isEmpty) return token;

    final direct = _englishRespelling(base, force: forceEnglish);
    if (direct != null) return '$direct$suffix';

    // "webcamden", "onlineda", "updatei" gibi apostrofsuz Türkçe ekler.
    if (!_isTurkish(base)) {
      final split = _stripTurkishSuffix(base);
      if (split != null) {
        final respelling = _englishRespelling(split.$1, force: forceEnglish);
        if (respelling != null) return '$respelling${split.$2}$suffix';
      }
    }
    return token;
  }

  String? _englishRespelling(String word, {required bool force}) {
    final lower = turkishLowercase(word);
    if (lower.isEmpty) return null;

    // Marka adlarında büyük "I" harfi Türkçe küçültmede "ı" olur
    // ("LinkedIn" → "linkedın"). Normalizasyon metni önce küçülttüğü için
    // "ı" → "i" geri dönüşümü de denenir; böylece sözlük anahtarı bulunur.
    final asciiLower = word.toLowerCase();
    final dotless = lower.replaceAll('ı', 'i');
    final curated =
        _curated[lower] ?? _curated[asciiLower] ?? _curated[dotless];
    if (curated != null) {
      // Tek harfli sözcükler Türkçe metinde genellikle harf adıdır
      // ("A planı", "B seçeneği"). Yalnızca İngilizce cümlede çevrilir.
      if (lower.length == 1 && !force) return null;
      return curated;
    }

    // Türkçe bir kelimeyi asla İngilizce okumaya çalışmayız.
    if (_isTurkish(lower)) return null;

    final lexiconMap = _lexicon ?? const <String, String>{};
    final lexicon =
        lexiconMap[lower] ?? lexiconMap[asciiLower] ?? lexiconMap[dotless];
    if (lexicon != null && (force || _looksEnglish(lower))) return lexicon;

    if ((force || _looksEnglish(lower)) && lower.length >= 2) {
      return _ruleBased(lower);
    }
    return null;
  }

  bool _isTurkish(String word) {
    if (word.isEmpty) return false;
    if (_protectedTurkish.contains(word)) return true;
    return (_turkishWords ?? const <String>{}).contains(word);
  }

  // ── İngilizce cümle tespiti ────────────────────────────────────────────

  static const Set<String> _englishStopwords = {
    'a',
    'an',
    'the',
    'and',
    'or',
    'but',
    'if',
    'of',
    'to',
    'in',
    'on',
    'at',
    'by',
    'for',
    'from',
    'with',
    'without',
    'about',
    'into',
    'over',
    'under',
    'after',
    'before',
    'between',
    'through',
    'during',
    'as',
    'than',
    'then',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'being',
    'am',
    'do',
    'does',
    'did',
    'have',
    'has',
    'had',
    'will',
    'would',
    'can',
    'could',
    'should',
    'may',
    'might',
    'must',
    'not',
    'no',
    'yes',
    'i',
    'you',
    'we',
    'they',
    'he',
    'she',
    'it',
    'me',
    'my',
    'your',
    'our',
    'their',
    'his',
    'her',
    'this',
    'that',
    'these',
    'those',
    'there',
    'here',
    'what',
    'which',
    'who',
    'whom',
    'whose',
    'when',
    'where',
    'why',
    'how',
    'also',
    'very',
    'just',
    'only',
    'all',
    'any',
    'some',
    'many',
    'much',
    'more',
    'most',
    'other',
    'another',
    'such',
    'both',
    'each',
    'every',
    'either',
    'neither',
    'same',
    'own',
  };

  bool _isEnglishSentence(String sentence) {
    final words = _wordPattern
        .allMatches(sentence)
        .map((m) => m.group(0)!)
        .where((w) => RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(w))
        .toList();
    if (words.length < 3) return false;

    var english = 0;
    var turkish = 0;
    for (final word in words) {
      final base = word.split(RegExp("['’]")).first;
      final lower = turkishLowercase(base);
      if (_englishStopwords.contains(lower)) {
        // Türkçe listede de geçen "the", "is", "good" gibi kelimeler
        // İngilizce cümlede Türkçe sayılmamalı.
        english++;
      } else if (_isTurkish(lower)) {
        turkish++;
      }
    }
    return english >= 2 && english > turkish;
  }

  // ── İngilizce görünüşlü kelime tespiti ─────────────────────────────────

  static final RegExp _markers = RegExp(
    r'[qwx]|ck|ch|sh|th|ph|wh|gh|dg|tch|'
    r'ea|ee|oo|ou|ow|oa|ue|aw|oi',
  );

  static final RegExp _suffixMarkers = RegExp(
    r'(?:tion|sion|ing|ed|ly|ness|ment|ship|able|ible|ous|ity|ize|ise|'
    r'ful|less|ward|wise|graphy|ology)$',
  );

  static final RegExp _initialMarkers = RegExp(r'^(?:kn|wr)');

  bool _looksEnglish(String word) {
    if (word.length < 3) return false;
    return _markers.hasMatch(word) ||
        _suffixMarkers.hasMatch(word) ||
        _initialMarkers.hasMatch(word);
  }

  // ── Türkçe ek soyma ────────────────────────────────────────────────────

  static const List<String> _turkishSuffixes = [
    'lerinden',
    'larından',
    'lerimiz',
    'larımız',
    'lerden',
    'lardan',
    'lerde',
    'larda',
    'lerin',
    'ların',
    'leri',
    'ları',
    'ler',
    'lar',
    'lerine',
    'larına',
    'lerini',
    'larını',
    'le',
    'la',
    'yle',
    'yla',
    'den',
    'dan',
    'ten',
    'tan',
    'de',
    'da',
    'te',
    'ta',
    'deki',
    'daki',
    'teki',
    'taki',
    'nin',
    'nın',
    'nun',
    'nün',
    'in',
    'ın',
    'un',
    'ün',
    'ne',
    'na',
    'ni',
    'nı',
    'nu',
    'nü',
    'e',
    'a',
    'i',
    'ı',
    'u',
    'ü',
    'im',
    'ım',
    'um',
    'üm',
    'imiz',
    'ımız',
    'umuz',
    'ümüz',
    'sin',
    'sın',
    'sun',
    'sün',
    'dir',
    'dır',
    'dur',
    'dür',
    'tir',
    'tır',
    'tur',
    'tür',
    'lik',
    'lık',
    'luk',
    'lük',
    'ci',
    'cı',
    'cu',
    'cü',
    'çi',
    'çı',
    'çu',
    'çü',
    'sel',
    'sal',
    'siz',
    'sız',
    'suz',
    'süz',
    'ce',
    'ca',
    'çe',
    'ça',
    'ken',
    'leyin',
    'gil',
    'me',
    'ma',
  ];

  (String, String)? _stripTurkishSuffix(String word) {
    for (final suffix in _turkishSuffixes) {
      if (word.length <= suffix.length + 2) continue;
      if (!word.endsWith(suffix)) continue;
      final stem = word.substring(0, word.length - suffix.length);
      if (stem.length < 3) continue;
      if (_curated.containsKey(stem) ||
          (_lexicon ?? const <String, String>{}).containsKey(stem)) {
        return (stem, suffix);
      }
    }
    return null;
  }

  // ── Kural tabanlı G2P ──────────────────────────────────────────────────

  static const Map<String, String> _g2pExceptions = {
    'a': 'e',
    'an': 'en',
    'the': 'dı',
    'of': 'ov',
    'to': 'tu',
    'by': 'bay',
    'my': 'may',
    'i': 'ay',
    'you': 'yu',
    'your': 'yur',
    'we': 'vi',
    'he': 'hi',
    'she': 'şi',
    'it': 'it',
    'me': 'mi',
    'us': 'as',
    'is': 'iz',
    'are': 'ar',
    'was': 'voz',
    'were': 'vır',
    'be': 'bi',
    'been': 'bin',
    'do': 'du',
    'does': 'daz',
    'did': 'did',
    'done': 'dan',
    'have': 'hev',
    'has': 'hez',
    'had': 'hed',
    'one': 'van',
    'once': 'vans',
    'love': 'lav',
    'come': 'kam',
    'some': 'sam',
    'none': 'nan',
    'gone': 'gon',
    'give': 'giv',
    'live': 'liv',
    'move': 'muv',
    'prove': 'pruv',
    'lose': 'luz',
    'whose': 'huz',
    'use': 'yuz',
    'used': 'yuzd',
    'here': 'hir',
    'there': 'deır',
    'where': 'veır',
    'their': 'deır',
    'they': 'dey',
    'them': 'dem',
    'then': 'den',
    'than': 'den',
    'this': 'dis',
    'that': 'det',
    'these': 'diz',
    'those': 'douz',
    'what': 'vat',
    'which': 'viç',
    'when': 'ven',
    'why': 'vay',
    'who': 'hu',
    'whom': 'hum',
    'how': 'hau',
    'now': 'nau',
    'new': 'nyu',
    'know': 'nou',
    'no': 'nou',
    'so': 'sou',
    'go': 'gou',
    'ok': 'okey',
    'okay': 'okey',
    'oh': 'ou',
    'ah': 'a',
    'hi': 'hay',
    'hello': 'helou',
    'thanks': 'tenks',
    'thank': 'tenk',
    'please': 'pliz',
    'sorry': 'sori',
    'good': 'gud',
    'great': 'greyt',
    'yes': 'yes',
    'yeah': 'ye',
    'yep': 'yep',
    'nope': 'noup',
    'today': 'tudey',
    'tomorrow': 'tumorou',
    'yesterday': 'yestırdey',
    'because': 'bikoz',
    'about': 'ebaut',
    'again': 'egeyn',
    'always': 'olveys',
    'never': 'nevır',
    'ever': 'evır',
    'often': 'ofın',
    'really': 'rili',
    'maybe': 'meybi',
    'perhaps': 'pırheps',
  };

  String _ruleBased(String input) {
    final word = input.replaceAll(RegExp(r'[^a-z]'), '');
    if (word.isEmpty) return input;

    final exception = _g2pExceptions[word];
    if (exception != null) return exception;

    final out = <String>[];
    var i = 0;
    final n = word.length;

    bool isVowelAt(int index) =>
        index >= 0 && index < n && 'aeiou'.contains(word[index]);
    bool isConsonantAt(int index) =>
        index >= 0 && index < n && !isVowelAt(index);

    while (i < n) {
      final c = word[i];
      final rest = word.substring(i);

      // Sessiz son "e": make, time, code, site.
      if (i == n - 1 && c == 'e') {
        i++;
        continue;
      }

      // -ive, -ate, -ite, -ace, -ice, -age, -ance, -ence, -ure, -ore, -are,
      // -ere: bunlarda son "e" sessiz değildir; kalıbı birlikte işleriz.
      if (i > 0) {
        if (rest == 'ive') {
          out.add('iv');
          i += 3;
          continue;
        }
        if (rest == 'ate') {
          out.add('eyt');
          i += 3;
          continue;
        }
        if (rest == 'ite') {
          out.add('ayt');
          i += 3;
          continue;
        }
        if (rest == 'ace') {
          out.add('eys');
          i += 3;
          continue;
        }
        if (rest == 'ice') {
          out.add('is');
          i += 3;
          continue;
        }
        if (rest == 'age') {
          out.add('ic');
          i += 3;
          continue;
        }
        if (rest == 'ance' || rest == 'ence') {
          out.add('ıns');
          i += 4;
          continue;
        }
        if (rest == 'ure') {
          out.add('yur');
          i += 3;
          continue;
        }
        if (rest == 'ore') {
          out.add('or');
          i += 3;
          continue;
        }
        if (rest == 'are' || rest == 'ere') {
          out.add('eır');
          i += 3;
          continue;
        }
      }

      // Sihirli "e": vowel + consonant + final e -> uzun ünlü.
      if (isVowelAt(i) &&
          i + 2 == n - 1 &&
          word[i + 2] == 'e' &&
          isConsonantAt(i + 1)) {
        out.add(_longVowel(c));
        i++;
        continue;
      }

      // Çok harfli kalıplar.
      if (rest.startsWith('tion')) {
        out.add('şın');
        i += 4;
        continue;
      }
      if (rest.startsWith('sion')) {
        out.add('jın');
        i += 4;
        continue;
      }
      if (rest.startsWith('ture')) {
        out.add('çır');
        i += 4;
        continue;
      }
      if (rest.startsWith('cial') || rest.startsWith('tial')) {
        out.add('şıl');
        i += 4;
        continue;
      }
      if (rest.startsWith('cious') || rest.startsWith('tious')) {
        out.add('şıs');
        i += 5;
        continue;
      }
      if (rest.startsWith('geous') || rest.startsWith('gious')) {
        out.add('cıs');
        i += 5;
        continue;
      }
      if (rest.startsWith('able')) {
        out.add('eybıl');
        i += 4;
        continue;
      }
      if (rest.startsWith('ible')) {
        out.add('ibıl');
        i += 4;
        continue;
      }
      if (rest.startsWith('ment')) {
        out.add('ment');
        i += 4;
        continue;
      }
      if (rest.startsWith('ness')) {
        out.add('nes');
        i += 4;
        continue;
      }
      if (rest.startsWith('ful')) {
        out.add('fıl');
        i += 3;
        continue;
      }
      if (rest.startsWith('less')) {
        out.add('les');
        i += 4;
        continue;
      }
      if (rest.startsWith('ship')) {
        out.add('şip');
        i += 4;
        continue;
      }
      if (rest.startsWith('ward')) {
        out.add('vord');
        i += 4;
        continue;
      }
      if (rest.startsWith('wise')) {
        out.add('vayz');
        i += 4;
        continue;
      }
      if (rest.startsWith('graphy')) {
        out.add('grafi');
        i += 6;
        continue;
      }
      if (rest.startsWith('ology')) {
        out.add('oloci');
        i += 5;
        continue;
      }
      if (rest.startsWith('ically')) {
        out.add('ikli');
        i += 6;
        continue;
      }
      if (rest.startsWith('ical')) {
        out.add('ikıl');
        i += 4;
        continue;
      }
      if (rest.startsWith('ity')) {
        out.add('iti');
        i += 3;
        continue;
      }
      if (rest.startsWith('ify')) {
        out.add('ifay');
        i += 3;
        continue;
      }
      if (rest.startsWith('ize') || rest.startsWith('ise')) {
        out.add('ayz');
        i += 3;
        continue;
      }
      if (rest.startsWith('ous')) {
        out.add('ıs');
        i += 3;
        continue;
      }
      if (rest.startsWith('ing')) {
        out.add('ing');
        i += 3;
        continue;
      }
      if (rest.startsWith('ed')) {
        out.add('d');
        i += 2;
        continue;
      }
      if (rest.startsWith('es')) {
        out.add('iz');
        i += 2;
        continue;
      }
      if (rest.startsWith('ly')) {
        out.add('li');
        i += 2;
        continue;
      }
      if (rest.startsWith('igh')) {
        out.add('ay');
        i += 3;
        continue;
      }
      if (rest.startsWith('ough')) {
        out.add('o');
        i += 4;
        continue;
      }
      if (rest.startsWith('augh')) {
        out.add('af');
        i += 4;
        continue;
      }
      if (rest.startsWith('tch')) {
        out.add('ç');
        i += 3;
        continue;
      }
      if (rest.startsWith('dge')) {
        out.add('c');
        i += 3;
        continue;
      }
      if (rest.startsWith('ck')) {
        out.add('k');
        i += 2;
        continue;
      }
      if (rest.startsWith('ch')) {
        out.add('ç');
        i += 2;
        continue;
      }
      if (rest.startsWith('sh')) {
        out.add('ş');
        i += 2;
        continue;
      }
      if (rest.startsWith('th')) {
        out.add('t');
        i += 2;
        continue;
      }
      if (rest.startsWith('ph')) {
        out.add('f');
        i += 2;
        continue;
      }
      if (rest.startsWith('wh')) {
        out.add('v');
        i += 2;
        continue;
      }
      if (rest.startsWith('qu')) {
        out.add('kv');
        i += 2;
        continue;
      }
      if (rest.startsWith('gh')) {
        i += 2;
        continue;
      }
      if (rest.startsWith('kn') && i == 0) {
        out.add('n');
        i += 2;
        continue;
      }
      if (rest.startsWith('wr') && i == 0) {
        out.add('r');
        i += 2;
        continue;
      }
      if (rest.startsWith('mb') && i + 2 == n) {
        out.add('m');
        i += 2;
        continue;
      }
      if (rest.startsWith('dg')) {
        out.add('c');
        i += 2;
        continue;
      }

      // Ünlü ikilileri.
      if (rest.startsWith('ee')) {
        out.add('i');
        i += 2;
        continue;
      }
      if (rest.startsWith('ea')) {
        out.add('i');
        i += 2;
        continue;
      }
      if (rest.startsWith('oo')) {
        out.add('u');
        i += 2;
        continue;
      }
      if (rest.startsWith('ou')) {
        out.add('au');
        i += 2;
        continue;
      }
      if (rest.startsWith('ow')) {
        out.add('ou');
        i += 2;
        continue;
      }
      if (rest.startsWith('oa')) {
        out.add('ou');
        i += 2;
        continue;
      }
      if (rest.startsWith('ai') || rest.startsWith('ay')) {
        out.add('ey');
        i += 2;
        continue;
      }
      if (rest.startsWith('ei') || rest.startsWith('ey')) {
        out.add('ey');
        i += 2;
        continue;
      }
      if (rest.startsWith('ie')) {
        out.add('i');
        i += 2;
        continue;
      }
      if (rest.startsWith('ue')) {
        out.add('u');
        i += 2;
        continue;
      }
      if (rest.startsWith('ui')) {
        out.add('u');
        i += 2;
        continue;
      }
      if (rest.startsWith('au') || rest.startsWith('aw')) {
        out.add('o');
        i += 2;
        continue;
      }
      if (rest.startsWith('oi') || rest.startsWith('oy')) {
        out.add('oy');
        i += 2;
        continue;
      }
      if (rest.startsWith('eu')) {
        out.add('yu');
        i += 2;
        continue;
      }

      // Sondaki kalıplar.
      if (i + 2 == n && rest == 'er') {
        out.add('ır');
        i += 2;
        continue;
      }
      if (i + 2 == n && rest == 'or') {
        out.add('ır');
        i += 2;
        continue;
      }
      if (i + 2 == n && rest == 'ar') {
        out.add('ar');
        i += 2;
        continue;
      }
      if (i + 2 == n && rest == 'le' && isConsonantAt(i - 1)) {
        out.add('ıl');
        i += 2;
        continue;
      }
      if (i + 2 == n && rest == 'al') {
        out.add('ıl');
        i += 2;
        continue;
      }
      if (i + 1 == n && rest == 'y' && isConsonantAt(i - 1)) {
        out.add('i');
        i++;
        continue;
      }

      // Tek harfler.
      switch (c) {
        case 'a':
          out.add('e');
          break;
        case 'e':
          out.add('e');
          break;
        case 'i':
          out.add('i');
          break;
        case 'o':
          out.add('o');
          break;
        case 'u':
          if (i == 0) {
            out.add('yu');
          } else if (isConsonantAt(i - 1) && isConsonantAt(i + 1)) {
            out.add('a');
          } else {
            out.add('a');
          }
          break;
        case 'y':
          if (i > 0 && isConsonantAt(i - 1) && isConsonantAt(i + 1)) {
            out.add('i');
          } else {
            out.add('y');
          }
          break;
        case 'c':
          final next = i + 1 < n ? word[i + 1] : '';
          out.add('eiy'.contains(next) ? 's' : 'k');
          break;
        case 'g':
          final next = i + 1 < n ? word[i + 1] : '';
          out.add('eiy'.contains(next) ? 'c' : 'g');
          break;
        case 'j':
          out.add('c');
          break;
        case 'x':
          out.add('ks');
          break;
        case 'w':
          out.add('v');
          break;
        case 'q':
          out.add('k');
          break;
        default:
          out.add(c);
      }
      i++;
    }

    var result = out.join();
    result = result.replaceAll(RegExp(r'([aeıioöuü])\1+'), r'$1');
    return result;
  }

  String _longVowel(String vowel) {
    return switch (vowel) {
      'a' => 'ey',
      'e' => 'i',
      'i' => 'ay',
      'o' => 'ou',
      'u' => 'yu',
      _ => vowel,
    };
  }

  // ── Gömülü sözlük ──────────────────────────────────────────────────────
  //
  // Elle seçilmiş, Türkçe TTS'in doğal okuyacağı karşılıklar. CMUdict
  // çıktısından daha doğru oldukları için önce bunlar denenir.

  static const Map<String, String> _curated = {
    // İşlev sözcükleri — CMUdict çıktısından daha doğal olanlar.
    'the': 'dı',
    'a': 'e',
    'of': 'ov',
    'your': 'yur',
    'hello': 'helou',
    'thanks': 'tenks',
    'thank': 'tenk',
    'please': 'pliz',
    'sorry': 'sori',
    'good': 'gud',
    'great': 'greyt',
    'very': 'veri',
    'terrible': 'teribıl',
    'various': 'veriıs',
    'example': 'eksample',
    'taxi': 'taksi',

    // Genel İngilizce — Türkçe metin içinde geçen sık kelimeler.
    'game': 'geym',
    'name': 'neym',
    'time': 'taym',
    'life': 'layf',
    'home': 'houm',
    'page': 'peyc',
    'age': 'eyc',
    'face': 'feys',
    'place': 'pleys',
    'space': 'speys',
    'case': 'keys',
    'base': 'beys',
    'date': 'deyt',
    'late': 'leyt',
    'rate': 'reyt',
    'state': 'steyt',
    'note': 'nout',
    'vote': 'vout',
    'white': 'vayt',
    'write': 'rayt',
    'large': 'larc',
    'change': 'çeync',
    'orange': 'orınc',
    'language': 'lenguic',
    'manage': 'menic',
    'village': 'vilic',
    'college': 'kollic',
    'practice': 'prektis',
    'notice': 'noutis',
    'justice': 'castis',
    'active': 'ektiv',
    'native': 'neytiv',
    'relative': 'relativ',
    'creative': 'krieytiv',
    'positive': 'pozitiv',
    'negative': 'negativ',
    'expensive': 'ekspensiv',
    'effective': 'efektiv',
    'alternative': 'oltırneytiv',
    'representative': 'reprzentativ',
    'executive': 'egzekyutiv',
    'competitive': 'kımpetitiv',
    'sensitive': 'sensitiv',
    'objective': 'obcektiv',
    'perspective': 'pırspektiv',
    'initiative': 'inişitiv',
    'conservative': 'kınsırvativ',
    'innovative': 'inoveytiv',
    'interactive': 'intırektiv',
    'attractive': 'etrektiv',
    'people': 'pipıl',
    'world': 'vırld',
    'work': 'vırk',
    'word': 'vırd',
    'part': 'part',
    'year': 'yir',
    'day': 'dey',
    'way': 'vey',
    'man': 'men',
    'woman': 'vumın',
    'child': 'çayld',
    'children': 'çildrın',
    'family': 'femıli',
    'friend': 'frend',
    'school': 'skul',
    'house': 'haus',
    'money': 'mani',
    'night': 'nayt',
    'light': 'layt',
    'right': 'rayt',
    'same': 'seym',
    'make': 'meyk',
    'take': 'teyk',
    'give': 'giv',
    'love': 'lav',
    'come': 'kam',
    'some': 'sam',
    'water': 'votır',
    'number': 'nambır',
    'story': 'stori',

    // Teknoloji / yazılım
    'webcam': 'vebkem',
    'computer': 'kompyutır',
    'software': 'softveır',
    'hardware': 'hardveır',
    'firmware': 'fırmveır',
    'malware': 'melveır',
    'update': 'apdeyt',
    'upgrade': 'apgreyd',
    'downgrade': 'daungreyd',
    'online': 'onlayn',
    'offline': 'oflayn',
    'download': 'daunloud',
    'upload': 'aploud',
    'website': 'vebsayt',
    'browser': 'brauzır',
    'server': 'sırvır',
    'client': 'klayınt',
    'cache': 'keş',
    'cookie': 'kuki',
    'firewall': 'fayırvol',
    'database': 'deytebeys',
    'backend': 'bekend',
    'frontend': 'frantend',
    'fullstack': 'fulstek',
    'framework': 'freymvırk',
    'library': 'laybreri',
    'package': 'pekic',
    'module': 'mocul',
    'plugin': 'plagin',
    'script': 'skript',
    'code': 'kod',
    'debug': 'dibag',
    'deploy': 'diploy',
    'commit': 'komit',
    'branch': 'branç',
    'merge': 'merc',
    'pull': 'pul',
    'push': 'puş',
    'clone': 'klon',
    'fork': 'fork',
    'issue': 'isu',
    'bug': 'bag',
    'feature': 'fiçır',
    'release': 'rilis',
    'build': 'bild',
    'startup': 'startap',
    'scaleup': 'skeylap',
    'podcast': 'podkest',
    'webinar': 'vebinır',
    'newsletter': 'nyuzletır',
    'deadline': 'dedlayn',
    'ethereum': 'eteryum',
    'unicorn': 'yunikorn',
    'venture': 'vençır',
    'investor': 'investır',
    'founder': 'faundır',
    'cofounder': 'kofaundır',
    'freelance': 'frilens',
    'remote': 'rimout',
    'hybrid': 'haybrid',
    'office': 'ofis',
    'coworking': 'kovırking',
    'onboarding': 'onbording',
    'offboarding': 'ofbording',
    'feedback': 'fidbek',
    'performance': 'pırformıns',
    'review': 'rivyu',
    'promotion': 'pırmouşın',
    'salary': 'seleri',
    'bonus': 'bounıs',
    'stock': 'stok',
    'option': 'opşın',
    'equity': 'ekvıti',
    'pitch': 'piç',
    'deck': 'dek',
    'demo': 'demou',
    'prototype': 'proutotayp',
    'beta': 'beyta',
    'alpha': 'alfa',
    'version': 'vırjın',
    'install': 'instol',
    'uninstall': 'aninstol',
    'sync': 'sink',
    'backup': 'bekbap',
    'restore': 'ristor',
    'reset': 'riset',
    'login': 'login',
    'logout': 'logaut',
    'signup': 'saynap',
    'signin': 'saynin',
    'password': 'pasvırd',
    'username': 'yuzırneym',
    'email': 'imeyl',
    'account': 'ekaunt',
    'profile': 'proufayl',
    'settings': 'setingz',
    'dashboard': 'deşbord',
    'widget': 'vicet',
    'extension': 'ekstenşın',
    'addon': 'edon',
    'theme': 'tim',
    'template': 'templıt',
    'layout': 'leyaut',
    'design': 'dizayn',
    'branding': 'brending',
    'logo': 'logou',
    'icon': 'aykon',
    'font': 'font',
    'image': 'imic',
    'video': 'vidiyo',
    'audio': 'odiyo',
    'stream': 'strim',
    'live': 'layv',
    'chat': 'çet',
    'message': 'mesic',
    'comment': 'koment',
    'reel': 'ril',
    'tweet': 'tvit',
    'retweet': 'ritvit',
    'hashtag': 'heşteg',
    'emoji': 'imouci',
    'meme': 'mim',
    'viral': 'vayrıl',
    'influencer': 'influensır',
    'creator': 'krieytır',
    'content': 'kontent',
    'engagement': 'engeycmınt',
    'reach': 'riç',
    'impression': 'impreşın',
    'click': 'klik',
    'conversion': 'kınvırjın',
    'funnel': 'fanıl',
    'campaign': 'kempeyn',
    'marketing': 'markiting',
    'sales': 'seylz',
    'customer': 'kastımır',
    'user': 'yuzır',
    'admin': 'edmin',
    'manager': 'menıcır',
    'team': 'tim',
    'leader': 'lidır',
    'member': 'membır',
    'project': 'procekt',
    'task': 'tesk',
    'ticket': 'tikit',
    'requirement': 'rikvayırmınt',
    'spec': 'spek',
    'documentation': 'dokyumenteyşın',
    'docs': 'doks',
    'wiki': 'viki',
    'readme': 'ridmi',
    'changelog': 'çeynglog',
    'repo': 'ripou',
    'repository': 'ripazitori',
    'origin': 'oricin',
    'master': 'mestır',
    'main': 'meyn',
    'develop': 'divelıp',
    'staging': 'steycing',
    'production': 'pırdakşın',
    'log': 'log',
    'error': 'erır',
    'warning': 'vornink',
    'info': 'infou',
    'trace': 'treys',
    'stack': 'stek',
    'thread': 'tred',
    'process': 'proses',
    'memory': 'memori',
    'session': 'seşın',
    'token': 'toukın',
    'key': 'ki',
    'secret': 'sikrıt',
    'hash': 'heş',
    'salt': 'solt',
    'encrypt': 'enkript',
    'decrypt': 'dikript',
    'auth': 'ot',
    'bot': 'bot',
    'spam': 'spem',
    'phishing': 'fişing',
    'virus': 'vayrıs',
    'proxy': 'proksi',
    'domain': 'domeyn',
    'host': 'host',
    'hosting': 'hosting',
    'request': 'rikvest',
    'response': 'rispons',
    'endpoint': 'endpoynt',
    'route': 'rut',
    'router': 'rutır',
    'controller': 'kıntroulır',
    'service': 'sırvıs',
    'model': 'model',
    'view': 'vyu',
    'component': 'kımpounınt',
    'props': 'props',
    'hook': 'huk',
    'context': 'kontekst',
    'provider': 'pırvaydır',
    'store': 'stor',
    'reducer': 'ridusır',
    'action': 'ekşın',
    'dispatch': 'dispeç',
    'middleware': 'midlveır',
    'async': 'eysink',
    'await': 'eveyit',
    'promise': 'promis',
    'callback': 'kolbek',
    'event': 'ivent',
    'listener': 'lisınır',
    'handler': 'hendlır',
    'trigger': 'trigır',
    'queue': 'kyu',
    'job': 'cob',
    'worker': 'vırkır',
    'cron': 'kron',
    'batch': 'beç',
    'buffer': 'bafır',
    'chunk': 'çank',
    'file': 'fayl',
    'folder': 'fouldır',
    'path': 'pet',
    'directory': 'dayrektori',
    'root': 'rut',
    'asset': 'eset',
    'resource': 'risors',
    'config': 'konfig',
    'environment': 'invayrınmınt',
    'variable': 'veriıbıl',
    'constant': 'konstınt',
    'function': 'fankşın',
    'method': 'metıd',
    'class': 'kles',
    'object': 'obcekt',
    'array': 'erey',
    'list': 'list',
    'map': 'mep',
    'set': 'set',
    'string': 'string',
    'boolean': 'buliın',
    'null': 'nal',
    'undefined': 'andifaynd',
    'true': 'tru',
    'false': 'fols',
    'loop': 'lup',
    'while': 'vayl',
    'if': 'if',
    'else': 'els',
    'switch': 'sviç',
    'break': 'breyk',
    'continue': 'kıntinyu',
    'return': 'ritırn',
    'throw': 'trou',
    'catch': 'keç',
    'try': 'tray',
    'finally': 'faynıli',
    'import': 'import',
    'export': 'eksport',
    'default': 'difolt',
    'dependency': 'dipendınsi',
    'semver': 'semvır',
    'webpack': 'vebpek',
    'vite': 'vit',
    'babel': 'beybıl',
    'eslint': 'eslint',
    'prettier': 'pritiyır',
    'jest': 'cest',
    'mocha': 'mouka',
    'cypress': 'sayprıs',
    'playwright': 'pleyrayt',
    'storybook': 'storibuk',

    // Yazılım ekosistemi
    'typescript': 'taypskript',
    'javascript': 'cavaskript',
    'node': 'noud',
    'nodejs': 'noud ce es',
    'angular': 'engyulır',
    'vue': 'vyu',
    'svelte': 'svelt',
    'nextjs': 'nekst ce es',
    'nuxt': 'nakst',
    'django': 'cango',
    'flask': 'flask',
    'spring': 'spring',
    'laravel': 'laravel',
    'wordpress': 'vırdpres',
    'woocommerce': 'vukomırs',
    'jquery': 'cey kveri',
    'redux': 'ridaks',
    'graphql': 'grafikl',
    'grpc': 'ci ar pi si',
    'websocket': 'vebsoket',
    'webhook': 'vebhuk',
    'oauth': 'ouot',
    'jwt': 'cey dabılyu ti',
    'sso': 'es es ou',
    'mfa': 'em ef ey',
    'otp': 'ou ti pi',
    'captcha': 'kepça',
    'smtp': 'es em ti pi',
    'imap': 'ay em ey pi',
    'pop3': 'pop üç',
    'lambda': 'lambda',
    'serverless': 'sırvırles',
    'microservice': 'maykrosırvıs',
    'hypervisor': 'haypırvayzır',
    'kernel': 'kırnıl',
    'zsh': 'zi es eyç',
    'console': 'konsol',
    'command': 'komand',
    'compiler': 'kımpaylır',
    'interpreter': 'intırpritır',
    'runtime': 'runtaym',
    'bytecode': 'baytkod',
    'binary': 'bayneri',
    'license': 'laysıns',
    'refactor': 'rifektır',
    'legacy': 'legısi',
    'scalability': 'skeylebiliti',
    'latency': 'leysınsi',
    'bandwidth': 'bendvidt',
    'uptime': 'aptaym',
    'incident': 'insidınt',
    'postmortem': 'poustmortem',
    'sprint': 'sprint',
    'kanban': 'kanban',
    'scrum': 'skram',
    'agile': 'ecayl',
    'milestone': 'maylston',
    'stakeholder': 'steykhouldır',
    'wireframe': 'vayırfreym',
    'rfc': 'ar ef si',
    'adr': 'ey di ar',
    'okr': 'ou key ar',
    'sla': 'es el ey',
    'sre': 'es ar i',
    'devops': 'devops',
    'infrastructure': 'infrastrıkcır',
    'helm': 'helm',
    'nginx': 'enci eks',
    'tomcat': 'tomket',
    'kafka': 'kafka',
    'rabbitmq': 'rabit em kyu',
    'kibana': 'kibana',
    'jaeger': 'yegır',
    'zipkin': 'zipkin',
    'datadog': 'deytadog',
    'sentry': 'sentri',
    'pagerduty': 'peycırduti',
    'jira': 'cira',
    'trello': 'trello',
    'asana': 'asana',
    'figma': 'figma',
    'zeplin': 'zeplin',
    'miro': 'miro',
    'calendly': 'kalendli',
    'gmail': 'cimeyl',
    'onedrive': 'vandrav',
    'evernote': 'evırnout',
    'todoist': 'tuduist',
    'obsidian': 'obsidiyın',
    'keynote': 'kinout',
    'pages': 'peycız',
    'numbers': 'nambırz',
    'premiere': 'premiır',
    'blender': 'blendır',
    'unity': 'yunıti',
    'unreal': 'anril',
    'godot': 'godou',
    'minecraft': 'maynkreft',
    'fortnite': 'fortnayt',
    'valorant': 'valırınt',
    'dota': 'douta',
    'epic': 'epik',
    'ipad': 'ayped',
    'macbook': 'mekbuk',
    'macos': 'mek os',
    'chromebook': 'kroumbuk',
    'airpods': 'eırpods',
    'imac': 'aymek',
    'icloud': 'ayklaud',

    // Markalar / ürünler
    'google': 'gugıl',
    'youtube': 'yutub',
    'amazon': 'amazın',
    'whatsapp': 'vatsap',
    'tiktok': 'tiktok',
    'instagram': 'instegram',
    'facebook': 'feysbuk',
    'twitter': 'tvitır',
    'snapchat': 'snapçet',
    'pinterest': 'pintırıst',
    'reddit': 'redit',
    'tumblr': 'tamblır',
    'linkedin': 'linkdın',
    'telegram': 'telıgrem',
    'discord': 'diskord',
    'slack': 'slek',
    'zoom': 'zum',
    'skype': 'skayp',
    'teams': 'timz',
    'webex': 'vebeks',
    'spotify': 'spotifay',
    'netflix': 'netfliks',
    'hulu': 'hulu',
    'disney': 'dizni',
    'prime': 'praym',
    'apple': 'epıl',
    'microsoft': 'maykrosoft',
    'meta': 'meta',
    'tesla': 'tesla',
    'spacex': 'speyseks',
    'nasa': 'nasa',
    'unesco': 'unesko',
    'openai': 'oupın ey ay',
    'anthropic': 'entropik',
    'claude': 'klod',
    'chatgpt': 'çet ci pi ti',
    'gemini': 'cemeni',
    'copilot': 'kopaylot',
    'midjourney': 'midcırni',
    'stable': 'steybıl',
    'diffusion': 'difyujın',
    'llama': 'lama',
    'mistral': 'mistral',
    'deepseek': 'dipsik',
    'qwen': 'küven',
    'grok': 'grok',
    'perplexity': 'pırpleksiti',
    'cursor': 'kırsır',
    'windsurf': 'vindsırf',
    'replit': 'replit',
    'vercel': 'vırsıl',
    'netlify': 'netlifay',
    'supabase': 'supabeys',
    'firebase': 'fayırbeys',
    'mongodb': 'mongo di bi',
    'postgres': 'poustgres',
    'mysql': 'may es kü el',
    'sqlite': 'es kü layt',
    'redis': 'redis',
    'docker': 'dokır',
    'kubernetes': 'kubernitis',
    'terraform': 'terrafom',
    'ansible': 'ensibıl',
    'jenkins': 'cenkins',
    'grafana': 'grafana',
    'prometheus': 'prımitiyıs',
    'cloudflare': 'klaudfleır',
    'azure': 'ejır',
    'heroku': 'heroku',
    'digitalocean': 'dicıtıl ouşın',
    'linode': 'laynoud',
    'vultr': 'valtır',
    'npm': 'en pi em',
    'yarn': 'yarn',
    'pnpm': 'pi en pi em',
    'json': 'ceyson',
    'yaml': 'yemıl',
    'sql': 'es kü el',
    'css': 'si es es',
    'html': 'eyç ti em el',
    'xml': 'eks em el',
    'pdf': 'pi di ef',
    'png': 'pi en ci',
    'jpg': 'cey pi ci',
    'gif': 'gif',
    'wav': 'vev',
    'vpn': 'vi pi en',
    'dns': 'di en es',
    'cdn': 'si di en',
    'ssh': 'es es eyç',
    'ftp': 'ef ti pi',
    'tcp': 'ti si pi',
    'udp': 'yu di pi',
    'ip': 'ay pi',
    'os': 'ou es',
    'ui': 'yu ay',
    'ux': 'yu eks',
    'seo': 'es i ou',
    'crm': 'si ar em',
    'erp': 'i ar pi',
    'saas': 'sas',
    'paas': 'pas',
    'iaas': 'yas',
    'mvp': 'em vi pi',
    'kpi': 'key pi ay',
    'roi': 'ar ou ay',
    'ceo': 'si i ou',
    'cto': 'si ti ou',
    'cfo': 'si ef ou',
    'hr': 'eyç ar',
    'pr': 'pi ar',
    'qa': 'kyu ey',
    'vr': 'vi ar',
    'nft': 'en ef ti',
    'dao': 'dey ou',
    'defi': 'di fay',
    'iot': 'ay ou ti',
    'api': 'ey pi ay',
    'sdk': 'es di key',
    'cli': 'si el ay',
    'gui': 'ci yu ay',
    'cpu': 'si pi yu',
    'gpu': 'ci pi yu',
    'ram': 'ram',
    'rom': 'rom',
    'ssd': 'es es di',
    'hdd': 'eyç di di',
    'usb': 'yu es bi',
    'hdmi': 'eyç di em ay',
    'url': 'yu ar el',
    'uri': 'yu ar ay',
    'http': 'eyç ti ti pi',
    'https': 'eyç ti ti pi es',
    'mp3': 'em pi üç',
    'mp4': 'em pi dört',
    '5g': 'beş ge',
    '4k': 'dört key',
    '8k': 'sekiz key',
    '3d': 'üç di',
    '2d': 'iki di',
    'b2b': 'bi tu bi',
    'b2c': 'bi tu si',
    'faq': 'ef ey kyu',
    'asap': 'ey es ey pi',
    'eta': 'i ti ey',
    'aka': 'ey key ey',
    'rsvp': 'ar es vi pi',
    'b12': 'be on iki',

    // Yabancı yer ve marka adları. Türkçe sıklık listesinde de geçtikleri
    // için burada açıkça tanımlanırlar; aksi hâlde hiç çevrilmezler.
    'cambridge': 'kembriç',
    // Yaygın yazım hataları da aynı sesletime gider.
    'cambrigde': 'kembriç',
    'cambirdge': 'kembriç',
    'cambiridge': 'kembriç',
    'oxford': 'oksford',
    'harvard': 'harvard',
    'stanford': 'stanford',
    'windows': 'vindouz',
    'iphone': 'ayfon',
    'samsung': 'samsung',
    'huawei': 'huavey',
    'xiaomi': 'şaomi',
    'sony': 'soni',
    'nokia': 'nokya',
    'intel': 'intel',
    'nvidia': 'envidia',
    'uber': 'uber',
    'paypal': 'peypal',
    'ebay': 'i bey',
    'aliexpress': 'aliekspres',
    'nike': 'nayk',
    'adidas': 'adidas',
    'starbucks': 'starbaks',
    'hollywood': 'holivud',
    'london': 'londra',
    'berlin': 'berlin',
    'tokyo': 'tokyo',
    'dubai': 'dubay',
    'singapore': 'singapur',
    'canada': 'kanada',
    'australia': 'avustralya',
  };

  /// Türkçe kelime listesinde bulunmasa bile asla İngilizce okunmayacak
  /// kelimeler. İngilizceye benzeyen harf kalıpları taşırlar.
  static const Set<String> _protectedTurkish = {
    'ithal',
    'ithalat',
    'müthiş',
    'ishal',
    'reaksiyon',
    'reaksiyoner',
    'koalisyon',
    'koordinasyon',
    'kooperatif',
    'koordinat',
    'organize',
    'organizasyon',
    'realite',
    'teatral',
    'teori',
    'teorik',
    'matematik',
    'problem',
    'sistem',
    'program',
    'telefon',
    'televizyon',
    'internet',
    'bilgisayar',
    'klavye',
    'ekran',
    'kamera',
    'video',
    'radyo',
    'müzik',
    'fotoğraf',
    'futbol',
    'basketbol',
    'voleybol',
    'tenis',
    'otobüs',
    'durak',
    'terminal',
    'transfer',
    'rezervasyon',
    'restoran',
    'otel',
    'pansiyon',
    'apartman',
    'asansör',
    'klima',
    'kombi',
    'petrol',
    'benzin',
    'dizel',
    'motor',
    'şanzıman',
    'fren',
    'direksiyon',
    'sigorta',
    'kasko',
    'trafik',
    'polis',
    'jandarma',
    'mahkeme',
    'avukat',
    'savcı',
    'dava',
    'karar',
    'itiraz',
    'temyiz',
    'hukuk',
    'ekonomi',
    'enflasyon',
    'deflasyon',
    'bütçe',
    'vergi',
    'faiz',
    'kredi',
    'banka',
    'hesap',
    'fatura',
    'makbuz',
    'sözleşme',
    'şirket',
    'fabrika',
    'üretim',
    'tüketim',
    'ihracat',
    'pazarlama',
    'reklam',
    'kampanya',
    'indirim',
    'müşteri',
    'personel',
    'müdür',
    'genel',
    'müdürlük',
    'sekreter',
    'toplantı',
    'sunum',
    'rapor',
    'proje',
    'planlama',
    'strateji',
    'analiz',
    'sonuç',
    'süreç',
    'kalite',
    'kontrol',
    'denetim',
    'güvenlik',
    'yazılım',
    'donanım',
    'ağ',
    'sunucu',
    'veritabanı',
    'uygulama',
    'geliştirici',
    'tasarım',
    'deneyim',
    'iletişim',
    'teknoloji',
    'dijital',
    'mobil',
    'cihaz',
    'batarya',
    'şarj',
    'kablo',
    'adaptör',
    'yazıcı',
    'tarayıcı',
    'fotokopi',
    'kağıt',
    'kalem',
    'defter',
    'dosya',
    'klasör',
    'belge',
    'imza',
    'mühür',
    'randevu',
    'takvim',
    'saat',
    'dakika',
    'saniye',
    'hafta',
    'ay',
    'yıl',
    'gün',
    'gece',
    'sabah',
    'akşam',
    'öğle',
    'ikindi',
    'yarın',
    'dün',
    'bugün',
    'şimdi',
    'sonra',
    'önce',
    'hemen',
    'belki',
    'mutlaka',
    'kesinlikle',
    'asla',
    'bazen',
    'genellikle',
    'nadiren',
  };
}
