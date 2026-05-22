import 'dart:io';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    super.client,
  });

  @override
  Stream<ChatResult<ChatMessage>> sendStream(
    List<ChatMessage> messages, {
    OpenAIChatOptions? options,
    Schema? outputSchema,
  }) {
    return super.sendStream(messages, options: options, outputSchema: outputSchema).map((chunk) {
      if (chunk.messages.isNotEmpty && chunk.output.parts.isNotEmpty) {
        final completeMessage = chunk.messages.first;
        final hasToolCalls = completeMessage.parts.any((part) => part is ToolPart);
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

void main() async {
  final apiKey = 'sk-f2c6f0dcec994bd29af88b856993b389';
  final provider = DeduplicatedOpenAIProvider(
    apiKey: apiKey,
    baseUrl: Uri.parse('https://api.deepseek.com/v1'),
  );

  final weatherTool = Tool(
    name: 'get_weather',
    description: 'Get current weather for a city using latitude and longitude.',
    inputSchema: S.object(
      properties: {
        'latitude': S.number(),
        'longitude': S.number(),
        'city_name': S.string(),
      },
      required: ['latitude', 'longitude', 'city_name'],
    ),
    onCall: (args) async {
      print('\n[TOOL CALL EXECUTING] get_weather with args: $args');
      return {'temperature': '22 C', 'condition': 'partly cloudy'};
    },
  );

  final agent = Agent.forProvider(
    provider,
    chatModelName: 'deepseek-chat',
    tools: [weatherTool],
    enableThinking: false,
  );

  final history = <ChatMessage>[
    ChatMessage.system('You are a helpful assistant. Use tools when needed. If a tool runs, show a weather card like <interface viewId="ai-1">{"namespace":"weather:forecast_card","cityName":"Paris","temperature":"22 C"}</interface>'),
  ];

  print('Sending: "What is the weather in Paris?"');
  final stream = agent.sendStream('What is the weather in Paris?', history: history);

  var chunkCount = 0;
  var accumulatedOutput = '';
  await for (final chunk in stream) {
    chunkCount++;
    accumulatedOutput += chunk.output;
    print('Chunk #$chunkCount:');
    print('  - Output: "${chunk.output}"');
    print('  - Thinking: "${chunk.thinking}"');
    print('  - Messages length: ${chunk.messages.length}');
  }

  print('\nStream complete!');
  print('Total Chunks: $chunkCount');
  print('Accumulated Output: "$accumulatedOutput"');
  print('History after stream:');
  for (var i = 0; i < history.length; i++) {
    print('Message #$i: [${history[i].role}] - ${history[i].text}');
  }
}
