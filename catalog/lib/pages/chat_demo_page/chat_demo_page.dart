import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/chat_demo_page/chat_demo_cubit.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';

class ChatDemoPage extends StatelessWidget {
  const ChatDemoPage({super.key});

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
                              // Header Pill
                              Column(
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
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "Generative UI",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                          ),
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
                              const SizedBox(height: 24),
                              // Scrollable Chat Message Space
                              Expanded(
                                child: Column(
                                  children: [
                                    if (state.errorMessage != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.errorContainer,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: theme.colorScheme.error.withOpacity(0.3),
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
                                      ),
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          constraints: const BoxConstraints(maxWidth: 720),
                                          child: ListView.builder(
                                            itemCount: state.messages.length,
                                            padding: const EdgeInsets.only(bottom: 140, left: 16, right: 16),
                                            physics: const BouncingScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              final message = state.messages[index];
                                              if (message.isUser) {
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
                                              } else {
                                                final cubit = context.read<ChatDemoCubit>();
                                                return Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Container(
                                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.surfaceContainerLow,
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: theme.colorScheme.outline.withOpacity(0.08),
                                                      ),
                                                    ),
                                                    child: ListenableBuilder(
                                                      listenable: cubit.generativeUi,
                                                      builder: (context, _) {
                                                        return cubit.generativeUi.view(message.id);
                                                      },
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
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
                      AnimatedContainer(
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
                          color: theme.colorScheme.surfaceContainerLow
                              .withOpacity(0.95),
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
                      ),
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
                      child: _ChatConsoleInput(
                        isChatExpanded: isChatExpanded,
                        isCanvasExpanded: isCanvasExpanded,
                        sizes: sizes,
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

class _ChatConsoleInput extends StatefulWidget {
  final bool isChatExpanded;
  final bool isCanvasExpanded;
  final Size sizes;

  const _ChatConsoleInput({
    required this.isChatExpanded,
    required this.isCanvasExpanded,
    required this.sizes,
  });

  @override
  State<_ChatConsoleInput> createState() => _ChatConsoleInputState();
}

class _ChatConsoleInputState extends State<_ChatConsoleInput> {
  bool _isTextFieldFocused = false;
  bool _isSendButtonPressed = false;
  bool _isSendButtonHovered = false;
  bool _isConsoleHovered = false;

  late final FocusNode _focusNode;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _isTextFieldFocused) {
      setState(() {
        _isTextFieldFocused = _focusNode.hasFocus;
      });
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatDemoCubit>().sendMessage(text);
      _controller.clear();
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
          spreadRadius: 2,
          offset: const Offset(0, 0),
        )
      else if (_isConsoleHovered)
        BoxShadow(
          color: theme.colorScheme.primary.withOpacity(0.04),
          blurRadius: 16,
          spreadRadius: 1,
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
          duration: const Duration(milliseconds: 200),
          curve: customSnap,
          width: widget.isCanvasExpanded
              ? (widget.sizes.width * 0.4 - 32).clamp(
                  100.0,
                  512.0 + (widget.isChatExpanded ? 64 : 0),
                )
              : 512.0 + (widget.isChatExpanded ? 64 : 0),
          height: widget.isChatExpanded ? 256.0 : 64.0,
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
                            controller: _controller,
                            focusNode: _focusNode,
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
    );
  }

  Widget _buildExpandedDrawerInput(BuildContext context, ThemeData theme) {
    final isCanvasExpanded = context.select(
      (ChatDemoCubit c) => c.state.canvasMode != CanvasMode.hidden,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            "ATTACHMENT CONSOLE",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDrawerPill(Icons.image_rounded, "Media", theme),
                _buildDrawerPill(Icons.code_rounded, "Stream XML", theme),
                _buildDrawerPill(
                  isCanvasExpanded
                      ? Icons.analytics_rounded
                      : Icons.analytics_outlined,
                  isCanvasExpanded ? "Close Monitor" : "Open Monitor",
                  theme,
                  onTap: () {
                    context.read<ChatDemoCubit>().setCanvasMode(
                      isCanvasExpanded ? CanvasMode.hidden : CanvasMode.code,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerPill(
    IconData icon,
    String label,
    ThemeData theme, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
