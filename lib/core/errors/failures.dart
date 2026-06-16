import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to access local storage.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred.']);
}

class AIExtractionFailure extends Failure {
  const AIExtractionFailure([
    super.message = 'Could not extract receipt information. Please review manually.',
  ]);
}

class AIInsightsFailure extends Failure {
  const AIInsightsFailure([
    super.message = 'Could not generate spending insights. Please try again.',
  ]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed.']);
}
