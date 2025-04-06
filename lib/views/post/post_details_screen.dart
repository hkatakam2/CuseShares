
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cusefoodshare_app/models/food_post.dart';
import 'package:cusefoodshare_app/models/chat_message.dart'; // Import Chat
import 'package:cusefoodshare_app/viewmodels/post_details_viewmodel.dart';
import 'package:cusefoodshare_app/repositories/post_repository.dart';
import 'package:cusefoodshare_app/viewmodels/auth_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import Maps
import 'package:url_launcher/url_launcher.dart'; // Import URL Launcher

class PostDetailsScreen extends StatefulWidget {
  final FoodPost post;

  const PostDetailsScreen({Key? key, required this.post}) : super(key: key);

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
   final TextEditingController _chatController = TextEditingController();
   final ScrollController _scrollController = ScrollController(); // To scroll chat list

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Launch Directions ---
  Future<void> _launchDirections(BuildContext context, FoodPost post) async {
    if (post.coordinates == null) {
      _showPlatformSnackbar(context, "Location coordinates not available for this post.", isError: true);
      return;
    }

    final lat = post.coordinates!.latitude;
    final lon = post.coordinates!.longitude;
    final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving";
    // Apple Maps URL Scheme
    final String appleMapsUrl = "http://maps.apple.com/?daddr=$lat,$lon&dirflg=d";

    Uri? uri;
    if (Platform.isIOS) {
      uri = Uri.parse(appleMapsUrl); // Prefer Apple Maps on iOS
    } else {
      uri = Uri.parse(googleMapsUrl); // Prefer Google Maps on Android
    }

     try {
        if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
            // Fallback to Google Maps web if native fails (less likely for maps)
            uri = Uri.parse(googleMapsUrl);
             if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
             } else {
                throw 'Could not launch $uri';
             }
        }
     } catch (e) {
         print("Could not launch maps: $e");
         _showPlatformSnackbar(context, "Could not open maps application.", isError: true);
     }
  }

  // --- Send Chat Message ---
  void _sendChatMessage(PostDetailsViewModel viewModel) {
     if (_chatController.text.trim().isNotEmpty) {
        viewModel.sendChatMessage(_chatController.text.trim()).then((success) {
           if (success) {
              _chatController.clear();
              // Scroll to bottom/top after sending (depending on list order)
              // Since it's descending (latest first), scroll to top
              WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                     _scrollController.animateTo(
                         0.0, // Scroll to top
                         duration: Duration(milliseconds: 300),
                         curve: Curves.easeOut,
                     );
                  }
              });
           }
           // Error message is handled by the ViewModel listener
        });
     }
  }


  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMM d, yyyy \'at\' h:mm a').format(widget.post.timestamp.toDate());
    final currentUser = Provider.of<AuthViewModel>(context, listen: false).user;
    final bool isPostOwner = currentUser?.uid == widget.post.userId;

    return ChangeNotifierProvider<PostDetailsViewModel>(
      create: (context) => PostDetailsViewModel(
        postRepository: Provider.of<PostRepository>(context, listen: false),
        post: widget.post, // Pass the initial post data
      ),
      child: Consumer<PostDetailsViewModel>(
        builder: (context, viewModel, child) {
          // Show messages based on status
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (viewModel.status == PostDetailsStatus.success) {
              _showPlatformSnackbar(context, 'Post status updated!', isError: false);
              viewModel.resetStatus();
            } else if (viewModel.status == PostDetailsStatus.error && viewModel.errorMessage != null) {
              _showPlatformSnackbar(context, 'Error: ${viewModel.errorMessage}', isError: true);
              viewModel.resetStatus();
            }
          });

          final currentPostState = viewModel.post;
          final bool isAvailable = currentPostState.isAvailable;
          final Color statusColor = isAvailable ? Colors.green.shade600 : Colors.red.shade600;

          final Widget body = CustomScrollView( // Use CustomScrollView for better control with map/chat
            controller: _scrollController, // Attach scroll controller
            slivers: <Widget>[
              // --- Image Header ---
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true, // Keep AppBar visible when scrolling up
                stretch: true, // Allow stretch effect
                backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Match background
                flexibleSpace: FlexibleSpaceBar(
                  // title: Text(currentPostState.foodName, style: TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 2.0)])), // Title can be distracting here
                  background: Hero(
                     tag: 'postImage_${currentPostState.id}', // Match tag from list item
                     child: Image.network(
                      currentPostState.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(color: Theme.of(context).colorScheme.surfaceVariant, child: Center(child: Platform.isIOS ? CupertinoActivityIndicator() : CircularProgressIndicator()));
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Theme.of(context).colorScheme.surfaceVariant, child: Icon(Platform.isIOS ? CupertinoIcons.photo : Icons.broken_image_outlined, size: 60, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)));
                      },
                    ),
                  ),
                   stretchModes: [StretchMode.zoomBackground],
                ),
                 // Custom leading back button for better visibility over image
                 leading: Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: CircleAvatar(
                     backgroundColor: Colors.black.withOpacity(0.4),
                     child: IconButton(
                       icon: Icon(Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back, color: Colors.white),
                       onPressed: () => Navigator.of(context).pop(),
                     ),
                   ),
                 ),
              ),

              // --- Details Section ---
              SliverPadding(
                 padding: const EdgeInsets.all(16.0),
                 sliver: SliverList(
                    delegate: SliverChildListDelegate([
                       // Title
                       Text(
                          currentPostState.foodName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                       ),
                       SizedBox(height: 10),

                       // Location Text & Status Chip
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.center,
                         children: [
                           Icon(Platform.isIOS ? CupertinoIcons.location_solid : Icons.location_on, size: 18, color: Theme.of(context).hintColor),
                           SizedBox(width: 8),
                           Expanded(
                             child: Text(
                               currentPostState.locationText,
                               style: Theme.of(context).textTheme.titleMedium,
                             ),
                           ),
                           SizedBox(width: 10),
                           Chip(
                              label: Text(
                                isAvailable ? 'AVAILABLE' : 'FINISHED',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: statusColor,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Smaller tap target
                           ),
                         ],
                       ),
                       SizedBox(height: 8),

                       // User and Time
                       Row(
                         children: [
                           Icon(Platform.isIOS ? CupertinoIcons.person : Icons.person_outline, size: 16, color: Theme.of(context).hintColor),
                           SizedBox(width: 8),
                           Text('By: ${currentPostState.userName}', style: Theme.of(context).textTheme.bodySmall),
                           Spacer(), // Push time to the right
                           Icon(Platform.isIOS ? CupertinoIcons.clock : Icons.access_time_outlined, size: 16, color: Theme.of(context).hintColor),
                           SizedBox(width: 4),
                           Text(formattedDate, style: Theme.of(context).textTheme.bodySmall),
                         ],
                       ),
                       SizedBox(height: 16),

                       // Description
                       Text('Description:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                       SizedBox(height: 5),
                       Text(currentPostState.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4)),
                       SizedBox(height: 20),

                       // --- Map Preview & Directions ---
                       if (currentPostState.coordinates != null) ...[
                          Text('Location Map:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Container(
                             height: 150,
                             decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Theme.of(context).dividerColor)
                             ),
                             child: ClipRRect( // Clip the map to rounded corners
                                borderRadius: BorderRadius.circular(10),
                                child: GoogleMap(
                                   initialCameraPosition: CameraPosition(
                                      target: LatLng(currentPostState.coordinates!.latitude, currentPostState.coordinates!.longitude),
                                      zoom: 15.5,
                                   ),
                                   markers: {
                                      Marker(
                                         markerId: MarkerId(currentPostState.id),
                                         position: LatLng(currentPostState.coordinates!.latitude, currentPostState.coordinates!.longitude),
                                         infoWindow: InfoWindow(title: currentPostState.foodName),
                                         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                                      )
                                   },
                                   scrollGesturesEnabled: false, // Disable map interaction in preview
                                   zoomGesturesEnabled: false,
                                   tiltGesturesEnabled: false,
                                   rotateGesturesEnabled: false,
                                   myLocationButtonEnabled: false,
                                   myLocationEnabled: false,
                                ),
                             ),
                          ),
                          SizedBox(height: 10),
                          Center(
                             child: Platform.isIOS
                               ? CupertinoButton(
                                   child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.location_north_fill, size: 18), SizedBox(width: 8), Text('Get Directions')]),
                                   onPressed: () => _launchDirections(context, currentPostState),
                                 )
                               : ElevatedButton.icon(
                                   icon: Icon(Icons.directions_outlined, size: 18),
                                   label: Text('Get Directions'),
                                   onPressed: () => _launchDirections(context, currentPostState),
                                   style: ElevatedButton.styleFrom(
                                      // Use theme accent color?
                                      // backgroundColor: Theme.of(context).colorScheme.secondary,
                                      // foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                   ),
                                 ),
                          ),
                          SizedBox(height: 20),
                       ], // End Map Section

                       // --- Action Button (Mark Finished/Available) ---
                       if (isPostOwner || isAvailable) // Show if owner OR if available (anyone can mark finished)
                          Center(
                             child: Platform.isIOS
                               ? CupertinoButton(
                                   color: isAvailable ? CupertinoColors.destructiveRed : CupertinoColors.activeGreen,
                                   child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                         if (viewModel.status == PostDetailsStatus.updating) CupertinoActivityIndicator(color: Colors.white) else Icon(isAvailable ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.gobackward, size: 20),
                                         SizedBox(width: 8),
                                         Text(isAvailable ? 'Mark as Finished' : 'Mark as Available'),
                                      ]
                                   ),
                                   onPressed: viewModel.status == PostDetailsStatus.updating ? null : () {
                                      if (isAvailable) {
                                         _showConfirmationDialog(context, viewModel.markAsFinished, 'Mark as Finished?', 'Are you sure this food is finished?');
                                      } else if (isPostOwner) { // Only owner can mark available again
                                         viewModel.markAsAvailable();
                                      }
                                   },
                                 )
                               : ElevatedButton.icon(
                                   icon: viewModel.status == PostDetailsStatus.updating
                                      ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                                      : Icon(isAvailable ? Icons.check_circle_outline : Icons.published_with_changes_outlined),
                                   label: Text(isAvailable ? 'Mark as Finished' : 'Mark as Available'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: isAvailable ? Colors.red[700] : Colors.green[700],
                                     foregroundColor: Colors.white,
                                     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                   ),
                                   onPressed: viewModel.status == PostDetailsStatus.updating ? null : () {
                                      if (isAvailable) {
                                         _showConfirmationDialog(context, viewModel.markAsFinished, 'Mark as Finished?', 'Are you sure this food is finished?');
                                      } else if (isPostOwner) { // Only owner can mark available again
                                          viewModel.markAsAvailable();
                                      }
                                   },
                                 ),
                          ),
                       SizedBox(height: 24),

                       Divider(),
                       SizedBox(height: 10),
                       Text('Updates & Comments', style: Theme.of(context).textTheme.titleLarge),
                       SizedBox(height: 10),
                    ]),
                 ),
              ),

              // --- Chat Messages List ---
              SliverPadding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
                 sliver: viewModel.messages.isEmpty
                   ? SliverToBoxAdapter(child: Center(child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 20.0),
                       child: Text('No updates yet.', style: TextStyle(color: Theme.of(context).hintColor)),
                     )))
                   : SliverList(
                       delegate: SliverChildBuilderDelegate(
                         (context, index) {
                           final message = viewModel.messages[index];
                           final bool isMyMessage = message.userId == currentUser?.uid;
                           return _buildChatMessageItem(context, message, isMyMessage);
                         },
                         childCount: viewModel.messages.length,
                       ),
                     ),
              ),
               // Add some bottom padding
               SliverPadding(padding: EdgeInsets.only(bottom: 80)), // Space for input field
            ],
          );

          // --- Main Scaffold Structure ---
          return Platform.isIOS
            ? CupertinoPageScaffold(
                // navigationBar handled by SliverAppBar
                child: Stack( // Use stack to overlay chat input
                   children: [
                      body,
                      Positioned(
                         bottom: 0,
                         left: 0,
                         right: 0,
                         child: _buildChatInput(context, viewModel),
                      )
                   ]
                ),
              )
            : Scaffold(
                 // appBar handled by SliverAppBar
                 body: Stack( // Use stack to overlay chat input
                   children: [
                      body,
                       Positioned(
                         bottom: 0,
                         left: 0,
                         right: 0,
                         child: _buildChatInput(context, viewModel),
                      )
                   ]
                ),
              );
        },
      ),
    );
  }

   // --- Build Chat Message Item ---
  Widget _buildChatMessageItem(BuildContext context, ChatMessage message, bool isMyMessage) {
     final alignment = isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;
     final color = isMyMessage ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceVariant;
     final textColor = Theme.of(context).textTheme.bodyMedium?.color;
     final timeFormat = DateFormat('h:mm a');

     return Container(
       margin: EdgeInsets.symmetric(vertical: 4.0),
       child: Column(
         crossAxisAlignment: alignment,
         children: [
           // Optional: Display name for other users' messages
           if (!isMyMessage)
             Padding(
               padding: const EdgeInsets.only(bottom: 2.0, left: 5, right: 5),
               child: Text(message.userName, style: Theme.of(context).textTheme.labelSmall),
             ),
           ConstrainedBox(
             constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), // Max width for bubble
             child: Container(
               padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
               decoration: BoxDecoration(
                 color: color,
                 borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: isMyMessage ? Radius.circular(12) : Radius.circular(0),
                    bottomRight: isMyMessage ? Radius.circular(0) : Radius.circular(12),
                 )
               ),
               child: Text(message.text, style: TextStyle(color: textColor)),
             ),
           ),
            Padding(
               padding: const EdgeInsets.only(top: 3.0, left: 5, right: 5),
               child: Text(timeFormat.format(message.timestamp.toDate()), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
             ),
         ],
       ),
     );
  }


  // --- Build Chat Input Field ---
  Widget _buildChatInput(BuildContext context, PostDetailsViewModel viewModel) {
     final bool isSending = viewModel.status == PostDetailsStatus.sendingMessage;

     // Need Material ancestor for TextField decoration theme
     return Material(
        elevation: 8.0, // Add elevation to lift it above content
        color: Theme.of(context).cardColor, // Use card color for background
        child: Padding(
          padding: EdgeInsets.only(
              left: 12.0,
              right: 8.0,
              top: 8.0,
              bottom: MediaQuery.of(context).padding.bottom + 8.0 // Adjust for safe area
          ),
          child: Row(
            children: [
              Expanded(
                child: Platform.isIOS
                  ? CupertinoTextField(
                      controller: _chatController,
                      placeholder: 'Type an update...',
                      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send, // Doesn't directly trigger send on iOS keyboard
                      onSubmitted: (_) => _sendChatMessage(viewModel), // Trigger on keyboard 'done'
                      decoration: BoxDecoration(
                          border: Border.all(color: CupertinoColors.systemGrey4),
                          borderRadius: BorderRadius.circular(18.0),
                      ),
                    )
                  : TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: 'Type an update...',
                        filled: true,
                        // fillColor: Theme.of(context).colorScheme.surfaceVariant, // Use theme color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none, // Remove default border
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendChatMessage(viewModel), // Trigger on keyboard send
                    ),
              ),
              SizedBox(width: 8.0),
              // Send Button (Platform Aware)
              Platform.isIOS
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: isSending ? CupertinoActivityIndicator() : Icon(CupertinoIcons.arrow_up_circle_fill, size: 30),
                    onPressed: isSending ? null : () => _sendChatMessage(viewModel),
                  )
                : IconButton(
                    icon: isSending ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.send),
                    onPressed: isSending ? null : () => _sendChatMessage(viewModel),
                    color: Theme.of(context).primaryColor,
                  ),
            ],
          ),
        ),
     );
  }

   // --- Helper for Confirmation Dialog --- (Platform Aware)
  Future<void> _showConfirmationDialog(BuildContext context, Function onConfirm, String title, String content) async {
     if (Platform.isIOS) {
        await showCupertinoDialog(
           context: context,
           builder: (ctx) => CupertinoAlertDialog(
              title: Text(title),
              content: Text(content),
              actions: <Widget>[
                 CupertinoDialogAction(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(),
                 ),
                 CupertinoDialogAction(
                    isDestructiveAction: true, // Make it red for destructive actions
                    child: Text('Confirm'),
                    onPressed: () {
                       Navigator.of(ctx).pop();
                       onConfirm();
                    },
                 ),
              ],
           ),
        );
     } else {
        await showDialog(
           context: context,
           builder: (ctx) => AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: <Widget>[
                 TextButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(),
                 ),
                 TextButton(
                    child: Text('Confirm', style: TextStyle(color: Colors.red)),
                    onPressed: () {
                       Navigator.of(ctx).pop();
                       onConfirm();
                    },
                 ),
              ],
           ),
        );
     }
  }

   // --- Helper for Platform Snackbar ---
  void _showPlatformSnackbar(BuildContext context, String message, {bool isError = false}) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message),
              backgroundColor: isError ? Colors.redAccent : Colors.green,
              behavior: SnackBarBehavior.floating,
          )
       );
  }

}
