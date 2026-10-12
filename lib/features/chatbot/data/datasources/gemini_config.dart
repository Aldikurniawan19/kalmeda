/// Configuration manager for Google Gemini AI integration.
/// Contains API credentials, model parameters, and resilience timeout configurations.
class GeminiConfig {
  /// Google Gemini API Key obtained from Google AI Studio (https://aistudio.google.com/).
  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6J5qAhpMmXjjkSywOIgYWFu9o7UPxAnD6k6e9kXkNjJ-w',
  );

  /// Default model identifier.
  /// Prioritized to gemini-3.1-flash-lite-preview.
  static const String model = 'gemini-3.1-flash-lite-preview';

  /// Base endpoint URL for Google Generative Language REST API.
  static const String baseUrl = 'https://generativelanguage.googleapis.com';

  /// Default API version endpoint.
  static const String defaultApiVersion = 'v1beta';

  /// Maximum duration to await response from Google Gemini API before reporting timeout.
  static const Duration timeoutDuration = Duration(seconds: 60);

  /// Helper verifying if an active API key has been populated.
  static bool get isConfigured =>
      apiKey.trim().isNotEmpty && !apiKey.contains('TEMPELKAN');
}
