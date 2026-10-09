import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../models/chat_room_model.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import 'user_avatar.dart';

/// Conversation tile in the Chat list dashboard
class ChatTile extends StatelessWidget {
  final ChatRoomModel room;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = room.getUnreadCount(currentUserId);
    final isGroup = room.isGroup;

    if (isGroup) {
      return _buildTile(
        context: context,
        title: room.groupName ?? 'Group',
        photoUrl: room.groupPhotoUrl,
        isOnline: false,
        showOnline: false,
        unreadCount: unreadCount,
      );
    }

    final otherUserId = room.getOtherUserId(currentUserId);
    final cachedName = room.memberNames[otherUserId] ?? 'User';

    if (!DefaultFirebaseOptions.isConfigured) {
      return _buildTile(
        context: context,
        title: cachedName,
        photoUrl: null,
        isOnline: true,
        showOnline: true,
        unreadCount: unreadCount,
      );
    }

    // Stream other user's presence & profile photo
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(otherUserId)
          .snapshots(),
      builder: (context, snapshot) {
        String name = cachedName;
        String? photoUrl;
        bool isOnline = false;

        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data()!;
          name = data['name'] as String? ?? cachedName;
          photoUrl = data['photoUrl'] as String?;
          isOnline = data['isOnline'] as bool? ?? false;
        }

        return _buildTile(
          context: context,
          title: name,
          photoUrl: photoUrl,
          isOnline: isOnline,
          showOnline: true,
          unreadCount: unreadCount,
        );
      },
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required String title,
    required String? photoUrl,
    required bool isOnline,
    required bool showOnline,
    required int unreadCount,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isYou = room.lastSenderId == currentUserId;

    String lastMessagePrefix = '';
    if (isYou && room.lastMessage.isNotEmpty) {
      lastMessagePrefix = 'You: ';
    }

    return InkWell(
      onTap: onTap,
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                UserAvatar(
                  name: title,
                  photoUrl: photoUrl,
                  radius: 26,
                  showOnlineIndicator: showOnline,
                  isOnline: isOnline,
                ),
                if (room.isGroup)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.group,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ChatDateUtils.formatChatListTime(room.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0
                              ? theme.colorScheme.primary
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.lastMessage.isEmpty
                              ? (room.isGroup ? 'Group conversation' : 'Tap to start chatting')
                              : '$lastMessagePrefix${room.lastMessage}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCount > 0
                                ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
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
