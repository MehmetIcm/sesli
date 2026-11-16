import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

Future<String?> saveMp3(Uint8List bytes, String fileName) async {
  final location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'MP3 ses dosyası',
        extensions: ['mp3'],
        mimeTypes: ['audio/mpeg'],
      ),
    ],
  );
  if (location == null) return null;

  final file = XFile.fromData(bytes, mimeType: 'audio/mpeg', name: fileName);
  await file.saveTo(location.path);
  return location.path;
}
