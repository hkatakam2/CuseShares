import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick an image from gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70); // Compress image slightly
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

   // Pick an image from camera
  Future<File?> pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70); // Compress image slightly
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }


  // Upload an image file to Firebase Storage
  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      // Create a unique file name using timestamp and user ID
      String fileName =
          'food_images/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child(fileName);

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(imageFile);

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }
}