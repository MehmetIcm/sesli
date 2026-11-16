/// Ses bazlı EQ ve de-esser ayarları.
///
/// Pocket TTS'in altı referans sesi aynı global EQ ile dengeli sonuç
/// vermiyor: erkek sesler belirgin biçimde daha karanlık, `female_1` ise
/// daha parlak ve tıslı. Bu profil, global zincirin üzerine yalnızca o
/// sese özgü küçük düzeltmeler ekler.
class VoiceEqProfile {
  const VoiceEqProfile({
    this.lowShelfDb = 0,
    this.presenceDb = 0,
    this.airDb = 0,
    this.deEsser = 0,
  });

  /// 250 Hz altındaki ek bas kesintisi (dB, negatif değer keser).
  final double lowShelfDb;

  /// 3,4 kHz varlık bölgesindeki ek kazanç (dB).
  final double presenceDb;

  /// 6,5 kHz üstündeki ek raf kazancı (dB).
  final double airDb;

  /// De-esser miktarı (0 = kapalı, 1 = tam).
  final double deEsser;

  static const VoiceEqProfile neutral = VoiceEqProfile();

  bool get isNeutral =>
      lowShelfDb == 0 && presenceDb == 0 && airDb == 0 && deEsser == 0;
}
