import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:streaming_gen_ui_widget_catalog/core/app_widgets/elastic_wrapper.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/chat_demo_page/chat_demo_cubit.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';

class ChatDemoPage extends StatefulWidget {
  const ChatDemoPage({super.key});

  @override
  State<ChatDemoPage> createState() => _ChatDemoPageState();
}

class _ChatDemoPageState extends State<ChatDemoPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = MediaQuery.sizeOf(context);

    return BlocBuilder<ChatDemoCubit, ChatDemoState>(
      builder: (context, state) {
        final isChatExpanded = state.textBoxMode != TextBoxMode.textfield;
        final isCanvasExpanded = state.canvasMode != CanvasMode.hidden;

        return Scaffold(
          body: GraphBackground(
            child: SafeArea(
              child: Stack(
                children: [
                  // Horizontal Split View
                  Row(
                    children: [
                      // 1. LEFT PANEL: Chat conversation space
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context, theme),
                              const SizedBox(height: 24),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildErrorBanner(context, theme, state),
                                    Expanded(
                                      child: _buildMessageList(
                                        context,
                                        theme,
                                        state,
                                        _controller,
                                        _focusNode,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. RIGHT PANEL: Floating Bento Canvas panel
                      _buildCanvasPanel(context, theme, state, sizes),
                    ],
                  ),

                  // 3. User's exact custom animated chat textfield console
                  AnimatedAlign(
                    duration: Durations.short4,
                    curve: Curves.easeInOut,
                    alignment: Alignment.bottomCenter,
                    child: AnimatedPadding(
                      duration: Durations.short4,
                      padding: EdgeInsets.only(
                        bottom: isChatExpanded ? 16.0 : 28.0,
                        right: isCanvasExpanded ? sizes.width * 0.6 : 0,
                      ),
                      curve: Curves.easeOut,
                      child: ChatConsoleInput(
                        isChatExpanded: isChatExpanded,
                        isCanvasExpanded: isCanvasExpanded,
                        sizes: sizes,
                        controller: _controller,
                        focusNode: _focusNode,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Sub-widgets & UI Helpers ---

  /// Renders the page title header
  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 24,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
            children: const [
              TextSpan(
                text: "Streaming ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: "Generative UI",
                style: TextStyle(fontWeight: FontWeight.w300),
              ),
            ],
          ),
        ),
        Text(
          "Chat Demo",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Renders a critical configuration warning or runtime API error banner
  Widget _buildErrorBanner(
    BuildContext context,
    ThemeData theme,
    ChatDemoState state,
  ) {
    if (state.errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.errorMessage!,
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: theme.colorScheme.onErrorContainer,
              onPressed: () => context.read<ChatDemoCubit>().clearError(),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders the scrollable centered list of all chat bubbles
  Widget _buildMessageList(
    BuildContext context,
    ThemeData theme,
    ChatDemoState state,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    if (state.messages.isEmpty) {
      return _buildEmptyState(context, theme, controller, focusNode);
    }
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.builder(
            reverse: true,
            itemCount: state.messages.length,
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 140,
              left: 16,
              right: 16,
            ),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final message = state.messages[state.messages.length - 1 - index];
              return Builder(
                builder: (context) {
                  return message.isUser
                      ? _buildUserMessageBubble(context, theme, message)
                      : _buildModelMessageBubble(context, theme, message);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Renders the empty state display with preset prompts
  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Try her out! Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  "Try her out!",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Headline
              Text(
                "Streaming Generative UI",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              Text(
                "Interact with real-time UI components rendered directly from the LLM stream. Choose a preset prompt below to begin.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 48),
              // Preset Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 450;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isNarrow ? 1 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isNarrow ? 2.5 : 2.0,
                    children: [
                      _PresetPromptCard(
                        title: "Show off",
                        prompt: "What makes you so cool?",
                        onTap: () {
                          controller.text = "What makes you so cool?";
                          focusNode.requestFocus();
                        },
                      ),
                      _PresetPromptCard(
                        title: "Weather check",
                        prompt:
                            "Give me a quick forecast, is it t-shirt weather?",
                        onTap: () {
                          controller.text =
                              "Give me a quick forecast, is it t-shirt weather?";
                          focusNode.requestFocus();
                        },
                      ),
                      _PresetPromptCard(
                        title: "Sun chaser",
                        prompt:
                            "When is the next Summer Solstice? I need some sun.",
                        onTap: () {
                          controller.text =
                              "When is the next Summer Solstice? I need some sun.";
                          focusNode.requestFocus();
                        },
                      ),
                      _PresetPromptCard(
                        title: "Interactive demo",
                        prompt:
                            "Show me what you've got! Demo all your widgets.",
                        onTap: () {
                          controller.text =
                              "Show me what you've got! Demo all your widgets.";
                          focusNode.requestFocus();
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the user text bubble aligned to the right
  Widget _buildUserMessageBubble(
    BuildContext context,
    ThemeData theme,
    DemoMessage message,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Renders the model UI/Text bubble aligned to the left, integrated with StreamingGenerativeUi
  Widget _buildModelMessageBubble(
    BuildContext context,
    ThemeData theme,
    DemoMessage message,
  ) {
    final cubit = context.read<ChatDemoCubit>();
    final showRaw = context.select(
      (ChatDemoCubit c) => c.state.showRawResponse,
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: showRaw
              ? Colors.black.withOpacity(0.9)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.08),
          ),
        ),
        child: showRaw
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: SelectableText(
                  message.text.isEmpty ? "..." : message.text,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.greenAccent,
                  ),
                ),
              )
            : ListenableBuilder(
                listenable: cubit.generativeUi,
                builder: (context, _) {
                  return cubit.generativeUi.view(
                    message.id,
                    textBlockBuilder: (context, text) => GptMarkdown(text),
                  );
                },
              ),
      ),
    );
  }

  /// Renders the bento canvas panel that dynamically expands/shrinks
  Widget _buildCanvasPanel(
    BuildContext context,
    ThemeData theme,
    ChatDemoState state,
    Size sizes,
  ) {
    final isCanvasExpanded = state.canvasMode != CanvasMode.hidden;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubicEmphasized,
      width: isCanvasExpanded ? sizes.width * 0.6 : 0,
      height: double.infinity,
      margin: isCanvasExpanded
          ? const EdgeInsets.fromLTRB(0, 16, 16, 16)
          : EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: isCanvasExpanded ? 1.0 : 0.0,
          ),
        ),
        color: theme.colorScheme.surfaceContainerLow.withOpacity(0.95),
        shadows: isCanvasExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(-8, 8),
                ),
              ]
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return OverflowBox(
            alignment: Alignment.topRight,
            minWidth: sizes.width * 0.6,
            maxWidth: sizes.width * 0.6,
            minHeight: constraints.maxHeight,
            maxHeight: constraints.maxHeight,
            child: _buildCanvasContent(context, theme),
          );
        },
      ),
    );
  }

  Widget _buildCanvasContent(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.dashboard_customize_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Docker Deploy monitor",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  context.read<ChatDemoCubit>().setCanvasMode(
                    CanvasMode.hidden,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "LIVE CONNECTION METRIC",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CPU load",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "12.4%",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Memory",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "512MB / 2GB",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "LIVE DEPLOYMENT CONTAINER TERMINAL LOGS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: const SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Text(
                  "\$ npm install -g pnpm\n"
                  "--> added 4 packages [OK]\n"
                  "\$ pnpm build\n"
                  "--> compiling source scripts...\n"
                  "--> tree shaking components...\n"
                  "--> assets saved under dist/ [OK]\n"
                  "\$ docker build -t server-node .\n"
                  "--> Layer 1/4: FROM node:20-alpine [OK]\n"
                  "--> Layer 2/4: COPY dist/ dist/ [OK]\n"
                  "--> Layer 3/4: EXPOSE 8080 [OK]\n"
                  "--> Layer 4/4: CMD pnpm dev [OK]\n"
                  "--> tag: server-node:latest successfully compiled!\n"
                  "\$ docker run -p 8080:8080 server-node\n"
                  "--> running deployment hooks...\n"
                  "--> metrics listener connected.\n"
                  "--> status: host online at http://192.168.1.144:8080\n"
                  "--> _",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.greenAccent,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatConsoleInput extends StatefulWidget {
  final bool isChatExpanded;
  final bool isCanvasExpanded;
  final Size sizes;
  final TextEditingController controller;
  final FocusNode focusNode;

  const ChatConsoleInput({
    super.key,
    required this.isChatExpanded,
    required this.isCanvasExpanded,
    required this.sizes,
    required this.controller,
    required this.focusNode,
  });

  @override
  State<ChatConsoleInput> createState() => _ChatConsoleInputState();
}

class _ChatConsoleInputState extends State<ChatConsoleInput> {
  bool _isTextFieldFocused = false;
  bool _isSendButtonPressed = false;
  bool _isSendButtonHovered = false;
  bool _isConsoleHovered = false;
  bool _isAnimatingChatExpansion = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant ChatConsoleInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChatExpanded != oldWidget.isChatExpanded) {
      _isAnimatingChatExpansion = true;
    }
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (widget.focusNode.hasFocus != _isTextFieldFocused) {
      setState(() {
        _isTextFieldFocused = widget.focusNode.hasFocus;
      });
    }
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatDemoCubit>().sendMessage(text);
      widget.controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Snappy custom curve for high-fidelity mechanical keyboard feeling
    const customSnap = Cubic(0.2, 0.8, 0.2, 1.0);

    // Calculate interactive scale
    double consoleScale = 1.0;
    if (_isTextFieldFocused) {
      consoleScale = 1.03; // Scale up when focused
    }
    if (_isSendButtonPressed) {
      consoleScale =
          0.96; // Tactile mechanical shrink when send button is pressed
    }

    // Interactive highlights & glow effects
    final borderColor = _isTextFieldFocused
        ? theme.colorScheme.primary.withOpacity(0.5)
        : (_isConsoleHovered
              ? theme.colorScheme.primary.withOpacity(0.25)
              : theme.colorScheme.outline.withOpacity(0.08));

    final borderWidth = _isTextFieldFocused ? 1.5 : 1.0;

    final List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
      if (_isTextFieldFocused)
        BoxShadow(
          color: theme.colorScheme.primary.withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 0),
        )
      else if (_isConsoleHovered)
        BoxShadow(
          color: theme.colorScheme.primary.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 2),
        ),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isConsoleHovered = true),
      onExit: (_) => setState(() => _isConsoleHovered = false),
      child: AnimatedScale(
        scale: consoleScale,
        duration: const Duration(milliseconds: 200),
        curve: customSnap,
        child: AnimatedContainer(
          duration: _isAnimatingChatExpansion
              ? const Duration(milliseconds: 350)
              : const Duration(milliseconds: 200),
          curve: _isAnimatingChatExpansion ? Curves.easeInOutBack : customSnap,
          onEnd: () {
            if (_isAnimatingChatExpansion) {
              setState(() {
                _isAnimatingChatExpansion = false;
              });
            }
          },
          width: widget.isCanvasExpanded
              ? (widget.sizes.width * 0.4 - 32).clamp(
                  100.0,
                  512.0 + (widget.isChatExpanded ? 64 : 0),
                )
              : 512.0 + (widget.isChatExpanded ? 64 : 0),
          height: widget.isChatExpanded ? 256.0 : 64.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: customSnap,
            decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(32),
                side: BorderSide(color: borderColor, width: borderWidth),
              ),
              color: theme.colorScheme.secondaryContainer,
              shadows: shadows,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedAlign(
                    alignment: widget.isChatExpanded
                        ? Alignment.topLeft
                        : Alignment.centerLeft,
                    duration: Durations.short1,
                    child: IconButton(
                      onPressed: () {
                        final cubit = context.read<ChatDemoCubit>();
                        cubit.setTextBoxMode(
                          widget.isChatExpanded
                              ? TextBoxMode.textfield
                              : TextBoxMode.media,
                        );
                      },
                      icon: AnimatedSwitcher(
                        duration: Durations.short4,
                        child: widget.isChatExpanded
                            ? const Icon(Icons.close, key: ValueKey('close'))
                            : const Icon(Icons.add, key: ValueKey('add')),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Durations.short4,
                      child: widget.isChatExpanded
                          ? _buildExpandedDrawerInput(context, theme)
                          : TextField(
                              controller: widget.controller,
                              focusNode: widget.focusNode,
                              onSubmitted: (_) => _submit(),
                              textAlignVertical: TextAlignVertical.center,
                              decoration: const InputDecoration(
                                hintText: 'Talk to AI',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (!widget.isChatExpanded)
                    Listener(
                      onPointerDown: (_) =>
                          setState(() => _isSendButtonPressed = true),
                      onPointerUp: (_) =>
                          setState(() => _isSendButtonPressed = false),
                      onPointerCancel: (_) =>
                          setState(() => _isSendButtonPressed = false),
                      child: MouseRegion(
                        onEnter: (_) =>
                            setState(() => _isSendButtonHovered = true),
                        onExit: (_) =>
                            setState(() => _isSendButtonHovered = false),
                        cursor: SystemMouseCursors.click,
                        child: AnimatedScale(
                          scale: _isSendButtonHovered ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutBack,
                          child: IconButton.filled(
                            onPressed: _submit,
                            icon: Icon(
                              Icons.arrow_upward,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedDrawerInput(BuildContext context, ThemeData theme) {
    final showRaw = context.select(
      (ChatDemoCubit c) => c.state.showRawResponse,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "CONSOLE UTILITIES",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.primary,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.5, indent: 12, endIndent: 12),
        const SizedBox(height: 16),
        Container(
          height: 110,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildConsoleUtilityCard(
                  icon: Icons.delete_sweep_rounded,
                  title: "Clear Chat",
                  subtitle: "Reset discussion",
                  theme: theme,
                  isAction: true,
                  onTap: () {
                    context.read<ChatDemoCubit>().clearChat();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildConsoleUtilityCard(
                  icon: Icons.code_rounded,
                  title: "Raw Response",
                  subtitle: "Toggle raw text",
                  theme: theme,
                  isToggle: true,
                  isActive: false,
                  isEnabled: false,
                  onTap: () {
                    // Disabled
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildConsoleUtilityCard(
                  icon: Icons.terminal_rounded,
                  title: "System Prompt",
                  subtitle: "View instructions",
                  theme: theme,
                  isAction: true,
                  onTap: () {
                    _showSystemPromptModal(context, theme);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsoleUtilityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    bool isAction = false,
    bool isToggle = false,
    bool isActive = false,
    bool isEnabled = true,
    required VoidCallback onTap,
  }) {
    return _ConsoleUtilityCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      isAction: isAction,
      isToggle: isToggle,
      isActive: isActive,
      isEnabled: isEnabled,
      onTap: onTap,
    );
  }

  void _showSystemPromptModal(BuildContext context, ThemeData theme) {
    final cubit = context.read<ChatDemoCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.sizeOf(context).height * 0.75,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              // Bottom sheet handle & header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.terminal_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "System Instructions",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Entire scrollable prompt content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.08),
                      ),
                    ),
                    child: SelectableText(
                      cubit.systemPrompt,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConsoleUtilityCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isAction;
  final bool isToggle;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ConsoleUtilityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isAction,
    required this.isToggle,
    required this.isActive,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_ConsoleUtilityCard> createState() => _ConsoleUtilityCardState();
}

class _ConsoleUtilityCardState extends State<_ConsoleUtilityCard> {
  bool _isHovered = false;
  late bool _toggleState;

  @override
  void initState() {
    super.initState();
    _toggleState = widget.isActive;
  }

  @override
  void didUpdateWidget(covariant _ConsoleUtilityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _toggleState = widget.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = widget.isToggle && _toggleState
        ? theme.colorScheme.primary.withOpacity(0.08)
        : (_isHovered && widget.isEnabled
              ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.8)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3));

    final borderColor = widget.isToggle && _toggleState
        ? theme.colorScheme.primary.withOpacity(0.4)
        : (_isHovered && widget.isEnabled
              ? theme.colorScheme.primary.withOpacity(0.2)
              : theme.colorScheme.outline.withOpacity(0.08));

    return Opacity(
      opacity: widget.isEnabled ? 1.0 : 0.4,
      child: MouseRegion(
        onEnter: (_) {
          if (widget.isEnabled) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (widget.isEnabled) setState(() => _isHovered = false);
        },
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: () {
            if (!widget.isEnabled) return;
            if (widget.isToggle) {
              setState(() {
                _toggleState = !_toggleState;
              });
            }
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      widget.icon,
                      size: 20,
                      color: widget.isToggle && _toggleState
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    if (widget.isToggle)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 32,
                        height: 18,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: _toggleState
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.3),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 150),
                          alignment: _toggleState
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetPromptCard extends StatefulWidget {
  final String title;
  final String prompt;
  final VoidCallback onTap;

  const _PresetPromptCard({
    required this.title,
    required this.prompt,
    required this.onTap,
  });

  @override
  State<_PresetPromptCard> createState() => _PresetPromptCardState();
}

class _PresetPromptCardState extends State<_PresetPromptCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElasticWrapper(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isHovered
                  ? theme.colorScheme.primary.withOpacity(0.04)
                  : theme.colorScheme.surfaceContainerLow.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? theme.colorScheme.primary.withOpacity(0.3)
                    : theme.colorScheme.outline.withOpacity(0.08),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _isHovered
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    widget.prompt,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.8,
                      ),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
