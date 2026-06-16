class ApiConstants {
  ApiConstants._();

  /// Loaded from compile-time environment variable to keep it secure.
  /// Pass it when running/building via:
  /// flutter run --dart-define=GEMINI_API_KEY=AIzaSyAr0...
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY',
  );

  /// Gemini model to use for receipt extraction and insights
  static const String geminiModel = 'gemini-2.5-flash';
}
