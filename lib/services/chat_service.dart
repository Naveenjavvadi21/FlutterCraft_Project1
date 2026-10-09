import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';
import 'demo_data_service.dart';

/// Service managing real-time chat rooms, messaging, pagination, and read receipts
class ChatService {
  FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore => _firestoreInstance ??= FirebaseFirestore.instance;

  ChatService({FirebaseFirestore? firestore})
      : _firestoreInstance = firestore;

  /// Retrieves or creates a deterministic direct chat room between two users
  Future<ChatRoomModel> getOrCreateDirectChatRoom({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
  }) async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return DemoDataService.instance.getOrCreateRoom(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
      );
    }

    final roomId = ChatRoomModel.getDeterministicRoomId(currentUserId, otherUserId);
    final roomDocRef = _firestore.collection(AppConstants.chatRoomsCollection).doc(roomId);

    final snapshot = await roomDocRef.get();
    if (snapshot.exists && snapshot.data() != null) {
      return ChatRoomModel.fromMap(snapshot.data()!, documentId: snapshot.id);
    }

    final newRoom = ChatRoomModel(
      id: roomId,
      members: [currentUserId, otherUserId],
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      isGroup: false,
      createdAt: DateTime.now(),
      unreadCounts: {currentUserId: 0, otherUserId: 0},
      memberNames: {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      typing: {currentUserId: false, otherUserId: false},
    );

    await roomDocRef.set(newRoom.toMap(useServerTimestampForCreation: true));
    return newRoom;
  }

  /// Creates a new group conversation
  Future<ChatRoomModel> createGroupChatRoom({
    required String groupName,
    String? groupPhotoUrl,
    required List<String> memberIds,
    required Map<String, String> memberNames,
    required String createdBy,
  }) async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return DemoDataService.instance.createGroup(
        groupName: groupName,
        groupPhotoUrl: groupPhotoUrl,
        memberIds: memberIds,
        memberNames: memberNames,
        createdBy: createdBy,
      );
    }

    final roomDocRef = _firestore.collection(AppConstants.chatRoomsCollection).doc();

    final unreadMap = <String, int>{};
    for (final memberId in memberIds) {
      unreadMap[memberId] = 0;
    }

    final newGroup = ChatRoomModel(
      id: roomDocRef.id,
      members: memberIds,
      groupName: groupName.trim(),
      groupPhotoUrl: groupPhotoUrl,
      isGroup: true,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      lastMessage: 'Group created',
      lastMessageTime: DateTime.now(),
      unreadCounts: unreadMap,
      memberNames: memberNames,
      typing: {},
    );

    await roomDocRef.set(newGroup.toMap(useServerTimestampForCreation: true));
    return newGroup;
  }

  /// Stream user's conversations ordered by last message time
  Stream<List<ChatRoomModel>> streamUserChatRooms(String userId) {
    if (!DefaultFirebaseOptions.isConfigured) {
      return DemoDataService.instance.streamRooms(userId);
    }
    return _firestore
        .collection(AppConstants.chatRoomsCollection)
        .where('members', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatRoomModel.fromMap(doc.data(), documentId: doc.id);
      }).toList();
    });
  }

  /// Stream a single chat room by ID (for live typing indicator and metadata updates)
  Stream<ChatRoomModel?> streamRoom(String roomId) {
    if (!DefaultFirebaseOptions.isConfigured) {
      return DemoDataService.instance.streamRoom(roomId);
    }
    return _firestore
        .collection(AppConstants.chatRoomsCollection)
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return ChatRoomModel.fromMap(snapshot.data()!, documentId: snapshot.id);
    });
  }

  /// Stream real-time messages within a room, ordered latest first
  Stream<List<MessageModel>> streamMessages(String roomId, {int limit = AppConstants.initialMessageLimit}) {
    if (!DefaultFirebaseOptions.isConfigured) {
      return DemoDataService.instance.streamMessages(roomId);
    }
    return _firestore
        .collection(AppConstants.chatRoomsCollection)
        .doc(roomId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), documentId: doc.id);
      }).toList();
    });
  }

  /// Paginate older messages using startAfterDocument
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchOlderMessageSnapshots({
    required String roomId,
    required DocumentSnapshot lastVisibleDoc,
    int limit = AppConstants.paginationMessageLimit,
  }) async {
    final query = await _firestore
        .collection(AppConstants.chatRoomsCollection)
        .doc(roomId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastVisibleDoc)
        .limit(limit)
        .get();

    return query.docs;
  }

  /// Sends a text or image message and updates room meta & unread counts
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
    String? imageUrl,
    required List<String> memberIds,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty && (imageUrl == null || imageUrl.trim().isEmpty)) {
      throw Exception('Cannot send an empty message.');
    }

    if (!DefaultFirebaseOptions.isConfigured) {
      await DemoDataService.instance.sendMessage(
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        text: trimmedText,
        imageUrl: imageUrl,
        memberIds: memberIds,
      );
      return;
    }

    final roomDocRef = _firestore.collection(AppConstants.chatRoomsCollection).doc(roomId);
    final messagesColRef = roomDocRef.collection(AppConstants.messagesCollection);
    final newMessageRef = messagesColRef.doc();

    final messageData = {
      'senderId': senderId,
      'senderName': senderName,
      'text': trimmedText,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'status': AppConstants.statusSent,
      'isRead': false,
      'readBy': [senderId],
    };

    final batch = _firestore.batch();

    // 1. Write the message
    batch.set(newMessageRef, messageData);

    // 2. Prepare room updates
    final previewText = imageUrl != null && trimmedText.isEmpty ? '📷 Photo' : trimmedText;
    final Map<String, dynamic> roomUpdates = {
      'lastMessage': previewText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'typing.$senderId': false, // clear typing indicator
    };

    // Increment unread counts for all members except sender
    for (final member in memberIds) {
      if (member != senderId) {
        roomUpdates['unreadCounts.$member'] = FieldValue.increment(1);
      }
    }

    batch.update(roomDocRef, roomUpdates);

    // Commit atomically
    await batch.commit();
  }

  /// Marks all incoming unread messages as read and resets user's unread count
  Future<void> markMessagesAsRead({
    required String roomId,
    required String currentUserId,
  }) async {
    if (!DefaultFirebaseOptions.isConfigured) {
      await DemoDataService.instance.markMessagesAsRead(
        roomId: roomId,
        currentUserId: currentUserId,
      );
      return;
    }
    try {
      final roomRef = _firestore.collection(AppConstants.chatRoomsCollection).doc(roomId);

      // Reset unread count for current user
      await roomRef.update({
        'unreadCounts.$currentUserId': 0,
      });

      // Find unread messages not sent by current user
      final unreadQuery = await roomRef
          .collection(AppConstants.messagesCollection)
          .where('isRead', isEqualTo: false)
          .limit(100)
          .get();

      if (unreadQuery.docs.isEmpty) return;

      final batch = _firestore.batch();
      var hasUpdates = false;

      for (final doc in unreadQuery.docs) {
        final data = doc.data();
        if (data['senderId'] != currentUserId) {
          batch.update(doc.reference, {
            'isRead': true,
            'status': AppConstants.statusRead,
            'readBy': FieldValue.arrayUnion([currentUserId]),
          });
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
      }
    } catch (_) {
      // Non-critical background operation
    }
  }

  /// Sets user typing indicator on the room document
  Future<void> setTypingStatus({
    required String roomId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.chatRoomsCollection)
          .doc(roomId)
          .update({
        'typing.$userId': isTyping,
      });
    } catch (_) {
      // Ignore background typing failures
    }
  }
}
