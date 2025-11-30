library;

/// Custom exceptions for the GitFolio application.
///
/// This file defines the exception hierarchy used throughout the app
/// for handling various error conditions in a structured way.

// ==================== Base Exception ====================

/// Base exception class for all app-specific exceptions.
///
/// All custom exceptions in the app should extend this class
/// to provide consistent error handling.
abstract class AppException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// Optional additional details about the error.
  final String? details;

  /// Optional stack trace for debugging.
  final StackTrace? stackTrace;

  const AppException(this.message, {this.details, this.stackTrace});

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (details != null && details!.isNotEmpty) {
      buffer.write('\nDetails: $details');
    }
    return buffer.toString();
  }
}

// ==================== Network Exceptions ====================

/// Exception thrown when there's a network connectivity issue.
///
/// This includes no internet connection, timeout errors, or general
/// network failures that prevent API communication.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.details, super.stackTrace});

  /// Creates a NetworkException for connection timeout.
  factory NetworkException.timeout() {
    return const NetworkException(
      'Connection timeout',
      details:
          'The request took too long to complete. Please check your internet connection and try again.',
    );
  }

  /// Creates a NetworkException for no internet connection.
  factory NetworkException.noConnection() {
    return const NetworkException(
      'No internet connection',
      details: 'Please check your internet connection and try again.',
    );
  }

  /// Creates a NetworkException for request cancellation.
  factory NetworkException.cancelled() {
    return const NetworkException(
      'Request cancelled',
      details: 'The network request was cancelled.',
    );
  }
}

// ==================== GitHub API Exceptions ====================

/// Exception thrown when the GitHub API returns an error response.
///
/// This includes HTTP errors like 404 (not found), 403 (forbidden),
/// 401 (unauthorized), and other API-specific errors.
class GitHubApiException extends AppException {
  /// HTTP status code of the error response.
  final int? statusCode;

  const GitHubApiException(
    super.message, {
    this.statusCode,
    super.details,
    super.stackTrace,
  });

  /// Creates a GitHubApiException for 404 Not Found errors.
  factory GitHubApiException.notFound({String? resource}) {
    return GitHubApiException(
      'Resource not found',
      statusCode: 404,
      details: resource != null
          ? 'The requested $resource could not be found.'
          : 'The requested resource could not be found.',
    );
  }

  /// Creates a GitHubApiException for 403 Forbidden errors.
  factory GitHubApiException.forbidden() {
    return const GitHubApiException(
      'Access forbidden',
      statusCode: 403,
      details: 'You do not have permission to access this resource.',
    );
  }

  /// Creates a GitHubApiException for 401 Unauthorized errors.
  factory GitHubApiException.unauthorized() {
    return const GitHubApiException(
      'Unauthorized',
      statusCode: 401,
      details: 'Authentication is required to access this resource.',
    );
  }

  /// Creates a GitHubApiException for rate limit exceeded.
  factory GitHubApiException.rateLimitExceeded({DateTime? resetTime}) {
    final resetInfo = resetTime != null
        ? ' Rate limit will reset at ${resetTime.toLocal()}.'
        : '';
    return GitHubApiException(
      'Rate limit exceeded',
      statusCode: 429,
      details: 'You have exceeded the GitHub API rate limit.$resetInfo',
    );
  }

  /// Creates a GitHubApiException for server errors (5xx).
  factory GitHubApiException.serverError({int? statusCode}) {
    return GitHubApiException(
      'Server error',
      statusCode: statusCode ?? 500,
      details:
          'GitHub\'s servers encountered an error. Please try again later.',
    );
  }

  /// Creates a GitHubApiException for invalid response.
  factory GitHubApiException.invalidResponse() {
    return const GitHubApiException(
      'Invalid response',
      details: 'The server returned an invalid or unexpected response.',
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType');
    if (statusCode != null) {
      buffer.write(' ($statusCode)');
    }
    buffer.write(': $message');
    if (details != null && details!.isNotEmpty) {
      buffer.write('\nDetails: $details');
    }
    return buffer.toString();
  }
}

// ==================== Authentication Exceptions ====================

/// Exception thrown when there's an authentication or authorization issue.
///
/// This includes OAuth failures, invalid tokens, expired sessions,
/// and other authentication-related errors.
class AuthException extends AppException {
  const AuthException(super.message, {super.details, super.stackTrace});

  /// Creates an AuthException for invalid credentials.
  factory AuthException.invalidCredentials() {
    return const AuthException(
      'Invalid credentials',
      details: 'The provided credentials are invalid or have expired.',
    );
  }

  /// Creates an AuthException for expired token.
  factory AuthException.tokenExpired() {
    return const AuthException(
      'Token expired',
      details: 'Your authentication token has expired. Please sign in again.',
    );
  }

  /// Creates an AuthException for OAuth failure.
  factory AuthException.oauthFailed({String? reason}) {
    return AuthException(
      'OAuth authentication failed',
      details:
          reason ?? 'Failed to authenticate with GitHub. Please try again.',
    );
  }

  /// Creates an AuthException for missing token.
  factory AuthException.noToken() {
    return const AuthException(
      'No authentication token',
      details: 'You must be signed in to access this feature.',
    );
  }

  /// Creates an AuthException for cancelled authentication.
  factory AuthException.cancelled() {
    return const AuthException(
      'Authentication cancelled',
      details: 'The authentication process was cancelled by the user.',
    );
  }
}

// ==================== Cache Exceptions ====================

/// Exception thrown when there's an issue with local data caching.
///
/// This includes cache read/write failures and data corruption issues.
class CacheException extends AppException {
  const CacheException(super.message, {super.details, super.stackTrace});

  /// Creates a CacheException for read failures.
  factory CacheException.readFailed({String? key}) {
    return CacheException(
      'Cache read failed',
      details: key != null
          ? 'Failed to read cached data for key: $key'
          : 'Failed to read cached data.',
    );
  }

  /// Creates a CacheException for write failures.
  factory CacheException.writeFailed({String? key}) {
    return CacheException(
      'Cache write failed',
      details: key != null
          ? 'Failed to write data to cache for key: $key'
          : 'Failed to write data to cache.',
    );
  }

  /// Creates a CacheException for corrupted data.
  factory CacheException.dataCorrupted() {
    return const CacheException(
      'Corrupted cache data',
      details: 'The cached data is corrupted or invalid.',
    );
  }
}

// ==================== Server Exceptions ====================

/// Exception thrown when there's a server-side error.
///
/// This is a legacy exception maintained for backward compatibility.
/// Consider using [GitHubApiException.serverError] instead for new code.
class ServerException extends AppException {
  const ServerException(super.message, {super.details, super.stackTrace});
}

// ==================== Validation Exceptions ====================

/// Exception thrown when data validation fails.
///
/// This includes invalid input, missing required fields, or data
/// that doesn't meet expected format or constraints.
class ValidationException extends AppException {
  /// The field that failed validation.
  final String? field;

  const ValidationException(
    super.message, {
    this.field,
    super.details,
    super.stackTrace,
  });

  /// Creates a ValidationException for invalid input.
  factory ValidationException.invalidInput({
    required String field,
    String? reason,
  }) {
    return ValidationException(
      'Invalid input',
      field: field,
      details: reason ?? 'The value provided for $field is invalid.',
    );
  }

  /// Creates a ValidationException for required field.
  factory ValidationException.requiredField(String field) {
    return ValidationException(
      'Required field missing',
      field: field,
      details: 'The field $field is required.',
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType');
    if (field != null) {
      buffer.write(' ($field)');
    }
    buffer.write(': $message');
    if (details != null && details!.isNotEmpty) {
      buffer.write('\nDetails: $details');
    }
    return buffer.toString();
  }
}
