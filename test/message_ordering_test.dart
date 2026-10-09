import 'package:chatflow/models/chat_room_model.dart';
import 'package:chatflow/models/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message Ordering & Room Logic Tests', () {
    test('Messages are ordered latest-first by timestamp', () {
      final t1 = DateTime(2026, 10, 2, 10, 0);
      final t2 = DateTime(2026, 10, 2, 10, 5);
      final t3 = DateTime(2026, 10, 2, 10, 15);

      final messages = [
        MessageModel(id: '1', senderId: 'u1', senderName: 'Alice', text: 'First', timestamp: t1),
        MessageModel(id: '3', senderId: 'u1', senderName: 'Alice', text: 'Third', timestamp: t3),
        MessageModel(id: '2', senderId: 'u2', senderName: 'Bob', text: 'Second', timestamp: t2),
      ];

      // Sort descending (as queried from Firestore: orderBy('timestamp', descending: true))
      messages.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

      expect(messages[0].id, '3');
      expect(messages[1].id, '2');
      expect(messages[2].id, '1');
    });

    test('Deterministic chat room ID is independent of caller order', () {
      const userAlpha = 'usr_abc_777';
      const userBeta = 'usr_xyz_888';

      final roomId1 = ChatRoomModel.getDeterministicRoomId(userAlpha, userBeta);
      final roomId2 = ChatRoomModel.getDeterministicRoomId(userBeta, userAlpha);

      expect(roomId1, roomId2);
      expect(roomId1, 'usr_abc_777_usr_xyz_888');
    });
  });
}
