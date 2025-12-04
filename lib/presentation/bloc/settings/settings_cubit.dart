import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
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
