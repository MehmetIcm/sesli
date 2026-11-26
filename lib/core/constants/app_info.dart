/// Uygulama genelinde kullanılan sabit bilgiler.
class AppInfo {
  AppInfo._();

  static const String name = 'Sesli';
  static const String tagline = 'Metniniz, doğal Türkçe sesle.';
  static const String version = '1.2.0';
  static const String buildNumber = '1';
  static const String bundleId = 'com.mehmeticme.turkceSes';

  /// Herkese açık kaynak deposu.
  static const String repositoryUrl = 'https://github.com/MehmetIcm/sesli';

  /// Web sürümünün yayın adresi.
  static const String webAppUrl = 'https://mehmeticm.github.io/sesli/';

  /// Gizlilik ve çerez politikasının web adresi.
  static const String privacyPolicyUrl =
      'https://mehmeticm.github.io/sesli/privacy.html';

  /// Kullanım koşullarının web adresi.
  static const String termsUrl = 'https://mehmeticm.github.io/sesli/terms.html';

  static const String privacySummary =
      'Yazdığınız metinler cihazınızdan dışarı çıkmaz. Sunucu, bulut, '
      'üçüncü taraf API, reklam veya analiz servisi kullanılmaz.';
}
