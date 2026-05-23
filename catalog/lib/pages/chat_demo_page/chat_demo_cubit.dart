import 'dart:async';
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
  final bool isError;

  DemoMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.isError = false,
  });

  DemoMessage copyWith({String? text, bool? isError}) {
    return DemoMessage(
      id: id,
      isUser: isUser,
      text: text ?? this.text,
      isError: isError ?? this.isError,
    );
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
    customViewIds: const {
      'canvas-ui':
          'Renders a dedicated full-screen dynamic mini app, interactive dashboard, or tool requested by the user.',
    },
  );

  final List<ChatMessage> _history = [];
  ChatAgentService? _agentService;

  StreamSubscription<String>? _currentStreamSubscription;
  StreamController<String>? _currentResponseController;

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
    generativeUi.addListener(_onGenerativeUiChanged);
  }

  bool _hasOpenedCanvasThisStream = false;

  void _onGenerativeUiChanged() {
    if (!_hasOpenedCanvasThisStream &&
        generativeUi.hasContent('canvas-ui') &&
        state.canvasMode != CanvasMode.ui) {
      _hasOpenedCanvasThisStream = true;
      emit(state.copyWith(canvasMode: CanvasMode.ui));
    }
  }

  String get systemPrompt =>
      '''
You are a helpful AI Assistant demonstrating your ability to show UI components in your chat.

Help the user with their requests. Use widgets when you can.

The package is still in early development. Expect bugs and instability. Better custom UI composition on runtime is planned.

${generativeUi.systemPrompt}

## WIDGET SELECTION & MAPPING (YOU MUST STRICTLY USE THESE WHEN CALLING A TOOL.):
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
     * "imageUrl": The "thumbnail" image URL (highly recommended to embed. If the product has no image, omit this property).
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
- For 'search_products', always populate the "imageUrl" property in the "ecommerce:product_card" widget with the product's "thumbnail" URL so that the image is beautifully embedded. If the product has no image or the URL is empty/missing, completely omit the "imageUrl" property so the widget dynamically hides the image frame.
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

  void stopResponse() {
    if (state.isThinking) {
      _currentStreamSubscription?.cancel();
      _currentStreamSubscription = null;

      if (_currentResponseController != null && !_currentResponseController!.isClosed) {
        _currentResponseController!.close();
      }
      _currentResponseController = null;

      emit(state.copyWith(isThinking: false));
    }
  }

  void clearChat() {
    stopResponse();
    _history.clear();
    _history.add(ChatMessage.system(systemPrompt));
    generativeUi.disposeView('canvas-ui');
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

    _hasOpenedCanvasThisStream = false;

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
      if (_agentService == null) {
        _agentService = ChatAgentService.create();
      }
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

      _currentResponseController = StreamController<String>();
      final StringBuffer accumulated = StringBuffer();

      _currentStreamSubscription = textStream.listen(
        (chunk) {
          accumulated.write(chunk);

          final updatedMessages = state.messages.map((m) {
            if (m.id == aiMsgId) {
              return m.copyWith(text: accumulated.toString());
            }
            return m;
          }).toList();

          emit(state.copyWith(messages: updatedMessages));

          if (_currentResponseController != null && !_currentResponseController!.isClosed) {
            _currentResponseController!.add(chunk);
          }
        },
        onError: (e) {
          final updatedMessages = state.messages.map((m) {
            if (m.id == aiMsgId) {
              return m.copyWith(
                text: 'Streaming error: ${e.toString()}',
                isError: true,
              );
            }
            return m;
          }).toList();

          emit(
            state.copyWith(
              messages: updatedMessages,
              errorMessage: 'Streaming error: ${e.toString()}',
              isThinking: false,
            ),
          );
          stopResponse();
        },
        onDone: () {
          if (_currentResponseController != null && !_currentResponseController!.isClosed) {
            _currentResponseController!.close();
          }
        },
      );

      await generativeUi.stream(
        _currentResponseController!.stream,
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
      final updatedMessages = state.messages.map((m) {
        if (m.id == aiMsgId) {
          return m.copyWith(
            text: 'Streaming error: ${e.toString()}',
            isError: true,
          );
        }
        return m;
      }).toList();

      emit(
        state.copyWith(
          messages: updatedMessages,
          errorMessage: 'Streaming error: ${e.toString()}',
          isThinking: false,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    stopResponse();
    generativeUi.removeListener(_onGenerativeUiChanged);
    return super.close();
  }
}
