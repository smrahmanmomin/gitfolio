import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/models/github_user_model.dart';
import '../../data/models/repository_model.dart';

/// Repository interface for GitHub-related operations.
///
/// This interface defines the contract for data operations in the domain layer.
/// Implementations should handle data fetching, caching, and error mapping.
abstract class GithubRepository {
  /// Authenticates with GitHub using an OAuth code.
  ///
  /// Returns either a [Failure] or the access token string.
  ///
  /// Example:
  /// ```dart
  /// final result = await repository.authenticate(code);
  /// result.fold(
  ///   (failure) => print('Error: ${failure.message}'),
  ///   (token) => print('Success: $token'),
  /// );
  /// ```
  Future<Either<Failure, String>> authenticate(String code);

  /// Fetches the authenticated user's data.
  ///
  /// Returns either a [Failure] or a [GithubUserModel].
  ///
  /// Example:
  /// ```dart
  /// final result = await repository.getUser(token);
  /// result.fold(
  ///   (failure) => print('Error: ${failure.message}'),
  ///   (user) => print('User: ${user.login}'),
  /// );
  /// ```
  Future<Either<Failure, GithubUserModel>> getUser(String token);

  /// Fetches the user's repositories.
  ///
  /// [token] - The GitHub access token
  /// [page] - The page number for pagination (default: 1)
  /// [perPage] - Number of items per page (default: 30)
  ///
  /// Returns either a [Failure] or a list of [RepositoryModel].
  ///
  /// Example:
  /// ```dart
  /// final result = await repository.getRepositories(token, page: 1);
  /// result.fold(
  ///   (failure) => print('Error: ${failure.message}'),
  ///   (repos) => print('Found ${repos.length} repositories'),
  /// );
  /// ```
  Future<Either<Failure, List<RepositoryModel>>> getRepositories(
    String token, {
    int page = 1,
    int perPage = 30,
  });

  /// Fetches the user's contribution data.
  ///
  /// Returns either a [Failure] or a map containing contribution statistics.
  ///
  /// Example:
  /// ```dart
  /// final result = await repository.getContributions(token);
  /// result.fold(
  ///   (failure) => print('Error: ${failure.message}'),
  ///   (data) => print('Contributions: $data'),
  /// );
  /// ```
  Future<Either<Failure, Map<String, dynamic>>> getContributions(String token);
}
