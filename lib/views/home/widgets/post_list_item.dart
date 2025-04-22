import 'package:flutter/material.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/views/post/post_details_screen.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter/cupertino.dart'; // For CupertinoPageRoute
import 'dart:io'; // For Platform check

class PostListItem extends StatelessWidget {
  final FoodPost post;

  const PostListItem({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, h:mm a').format(post.timestamp.toDate());
    final bool isAvailable = post.isAvailable;
    final Color statusColor = isAvailable ? (Platform.isIOS ? CupertinoColors.activeGreen : Colors.green.shade500) : (Platform.isIOS ? CupertinoColors.systemRed : Colors.red.shade500);
    final Color cardBackgroundColor = Platform.isIOS
        ? CupertinoTheme.of(context).barBackgroundColor // Use bar background for iOS cards for a distinct look
        : Theme.of(context).cardColor;

    final Widget content = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Thumbnail with Hero Animation
          Hero(
            tag: 'postImage_${post.id}', // Unique tag for Hero animation
            child: ClipRRect(
               borderRadius: BorderRadius.circular(8.0),
               child: Image.network(
                  post.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                        width: 80, height: 80, color: Theme.of(context).colorScheme.secondaryContainer, // Use theme color
                        child: Center(child: Platform.isIOS ? CupertinoActivityIndicator(radius: 10) : CircularProgressIndicator(strokeWidth: 2.0))
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                        width: 80, height: 80, color: Theme.of(context).colorScheme.secondaryContainer,
                        child: Icon(Platform.isIOS ? CupertinoIcons.photo : Icons.broken_image_outlined, color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.5))
                    );
                  },
                ),
            ),
          ),
          SizedBox(width: 15),
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.foodName,
                  style: Platform.isIOS
                      ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 17)
                      : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Use theme text style
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Row( // Row for location and status dot
                  children: [
                     Icon(Platform.isIOS ? CupertinoIcons.location_solid : Icons.location_on_outlined, size: 16, color: Theme.of(context).hintColor),
                     SizedBox(width: 4),
                     Expanded( // Allow location text to take space but ellipsis if needed
                       child: Text(
                        post.locationText,
                         style: Platform.isIOS
                            ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontSize: 15)
                            : Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                       ),
                     ),
                     SizedBox(width: 8), // Space before dot
                     // Status Indicator Dot
                     Container(
                       margin: const EdgeInsets.only(top: 2), // Align dot slightly better
                       width: 10,
                       height: 10,
                       decoration: BoxDecoration(
                         color: statusColor,
                         shape: BoxShape.circle,
                         boxShadow: [ // Add a subtle shadow for depth
                            BoxShadow(
                              color: statusColor.withOpacity(0.5),
                              blurRadius: 3.0,
                              spreadRadius: 0.5,
                            )
                          ]
                       ),
                     ),
                  ],
                ),
                 SizedBox(height: 3),
                Text(
                  'By: ${post.userName}', // Shortened label
                  style: Platform.isIOS
                      ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(fontSize: 13)
                      : Theme.of(context).textTheme.bodySmall,
                   maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                 SizedBox(height: 3),
                 Text(
                  formattedDate,
                   style: Platform.isIOS
                      ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(fontSize: 13)
                      : Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Optional: Chevron might look better on iOS
          if (Platform.isIOS)
             Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey2, size: 20),
        ],
      ),
    );

    if (Platform.isIOS) {
        // Use a simpler container for iOS list items
        return GestureDetector(
            onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => PostDetailsScreen(post: post))),
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                decoration: BoxDecoration(
                    color: cardBackgroundColor,
                    borderRadius: BorderRadius.circular(12.0),
                ),
                child: content,
            ),
        );
    } else {
        // Use Material Card
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailsScreen(post: post))),
            child: content,
          ),
        );
    }
  }
}