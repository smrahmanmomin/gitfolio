import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<void> savePreviewBytes(Uint8List bytes) async {
  final directory = await getTemporaryDirectory();
  final file = File(
    '${directory.path}/gitfolio_preview_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes, flush: true);
}
