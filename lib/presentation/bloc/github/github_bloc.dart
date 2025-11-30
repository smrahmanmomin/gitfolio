import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/repository_model.dart';
import '../../../domain/repositories/github_repository.dart';
import 'github_event.dart';
import 'github_state.dart';

/// BLoC for managing GitHub-related state and operations.
///
/// This BLoC handles authentication, user data fetching, repository loading,
/// and contribution data retrieval. It uses the [GithubRepository] to interact
/// with the data layer and manages the state transitions.
///
/// Example usage:
/// ```dart
/// // Authenticate
/// context.read<GithubBloc>().add(GithubAuthenticate(code: authCode));
///
/// // Fetch user data
/// context.read<GithubBloc>().add(GithubFetchUser(token: token));
///
/// // Load repositories
/// context.read<GithubBloc>().add(GithubFetchRepos(token: token));
/// ```
class GithubBloc extends Bloc<GithubEvent, GithubState> {
  final GithubRepository repository;

  GithubBloc({required this.repository}) : super(const GithubInitial()) {
    // Register event handlers
    on<GithubAuthenticate>(_onAuthenticate);
    on<GithubFetchUser>(_onFetchUser);
    on<GithubFetchRepos>(_onFetchRepos);
    on<GithubFetchContributions>(_onFetchContributions);
    on<GithubRefreshData>(_onRefreshData);
    on<GithubLogout>(_onLogout);
  }

  // ==================== Authentication Handler ====================

  /// Handles the [GithubAuthenticate] event.
  ///
  /// If a direct token is provided, emits [GithubAuthenticated] immediately.
  /// Otherwise, exchanges the OAuth code for an access token.
  Future<void> _onAuthenticate(
    GithubAuthenticate event,
    Emitter<GithubState> emit,
  ) async {
    // If token is provided directly (e.g., from saved token), use it
    if (event.token != null) {
      emit(GithubAuthenticated(token: event.token!));
      // Auto-fetch user data
      add(GithubFetchUser(token: event.token!));
      return;
    }

    // Otherwise, exchange OAuth code for token
    emit(const GithubLoading(message: 'Authenticating...'));

    final result = await repository.authenticate(event.code!);

    result.fold(
      (failure) => emit(_mapFailureToError(failure)),
      (token) {
        emit(GithubAuthenticated(token: token));
        // Auto-fetch user data
        add(GithubFetchUser(token: token));
      },
    );
  }

  // ==================== User Data Handler ====================

  /// Handles the [GithubFetchUser] event.
  ///
  /// Fetches the authenticated user's profile data and emits
  /// [GithubUserLoaded] on success or [GithubError] on failure.
  /// Automatically triggers repository fetch after user data loads.
  Future<void> _onFetchUser(
    GithubFetchUser event,
    Emitter<GithubState> emit,
  ) async {
    emit(const GithubLoading(message: 'Loading user data...'));

    final result = await repository.getUser(event.token);

    result.fold((failure) => emit(_mapFailureToError(failure)), (user) {
      // If we have previous state with repos/contributions, preserve them
      if (state is GithubUserLoaded) {
        final currentState = state as GithubUserLoaded;
        emit(
          GithubUserLoaded(
            user: user,
            repositories: currentState.repositories,
            contributions: currentState.contributions,
            currentPage: currentState.currentPage,
            hasMoreRepos: currentState.hasMoreRepos,
            token: event.token,
          ),
        );
      } else {
        emit(GithubUserLoaded(user: user, token: event.token));
        // Auto-fetch repositories after user data loads
        add(GithubFetchRepos(token: event.token));
      }
    });
  }

  // ==================== Repositories Handler ====================

  /// Handles the [GithubFetchRepos] event.
  ///
  /// Fetches the user's repositories with pagination support.
  /// Emits [GithubUserLoaded] or [GithubReposLoaded] on success,
  /// or [GithubError] on failure.
  Future<void> _onFetchRepos(
    GithubFetchRepos event,
    Emitter<GithubState> emit,
  ) async {
    // Don't show loading if we're appending (pagination)
    if (!event.append) {
      emit(const GithubLoading(message: 'Loading repositories...'));
    }

    final result = await repository.getRepositories(
      event.token,
      page: event.page,
      perPage: event.perPage,
    );

    result.fold((failure) => emit(_mapFailureToError(failure)), (repos) {
      // Determine if there are more repos to load
      final hasMore = repos.length >= event.perPage;

      if (state is GithubUserLoaded) {
        // We have user data, update the state with repos
        final currentState = state as GithubUserLoaded;
        final List<RepositoryModel> updatedRepos = event.append
            ? [...(currentState.repositories ?? []), ...repos]
            : repos;

        emit(
          currentState.copyWith(
            repositories: updatedRepos,
            currentPage: event.page,
            hasMoreRepos: hasMore,
          ),
        );
      } else {
        // No user data yet, emit repos-only state
        final existingRepos = state is GithubReposLoaded
            ? (state as GithubReposLoaded).repositories
            : <RepositoryModel>[];

        final updatedRepos =
            event.append ? [...existingRepos, ...repos] : repos;

        emit(
          GithubReposLoaded(
            repositories: updatedRepos,
            currentPage: event.page,
            hasMoreRepos: hasMore,
            token: event.token,
          ),
        );
      }
    });
  }

  // ==================== Contributions Handler ====================

  /// Handles the [GithubFetchContributions] event.
  ///
  /// Fetches the user's contribution data and emits
  /// [GithubUserLoaded] on success or [GithubError] on failure.
  Future<void> _onFetchContributions(
    GithubFetchContributions event,
    Emitter<GithubState> emit,
  ) async {
    emit(const GithubLoading(message: 'Loading contributions...'));

    final result = await repository.getContributions(event.token);

    result.fold((failure) => emit(_mapFailureToError(failure)), (
      contributions,
    ) {
      if (state is GithubUserLoaded) {
        // We have user data, update with contributions
        final currentState = state as GithubUserLoaded;
        emit(currentState.copyWith(contributions: contributions));
      } else {
        // Can't load contributions without user data
        emit(
          const GithubError(
            message: 'User data must be loaded before contributions',
            errorType: 'validation',
          ),
        );
      }
    });
  }

  // ==================== Refresh Handler ====================

  /// Handles the [GithubRefreshData] event.
  ///
  /// Refreshes all user data sequentially: user info, repositories,
  /// and contributions.
  Future<void> _onRefreshData(
    GithubRefreshData event,
    Emitter<GithubState> emit,
  ) async {
    emit(const GithubLoading(message: 'Refreshing data...'));

    // Fetch user data first
    final userResult = await repository.getUser(event.token);

    await userResult.fold(
      (failure) async {
        emit(_mapFailureToError(failure));
      },
      (user) async {
        // User data loaded, now fetch repos
        final reposResult = await repository.getRepositories(event.token);

        await reposResult.fold(
          (failure) async {
            // Emit user with error for repos
            emit(GithubUserLoaded(user: user, token: event.token));
          },
          (repos) async {
            // Repos loaded, now fetch contributions
            final contributionsResult = await repository.getContributions(
              event.token,
            );

            contributionsResult.fold(
              (failure) {
                // Emit user and repos without contributions
                emit(
                  GithubUserLoaded(
                    user: user,
                    repositories: repos,
                    token: event.token,
                  ),
                );
              },
              (contributions) {
                // All data loaded successfully
                emit(
                  GithubUserLoaded(
                    user: user,
                    repositories: repos,
                    contributions: contributions,
                    token: event.token,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ==================== Logout Handler ====================

  /// Handles the [GithubLogout] event.
  ///
  /// Resets the BLoC to its initial state, clearing all user data.
  Future<void> _onLogout(GithubLogout event, Emitter<GithubState> emit) async {
    emit(const GithubInitial());
  }

  // ==================== Helper Methods ====================

  /// Maps a [Failure] to a [GithubError] state.
  ///
  /// This method converts domain failures to appropriate error states
  /// with proper error types and messages.
  GithubError _mapFailureToError(Failure failure) {
    if (failure is AuthFailure) {
      return GithubError.authentication(
        message: failure.message,
        details: failure.details,
        previousState: state,
      );
    } else if (failure is NetworkFailure) {
      return GithubError.network(
        message: failure.message,
        details: failure.details,
        previousState: state,
      );
    } else if (failure is ApiFailure) {
      return GithubError.api(
        message: failure.message,
        details: failure.details,
        previousState: state,
      );
    } else {
      return GithubError(
        message: failure.message,
        details: failure.details,
        previousState: state,
      );
    }
  }
}
