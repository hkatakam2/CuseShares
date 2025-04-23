import 'package:flutter/foundation.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart';

class HomeViewModel with ChangeNotifier {
  final PostRepository _postRepository;

  HomeViewModel({required PostRepository postRepository}) : _postRepository = postRepository;

  // Stream of ALL food posts (renamed)
  Stream<List<FoodPost>> get allPosts => _postRepository.getAllFoodPostsStream();

}