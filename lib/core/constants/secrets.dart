/// API keys are injected at build time via --dart-define flags.
/// Never hardcode secrets in this file.
/// Run the app using the command in .env.example
class Secrets {
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  static const String nvidiaApiKey =
      String.fromEnvironment('NVIDIA_API_KEY');

  static const String groqApiKey =
      String.fromEnvironment('GROQ_API_KEY');

  /// Returns true if all required keys are present at runtime.
  static bool get isConfigured =>
      geminiApiKey.isNotEmpty && groqApiKey.isNotEmpty;
}
