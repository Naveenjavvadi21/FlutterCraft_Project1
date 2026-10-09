import 'package:cloud_firestore/cloud_firestore.dart';

/// User representation in ChatFlow
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final String? fcmToken;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.fcmToken,
  });

  /// Factory constructor to parse Firestore map or document snapshot
  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return UserModel(
      uid: documentId ?? map['uid'] as String? ?? '',
      name: map['name'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: parseDateTime(map['lastSeen']),
      createdAt: parseDateTime(map['createdAt']),
      fcmToken: map['fcmToken'] as String?,
    );
  }

  /// Convert model to a Firestore-compatible map
  Map<String, dynamic> toMap({bool useServerTimestampForCreation = false}) {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null
          ? Timestamp.fromDate(lastSeen!)
          : FieldValue.serverTimestamp(),
      'createdAt': useServerTimestampForCreation
          ? FieldValue.serverTimestamp()
          : (createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp()),
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }

  /// Create a copy with modified fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, isOnline: $isOnline)';
  }
}
