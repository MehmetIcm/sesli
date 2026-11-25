/// Pocket TTS çıkarımı için ortak üretim parametreleri.
///
/// Bu değerler Web (WASM) ve macOS (ONNX Runtime) motorlarında aynı ses
/// karakterini elde etmek için tek yerden yönetilir.
class PocketTtsParams {
  PocketTtsParams._();

  /// Modelin cümle içi duraklamalarını ölçekler. 1.0 = hiç kısaltma yok.
  /// Uygulama artık cümleleri tek tek ürettiği ve cümle arası payı kendisi
  /// yönettiği için modelin kendi duraklamalarını hafifçe uzatmak yeterli.
  static const double silenceScale = 1.05;

  /// Difüzyon adımı sayısı. Daha yüksek = daha temiz, daha yavaş.
  /// Varsayılan en yüksek kaliteye ayarlıdır; kullanıcı düşürebilir.
  static const int defaultNumSteps = 8;

  /// Örnekleme sıcaklığı. Modelin kendi varsayılanı 0,3'tür; 0,45 daha
  /// canlı bir ezgi verirken kararlılığı korur.
  static const double temperature = 0.45;

  /// Taban tohum. Aynı metin aynı sesle tekrar üretilebilir kalır.
  static const int seed = 42;

  /// Her cümle için tohuma eklenen asal adım.
  ///
  /// Sabit tohum, her cümlenin aynı gürültü dizisiyle üretilmesine ve
  /// ezgilerin birbirine benzemesine yol açıyordu. Cümle başına farklı ama
  /// yine belirlenebilir bir tohum kullanılır.
  static const int seedStride = 104729;

  static int seedForSegment(int index) => seed + index * seedStride;

  /// Kısa cümlelerin birleştirilmesi için alt sınır. Düşük değer, modelin
  /// cümle sonu duraklamalarını korumasını sağlar.
  static const int minCharsInSentence = 20;

  /// Modelin kendi içinde böleceği üst sınır. Dart tarafındaki parçalama
  /// 260 karakter olduğundan bu değer onunla uyumludur.
  static const int maxCharsInSentence = 240;

  /// Modele özgü ek parametreler (JSON olarak iletilir).
  static const Map<String, Object> extra = {
    'temperature': temperature,
    'seed': seed,
    'max_reference_audio_len': 5,
    'min_char_in_sentence': minCharsInSentence,
    'max_char_in_sentence': maxCharsInSentence,
  };

  /// [extra] haritasının belirli bir tohumla kopyası.
  static Map<String, Object> extraForSeed(int value) => {
    ...extra,
    'seed': value,
  };
}
