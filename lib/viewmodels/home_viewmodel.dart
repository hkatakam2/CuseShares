import 'package:flutter/foundation.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart';

class HomeViewModel with ChangeNotifier {
  final PostRepository _postRepository;

  HomeViewModel({required PostRepository postRepository}) : _postRepository = postRepository;

  // Stream of available food posts
  Stream<List<FoodPost>> get availablePosts => _postRepository.getAvailableFoodPosts();

  // Potential future additions:
  // - Search/filter logic
  // - Refresh mechanism (though stream handles updates)
}