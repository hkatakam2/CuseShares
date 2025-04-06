import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/viewmodels/post_details_viewmodel.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart'; // Need repository
import 'package:cuse_food_share_app/viewmodels/auth_viewmodel.dart'; // To check current user
import 'package:intl/intl.dart'; // For date formatting


class PostDetailsScreen extends StatelessWidget {
  final FoodPost post; // Receive the post object

  const PostDetailsScreen({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format the timestamp
    final formattedDate = DateFormat('EEEE, MMM d, yyyy \'at\' h:mm a').format(post.timestamp.toDate());
    final currentUser = Provider.of<AuthViewModel>(context, listen: false).user;

    return ChangeNotifierProvider<PostDetailsViewModel>(
      create: (context) => PostDetailsViewModel(
        postRepository: Provider.of<PostRepository>(context, listen: false),
        post: post, // Pass the initial post data
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(post.foodName),
           backgroundColor: Colors.orange[800],
        ),
        body: Consumer<PostDetailsViewModel>(
           builder: (context, viewModel, child) {
                // Show messages based on status
                WidgetsBinding.instance.addPostFrameCallback((_) {
                     if (viewModel.status == PostDetailsStatus.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Post marked as finished!'), backgroundColor: Colors.green)
                        );
                        viewModel.resetStatus();
                     } else if (viewModel.status == PostDetailsStatus.error && viewModel.errorMessage != null) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${viewModel.errorMessage}'), backgroundColor: Colors.red)
                        );
                         viewModel.resetStatus();
                     }
                });

                // Use viewModel.post which reflects the latest state (e.g., isAvailable)
                final currentPostState = viewModel.post;

                return SingleChildScrollView(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Image Section
                        Image.network(
                        currentPostState.imageUrl,
                        width: double.infinity, // Full width
                        height: 250, // Fixed height
                        fit: BoxFit.cover,
                         loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(height: 250, color: Colors.grey[200], child: Center(child: CircularProgressIndicator()));
                         },
                         errorBuilder: (context, error, stackTrace) {
                            return Container(height: 250, color: Colors.grey[200], child: Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey[400]));
                         },
                        ),
                        SizedBox(height: 16),

                        // Details Section
                        Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Text(
                                currentPostState.foodName,
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Row(
                                children: [
                                Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[700]),
                                SizedBox(width: 8),
                                Expanded( // Allow location text to wrap
                                    child: Text(
                                    currentPostState.location,
                                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                                    ),
                                ),
                                ],
                            ),
                            SizedBox(height: 8),
                             Row(
                                children: [
                                Icon(Icons.person_outline, size: 18, color: Colors.grey[700]),
                                SizedBox(width: 8),
                                Text(
                                    'Posted by: ${currentPostState.userName}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                                ],
                            ),
                             SizedBox(height: 8),
                            Row(
                                children: [
                                Icon(Icons.access_time_outlined, size: 18, color: Colors.grey[700]),
                                SizedBox(width: 8),
                                Text(
                                    'Posted: $formattedDate',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                                ],
                            ),
                            SizedBox(height: 16),
                            Text(
                                'Description:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 5),
                            Text(
                                currentPostState.description,
                                style: TextStyle(fontSize: 16, height: 1.4), // Add line spacing
                            ),
                            SizedBox(height: 24),

                            // Availability Status & Action Button
                            Center(
                                child: Column(
                                children: [
                                    Chip(
                                    label: Text(
                                        currentPostState.isAvailable ? 'AVAILABLE' : 'FINISHED',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: currentPostState.isAvailable ? Colors.green[600] : Colors.red[600],
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    SizedBox(height: 16),
                                    if (currentPostState.isAvailable) // Show button only if available
                                    ElevatedButton.icon(
                                        icon: viewModel.status == PostDetailsStatus.updating
                                            ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                                            : Icon(Icons.check_circle_outline),
                                        label: Text('Mark as Finished'),
                                        style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[700],
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                        textStyle: TextStyle(fontSize: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8.0)
                                        ),
                                        ),
                                        onPressed: viewModel.status == PostDetailsStatus.updating
                                            ? null // Disable while updating
                                            : () {
                                                // Show confirmation dialog
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext ctx) {
                                                    return AlertDialog(
                                                        title: Text('Confirm Action'),
                                                        content: Text('Are you sure this food is finished and no longer available?'),
                                                        actions: <Widget>[
                                                        TextButton(
                                                            child: Text('Cancel'),
                                                            onPressed: () {
                                                            Navigator.of(ctx).pop(); // Close dialog
                                                            },
                                                        ),
                                                        TextButton(
                                                            child: Text('Yes, Mark as Finished', style: TextStyle(color: Colors.red)),
                                                            onPressed: () {
                                                                Navigator.of(ctx).pop(); // Close dialog
                                                                viewModel.markAsFinished(); // Call the ViewModel method
                                                            },
                                                        ),
                                                        ],
                                                    );
                                                    });
                                            },
                                    ),
                                    // Optional: Add button to mark as available again if needed
                                    // if (!currentPostState.isAvailable && currentUser?.uid == currentPostState.userId)
                                    //    ElevatedButton(...)
                                ],
                                ),
                            ),
                             SizedBox(height: 30), // Bottom padding
                            ],
                        ),
                        ),
                    ],
                    ),
                );
           },
        ),
      ),
    );
  }
}
