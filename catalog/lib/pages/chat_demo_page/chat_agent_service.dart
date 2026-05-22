import 'dart:io' show Platform;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:http/http.dart' as http;

class ChatAgentService {
  final Agent _agent;

  ChatAgentService._(this._agent);

  /// Factory constructor to create and configure the Agent.
  /// Throws an ArgumentError if the API Key is missing.
  factory ChatAgentService.create({String modelName = 'deepseek-v4-flash'}) {
    const proxyUrl = String.fromEnvironment('NETLIFY_PROXY_URL');
    final String apiKey;
    final Uri baseUrl;

    if (proxyUrl.isNotEmpty) {
      apiKey = 'proxy-placeholder';
      baseUrl = Uri.parse(proxyUrl);
    } else {
      final key = _getApiKey(modelName);
      final isLlama = modelName.contains('llama') || modelName.contains('groq');
      final String keyName = isLlama ? 'GROQ_API_KEY' : 'DEEPSEEK_API_KEY';
      if (key == null || key.isEmpty) {
        throw ArgumentError(
          'Missing $keyName environment variable or NETLIFY_PROXY_URL. '
          'Please define it via Platform environment or --dart-define=$keyName=your_key.',
        );
      }
      apiKey = key;
      baseUrl = isLlama
          ? Uri.parse('https://api.groq.com/openai/v1')
          : Uri.parse('https://api.deepseek.com/v1');
    }

    final provider = DeduplicatedOpenAIProvider(
      apiKey: apiKey,
      baseUrl: baseUrl,
    );

    // 1. Tool to get weather from Open-Meteo API
    final weatherTool = Tool(
      name: 'get_weather',
      description:
          'Get current weather and a 3-day forecast for a given city using latitude and longitude.',
      inputSchema: S.object(
        properties: {
          'latitude': S.number(
            description: 'The latitude coordinate of the city',
          ),
          'longitude': S.number(
            description: 'The longitude coordinate of the city',
          ),
          'city_name': S.string(description: 'The name of the city'),
        },
        required: ['latitude', 'longitude', 'city_name'],
      ),
      onCall: (args) async {
        final map = args as Map<String, dynamic>?;
        if (map == null ||
            map['latitude'] == null ||
            map['longitude'] == null) {
          return 'Please provide both latitude and longitude.';
        }

        final lat = map['latitude'];
        final lon = map['longitude'];
        final response = await http.get(
          Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&daily=temperature_2m_max,temperature_2m_min&timezone=auto',
          ),
        );
        return jsonDecode(response.body);
      },
    );

    // 2. Tool to search products from DummyJSON Products API
    final productsTool = Tool(
      name: 'search_products',
      description:
          'Search an online catalog for items, products, or accommodations matching a query string. Returns details including "title", "description", "price", "rating", and "thumbnail" (image URL).',
      inputSchema: S.object(
        properties: {
          'query': S.string(
            description:
                'The search query (e.g., "phone", "furniture", "laptop")',
          ),
        },
        required: ['query'],
      ),
      onCall: (args) async {
        final map = args as Map<String, dynamic>;
        final query = map['query'] as String;
        final response = await http.get(
          Uri.parse(
            'https://dummyjson.com/products/search?q=${Uri.encodeComponent(query)}',
          ),
        );
        return jsonDecode(response.body);
      },
    );

    // 3. Tool to get live crypto price from CoinGecko Simple Price API
    final cryptoTool = Tool(
      name: 'get_crypto_price',
      description:
          'Get the current real-time price, 24-hour high/low, and 24-hour price change percentage for a cryptocurrency (e.g. bitcoin, ethereum, solana).',
      inputSchema: S.object(
        properties: {
          'coin_id': S.string(
            description:
                'The CoinGecko coin ID (e.g. "bitcoin", "ethereum", "solana", "dogecoin")',
          ),
        },
        required: ['coin_id'],
      ),
      onCall: (args) async {
        final map = args as Map<String, dynamic>;
        final coinId = (map['coin_id'] as String).toLowerCase().trim();

        final response = await http.get(
          Uri.parse(
            'https://api.coingecko.com/api/v3/simple/price?ids=$coinId&vs_currencies=usd&include_24hr_change=true&include_24hr_high_low=true',
          ),
        );

        if (response.statusCode != 200) {
          return 'Failed to fetch price for "$coinId".';
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (!data.containsKey(coinId)) {
          return 'Cryptocurrency "$coinId" not found or unsupported.';
        }

        final coinData = data[coinId] as Map<String, dynamic>;
        final price = coinData['usd'] as num? ?? 0.0;
        final change24h = coinData['usd_24h_change'] as num? ?? 0.0;
        final high24h = coinData['usd_24h_high'] as num? ?? 0.0;
        final low24h = coinData['usd_24h_low'] as num? ?? 0.0;

        // Map popular coins to clean names and symbols
        final Map<String, (String, String)> coinMap = {
          'bitcoin': ('Bitcoin', 'BTC'),
          'ethereum': ('Ethereum', 'ETH'),
          'solana': ('Solana', 'SOL'),
          'dogecoin': ('Dogecoin', 'DOGE'),
          'cardano': ('Cardano', 'ADA'),
          'ripple': ('Ripple', 'XRP'),
          'polkadot': ('Polkadot', 'DOT'),
        };

        final (name, symbol) =
            coinMap[coinId] ??
            (
              coinId.substring(0, 1).toUpperCase() + coinId.substring(1),
              coinId.substring(0, 3).toUpperCase(),
            );

        // Generate a beautiful, natural 8-point price fluctuation trend line
        // starting at low, moving through high, and ending at current price.
        final List<double> sparkline = [
          low24h.toDouble(),
          (low24h * 1.01).toDouble(),
          (low24h * 0.99).toDouble(),
          (high24h * 0.98).toDouble(),
          high24h.toDouble(),
          (high24h * 0.99).toDouble(),
          ((high24h + price) / 2).toDouble(),
          price.toDouble(),
        ];

        return {
          'symbol': symbol,
          'name': name,
          'price': '\$${price.toStringAsFixed(price < 1.0 ? 4 : 2)}',
          'change24h':
              '${change24h >= 0 ? "+" : ""}${change24h.toStringAsFixed(2)}%',
          'isPositive': change24h >= 0,
          'high24h': '\$${high24h.toStringAsFixed(high24h < 1.0 ? 4 : 2)}',
          'low24h': '\$${low24h.toStringAsFixed(low24h < 1.0 ? 4 : 2)}',
          'sparkline': sparkline,
        };
      },
    );

    final tools = <Tool>[weatherTool, productsTool, cryptoTool];

    final agent = Agent.forProvider(
      provider,
      chatModelName: modelName,
      tools: tools,
      enableThinking: false,
    );

    return ChatAgentService._(agent);
  }

  /// Streams the agent's response for a given prompt and conversational history.
  /// Converts the chunk output stream to a standard `Stream<String>` of text deltas.
  Stream<String> streamResponse(String prompt, List<ChatMessage> history) {
    return _agent
        .sendStream(prompt, history: history)
        .map((chunk) => chunk.output);
  }

  static String? _getApiKey(String modelName) {
    final isLlama = modelName.contains('llama') || modelName.contains('groq');
    final String keyName = isLlama ? 'GROQ_API_KEY' : 'DEEPSEEK_API_KEY';

    final envKey = isLlama
        ? const String.fromEnvironment('GROQ_API_KEY')
        : const String.fromEnvironment('DEEPSEEK_API_KEY');
    if (envKey.isNotEmpty) return envKey;

    if (!kIsWeb) {
      return Platform.environment[keyName];
    }
    return null;
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
        final bodyString = request.body;
        final bodyJson = jsonDecode(bodyString);
        if (bodyJson is Map<String, dynamic>) {
          final model = bodyJson['model'] as String?;
          if (model != null && (model.contains('llama') || model.contains('groq'))) {
            bodyJson.remove('thinking');
            bodyJson.remove('reasoning_effort');
          } else {
            bodyJson['thinking'] = {'type': 'disabled'};
            bodyJson.remove('reasoning_effort');
          }
          final newBodyString = jsonEncode(bodyJson);
          final newRequest = http.Request(request.method, request.url)
            ..headers.addAll(request.headers)
            ..body = newBodyString;
          return _inner.send(newRequest);
        }
      } catch (_) {}
    }
    return _inner.send(request);
  }
}

class DeduplicatedOpenAIChatModel extends OpenAIChatModel {
  DeduplicatedOpenAIChatModel({
    required super.name,
    super.apiKey,
    super.tools,
    super.temperature,
    super.defaultOptions,
    super.organization,
    super.baseUrl,
    super.headers,
    http.Client? client,
  }) : super(client: ThinkingDisabledHttpClient(client ?? http.Client()));

  @override
  Stream<ChatResult<ChatMessage>> sendStream(
    List<ChatMessage> messages, {
    OpenAIChatOptions? options,
    Schema? outputSchema,
  }) {
    return super
        .sendStream(messages, options: options, outputSchema: outputSchema)
        .map((chunk) {
          if (chunk.messages.isNotEmpty && chunk.output.parts.isNotEmpty) {
            final completeMessage = chunk.messages.first;
            final hasToolCalls = completeMessage.parts.any(
              (part) => part is ToolPart,
            );
            if (hasToolCalls) {
              // Clear the text parts in output to prevent the orchestrator from streaming the accumulated text again.
              final emptyOutput = ChatMessage(
                role: ChatMessageRole.model,
                parts: const [],
              );
              return ChatResult<ChatMessage>(
                id: chunk.id,
                output: emptyOutput,
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

class DeduplicatedOpenAIProvider extends OpenAIProvider {
  DeduplicatedOpenAIProvider({
    super.apiKey,
    super.name = 'openai',
    super.displayName = 'OpenAI',
    super.defaultModelNames = const {
      ModelKind.chat: 'gpt-4o',
      ModelKind.embeddings: 'text-embedding-3-small',
    },
    super.baseUrl,
    super.apiKeyName = 'OPENAI_API_KEY',
    super.aliases,
    super.headers,
  });

  @override
  ChatModel<OpenAIChatOptions> createChatModel({
    String? name,
    List<Tool>? tools,
    double? temperature,
    bool enableThinking = false,
    OpenAIChatOptions? options,
  }) {
    validateApiKeyPresence();
    final modelName = name ?? defaultModelNames[ModelKind.chat]!;

    return DeduplicatedOpenAIChatModel(
      name: modelName,
      tools: tools,
      temperature: temperature,
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      defaultOptions: OpenAIChatOptions(
        temperature: temperature ?? options?.temperature,
        topP: options?.topP,
        n: options?.n,
        maxTokens: options?.maxTokens,
        presencePenalty: options?.presencePenalty,
        frequencyPenalty: options?.frequencyPenalty,
        logitBias: options?.logitBias,
        stop: options?.stop,
        user: options?.user,
        responseFormat: options?.responseFormat,
        seed: options?.seed,
        parallelToolCalls: options?.parallelToolCalls,
        streamOptions:
            options?.streamOptions ?? const StreamOptions(includeUsage: true),
        serviceTier: options?.serviceTier,
      ),
    );
  }
}
