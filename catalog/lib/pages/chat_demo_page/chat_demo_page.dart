import 'dart:async';
import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/utilities/stream_text_in_chunks.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';

class ChatDemoPage extends StatefulWidget {
  const ChatDemoPage({super.key});

  @override
  State<ChatDemoPage> createState() => _ChatDemoPageState();
}

class _ChatDemoPageState extends State<ChatDemoPage> {
  bool isChatExpanded = false;
  bool isCanvasExpanded = false;
  
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Engine and controllers for live streamed AI bubble widgets
  late final StreamingGenerativeUi _bubbleStreamEngine;
  final StreamController<String> _bubbleStreamController = StreamController<String>.broadcast();
  bool _isBubbleStreaming = false;

  @override
  void initState() {
    super.initState();
    _bubbleStreamEngine = StreamingGenerativeUi(registry: Registries.all);
    _bubbleStreamEngine.stream(_bubbleStreamController.stream, viewId: 'ai-bubble-widget');
  }

  @override
  void dispose() {
    _bubbleStreamController.close();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    // 1. Add User query
    setState(() {
      _messages.add({
        "sender": "user",
        "text": query,
        "widgetType": null,
      });
      _chatController.clear();
      isChatExpanded = false; // Collapse text area back with spring animation on send
    });

    _scrollToBottom();

    // 2. AI response stream after a brief typing thinking gap
    Timer(const Duration(milliseconds: 800), () {
      setState(() {
        _messages.add({
          "sender": "ai",
          "text": "Initiated backend docker node server deployment logs. I have automatically opened the diagnostic monitor panel on the right side for you:",
          "widgetType": "agent",
        });
        isCanvasExpanded = true; // Slide open the 60% Canvas panel!
      });
      
      _scrollToBottom();

      // 3. Stream the interactive Agent stepper widget inside the chat bubble
      final stepperText = '<interface>{"namespace":"doc:agent_stepper","steps":[{"title":"Initialize Node Container","status":"completed","duration":"70ms"},{"title":"Pull Docker Repository","status":"completed","duration":"190ms"},{"title":"Deploy Production Host","status":"running","duration":""},{"title":"Expose Ports & Run Probe","status":"pending","duration":""}]}</interface>';
      
      _isBubbleStreaming = true;
      streamTextInChunks(
        text: stepperText,
        chunkSize: 6,
        interval: const Duration(milliseconds: 80),
      ).listen(
        (chunk) {
          _bubbleStreamController.add(chunk);
        },
        onDone: () {
          setState(() {
            _isBubbleStreaming = false;
          });
        },
      );
    });
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizes = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final isMobile = sizes.width < 768;

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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      child: Column(
                        children: [
                          // Header Pill
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                                      children: [
                                        const TextSpan(
                                          text: "Streaming ",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const TextSpan(
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
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Scrollable Bubbles list
                          Expanded(
                            child: _messages.isEmpty
                                ? _buildEmptyPrompt(theme)
                                : ListView.builder(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                      final message = _messages[index];
                                      final isUser = message["sender"] == "user";
                                      final widgetType = message["widgetType"];

                                      return Align(
                                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          constraints: BoxConstraints(maxWidth: sizes.width * 0.5),
                                          child: Column(
                                            crossAxisAlignment:
                                                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                            children: [
                                              // Text bubble container
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: isUser
                                                      ? theme.colorScheme.primary
                                                      : theme.colorScheme.surfaceContainerHigh.withOpacity(0.9),
                                                  borderRadius: BorderRadius.only(
                                                    topLeft: const Radius.circular(20),
                                                    topRight: const Radius.circular(20),
                                                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                                                    bottomRight: Radius.circular(isUser ? 4 : 20),
                                                  ),
                                                  border: isUser
                                                      ? null
                                                      : Border.all(
                                                          color: theme.colorScheme.outline.withOpacity(0.08),
                                                        ),
                                                ),
                                                child: Text(
                                                  message["text"] as String,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    height: 1.3,
                                                    color: isUser
                                                        ? theme.colorScheme.onPrimary
                                                        : theme.colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),

                                              // Stream Generative UI inside Chat bubble
                                              if (widgetType != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Container(
                                                    width: 320,
                                                    decoration: ShapeDecoration(
                                                      shape: RoundedSuperellipseBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      shadows: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.05),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 4),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Card(
                                                      margin: EdgeInsets.zero,
                                                      shape: RoundedSuperellipseBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(10.0),
                                                        child: _bubbleStreamEngine.view('ai-bubble-widget'),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. RIGHT PANEL: Floating 60% Bento Canvas panel (Slides & Shifts the left panel)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubicEmphasized,
                    width: isCanvasExpanded ? (isMobile ? sizes.width : sizes.width * 0.6) : 0,
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
                              )
                            ]
                          : null,
                    ),
                    child: OverflowBox(
                      alignment: Alignment.topRight,
                      minWidth: isMobile ? sizes.width : sizes.width * 0.6,
                      maxWidth: isMobile ? sizes.width : sizes.width * 0.6,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: _buildCanvasContent(theme),
                    ),
                  ),
                ],
              ),

              // 3. User's exact custom animated chat textfield console
              AnimatedAlign(
                duration: Durations.short4,
                curve: Curves.easeInOut,
                alignment: .bottomCenter,
                child: AnimatedPadding(
                  duration: Durations.short4,
                  // Keep bounds aligned depending on expanded drawer side panel
                  padding: EdgeInsets.only(
                    bottom: isChatExpanded ? 16.0 : 28.0,
                    right: isCanvasExpanded && !isMobile ? sizes.width * 0.6 : 0,
                  ),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    // Scales responsively to fit inside the compressed left panel
                    width: isCanvasExpanded
                        ? (sizes.width * 0.4 - 32).clamp(100.0, 512.0 + (isChatExpanded ? 64 : 0))
                        : 512.0 + (isChatExpanded ? 64 : 0),
                    height: isChatExpanded ? 256.0 : 64.0,
                    decoration: ShapeDecoration(
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      color: theme.colorScheme.secondaryContainer,
                    ),
                    duration: Durations.medium2,
                    curve: Curves.easeOutBack,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedAlign(
                            alignment: isChatExpanded ? Alignment.topLeft : Alignment.centerLeft,
                            duration: Durations.short1,
                            child: IconButton(
                              onPressed: () => setState(() => isChatExpanded = !isChatExpanded),
                              icon: AnimatedSwitcher(
                                duration: Durations.short4,
                                child: isChatExpanded
                                    ? const Icon(Icons.close, key: ValueKey('close'))
                                    : const Icon(Icons.add, key: ValueKey('add')),
                              ),
                            ),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: Durations.short4,
                              child: isChatExpanded
                                  ? _buildExpandedDrawerInput(theme)
                                  : TextField(
                                      controller: _chatController,
                                      textAlignVertical: TextAlignVertical.center,
                                      decoration: const InputDecoration(
                                        hintText: 'Talk to AI',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      onSubmitted: (_) => _sendMessage(),
                                    ),
                            ),
                          ),
                          if (!isChatExpanded)
                            IconButton.filled(
                              onPressed: _sendMessage,
                              icon: Icon(
                                Icons.arrow_upward,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Visual prompt for clean startup
  Widget _buildEmptyPrompt(ThemeData theme) {
    final prompts = const [
      {"text": "Deploy production node server container"},
      {"text": "Query marketing analytics metric dashboard"},
      {"text": "Show concept gradient image carousel"},
    ];

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Let's try her out!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Send a prompt to stream dynamic widgets in conversation, or select one of the quick starters below:",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            ...prompts.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHigh.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _chatController.text = p["text"]!;
                      _sendMessage(); // Submit instantly!
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.primary.withOpacity(0.8),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p["text"]!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Expanded panel input contents
  Widget _buildExpandedDrawerInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            "ATTACHMENT CONSOLE",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
                  isCanvasExpanded ? Icons.analytics_rounded : Icons.analytics_outlined,
                  isCanvasExpanded ? "Close Monitor" : "Open Monitor",
                  theme,
                  onTap: () {
                    setState(() {
                      isCanvasExpanded = !isCanvasExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerPill(IconData icon, String label, ThemeData theme, {VoidCallback? onTap}) {
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
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // 60% Floating Bento canvas card contents
  Widget _buildCanvasContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.dashboard_customize_rounded, color: theme.colorScheme.primary, size: 22),
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
                  setState(() {
                    isCanvasExpanded = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Diagnostic cards
          const Text(
            "LIVE CONNECTION METRIC",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("CPU load", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text("12.4%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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
                    side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Memory", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        const Text("512MB / 2GB", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Running logs terminal block
          const Text(
            "LIVE DEPLOYMENT CONTAINER TERMINAL LOGS",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
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
