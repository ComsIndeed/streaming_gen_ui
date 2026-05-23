import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/theme_style_helper.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A premium, shared Profile Card widget that displays contacts and portfolios,
/// providing offline-safe vector avatar fallbacks for privacy and premium styling.
class BaseThemedUserProfile extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedUserProfile({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedUserProfile> createState() => _BaseThemedUserProfileState();
}

class _BaseThemedUserProfileState extends State<BaseThemedUserProfile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final mapStream = widget.props.asMap;

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: mapStream.stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final settings = data["themeSettings"] as Map<String, dynamic>? ?? const {};

          final name = data["name"] as String?;
          final role = data["role"] as String?;
          final website = data["website"] as String?;
          final avatarUrl = data["avatarUrl"] as String?;
          final bio = data["bio"] as String?;
          final action = data["action"] as String?;

          final skillsList = data["skills"] as List<dynamic>? ?? const [];

          final decoration = ThemeStyleHelper.getCardDecoration(
            widget.themeName,
            settings,
            context,
            isPressed: _isPressed,
          );

          final shape = ThemeStyleHelper.getCardShape(
            widget.themeName,
            (settings["borderRadius"] as num?)?.toDouble(),
            context,
          );

          final cardContent = _buildProfileContent(
            context,
            name,
            role,
            website,
            avatarUrl,
            bio,
            skillsList,
            action,
          );

          Widget frame;

          if (widget.themeName == 'glassmorphic') {
            frame = ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ColorFilter.mode(Colors.black.withOpacity(0.02), BlendMode.dstATop),
                child: Container(
                  decoration: decoration,
                  child: cardContent,
                ),
              ),
            );
          } else if (widget.themeName == 'fluent') {
            frame = ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ColorFilter.mode(Colors.black.withOpacity(0.04), BlendMode.dstATop),
                child: Container(
                  decoration: decoration,
                  child: cardContent,
                ),
              ),
            );
          } else {
            frame = Container(
              decoration: decoration,
              child: Material(
                type: MaterialType.transparency,
                shape: shape,
                clipBehavior: Clip.antiAlias,
                child: cardContent,
              ),
            );
          }

          return frame;
        },
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    String? name,
    String? role,
    String? website,
    String? avatarUrl,
    String? bio,
    List<dynamic> skills,
    String? action,
  ) {
    final theme = Theme.of(context);
    final titleStyle = ThemeStyleHelper.getTextStyle(widget.themeName, context, isTitle: true);
    final subStyle = ThemeStyleHelper.getTextStyle(widget.themeName, context, isTitle: false);

    // Build offline-safe avatar bubble
    Widget avatarWidget;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarWidget = CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: theme.colorScheme.primaryContainer,
      );
    } else {
      // Stunning local visual gradient vector to ensure privacy and offline rendering
      avatarWidget = Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.24),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 36,
          ),
        ),
      );
    }

    final hasAction = action != null && action.isNotEmpty;

    final contentLayout = Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatarWidget,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (name != null && name.isNotEmpty)
                      Text(
                        name,
                        style: titleStyle.copyWith(fontSize: 18.0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (role != null && role.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: subStyle.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Bio Section
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              bio,
              style: subStyle.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.85),
                height: 1.4,
              ),
            ),
          ],
          // Skills Wrap Section
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(skills.length, (index) {
                final skillText = skills[index].toString();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.themeName == 'brutalist'
                        ? const Color(0xFF00FFFF) // Cyan
                        : theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(widget.themeName == 'brutalist' ? 0.0 : 8.0),
                    border: Border.all(
                      color: widget.themeName == 'brutalist'
                          ? Colors.black
                          : theme.colorScheme.outline.withOpacity(0.08),
                      width: widget.themeName == 'brutalist' ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    skillText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: widget.themeName == 'brutalist' ? 'monospace' : null,
                      color: widget.themeName == 'brutalist' ? Colors.black : theme.colorScheme.primary,
                    ),
                  ),
                );
              }),
            ),
          ],
          // Footer Links / Portfolio Actions
          if (website != null && website.isNotEmpty) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                debugPrint('[GEN_UI:PORTFOLIO_NAV] Navigating to: $website');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    website.replaceAll('https://', '').replaceAll('http://', ''),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasAction) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                onTap: () {
                  debugPrint('[GEN_UI:PROFILE_ACTION] Callback triggered -> $action');
                },
                child: AnimatedScale(
                  scale: _isPressed ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.themeName == 'brutalist'
                          ? const Color(0xFFFF00FF) // Hot Pink
                          : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(widget.themeName == 'brutalist' ? 0.0 : 8.0),
                      border: Border.all(
                        color: widget.themeName == 'brutalist' ? Colors.black : Colors.transparent,
                        width: widget.themeName == 'brutalist' ? 2.0 : 0.0,
                      ),
                    ),
                    child: Text(
                      'Get in Touch',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: widget.themeName == 'brutalist' ? 'monospace' : null,
                        color: widget.themeName == 'brutalist' ? Colors.black : theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: contentLayout,
    );
  }
}
