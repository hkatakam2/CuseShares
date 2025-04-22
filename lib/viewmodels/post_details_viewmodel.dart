import 'dart:async'; // For StreamSubscription
import 'package:flutter/foundation.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/models/chat_message.dart';

enum PostDetailsStatus { idle, updating, sendingMessage, success, error }

class PostDetailsViewModel with ChangeNotifier {
    final PostRepository _postRepository;
    FoodPost post;

    PostDetailsStatus _status = PostDetailsStatus.idle;
    String? _errorMessage;

    List<ChatMessage> _messages = [];
    StreamSubscription? _messageSubscription;

    PostDetailsViewModel({required PostRepository postRepository, required this.post})
        : _postRepository = postRepository {
            _listenToMessages();
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
            post.isAvailable = false;
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
            post.isAvailable = true;
            _status = PostDetailsStatus.success;
        } catch (e) {
            _setError("Failed to update status: ${e.toString()}");
        } finally {
            notifyListeners();
        }
    }

    // --- Chat Functionality ---
    void _listenToMessages() {
        _messageSubscription?.cancel();
        _messageSubscription = _postRepository.getChatMessagesStream(post.id).listen(
            (newMessages) {
                _messages = newMessages;
                notifyListeners();
            },
            onError: (error) {
                print("Error listening to messages: $error");
                _setError("Could not load messages.");
            }
        );
    }

    Future<bool> sendChatMessage(String text) async {
        if (text.trim().isEmpty) {
            // Optionally handle this in UI instead of error state
            // _setError("Message cannot be empty.");
            return false;
        }
        _updateStatus(PostDetailsStatus.sendingMessage);
        try {
            await _postRepository.addChatMessage(postId: post.id, text: text);
             _updateStatus(PostDetailsStatus.idle); // Reset status after attempt
             return true;
        } catch (e) {
            _setError("Failed to send message: ${e.toString()}");
            return false;
        }
    }

    // --- Helpers ---
     void _updateStatus(PostDetailsStatus newStatus) {
        _status = newStatus;
        _errorMessage = null;
        notifyListeners();
    }

    void _setError(String message) {
        _status = PostDetailsStatus.error;
        _errorMessage = message;
        notifyListeners();
    }

    void resetStatus() {
      if (_status == PostDetailsStatus.success || _status == PostDetailsStatus.error) {
          _updateStatus(PostDetailsStatus.idle);
      }
    }

    @override
    void dispose() {
        _messageSubscription?.cancel();
        super.dispose();
    }
}