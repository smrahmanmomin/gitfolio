/// App-wide constants and configuration values.
///
/// This class contains all the constant values used throughout the application,
/// including GitHub OAuth credentials, API endpoints, and app metadata.
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ==================== App Information ====================

  /// The name of the application
  static const String appName = 'GitFolio';

  /// The current version of the application
  static const String appVersion = '1.0.0';

  /// The build number
  static const String buildNumber = '1';

  // ==================== GitHub OAuth ====================

  /// GitHub OAuth Client ID
  /// TODO: Replace with actual client ID from GitHub OAuth App
  static const String githubClientId = 'Ov23linm3CgD7PSm1Tka';

  /// GitHub OAuth Client Secret
  /// TODO: Replace with actual client secret from GitHub OAuth App
  static const String githubClientSecret =
      '597a4c3546191bd8917e93a5f772a18c9bbdb63f';

  /// GitHub OAuth redirect URI
  /// For GitHub Pages: https://smrahmanmomin.github.io/gitfolio/
  /// For local dev: http://localhost:port/
  static const String githubRedirectUri =
      'https://smrahmanmomin.github.io/gitfolio/';

  /// GitHub OAuth scopes
  static const List<String> githubScopes = ['user', 'repo', 'read:org'];

  /// GitHub OAuth authorization URL
  static const String githubAuthUrl =
      'https://github.com/login/oauth/authorize';

  /// GitHub OAuth token URL
  static const String githubTokenUrl =
      'https://github.com/login/oauth/access_token';

  // ==================== GitHub API ====================

  /// Base URL for GitHub REST API
  static const String githubApiBaseUrl = 'https://api.github.com';

  /// Base URL for GitHub GraphQL API
  static const String githubGraphqlUrl = 'https://api.github.com/graphql';

  /// GitHub API version header
  static const String githubApiVersion = '2022-11-28';

  /// Default API timeout duration in seconds
  static const int apiTimeout = 30;

  /// Maximum number of items per page for paginated requests
  static const int defaultPageSize = 30;

  // ==================== Storage Keys ====================

  /// Key for storing authentication token
  static const String tokenKey = 'auth_token';

  /// Key for storing user data
  static const String userDataKey = 'user_data';

  /// Key for storing cached user
  static const String cachedUserKey = 'CACHED_USER';

  /// Key for storing cached repositories
  static const String cachedReposKey = 'CACHED_REPOS';

  /// Key for storing theme preference
  static const String themeKey = 'theme_mode';

  /// Key for storing language preference
  static const String languageKey = 'language';

  // ==================== Cache Duration ====================

  /// Duration to cache user profile data
  static const Duration userCacheDuration = Duration(hours: 1);

  /// Duration to cache repository data
  static const Duration repositoryCacheDuration = Duration(minutes: 30);

  /// Duration to cache activity data
  static const Duration activityCacheDuration = Duration(minutes: 15);

  // ==================== URLs ====================

  /// GitHub main website URL
  static const String githubWebUrl = 'https://github.com';

  /// Privacy policy URL
  static const String privacyPolicyUrl = 'https://gitfolio.app/privacy';

  /// Terms of service URL
  static const String termsOfServiceUrl = 'https://gitfolio.app/terms';

  /// Support email
  static const String supportEmail = 'support@gitfolio.app';

  // ==================== UI Constants ====================

  /// Default padding value
  static const double defaultPadding = 16.0;

  /// Small padding value
  static const double smallPadding = 8.0;

  /// Large padding value
  static const double largePadding = 24.0;

  /// Default border radius
  static const double defaultBorderRadius = 12.0;

  /// Avatar size
  static const double avatarSize = 48.0;

  /// Large avatar size
  static const double largeAvatarSize = 80.0;

  // ==================== Animation Duration ====================

  /// Default animation duration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  /// Fast animation duration
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);

  /// Slow animation duration
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
}
