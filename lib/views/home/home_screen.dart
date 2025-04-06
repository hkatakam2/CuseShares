import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuse_food_share_app/viewmodels/home_viewmodel.dart';
import 'package:cuse_food_share_app/viewmodels/auth_viewmodel.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/views/home/widgets/post_list_item.dart';
import 'package:cuse_food_share_app/views/post/create_post_screen.dart';
import 'package:cuse_food_share_app/views/profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false); // Don't need to listen here

    return Scaffold(
      appBar: AppBar(
        title: Text('CuseFoodShare - Available Food'),
        backgroundColor: Colors.orange[800],
        actions: [
          // Profile Button
          IconButton(
            icon: Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () {
              // Navigate to Profile Screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),
          // Logout Button
          IconButton(
            icon: Icon(Icons.logout),
             tooltip: 'Logout',
            onPressed: () async {
              await authViewModel.signOut();
              // AuthWrapper will handle navigation
            },
          ),
        ],
      ),
      body: StreamBuilder<List<FoodPost>>(
        stream: homeViewModel.availablePosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error in stream: ${snapshot.error}"); // Log error
            return Center(child: Text('Error loading posts: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(
                    'No food available right now.\nCheck back later or post some!',
                     textAlign: TextAlign.center,
                     style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                )
            );
          }

          final posts = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(8.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostListItem(post: posts[index]); // Use the custom list item widget
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to Create Post Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreatePostScreen()),
          );
        },
        label: Text('Post Food'),
        icon: Icon(Icons.add_outlined),
        backgroundColor: Colors.orange[700],
      ),
    );
  }
}
