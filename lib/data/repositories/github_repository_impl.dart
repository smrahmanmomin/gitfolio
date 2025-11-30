import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/github_repository.dart';
import '../datasources/github_remote_data_source.dart';
import '../models/github_user_model.dart';
import '../models/repository_model.dart';

/// Implementation of [GithubRepository].
///
/// This class bridges the data layer and domain layer, converting
/// data models to domain entities and handling error mapping.
class GithubRepositoryImpl implements GithubRepository {
  final GithubRemoteDataSource remoteDataSource;

  GithubRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> authenticate(String code) async {
    try {
      final token = await remoteDataSource.authenticateWithGitHub(code);
      return Right(token);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message, details: e.details));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, details: e.details));
    } on Exception catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GithubUserModel>> getUser(String token) async {
    try {
      final user = await remoteDataSource.getUserData(token);
      return Right(user);
    } on GitHubApiException catch (e) {
      return Left(ApiFailure(e.message, details: e.details));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message, details: e.details));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, details: e.details));
    } on Exception catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<RepositoryModel>>> getRepositories(
    String token, {
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final repos = await remoteDataSource.getUserRepos(
        token,
        page: page,
        perPage: perPage,
      );
      return Right(repos);
    } on GitHubApiException catch (e) {
      return Left(ApiFailure(e.message, details: e.details));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message, details: e.details));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, details: e.details));
    } on Exception catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getContributions(
    String token,
  ) async {
    try {
      final contributions = await remoteDataSource.getContributions(token);
      return Right(contributions);
    } on GitHubApiException catch (e) {
      return Left(ApiFailure(e.message, details: e.details));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message, details: e.details));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, details: e.details));
    } on Exception catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
