// ignore_for_file: avoid_print

import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:shine_dart/shine_dart.dart';

void main() {
  final cfg = ShineConfig(
    wave: ShineWave(channels: Channels.pcmMono, samplerate: 44100),
    mpeg: ShineMpeg(mode: StereoMode.mono, bitr: 128),
  );
  final enc = shineInitialise(cfg)!;
  const sr = 44100;
  final n = sr * 2;
  final pcm = Int16List(n);
  for (var i = 0; i < n; i++) {
    pcm[i] = (sin(2 * pi * 440 * i / sr) * 0.5 * 32767).round();
  }
  final per = shineSamplesPerPass(enc);
  final out = BytesBuilder();
  var off = 0;
  while (off + per <= n) {
    final chunk = Int16List.sublistView(pcm, off, off + per);
    final r = shineEncodeBufferInterleaved(enc, chunk);
    out.add(Uint8List.fromList(Uint8List.sublistView(r.buffer, 0, r.length)));
    off += per;
  }
  final f = shineFlush(enc);
  out.add(Uint8List.fromList(Uint8List.sublistView(f.buffer, 0, f.length)));
  shineClose(enc);
  final bytes = out.takeBytes();
  File('/tmp/shine_test.mp3').writeAsBytesSync(bytes);
  print('samplesPerPass=$per wrote ${bytes.length} bytes');
}
