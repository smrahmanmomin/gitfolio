import 'dart:async';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter, uri_does_not_exist
import 'dart:js_util' as js_util;

/// Bridge to the browser-based local LLM defined in `web/index.html`.
class WebLlmBridge {
  const WebLlmBridge._();

  static dynamic get _bridge =>
      js_util.hasProperty(js_util.globalThis, 'gitfolioLlm')
          ? js_util.getProperty(js_util.globalThis, 'gitfolioLlm')
          : null;

  static bool get isSupported => _bridge != null;

  static Future<String> generate(String prompt) async {
    if (!isSupported) {
      throw StateError('Browser LLM bridge is not loaded.');
    }
    final result = await js_util.promiseToFuture<Object?>(
      js_util.callMethod(_bridge, 'generate', [prompt]),
    );
    return (result as String?)?.trim() ?? '';
  }

  static Future<List<double>> embed(String text) async {
    if (!isSupported) {
      throw StateError('Browser LLM bridge is not loaded.');
    }
    final result = await js_util.promiseToFuture<Object?>(
      js_util.callMethod(_bridge, 'embed', [text]),
    );
    if (result is Float32List) {
      return result.map((value) => value.toDouble()).toList();
    }
    if (result is List) {
      return result.map((value) => (value as num).toDouble()).toList();
    }
    return const [];
  }
}
