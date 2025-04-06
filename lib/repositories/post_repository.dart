import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/services/firestore_service.dart';
import 'package:cuse_food_share_app/services/storage_service.dart';
import 'package:cuse_food_share_app/services/auth_service.dart'; // Need user info

class PostRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final AuthService _authService; // To get current user details for posting

  PostRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
    required AuthService authService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService,
        _authService = authService;

  // Get stream of available food posts
  Stream<List<FoodPost>> getAvailableFoodPosts() =>
      _firestoreService.getAvailableFoodPosts();

  // Get stream of user's food posts
  Stream<List<FoodPost>> getUserFoodPosts(String userId) =>
      _firestoreService.getUserFoodPosts(userId);

  // Pick image from gallery
   Future<File?> pickImageFromGallery() => _storageService.pickImageFromGallery();

   // Pick image from camera
   Future<File?> pickImageFromCamera() => _storageService.pickImageFromCamera();


  // Create a new food post
  Future<void> createFoodPost({
    required String foodName,
    required String description,
    required String location,
    required File imageFile,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    // 1. Upload image
    String? imageUrl =
        await _storageService.uploadImage(imageFile, currentUser.uid);
    if (imageUrl == null) {
      throw Exception("Image upload failed");
    }

    // 2. Create FoodPost object
    final newPost = FoodPost(
      id: '', // Firestore generates the ID
      foodName: foodName,
      description: description,
      location: location,
      imageUrl: imageUrl,
      userId: currentUser.uid,
      userName: currentUser.displayName ?? currentUser.email ?? 'Anonymous', // Use display name or email
      timestamp: Timestamp.now(), // Set current time
      isAvailable: true, // New posts are available by default
    );

    // 3. Add to Firestore
    await _firestoreService.addFoodPost(newPost);

    // 4. NOTE: Sending the notification should ideally be handled by a Cloud Function
    // triggered by the Firestore write, not directly from the client app.
    // See comment in NotificationService.
  }

  // Mark post as finished
  Future<void> markPostAsFinished(String postId) =>
      _firestoreService.updatePostAvailability(postId, false);

  // Mark post as available again (optional)
   Future<void> markPostAsAvailable(String postId) =>
      _firestoreService.updatePostAvailability(postId, true);
}
