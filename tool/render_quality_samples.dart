// Geliştirici aracı: ham model çıktısından dinleme örnekleri üretir.
//
// Kullanım:
//   dart run tool/render_quality_samples.dart <girdi-klasörü> <çıktı-klasörü>
//
// Girdi klasöründe `raw_<ses>.wav` (24 kHz) dosyaları bulunmalıdır. Araç,
// aynı kaydı eski (legacy), doğal ve düz (flat) işlem zincirlerinden geçirip
// 48 kHz WAV olarak yazar. A/B dinleme testleri içindir.
import 'dart:io';
import 'dart:typed_data';

import 'package:turkce_ses/features/tts/domain/voice_eq_profile.dart';
import 'package:turkce_ses/features/tts/infrastructure/audio_post_processor.dart';
import 'package:turkce_ses/features/tts/infrastructure/audio_resampler.dart';
import 'package:turkce_ses/features/tts/infrastructure/wav_codec.dart';

const _legacyVoiceEq = {
  'female_1': VoiceEqProfile(presenceDb: -1.0, deEsser: 1.0),
  'male_1': VoiceEqProfile(
    lowShelfDb: -2.0,
    presenceDb: 3.0,
    airDb: 2.0,
    deEsser: 0.2,
  ),
};

/// Uygulamadaki `VoiceCatalog._eqProfiles` ile aynı değerler.
const _naturalVoiceEq = {
  'female_1': VoiceEqProfile(presenceDb: -1.5),
  'male_2': VoiceEqProfile(
    lowShelfDb: -2.0,
    presenceDb: 3.0,
    airDb: 1.0,
  ),
  'male_3': VoiceEqProfile(lowShelfDb: -2.5, presenceDb: -1.0),
};

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'Kullanım: dart run tool/render_quality_samples.dart <girdi> <çıktı>',
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

    final variants = <String, Float32List>{
      'legacy': AudioPostProcessor.enhance(
        wav.samples,
        sampleRate: wav.sampleRate,
        voiceEq: _legacyVoiceEq[voice] ?? VoiceEqProfile.neutral,
        targetLufs: -20,
        compressor: true,
        profile: DspProfile.legacy,
      ),
      'natural': AudioPostProcessor.enhance(
        wav.samples,
        sampleRate: wav.sampleRate,
        voiceEq: _naturalVoiceEq[voice] ?? VoiceEqProfile.neutral,
        profile: DspProfile.natural,
      ),
      'flat': AudioPostProcessor.enhance(
        wav.samples,
        sampleRate: wav.sampleRate,
        profile: DspProfile.flat,
      ),
    };

    for (final entry in variants.entries) {
      final samples = entry.value;
      final lufs = AudioPostProcessor.integratedLufs(samples, wav.sampleRate);
      final peak = AudioPostProcessor.truePeakDb(samples);
      final resampled = AudioResampler.resample(samples, wav.sampleRate, 48000);
      final path = '${output.path}/${voice}_${entry.key}.wav';
      File(path).writeAsBytesSync(
        WavCodec.encode(resampled, sampleRate: 48000),
      );
      stdout.writeln(
        '$path  ${lufs.toStringAsFixed(1)} LUFS  '
        '${peak.toStringAsFixed(1)} dBTP',
      );
    }
  }
}
