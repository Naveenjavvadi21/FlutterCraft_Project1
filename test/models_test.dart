import 'package:chatflow/models/chat_room_model.dart';
import 'package:chatflow/models/message_model.dart';
import 'package:chatflow/models/user_model.dart';
import 'package:chatflow/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Models Serialization Tests', () {
    test('UserModel serialization and deserialization', () {
      final now = DateTime(2026, 10, 2, 12, 0);
      final user = UserModel(
        uid: 'user_123',
        name: 'Jane Doe',
        email: 'jane@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        isOnline: true,
        lastSeen: now,
        createdAt: now,
        fcmToken: 'fcm_sample_token',
      );

      final map = user.toMap();
      expect(map['uid'], 'user_123');
      expect(map['name'], 'Jane Doe');
      expect(map['email'], 'jane@example.com');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
      expect(map['isOnline'], true);
      expect(map['fcmToken'], 'fcm_sample_token');

      final fromMapUser = UserModel.fromMap({
        'uid': 'user_123',
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'photoUrl': 'https://example.com/photo.jpg',
        'isOnline': true,
        'lastSeen': now.millisecondsSinceEpoch,
        'createdAt': now.millisecondsSinceEpoch,
        'fcmToken': 'fcm_sample_token',
      }, documentId: 'user_123');

      expect(fromMapUser.uid, 'user_123');
      expect(fromMapUser.name, 'Jane Doe');
      expect(fromMapUser.isOnline, true);
      expect(fromMapUser.lastSeen, now);
    });

    test('MessageModel serialization and status', () {
      final now = DateTime(2026, 10, 2, 14, 30);
      final message = MessageModel(
        id: 'msg_001',
        senderId: 'user_1',
        senderName: 'Alice',
        text: 'Hello there!',
        imageUrl: null,
        timestamp: now,
        status: AppConstants.statusRead,
        isRead: true,
        readBy: ['user_1', 'user_2'],
      );

      expect(message.hasImage, isFalse);

      final fromMapMessage = MessageModel.fromMap({
        'senderId': 'user_1',
        'senderName': 'Alice',
        'text': 'Hello there!',
        'imageUrl': null,
        'timestamp': now.millisecondsSinceEpoch,
        'status': AppConstants.statusRead,
        'isRead': true,
        'readBy': ['user_1', 'user_2'],
      }, documentId: 'msg_001');

      expect(fromMapMessage.id, 'msg_001');
      expect(fromMapMessage.senderName, 'Alice');
      expect(fromMapMessage.isRead, isTrue);
      expect(fromMapMessage.status, AppConstants.statusRead);
      expect(fromMapMessage.readBy, contains('user_2'));
    });

    test('ChatRoomModel deterministic ID and unread counts', () {
      // Deterministic ID test: IDs should always be sorted
      final id1 = ChatRoomModel.getDeterministicRoomId('alice', 'bob');
      final id2 = ChatRoomModel.getDeterministicRoomId('bob', 'alice');
      expect(id1, 'alice_bob');
      expect(id2, 'alice_bob');
      expect(id1, id2);

      final room = ChatRoomModel(
        id: id1,
        members: ['alice', 'bob'],
        lastMessage: 'Hey Alice',
        isGroup: false,
        unreadCounts: {'alice': 2, 'bob': 0},
      );

      expect(room.getOtherUserId('alice'), 'bob');
      expect(room.getOtherUserId('bob'), 'alice');
      expect(room.getUnreadCount('alice'), 2);
      expect(room.getUnreadCount('bob'), 0);
    });
  });
}
