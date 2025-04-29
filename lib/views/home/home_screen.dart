import 'dart:io'; // For Platform check
import 'package:flutter/cupertino.dart'; // For Cupertino widgets
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuse_food_share_app/viewmodels/home_viewmodel.dart';
import 'package:cuse_food_share_app/viewmodels/auth_viewmodel.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/views/home/widgets/post_list_item.dart';
import 'package:cuse_food_share_app/views/post/create_post_screen.dart';
import 'package:cuse_food_share_app/views/profile/profile_screen.dart';
import 'package:cuse_food_share_app/utils/theme_notifier.dart'; // Import ThemeNotifier

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final themeNotifier = Provider.of<ThemeNotifier>(context); // Get ThemeNotifier

    // Determine if dark mode is active (considering system theme)
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    // Platform-specific AppBar/NavigationBar
    final PreferredSizeWidget appBar = Platform.isIOS
        ? CupertinoNavigationBar(
            middle: Text('CuseFoodShare'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.profile_circled, size: 28),
              onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => ProfileScreen())),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 CupertinoButton( // Theme Toggle
                    padding: EdgeInsets.symmetric(horizontal: 8), // Add padding
                    child: Icon(isDarkMode ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_stars_fill, size: 22),
                    onPressed: () => themeNotifier.toggleTheme(!isDarkMode),
                  ),
                 CupertinoButton( // Post Button
                    padding: EdgeInsets.symmetric(horizontal: 0),
                    child: Icon(CupertinoIcons.add_circled, size: 26),
                    onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => CreatePostScreen())),
                 ),
                 CupertinoButton( // Logout
                    padding: EdgeInsets.only(left: 8), // Add padding
                    child: Icon(CupertinoIcons.square_arrow_right, size: 24),
                    onPressed: () async => await authViewModel.signOut(),
                 ),
              ],
            ),
             backgroundColor: CupertinoTheme.of(context).barBackgroundColor.withOpacity(0.7), // Make slightly transparent
             border: null, // Remove bottom border for cleaner look
          )
        : AppBar(
            title: Text('CuseFoodShare - Food Posts'),
            actions: [
              IconButton(
                icon: Icon(isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round),
                tooltip: 'Toggle Theme',
                onPressed: () => themeNotifier.toggleTheme(!isDarkMode),
              ),
              IconButton(
                icon: Icon(Icons.person_outline),
                tooltip: 'My Profile',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen())),
              ),
              IconButton(
                icon: Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async => await authViewModel.signOut(),
              ),
            ],
          );

    // Platform-specific Scaffold/PageScaffold
    return Platform.isIOS
      ? CupertinoPageScaffold(
          navigationBar: appBar as ObstructingPreferredSizeWidget, // Cast needed
          child: _buildBody(context, homeViewModel), // Pass context here
        )
      : Scaffold(
          appBar: appBar,
          body: _buildBody(context, homeViewModel), // Pass context here
          floatingActionButton: FloatingActionButton.extended( // Only for Material
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePostScreen())),
            label: Text('Post Food'),
            icon: Icon(Icons.add_outlined),
          ),
        );
  }

  // Extracted body builder for reuse
  Widget _buildBody(BuildContext context, HomeViewModel homeViewModel) { // Added context parameter
     return StreamBuilder<List<FoodPost>>(
        stream: homeViewModel.allPosts, // Use the updated stream name
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Use platform-specific loading indicator
            return Center(child: Platform.isIOS ? CupertinoActivityIndicator(radius: 15) : CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error in stream: ${snapshot.error}");
            return Center(child: Text('Error loading posts: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(
                    'No food posts available right now.\nBe the first to share!',
                     textAlign: TextAlign.center,
                     style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)), // Use theme color
                )
            );
          }

          final posts = snapshot.data!;

          // Use CupertinoScrollbar on iOS
          // Add SafeArea to prevent list items going under status bar/nav bar visually
          final Widget listView = ListView.builder(
             // Add padding to avoid content going under navigation bar on iOS when bouncing
             // Let SafeArea handle top padding
             padding: Platform.isIOS
                ? EdgeInsets.only(bottom: 8, left: 8, right: 8)
                : EdgeInsets.all(8.0),
             itemCount: posts.length,
             itemBuilder: (context, index) {
               return PostListItem(post: posts[index]);
             },
           );

          return SafeArea( // Add SafeArea here
              child: Platform.isIOS
                  ? CupertinoScrollbar(child: listView)
                  : listView,
          );
        },
      );
  }
}