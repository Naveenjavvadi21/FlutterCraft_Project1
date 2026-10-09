import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Message representation in ChatFlow
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final DateTime? timestamp;
  final String status; // 'sending', 'sent', 'delivered', 'read'
  final bool isRead;
  final List<String> readBy;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    this.timestamp,
    this.status = AppConstants.statusSent,
    this.isRead = false,
    this.readBy = const [],
  });

  /// True if message contains an image
  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  /// Factory constructor to parse Firestore map or document snapshot
  factory MessageModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rawReadBy = map['readBy'];
    List<String> readByList = [];
    if (rawReadBy is List) {
      readByList = rawReadBy.map((e) => e.toString()).toList();
    }

    final bool readFlag = map['isRead'] as bool? ?? false;
    final String msgStatus = map['status'] as String? ??
        (readFlag ? AppConstants.statusRead : AppConstants.statusSent);

    return MessageModel(
      id: documentId ?? map['id'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'User',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      timestamp: parseDateTime(map['timestamp']),
      status: msgStatus,
      isRead: readFlag,
      readBy: readByList,
    );
  }

  /// Convert model to a Firestore-compatible map
  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : (timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp()),
      'status': status,
      'isRead': isRead,
      'readBy': readBy,
    };
  }

  /// Create a copy with modified fields
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    String? status,
    bool? isRead,
    List<String>? readBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MessageModel(id: $id, sender: $senderName, text: $text, status: $status)';
  }
}
