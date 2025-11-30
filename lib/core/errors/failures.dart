/// Base class for all failures in the application.
///
/// Failures represent errors that occur during business logic execution
/// and are returned as part of the Either type from the repository layer.
abstract class Failure {
  final String message;
  final String? details;

  const Failure(this.message, {this.details});

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (details != null && details!.isNotEmpty) {
      buffer.write('\nDetails: $details');
    }
    return buffer.toString();
  }
}

/// Failure that occurs during server communication.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.details});
}

/// Failure that occurs during local caching operations.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.details});
}

/// Failure that occurs due to network connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.details});
}

/// Failure that occurs during authentication or authorization.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.details});
}

/// Failure that occurs during API communication.
class ApiFailure extends Failure {
  const ApiFailure(super.message, {super.details});
}

/// Failure that occurs during data validation.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.details});
}
