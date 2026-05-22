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

## WIDGET SELECTION & MAPPING:
1. Weather ('get_weather' tool success):
   - Stream "weather:forecast_card".
   - Map:
     * "cityName": Requested city name.
     * "temperature": "${r'${current_weather["temperature"]}'}°C".
     * "condition": Short weather summary (sunny/rainy/cloudy/snowy).
     * "humidity": Format or omit.
     * "windSpeed": "${r'${current_weather["windspeed"]}'} km/h".
     * "forecast": 3-day list. Map items: {"day": "Mon", "temp": "24°C", "condition": "sunny"}.
     
2. Products ('search_products' tool success):
   - Stream "ecommerce:product_card" (wrap in "core:column" if multiple).
   - Map:
     * "title": Product title.
     * "description": Short summary.
     * "price": "\$${r'${product["price"]}'}".
     * "imageUrl": Primary image URL.
     * "rating": Float (1.0 to 5.0).
     * "action": "buy_product_${r'${product["id"]}'}".

3. Crypto ('get_crypto_price' tool success):
   - Stream "crypto:price_card".
   - Map:
     * "symbol": Uppercase symbol (e.g. BTC).
     * "name": Capitalized name (e.g. Bitcoin).
     * "price": Formatted price.
     * "change24h": Formatted change (e.g. +2.51%).
     * "isPositive": Trend boolean.
     * "high24h": Formatted high.
     * "low24h": Formatted low.
     * "sparkline": Trend float list.
 
## IMPORTANT:
- For the above stated WIDGET SELECTION & MAPPING, you must stream the mentioned widget if available.
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
