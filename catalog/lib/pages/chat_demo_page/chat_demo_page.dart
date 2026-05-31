import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_gen_ui_widget_catalog/core/app_widgets/elastic_wrapper.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/chat_demo_page/chat_demo_cubit.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';
import 'package:streaming_gen_ui_widget_catalog/core/utilities/stream_text_in_chunks.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatDemoPage extends StatefulWidget {
  final VoidCallback? onBack;
  const ChatDemoPage({super.key, this.onBack});

  @override
  State<ChatDemoPage> createState() => _ChatDemoPageState();
}

class _ChatDemoPageState extends State<ChatDemoPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isCanvasBottomSheetOpen = false;
  int _headerTapCount = 0;

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

  void _showCanvasBottomSheet(BuildContext context) {
    if (_isCanvasBottomSheetOpen) return;
    _isCanvasBottomSheetOpen = true;

    final theme = Theme.of(context);
    final cubit = context.read<ChatDemoCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (modalContext) {
        return BlocProvider.value(
          value: cubit,
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.85,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
                            Icons.dashboard_customize_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Canvas Preview",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          Navigator.pop(modalContext);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ListenableBuilder(
                            listenable: cubit.generativeUi,
                            builder: (context, _) {
                              return cubit.generativeUi.view(
                                'canvas-ui',
                                textBlockBuilder: (context, text) =>
                                    GptMarkdown(text),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isCanvasBottomSheetOpen = false;
      cubit.setCanvasMode(CanvasMode.hidden);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = MediaQuery.sizeOf(context);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return BlocListener<ChatDemoCubit, ChatDemoState>(
      listener: (context, state) {
        final isCanvasExpanded = state.canvasMode != CanvasMode.hidden;
        if (isMobile && isCanvasExpanded) {
          if (!_isCanvasBottomSheetOpen) {
            _showCanvasBottomSheet(context);
          }
        } else {
          if (_isCanvasBottomSheetOpen) {
            _isCanvasBottomSheetOpen = false;
            Navigator.of(context).pop();
          }
        }
      },
      child: BlocBuilder<ChatDemoCubit, ChatDemoState>(
        builder: (context, state) {
          final isChatExpanded = state.textBoxMode != TextBoxMode.textfield;
          final isCanvasExpanded = state.canvasMode != CanvasMode.hidden;
          final showRightPanel = !isMobile && isCanvasExpanded;

          return Scaffold(
            body: GraphBackground(
              child: SafeArea(
                child: Stack(
                  children: [
                    // Horizontal Split View (left chat conversation, right sliding canvas preview)
                    Row(
                      children: [
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
                        if (showRightPanel)
                          _buildCanvasPanel(context, theme, state, sizes),
                      ],
                    ),

                    // User's exact custom animated chat textfield console
                    AnimatedAlign(
                      duration: Durations.short4,
                      curve: Curves.easeInOut,
                      alignment: Alignment.bottomCenter,
                      child: AnimatedPadding(
                        duration: Durations.short4,
                        padding: EdgeInsets.only(
                          bottom: isMobile
                              ? (isChatExpanded ? 8.0 : 12.0)
                              : (isChatExpanded ? 16.0 : 28.0),
                          right: showRightPanel ? sizes.width * 0.6 : 0,
                        ),
                        curve: Curves.easeOut,
                        child: Column(
                          mainAxisSize: .min,
                          children: [
                            ChatConsoleInput(
                              isChatExpanded: isChatExpanded,
                              isCanvasExpanded: showRightPanel,
                              sizes: sizes,
                              controller: _controller,
                              focusNode: _focusNode,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: isCanvasExpanded ? 1.0 : 0.0,
        ),
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.95),
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
    final cubit = context.read<ChatDemoCubit>();
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
                    "Canvas Preview",
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
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ListenableBuilder(
                listenable: cubit.generativeUi,
                builder: (context, _) {
                  return cubit.generativeUi.view(
                    'canvas-ui',
                    textBlockBuilder: (context, text) => GptMarkdown(text),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Sub-widgets & UI Helpers ---

  /// Renders the page title header
  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final headerContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _headerTapCount++;
              if (_headerTapCount >= 5) {
                showDevOptionsNotifier.value = true;
              }
            },
            child: Column(
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
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: showDevOptionsNotifier,
          builder: (context, showDev, _) {
            if (!showDev) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [_buildStreamingModeButton(context)],
            );
          },
        ),
      ],
    );

    if (isMobile && widget.onBack != null) {
      return Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: widget.onBack,
            ),
          ),
          Expanded(child: headerContent),
        ],
      );
    }
    return headerContent;
  }

  Widget _buildStreamingModeButton(BuildContext context) {
    return ListenableBuilder(
      listenable: currentStreamingMode,
      builder: (context, _) {
        final mode = currentStreamingMode.value;
        final IconData icon;
        final Color color;
        final String tooltip;

        switch (mode) {
          case StreamingMode.streaming:
            icon = Icons.waves_rounded;
            color = Colors.greenAccent;
            tooltip = "Streaming Mode: Progressive text & widgets";
            break;
          case StreamingMode.noWidgetStreaming:
            icon = Icons.widgets_rounded;
            color = Colors.orangeAccent;
            tooltip =
                "No Widget Stream Mode: Text streams, widgets render whole";
            break;
          case StreamingMode.noStreaming:
            icon = Icons.done_all_rounded;
            color = Colors.blueAccent;
            tooltip =
                "No-Stream Mode: Entire response awaited and rendered whole";
            break;
        }

        return IconButton(
          icon: Icon(icon, color: color),
          tooltip: tooltip,
          onPressed: () {
            final nextMode = StreamingMode
                .values[(mode.index + 1) % StreamingMode.values.length];
            currentStreamingMode.value = nextMode;
          },
        );
      },
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
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
          ),
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
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
          child: ListView.builder(
            reverse: true,
            itemCount: state.messages.length,
            padding: EdgeInsets.only(
              top: 16,
              bottom: ResponsiveBreakpoints.of(context).isMobile ? 200 : 140,
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
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: isMobile ? 180 : 100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Headline (Fits in one line on all devices)
              // Headline (Fits in one line on all devices)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Streaming Generative UI",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://pub.dev/packages/streaming_gen_ui'),
                  // mode: LaunchMode.externalApplication,
                ),
                icon: SvgPicture.network(
                  'https://cdn.simpleicons.org/dart/0175C2',
                  width: 16,
                  height: 16,
                ),
                label: const Text("View package on pub.dev"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              Text(
                "Get your AI to render widgets. Choose a preset prompt below or type a message to begin.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
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
                    childAspectRatio: isNarrow ? 3.4 : 2.0,
                    children: [
                      _PresetPromptCard(
                        title: "Weather Check",
                        prompt: "Check the weather in Paris. Is it warm?",
                        onTap: () {
                          controller.text =
                              "Check the weather in Paris. Is it warm?";
                          focusNode.requestFocus();
                        },
                      ),
                      _PresetPromptCard(
                        title: "Crypto Price",
                        prompt:
                            "What is the current price and 24h trend of Bitcoin?",
                        onTap: () {
                          controller.text =
                              "What is the current price and 24h trend of Bitcoin?";
                          focusNode.requestFocus();
                        },
                      ),
                      _PresetPromptCard(
                        title: "Search Catalog",
                        prompt:
                            "Search for some high-quality laptops and show me the catalog.",
                        onTap: () {
                          controller.text =
                              "Search for some high-quality laptops and show me the catalog.";
                          focusNode.requestFocus();
                        },
                      ),
                      _PresetPromptCard(
                        title: "Canvas Mini-App",
                        prompt:
                            "Build a beautiful interactive dashboard in canvas-ui containing a CPU load card and a live deploy log terminal.",
                        onTap: () {
                          controller.text =
                              "Build a beautiful interactive dashboard in canvas-ui containing a CPU load card and a live deploy log terminal.";
                          focusNode.requestFocus();
                        },
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 48),
              Text.rich(
                TextSpan(
                  text:
                      'Powered by DeepSeek. Do not share sensitive information. ',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  children: [
                    TextSpan(
                      text: 'Privacy Note →',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(
                            Uri.parse(
                              'https://github.com/ComsIndeed/streaming_gen_ui/blob/main/PRIVACY.md',
                            ),
                          );
                        },
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
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
    if (message.isError) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
              ? Colors.black.withValues(alpha: 0.9)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
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
  bool? _hasAcceptedDisclosure;

  // Design Theme selector state
  bool _singleThemeMode = true; // true = single, false = multiple
  String _selectedSingleTheme = 'apple';
  Set<String> _selectedMultipleThemes = {'apple'};
  bool _includePrimitives = false;

  static const _allThemes = [
    ('apple', Icons.phone_iphone_rounded),
    ('fluent', Icons.window_rounded),
    ('material', Icons.layers_rounded),
    ('glassmorphic', Icons.blur_on_rounded),
    ('neumorphic', Icons.texture_rounded),
    ('skeumorphic', Icons.style_rounded),
    ('brutalist', Icons.grid_on_rounded),
  ];

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
    _loadDisclosurePreference();
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

  Future<void> _loadDisclosurePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('hasAcceptedDataDisclosure') ?? false;
    if (!mounted) return;
    setState(() {
      _hasAcceptedDisclosure = accepted;
    });
  }

  Future<bool> _ensureDisclosureAccepted() async {
    if (_hasAcceptedDisclosure == true) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('hasAcceptedDataDisclosure') ?? false;
    if (accepted) {
      if (mounted) {
        setState(() {
          _hasAcceptedDisclosure = true;
        });
      }
      return true;
    }

    final didAccept = await _showDisclosureModal();
    if (didAccept) {
      await prefs.setBool('hasAcceptedDataDisclosure', true);
      if (mounted) {
        setState(() {
          _hasAcceptedDisclosure = true;
        });
      }
    }

    return didAccept;
  }

  Future<bool> _showDisclosureModal() async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Data Disclosure'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const Text(
              'This demo sends your messages to the DeepSeek API for processing. '
              'DeepSeek may collect and store prompt data on servers in China and may use it to improve their models. '
              'I do not store your messages. Do not enter personal, sensitive, or confidential information.',
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Nevermind'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('I Understand'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _submit() async {
    final cubit = context.read<ChatDemoCubit>();
    if (cubit.state.isThinking) {
      cubit.stopResponse();
      return;
    }
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      final accepted = await _ensureDisclosureAccepted();
      if (!accepted) return;
      cubit.sendMessage(text);
      widget.controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatDemoCubit, ChatDemoState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final isMobile = ResponsiveBreakpoints.of(context).isMobile;

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
            ? theme.colorScheme.primary.withValues(alpha: 0.5)
            : (_isConsoleHovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.25)
                  : theme.colorScheme.outline.withValues(alpha: 0.08));

        final borderWidth = _isTextFieldFocused ? 1.5 : 1.0;

        final List<BoxShadow> shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          if (_isTextFieldFocused)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 0),
            )
          else if (_isConsoleHovered)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.04),
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
              curve: customSnap,
              // curve: _isAnimatingChatExpansion
              //     ? Curves.easeInOutBack
              //     : customSnap,
              onEnd: () {
                if (_isAnimatingChatExpansion) {
                  setState(() {
                    _isAnimatingChatExpansion = false;
                  });
                }
              },
              width: isMobile
                  ? (widget.isChatExpanded
                        ? (widget.sizes.width - 16)
                        : (widget.sizes.width - 48))
                  : (widget.isCanvasExpanded
                        ? (widget.sizes.width * 0.4 - 32).clamp(
                            100.0,
                            512.0 + (widget.isChatExpanded ? 64 : 0),
                          )
                        : 512.0 + (widget.isChatExpanded ? 64 : 0)),
              height: widget.isChatExpanded ? 330.0 : 64.0,
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
                                ? const Icon(
                                    Icons.close,
                                    key: ValueKey('close'),
                                  )
                                : const Icon(Icons.menu, key: ValueKey('add')),
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: Durations.short4,
                          child: widget.isChatExpanded
                              ? _buildExpandedDrawerInput(context, state, theme)
                              : TextField(
                                  controller: widget.controller,
                                  focusNode: widget.focusNode,
                                  onSubmitted: (_) {
                                    if (!state.isThinking) {
                                      _submit();
                                    }
                                  },
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: const InputDecoration(
                                    hintText: 'Talk to AI',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
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
                                style: state.isThinking
                                    ? IconButton.styleFrom(
                                        backgroundColor: Colors.red.withValues(
                                          alpha: 0.12,
                                        ),
                                      )
                                    : null,
                                icon: Icon(
                                  state.isThinking
                                      ? Icons.stop_rounded
                                      : Icons.arrow_upward,
                                  color: state.isThinking
                                      ? Colors.red
                                      : theme.colorScheme.onPrimary,
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
      },
    );
  }

  Widget _buildExpandedDrawerInput(
    BuildContext context,
    ChatDemoState state,
    ThemeData theme,
  ) {
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
                  icon: Icons.dashboard_customize_rounded,
                  title: "Canvas Preview",
                  subtitle: "Open canvas UI",
                  theme: theme,
                  isAction: true,
                  isEnabled: true,
                  onTap: () {
                    context.read<ChatDemoCubit>().setCanvasMode(CanvasMode.ui);
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
        const SizedBox(height: 12),
        // Design Theme selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: () => _showDesignThemeModal(context, theme),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Design Theme',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _singleThemeMode
                            ? _selectedSingleTheme[0].toUpperCase() +
                                  _selectedSingleTheme.substring(1)
                            : '${_selectedMultipleThemes.length} selected',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_includePrimitives) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+primitives',
                          style: TextStyle(
                            fontSize: 9,
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDesignThemeModal(BuildContext context, ThemeData theme) {
    final cubit = context.read<ChatDemoCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.7,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Design Theme',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mode Toggle: Single vs Multiple
                          Text(
                            'SELECTION MODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                _ThemeModeRadioTile(
                                  title: 'Single Theme',
                                  subtitle: 'Use one curated design aesthetic',
                                  icon: Icons.radio_button_checked_rounded,
                                  selected: _singleThemeMode,
                                  onTap: () {
                                    setModalState(() {});
                                    setState(() => _singleThemeMode = true);
                                  },
                                ),
                                Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.08,
                                  ),
                                ),
                                _ThemeModeRadioTile(
                                  title: 'Multiple Themes',
                                  subtitle:
                                      'Mix styles from several aesthetics',
                                  icon: Icons.library_add_check_rounded,
                                  selected: !_singleThemeMode,
                                  onTap: () {
                                    setModalState(() {});
                                    setState(() => _singleThemeMode = false);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Theme chips
                          Text(
                            _singleThemeMode ? 'THEME' : 'THEMES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allThemes.map((entry) {
                              final (themeId, icon) = entry;
                              final label =
                                  themeId[0].toUpperCase() +
                                  themeId.substring(1);
                              final isSelected = _singleThemeMode
                                  ? _selectedSingleTheme == themeId
                                  : _selectedMultipleThemes.contains(themeId);
                              return GestureDetector(
                                onTap: () {
                                  if (_singleThemeMode) {
                                    setModalState(() {});
                                    setState(
                                      () => _selectedSingleTheme = themeId,
                                    );
                                  } else {
                                    setModalState(() {});
                                    setState(() {
                                      if (_selectedMultipleThemes.contains(
                                        themeId,
                                      )) {
                                        if (_selectedMultipleThemes.length >
                                            1) {
                                          _selectedMultipleThemes = Set.from(
                                            _selectedMultipleThemes,
                                          )..remove(themeId);
                                        }
                                      } else {
                                        _selectedMultipleThemes = Set.from(
                                          _selectedMultipleThemes,
                                        )..add(themeId);
                                      }
                                    });
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary.withValues(
                                            alpha: 0.12,
                                          )
                                        : theme
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                                .withValues(alpha: 0.5)
                                          : theme.colorScheme.outline
                                                .withValues(alpha: 0.1),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 15,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          // Include Primitives checkbox
                          GestureDetector(
                            onTap: () {
                              setModalState(() {});
                              setState(
                                () => _includePrimitives = !_includePrimitives,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: _includePrimitives
                                    ? theme.colorScheme.tertiary.withValues(
                                        alpha: 0.08,
                                      )
                                    : theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _includePrimitives
                                      ? theme.colorScheme.tertiary.withValues(
                                          alpha: 0.4,
                                        )
                                      : theme.colorScheme.outline.withValues(
                                          alpha: 0.08,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _includePrimitives
                                          ? theme.colorScheme.tertiary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: _includePrimitives
                                            ? theme.colorScheme.tertiary
                                            : theme.colorScheme.outline
                                                  .withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _includePrimitives
                                        ? Icon(
                                            Icons.check_rounded,
                                            size: 13,
                                            color: theme.colorScheme.onTertiary,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Include Primitives',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Add core layout & text primitives to the registry',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      cubit.updateRegistry(
        _singleThemeMode ? {_selectedSingleTheme} : _selectedMultipleThemes,
        includePrimitives: _includePrimitives,
      );
    });
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
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
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
                      color: Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.08,
                        ),
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
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : (_isHovered && widget.isEnabled
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ));

    final borderColor = widget.isToggle && _toggleState
        ? theme.colorScheme.primary.withValues(alpha: 0.4)
        : (_isHovered && widget.isEnabled
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.outline.withValues(alpha: 0.08));

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
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
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
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
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
                  ? theme.colorScheme.primary.withValues(alpha: 0.04)
                  : theme.colorScheme.surfaceContainerLow.withValues(
                      alpha: 0.6,
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : theme.colorScheme.outline.withValues(alpha: 0.08),
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
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
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

class _ThemeModeRadioTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeRadioTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
