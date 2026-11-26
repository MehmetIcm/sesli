// Geliştirici aracı: ses önizleme dosyalarını doğal DSP ile üretir.
//
// Kullanım:
//   dart run tool/render_previews.dart <girdi-klasörü> <çıktı-klasörü>
//
// Girdi klasöründe `raw_<ses>.wav` (24 kHz) dosyaları bulunur. Çıktı, ses
// kartındaki önizlemeyle aynı zincirden geçmiş 24 kHz WAV'dir.
import 'dart:io';

import 'package:turkce_ses/features/tts/domain/voice_eq_profile.dart';
import 'package:turkce_ses/features/tts/infrastructure/audio_post_processor.dart';
import 'package:turkce_ses/features/tts/infrastructure/wav_codec.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'Kullanım: dart run tool/render_previews.dart <girdi> <çıktı>',
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
    final wav = WavCodec.decode(file.readAsBytesSync());
    if (wav.channels != 1) {
      stderr.writeln('${file.path}: mono değil, atlandı.');
      continue;
    }
    final samples = AudioPostProcessor.enhance(
      wav.samples,
      sampleRate: wav.sampleRate,
      voiceEq: VoiceEqProfile.neutral,
      profile: DspProfile.natural,
    );
    final path = '${output.path}/$name';
    File(path).writeAsBytesSync(
      WavCodec.encode(samples, sampleRate: wav.sampleRate),
    );
    stdout.writeln('$path  ${samples.length / wav.sampleRate} s');
  }
}
