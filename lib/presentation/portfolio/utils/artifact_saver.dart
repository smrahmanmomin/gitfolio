import 'dart:typed_data';

import 'artifact_saver_stub.dart'
    if (dart.library.io) 'artifact_saver_io.dart'
    if (dart.library.html) 'artifact_saver_web.dart' as saver;

/// Persists exported artifacts to a user-visible location when possible.
///
/// Returns the file path (or a platform-specific description) when the
/// operation succeeds. When saving is not supported, null is returned.
Future<String?> saveArtifactBytes(Uint8List bytes, String fileName) {
  return saver.saveArtifactBytes(bytes, fileName);
}
