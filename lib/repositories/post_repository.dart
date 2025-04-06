import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for GeoPoint
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/models/chat_message.dart'; // Import ChatMessage
import 'package:cuse_food_share_app/models/app_user.dart'; // Import AppUser
import 'package:cuse_food_share_app/services/firestore_service.dart';
import 'package:cuse_food_share_app/services/storage_service.dart';
import 'package:cuse_food_share_app/services/auth_service.dart'; // Need user info

class PostRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final AuthService _authService; // To get current user details

  PostRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
    required AuthService authService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService,
        _authService = authService;

  // Get stream of ALL food posts (renamed)
  Stream<List<FoodPost>> getAllFoodPostsStream() =>
      _firestoreService.getAllFoodPostsStream();

  // Get stream of user's food posts
  Stream<List<FoodPost>> getUserFoodPosts(String userId) =>
      _firestoreService.getUserFoodPosts(userId);

  // Pick image from gallery
   Future<File?> pickImageFromGallery() => _storageService.pickImageFromGallery();

   // Pick image from camera
   Future<File?> pickImageFromCamera() => _storageService.pickImageFromCamera();


  // Create a new food post (includes coordinates)
  Future<void> createFoodPost({
    required String foodName,
    required String description,
    required String locationText,
    required GeoPoint? coordinates, // Add coordinates parameter
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
      locationText: locationText, // Use the text field value
      coordinates: coordinates, // Assign coordinates
      imageUrl: imageUrl,
      userId: currentUser.uid,
      userName: currentUser.displayName ?? currentUser.email ?? 'Anonymous',
      timestamp: Timestamp.now(),
      isAvailable: true,
    );

    // 3. Add to Firestore
    DocumentReference docRef = await _firestoreService.addFoodPost(newPost);

    // 4. Trigger Notification (via Cloud Function - see separate section)
    // The Cloud Function will listen for this creation event.
    print("Post created with ID: ${docRef.id}");
  }

  // Mark post as finished
  Future<void> markPostAsFinished(String postId) =>
      _firestoreService.updatePostAvailability(postId, false);

  // Mark post as available again
   Future<void> markPostAsAvailable(String postId) =>
      _firestoreService.updatePostAvailability(postId, true);


  // --- Chat Methods ---

  // Get chat messages stream for a post
  Stream<List<ChatMessage>> getChatMessagesStream(String postId) =>
      _firestoreService.getChatMessagesStream(postId);

  // Add a chat message
  Future<void> addChatMessage({
    required String postId,
    required String text,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in to chat");
    }
    if (text.trim().isEmpty) {
        throw Exception("Message cannot be empty");
    }

    final newMessage = ChatMessage(
      id: '', // Firestore generates ID
      text: text.trim(),
      userId: currentUser.uid,
      userName: currentUser.displayName ?? currentUser.email ?? 'Anonymous',
      timestamp: Timestamp.now(),
    );

    await _firestoreService.addChatMessage(postId, newMessage);
  }
}