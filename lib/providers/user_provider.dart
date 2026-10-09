import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../models/user_model.dart';
import '../services/demo_data_service.dart';
import '../utils/constants.dart';

/// Provider handling user searching, contact directory, and member selection
class UserProvider with ChangeNotifier {
  FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore => _firestoreInstance ??= FirebaseFirestore.instance;

  List<UserModel> _searchResults = [];
  List<UserModel> _allUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Cache for quick user info lookup by UID
  final Map<String, UserModel> _userCache = {};

  UserProvider({FirebaseFirestore? firestore})
      : _firestoreInstance = firestore;

  List<UserModel> get searchResults => _searchResults;
  List<UserModel> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all users except the current user (e.g. for contacts or new chat screen)
  Future<void> fetchAllUsers(String currentUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (!DefaultFirebaseOptions.isConfigured) {
      _allUsers = DemoDataService.instance.allUsers
          .where((u) => u.uid != currentUserId)
          .toList();
      for (final user in _allUsers) {
        _userCache[user.uid] = user;
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .limit(100)
          .get();

      _allUsers = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), documentId: doc.id))
          .where((u) => u.uid != currentUserId)
          .toList();

      for (final user in _allUsers) {
        _userCache[user.uid] = user;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load users: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search users by name or email query (case-insensitive)
  Future<void> searchUsers(String query, String currentUserId) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (!DefaultFirebaseOptions.isConfigured) {
      _searchResults = DemoDataService.instance.allUsers
          .where((u) =>
              u.uid != currentUserId &&
              (u.name.toLowerCase().contains(trimmed) ||
                  u.email.toLowerCase().contains(trimmed)))
          .toList();
      for (final user in _searchResults) {
        _userCache[user.uid] = user;
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Query users collection
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .limit(50)
          .get();

      final matches = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), documentId: doc.id))
          .where((u) {
        if (u.uid == currentUserId) return false;
        final nameMatch = u.name.toLowerCase().contains(trimmed);
        final emailMatch = u.email.toLowerCase().contains(trimmed);
        return nameMatch || emailMatch;
      }).toList();

      _searchResults = matches;

      for (final user in matches) {
        _userCache[user.uid] = user;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Search failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get cached user or fetch from Firestore if missing
  Future<UserModel?> getUser(String uid) async {
    if (_userCache.containsKey(uid)) {
      return _userCache[uid];
    }

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromMap(doc.data()!, documentId: doc.id);
        _userCache[uid] = user;
        return user;
      }
    } catch (_) {}
    return null;
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}
