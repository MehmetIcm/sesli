// Geliştirici aracı: tek bir ses için EQ profili varyantları üretir.
//
// Kullanım:
//   dart run tool/profile_sweep.dart <ham-wav> <ses-adı> <çıktı-klasörü>
import 'dart:io';

import 'package:turkce_ses/features/tts/domain/voice_eq_profile.dart';
import 'package:turkce_ses/features/tts/infrastructure/audio_post_processor.dart';
import 'package:turkce_ses/features/tts/infrastructure/audio_resampler.dart';
import 'package:turkce_ses/features/tts/infrastructure/wav_codec.dart';

const _variants = <String, VoiceEqProfile>{
  'neutral': VoiceEqProfile.neutral,
  'm05': VoiceEqProfile(presenceDb: -0.5),
  'm1': VoiceEqProfile(presenceDb: -1.0),
  'm15': VoiceEqProfile(presenceDb: -1.5),
  'm2': VoiceEqProfile(presenceDb: -2.0),
  'p1': VoiceEqProfile(presenceDb: 1.0),
  'p2': VoiceEqProfile(presenceDb: 2.0),
  'p3': VoiceEqProfile(presenceDb: 3.0),
  'low1_m05': VoiceEqProfile(lowShelfDb: -1.0, presenceDb: -0.5),
  'low2_m05': VoiceEqProfile(lowShelfDb: -2.0, presenceDb: -0.5),
  'low2_m1': VoiceEqProfile(lowShelfDb: -2.0, presenceDb: -1.0),
  'low25_m1': VoiceEqProfile(lowShelfDb: -2.5, presenceDb: -1.0),
  'low2_p2_air1': VoiceEqProfile(
    lowShelfDb: -2.0,
    presenceDb: 2.0,
    airDb: 1.0,
  ),
  'low15_p2_air05': VoiceEqProfile(
    lowShelfDb: -1.5,
    presenceDb: 2.0,
    airDb: 0.5,
  ),
  'low1_p25_air15': VoiceEqProfile(
    lowShelfDb: -1.0,
    presenceDb: 2.5,
    airDb: 1.5,
  ),
  'low2_p3_air1': VoiceEqProfile(
    lowShelfDb: -2.0,
    presenceDb: 3.0,
    airDb: 1.0,
  ),
  'm1_air_m1': VoiceEqProfile(presenceDb: -1.0, airDb: -1.0),
  'm15_air_m1': VoiceEqProfile(presenceDb: -1.5, airDb: -1.0),
  'm1_air_m2': VoiceEqProfile(presenceDb: -1.0, airDb: -2.0),
  'p15_air15_de0': VoiceEqProfile(
    presenceDb: -1.5,
    airDb: -1.5,
    deEsser: 0,
  ),
  'p15_air15_de08': VoiceEqProfile(
    presenceDb: -1.5,
    airDb: -1.5,
    deEsser: 0.8,
  ),
  'de0': VoiceEqProfile(deEsser: 0),
  'de025': VoiceEqProfile(deEsser: 0.25),
  'de05': VoiceEqProfile(deEsser: 0.5),
};

void main(List<String> args) {
  if (args.length != 3) {
    stderr.writeln(
      'Kullanım: dart run tool/profile_sweep.dart <ham-wav> <ses> <çıktı>',
    );
    exit(64);
  }
  final wav = WavCodec.decode(File(args[0]).readAsBytesSync());
  final voice = args[1];
  final output = Directory(args[2])..createSync(recursive: true);

  for (final entry in _variants.entries) {
    final enhanced = AudioPostProcessor.enhance(
      wav.samples,
      sampleRate: wav.sampleRate,
      voiceEq: entry.value,
      profile: DspProfile.natural,
    );
    final resampled = AudioResampler.resample(
      enhanced,
      wav.sampleRate,
      48000,
    );
    final path = '${output.path}/${voice}_${entry.key}.wav';
    File(path).writeAsBytesSync(
      WavCodec.encode(resampled, sampleRate: 48000),
    );
    stdout.writeln(path);
  }
}
