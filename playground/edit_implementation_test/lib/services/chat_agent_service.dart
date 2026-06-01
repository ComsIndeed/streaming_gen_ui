import 'dart:io' show Platform;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dartantic_ai/dartantic_ai.dart' as ai;
import 'package:http/http.dart' as http;

class ChatAgentService {
  final ai.Agent _agent;

  ChatAgentService._(this._agent);

  factory ChatAgentService.create() {
    final apiKey = const String.fromEnvironment('DEEPSEEK_API_KEY').isNotEmpty
        ? const String.fromEnvironment('DEEPSEEK_API_KEY')
        : (!kIsWeb ? Platform.environment['DEEPSEEK_API_KEY'] : null);

    if (apiKey == null || apiKey.isEmpty) {
      throw ArgumentError(
        'Missing DEEPSEEK_API_KEY environment variable. Please define it via Platform environment or --dart-define=DEEPSEEK_API_KEY=your_key.',
      );
    }

    final provider = DeduplicatedOpenAIProvider(
      apiKey: apiKey,
      baseUrl: Uri.parse('https://api.deepseek.com/v1'),
    );

    // Weather Tool
    final weatherTool = ai.Tool(
      name: 'get_weather',
      description: 'Get current weather and forecast for a city using coordinates.',
      inputSchema: ai.S.object(
        properties: {
          'latitude': ai.S.number(description: 'Latitude coordinate'),
          'longitude': ai.S.number(description: 'Longitude coordinate'),
          'city_name': ai.S.string(description: 'Name of the city'),
        },
        required: ['latitude', 'longitude', 'city_name'],
      ),
      onCall: (args) async {
        final map = args as Map<String, dynamic>;
        final lat = map['latitude'];
        final lon = map['longitude'];
        final response = await http.get(
          Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true'),
        );
        return jsonDecode(response.body);
      },
    );

    // Crypto Tool
    final cryptoTool = ai.Tool(
      name: 'get_crypto_price',
      description: 'Get real-time price and 24h metrics for a cryptocurrency.',
      inputSchema: ai.S.object(
        properties: {
          'coin_id': ai.S.string(description: 'Cryptocurrency coin ID (e.g. bitcoin, ethereum, solana)'),
        },
        required: ['coin_id'],
      ),
      onCall: (args) async {
        final map = args as Map<String, dynamic>;
        final coinId = (map['coin_id'] as String).toLowerCase().trim();
        final response = await http.get(
          Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=$coinId&vs_currencies=usd&include_24hr_change=true&include_24hr_high_low=true'),
        );
        if (response.statusCode != 200) return 'Failed to fetch price.';
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (!data.containsKey(coinId)) return 'Cryptocurrency not found.';
        final coinData = data[coinId] as Map<String, dynamic>;
        final price = coinData['usd'] as num? ?? 0.0;
        final change24h = coinData['usd_24h_change'] as num? ?? 0.0;
        return {
          'symbol': coinId.toUpperCase().substring(0, 3),
          'name': coinId.substring(0, 1).toUpperCase() + coinId.substring(1),
          'price': '\$${price.toStringAsFixed(2)}',
          'change24h': '${change24h >= 0 ? "+" : ""}${change24h.toStringAsFixed(2)}%',
          'isPositive': change24h >= 0,
        };
      },
    );

    final agent = ai.Agent.forProvider(
      provider,
      chatModelName: 'deepseek-chat',
      tools: [weatherTool, cryptoTool],
      enableThinking: false,
    );

    return ChatAgentService._(agent);
  }

  Stream<String> streamResponse(String prompt, List<ai.ChatMessage> history) {
    return _agent.sendStream(prompt, history: history).map((chunk) => chunk.output);
  }
}

class ThinkingDisabledHttpClient extends http.BaseClient {
  final http.Client _inner;
  ThinkingDisabledHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request &&
        request.method == 'POST' &&
        request.url.path.endsWith('/chat/completions')) {
      try {
        final bodyJson = jsonDecode(request.body);
        if (bodyJson is Map<String, dynamic>) {
          bodyJson['thinking'] = {'type': 'disabled'};
          bodyJson.remove('reasoning_effort');
          request.body = jsonEncode(bodyJson);
        }
      } catch (_) {}
    }
    return _inner.send(request);
  }
}

class DeduplicatedOpenAIChatModel extends ai.OpenAIChatModel {
  DeduplicatedOpenAIChatModel({
    required super.name,
    super.apiKey,
    super.tools,
    super.temperature,
    super.defaultOptions,
    super.baseUrl,
    http.Client? client,
  }) : super(client: ThinkingDisabledHttpClient(client ?? http.Client()));

  @override
  Stream<ai.ChatResult<ai.ChatMessage>> sendStream(
    List<ai.ChatMessage> messages, {
    ai.OpenAIChatOptions? options,
    ai.Schema? outputSchema,
  }) {
    return super
        .sendStream(messages, options: options, outputSchema: outputSchema)
        .map((chunk) {
          if (chunk.messages.isNotEmpty && chunk.output.parts.isNotEmpty) {
            final completeMessage = chunk.messages.first;
            final hasToolCalls = completeMessage.parts.any((part) => part is ai.ToolPart);
            if (hasToolCalls) {
              return ai.ChatResult<ai.ChatMessage>(
                id: chunk.id,
                output: ai.ChatMessage(role: ai.ChatMessageRole.model, parts: const []),
                messages: chunk.messages,
                finishReason: chunk.finishReason,
                metadata: chunk.metadata,
                usage: chunk.usage,
              );
            }
          }
          return chunk;
        });
  }
}

class DeduplicatedOpenAIProvider extends ai.OpenAIProvider {
  DeduplicatedOpenAIProvider({super.apiKey, super.baseUrl});

  @override
  ai.ChatModel<ai.OpenAIChatOptions> createChatModel({
    String? name,
    List<ai.Tool>? tools,
    double? temperature,
    bool enableThinking = false,
    ai.OpenAIChatOptions? options,
  }) {
    validateApiKeyPresence();
    return DeduplicatedOpenAIChatModel(
      name: name ?? 'deepseek-chat',
      tools: tools,
      temperature: temperature,
      apiKey: apiKey,
      baseUrl: baseUrl,
      defaultOptions: ai.OpenAIChatOptions(
        temperature: temperature ?? options?.temperature,
        streamOptions: const ai.StreamOptions(includeUsage: true),
      ),
    );
  }
}
