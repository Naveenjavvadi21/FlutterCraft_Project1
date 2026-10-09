import 'package:flutter/material.dart';

/// App-wide constants for ChatFlow
class AppConstants {
  static const String appName = 'ChatFlow';
  static const String appSubtitle = 'Real-Time Firebase Chat';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String chatRoomsCollection = 'chatRooms';
  static const String messagesCollection = 'messages';

  // Firebase Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String chatImagesPath = 'chat_images';

  // Message Types & Status
  static const String statusSending = 'sending';
  static const String statusSent = 'sent';
  static const String statusDelivered = 'delivered';
  static const String statusRead = 'read';

  // Typing debounce duration
  static const Duration typingDebounceDuration = Duration(milliseconds: 1500);
  static const Duration typingTimeoutDuration = Duration(seconds: 4);

  // Pagination
  static const int initialMessageLimit = 50;
  static const int paginationMessageLimit = 25;

  // Design Colors
  static const Color primaryColor = Color(0xFF0066FF); // Electric Blue
  static const Color primaryDark = Color(0xFF0052CC);
  static const Color secondaryColor = Color(0xFF00D2B4); // Teal accent
  static const Color accentColor = Color(0xFF6C5CE7); // Modern Purple
  static const Color onlineColor = Color(0xFF10B981); // Emerald Green
  static const Color offlineColor = Color(0xFF94A3B8); // Cool Gray
  static const Color errorColor = Color(0xFFEF4444); // Crimson
  static const Color readStatusColor = Color(0xFF00D2B4); // Cyan/Teal checkmark
}
