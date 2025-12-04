import 'dart:typed_data';
import 'dart:html' as html;

Future<String?> saveArtifactBytes(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = fileName
    ..click();
  html.Url.revokeObjectUrl(url);
  return fileName;
}
