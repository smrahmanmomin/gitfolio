import '../constants/app_constants.dart';

/// Supported backends for the GitFolio Copilot assistant.
enum ChatProvider { openAi, local }

extension ChatProviderLabel on ChatProvider {
  String get label {
    switch (this) {
      case ChatProvider.openAi:
        return 'OpenAI-compatible API';
      case ChatProvider.local:
        return 'Local LLM (Ollama / llama.cpp)';
    }
  }

  String get helper {
    switch (this) {
      case ChatProvider.openAi:
        return 'Use a hosted API key such as OpenAI, Together, or Groq.';
      case ChatProvider.local:
        return 'Send prompts to a self-hosted model (e.g., Ollama on localhost).';
    }
  }

  String get analyticsName {
    switch (this) {
      case ChatProvider.openAi:
        return AppConstants.openAiChatModel;
      case ChatProvider.local:
        return 'Local model';
    }
  }
}

/// Configuration required when running the assistant against a local model.
class LocalLlmConfig {
  const LocalLlmConfig({
    required this.baseUrl,
    required this.chatModel,
    required this.embeddingModel,
  });

  final String baseUrl;
  final String chatModel;
  final String embeddingModel;

  String get _normalizedBaseUrl {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) return AppConstants.defaultLocalLlmBaseUrl;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  Uri get chatUri => Uri.parse('$_normalizedBaseUrl/api/chat');
  Uri get embeddingUri => Uri.parse('$_normalizedBaseUrl/api/embeddings');

  bool get isComplete =>
      baseUrl.trim().isNotEmpty &&
      chatModel.trim().isNotEmpty &&
      embeddingModel.trim().isNotEmpty;

  LocalLlmConfig copyWith({
    String? baseUrl,
    String? chatModel,
    String? embeddingModel,
  }) {
    return LocalLlmConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      chatModel: chatModel ?? this.chatModel,
      embeddingModel: embeddingModel ?? this.embeddingModel,
    );
  }
}
