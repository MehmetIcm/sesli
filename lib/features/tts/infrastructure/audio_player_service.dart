import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Oynatma katmanının denetleyicinin ihtiyaç duyduğu yüzeyi.
///
/// Testlerde gerçek ses aygıtı yerine sahte bir uygulama verilebilir.
abstract class AudioPlayback {
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<void> get completeStream;
  Stream<PlayerState> get stateStream;

  Future<void> playMp3(Uint8List bytes);
  Future<void> playWav(Uint8List bytes);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> playPreview(Uint8List wavBytes);
  Future<void> stopPreview();
  Future<void> dispose();
}

/// Uygulamanın ses oynatma katmanı.
///
/// Ana oynatıcı üretilen MP3'ü, önizleme oynatıcısı ise ses kartlarındaki
/// kısa WAV tanıtımlarını çalar. İki oynatıcı birbirini etkilemez.
class AudioPlayerService implements AudioPlayback {
  AudioPlayerService() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _preview = AudioPlayer();

  @override
  Stream<Duration> get positionStream => _player.onPositionChanged;
  @override
  Stream<Duration> get durationStream => _player.onDurationChanged;
  @override
  Stream<void> get completeStream => _player.onPlayerComplete;
  @override
  Stream<PlayerState> get stateStream => _player.onPlayerStateChanged;

  @override
  Future<void> playMp3(Uint8List bytes) async {
    await _player.stop();
    await _player.setSource(BytesSource(bytes, mimeType: 'audio/mpeg'));
    await _player.resume();
  }

  @override
  Future<void> playWav(Uint8List bytes) async {
    await _player.stop();
    await _player.setSource(BytesSource(bytes, mimeType: 'audio/wav'));
    await _player.resume();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> playPreview(Uint8List wavBytes) async {
    await _preview.stop();
    await _preview.setSource(BytesSource(wavBytes, mimeType: 'audio/wav'));
    await _preview.resume();
  }

  @override
  Future<void> stopPreview() => _preview.stop();

  @override
  Future<void> dispose() async {
    await _player.dispose();
    await _preview.dispose();
  }
}
