import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../utils/constants.dart';

/// Service managing push notifications and foreground alerts via FCM
class NotificationService {
  FirebaseMessaging? _messagingInstance;
  FirebaseFirestore? _firestoreInstance;

  FirebaseMessaging get _messaging => _messagingInstance ??= FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => _firestoreInstance ??= FirebaseFirestore.instance;

  // Callback when a notification is tapped to navigate to a chat room
  static Function(String roomId)? onChatNotificationTap;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messagingInstance = messaging,
        _firestoreInstance = firestore;

  /// Initializes FCM listeners, permissions, and token sync
  Future<void> initialize(String? userId) async {
    if (!DefaultFirebaseOptions.isConfigured) return;
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          final token = await _messaging.getToken();
          if (token != null && userId != null) {
            await _updateUserToken(userId, token);
          }

          // Listen for token refreshes
          _messaging.onTokenRefresh.listen((newToken) {
            if (userId != null) {
              _updateUserToken(userId, newToken);
            }
          });

          // Handle app opened from background state
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            final roomId = message.data['roomId'];
            if (roomId != null && onChatNotificationTap != null) {
              onChatNotificationTap!(roomId.toString());
            }
          });

          // Check if app was opened from terminated state
          final initialMessage = await _messaging.getInitialMessage();
          if (initialMessage != null) {
            final roomId = initialMessage.data['roomId'];
            if (roomId != null && onChatNotificationTap != null) {
              Timer(const Duration(milliseconds: 800), () {
                onChatNotificationTap!(roomId.toString());
              });
            }
          }
        }
      } catch (_) {
        // FCM might not be configured or supported on this environment
      }
    }
  }

  /// Updates current user's FCM token in Firestore
  Future<void> _updateUserToken(String userId, String token) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Clears token when signing out
  Future<void> clearToken(String userId) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (_) {}
  }
}
