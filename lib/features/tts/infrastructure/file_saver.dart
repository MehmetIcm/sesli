import 'dart:typed_data';

import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_native.dart'
    if (dart.library.js_interop) 'file_saver_web.dart'
    as impl;

/// MP3 baytlarını kullanıcının seçtiği konuma kaydeder.
///
/// Web'de tarayıcı indirmesi başlatılır ve dosya adı döner. macOS'ta kayıt
/// iletişim kutusu gösterilir; kullanıcı iptal ederse `null` döner.
Future<String?> saveMp3(Uint8List bytes, String fileName) {
  return impl.saveMp3(bytes, fileName);
}
