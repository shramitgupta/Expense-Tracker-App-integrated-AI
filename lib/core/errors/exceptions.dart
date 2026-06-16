class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache operation failed.']);

  @override
  String toString() => 'CacheException: $message';
}

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server request failed.']);

  @override
  String toString() => 'ServerException: $message';
}

class AIExtractionException implements Exception {
  final String message;
  const AIExtractionException([
    this.message = 'AI extraction failed.',
  ]);

  @override
  String toString() => 'AIExtractionException: $message';
}

class AIInsightsException implements Exception {
  final String message;
  const AIInsightsException([
    this.message = 'AI insights generation failed.',
  ]);

  @override
  String toString() => 'AIInsightsException: $message';
}
