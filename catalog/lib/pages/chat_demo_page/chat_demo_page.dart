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
  bool isCanvasExpanded = false;
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Engine instances for chat streams
  late final StreamingGenerativeUi _agentStreamEngine;
  late final StreamingGenerativeUi _metricStreamEngine;
  late final StreamingGenerativeUi _carouselStreamEngine;

  final StreamController<String> _agentStreamController =
      StreamController<String>.broadcast();
  final StreamController<String> _metricStreamController =
      StreamController<String>.broadcast();
  final StreamController<String> _carouselStreamController =
      StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();

    // Initialize streaming engines for bubbles
    _agentStreamEngine = StreamingGenerativeUi(registry: Registries.all);
    _metricStreamEngine = StreamingGenerativeUi(registry: Registries.all);
    _carouselStreamEngine = StreamingGenerativeUi(registry: Registries.all);

    _agentStreamEngine.stream(
      _agentStreamController.stream,
      viewId: 'bubble-agent',
    );
    _metricStreamEngine.stream(
      _metricStreamController.stream,
      viewId: 'bubble-metric',
    );
    _carouselStreamEngine.stream(
      _carouselStreamController.stream,
      viewId: 'bubble-carousel',
    );

    // Load initial greeting and play simulated generative UI streams
    _loadInitialConversation();
  }

  @override
  void dispose() {
    _agentStreamController.close();
    _metricStreamController.close();
    _carouselStreamController.close();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialConversation() {
    _messages.addAll([
      {
        "sender": "user",
        "text":
            "Hello AI! Can you plan a production server deployment and show me our core marketing performance stats?",
        "widgetType": null,
      },
      {
        "sender": "ai",
        "text":
            "Certainly! I've scheduled our backend deployment agent. Here is the real-time reasoning timeline:",
        "widgetType": "agent",
      },
      {
        "sender": "ai",
        "text":
            "Additionally, here is a quick snapshot of our active analytics stats and marketing banner concepts:",
        "widgetType": "stats",
      },
    ]);

    // Trigger mock streams after a small build layout gap
    Timer(const Duration(milliseconds: 600), () {
      _startSimulatedStreams();
    });
  }

  void _startSimulatedStreams() {
    // 1. Stream the Agent Timeline Stepper
    final agentText =
        '<interface>{"namespace":"doc:agent_stepper","steps":[{"title":"Initialize Node Server","status":"completed","duration":"80ms"},{"title":"Fetch Git repository","status":"completed","duration":"210ms"},{"title":"Running Docker Container","status":"running","duration":""},{"title":"Health Check Probes","status":"pending","duration":""}]}</interface>';
    streamTextInChunks(
      text: agentText,
      chunkSize: 5,
      interval: const Duration(milliseconds: 60),
    ).listen((c) => _agentStreamController.add(c));

    // 2. Stream the Metric Data
    final metricText =
        '<interface>{"namespace":"dash:metric","label":"Acquisition Rate","value":"+34.2%","trend":"2.4k new clicks","trendDirection":"up"}</interface>';
    streamTextInChunks(
      text: metricText,
      chunkSize: 6,
      interval: const Duration(milliseconds: 80),
    ).listen((c) => _metricStreamController.add(c));

    // 3. Stream the dynamic Image Carousel
    final carouselText =
        '<interface>{"namespace":"media:image","height":160.0,"borderRadius":16.0,"urls":["https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600","https://images.unsplash.com/photo-1604871000636-074fa5117945?w=600"]}</interface>';
    streamTextInChunks(
      text: carouselText,
      chunkSize: 8,
      interval: const Duration(milliseconds: 90),
    ).listen((c) => _carouselStreamController.add(c));
  }

  void _sendMessage() {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": query, "widgetType": null});
      _chatController.clear();
    });

    _scrollToBottom();

    // AI thinking delay
    Timer(const Duration(seconds: 1), () {
      setState(() {
        _messages.add({
          "sender": "ai",
          "text":
              "I've processed your query. Let's expand our visual timeline on the side Canvas Panel for detail diagnostics!",
          "widgetType": null,
        });
        isCanvasExpanded = true; // Auto expand layout shifter for rich content!
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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
              // Main Split Row (Left: Chat Feed Panel, Right: Collapsible side Canvas Panel)
              Row(
                children: [
                  // 1. LEFT PANEL: Chat conversation feed
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 64, 20, 96),
                      child: Column(
                        children: [
                          // Custom Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "AI Chat Room",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    "Conversational Generative UI",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                              // Floating Layout Shifter toggle pill
                              Container(
                                decoration: ShapeDecoration(
                                  shape: RoundedSuperellipseBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.12),
                                    ),
                                  ),
                                  color: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withOpacity(0.5),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    setState(() {
                                      isCanvasExpanded = !isCanvasExpanded;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isCanvasExpanded
                                              ? Icons.chevron_right_rounded
                                              : Icons.chevron_left_rounded,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isCanvasExpanded
                                              ? "Close Canvas"
                                              : "Open Canvas",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Chat bubble feed list
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isUser = message["sender"] == "user";
                                final widgetType = message["widgetType"];

                                return Align(
                                  alignment: isUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    constraints: BoxConstraints(
                                      maxWidth: sizes.width * 0.7,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isUser
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        // Text Bubble
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isUser
                                                ? theme.colorScheme.primary
                                                : theme
                                                      .colorScheme
                                                      .surfaceContainerHigh
                                                      .withOpacity(0.9),
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(
                                                20,
                                              ),
                                              topRight: const Radius.circular(
                                                20,
                                              ),
                                              bottomLeft: Radius.circular(
                                                isUser ? 20 : 4,
                                              ),
                                              bottomRight: Radius.circular(
                                                isUser ? 4 : 20,
                                              ),
                                            ),
                                            border: isUser
                                                ? null
                                                : Border.all(
                                                    color: theme
                                                        .colorScheme
                                                        .outline
                                                        .withOpacity(0.08),
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

                                        // Renders dynamic, live streaming widget inside chat bubbles
                                        if (widgetType != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                              bottom: 4.0,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: SizedBox(
                                                width: 320,
                                                child: Card(
                                                  elevation: 2,
                                                  margin: EdgeInsets.zero,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                    child: _buildBubbleWidget(
                                                      widgetType,
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. RIGHT PANEL: Sliding canvas container layout shifter
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubicEmphasized,
                    width: isCanvasExpanded
                        ? (isMobile ? sizes.width : 380.0)
                        : 0.0,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow.withOpacity(
                        0.95,
                      ),
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.12),
                          width: isCanvasExpanded ? 1.0 : 0.0,
                        ),
                      ),
                      boxShadow: isCanvasExpanded
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(-8, 0),
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isCanvasExpanded
                        ? _buildCanvasPanel(theme)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),

              // Chat text input bar docked at bottom left
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: isCanvasExpanded && !isMobile
                      ? sizes.width - 380.0
                      : sizes.width,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Container(
                    decoration: ShapeDecoration(
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.8),
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              decoration: const InputDecoration(
                                hintText: 'Message AI...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton.filled(
                            onPressed: _sendMessage,
                            icon: Icon(
                              Icons.send_rounded,
                              size: 16,
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

  // Visual selector matching the bubble stream controllers
  Widget _buildBubbleWidget(String type) {
    if (type == "agent") {
      return _agentStreamEngine.view('bubble-agent');
    } else if (type == "stats") {
      return Column(
        children: [
          _metricStreamEngine.view('bubble-metric'),
          const SizedBox(height: 8),
          _carouselStreamEngine.view('bubble-carousel'),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // Sliding Drawer rich document sheet console view
  Widget _buildCanvasPanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Canvas Console",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  setState(() {
                    isCanvasExpanded = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Diagnostics Cards
          const Text(
            "SYSTEM DIAGNOSTICS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.greenAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Production Node",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "Online - 99.98% SLA",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Code logs console
          const Text(
            "DEPLOYMENT TERMINAL LOGS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.12),
                ),
              ),
              child: const SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Text(
                  "\$ docker run -d -p 80:80 backend_agent\n"
                  "--> pulling layers [OK]\n"
                  "--> mounting filesystem [OK]\n"
                  "--> exposing server ports [OK]\n"
                  "--> logs: server running at http://localhost:80\n"
                  "--> diagnostic: latency 18ms\n"
                  "--> streaming socket initialized...\n"
                  "--> listening on port 80...\n"
                  "\$ _",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.lightGreenAccent,
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
