import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/portfolio_template.dart';

/// Immutable snapshot of all configurable application preferences.
class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool compactMode;
  final bool notifyFollowers;
  final bool notifyStars;
  final bool notifyPullRequests;
  final String? selectedTemplateId;
  final String? openAiApiKey;
  final bool isInitialized;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.compactMode = false,
    this.notifyFollowers = true,
    this.notifyStars = true,
    this.notifyPullRequests = false,
    this.selectedTemplateId,
    this.openAiApiKey,
    this.isInitialized = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? compactMode,
    bool? notifyFollowers,
    bool? notifyStars,
    bool? notifyPullRequests,
    String? selectedTemplateId,
    String? openAiApiKey,
    bool? isInitialized,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      compactMode: compactMode ?? this.compactMode,
      notifyFollowers: notifyFollowers ?? this.notifyFollowers,
      notifyStars: notifyStars ?? this.notifyStars,
      notifyPullRequests: notifyPullRequests ?? this.notifyPullRequests,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      openAiApiKey: openAiApiKey ?? this.openAiApiKey,
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

  @override
  List<Object?> get props => [
        themeMode,
        compactMode,
        notifyFollowers,
        notifyStars,
        notifyPullRequests,
        selectedTemplateId,
        openAiApiKey,
        isInitialized,
      ];
}
