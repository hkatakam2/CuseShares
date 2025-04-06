import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cuse_food_share_app/viewmodels/auth_viewmodel.dart';
import 'package:cuse_food_share_app/viewmodels/profile_viewmodel.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart'; // Needed for ProfileViewModel creation
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/views/home/widgets/post_list_item.dart'; // Reuse list item
import 'dart:io'; // For Platform check

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;

    if (currentUser == null) {
      // Should not happen if AuthWrapper is set up correctly
      final Widget errorBody = Center(child: Text('User not logged in.'));
      return Platform.isIOS
          ? CupertinoPageScaffold(navigationBar: CupertinoNavigationBar(middle: Text('Profile')), child: errorBody)
          : Scaffold(appBar: AppBar(title: Text('Profile')), body: errorBody);
    }

    // Provide the ProfileViewModel
    return ChangeNotifierProvider<ProfileViewModel>(
      create: (context) => ProfileViewModel(
        postRepository: Provider.of<PostRepository>(context, listen: false),
        user: currentUser,
      ),
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          // --- User Info Section ---
          final Widget userInfo = Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  backgroundImage: viewModel.user.photoURL != null
                      ? NetworkImage(viewModel.user.photoURL!)
                      : null,
                  child: viewModel.user.photoURL == null
                      ? Icon(Platform.isIOS ? CupertinoIcons.person_fill : Icons.person, size: 40, color: Theme.of(context).hintColor)
                      : null,
                ),
                SizedBox(width: 20),
                Expanded( // Allow text to wrap if needed
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.user.displayName ?? 'No Name',
                        style: Platform.isIOS
                            ? CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)
                            : Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        viewModel.user.email ?? 'No Email',
                         style: Platform.isIOS
                            ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(color: CupertinoColors.systemGrey)
                            : Theme.of(context).textTheme.bodySmall,
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          // --- Posts List Section ---
          final Widget postsList = StreamBuilder<List<FoodPost>>(
            stream: viewModel.userPosts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Platform.isIOS ? CupertinoActivityIndicator() : CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading your posts: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text(
                        'You haven\'t posted any food yet.',
                         style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor),
                    )
                );
              }
              final posts = snapshot.data!;
              return ListView.builder(
                 // Add padding for iOS safe area if needed, handled by CupertinoPageScaffold's SafeArea
                 padding: Platform.isIOS ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                 itemCount: posts.length,
                 itemBuilder: (context, index) {
                   return PostListItem(post: posts[index]); // Reuse the same list item
                 },
              );
            },
          );

          // --- Build UI based on Platform ---
          if (Platform.isIOS) {
             return CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                   middle: Text('My Profile'),
                   previousPageTitle: 'Home', // Or appropriate back title
                ),
                child: SafeArea( // Ensure content respects safe areas
                  child: Column(
                    children: [
                       userInfo,
                       Divider(height: 1, color: CupertinoColors.systemGrey4), // iOS style divider
                       Padding(
                         padding: const EdgeInsets.symmetric(vertical: 10.0),
                         child: Text('My Food Posts', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                       ),
                       Expanded(child: postsList),
                    ]
                  ),
                ),
             );
          } else {
             // Material UI
             return Scaffold(
                appBar: AppBar(
                   title: Text('My Profile & Posts'),
                ),
                body: Column(
                   children: [
                      userInfo,
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          'My Food Posts',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(child: postsList),
                   ],
                ),
             );
          }
        },
      ),
    );
  }
}
