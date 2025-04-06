import 'package:flutter/foundation.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart';
import 'package:cuse_food_share_app/models/app_user.dart'; // Need user info

class ProfileViewModel with ChangeNotifier {
  final PostRepository _postRepository;
  final AppUser _user; // The user whose profile this is

  ProfileViewModel({required PostRepository postRepository, required AppUser user})
      : _postRepository = postRepository,
        _user = user;

  // Get the current user's details
  AppUser get user => _user;

  // Stream of the user's created food posts
  Stream<List<FoodPost>> get userPosts => _postRepository.getUserFoodPosts(_user.uid);

}
