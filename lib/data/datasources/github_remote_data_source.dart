import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/github_user_model.dart';
import '../models/repository_model.dart';

/// Remote data source for GitHub API operations.
///
/// This class handles all HTTP requests to the GitHub API, including
/// authentication, user data retrieval, and repository information.
abstract class GithubRemoteDataSource {
  /// Authenticates with GitHub using OAuth and returns the access token.
  ///
  /// Throws [AuthException] if authentication fails.
  /// Throws [NetworkException] if there's a network error.
  Future<String> authenticateWithGitHub(String code);

  /// Fetches the authenticated user's data.
  ///
  /// Throws [GitHubApiException] if the API request fails.
  /// Throws [NetworkException] if there's a network error.
  /// Throws [AuthException] if the token is invalid.
  Future<GithubUserModel> getUserData(String token);

  /// Fetches the user's repositories.
  ///
  /// [token] - The GitHub access token
  /// [page] - The page number for pagination (default: 1)
  /// [perPage] - Number of items per page (default: 30)
  ///
  /// Throws [GitHubApiException] if the API request fails.
  /// Throws [NetworkException] if there's a network error.
  Future<List<RepositoryModel>> getUserRepos(
    String token, {
    int page = 1,
    int perPage = 30,
  });

  /// Fetches the user's contribution data.
  ///
  /// Returns a map with contribution statistics and activity data.
  ///
  /// Throws [GitHubApiException] if the API request fails.
  /// Throws [NetworkException] if there's a network error.
  Future<Map<String, dynamic>> getContributions(String token);
}

/// Implementation of [GithubRemoteDataSource] using the http package.
class GithubRemoteDataSourceImpl implements GithubRemoteDataSource {
  final http.Client client;

  GithubRemoteDataSourceImpl({required this.client});

  @override
  Future<String> authenticateWithGitHub(String code) async {
    try {
      final response = await client
          .post(
        Uri.parse(AppConstants.githubTokenUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': AppConstants.githubClientId,
          'client_secret': AppConstants.githubClientSecret,
          'code': code,
          'redirect_uri': AppConstants.githubRedirectUri,
        }),
      )
          .timeout(
        Duration(seconds: AppConstants.apiTimeout),
        onTimeout: () {
          throw NetworkException.timeout();
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data.containsKey('error')) {
          throw AuthException.oauthFailed(
            reason: data['error_description'] as String? ?? 'Unknown error',
          );
        }

        final accessToken = data['access_token'] as String?;
        if (accessToken == null) {
          throw AuthException.oauthFailed(
            reason: 'No access token in response',
          );
        }

        return accessToken;
      } else {
        throw AuthException.oauthFailed(
          reason: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        throw NetworkException.noConnection();
      }
      throw NetworkException(
        'Failed to authenticate with GitHub',
        details: e.toString(),
      );
    }
  }

  @override
  Future<GithubUserModel> getUserData(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.githubApiBaseUrl}/user'),
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': 'Bearer $token',
          'X-GitHub-Api-Version': AppConstants.githubApiVersion,
        },
      ).timeout(
        Duration(seconds: AppConstants.apiTimeout),
        onTimeout: () {
          throw NetworkException.timeout();
        },
      );

      return _handleUserResponse(response);
    } on GitHubApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        throw NetworkException.noConnection();
      }
      throw GitHubApiException(
        'Failed to fetch user data',
        details: e.toString(),
      );
    }
  }

  @override
  Future<List<RepositoryModel>> getUserRepos(
    String token, {
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final response = await client.get(
        Uri.parse(
          '${AppConstants.githubApiBaseUrl}/user/repos'
          '?sort=updated&page=$page&per_page=$perPage',
        ),
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': 'Bearer $token',
          'X-GitHub-Api-Version': AppConstants.githubApiVersion,
        },
      ).timeout(
        Duration(seconds: AppConstants.apiTimeout),
        onTimeout: () {
          throw NetworkException.timeout();
        },
      );

      return _handleReposResponse(response);
    } on GitHubApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        throw NetworkException.noConnection();
      }
      throw GitHubApiException(
        'Failed to fetch repositories',
        details: e.toString(),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getContributions(String token) async {
    try {
      // First, get the authenticated user to get their username
      final user = await getUserData(token);

      // Fetch contribution stats using GraphQL API
      final query = '''
        query {
          user(login: "${user.login}") {
            contributionsCollection {
              contributionCalendar {
                totalContributions
                weeks {
                  contributionDays {
                    contributionCount
                    date
                  }
                }
              }
            }
          }
        }
      ''';

      final response = await client
          .post(
        Uri.parse(AppConstants.githubGraphqlUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'query': query}),
      )
          .timeout(
        Duration(seconds: AppConstants.apiTimeout),
        onTimeout: () {
          throw NetworkException.timeout();
        },
      );

      return _handleContributionsResponse(response);
    } on GitHubApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        throw NetworkException.noConnection();
      }
      throw GitHubApiException(
        'Failed to fetch contributions',
        details: e.toString(),
      );
    }
  }

  // ==================== Helper Methods ====================

  /// Handles the HTTP response for user data requests.
  GithubUserModel _handleUserResponse(http.Response response) {
    _checkForApiErrors(response);

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return GithubUserModel.fromJson(data);
    } catch (e) {
      throw GitHubApiException.invalidResponse();
    }
  }

  /// Handles the HTTP response for repositories requests.
  List<RepositoryModel> _handleReposResponse(http.Response response) {
    _checkForApiErrors(response);

    try {
      final data = jsonDecode(response.body) as List;
      return data
          .map((repo) => RepositoryModel.fromJson(repo as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw GitHubApiException.invalidResponse();
    }
  }

  /// Handles the HTTP response for contributions requests.
  Map<String, dynamic> _handleContributionsResponse(http.Response response) {
    _checkForApiErrors(response);

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data.containsKey('errors')) {
        throw GitHubApiException(
          'GraphQL error',
          details: data['errors'].toString(),
        );
      }

      return data['data'] as Map<String, dynamic>;
    } catch (e) {
      if (e is GitHubApiException) rethrow;
      throw GitHubApiException.invalidResponse();
    }
  }

  /// Checks the HTTP response for API errors and throws appropriate exceptions.
  void _checkForApiErrors(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      return; // Success
    }

    // Try to parse error message from response
    String? errorMessage;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = data['message'] as String?;
    } catch (_) {
      // Ignore parsing errors
    }

    switch (statusCode) {
      case 401:
        throw AuthException.invalidCredentials();

      case 403:
        // Check if it's a rate limit error
        final rateLimitRemaining = response.headers['x-ratelimit-remaining'];
        if (rateLimitRemaining == '0') {
          final resetTime = response.headers['x-ratelimit-reset'];
          DateTime? resetDateTime;
          if (resetTime != null) {
            try {
              final timestamp = int.parse(resetTime);
              resetDateTime = DateTime.fromMillisecondsSinceEpoch(
                timestamp * 1000,
              );
            } catch (_) {}
          }
          throw GitHubApiException.rateLimitExceeded(resetTime: resetDateTime);
        }
        throw GitHubApiException.forbidden();

      case 404:
        throw GitHubApiException.notFound();

      case 422:
        throw GitHubApiException(
          'Validation failed',
          statusCode: 422,
          details: errorMessage ??
              'The request was well-formed but contains invalid data.',
        );

      case 429:
        throw GitHubApiException.rateLimitExceeded();

      default:
        if (statusCode >= 500) {
          throw GitHubApiException.serverError(statusCode: statusCode);
        }
        throw GitHubApiException(
          errorMessage ?? 'HTTP error $statusCode',
          statusCode: statusCode,
          details: response.body,
        );
    }
  }
}
