import 'package:cuse_food_share_app/models/app_user.dart';
import 'package:cuse_food_share_app/services/auth_service.dart';

// Repository acts as a mediator between ViewModel and Service
class AuthRepository {
  final AuthService _authService;

  AuthRepository({required AuthService authService}) : _authService = authService;

  // Expose the user stream from the service
  Stream<AppUser?> get user => _authService.user;

  // Expose the current user getter
  AppUser? get currentUser => _authService.currentUser;

  // Expose sign-in methods
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) =>
      _authService.signInWithEmailAndPassword(email, password);

  Future<AppUser?> registerWithEmailAndPassword(
          String email, String password, String displayName) =>
      _authService.registerWithEmailAndPassword(email, password, displayName);

  // Expose sign-out method
  Future<void> signOut() => _authService.signOut();
}
