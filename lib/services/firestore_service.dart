import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/models/chat_message.dart'; // Import ChatMessage

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference for posts
  final CollectionReference _postsCollection =
      FirebaseFirestore.instance.collection('foodPosts');

  // Get ALL food posts stream (renamed and filter removed)
  Stream<List<FoodPost>> getAllFoodPostsStream() {
    return _postsCollection
        // Removed: .where('isAvailable', isEqualTo: true)
        .orderBy('timestamp', descending: true) // Show newest first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FoodPost.fromFirestore(doc)).toList();
    });
  }

   // Get food posts created by a specific user
  Stream<List<FoodPost>> getUserFoodPosts(String userId) {
    return _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FoodPost.fromFirestore(doc)).toList();
    });
  }


  // Add a new food post (now includes coordinates)
  Future<DocumentReference> addFoodPost(FoodPost post) {
    // Use the FoodPost's toFirestore method
    return _postsCollection.add(post.toFirestore());
  }

  // Update food post availability (mark as finished)
  Future<void> updatePostAvailability(String postId, bool isAvailable) {
    return _postsCollection.doc(postId).update({'isAvailable': isAvailable});
  }

  // Get a single post
  Future<FoodPost?> getFoodPost(String postId) async {
      DocumentSnapshot doc = await _postsCollection.doc(postId).get();
      if (doc.exists) {
          return FoodPost.fromFirestore(doc);
      }
      return null;
  }

  // --- Chat Message Methods ---

  // Get chat messages stream for a post
  Stream<List<ChatMessage>> getChatMessagesStream(String postId) {
    return _postsCollection
        .doc(postId)
        .collection('messages') // Access the subcollection
        .orderBy('timestamp', descending: true) // Latest messages first
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Add a chat message to a post
  Future<void> addChatMessage(String postId, ChatMessage message) {
    return _postsCollection
        .doc(postId)
        .collection('messages')
        .add(message.toFirestore());
  }

}
