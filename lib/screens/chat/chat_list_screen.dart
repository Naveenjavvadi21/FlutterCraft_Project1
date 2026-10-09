import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'chat_room_screen.dart';
import 'new_chat_screen.dart';

/// Active conversations dashboard tab
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      body: Column(
        children: [
          // Quick filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Real-time chat list stream
          Expanded(
            child: StreamBuilder<List<ChatRoomModel>>(
              stream: chatProvider.getUserChatRooms(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const LoadingWidget(message: 'Loading conversations...');
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Unable to load chats: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppConstants.errorColor),
                      ),
                    ),
                  );
                }

                final allRooms = snapshot.data ?? [];

                // Filter by local search query if typed
                final rooms = allRooms.where((room) {
                  if (_searchQuery.isEmpty) return true;
                  final otherUserId = room.getOtherUserId(currentUserId);
                  final name = room.isGroup
                      ? (room.groupName ?? '')
                      : (room.memberNames[otherUserId] ?? '');
                  final lastMsg = room.lastMessage;
                  return name.toLowerCase().contains(_searchQuery) ||
                      lastMsg.toLowerCase().contains(_searchQuery);
                }).toList();

                if (rooms.isEmpty) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: _searchQuery.isNotEmpty ? 'No results found' : 'No conversations yet',
                    description: _searchQuery.isNotEmpty
                        ? 'Try searching with a different keyword.'
                        : 'Start a new chat to begin messaging with friends or team members.',
                    actionLabel: _searchQuery.isEmpty ? 'Start a Chat' : null,
                    onAction: _searchQuery.isEmpty
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const NewChatScreen(),
                              ),
                            );
                          }
                        : null,
                  );
                }

                return ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 82,
                  ),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return ChatTile(
                      room: room,
                      currentUserId: currentUserId,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(chatRoom: room),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Chat',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NewChatScreen(),
            ),
          );
        },
        child: const Icon(Icons.chat_rounded),
      ),
    );
  }
}
