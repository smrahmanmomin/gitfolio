import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/web_llm_bridge.dart';
import '../../../core/models/chat_provider.dart';
import '../../../domain/entities/portfolio_template.dart';

/// Immutable snapshot of all configurable application preferences.
class SettingsState extends Equatable {
  static const Object _sentinel = Object();

  final ThemeMode themeMode;
  final bool compactMode;
  final bool notifyFollowers;
  final bool notifyStars;
  final bool notifyPullRequests;
  final String? selectedTemplateId;
  final String? openAiApiKey;
  final ChatProvider chatProvider;
  final String localLlmBaseUrl;
  final String localLlmModel;
  final String localLlmEmbeddingModel;
  final bool isInitialized;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.compactMode = false,
    this.notifyFollowers = true,
    this.notifyStars = true,
    this.notifyPullRequests = false,
    this.selectedTemplateId,
    this.openAiApiKey,
    this.chatProvider = ChatProvider.local,
    this.localLlmBaseUrl = AppConstants.defaultLocalLlmBaseUrl,
    this.localLlmModel = AppConstants.defaultLocalLlmChatModel,
    this.localLlmEmbeddingModel = AppConstants.defaultLocalLlmEmbeddingModel,
    this.isInitialized = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? compactMode,
    bool? notifyFollowers,
    bool? notifyStars,
    bool? notifyPullRequests,
    Object? selectedTemplateId = _sentinel,
    Object? openAiApiKey = _sentinel,
    ChatProvider? chatProvider,
    String? localLlmBaseUrl,
    String? localLlmModel,
    String? localLlmEmbeddingModel,
    bool? isInitialized,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      compactMode: compactMode ?? this.compactMode,
      notifyFollowers: notifyFollowers ?? this.notifyFollowers,
      notifyStars: notifyStars ?? this.notifyStars,
      notifyPullRequests: notifyPullRequests ?? this.notifyPullRequests,
      selectedTemplateId: selectedTemplateId == _sentinel
          ? this.selectedTemplateId
          : selectedTemplateId as String?,
      openAiApiKey: openAiApiKey == _sentinel
          ? this.openAiApiKey
          : openAiApiKey as String?,
      chatProvider: chatProvider ?? this.chatProvider,
      localLlmBaseUrl: localLlmBaseUrl ?? this.localLlmBaseUrl,
      localLlmModel: localLlmModel ?? this.localLlmModel,
      localLlmEmbeddingModel:
          localLlmEmbeddingModel ?? this.localLlmEmbeddingModel,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  /// Returns the currently selected portfolio template if available.
  PortfolioTemplate? get selectedTemplate {
    if (selectedTemplateId == null) return null;
    try {
      return PortfolioTemplates.all
          .firstWhere((template) => template.id == selectedTemplateId);
    } catch (_) {
      return null;
    }
  }

  bool get hasOpenAiKey => (openAiApiKey?.isNotEmpty ?? false);

  bool get isAssistantReady {
    switch (chatProvider) {
      case ChatProvider.openAi:
        return hasOpenAiKey;
      case ChatProvider.local:
        if (kIsWeb && WebLlmBridge.isSupported) {
          return true;
        }
        return localLlmBaseUrl.trim().isNotEmpty &&
            localLlmModel.trim().isNotEmpty &&
            localLlmEmbeddingModel.trim().isNotEmpty;
    }
  }

  LocalLlmConfig get localLlmConfig => LocalLlmConfig(
        baseUrl: localLlmBaseUrl,
        chatModel: localLlmModel,
        embeddingModel: localLlmEmbeddingModel,
      );

  @override
  List<Object?> get props => [
        themeMode,
        compactMode,
        notifyFollowers,
        notifyStars,
        notifyPullRequests,
        selectedTemplateId,
        openAiApiKey,
        chatProvider,
        localLlmBaseUrl,
        localLlmModel,
        localLlmEmbeddingModel,
        isInitialized,
      ];
}
