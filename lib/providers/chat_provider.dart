import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

/// Provider handling message dispatch, image uploads, typing status debounce, and chat state
class ChatProvider with ChangeNotifier {
  final ChatService _chatService;
  final StorageService _storageService;

  bool _isSending = false;
  bool _isUploadingImage = false;
  String? _errorMessage;

  // Typing debounce timer
  Timer? _typingTimer;
  bool _isCurrentlyTyping = false;

  ChatProvider({
    ChatService? chatService,
    StorageService? storageService,
  })  : _chatService = chatService ?? ChatService(),
        _storageService = storageService ?? StorageService();

  bool get isSending => _isSending;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorMessage => _errorMessage;

  /// Send text message
  Future<bool> sendTextMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
    required List<String> memberIds,
  }) async {
    if (text.trim().isEmpty) return false;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cancel typing status immediately when message is dispatched
      resetTyping(roomId, senderId);

      await _chatService.sendMessage(
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        memberIds: memberIds,
      );

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload image and send image message
  Future<bool> sendImageMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required XFile imageFile,
    required List<String> memberIds,
    String caption = '',
  }) async {
    _isUploadingImage = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload to Firebase Storage
      final imageUrl = await _storageService.uploadChatImage(
        roomId: roomId,
        file: imageFile,
      );

      // 2. Post message with imageUrl
      await _chatService.sendMessage(
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        text: caption,
        imageUrl: imageUrl,
        memberIds: memberIds,
      );

      _isUploadingImage = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to upload and send image: ${e.toString()}';
      _isUploadingImage = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark incoming messages as read
  Future<void> markRoomAsRead({
    required String roomId,
    required String currentUserId,
  }) async {
    await _chatService.markMessagesAsRead(
      roomId: roomId,
      currentUserId: currentUserId,
    );
  }

  /// Handles debounced typing status updates to Firestore
  void onUserTyping({
    required String roomId,
    required String userId,
    required String currentInput,
  }) {
    if (currentInput.trim().isEmpty) {
      resetTyping(roomId, userId);
      return;
    }

    if (!_isCurrentlyTyping) {
      _isCurrentlyTyping = true;
      _chatService.setTypingStatus(
        roomId: roomId,
        userId: userId,
        isTyping: true,
      );
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(AppConstants.typingTimeoutDuration, () {
      resetTyping(roomId, userId);
    });
  }

  /// Explicitly resets typing indicator to false
  void resetTyping(String roomId, String userId) {
    if (_isCurrentlyTyping) {
      _isCurrentlyTyping = false;
      _chatService.setTypingStatus(
        roomId: roomId,
        userId: userId,
        isTyping: false,
      );
    }
    _typingTimer?.cancel();
  }

  /// Stream of user chat rooms
  Stream<List<ChatRoomModel>> getUserChatRooms(String userId) {
    return _chatService.streamUserChatRooms(userId);
  }

  /// Stream of messages in a room
  Stream<List<MessageModel>> getRoomMessages(String roomId, {int limit = AppConstants.initialMessageLimit}) {
    return _chatService.streamMessages(roomId, limit: limit);
  }

  /// Stream active room details (for live typing indicators)
  Stream<ChatRoomModel?> getRoomDetails(String roomId) {
    return _chatService.streamRoom(roomId);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }
}
