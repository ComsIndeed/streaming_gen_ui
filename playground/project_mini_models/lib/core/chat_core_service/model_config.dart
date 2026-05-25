/// Configuration for an OpenAI-compatible model endpoint.
class ModelConfig {
  final String baseUrl;
  final String modelName;
  final String apiKey;

  /// System prompt / instructions. Sent as a system message per request.
  final String? instructions;

  const ModelConfig({
    required this.baseUrl,
    required this.modelName,
    required this.apiKey,
    this.instructions,
  });

  /// Returns the full chat completions endpoint URL.
  String get endpoint => '$baseUrl/chat/completions';
}
