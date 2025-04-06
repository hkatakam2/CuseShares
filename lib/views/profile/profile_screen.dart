import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuse_food_share_app/viewmodels/auth_viewmodel.dart';
import 'package:cuse_food_share_app/viewmodels/profile_viewmodel.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart'; // Needed for ProfileViewModel creation
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/views/home/widgets/post_list_item.dart'; // Reuse list item


class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the current user from AuthViewModel
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;

    if (currentUser == null) {
      // Should not happen if AuthWrapper is set up correctly, but handle defensively
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: Text('User not logged in.')),
      );
    }

    // Provide the ProfileViewModel, passing the required PostRepository and the current user
    return ChangeNotifierProvider<ProfileViewModel>(
      create: (context) => ProfileViewModel(
        postRepository: Provider.of<PostRepository>(context, listen: false),
        user: currentUser,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Profile & Posts'),
          backgroundColor: Colors.orange[800],
        ),
        body: Consumer<ProfileViewModel>( // Use Consumer to access the ProfileViewModel
          builder: (context, viewModel, child) {
            return Column(
              children: [
                // User Info Section
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: viewModel.user.photoURL != null
                            ? NetworkImage(viewModel.user.photoURL!)
                            : null, // Use NetworkImage for URL
                        child: viewModel.user.photoURL == null
                            ? Icon(Icons.person, size: 40, color: Colors.grey[600])
                            : null,
                      ),
                      SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viewModel.user.displayName ?? 'No Name',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            viewModel.user.email ?? 'No Email',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(),

                // User's Posts Section Header
                 Padding(
                   padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                   child: Text(
                     'My Food Posts',
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                   ),
                 ),


                // List of User's Posts
                Expanded(
                  child: StreamBuilder<List<FoodPost>>(
                    stream: viewModel.userPosts, // Get stream from ViewModel
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading your posts: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                            child: Text(
                                'You haven\'t posted any food yet.',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            )
                        );
                      }

                      final posts = snapshot.data!;

                      // Reuse the PostListItem widget
                      return ListView.builder(
                         padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0), // Add padding
                         itemCount: posts.length,
                         itemBuilder: (context, index) {
                           // Can optionally add indicators for available/finished status here
                           return PostListItem(post: posts[index]);
                         },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
