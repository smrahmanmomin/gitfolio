import 'package:equatable/equatable.dart';
import '../../../data/models/github_user_model.dart';
import '../../../data/models/repository_model.dart';

/// Base class for all GitHub BLoC states.
///
/// All states in the [GithubBloc] should extend this class.
abstract class GithubState extends Equatable {
  const GithubState();

  @override
  List<Object?> get props => [];
}

// ==================== Initial State ====================

/// Initial state when the BLoC is first created.
///
/// This is the default state before any events are dispatched.
class GithubInitial extends GithubState {
  const GithubInitial();

  @override
  String toString() => 'GithubInitial';
}

// ==================== Loading States ====================

/// State indicating that an operation is in progress.
///
/// The [message] provides context about what is being loaded.
class GithubLoading extends GithubState {
  /// Optional message describing what is being loaded
  final String message;

  const GithubLoading({this.message = 'Loading...'});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'GithubLoading { message: $message }';
}

// ==================== Authentication States ====================

/// State indicating successful authentication.
///
/// Contains the access token that can be used for subsequent API calls.
class GithubAuthenticated extends GithubState {
  /// The GitHub access token
  final String token;

  const GithubAuthenticated({required this.token});

  @override
  List<Object?> get props => [token];

  @override
  String toString() =>
      'GithubAuthenticated { token: ${token.substring(0, 10)}... }';
}

// ==================== Success States ====================

/// State indicating that user data has been successfully loaded.
///
/// This state contains the authenticated user's profile information
/// and optionally their repositories and contribution data.
class GithubUserLoaded extends GithubState {
  /// The authenticated user's data
  final GithubUserModel user;

  /// The user's repositories (if loaded)
  final List<RepositoryModel>? repositories;

  /// The user's contribution data (if loaded)
  final Map<String, dynamic>? contributions;

  /// The current page for repository pagination
  final int currentPage;

  /// Whether there are more repositories to load
  final bool hasMoreRepos;

  /// The access token for subsequent requests
  final String token;

  const GithubUserLoaded({
    required this.user,
    this.repositories,
    this.contributions,
    this.currentPage = 1,
    this.hasMoreRepos = true,
    required this.token,
  });

  /// Creates a copy of this state with updated values.
  GithubUserLoaded copyWith({
    GithubUserModel? user,
    List<RepositoryModel>? repositories,
    Map<String, dynamic>? contributions,
    int? currentPage,
    bool? hasMoreRepos,
    String? token,
  }) {
    return GithubUserLoaded(
      user: user ?? this.user,
      repositories: repositories ?? this.repositories,
      contributions: contributions ?? this.contributions,
      currentPage: currentPage ?? this.currentPage,
      hasMoreRepos: hasMoreRepos ?? this.hasMoreRepos,
      token: token ?? this.token,
    );
  }

  @override
  List<Object?> get props => [
        user,
        repositories,
        contributions,
        currentPage,
        hasMoreRepos,
        token,
      ];

  @override
  String toString() =>
      'GithubUserLoaded { user: ${user.login}, repos: ${repositories?.length ?? 0}, page: $currentPage }';
}

/// State indicating that repositories have been successfully loaded.
///
/// This is a transitional state used when only repositories are fetched
/// without user data.
class GithubReposLoaded extends GithubState {
  /// The list of repositories
  final List<RepositoryModel> repositories;

  /// The current page for pagination
  final int currentPage;

  /// Whether there are more repositories to load
  final bool hasMoreRepos;

  /// The access token
  final String token;

  const GithubReposLoaded({
    required this.repositories,
    required this.currentPage,
    required this.hasMoreRepos,
    required this.token,
  });

  @override
  List<Object?> get props => [repositories, currentPage, hasMoreRepos, token];

  @override
  String toString() =>
      'GithubReposLoaded { count: ${repositories.length}, page: $currentPage, hasMore: $hasMoreRepos }';
}

// ==================== Error States ====================

/// State indicating that an error occurred.
///
/// Contains information about the error including the message and optional details.
class GithubError extends GithubState {
  /// The error message
  final String message;

  /// Additional error details
  final String? details;

  /// The type of error (e.g., 'network', 'auth', 'api')
  final String? errorType;

  /// Optional previous state to allow recovery
  final GithubState? previousState;

  const GithubError({
    required this.message,
    this.details,
    this.errorType,
    this.previousState,
  });

  /// Creates an authentication error state.
  factory GithubError.authentication({
    String? message,
    String? details,
    GithubState? previousState,
  }) {
    return GithubError(
      message: message ?? 'Authentication failed',
      details: details,
      errorType: 'auth',
      previousState: previousState,
    );
  }

  /// Creates a network error state.
  factory GithubError.network({
    String? message,
    String? details,
    GithubState? previousState,
  }) {
    return GithubError(
      message: message ?? 'Network error',
      details: details,
      errorType: 'network',
      previousState: previousState,
    );
  }

  /// Creates an API error state.
  factory GithubError.api({
    String? message,
    String? details,
    GithubState? previousState,
  }) {
    return GithubError(
      message: message ?? 'API error',
      details: details,
      errorType: 'api',
      previousState: previousState,
    );
  }

  @override
  List<Object?> get props => [message, details, errorType, previousState];

  @override
  String toString() {
    final buffer = StringBuffer('GithubError { message: $message');
    if (errorType != null) {
      buffer.write(', type: $errorType');
    }
    if (details != null) {
      buffer.write(', details: $details');
    }
    buffer.write(' }');
    return buffer.toString();
  }
}
