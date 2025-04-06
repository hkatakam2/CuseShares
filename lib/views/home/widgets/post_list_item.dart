import 'package:flutter/material.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/views/post/post_details_screen.dart';
import 'package:intl/intl.dart'; // For date formatting

class PostListItem extends StatelessWidget {
  final FoodPost post;

  const PostListItem({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format the timestamp
    final formattedDate = DateFormat('MMM d, h:mm a').format(post.timestamp.toDate());

    return Card(
      elevation: 3.0,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell( // Make the whole card tappable
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailsScreen(post: post), // Pass the post object
            ),
          );
        },
        borderRadius: BorderRadius.circular(10.0), // Match card shape
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail
              ClipRRect(
                 borderRadius: BorderRadius.circular(8.0),
                 child: Image.network(
                    post.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    // Add error and loading builders for robustness
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2.0))
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey[400])
                      );
                    },
                  ),
              ),
              SizedBox(width: 15),
              // Text Details (Expanded to take available space)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.foodName,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Location: ${post.location}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                       maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                     SizedBox(height: 3),
                    Text(
                      'Posted by: ${post.userName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                       maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                     SizedBox(height: 3),
                     Text(
                      'Time: $formattedDate',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
               // Optional: Add a small indicator if needed (e.g., distance, new)
               // Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
