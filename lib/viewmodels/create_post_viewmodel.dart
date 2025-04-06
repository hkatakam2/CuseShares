import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart';
import 'package:image_picker/image_picker.dart'; // Import ImageSource


enum CreatePostStatus { idle, pickingImage, uploading, success, error }

class CreatePostViewModel with ChangeNotifier {
  final PostRepository _postRepository;

  CreatePostViewModel({required PostRepository postRepository}) : _postRepository = postRepository;

  File? _selectedImage;
  CreatePostStatus _status = CreatePostStatus.idle;
  String? _errorMessage;

  // Getters
  File? get selectedImage => _selectedImage;
  CreatePostStatus get status => _status;
  String? get errorMessage => _errorMessage;

  // Pick Image
  Future<void> pickImage(ImageSource source) async {
    _status = CreatePostStatus.pickingImage;
     _errorMessage = null;
     _selectedImage = null; // Clear previous image
    notifyListeners();
    try {
        File? image;
        if (source == ImageSource.gallery) {
            image = await _postRepository.pickImageFromGallery();
        } else {
            image = await _postRepository.pickImageFromCamera();
        }

      if (image != null) {
        _selectedImage = image;
        _status = CreatePostStatus.idle;
      } else {
         _status = CreatePostStatus.idle; // Reset status if user cancelled
      }
    } catch (e) {
      _status = CreatePostStatus.error;
      _errorMessage = "Failed to pick image: ${e.toString()}";
    } finally {
      notifyListeners();
    }
  }

  // Submit Post
  Future<bool> submitPost({
    required String foodName,
    required String description,
    required String location,
  }) async {
    if (_selectedImage == null) {
      _status = CreatePostStatus.error;
      _errorMessage = "Please select an image.";
      notifyListeners();
      return false;
    }
    if (foodName.isEmpty || description.isEmpty || location.isEmpty) {
       _status = CreatePostStatus.error;
       _errorMessage = "Please fill in all fields.";
       notifyListeners();
       return false;
    }


    _status = CreatePostStatus.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _postRepository.createFoodPost(
        foodName: foodName,
        description: description,
        location: location,
        imageFile: _selectedImage!,
      );
      _status = CreatePostStatus.success;
      _selectedImage = null; // Clear image after successful upload
      notifyListeners();
      return true;
    } catch (e) {
      _status = CreatePostStatus.error;
      _errorMessage = "Failed to create post: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  // Reset status (e.g., after success or error message is shown)
  void resetStatus() {
      if (_status == CreatePostStatus.success || _status == CreatePostStatus.error) {
          _status = CreatePostStatus.idle;
          _errorMessage = null;
          notifyListeners();
      }
  }
}

