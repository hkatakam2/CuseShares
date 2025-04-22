// Simple User model mirroring Firebase Auth user info
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  // Create user from Firebase User data
  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['name'] ?? '',
      photoURL: data['photoURL'] ?? '',
    );
  }

  // Convert user to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': displayName,
      'photoURL': photoURL,
    };
  }
}