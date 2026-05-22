import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/chat_demo_page/chat_agent_service.dart';

enum TextBoxMode { textfield, media, view }

enum CanvasMode { hidden, code, document, ui }

class DemoMessage {
  final String id;
  final bool isUser;
  final String text;

  DemoMessage({required this.id, required this.isUser, required this.text});

  DemoMessage copyWith({String? text}) {
    return DemoMessage(id: id, isUser: isUser, text: text ?? this.text);
  }
}

class ChatDemoState {
  final TextBoxMode textBoxMode;
  final CanvasMode canvasMode;
  final List<DemoMessage> messages;
  final bool isThinking;
  final String? errorMessage;
  final bool showRawResponse;

  const ChatDemoState({
    required this.textBoxMode,
    required this.canvasMode,
    required this.messages,
    required this.isThinking,
    this.errorMessage,
    this.showRawResponse = false,
  });

  ChatDemoState copyWith({
    TextBoxMode? textBoxMode,
    CanvasMode? canvasMode,
    List<DemoMessage>? messages,
    bool? isThinking,
    String? errorMessage,
    bool? showRawResponse,
  }) {
    return ChatDemoState(
      textBoxMode: textBoxMode ?? this.textBoxMode,
      canvasMode: canvasMode ?? this.canvasMode,
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: errorMessage ?? this.errorMessage,
      showRawResponse: showRawResponse ?? this.showRawResponse,
    );
  }

  ChatDemoState copyWithClearedError({
    TextBoxMode? textBoxMode,
    CanvasMode? canvasMode,
    List<DemoMessage>? messages,
    bool? isThinking,
    bool? showRawResponse,
  }) {
    return ChatDemoState(
      textBoxMode: textBoxMode ?? this.textBoxMode,
      canvasMode: canvasMode ?? this.canvasMode,
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: null,
      showRawResponse: showRawResponse ?? this.showRawResponse,
    );
  }
}

class ChatDemoCubit extends Cubit<ChatDemoState> {
  final StreamingGenerativeUi generativeUi = StreamingGenerativeUi(
    registry: Registries.all,
  );

  final List<ChatMessage> _history = [];
  ChatAgentService? _agentService;

  ChatDemoCubit()
    : super(
        const ChatDemoState(
          textBoxMode: TextBoxMode.textfield,
          canvasMode: CanvasMode.hidden,
          messages: [],
          isThinking: false,
        ),
      ) {
    _history.add(ChatMessage.system(systemPrompt));
  }

  String get systemPrompt =>
      '''
You are a helpful AI Assistant demonstrating your ability to show UI components in your chat.

Help the user with their requests. Use widgets when you can.

${generativeUi.registry.systemPromptFragment}

CRITICAL RULES FOR DYNAMIC WIDGET SELECTION:
1. When the user asks about weather, and the 'get_weather' tool runs successfully:
   - You MUST stream a "weather:forecast_card" widget.
   - Map the fields correctly:
     * "cityName": The name of the city requested (e.g. "Paris" or "Manila").
     * "temperature": Map the current_weather's temperature formatted (e.g., "${r'${current_weather["temperature"]}'}°C").
     * "condition": A short string summarizing weather condition based on the weathercode or description (e.g., "sunny", "rainy", "cloudy", "snowy").
     * "humidity": Format and output humidity if available, or leave empty if not provided.
     * "windSpeed": Format windspeed (e.g. "${r'${current_weather["windspeed"]}'} km/h").
     * "forecast": Provide a 3-day projection mapped from the daily fields. Each daily forecast map in the list must contain "day" (e.g., "Mon", "Tue"), "temp" (e.g. "24°C"), and "condition" (e.g. "sunny", "rainy").
     
2. When the user searches for products, and the 'search_products' tool runs successfully:
   - You MUST stream one or more "ecommerce:product_card" widgets (wrapped in a vertical "core:column" or standard layout if showing multiple).
   - Map the fields from the tool's returned products:
     * "title": The product's title (e.g. "iPhone 15").
     * "description": A concise summary of the item description.
     * "price": Format price cleanly (e.g., "\$${r'${product["price"]}'}").
     * "imageUrl": Provide the primary product thumbnail or image URL.
     * "rating": Float value between 1.0 and 5.0 indicating user rating.
     * "action": Map to a unique callback action key like "buy_product_${r'${product["id"]}'}".
3. When the user asks about cryptocurrency prices or tickers, and the 'get_crypto_price' tool runs successfully:
   - You MUST stream a "crypto:price_card" widget.
   - Map the fields returned directly by the tool:
     * "symbol": The uppercase coin symbol (e.g. "BTC", "ETH").
     * "name": The capitalized full name of the coin (e.g. "Bitcoin", "Solana").
     * "price": The pre-formatted price (e.g. "\$63,245.20").
     * "change24h": The pre-formatted 24h percentage change (e.g. "+2.51%" or "-1.42%").
     * "isPositive": The boolean indicating if the trend is up.
     * "high24h": The pre-formatted 24h high price.
     * "low24h": The pre-formatted 24h low price.
     * "sparkline": The array of floating point numbers representing the price trend.
''';

  void setTextBoxMode(TextBoxMode mode) {
    emit(state.copyWith(textBoxMode: mode));
  }

  void setCanvasMode(CanvasMode mode) {
    emit(state.copyWith(canvasMode: mode));
  }

  void clearError() {
    emit(state.copyWithClearedError());
  }

  void toggleRawResponse() {
    emit(state.copyWith(showRawResponse: !state.showRawResponse));
  }

  void clearChat() {
    _history.clear();
    _history.add(ChatMessage.system(systemPrompt));
    emit(
      const ChatDemoState(
        textBoxMode: TextBoxMode.textfield,
        canvasMode: CanvasMode.hidden,
        messages: [],
        isThinking: false,
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add user message to UI state and internal history
    final userMsgId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    final userMsg = DemoMessage(id: userMsgId, isUser: true, text: text);
    _history.add(ChatMessage.user(text));

    emit(
      state.copyWithClearedError(
        messages: [...state.messages, userMsg],
        isThinking: true,
      ),
    );

    // 2. Instantiate Agent Service (checks API key)
    try {
      _agentService ??= ChatAgentService.create();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString(), isThinking: false));
      return;
    }

    // 3. Setup streaming assistant message representation
    final aiMsgId = 'ai-${DateTime.now().millisecondsSinceEpoch}';
    final aiMsg = DemoMessage(id: aiMsgId, isUser: false, text: '');

    emit(state.copyWithClearedError(messages: [...state.messages, aiMsg]));

    try {
      final textStream = _agentService!.streamResponse(text, _history);

      final StringBuffer accumulated = StringBuffer();
      final trackedStream = textStream.map((chunk) {
        accumulated.write(chunk);

        final updatedMessages = state.messages.map((m) {
          if (m.id == aiMsgId) {
            return m.copyWith(text: accumulated.toString());
          }
          return m;
        }).toList();

        emit(state.copyWith(messages: updatedMessages));

        return chunk;
      });

      await generativeUi.stream(
        trackedStream,
        viewId: aiMsgId,
        onComplete: (raw) {
          // Add to LLM history for subsequent turns
          _history.add(ChatMessage.model(raw));

          // Update message text when stream completes
          final updatedMessages = state.messages.map((m) {
            if (m.id == aiMsgId) {
              return m.copyWith(text: raw);
            }
            return m;
          }).toList();

          emit(
            state.copyWithClearedError(
              messages: updatedMessages,
              isThinking: false,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Streaming error: ${e.toString()}',
          isThinking: false,
        ),
      );
    }
  }
}
