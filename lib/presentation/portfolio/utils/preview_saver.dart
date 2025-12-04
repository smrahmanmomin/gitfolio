import 'dart:typed_data';

import 'preview_saver_stub.dart'
    if (dart.library.io) 'preview_saver_io.dart'
    if (dart.library.html) 'preview_saver_web.dart' as saver;

Future<void> savePreviewBytes(Uint8List bytes) => saver.savePreviewBytes(bytes);
