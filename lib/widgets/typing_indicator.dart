import 'package:flutter/material.dart';

/// Animated 3-dot typing indicator bubble with smooth wave motion
class TypingIndicator extends StatefulWidget {
  final String? userName;
  final bool isBubble;

  const TypingIndicator({
    super.key,
    this.userName,
    this.isBubble = true,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index, ThemeData theme) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Offset each dot's sine wave animation
        final delay = index * 0.2;
        final value = (_controller.value + delay) % 1.0;
        final offsetY = -4.0 * (1.0 - (2.0 * (value - 0.5)).abs());

        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dotRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0, theme),
        _buildDot(1, theme),
        _buildDot(2, theme),
      ],
    );

    if (!widget.isBubble) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dotRow,
          if (widget.userName != null) ...[
            const SizedBox(width: 8),
            Text(
              '${widget.userName} is typing...',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF2F7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.userName != null) ...[
              Text(
                '${widget.userName} is typing',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            dotRow,
          ],
        ),
      ),
    );
  }
}
