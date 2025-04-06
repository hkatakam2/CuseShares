import 'package:flutter/foundation.dart';
import 'package:cuse_food_share_app/models/app_user.dart';
import 'package:cuse_food_share_app/repositories/auth_repository.dart';

enum AuthStatus { uninitialized, authenticated, authenticating, unauthenticated, error }

class AuthViewModel with ChangeNotifier {
  final AuthRepository _authRepository;
  AuthStatus _status = AuthStatus.uninitialized;
  AppUser? _user;
  String? _errorMessage;

  AuthViewModel({required AuthRepository authRepository}) : _authRepository = authRepository {
    // Listen to user changes from the repository
    _authRepository.user.listen((AppUser? user) {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else {
        _status = AuthStatus.authenticated;
        _user = user;
      }
      _errorMessage = null; // Clear error on status change
      notifyListeners();
    }, onError: (e) {
        _status = AuthStatus.error;
        _errorMessage = "An error occurred: ${e.toString()}";
        _user = null;
        notifyListeners();
    });
    // Set initial status based on current user
     _user = _authRepository.currentUser;
     _status = _user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
     // No need to notify here as the stream listener will handle it if state changes
  }

  // Getters
  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;

  // Sign In with Google
  Future<void> signInWithGoogle() async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      AppUser? loggedInUser = await _authRepository.signInWithGoogle();
      if (loggedInUser == null && _status != AuthStatus.authenticated) {
         // User cancelled or failed, and stream hasn't updated yet
         _status = AuthStatus.unauthenticated;
         _errorMessage = "Sign in cancelled or failed.";
      }
      // Status will be updated by the stream listener upon success/failure
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      _user = null; // Ensure user is null on error
    } finally {
        // Only notify if status wasn't updated by the stream listener
        if (_status != AuthStatus.authenticated && _status != AuthStatus.unauthenticated) {
            notifyListeners();
        }
    }
  }

  // Sign In with Email
  Future<bool> signInWithEmail(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      AppUser? loggedInUser = await _authRepository.signInWithEmailAndPassword(email, password);
       if (loggedInUser == null) {
         _status = AuthStatus.unauthenticated; // Explicitly set if login fails
         _errorMessage = "Invalid email or password.";
         notifyListeners();
         return false;
       }
       // Stream listener will update status to authenticated
       return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = "Sign in failed: ${e.toString()}";
       _user = null;
      notifyListeners();
      return false;
    }
  }

   // Register with Email
  Future<bool> registerWithEmail(String email, String password, String displayName) async {
    _status = AuthStatus.authenticating;
     _errorMessage = null;
    notifyListeners();
    try {
      AppUser? registeredUser = await _authRepository.registerWithEmailAndPassword(email, password, displayName);
       if (registeredUser == null) {
         _status = AuthStatus.unauthenticated; // Stay unauthenticated if registration fails
         _errorMessage = "Registration failed. Please try again.";
         notifyListeners();
         return false;
       }
       // Stream listener will update status to authenticated
       return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = "Registration failed: ${e.toString()}";
       _user = null;
      notifyListeners();
      return false;
    }
  }


  // Sign Out
  Future<void> signOut() async {
    _status = AuthStatus.unauthenticated; // Optimistically update status
    _user = null;
    _errorMessage = null;
    notifyListeners(); // Notify immediately for faster UI update
    await _authRepository.signOut();
    // Stream listener will confirm unauthenticated state
  }
}
