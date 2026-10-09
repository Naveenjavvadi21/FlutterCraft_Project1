import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/user_avatar.dart';
import 'chat_room_screen.dart';
import 'group_chat_screen.dart';

/// Screen allowing users to select a contact to start a 1-to-1 conversation or initiate a group
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = context.read<AuthProvider>().currentUser?.uid;
      if (currentUserId != null) {
        context.read<UserProvider>().fetchAllUsers(currentUserId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startDirectChat(UserModel targetUser) async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    try {
      final room = await _chatService.getOrCreateDirectChatRoom(
        currentUserId: currentUser.uid,
        currentUserName: currentUser.name,
        otherUserId: targetUser.uid,
        otherUserName: targetUser.name,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(chatRoom: room),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final users = userProvider.allUsers.where((u) {
      if (_searchFilter.isEmpty) return true;
      final term = _searchFilter.toLowerCase();
      return u.name.toLowerCase().contains(term) || u.email.toLowerCase().contains(term);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchFilter = val.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search people by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchFilter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchFilter = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Option to create group
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.15),
              radius: 22,
              child: const Icon(Icons.group_add_rounded, color: AppConstants.primaryColor),
            ),
            title: const Text(
              'New Group',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text('Create a chat with multiple people'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GroupChatScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),

          // User list
          Expanded(
            child: userProvider.isLoading
                ? const LoadingWidget(message: 'Loading contacts...')
                : users.isEmpty
                    ? const EmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'No users found',
                        description: 'Invite your friends to register and chat with them on ChatFlow.',
                      )
                    : ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 68),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: UserAvatar(
                              name: user.name,
                              photoUrl: user.photoUrl,
                              isOnline: user.isOnline,
                              showOnlineIndicator: true,
                              radius: 22,
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              user.isOnline
                                  ? 'Online'
                                  : ChatDateUtils.formatLastSeen(
                                      isOnline: false,
                                      lastSeen: user.lastSeen,
                                    ),
                              style: TextStyle(
                                color: user.isOnline
                                    ? AppConstants.onlineColor
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                fontSize: 13,
                              ),
                            ),
                            trailing: Text(
                              user.email,
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () => _startDirectChat(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
