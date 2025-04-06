import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cuse_food_share_app/models/app_user.dart'; // Assuming models folder exists

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Create user object based on FirebaseUser
  AppUser? _userFromFirebaseUser(User? user) {
    return user != null
        ? AppUser(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL)
        : null;
  }

  // Auth change user stream
  Stream<AppUser?> get user {
    return _firebaseAuth.authStateChanges().map(_userFromFirebaseUser);
  }

  // Get current user
  AppUser? get currentUser {
    return _userFromFirebaseUser(_firebaseAuth.currentUser);
  }

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return _userFromFirebaseUser(userCredential.user);
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }

  // Sign in with Email & Password
  Future<AppUser?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print("Error signing in with email: $e");
      return null;
    }
  }

  // Register with Email & Password
  Future<AppUser?> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      // Update display name
      await user?.updateDisplayName(displayName);
      // Reload user to get updated info
      await user?.reload();
      user = _firebaseAuth.currentUser; // Get the updated user
      return _userFromFirebaseUser(user);
    } catch (e) {
      print("Error registering with email: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Sign out from Google
      await _firebaseAuth.signOut(); // Sign out from Firebase
    } catch (e) {
      print("Error signing out: $e");
    }
  }
}
