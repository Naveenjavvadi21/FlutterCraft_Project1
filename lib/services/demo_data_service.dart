import 'dart:async';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// In-memory demo data store for local previewing when Firebase is not yet linked
class DemoDataService {
  static final DemoDataService instance = DemoDataService._internal();

  DemoDataService._internal() {
    _initSeedData();
  }

  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();
  final Map<String, StreamController<List<MessageModel>>> _messageControllers = {};
  final _roomsController = StreamController<List<ChatRoomModel>>.broadcast();

  final List<UserModel> _users = [];
  final List<ChatRoomModel> _rooms = [];
  final Map<String, List<MessageModel>> _messagesByRoom = {};

  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  UserModel? get currentUser => _currentUser;
  List<UserModel> get allUsers => List.unmodifiable(_users);

  void _initSeedData() {
    final now = DateTime.now();

    // 1. Seed Demo Users
    final demoUser = UserModel(
      uid: 'usr_demo',
      name: 'Demo User',
      email: 'demo@chatflow.com',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      isOnline: true,
      lastSeen: now,
      createdAt: now.subtract(const Duration(days: 30)),
    );

    final alice = UserModel(
      uid: 'usr_alice',
      name: 'Alice Smith',
      email: 'alice@chatflow.com',
      photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      isOnline: true,
      lastSeen: now,
      createdAt: now.subtract(const Duration(days: 20)),
    );

    final bob = UserModel(
      uid: 'usr_bob',
      name: 'Bob Johnson',
      email: 'bob@chatflow.com',
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      isOnline: false,
      lastSeen: now.subtract(const Duration(minutes: 15)),
      createdAt: now.subtract(const Duration(days: 15)),
    );

    _users.addAll([demoUser, alice, bob]);

    // 2. Seed 1-to-1 Room (Alice & Demo User)
    final directRoomId = ChatRoomModel.getDeterministicRoomId(alice.uid, demoUser.uid);
    final directRoom = ChatRoomModel(
      id: directRoomId,
      members: [alice.uid, demoUser.uid],
      memberNames: {
        alice.uid: alice.name,
        demoUser.uid: demoUser.name,
      },
      lastMessage: 'Awesome! Can you send me the latest UI update?',
      lastMessageTime: now.subtract(const Duration(minutes: 2)),
      lastSenderId: alice.uid,
      isGroup: false,
      unreadCounts: {demoUser.uid: 1, alice.uid: 0},
      typing: {},
    );

    // 3. Seed Group Room ("Flutter Developers")
    final groupRoom = ChatRoomModel(
      id: 'room_flutter_devs',
      members: [demoUser.uid, alice.uid, bob.uid],
      memberNames: {
        demoUser.uid: demoUser.name,
        alice.uid: alice.name,
        bob.uid: bob.name,
      },
      groupName: 'Flutter Developers',
      groupPhotoUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=150',
      isGroup: true,
      createdBy: alice.uid,
      createdAt: now.subtract(const Duration(days: 5)),
      lastMessage: 'Welcome to the ChatFlow Flutter group! 🚀',
      lastMessageTime: now.subtract(const Duration(hours: 1)),
      lastSenderId: alice.uid,
      unreadCounts: {demoUser.uid: 0, alice.uid: 0, bob.uid: 0},
      typing: {},
    );

    _rooms.addAll([directRoom, groupRoom]);

    // 4. Seed Messages for Direct Room
    _messagesByRoom[directRoomId] = [
      MessageModel(
        id: 'msg_3',
        senderId: alice.uid,
        senderName: alice.name,
        text: 'Awesome! Can you send me the latest UI update?',
        timestamp: now.subtract(const Duration(minutes: 2)),
        status: AppConstants.statusSent,
        isRead: false,
      ),
      MessageModel(
        id: 'msg_2',
        senderId: demoUser.uid,
        senderName: demoUser.name,
        text: 'Hey Alice! The real-time messaging and dark mode are working smoothly.',
        timestamp: now.subtract(const Duration(minutes: 5)),
        status: AppConstants.statusRead,
        isRead: true,
      ),
      MessageModel(
        id: 'msg_1',
        senderId: alice.uid,
        senderName: alice.name,
        text: 'Hello there! Welcome to ChatFlow 👋',
        timestamp: now.subtract(const Duration(minutes: 10)),
        status: AppConstants.statusRead,
        isRead: true,
      ),
    ];

    // 5. Seed Messages for Group
    _messagesByRoom[groupRoom.id] = [
      MessageModel(
        id: 'grp_msg_1',
        senderId: alice.uid,
        senderName: alice.name,
        text: 'Welcome to the ChatFlow Flutter group! 🚀',
        timestamp: now.subtract(const Duration(hours: 1)),
        status: AppConstants.statusSent,
        isRead: true,
      ),
    ];
  }

  UserModel signIn(String email, String password) {
    final trimmed = email.trim().toLowerCase();
    final matched = _users.firstWhere(
      (u) => u.email.toLowerCase() == trimmed,
      orElse: () {
        // If not pre-seeded, dynamically create user in demo mode
        final newUser = UserModel(
          uid: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          name: trimmed.split('@').first,
          email: trimmed,
          isOnline: true,
          lastSeen: DateTime.now(),
          createdAt: DateTime.now(),
        );
        _users.add(newUser);
        return newUser;
      },
    );

    _currentUser = matched.copyWith(isOnline: true);
    _authStateController.add(_currentUser);
    _emitRooms();
    return _currentUser!;
  }

  UserModel signUp(String name, String email, String password) {
    final newUser = UserModel(
      uid: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim().toLowerCase(),
      isOnline: true,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
    );
    _users.add(newUser);
    _currentUser = newUser;
    _authStateController.add(_currentUser);
    _emitRooms();
    return newUser;
  }

  void signOut() {
    _currentUser = null;
    _authStateController.add(null);
  }

  Stream<List<ChatRoomModel>> streamRooms(String userId) {
    // Return stream emitting user's rooms
    Timer.run(() => _emitRooms());
    return _roomsController.stream;
  }

  void _emitRooms() {
    if (_roomsController.isClosed) return;
    final uid = _currentUser?.uid;
    if (uid == null) {
      _roomsController.add([]);
      return;
    }
    final userRooms = _rooms.where((r) => r.members.contains(uid)).toList()
      ..sort((a, b) => (b.lastMessageTime ?? DateTime.now())
          .compareTo(a.lastMessageTime ?? DateTime.now()));
    _roomsController.add(userRooms);
  }

  Stream<List<MessageModel>> streamMessages(String roomId) {
    if (!_messageControllers.containsKey(roomId)) {
      _messageControllers[roomId] = StreamController<List<MessageModel>>.broadcast();
    }
    final controller = _messageControllers[roomId]!;
    Timer.run(() {
      controller.add(List.from(_messagesByRoom[roomId] ?? []));
    });
    return controller.stream;
  }

  Stream<ChatRoomModel?> streamRoom(String roomId) {
    final controller = StreamController<ChatRoomModel?>.broadcast();
    Timer.run(() {
      final room = _rooms.firstWhere(
        (r) => r.id == roomId,
        orElse: () => ChatRoomModel(id: roomId, members: []),
      );
      controller.add(room);
    });
    return controller.stream;
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
    String? imageUrl,
    required List<String> memberIds,
  }) async {
    final now = DateTime.now();
    final newMsg = MessageModel(
      id: 'msg_${now.millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      text: text.trim(),
      imageUrl: imageUrl,
      timestamp: now,
      status: AppConstants.statusSent,
      isRead: false,
      readBy: [senderId],
    );

    if (!_messagesByRoom.containsKey(roomId)) {
      _messagesByRoom[roomId] = [];
    }
    _messagesByRoom[roomId]!.insert(0, newMsg);

    // Update room metadata
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      final unread = Map<String, int>.from(room.unreadCounts);
      for (final m in memberIds) {
        if (m != senderId) {
          unread[m] = (unread[m] ?? 0) + 1;
        }
      }
      _rooms[roomIndex] = room.copyWith(
        lastMessage: imageUrl != null && text.trim().isEmpty ? '📷 Photo' : text.trim(),
        lastMessageTime: now,
        lastSenderId: senderId,
        unreadCounts: unread,
      );
    }

    if (_messageControllers.containsKey(roomId)) {
      _messageControllers[roomId]!.add(List.from(_messagesByRoom[roomId]!));
    }
    _emitRooms();
  }

  Future<void> markMessagesAsRead({
    required String roomId,
    required String currentUserId,
  }) async {
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      final unread = Map<String, int>.from(room.unreadCounts);
      unread[currentUserId] = 0;
      _rooms[roomIndex] = room.copyWith(unreadCounts: unread);
    }

    final msgs = _messagesByRoom[roomId];
    if (msgs != null) {
      for (int i = 0; i < msgs.length; i++) {
        if (msgs[i].senderId != currentUserId && !msgs[i].isRead) {
          msgs[i] = msgs[i].copyWith(isRead: true, status: AppConstants.statusRead);
        }
      }
      if (_messageControllers.containsKey(roomId)) {
        _messageControllers[roomId]!.add(List.from(msgs));
      }
    }
    _emitRooms();
  }

  Future<ChatRoomModel> getOrCreateRoom({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
  }) async {
    final roomId = ChatRoomModel.getDeterministicRoomId(currentUserId, otherUserId);
    final existing = _rooms.where((r) => r.id == roomId);
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final newRoom = ChatRoomModel(
      id: roomId,
      members: [currentUserId, otherUserId],
      memberNames: {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      isGroup: false,
      createdAt: DateTime.now(),
      unreadCounts: {currentUserId: 0, otherUserId: 0},
      typing: {},
    );
    _rooms.insert(0, newRoom);
    _emitRooms();
    return newRoom;
  }

  Future<ChatRoomModel> createGroup({
    required String groupName,
    String? groupPhotoUrl,
    required List<String> memberIds,
    required Map<String, String> memberNames,
    required String createdBy,
  }) async {
    final newRoom = ChatRoomModel(
      id: 'group_${DateTime.now().millisecondsSinceEpoch}',
      members: memberIds,
      groupName: groupName,
      groupPhotoUrl: groupPhotoUrl,
      isGroup: true,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      lastMessage: 'Group created',
      lastMessageTime: DateTime.now(),
      unreadCounts: {for (final m in memberIds) m: 0},
      memberNames: memberNames,
      typing: {},
    );
    _rooms.insert(0, newRoom);
    _emitRooms();
    return newRoom;
  }
}
