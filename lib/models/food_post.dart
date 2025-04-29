import 'package:cloud_firestore/cloud_firestore.dart';

class FoodPost {
  final String id; // Document ID from Firestore
  final String foodName;
  final String description;
  final String locationText; // User-entered location text
  final GeoPoint? coordinates; // Latitude/Longitude for map
  final String imageUrl;
  final String userId; // ID of the user who posted
  final String userName; // Name of the user who posted
  final Timestamp timestamp; // Time of posting
  bool isAvailable; // Status: available or finished

  FoodPost({
    required this.id,
    required this.foodName,
    required this.description,
    required this.locationText,
    this.coordinates, // Make coordinates optional
    required this.imageUrl,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.isAvailable = true, // Default to available
  });

  // Factory constructor to create a FoodPost from a Firestore document
  factory FoodPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FoodPost(
      id: doc.id,
      foodName: data['foodName'] ?? '',
      description: data['description'] ?? '',
      locationText: data['locationText'] ?? '', // Changed from 'location'
      coordinates: data['coordinates'] as GeoPoint?, // Read GeoPoint
      imageUrl: data['imageUrl'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  // Method to convert FoodPost instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'foodName': foodName,
      'description': description,
      'locationText': locationText, // Changed from 'location'
      'coordinates': coordinates, // Store GeoPoint
      'imageUrl': imageUrl,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp,
      'isAvailable': isAvailable,
    };
  }
}