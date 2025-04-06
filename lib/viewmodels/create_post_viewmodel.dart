import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For GeoPoint
import 'package:cuse_food_share_app/repositories/post_repository.dart';
import 'package:image_picker/image_picker.dart';
// Import location related things if needed for state management here
// For simplicity, location picking logic might live directly in the View for now

enum CreatePostStatus { idle, pickingImage, pickingLocation, uploading, success, error }

class CreatePostViewModel with ChangeNotifier {
  final PostRepository _postRepository;

  CreatePostViewModel({required PostRepository postRepository}) : _postRepository = postRepository;

  File? _selectedImage;
  // Store selected location details if picked from map
  GeoPoint? _selectedCoordinates;
  String? _selectedLocationText; // Can be from map reverse geocode or manual input

  CreatePostStatus _status = CreatePostStatus.idle;
  String? _errorMessage;

  // Getters
  File? get selectedImage => _selectedImage;
  GeoPoint? get selectedCoordinates => _selectedCoordinates;
  String? get selectedLocationText => _selectedLocationText; // Display this in UI
  CreatePostStatus get status => _status;
  String? get errorMessage => _errorMessage;

  // --- Image Picking ---
  Future<void> pickImage(ImageSource source) async {
    _updateStatus(CreatePostStatus.pickingImage);
    try {
      File? image;
      if (source == ImageSource.gallery) {
        image = await _postRepository.pickImageFromGallery();
      } else {
        image = await _postRepository.pickImageFromCamera();
      }
      if (image != null) {
        _selectedImage = image;
        _updateStatus(CreatePostStatus.idle);
      } else {
        _updateStatus(CreatePostStatus.idle); // Reset status if user cancelled
      }
    } catch (e) {
      _setError("Failed to pick image: ${e.toString()}");
    }
  }

  // --- Location Picking --- (State management part)
  void setLocation(GeoPoint coordinates, String address) {
      _selectedCoordinates = coordinates;
      _selectedLocationText = address;
      notifyListeners(); // Update UI to show selected location
  }

   void clearLocation() {
      _selectedCoordinates = null;
      _selectedLocationText = null;
      notifyListeners();
  }

  // --- Submit Post ---
  Future<bool> submitPost({
    required String foodName,
    required String description,
    required String locationText, // Use the text provided by user OR from map picker state
  }) async {
    if (_selectedImage == null) {
      _setError("Please select an image.");
      return false;
    }
    if (foodName.isEmpty || description.isEmpty || locationText.isEmpty) {
       _setError("Please fill in all fields.");
       return false;
    }
    // Note: _selectedCoordinates might be null if user entered location manually

    _updateStatus(CreatePostStatus.uploading);
    try {
      await _postRepository.createFoodPost(
        foodName: foodName,
        description: description,
        locationText: locationText, // Pass the final text
        coordinates: _selectedCoordinates, // Pass the coordinates (can be null)
        imageFile: _selectedImage!,
      );
      _status = CreatePostStatus.success;
      _clearForm(); // Clear fields after successful upload
      notifyListeners();
      return true;
    } catch (e) {
      _setError("Failed to create post: ${e.toString()}");
      return false;
    }
  }

  // --- Helpers ---
  void _updateStatus(CreatePostStatus newStatus) {
    _status = newStatus;
    _errorMessage = null; // Clear error on status change
    notifyListeners();
  }

  void _setError(String message) {
    _status = CreatePostStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearForm() {
      _selectedImage = null;
      _selectedCoordinates = null;
      _selectedLocationText = null;
      // Don't clear controllers here, let the view handle that on success maybe
  }

  // Reset status (e.g., after success or error message is shown)
  void resetStatus() {
      if (_status == CreatePostStatus.success || _status == CreatePostStatus.error) {
          _updateStatus(CreatePostStatus.idle);
      }
  }
}
