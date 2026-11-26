import 'package:flutter/material.dart';

/// Sesin cinsiyeti. Arayüzde rozet ve simge seçiminde kullanılır.
enum VoiceGender { female, male }

/// Uygulamadaki bir Türkçe konuşmacıyı temsil eder.
///
/// Pocket TTS, konuşmacıyı referans ses kaydıyla klonlar. Bu nedenle her
/// profil bir referans kaydına ve o sesin kısa bir tanıtım kaydına işaret
/// eder. Referansların bir kısmı modelle gelir; bir kısmı ise Apache-2.0
/// lisanslı sentetik Türkçe ses modellerinden üretilmiştir. Çıktıda perde
/// kaydırma (pitch shift) kullanılmaz.
class VoiceProfile {
  const VoiceProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.description,
    required this.referenceAsset,
    required this.previewAsset,
    required this.accent,
    required this.initial,
  });

  /// Modeldeki referans dosyasının kimliği, örn. `female_1`.
  final String id;

  /// Kullanıcıya gösterilen ad.
  final String name;

  final VoiceGender gender;

  /// Kısa tanıtım cümlesi.
  final String description;

  final String referenceAsset;
  final String previewAsset;

  /// Kart vurgu rengi.
  final Color accent;

  /// Avatar baş harfi.
  final String initial;

  String get genderLabel => gender == VoiceGender.female ? 'Kadın' : 'Erkek';

  IconData get genderIcon =>
      gender == VoiceGender.female ? Icons.female_rounded : Icons.male_rounded;
}
