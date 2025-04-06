
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cuse_food_share_app/viewmodels/create_post_viewmodel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import Google Maps
import 'package:cuse_food_share_app/views/post/map_picker_screen.dart'; // Import Map Picker Screen (Create this next)
import 'package:cloud_firestore/cloud_firestore.dart'; // For GeoPoint
import 'package:cuse_food_share_app/repositories/post_repository.dart'; // Add PostRepository import

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationTextController = TextEditingController(); // For manual input / display selected

  @override
  void dispose() {
    _foodNameController.dispose();
    _descriptionController.dispose();
    _locationTextController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CreatePostViewModel>(context, listen: false).resetStatus();
      Provider.of<CreatePostViewModel>(context, listen: false).clearLocation(); // Clear location state too
    });
    super.dispose();
  }

  // --- Image Source Dialog --- (Platform Aware)
  Future<void> _showImageSourceDialog(CreatePostViewModel viewModel) async {
    if (Platform.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: Text('Select Image Source'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              child: Text('Camera'),
              onPressed: () {
                Navigator.pop(context);
                viewModel.pickImage(ImageSource.camera);
              },
            ),
            CupertinoActionSheetAction(
              child: Text('Gallery'),
              onPressed: () {
                Navigator.pop(context);
                viewModel.pickImage(ImageSource.gallery);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text('Cancel'),
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea( // Prevent overlap with system UI
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Gallery'),
                    onTap: () {
                      viewModel.pickImage(ImageSource.gallery);
                      Navigator.of(context).pop();
                    }),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Camera'),
                  onTap: () {
                    viewModel.pickImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  // --- Navigate to Map Picker ---
  Future<void> _navigateToMapPicker(CreatePostViewModel viewModel) async {
     // Dismiss keyboard if open
     FocusScope.of(context).unfocus();

     final LatLng syracuseLatLng = LatLng(43.0481, -76.1474); // Center map initially

     // Use platform-specific navigation
      Route route = Platform.isIOS
        ? CupertinoPageRoute(builder: (_) => MapPickerScreen(initialPosition: syracuseLatLng))
        : MaterialPageRoute(builder: (_) => MapPickerScreen(initialPosition: syracuseLatLng));

      final result = await Navigator.push(context, route);


     if (result != null && result is Map<String, dynamic>) {
        final LatLng pickedLatLng = result['latlng'];
        final String address = result['address'];
        viewModel.setLocation(GeoPoint(pickedLatLng.latitude, pickedLatLng.longitude), address);
        _locationTextController.text = address; // Update text field
     }
  }

  @override
  Widget build(BuildContext context) {
    // Use a single provider instance for this screen
    return ChangeNotifierProvider<CreatePostViewModel>(
      create: (context) => CreatePostViewModel(
          postRepository: Provider.of<PostRepository>(context, listen: false)),
      child: Consumer<CreatePostViewModel>(
        builder: (context, viewModel, child) {
          // Show success/error messages (Platform Aware)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (viewModel.status == CreatePostStatus.success) {
               _showPlatformSnackbar(context, 'Post created successfully!', isError: false);
               Navigator.of(context).pop(); // Go back
               viewModel.resetStatus();
            } else if (viewModel.status == CreatePostStatus.error && viewModel.errorMessage != null) {
                _showPlatformSnackbar(context, 'Error: ${viewModel.errorMessage}', isError: true);
                viewModel.resetStatus();
            }
          });

          // Platform-specific Scaffold/PageScaffold
          final Widget body = _buildFormBody(context, viewModel);
          final PreferredSizeWidget appBar = Platform.isIOS
              ? CupertinoNavigationBar(
                  middle: Text('Create Post'),
                  // Add leading cancel button?
                )
              : AppBar(
                  title: Text('Create New Food Post'),
                  // backgroundColor: Colors.orange[800], // From theme
                );

          return Platform.isIOS
            ? CupertinoPageScaffold(
                navigationBar: appBar as ObstructingPreferredSizeWidget,
                child: SafeArea(child: body), // SafeArea for content below nav bar
              )
            : Scaffold(
                appBar: appBar,
                body: body,
              );
        },
      ),
    );
  }

  // --- Build Form Body ---
  Widget _buildFormBody(BuildContext context, CreatePostViewModel viewModel) {
      // Update location text field if viewModel has a selected location
      // but only if the controller doesn't already match (prevents cursor jump)
      if (viewModel.selectedLocationText != null && _locationTextController.text != viewModel.selectedLocationText) {
          WidgetsBinding.instance.addPostFrameCallback((_) { // Schedule update after build
            _locationTextController.text = viewModel.selectedLocationText!;
          });
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Image Picker ---
              GestureDetector(
                onTap: viewModel.status == CreatePostStatus.uploading || viewModel.status == CreatePostStatus.pickingImage
                    ? null
                    : () => _showImageSourceDialog(viewModel),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant, // Use theme color
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: viewModel.selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.file(viewModel.selectedImage!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (viewModel.status == CreatePostStatus.pickingImage)
                                Platform.isIOS ? CupertinoActivityIndicator() : CircularProgressIndicator()
                              else ...[
                                Icon(Platform.isIOS ? CupertinoIcons.camera : Icons.add_a_photo_outlined, size: 50, color: Theme.of(context).hintColor),
                                SizedBox(height: 8),
                                Text('Tap to select image', style: TextStyle(color: Theme.of(context).hintColor)),
                              ]
                            ],
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20),

              // --- Food Name ---
              _buildTextFormField(
                  controller: _foodNameController,
                  labelText: 'Food Name / Title',
                  icon: Platform.isIOS ? CupertinoIcons.tag : Icons.fastfood_outlined,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter the food name' : null,
              ),
              SizedBox(height: 16),

              // --- Description ---
              _buildTextFormField(
                  controller: _descriptionController,
                  labelText: 'Description (e.g., quantity, type)',
                  icon: Platform.isIOS ? CupertinoIcons.text_alignleft : Icons.description_outlined,
                  maxLines: 3,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description' : null,
              ),
              SizedBox(height: 16),

              // --- Location ---
              _buildTextFormField(
                  controller: _locationTextController,
                  labelText: 'Location Address / Building',
                  icon: Platform.isIOS ? CupertinoIcons.location : Icons.location_on_outlined,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter or pick a location' : null,
                  // Clear picked coordinates if user manually edits text field
                  onChanged: (value) {
                      if (viewModel.selectedCoordinates != null) {
                          viewModel.clearLocation();
                      }
                  }
              ),
              SizedBox(height: 8),
              // Map Picker Button (Platform Aware)
              Platform.isIOS
                ? CupertinoButton(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.map_pin_ellipse, size: 20), SizedBox(width: 8), Text('Pick Location on Map')]),
                    onPressed: viewModel.status == CreatePostStatus.uploading ? null : () => _navigateToMapPicker(viewModel),
                  )
                : TextButton.icon(
                    icon: Icon(Icons.map_outlined, size: 20),
                    label: Text('Pick Location on Map'),
                    onPressed: viewModel.status == CreatePostStatus.uploading ? null : () => _navigateToMapPicker(viewModel),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        // alignment: Alignment.centerLeft, // Align left
                    ),
                  ),
              // Display coordinates if picked (optional)
              // if (viewModel.selectedCoordinates != null)
              //    Padding(
              //      padding: const EdgeInsets.only(top: 4.0),
              //      child: Text('Coords: ${viewModel.selectedCoordinates!.latitude.toStringAsFixed(4)}, ${viewModel.selectedCoordinates!.longitude.toStringAsFixed(4)}', style: Theme.of(context).textTheme.caption),
              //    ),

              SizedBox(height: 30),

              // --- Submit Button --- (Platform Aware)
              _buildSubmitButton(context, viewModel),
            ],
          ),
        ),
      );
  }

  // --- Helper for TextFormFields --- (Platform Aware Styling)
  Widget _buildTextFormField({
      required TextEditingController controller,
      required String labelText,
      required IconData icon,
      required FormFieldValidator<String> validator,
      int maxLines = 1,
      void Function(String)? onChanged,
  }) {
      if (Platform.isIOS) {
          return CupertinoTextField(
              controller: controller,
              placeholder: labelText,
              prefix: Padding(padding: const EdgeInsets.only(left: 8.0), child: Icon(icon, color: CupertinoColors.systemGrey)),
              padding: EdgeInsets.all(12.0),
              maxLines: maxLines,
              onChanged: onChanged,
              decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8.0),
              ),
              // TODO: Add Cupertino validation handling if needed (less direct than Form)
          );
      } else {
          return TextFormField(
              controller: controller,
              decoration: InputDecoration(
                  labelText: labelText,
                  // border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)), // From theme
                  prefixIcon: Icon(icon),
              ),
              maxLines: maxLines,
              validator: validator,
              onChanged: onChanged,
          );
      }
  }

   // --- Helper for Submit Button --- (Platform Aware)
  Widget _buildSubmitButton(BuildContext context, CreatePostViewModel viewModel) {
      final bool isLoading = viewModel.status == CreatePostStatus.uploading || viewModel.status == CreatePostStatus.pickingImage;
      final String buttonText = viewModel.status == CreatePostStatus.uploading ? 'Submitting...' : 'Submit Post';

      if (Platform.isIOS) {
          return CupertinoButton.filled(
              child: isLoading ? CupertinoActivityIndicator(color: Colors.white) : Text(buttonText),
              onPressed: isLoading ? null : () {
                  // TODO: Implement validation check for Cupertino fields if needed
                  // For now, assume validation happens before calling submit
                   viewModel.submitPost(
                      foodName: _foodNameController.text.trim(),
                      description: _descriptionController.text.trim(),
                      locationText: _locationTextController.text.trim(), // Use text field value
                    );
              },
          );
      } else {
          return ElevatedButton.icon(
            icon: isLoading
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0))
                : Icon(Icons.cloud_upload_outlined),
            label: Text(buttonText),
            // style: ElevatedButton.styleFrom(...), // From theme
            onPressed: isLoading ? null : () {
              if (_formKey.currentState!.validate()) {
                viewModel.submitPost(
                  foodName: _foodNameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  locationText: _locationTextController.text.trim(), // Use text field value
                );
              }
            },
          );
      }
  }

   // --- Helper for Platform Snackbar ---
  void _showPlatformSnackbar(BuildContext context, String message, {bool isError = false}) {
      // Simple Snackbar for both for now, can customize further
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message),
              backgroundColor: isError ? Colors.redAccent : Colors.green,
              behavior: SnackBarBehavior.floating, // Looks better generally
          )
       );
      // TODO: Implement Cupertino equivalent if desired (e.g., using a package or custom overlay)
  }
}
