import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import '../firebase_options.dart';
import '../utils/constants.dart';

/// Service managing user online presence & last-seen status
class PresenceService with WidgetsBindingObserver {
  FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore => _firestoreInstance ??= FirebaseFirestore.instance;

  String? _currentUserId;
  bool _isInitialized = false;

  PresenceService({FirebaseFirestore? firestore})
      : _firestoreInstance = firestore;

  /// Initialize presence tracker with the current authenticated user
  void initialize(String? userId) {
    if (userId == null) {
      stop();
      return;
    }

    _currentUserId = userId;
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
    }

    // Set online on initialization
    setOnline(true);
  }

  /// Stop tracking presence (e.g. on user logout)
  void stop() {
    if (_currentUserId != null) {
      setOnline(false);
      _currentUserId = null;
    }
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }

  /// Updates online status and last-seen timestamp in Firestore
  Future<void> setOnline(bool isOnline) async {
    if (!DefaultFirebaseOptions.isConfigured) return;
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Ignore network errors in background
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUserId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        setOnline(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        setOnline(false);
        break;
    }
  }

  /// Streams presence data for a specific user
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamPresence(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots();
  }
}
