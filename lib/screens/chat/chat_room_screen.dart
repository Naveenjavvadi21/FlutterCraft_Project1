import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../firebase_options.dart';
import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_input.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/user_avatar.dart';

/// One-to-one and Group Real-time Chat Room screen
class ChatRoomScreen extends StatefulWidget {
  final ChatRoomModel chatRoom;

  const ChatRoomScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentLimit = AppConstants.initialMessageLimit;
  bool _isLoadingMore = false;
  final bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
    });
  }

  void _markRead() {
    final currentUserId = context.read<AuthProvider>().currentUser?.uid;
    if (currentUserId != null) {
      context.read<ChatProvider>().markRoomAsRead(
            roomId: widget.chatRoom.id,
            currentUserId: currentUserId,
          );
    }
  }

  void _onScroll() {
    // In reverse ListView, maxScrollExtent corresponds to the oldest messages
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreMessages) {
      _loadOlderMessages();
    }
  }

  void _loadOlderMessages() {
    setState(() {
      _isLoadingMore = true;
      _currentLimit += AppConstants.paginationMessageLimit;
    });

    // Reset loading state after stream update
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';
    final currentUserName = authProvider.currentUser?.name ?? 'User';

    final isGroup = widget.chatRoom.isGroup;
    final otherUserId = widget.chatRoom.getOtherUserId(currentUserId);
    final roomName = isGroup
        ? (widget.chatRoom.groupName ?? 'Group')
        : (widget.chatRoom.memberNames[otherUserId] ?? 'Chat');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _buildAppBarTitle(otherUserId, isGroup, roomName, isDark),
        actions: [
          if (isGroup)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => _showGroupDetails(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Real-time messages stream
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatProvider.getRoomMessages(
                widget.chatRoom.id,
                limit: _currentLimit,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const LoadingWidget(message: 'Loading conversation...');
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppConstants.errorColor),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load messages',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.waving_hand_rounded,
                            size: 52,
                            color: theme.colorScheme.primary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Say Hello 👋',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No messages here yet. Send a message to start the conversation.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Latest message at bottom
                  itemCount: messages.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoadingMore && index == messages.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final message = messages[index];
                    final isOutgoing = message.senderId == currentUserId;

                    // Date separator check
                    final hasNextMessage = index < messages.length - 1;
                    final nextMessage = hasNextMessage ? messages[index + 1] : null;
                    final showDateSeparator = nextMessage == null ||
                        ChatDateUtils.isDifferentDay(
                          message.timestamp,
                          nextMessage.timestamp,
                        );

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showDateSeparator) _buildDateSeparator(message.timestamp, isDark),
                        MessageBubble(
                          message: message,
                          isOutgoing: isOutgoing,
                          showSenderName: isGroup && !isOutgoing,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Real-time typing indicator bar
          StreamBuilder<ChatRoomModel?>(
            stream: chatProvider.getRoomDetails(widget.chatRoom.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final room = snapshot.data!;
              final typingMap = room.typing;

              // Check if any member other than current user is typing
              String? typingUserName;
              for (final entry in typingMap.entries) {
                if (entry.key != currentUserId && entry.value == true) {
                  typingUserName = room.memberNames[entry.key] ?? 'Someone';
                  break;
                }
              }

              if (typingUserName != null) {
                return TypingIndicator(userName: typingUserName);
              }
              return const SizedBox.shrink();
            },
          ),

          // Bottom message input composer
          MessageInput(
            isSending: chatProvider.isSending,
            isUploadingImage: chatProvider.isUploadingImage,
            onTyping: (text) {
              chatProvider.onUserTyping(
                roomId: widget.chatRoom.id,
                userId: currentUserId,
                currentInput: text,
              );
            },
            onSendText: (text) {
              chatProvider.sendTextMessage(
                roomId: widget.chatRoom.id,
                senderId: currentUserId,
                senderName: currentUserName,
                text: text,
                memberIds: widget.chatRoom.members,
              );
            },
            onSendImage: (image, caption) {
              chatProvider.sendImageMessage(
                roomId: widget.chatRoom.id,
                senderId: currentUserId,
                senderName: currentUserName,
                imageFile: image,
                memberIds: widget.chatRoom.members,
                caption: caption,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(
      String otherUserId, bool isGroup, String roomName, bool isDark) {
    if (isGroup) {
      return Row(
        children: [
          UserAvatar(
            name: roomName,
            photoUrl: widget.chatRoom.groupPhotoUrl,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.chatRoom.members.length} members',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (!DefaultFirebaseOptions.isConfigured) {
      return Row(
        children: [
          UserAvatar(
            name: roomName,
            photoUrl: null,
            radius: 20,
            showOnlineIndicator: true,
            isOnline: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.onlineColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Direct 1-1 chat: live presence stream of peer
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(otherUserId)
          .snapshots(),
      builder: (context, snapshot) {
        String name = roomName;
        String? photoUrl;
        bool isOnline = false;
        DateTime? lastSeen;

        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data()!;
          name = data['name'] as String? ?? roomName;
          photoUrl = data['photoUrl'] as String?;
          isOnline = data['isOnline'] as bool? ?? false;
          final dynamic rawLastSeen = data['lastSeen'];
          if (rawLastSeen is Timestamp) {
            lastSeen = rawLastSeen.toDate();
          }
        }

        return Row(
          children: [
            UserAvatar(
              name: name,
              photoUrl: photoUrl,
              radius: 20,
              showOnlineIndicator: true,
              isOnline: isOnline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ChatDateUtils.formatLastSeen(isOnline: isOnline, lastSeen: lastSeen),
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline
                          ? AppConstants.onlineColor
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      fontWeight: isOnline ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime? timestamp, bool isDark) {
    if (timestamp == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ChatDateUtils.formatDateSeparator(timestamp),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        ),
      ),
    );
  }

  void _showGroupDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chatRoom.groupName ?? 'Group',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Members (${widget.chatRoom.members.length}):',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: widget.chatRoom.members.map((memberId) {
                    final name = widget.chatRoom.memberNames[memberId] ?? 'Member';
                    final isCreator = memberId == widget.chatRoom.createdBy;
                    return ListTile(
                      leading: UserAvatar(name: name, radius: 18),
                      title: Text(name),
                      trailing: isCreator
                          ? const Chip(
                              label: Text('Admin', style: TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
