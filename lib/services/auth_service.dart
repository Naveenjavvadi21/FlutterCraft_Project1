import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'demo_data_service.dart';

/// Service handling Firebase Authentication & User Profile Sync
class AuthService {
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;

  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _firestoreInstance ??= FirebaseFirestore.instance;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _authInstance = auth,
        _firestoreInstance = firestore;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges {
    if (!DefaultFirebaseOptions.isConfigured) {
      return const Stream.empty();
    }
    return _auth.authStateChanges();
  }

  /// Current authenticated user (or null)
  User? get currentUser {
    if (!DefaultFirebaseOptions.isConfigured) return null;
    return _auth.currentUser;
  }

  /// Current authenticated user ID
  String? get currentUserId {
    if (!DefaultFirebaseOptions.isConfigured) {
      return DemoDataService.instance.currentUser?.uid;
    }
    return _auth.currentUser?.uid;
  }

  /// Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return DemoDataService.instance.signIn(email, password);
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User sign in returned empty profile.');
      }

      // Mark online in Firestore
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final profile = await getUserProfile(user.uid);
      return profile ??
          UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? email,
            photoUrl: user.photoURL,
            isOnline: true,
          );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Register a new account with email, password, and full name
  Future<UserModel> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return DemoDataService.instance.signUp(name, email, password);
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Registration succeeded but user is null.');
      }

      // Update auth profile display name
      await user.updateDisplayName(name.trim());

      final newUser = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        photoUrl: null,
        isOnline: true,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Create users/{uid} document in Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(newUser.toMap(useServerTimestampForCreation: true));

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Send password reset link to user email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  /// Sign out current user and set offline status
  Future<void> signOut() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      DemoDataService.instance.signOut();
      return;
    }
    try {
      final uid = currentUserId;
      if (uid != null) {
        await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await _auth.signOut();
    } catch (e) {
      // Even if firestore presence write fails, ensure auth signout proceeds
      await _auth.signOut();
    }
  }

  /// Fetch single user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    if (!DefaultFirebaseOptions.isConfigured) {
      final matches = DemoDataService.instance.allUsers.where((u) => u.uid == uid);
      return matches.isNotEmpty ? matches.first : null;
    }
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, documentId: doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Stream user profile for real-time changes
  Stream<UserModel?> streamUserProfile(String uid) {
    if (!DefaultFirebaseOptions.isConfigured) {
      return Stream.value(DemoDataService.instance.currentUser);
    }
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserModel.fromMap(snapshot.data()!, documentId: snapshot.id);
    });
  }

  /// Update user profile (name or photoUrl)
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('No user currently signed in');

    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
      await _auth.currentUser?.updateDisplayName(name.trim());
    }
    if (photoUrl != null) {
      updates['photoUrl'] = photoUrl;
      await _auth.currentUser?.updatePhotoURL(photoUrl);
    }

    if (updates.isNotEmpty) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(updates);
    }
  }

  /// Convert technical FirebaseAuthException codes to friendly human messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }
}
