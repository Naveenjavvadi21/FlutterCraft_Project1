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
import '../chat/chat_room_screen.dart';

/// Screen for searching registered users by name or email
class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final currentUserId = context.read<AuthProvider>().currentUser?.uid;
    if (currentUserId != null) {
      context.read<UserProvider>().searchUsers(query, currentUserId);
    }
  }

  Future<void> _startChat(UserModel targetUser) async {
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
        Navigator.of(context).push(
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search people by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<UserProvider>().clearSearch();
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Content
            Expanded(
              child: userProvider.isLoading
                  ? const LoadingWidget(message: 'Searching directory...')
                  : _searchController.text.trim().isEmpty
                      ? const EmptyState(
                          icon: Icons.person_search_rounded,
                          title: 'Search Directory',
                          description: 'Type a name or email address above to find contacts and start chatting.',
                        )
                      : userProvider.searchResults.isEmpty
                          ? EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No Users Found',
                              description: 'No users matched "${_searchController.text}". Check the spelling and try again.',
                            )
                          : ListView.separated(
                              itemCount: userProvider.searchResults.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                              itemBuilder: (context, index) {
                                final user = userProvider.searchResults[index];
                                return ListTile(
                                  leading: UserAvatar(
                                    name: user.name,
                                    photoUrl: user.photoUrl,
                                    isOnline: user.isOnline,
                                    showOnlineIndicator: true,
                                    radius: 24,
                                  ),
                                  title: Text(
                                    user.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    user.email,
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        user.isOnline
                                            ? '● Online'
                                            : ChatDateUtils.formatLastSeen(
                                                isOnline: false,
                                                lastSeen: user.lastSeen,
                                              ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: user.isOnline
                                              ? AppConstants.onlineColor
                                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                          fontWeight: user.isOnline ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _startChat(user),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
