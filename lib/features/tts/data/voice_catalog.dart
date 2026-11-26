import 'package:flutter/material.dart';

import '../domain/voice_eq_profile.dart';
import '../domain/voice_profile.dart';

/// Uygulamayla birlikte gelen altı doğal Türkçe konuşmacı.
///
/// Pocket TTS, konuşmacıyı referans kaydıyla klonlar. Elif, Kerem ve Mert
/// modelin kendi referans kayıtlarını kullanır; Zeynep, Defne ve Emre için
/// daha temiz, izin verici lisanslı sentetik referanslar (Canora Turkish ve
/// Clarvia TTS tiny, Apache-2.0) seçildi. Aynı motor farklı referanslarla
/// çalıştırılarak gerçekten farklı tınılar elde edilir.
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
  /// Değerler, altı sesin ham çıktısı ile referans kayıtlarının spektral
  /// dengesi karşılaştırılarak seçildi. Düzeltmeler bilinçli olarak küçük
  /// tutulur; büyük EQ eğrileri sesi doğal tınısından uzaklaştırıyordu.
  ///
  /// Yeni sentetik referanslar (Zeynep, Defne, Emre) zaten dengeli
  /// geldiği için bu seslerde ek EQ uygulanmaz.
  static const Map<String, VoiceEqProfile> _eqProfiles = {
    'female_1': VoiceEqProfile(presenceDb: -1.5),
    'male_2': VoiceEqProfile(
      lowShelfDb: -2.0,
      presenceDb: 3.0,
      airDb: 1.0,
    ),
    'male_3': VoiceEqProfile(lowShelfDb: -2.5, presenceDb: -1.0),
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
