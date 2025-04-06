import 'dart:async'; // For StreamSubscription
import 'package:flutter/foundation.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/models/chat_message.dart';

enum PostDetailsStatus { idle, updating, sendingMessage, success, error }

class PostDetailsViewModel with ChangeNotifier {
    final PostRepository _postRepository;
    FoodPost post; // Hold the specific post

    PostDetailsStatus _status = PostDetailsStatus.idle;
    String? _errorMessage;

    // Chat state
    List<ChatMessage> _messages = [];
    StreamSubscription? _messageSubscription; // To manage the stream listener

    PostDetailsViewModel({required PostRepository postRepository, required this.post})
        : _postRepository = postRepository {
            _listenToMessages(); // Start listening to chat messages on init
        }

    // Getters
    PostDetailsStatus get status => _status;
    String? get errorMessage => _errorMessage;
    List<ChatMessage> get messages => _messages;

    // --- Post Status Update ---
    Future<void> markAsFinished() async {
        if (!post.isAvailable) return;
        _updateStatus(PostDetailsStatus.updating);
        try {
            await _postRepository.markPostAsFinished(post.id);
            post.isAvailable = false; // Update local state
            _status = PostDetailsStatus.success;
        } catch (e) {
            _setError("Failed to update status: ${e.toString()}");
        } finally {
            notifyListeners();
        }
    }

     Future<void> markAsAvailable() async {
        if (post.isAvailable) return;
        _updateStatus(PostDetailsStatus.updating);
        try {
            await _postRepository.markPostAsAvailable(post.id);
            post.isAvailable = true; // Update local state
            _status = PostDetailsStatus.success;
        } catch (e) {
            _setError("Failed to update status: ${e.toString()}");
        } finally {
            notifyListeners();
        }
    }

    // --- Chat Functionality ---
    void _listenToMessages() {
        _messageSubscription?.cancel(); // Cancel previous subscription if any
        _messageSubscription = _postRepository.getChatMessagesStream(post.id).listen(
            (newMessages) {
                _messages = newMessages;
                notifyListeners(); // Update UI when messages change
            },
            onError: (error) {
                print("Error listening to messages: $error");
                _setError("Could not load messages.");
            }
        );
    }

    Future<bool> sendChatMessage(String text) async {
        if (text.trim().isEmpty) {
            _setError("Message cannot be empty.");
            return false;
        }
        _updateStatus(PostDetailsStatus.sendingMessage);
        try {
            await _postRepository.addChatMessage(postId: post.id, text: text);
            // Don't set success status here, the stream listener will update the list
             _updateStatus(PostDetailsStatus.idle); // Reset status after sending attempt
             return true;
        } catch (e) {
            _setError("Failed to send message: ${e.toString()}");
            return false;
        }
    }

    // --- Helpers ---
     void _updateStatus(PostDetailsStatus newStatus) {
        _status = newStatus;
        _errorMessage = null; // Clear error on status change
        notifyListeners();
    }

    void _setError(String message) {
        _status = PostDetailsStatus.error;
        _errorMessage = message;
        notifyListeners();
    }

     // Reset status after operation
    void resetStatus() {
      if (_status == PostDetailsStatus.success || _status == PostDetailsStatus.error) {
          _updateStatus(PostDetailsStatus.idle);
      }
    }

    // Clean up listener when ViewModel is disposed
    @override
    void dispose() {
        _messageSubscription?.cancel();
        super.dispose();
    }
}
