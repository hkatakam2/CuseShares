import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuse_food_share_app/models/food_post.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  final CollectionReference _postsCollection =
      FirebaseFirestore.instance.collection('foodPosts');

  // Get all available food posts stream
  Stream<List<FoodPost>> getAvailableFoodPosts() {
    return _postsCollection
        .where('isAvailable', isEqualTo: true) // Only get available posts
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


  // Add a new food post
  Future<void> addFoodPost(FoodPost post) {
    // Use the FoodPost's toFirestore method
    return _postsCollection.add(post.toFirestore());
  }

  // Update food post availability (mark as finished)
  Future<void> updatePostAvailability(String postId, bool isAvailable) {
    return _postsCollection.doc(postId).update({'isAvailable': isAvailable});
  }

  // Get a single post (might be needed for details screen if not passed directly)
  Future<FoodPost?> getFoodPost(String postId) async {
      DocumentSnapshot doc = await _postsCollection.doc(postId).get();
      if (doc.exists) {
          return FoodPost.fromFirestore(doc);
      }
      return null;
  }

  // Delete a food post (Optional - maybe only creator can delete)
  // Future<void> deleteFoodPost(String postId) {
  //   return _postsCollection.doc(postId).delete();
  // }
}