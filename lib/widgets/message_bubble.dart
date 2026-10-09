import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

/// WhatsApp/Telegram-inspired responsive message bubble
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOutgoing;
  final bool showSenderName;
  final VoidCallback? onImageTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    this.showSenderName = false,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    // Outgoing & incoming color palettes
    final bubbleColor = isOutgoing
        ? (isDark ? const Color(0xFF2563EB) : AppConstants.primaryColor)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF2F7));

    final textColor = isOutgoing
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    final timeColor = isOutgoing
        ? Colors.white.withValues(alpha: 0.75)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isOutgoing ? 18 : 4),
            bottomRight: Radius.circular(isOutgoing ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment:
                isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sender Name (visible in group chats for incoming messages)
              if (!isOutgoing && showSenderName) ...[
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF38BDF8) : AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Attached Image
              if (message.hasImage) ...[
                GestureDetector(
                  onTap: () {
                    if (onImageTap != null) {
                      onImageTap!();
                    } else {
                      _showFullScreenImage(context, message.imageUrl!);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: 'msg_img_${message.id}',
                      child: CachedNetworkImage(
                        imageUrl: message.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (message.text.isNotEmpty) const SizedBox(height: 6),
              ],

              // Message Text
              if (message.text.isNotEmpty)
                Text(
                  message.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),

              const SizedBox(height: 3),

              // Timestamp & Read Receipts
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    ChatDateUtils.formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: timeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (isOutgoing) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// WhatsApp-style status checkmark:
  /// - Sending: clock icon
  /// - Sent: single check ✓
  /// - Read: double check ✓✓ with teal/cyan highlight
  Widget _buildStatusIcon() {
    if (message.status == AppConstants.statusSending) {
      return const Icon(
        Icons.access_time,
        size: 13,
        color: Colors.white70,
      );
    }

    if (message.isRead || message.status == AppConstants.statusRead) {
      return const Icon(
        Icons.done_all,
        size: 15,
        color: AppConstants.readStatusColor,
      );
    }

    // Default sent status
    return const Icon(
      Icons.done,
      size: 14,
      color: Colors.white70,
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Hero(
                tag: 'msg_img_${message.id}',
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
