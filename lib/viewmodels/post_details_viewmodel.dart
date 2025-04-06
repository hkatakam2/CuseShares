import 'package:flutter/foundation.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart';
import 'package:cuse_food_share_app/models/food_post.dart'; // Import FoodPost

enum PostDetailsStatus { idle, updating, success, error }


class PostDetailsViewModel with ChangeNotifier {
    final PostRepository _postRepository;
    FoodPost post; // Hold the specific post

    PostDetailsStatus _status = PostDetailsStatus.idle;
    String? _errorMessage;

    PostDetailsViewModel({required PostRepository postRepository, required this.post})
        : _postRepository = postRepository;

    // Getters
    PostDetailsStatus get status => _status;
    String? get errorMessage => _errorMessage;


    // Mark post as finished
    Future<void> markAsFinished() async {
        if (!post.isAvailable) return; // Already finished

        _status = PostDetailsStatus.updating;
        _errorMessage = null;
        notifyListeners();

        try {
            await _postRepository.markPostAsFinished(post.id);
            post.isAvailable = false; // Update local state
            _status = PostDetailsStatus.success;
        } catch (e) {
            _status = PostDetailsStatus.error;
            _errorMessage = "Failed to update status: ${e.toString()}";
        } finally {
            notifyListeners();
        }
    }

     // Reset status after operation
    void resetStatus() {
      if (_status == PostDetailsStatus.success || _status == PostDetailsStatus.error) {
          _status = PostDetailsStatus.idle;
          _errorMessage = null;
          notifyListeners();
      }
    }

    // Optional: Add markAsAvailable again if needed
    // Future<void> markAsAvailable() async { ... }
}
