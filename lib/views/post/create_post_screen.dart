import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cuse_food_share_app/viewmodels/create_post_viewmodel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import Google Maps
import 'package:cuse_food_share_app/views/post/map_picker_screen.dart'; // Import Map Picker Screen (Create this next)
import 'package:cloud_firestore/cloud_firestore.dart'; // For GeoPoint
import 'package:cuse_food_share_app/repositories/post_repository.dart'; // Import PostRepository

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
       // Check if the provider still exists before accessing it
       if (mounted) {
           Provider.of<CreatePostViewModel>(context, listen: false).resetStatus();
           Provider.of<CreatePostViewModel>(context, listen: false).clearLocation();
       }
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
    return ChangeNotifierProvider<CreatePostViewModel>(
      create: (context) => CreatePostViewModel(
          postRepository: Provider.of<PostRepository>(context, listen: false)),
      child: Platform.isIOS
          ? _buildIOSLayout(context)
          : _buildAndroidLayout(context),
    );
  }

  Widget _buildIOSLayout(BuildContext context) {
    return Consumer<CreatePostViewModel>(
      builder: (context, viewModel, child) {
        // Handle success/error states
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (viewModel.status == CreatePostStatus.success) {
            viewModel.resetStatus();
            // Pop until we reach the root navigator (home screen)
            Navigator.of(context, rootNavigator: true).pop();
          } else if (viewModel.status == CreatePostStatus.error && viewModel.errorMessage != null) {
            // Show error using CupertinoDialog instead of Snackbar
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: Text('Error'),
                content: Text(viewModel.errorMessage!),
                actions: [
                  CupertinoDialogAction(
                    child: Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
            viewModel.resetStatus();
          }
        });

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text('Create Post'),
            leading: CupertinoNavigationBarBackButton(
              previousPageTitle: 'Home',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          child: SafeArea(child: _buildFormBody(context, viewModel)),
        );
      },
    );
  }

  Widget _buildAndroidLayout(BuildContext context) {
    return Consumer<CreatePostViewModel>(
      builder: (context, viewModel, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (viewModel.status == CreatePostStatus.success) {
            _showPlatformSnackbar(context, 'Post created successfully!', isError: false);
            viewModel.resetStatus();
            Navigator.of(context, rootNavigator: true).pop();
          } else if (viewModel.status == CreatePostStatus.error && viewModel.errorMessage != null) {
            _showPlatformSnackbar(context, 'Error: ${viewModel.errorMessage}', isError: true);
            viewModel.resetStatus();
          }
        });

        return Scaffold(
          appBar: AppBar(title: Text('Create New Food Post')),
          body: _buildFormBody(context, viewModel),
        );
      },
    );
  }

  // --- Build Form Body ---
  Widget _buildFormBody(BuildContext context, CreatePostViewModel viewModel) {
      // Update location text field if viewModel has a selected location
      // but only if the controller doesn't already match (prevents cursor jump)
      if (viewModel.selectedLocationText != null && _locationTextController.text != viewModel.selectedLocationText) {
          WidgetsBinding.instance.addPostFrameCallback((_) { // Schedule update after build
            if (mounted) { // Check if mounted before updating controller
               _locationTextController.text = viewModel.selectedLocationText!;
            }
          });
      }

      // Use CupertinoFormSection for iOS grouping
      final List<Widget> formFields = [
           // --- Image Picker ---
            GestureDetector(
              onTap: viewModel.status == CreatePostStatus.uploading || viewModel.status == CreatePostStatus.pickingImage
                  ? null
                  : () => _showImageSourceDialog(viewModel),
              child: Container(
                height: 200,
                margin: Platform.isIOS ? EdgeInsets.zero : EdgeInsets.only(bottom: 20), // Margin for Material only
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
            if (Platform.isIOS) SizedBox(height: 20), // Spacing for iOS

            // --- Food Name ---
            _buildTextFormField(
                controller: _foodNameController,
                labelText: 'Food Name / Title',
                icon: Platform.isIOS ? CupertinoIcons.tag : Icons.fastfood_outlined,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter the food name' : null,
            ),
             if (Platform.isAndroid) SizedBox(height: 16),

            // --- Description ---
            _buildTextFormField(
                controller: _descriptionController,
                labelText: 'Description (e.g., quantity, type)',
                icon: Platform.isIOS ? CupertinoIcons.text_alignleft : Icons.description_outlined,
                maxLines: 3,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description' : null,
            ),
             if (Platform.isAndroid) SizedBox(height: 16),

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
            Container( // Wrap button for alignment/padding control
                alignment: Platform.isIOS ? Alignment.center : Alignment.centerLeft,
                child: Platform.isIOS
                  ? CupertinoButton(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.map_pin_ellipse, size: 20), SizedBox(width: 8), Text('Pick Location on Map')]),
                      onPressed: viewModel.status == CreatePostStatus.uploading ? null : () => _navigateToMapPicker(viewModel),
                    )
                  : TextButton.icon(
                      icon: Icon(Icons.map_outlined, size: 20),
                      label: Text('Pick Location on Map'),
                      onPressed: viewModel.status == CreatePostStatus.uploading ? null : () => _navigateToMapPicker(viewModel),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0), // Adjust padding
                      ),
                    ),
            ),
            SizedBox(height: 30),

            // --- Submit Button --- (Platform Aware)
            _buildSubmitButton(context, viewModel),
      ];


      return SingleChildScrollView(
        // Use different padding for iOS to look better with CupertinoFormSection
        padding: Platform.isIOS ? EdgeInsets.zero : const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // Wrap fields in CupertinoFormSection on iOS
          child: Platform.isIOS
            ? CupertinoFormSection.insetGrouped(
                header: Padding( // Add header for image picker on iOS
                  padding: const EdgeInsets.only(top: 10.0), // Space above image
                  child: formFields[0], // Image picker is the first element
                ),
                children: formFields.sublist(1), // Rest of the fields
                 footer: SizedBox(height: 20), // Add space at the bottom
              )
            : Column( // Use Column for Material
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: formFields,
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
          // Using CupertinoTextFormFieldRow for integrated label/validation look
          return CupertinoTextFormFieldRow(
              controller: controller,
              prefix: Padding(
                 padding: const EdgeInsets.only(right: 6.0), // Add padding to icon
                 child: Icon(icon, color: CupertinoTheme.of(context).primaryColor, size: 20),
              ),
              placeholder: labelText,
              maxLines: maxLines,
              onChanged: onChanged,
              validator: validator, // Pass validator
          );
      } else {
          return TextFormField(
              controller: controller,
              decoration: InputDecoration(
                  labelText: labelText,
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

      final Widget buttonContent = isLoading
          ? (Platform.isIOS ? CupertinoActivityIndicator(color: Colors.white) : SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0)))
          : Text(buttonText);

      final VoidCallback? onPressed = isLoading ? null : () {
          bool isValid = true;
          // Trigger validation based on platform
          if (Platform.isAndroid) {
             isValid = _formKey.currentState?.validate() ?? false;
          } else {
             // Manually check controllers for basic validation on iOS
             if (_foodNameController.text.isEmpty) isValid = false;
             if (_descriptionController.text.isEmpty) isValid = false;
             if (_locationTextController.text.isEmpty) isValid = false;
             if (viewModel.selectedImage == null) isValid = false; // Check image

             // Trigger validation visuals in CupertinoTextFormFieldRow
             // This requires accessing the state of each CupertinoTextFormFieldRow, which is complex.
             // A simpler approach for iOS might be just checking controllers and showing a general error.
          }

          if (isValid && viewModel.selectedImage == null) {
              _showPlatformSnackbar(context, 'Please select an image.', isError: true);
              isValid = false;
          }


          if (isValid) {
             viewModel.submitPost(
                foodName: _foodNameController.text.trim(),
                description: _descriptionController.text.trim(),
                locationText: _locationTextController.text.trim(), // Use text field value
              );
          } else if (!isValid) { // Show general error if validation fails
               _showPlatformSnackbar(context, 'Please fill all fields and select an image.', isError: true);
          }
      };


      return Padding(
        // Add padding, especially for Material to separate from form fields
        padding: Platform.isIOS ? EdgeInsets.symmetric(horizontal: 16.0, vertical: 20) : const EdgeInsets.only(top: 16.0),
        child: Platform.isIOS
          ? CupertinoButton.filled(
              child: buttonContent,
              onPressed: onPressed,
            )
          : ElevatedButton(
              child: buttonContent,
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
      );
  }

   // --- Helper for Platform Snackbar ---
  void _showPlatformSnackbar(BuildContext context, String message, {bool isError = false}) {
    if (Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
