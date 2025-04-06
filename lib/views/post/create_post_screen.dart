import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuse_food_share_app/viewmodels/create_post_viewmodel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart';


class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _foodNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
     // Reset status when screen is disposed if needed
     WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<CreatePostViewModel>(context, listen: false).resetStatus();
     });
    super.dispose();
  }

  // Function to show image source selection dialog
  Future<void> _showImageSourceDialog(CreatePostViewModel viewModel) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Select Image Source"),
            content: Column(
              mainAxisSize: MainAxisSize.min, // Prevent stretching
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Gallery'),
                  onTap: () {
                    viewModel.pickImage(ImageSource.gallery);
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Camera'),
                  onTap: () {
                    viewModel.pickImage(ImageSource.camera);
                     Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            ),
          );
        });
  }


  @override
  Widget build(BuildContext context) {
    // Listen to the ViewModel
    return ChangeNotifierProvider<CreatePostViewModel>(
       // Create the ViewModel using the PostRepository from the parent provider
       create: (context) => CreatePostViewModel(
           postRepository: Provider.of<PostRepository>(context, listen: false)
       ),
       child: Scaffold(
        appBar: AppBar(
          title: Text('Create New Food Post'),
          backgroundColor: Colors.orange[800],
        ),
        body: Consumer<CreatePostViewModel>( // Use Consumer to react to changes
          builder: (context, viewModel, child) {
            // Show success/error messages
            WidgetsBinding.instance.addPostFrameCallback((_) { // Schedule for after build
                 if (viewModel.status == CreatePostStatus.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Post created successfully!'), backgroundColor: Colors.green)
                    );
                    // Optionally navigate back or clear form
                    Navigator.of(context).pop(); // Go back after success
                    viewModel.resetStatus(); // Reset status after showing message
                 } else if (viewModel.status == CreatePostStatus.error && viewModel.errorMessage != null) {
                     ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${viewModel.errorMessage}'), backgroundColor: Colors.red)
                    );
                     viewModel.resetStatus(); // Reset status after showing message
                 }
            });


            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Image Picker Area
                    GestureDetector(
                      onTap: viewModel.status == CreatePostStatus.uploading || viewModel.status == CreatePostStatus.pickingImage
                          ? null // Disable tap while busy
                          : () => _showImageSourceDialog(viewModel), // Show source selection
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: viewModel.selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: Image.file(
                                  viewModel.selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                     if (viewModel.status == CreatePostStatus.pickingImage)
                                        CircularProgressIndicator()
                                     else ...[
                                        Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey[600]),
                                        SizedBox(height: 8),
                                        Text('Tap to select image', style: TextStyle(color: Colors.grey[700])),
                                     ]
                                  ],
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Food Name Field
                    TextFormField(
                      controller: _foodNameController,
                      decoration: InputDecoration(
                        labelText: 'Food Name / Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                        prefixIcon: Icon(Icons.fastfood_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the food name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (e.g., quantity, type)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                         prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Location Field (Text)
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location (e.g., Building name, Room #)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                         prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the location';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),

                    // Submit Button with Loading Indicator
                    ElevatedButton.icon(
                      icon: viewModel.status == CreatePostStatus.uploading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0))
                          : Icon(Icons.cloud_upload_outlined),
                      label: Text(viewModel.status == CreatePostStatus.uploading ? 'Submitting...' : 'Submit Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)
                        ),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      onPressed: viewModel.status == CreatePostStatus.uploading || viewModel.status == CreatePostStatus.pickingImage
                          ? null // Disable button while uploading or picking
                          : () {
                              if (_formKey.currentState!.validate()) {
                                viewModel.submitPost(
                                  foodName: _foodNameController.text.trim(),
                                  description: _descriptionController.text.trim(),
                                  location: _locationController.text.trim(),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
       ),
    );
  }
}
