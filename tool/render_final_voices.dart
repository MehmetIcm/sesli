// Geliştirici aracı: nihai ses seti için DSP varyantları üretir.
//
// Kullanım:
//   dart run tool/render_final_voices.dart <girdi-klasörü> <çıktı-klasörü>
//
// Girdi klasöründe `raw_<ses>.wav` (24 kHz) dosyaları bulunur. Her ses için
// mevcut EQ, nötr EQ ve hafif varyantlar 48 kHz WAV olarak yazılır.
import 'dart:io';

import 'package:turkce_ses/features/tts/domain/voice_eq_profile.dart';
import 'package:turkce_ses/features/tts/infrastructure/audio_post_processor.dart';
import 'package:turkce_ses/features/tts/infrastructure/audio_resampler.dart';
import 'package:turkce_ses/features/tts/infrastructure/wav_codec.dart';

const _existing = <String, VoiceEqProfile>{
  'female_1': VoiceEqProfile(presenceDb: -1.5),
  'male_2': VoiceEqProfile(lowShelfDb: -2.0, presenceDb: 3.0, airDb: 1.0),
  'male_3': VoiceEqProfile(lowShelfDb: -2.5, presenceDb: -1.0),
};

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'Kullanım: dart run tool/render_final_voices.dart <girdi> <çıktı>',
    );
    exit(64);
  }
  final input = Directory(args[0]);
  final output = Directory(args[1])..createSync(recursive: true);

  final files = input
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.wav'))
      .where((file) => file.uri.pathSegments.last.startsWith('raw_'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceFirst('raw_', '');
    final voice = name.replaceAll('.wav', '');
    final wav = WavCodec.decode(file.readAsBytesSync());
    if (wav.channels != 1) {
      stderr.writeln('${file.path}: mono değil, atlandı.');
      continue;
    }

    final variants = <String, VoiceEqProfile>{
      'existing': _existing[voice] ?? VoiceEqProfile.neutral,
      'neutral': VoiceEqProfile.neutral,
      'presence': const VoiceEqProfile(presenceDb: 1.0),
      'deess': const VoiceEqProfile(deEsser: 0.5),
    };

    for (final entry in variants.entries) {
      final samples = AudioPostProcessor.enhance(
        wav.samples,
        sampleRate: wav.sampleRate,
        voiceEq: entry.value,
        profile: DspProfile.natural,
      );
      final resampled = AudioResampler.resample(samples, wav.sampleRate, 48000);
      final path = '${output.path}/${voice}_${entry.key}.wav';
      File(path).writeAsBytesSync(
        WavCodec.encode(resampled, sampleRate: 48000),
      );
      stdout.writeln('$path  ${samples.length / wav.sampleRate} s');
    }
  }
}
