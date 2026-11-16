import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/pocket_tts_model.dart';

/// macOS'ta model dosyalarını uygulama desteği klasörüne kurar.
///
/// Flutter varlıkları doğrudan ONNX Runtime'a verilemediği için dosyalar ilk
/// çalıştırmada kopyalanır. Sonraki açılışlarda kurulum işareti sayesinde
/// kopyalama atlanır.
class ModelInstaller {
  ModelInstaller._();

  static const String _markerName = '.installed';

  static Future<Map<String, String>> ensureInstalled({
    void Function(double progress)? onProgress,
  }) async {
    final support = await getApplicationSupportDirectory();
    final modelDir = Directory(
      p.join(support.path, 'models', PocketTtsModel.installDirectoryName),
    );

    final paths = <String, String>{
      for (final file in PocketTtsModel.files)
        file: p.join(modelDir.path, file),
    };

    final marker = File(p.join(modelDir.path, _markerName));
    if (await _isComplete(marker, paths)) {
      onProgress?.call(1);
      return paths;
    }

    await modelDir.create(recursive: true);

    for (var index = 0; index < PocketTtsModel.files.length; index++) {
      final fileName = PocketTtsModel.files[index];
      final data = await rootBundle.load(PocketTtsModel.assetPath(fileName));
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final file = File(paths[fileName]!);
      await file.writeAsBytes(bytes, flush: true);
      onProgress?.call((index + 1) / (PocketTtsModel.files.length + 1));
    }

    await marker.writeAsString(
      '${PocketTtsModel.version}\n${DateTime.now().toIso8601String()}\n',
      flush: true,
    );
    onProgress?.call(1);
    return paths;
  }

  static Future<bool> _isComplete(
    File marker,
    Map<String, String> paths,
  ) async {
    if (!await marker.exists()) return false;
    for (final path in paths.values) {
      final file = File(path);
      if (!await file.exists() || await file.length() < 1024) {
        return false;
      }
    }
    return true;
  }

  /// Kurulu model klasörünü siler (ayarlardan temizleme için).
  static Future<void> removeInstalled() async {
    final support = await getApplicationSupportDirectory();
    final modelDir = Directory(
      p.join(support.path, 'models', PocketTtsModel.installDirectoryName),
    );
    if (await modelDir.exists()) {
      await modelDir.delete(recursive: true);
    }
  }
}
