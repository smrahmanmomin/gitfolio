import 'package:equatable/equatable.dart';

/// Base class for all GitHub-related events.
///
/// All events that can be dispatched to the [GithubBloc] should extend this class.
abstract class GithubEvent extends Equatable {
  const GithubEvent();

  @override
  List<Object?> get props => [];
}

// ==================== Authentication Events ====================

/// Event to authenticate with GitHub using an OAuth code.
///
/// This event is dispatched after the user completes the OAuth flow
/// and returns with an authorization code.
///
/// Example:
/// ```dart
/// context.read<GithubBloc>().add(GithubAuthenticate(code: authCode));
/// ```
class GithubAuthenticate extends GithubEvent {
  /// The OAuth authorization code received from GitHub
  final String code;

  const GithubAuthenticate({required this.code});

  @override
  List<Object?> get props => [code];

  @override
  String toString() => 'GithubAuthenticate { code: $code }';
}

// ==================== User Data Events ====================

/// Event to fetch the authenticated user's data.
///
/// This event requires a valid GitHub access token.
///
/// Example:
/// ```dart
/// context.read<GithubBloc>().add(GithubFetchUser(token: accessToken));
/// ```
class GithubFetchUser extends GithubEvent {
  /// The GitHub access token
  final String token;

  const GithubFetchUser({required this.token});

  @override
  List<Object?> get props => [token];

  @override
  String toString() =>
      'GithubFetchUser { token: ${token.substring(0, 10)}... }';
}

// ==================== Repository Events ====================

/// Event to fetch the user's repositories.
///
/// This event supports pagination through the [page] and [perPage] parameters.
///
/// Example:
/// ```dart
/// context.read<GithubBloc>().add(
///   GithubFetchRepos(
///     token: accessToken,
///     page: 1,
///     perPage: 30,
///   ),
/// );
/// ```
class GithubFetchRepos extends GithubEvent {
  /// The GitHub access token
  final String token;

  /// The page number for pagination (default: 1)
  final int page;

  /// Number of items per page (default: 30)
  final int perPage;

  /// Whether to append to existing repos (for pagination) or replace them
  final bool append;

  const GithubFetchRepos({
    required this.token,
    this.page = 1,
    this.perPage = 30,
    this.append = false,
  });

  @override
  List<Object?> get props => [token, page, perPage, append];

  @override
  String toString() =>
      'GithubFetchRepos { page: $page, perPage: $perPage, append: $append }';
}

// ==================== Contribution Events ====================

/// Event to fetch the user's contribution data.
///
/// This event retrieves contribution statistics and calendar data
/// using the GitHub GraphQL API.
///
/// Example:
/// ```dart
/// context.read<GithubBloc>().add(GithubFetchContributions(token: accessToken));
/// ```
class GithubFetchContributions extends GithubEvent {
  /// The GitHub access token
  final String token;

  const GithubFetchContributions({required this.token});

  @override
  List<Object?> get props => [token];

  @override
  String toString() =>
      'GithubFetchContributions { token: ${token.substring(0, 10)}... }';
}

// ==================== Refresh Events ====================

/// Event to refresh all user data (user info, repos, and contributions).
///
/// This is a convenience event that triggers fetching all data sequentially.
///
/// Example:
/// ```dart
/// context.read<GithubBloc>().add(GithubRefreshData(token: accessToken));
/// ```
class GithubRefreshData extends GithubEvent {
  /// The GitHub access token
  final String token;

  const GithubRefreshData({required this.token});

  @override
  List<Object?> get props => [token];

  @override
  String toString() =>
      'GithubRefreshData { token: ${token.substring(0, 10)}... }';
}

// ==================== Logout Event ====================

/// Event to log out and clear all GitHub data.
///
/// This event resets the BLoC to its initial state.
///
/// Example:
/// ```dart
/// context.read<GithubBloc>().add(const GithubLogout());
/// ```
class GithubLogout extends GithubEvent {
  const GithubLogout();

  @override
  String toString() => 'GithubLogout';
}
