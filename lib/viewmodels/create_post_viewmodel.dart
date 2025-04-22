import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For GeoPoint
import 'package:cuse_food_share_app/repositories/post_repository.dart';
import 'package:image_picker/image_picker.dart';

enum CreatePostStatus { idle, pickingImage, pickingLocation, uploading, success, error }

class CreatePostViewModel with ChangeNotifier {
  final PostRepository _postRepository;

  CreatePostViewModel({required PostRepository postRepository}) : _postRepository = postRepository;

  File? _selectedImage;
  GeoPoint? _selectedCoordinates;
  String? _selectedLocationText;

  CreatePostStatus _status = CreatePostStatus.idle;
  String? _errorMessage;

  // Getters
  File? get selectedImage => _selectedImage;
  GeoPoint? get selectedCoordinates => _selectedCoordinates;
  String? get selectedLocationText => _selectedLocationText;
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

  // --- Location Picking ---
  void setLocation(GeoPoint coordinates, String address) {
      _selectedCoordinates = coordinates;
      _selectedLocationText = address;
      notifyListeners();
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
    required String locationText,
  }) async {
    if (_selectedImage == null) {
      _setError("Please select an image.");
      return false;
    }
    if (foodName.isEmpty || description.isEmpty || locationText.isEmpty) {
       _setError("Please fill in all fields.");
       return false;
    }

    _updateStatus(CreatePostStatus.uploading);
    try {
      await _postRepository.createFoodPost(
        foodName: foodName,
        description: description,
        locationText: locationText,
        coordinates: _selectedCoordinates, // Pass coordinates (can be null)
        imageFile: _selectedImage!,
      );
      _status = CreatePostStatus.success;
      _clearForm();
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
    _errorMessage = null;
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
  }

  void resetStatus() {
      if (_status == CreatePostStatus.success || _status == CreatePostStatus.error) {
          _updateStatus(CreatePostStatus.idle);
      }
  }
}