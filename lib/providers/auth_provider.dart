import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/presence_service.dart';
import '../services/storage_service.dart';

/// Provider managing authentication state, active user profile, and app theme
class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final PresenceService _presenceService;
  final NotificationService _notificationService;
  final StorageService _storageService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userProfileSubscription;

  AuthProvider({
    AuthService? authService,
    PresenceService? presenceService,
    NotificationService? notificationService,
    StorageService? storageService,
  })  : _authService = authService ?? AuthService(),
        _presenceService = presenceService ?? PresenceService(),
        _notificationService = notificationService ?? NotificationService(),
        _storageService = storageService ?? StorageService() {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Initialize auth listeners and load preferences
  void _init() {
    _loadThemePreference();
    _authSubscription = _authService.authStateChanges.listen((user) async {
      if (user != null) {
        _presenceService.initialize(user.uid);
        _notificationService.initialize(user.uid);

        // Listen for live updates to the current user's profile
        _userProfileSubscription?.cancel();
        _userProfileSubscription = _authService.streamUserProfile(user.uid).listen((profile) {
          _currentUser = profile ?? UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            isOnline: true,
          );
          notifyListeners();
        });
      } else {
        _presenceService.stop();
        _userProfileSubscription?.cancel();
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  /// Sign In with Email & Password
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Register new user with full name, email, and password
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.signUpWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Send password reset link
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Update Profile Name and/or Avatar
  Future<bool> updateProfile({String? name, XFile? photoFile}) async {
    _setLoading(true);
    _clearError();
    try {
      final uid = _currentUser?.uid;
      if (uid == null) throw Exception('No user logged in.');

      String? photoUrl;
      if (photoFile != null) {
        photoUrl = await _storageService.uploadProfileImage(
          uid: uid,
          file: photoFile,
        );
      }

      await _authService.updateProfile(name: name, photoUrl: photoUrl);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    final uid = _currentUser?.uid;
    if (uid != null) {
      await _notificationService.clearToken(uid);
    }
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Theme switching
  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('theme_mode');
      if (mode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (mode == 'light') {
        _themeMode = ThemeMode.light;
      }
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userProfileSubscription?.cancel();
    super.dispose();
  }
}
