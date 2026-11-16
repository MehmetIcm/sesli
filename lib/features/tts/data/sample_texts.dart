class SampleText {
  const SampleText(this.label, this.text);

  final String label;
  final String text;
}

/// Denemek için hazır Türkçe metinler.
class SampleTexts {
  SampleTexts._();

  static const List<SampleText> all = [
    SampleText(
      'Günlük',
      'Merhaba! Bugün 6 Kasım 2026, saat 14.30. Hava 18°C ve hafif '
          'yağmurlu. Saat 19.00\'da arkadaşlarımla buluşacağım. '
          'Yolculuk yaklaşık 25 dakika sürecek.',
    ),
    SampleText(
      'Haber',
      'Türkiye Büyük Millet Meclisi\'nde yeni yasa tasarısı kabul edildi. '
          'Bakanlık, 2027 yılı için 1.250.000 TL\'lik yatırım planını '
          'açıkladı. Projenin yüzde 65\'i tamamlandı; kalan kısmın '
          'gelecek yıl bitirilmesi bekleniyor.',
    ),
    SampleText(
      'Hikâye',
      'Küçük kasabanın en yaşlı çınarı, her sabah güneşle birlikte '
          'uyanırdı. Bir gün, dallarının arasında parlayan bir anahtar '
          'buldu. Anahtarı eline alan çocuk, bunun sıradan bir anahtar '
          'olmadığını hemen anladı.',
    ),
    SampleText(
      'Teknik',
      'Sesli, 24 kHz örnekleme hızında çalışan bir Pocket TTS modeli '
          'kullanır. Model tamamen cihaz üzerinde çalışır; metinler '
          'sunucuya gönderilmez. Çıktı, 48 kHz ve 160 kbps mono MP3 '
          'olarak kaydedilir.',
    ),
  ];
}
