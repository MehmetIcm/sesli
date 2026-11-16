import 'package:flutter/material.dart';

import '../domain/voice_eq_profile.dart';
import '../domain/voice_profile.dart';

/// Uygulamayla birlikte gelen altı doğal Türkçe konuşmacı.
///
/// Tüm sesler Pocket TTS Türkçe modelinin kendi referans kayıtlarıdır.
/// Aynı model, farklı referans seslerle çalıştırılarak gerçekten farklı
/// tınılar elde edilir.
class VoiceCatalog {
  VoiceCatalog._();

  static const List<VoiceProfile> all = [
    VoiceProfile(
      id: 'female_1',
      name: 'Elif',
      gender: VoiceGender.female,
      description: 'Sıcak ve akıcı',
      referenceAsset: 'assets/voices/female_1.wav',
      previewAsset: 'assets/previews/female_1.wav',
      accent: Color(0xFF0F766E),
      initial: 'E',
    ),
    VoiceProfile(
      id: 'female_2',
      name: 'Zeynep',
      gender: VoiceGender.female,
      description: 'Sakin ve olgun',
      referenceAsset: 'assets/voices/female_2.wav',
      previewAsset: 'assets/previews/female_2.wav',
      accent: Color(0xFF9A5B12),
      initial: 'Z',
    ),
    VoiceProfile(
      id: 'female_3',
      name: 'Defne',
      gender: VoiceGender.female,
      description: 'Genç ve enerjik',
      referenceAsset: 'assets/voices/female_3.wav',
      previewAsset: 'assets/previews/female_3.wav',
      accent: Color(0xFF9D3B62),
      initial: 'D',
    ),
    VoiceProfile(
      id: 'male_1',
      name: 'Emre',
      gender: VoiceGender.male,
      description: 'Net ve güvenilir',
      referenceAsset: 'assets/voices/male_1.wav',
      previewAsset: 'assets/previews/male_1.wav',
      accent: Color(0xFF1D4E89),
      initial: 'E',
    ),
    VoiceProfile(
      id: 'male_2',
      name: 'Kerem',
      gender: VoiceGender.male,
      description: 'Derin ve sakin',
      referenceAsset: 'assets/voices/male_2.wav',
      previewAsset: 'assets/previews/male_2.wav',
      accent: Color(0xFF4A5A3A),
      initial: 'K',
    ),
    VoiceProfile(
      id: 'male_3',
      name: 'Mert',
      gender: VoiceGender.male,
      description: 'Dinamik ve berrak',
      referenceAsset: 'assets/voices/male_3.wav',
      previewAsset: 'assets/previews/male_3.wav',
      accent: Color(0xFF7A4E2D),
      initial: 'M',
    ),
  ];

  /// Ses bazlı EQ profilleri.
  ///
  /// Değerler, altı sesin ölçülen spektrumlarına göre seçilmiş başlangıç
  /// değerleridir; global EQ'nun üzerine uygulanır. `female_1` zaten parlak
  /// olduğu için varlık bölgesi hafifçe kısılır ve de-esser devreye girer.
  static const Map<String, VoiceEqProfile> _eqProfiles = {
    'female_1': VoiceEqProfile(presenceDb: -1.0, deEsser: 1.0),
    'female_2': VoiceEqProfile(
      lowShelfDb: -1.0,
      presenceDb: 2.0,
      airDb: 1.0,
      deEsser: 0.35,
    ),
    'female_3': VoiceEqProfile(
      lowShelfDb: -2.0,
      presenceDb: 3.0,
      airDb: 2.0,
      deEsser: 0.35,
    ),
    'male_1': VoiceEqProfile(
      lowShelfDb: -2.0,
      presenceDb: 3.0,
      airDb: 2.0,
      deEsser: 0.2,
    ),
    'male_2': VoiceEqProfile(
      lowShelfDb: -4.0,
      presenceDb: 4.0,
      airDb: 2.0,
      deEsser: 0.2,
    ),
    'male_3': VoiceEqProfile(
      lowShelfDb: -2.0,
      presenceDb: 3.0,
      airDb: 2.0,
      deEsser: 0.2,
    ),
  };

  static VoiceProfile byId(String? id) {
    return all.firstWhere((voice) => voice.id == id, orElse: () => all.first);
  }

  /// Verilen ses kimliği için EQ profilini döndürür.
  static VoiceEqProfile eqFor(String? id) {
    return _eqProfiles[id] ?? VoiceEqProfile.neutral;
  }

  static List<VoiceProfile> get female =>
      all.where((voice) => voice.gender == VoiceGender.female).toList();

  static List<VoiceProfile> get male =>
      all.where((voice) => voice.gender == VoiceGender.male).toList();
}
