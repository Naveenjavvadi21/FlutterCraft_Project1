import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/user_avatar.dart';
import 'chat_room_screen.dart';

/// Screen for creating a multi-member group conversation
class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();

  XFile? _groupPhoto;
  bool _isCreating = false;

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
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _groupPhoto = picked;
      });
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member for the group.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final allMembers = [currentUser.uid, ..._selectedMemberIds];
      final memberNames = <String, String>{
        currentUser.uid: currentUser.name,
      };

      for (final id in _selectedMemberIds) {
        final member = userProvider.allUsers.firstWhere(
          (u) => u.uid == id,
          orElse: () => UserModel(uid: id, name: 'User', email: ''),
        );
        memberNames[id] = member.name;
      }

      String? photoUrl;
      // Generate temporary id to store image or upload with auto-id
      final groupName = _nameController.text.trim();
      if (_groupPhoto != null) {
        photoUrl = await _storageService.uploadChatImage(
          roomId: 'groups',
          file: _groupPhoto!,
        );
      }

      final createdRoom = await _chatService.createGroupChatRoom(
        groupName: groupName,
        groupPhotoUrl: photoUrl,
        memberIds: allMembers,
        memberNames: memberNames,
        createdBy: currentUser.uid,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(chatRoom: createdRoom),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Group'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header: Group Avatar + Name
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                      child: _groupPhoto != null
                          ? const Icon(Icons.check, color: AppConstants.onlineColor, size: 32)
                          : Icon(Icons.camera_alt, color: theme.colorScheme.primary, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      validator: Validators.validateGroupName,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        hintText: 'e.g. Flutter Developers',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Members (${_selectedMemberIds.length} selected)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // User Checklist
          Expanded(
            child: userProvider.isLoading
                ? const LoadingWidget(message: 'Loading users...')
                : ListView.builder(
                    itemCount: userProvider.allUsers.length,
                    itemBuilder: (context, index) {
                      final user = userProvider.allUsers[index];
                      final isSelected = _selectedMemberIds.contains(user.uid);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              _selectedMemberIds.add(user.uid);
                            } else {
                              _selectedMemberIds.remove(user.uid);
                            }
                          });
                        },
                        secondary: UserAvatar(name: user.name, radius: 20),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
