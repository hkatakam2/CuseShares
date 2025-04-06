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
// import 'package:shimmer/shimmer.dart'; // Optional: for loading shimmer

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
                 CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(isDarkMode ? CupertinoIcons.sun_max : CupertinoIcons.moon_stars, size: 24),
                  onPressed: () => themeNotifier.toggleTheme(!isDarkMode),
                ),
                SizedBox(width: 8), // Adjust spacing
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(CupertinoIcons.square_arrow_right, size: 24),
                  onPressed: () async => await authViewModel.signOut(),
                ),
              ],
            ),
          )
        : AppBar(
            title: Text('CuseFoodShare - Food Posts'),
            // backgroundColor: Colors.orange[800], // Set in theme
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
          child: _buildBody(context, homeViewModel),
        )
      : Scaffold(
          appBar: appBar,
          body: _buildBody(context, homeViewModel),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePostScreen())),
            label: Text('Post Food'),
            icon: Icon(Icons.add_outlined),
            // backgroundColor: Colors.orange[700], // Set in theme
          ),
        );
  }

  // Extracted body builder for reuse
  Widget _buildBody(BuildContext context, HomeViewModel homeViewModel) {
     return StreamBuilder<List<FoodPost>>(
        stream: homeViewModel.allPosts, // Use the updated stream name
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Optional: Show shimmer loading effect
            // return _buildLoadingShimmer();
            return Center(child: Platform.isIOS ? CupertinoActivityIndicator() : CircularProgressIndicator());
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
          final Widget listView = ListView.builder(
            padding: EdgeInsets.all(8.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              // Pass the full post object to the list item
              return PostListItem(post: posts[index]);
            },
          );

          return Platform.isIOS
            ? CupertinoScrollbar(child: listView)
            : listView;

          // TODO: Add RefreshIndicator for pull-to-refresh
          // return RefreshIndicator(
          //   onRefresh: () => homeViewModel.refreshPosts(), // Implement refreshPosts in ViewModel
          //   child: Platform.isIOS ? CupertinoScrollbar(child: listView) : listView,
          // );
        },
      );
  }

  // Optional: Shimmer loading widget
  // Widget _buildLoadingShimmer() {
  //   return Shimmer.fromColors(
  //     baseColor: Colors.grey[300]!,
  //     highlightColor: Colors.grey[100]!,
  //     child: ListView.builder(
  //       itemCount: 6, // Number of shimmer items
  //       itemBuilder: (_, __) => Padding(
  //         padding: const EdgeInsets.all(12.0),
  //         child: Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Container(width: 80.0, height: 80.0, color: Colors.white),
  //             const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0)),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: <Widget>[
  //                   Container(width: double.infinity, height: 12.0, color: Colors.white),
  //                   const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
  //                   Container(width: double.infinity, height: 10.0, color: Colors.white),
  //                   const Padding(padding: EdgeInsets.symmetric(vertical: 3.0)),
  //                   Container(width: 100.0, height: 8.0, color: Colors.white),
  //                 ],
  //               ),
  //             )
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}