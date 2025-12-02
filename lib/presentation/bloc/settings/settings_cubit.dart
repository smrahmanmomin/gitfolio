import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/chat_provider.dart';
import '../../../domain/entities/portfolio_template.dart';
import 'settings_state.dart';

/// Cubit responsible for managing persisted user preferences and settings.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _loadPreferences();
  }

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _loadPreferences() async {
    final prefs = await _preferences;
    final themeValue = prefs.getString(AppConstants.themeKey);
    emit(
      state.copyWith(
        themeMode: _themeFromString(themeValue),
        compactMode: prefs.getBool(AppConstants.compactModeKey) ?? false,
        notifyFollowers: prefs.getBool(AppConstants.notifyFollowersKey) ?? true,
        notifyStars: prefs.getBool(AppConstants.notifyStarsKey) ?? true,
        notifyPullRequests:
            prefs.getBool(AppConstants.notifyPullRequestsKey) ?? false,
        selectedTemplateId: prefs.getString(AppConstants.selectedTemplateKey),
        openAiApiKey: prefs.getString(AppConstants.openAiApiKeyKey),
        chatProvider: _providerFromString(
          prefs.getString(AppConstants.chatProviderKey),
        ),
        localLlmBaseUrl: prefs.getString(AppConstants.localLlmBaseUrlKey) ??
            AppConstants.defaultLocalLlmBaseUrl,
        localLlmModel: prefs.getString(AppConstants.localLlmModelKey) ??
            AppConstants.defaultLocalLlmChatModel,
        localLlmEmbeddingModel:
            prefs.getString(AppConstants.localLlmEmbeddingModelKey) ??
                AppConstants.defaultLocalLlmEmbeddingModel,
        isInitialized: true,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.themeKey, mode.name);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> toggleCompactMode(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.compactModeKey, enabled);
    emit(state.copyWith(compactMode: enabled));
  }

  Future<void> setNotificationPreference({
    bool? followers,
    bool? stars,
    bool? pullRequests,
  }) async {
    final prefs = await _preferences;
    final nextFollowers = followers ?? state.notifyFollowers;
    final nextStars = stars ?? state.notifyStars;
    final nextPullRequests = pullRequests ?? state.notifyPullRequests;
    await prefs.setBool(AppConstants.notifyFollowersKey, nextFollowers);
    await prefs.setBool(AppConstants.notifyStarsKey, nextStars);
    await prefs.setBool(AppConstants.notifyPullRequestsKey, nextPullRequests);
    emit(
      state.copyWith(
        notifyFollowers: nextFollowers,
        notifyStars: nextStars,
        notifyPullRequests: nextPullRequests,
      ),
    );
  }

  Future<void> selectTemplate(String templateId) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.selectedTemplateKey, templateId);
    emit(state.copyWith(selectedTemplateId: templateId));
  }

  Future<void> clearTemplateSelection() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.selectedTemplateKey);
    emit(state.copyWith(selectedTemplateId: null));
  }

  Future<void> saveOpenAiKey(String? apiKey) async {
    final prefs = await _preferences;
    final trimmed = apiKey?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await prefs.remove(AppConstants.openAiApiKeyKey);
      emit(state.copyWith(openAiApiKey: null));
      return;
    }
    await prefs.setString(AppConstants.openAiApiKeyKey, trimmed);
    emit(state.copyWith(openAiApiKey: trimmed));
  }

  Future<void> setChatProvider(ChatProvider provider) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.chatProviderKey, provider.name);
    emit(state.copyWith(chatProvider: provider));
  }

  Future<void> saveLocalLlmConfig({
    required String baseUrl,
    required String chatModel,
    required String embeddingModel,
  }) async {
    final prefs = await _preferences;
    final normalizedBaseUrl = baseUrl.trim().isEmpty
        ? AppConstants.defaultLocalLlmBaseUrl
        : baseUrl.trim();
    final normalizedChatModel = chatModel.trim().isEmpty
        ? AppConstants.defaultLocalLlmChatModel
        : chatModel.trim();
    final normalizedEmbeddingModel = embeddingModel.trim().isEmpty
        ? AppConstants.defaultLocalLlmEmbeddingModel
        : embeddingModel.trim();

    await prefs.setString(AppConstants.localLlmBaseUrlKey, normalizedBaseUrl);
    await prefs.setString(AppConstants.localLlmModelKey, normalizedChatModel);
    await prefs.setString(
      AppConstants.localLlmEmbeddingModelKey,
      normalizedEmbeddingModel,
    );

    emit(
      state.copyWith(
        localLlmBaseUrl: normalizedBaseUrl,
        localLlmModel: normalizedChatModel,
        localLlmEmbeddingModel: normalizedEmbeddingModel,
      ),
    );
  }

  ChatProvider _providerFromString(String? value) {
    if (value == null) return ChatProvider.local;
    return ChatProvider.values.firstWhere(
      (provider) => provider.name == value,
      orElse: () => ChatProvider.local,
    );
  }

  ThemeMode _themeFromString(String? value) {
    if (value == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  /// Returns a human-friendly label for the provided [ThemeMode].
  static String themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System default';
    }
  }

  /// Friendly description of a [PortfolioTemplate] for UI use.
  static String templateDescription(PortfolioTemplate template) {
    return '${template.name} • ${template.theme.fontFamily} • '
        '${template.sections.length} sections';
  }
}
