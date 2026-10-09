import 'package:cloud_firestore/cloud_firestore.dart';

/// Representation of a 1-to-1 or group chat room in ChatFlow
class ChatRoomModel {
  final String id;
  final List<String> members;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;
  final bool isGroup;
  final String? groupName;
  final String? groupPhotoUrl;
  final String? createdBy;
  final DateTime? createdAt;
  final Map<String, int> unreadCounts;
  final Map<String, String> memberNames;
  final Map<String, bool> typing;

  const ChatRoomModel({
    required this.id,
    required this.members,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastSenderId,
    this.isGroup = false,
    this.groupName,
    this.groupPhotoUrl,
    this.createdBy,
    this.createdAt,
    this.unreadCounts = const {},
    this.memberNames = const {},
    this.typing = const {},
  });

  /// Deterministic room ID generation for direct 1-to-1 chats:
  /// chatRooms/{sortedUserId1_sortedUserId2}
  static String getDeterministicRoomId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Gets the other user's ID in a direct (1-to-1) conversation
  String getOtherUserId(String currentUserId) {
    if (members.length < 2) return members.isNotEmpty ? members.first : '';
    return members.firstWhere(
      (m) => m != currentUserId,
      orElse: () => members.first,
    );
  }

  /// Unread messages count for a specific user
  int getUnreadCount(String currentUserId) {
    return unreadCounts[currentUserId] ?? 0;
  }

  /// Factory constructor to parse Firestore map or document snapshot
  factory ChatRoomModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rawMembers = map['members'];
    List<String> membersList = [];
    if (rawMembers is List) {
      membersList = rawMembers.map((e) => e.toString()).toList();
    }

    final rawUnread = map['unreadCounts'];
    Map<String, int> unreadMap = {};
    if (rawUnread is Map) {
      rawUnread.forEach((key, value) {
        if (value is int) {
          unreadMap[key.toString()] = value;
        } else if (value is num) {
          unreadMap[key.toString()] = value.toInt();
        }
      });
    }

    final rawNames = map['memberNames'];
    Map<String, String> namesMap = {};
    if (rawNames is Map) {
      rawNames.forEach((key, value) {
        namesMap[key.toString()] = value.toString();
      });
    }

    final rawTyping = map['typing'];
    Map<String, bool> typingMap = {};
    if (rawTyping is Map) {
      rawTyping.forEach((key, value) {
        typingMap[key.toString()] = value == true;
      });
    }

    return ChatRoomModel(
      id: documentId ?? map['id'] as String? ?? '',
      members: membersList,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime: parseDateTime(map['lastMessageTime']),
      lastSenderId: map['lastSenderId'] as String?,
      isGroup: map['isGroup'] as bool? ?? false,
      groupName: map['groupName'] as String?,
      groupPhotoUrl: map['groupPhotoUrl'] as String?,
      createdBy: map['createdBy'] as String?,
      createdAt: parseDateTime(map['createdAt']),
      unreadCounts: unreadMap,
      memberNames: namesMap,
      typing: typingMap,
    );
  }

  /// Convert model to a Firestore-compatible map
  Map<String, dynamic> toMap({bool useServerTimestampForCreation = false}) {
    return {
      'members': members,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : FieldValue.serverTimestamp(),
      if (lastSenderId != null) 'lastSenderId': lastSenderId,
      'isGroup': isGroup,
      if (groupName != null) 'groupName': groupName,
      if (groupPhotoUrl != null) 'groupPhotoUrl': groupPhotoUrl,
      if (createdBy != null) 'createdBy': createdBy,
      'createdAt': useServerTimestampForCreation
          ? FieldValue.serverTimestamp()
          : (createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp()),
      'unreadCounts': unreadCounts,
      'memberNames': memberNames,
      'typing': typing,
    };
  }

  /// Create a copy with modified fields
  ChatRoomModel copyWith({
    String? id,
    List<String>? members,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastSenderId,
    bool? isGroup,
    String? groupName,
    String? groupPhotoUrl,
    String? createdBy,
    DateTime? createdAt,
    Map<String, int>? unreadCounts,
    Map<String, String>? memberNames,
    Map<String, bool>? typing,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupPhotoUrl: groupPhotoUrl ?? this.groupPhotoUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      memberNames: memberNames ?? this.memberNames,
      typing: typing ?? this.typing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoomModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatRoomModel(id: $id, isGroup: $isGroup, lastMessage: $lastMessage)';
  }
}
