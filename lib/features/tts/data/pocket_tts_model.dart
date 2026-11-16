/// Pocket TTS Türkçe model dosyalarının ortak tanımı.
///
/// Model, `wite-tech/pocket-tts-turkish` (CC-BY-4.0) ağırlıklarının
/// INT8 olarak ONNX'e aktarılmış hâlidir. Tüm dosyalar uygulamayla birlikte
/// gelir; çalışma sırasında hiçbir ağ isteği yapılmaz.
class PocketTtsModel {
  PocketTtsModel._();

  static const String name = 'Pocket TTS Türkçe';
  static const String version = '1.0 (INT8 ONNX)';
  static const String license = 'CC-BY-4.0';
  static const String source = 'wite-tech/pocket-tts-turkish';

  static const String assetDirectory = 'assets/models/pocket_tts_tr';
  static const String installDirectoryName = 'pocket_tts_tr';

  static const String lmFlow = 'lm_flow.int8.onnx';
  static const String lmMain = 'lm_main.int8.onnx';
  static const String encoder = 'encoder.onnx';
  static const String decoder = 'decoder.int8.onnx';
  static const String textConditioner = 'text_conditioner.onnx';
  static const String vocab = 'vocab.json';
  static const String tokenScores = 'token_scores.json';

  static const List<String> files = [
    lmFlow,
    lmMain,
    encoder,
    decoder,
    textConditioner,
    vocab,
    tokenScores,
  ];

  /// Dosyaların yaklaşık toplam boyutu (bayt).
  static const int approximateTotalBytes = 143000000;

  static String assetPath(String fileName) => '$assetDirectory/$fileName';
}
