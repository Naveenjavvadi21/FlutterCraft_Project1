import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../firebase_options.dart';
import '../utils/constants.dart';

/// Service for uploading media to Firebase Storage
class StorageService {
  FirebaseStorage? _storageInstance;
  FirebaseStorage get _storage => _storageInstance ??= FirebaseStorage.instance;
  final Uuid _uuid;

  StorageService({FirebaseStorage? storage})
      : _storageInstance = storage,
        _uuid = const Uuid();

  /// Uploads a chat image and returns its public download URL
  Future<String> uploadChatImage({
    required String roomId,
    required XFile file,
  }) async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return 'https://images.unsplash.com/photo-1579202673506-ca3ce28943ef?w=600';
    }

    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage
          .ref()
          .child(AppConstants.chatImagesPath)
          .child(roomId)
          .child(fileName);

      final bytes = await file.readAsBytes();
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'roomId': roomId,
        },
      );

      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload chat image: ${e.toString()}');
    }
  }

  /// Uploads a user's profile image and returns its download URL
  Future<String> uploadProfileImage({
    required String uid,
    required XFile file,
  }) async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';
    }

    try {
      final ref = _storage
          .ref()
          .child(AppConstants.profileImagesPath)
          .child(uid)
          .child('profile.jpg');

      final bytes = await file.readAsBytes();
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'updatedAt': DateTime.now().toIso8601String(),
          'uid': uid,
        },
      );

      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  /// Uploads a group avatar image and returns its download URL
  Future<String> uploadGroupImage({
    required String roomId,
    required XFile file,
  }) async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=150';
    }

    try {
      final fileName = 'group_avatar_${_uuid.v4().substring(0, 8)}.jpg';
      final ref = _storage
          .ref()
          .child(AppConstants.chatImagesPath)
          .child(roomId)
          .child(fileName);

      final bytes = await file.readAsBytes();
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final uploadTask = await ref.putData(bytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload group image: ${e.toString()}');
    }
  }
}
