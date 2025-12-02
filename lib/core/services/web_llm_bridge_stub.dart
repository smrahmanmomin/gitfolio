/// Stub implementation used on platforms where the browser LLM bridge
/// is unavailable (mobile, desktop, server).
class WebLlmBridge {
  const WebLlmBridge._();

  static bool get isSupported => false;

  static Future<String> generate(String prompt) async {
    throw UnsupportedError('Web-based local LLM is not available.');
  }

  static Future<List<double>> embed(String text) async {
    throw UnsupportedError('Web-based local LLM is not available.');
  }
}
