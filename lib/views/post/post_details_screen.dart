import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cuse_food_share_app/models/food_post.dart';
import 'package:cuse_food_share_app/models/chat_message.dart'; // Import Chat
import 'package:cuse_food_share_app/models/app_user.dart'; // Import AppUser
import 'package:cuse_food_share_app/viewmodels/post_details_viewmodel.dart';
import 'package:cuse_food_share_app/repositories/post_repository.dart';
import 'package:cuse_food_share_app/viewmodels/auth_viewmodel.dart';
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
    // Universal Map Link (works on both platforms)
    final String mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
    // Apple Maps specific URL
    // final String appleMapsUrl = 'http://maps.apple.com/?daddr=$lat,$lon&dirflg=d';

    Uri uri = Uri.parse(mapsUrl);

     try {
        if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
           throw 'Could not launch $uri';
        }
     } catch (e) {
         print("Could not launch maps: $e");
         _showPlatformSnackbar(context, "Could not open maps application.", isError: true);
     }
  }

  // --- Send Chat Message ---
  void _sendChatMessage(PostDetailsViewModel viewModel) {
     if (_chatController.text.trim().isNotEmpty) {
        FocusScope.of(context).unfocus(); // Dismiss keyboard
        viewModel.sendChatMessage(_chatController.text.trim()).then((success) {
           if (success) {
              _chatController.clear();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                     _scrollController.animateTo(
                         0.0,
                         duration: Duration(milliseconds: 300),
                         curve: Curves.easeOut,
                     );
                  }
              });
           }
        });
     }
  }


  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMM d, archetype \'at\' h:mm a').format(widget.post.timestamp.toDate()); // More detailed date
    final currentUser = Provider.of<AuthViewModel>(context, listen: false).user;
    final bool isPostOwner = currentUser?.uid == widget.post.userId;

    return ChangeNotifierProvider<PostDetailsViewModel>(
      create: (context) => PostDetailsViewModel(
        postRepository: Provider.of<PostRepository>(context, listen: false),
        post: widget.post,
      ),
      child: Consumer<PostDetailsViewModel>(
        builder: (context, viewModel, child) {
          // Show messages based on status
          WidgetsBinding.instance.addPostFrameCallback((_) {
             if (!mounted) return; // Check if mounted
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
          final Color statusColor = isAvailable ? (Platform.isIOS ? CupertinoColors.activeGreen : Colors.green.shade600) : (Platform.isIOS ? CupertinoColors.systemRed : Colors.red.shade600);

          // --- Body Content ---
          final Widget bodyContent = CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              // --- Image Header (SliverAppBar for collapsing effect) ---
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                stretch: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                     tag: 'postImage_${currentPostState.id}',
                     child: Image.network(
                      currentPostState.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : Container(color: Theme.of(context).colorScheme.surfaceVariant, child: Center(child: Platform.isIOS ? CupertinoActivityIndicator() : CircularProgressIndicator())),
                      errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).colorScheme.surfaceVariant, child: Icon(Platform.isIOS ? CupertinoIcons.photo : Icons.broken_image_outlined, size: 60, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5))),
                    ),
                  ),
                   stretchModes: [StretchMode.zoomBackground],
                ),
                 leading: Padding( // Custom back button
                   padding: const EdgeInsets.all(8.0),
                   child: CircleAvatar(
                     backgroundColor: Colors.black.withOpacity(0.4),
                     child: IconButton(
                       icon: Icon(Platform.isIOS ? CupertinoIcons.chevron_back : Icons.arrow_back, color: Colors.white),
                       onPressed: () => Navigator.of(context).pop(),
                     ),
                   ),
                 ),
                  // No title in SliverAppBar itself, title shown below
              ),

              // --- Details Section ---
              SliverPadding(
                 padding: const EdgeInsets.all(16.0),
                 sliver: SliverList(
                    delegate: SliverChildListDelegate([
                       // Title
                       Text(
                          currentPostState.foodName,
                          style: Platform.isIOS
                             ? CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color) // Use large title style for iOS
                             : Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                               style: Platform.isIOS
                                  ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontSize: 17)
                                  : Theme.of(context).textTheme.titleMedium,
                             ),
                           ),
                           SizedBox(width: 10),
                           _buildStatusChip(context, isAvailable, statusColor),
                         ],
                       ),
                       SizedBox(height: 8),

                       // User and Time
                       Row(
                         children: [
                           Icon(Platform.isIOS ? CupertinoIcons.person_alt_circle : Icons.person_outline, size: 16, color: Theme.of(context).hintColor),
                           SizedBox(width: 8),
                           Text('By: ${currentPostState.userName}', style: Platform.isIOS ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle : Theme.of(context).textTheme.bodySmall),
                           Spacer(),
                           Icon(Platform.isIOS ? CupertinoIcons.clock : Icons.access_time_outlined, size: 16, color: Theme.of(context).hintColor),
                           SizedBox(width: 4),
                           Text(formattedDate, style: Platform.isIOS ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle : Theme.of(context).textTheme.bodySmall),
                         ],
                       ),
                       SizedBox(height: 16),

                       // Description
                       Text('Description:', style: Platform.isIOS ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600) : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                       SizedBox(height: 5),
                       Text(currentPostState.description, style: Platform.isIOS ? CupertinoTheme.of(context).textTheme.textStyle : Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4)),
                       SizedBox(height: 20),

                       // --- Map Preview & Directions ---
                       if (currentPostState.coordinates != null) ...[
                          Text('Location Map:', style: Platform.isIOS ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600) : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          _buildMapPreview(context, currentPostState),
                          SizedBox(height: 10),
                          Center(child: _buildDirectionsButton(context, currentPostState)),
                          SizedBox(height: 20),
                       ],

                       // --- Action Button (Mark Finished/Available) ---
                       if (isPostOwner || isAvailable)
                          Center(child: _buildActionButton(context, viewModel, isAvailable, isPostOwner)),
                       SizedBox(height: 24),

                       Divider(),
                       SizedBox(height: 10),
                       Text('Updates & Comments', style: Platform.isIOS ? CupertinoTheme.of(context).textTheme.navTitleTextStyle : Theme.of(context).textTheme.titleLarge),
                       SizedBox(height: 10),
                    ]),
                 ),
              ),

              // --- Chat Messages List ---
              SliverPadding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
                 sliver: _buildChatList(context, viewModel, currentUser),
              ),
               // Add bottom padding to ensure content scrolls above input field
               SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );

          // --- Main Scaffold Structure ---
          return Platform.isIOS
            ? CupertinoPageScaffold(
                // navigationBar handled by SliverAppBar
                child: GestureDetector( // Dismiss keyboard on tap outside input
                   onTap: () => FocusScope.of(context).unfocus(),
                   child: Stack(
                     children: [
                        bodyContent,
                        Positioned(bottom: 0, left: 0, right: 0, child: _buildChatInput(context, viewModel))
                     ]
                   ),
                ),
              )
            : Scaffold(
                 // appBar handled by SliverAppBar
                 body: GestureDetector( // Dismiss keyboard on tap outside input
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Stack(
                      children: [
                         bodyContent,
                         Positioned(bottom: 0, left: 0, right: 0, child: _buildChatInput(context, viewModel))
                      ]
                    ),
                 ),
              );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildStatusChip(BuildContext context, bool isAvailable, Color statusColor) {
    return Chip(
      label: Text(
        isAvailable ? 'AVAILABLE' : 'FINISHED',
        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      backgroundColor: statusColor,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact, // Make chip smaller
    );
  }

  Widget _buildMapPreview(BuildContext context, FoodPost post) {
     // Update map style based on theme
     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
     final String? mapStyle = isDarkMode ? null : null; // Add dark style JSON string if available

     return Container(
       height: 150,
       decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(10),
         border: Border.all(color: Theme.of(context).dividerColor)
       ),
       child: ClipRRect(
         borderRadius: BorderRadius.circular(10),
         child: GoogleMap(
           initialCameraPosition: CameraPosition(
             target: LatLng(post.coordinates!.latitude, post.coordinates!.longitude),
             zoom: 15.5,
           ),
           markers: {
             Marker(
               markerId: MarkerId(post.id),
               position: LatLng(post.coordinates!.latitude, post.coordinates!.longitude),
               infoWindow: InfoWindow(title: post.foodName),
               icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
             )
           },
           scrollGesturesEnabled: false, zoomGesturesEnabled: false,
           tiltGesturesEnabled: false, rotateGesturesEnabled: false,
           myLocationButtonEnabled: false, myLocationEnabled: false,
           mapToolbarEnabled: false, // Hide toolbar
           style: mapStyle, // Apply dark/light style
         ),
       ),
     );
  }

  Widget _buildDirectionsButton(BuildContext context, FoodPost post) {
     return Platform.isIOS
       ? CupertinoButton(
           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.location_north_fill, size: 18), SizedBox(width: 8), Text('Get Directions')]),
           onPressed: () => _launchDirections(context, post),
         )
       : ElevatedButton.icon(
           icon: Icon(Icons.directions_outlined, size: 18),
           label: Text('Get Directions'),
           onPressed: () => _launchDirections(context, post),
           style: ElevatedButton.styleFrom(
             padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
             textStyle: TextStyle(fontSize: 14), // Slightly smaller text
           ),
         );
  }

  Widget _buildActionButton(BuildContext context, PostDetailsViewModel viewModel, bool isAvailable, bool isPostOwner) {
     final bool canMarkAvailable = !isAvailable && isPostOwner;
     final bool canMarkFinished = isAvailable; // Anyone can mark finished

     if (!canMarkAvailable && !canMarkFinished) return SizedBox.shrink(); // Hide if nothing to do

     final String text = isAvailable ? 'Mark as Finished' : 'Mark as Available';
     final IconData materialIcon = isAvailable ? Icons.check_circle_outline : Icons.published_with_changes_outlined;
     final IconData cupertinoIcon = isAvailable ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.gobackward;
     final Color materialColor = isAvailable ? Colors.red[700]! : Colors.green[700]!;
     final Color cupertinoColor = isAvailable ? CupertinoColors.destructiveRed : CupertinoColors.activeGreen;

     final VoidCallback? onPressed = viewModel.status == PostDetailsStatus.updating ? null : () {
        if (isAvailable) {
           _showConfirmationDialog(context, viewModel.markAsFinished, 'Mark as Finished?', 'Are you sure this food is finished?');
        } else if (canMarkAvailable) {
           viewModel.markAsAvailable();
        }
     };

     return Platform.isIOS
       ? CupertinoButton(
           color: cupertinoColor,
           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
           child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 if (viewModel.status == PostDetailsStatus.updating) CupertinoActivityIndicator(color: Colors.white) else Icon(cupertinoIcon, size: 20, color: Colors.white),
                 SizedBox(width: 8),
                 Text(text, style: TextStyle(color: Colors.white)),
              ]
           ),
           onPressed: onPressed,
         )
       : ElevatedButton.icon(
           icon: viewModel.status == PostDetailsStatus.updating
              ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
              : Icon(materialIcon),
           label: Text(text),
           style: ElevatedButton.styleFrom(
             backgroundColor: materialColor,
             foregroundColor: Colors.white,
             padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
           ),
           onPressed: onPressed,
         );
  }

   Widget _buildChatList(BuildContext context, PostDetailsViewModel viewModel, AppUser? currentUser) {
       if (viewModel.messages.isEmpty) {
          return SliverToBoxAdapter(child: Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text('No updates yet.', style: TextStyle(color: Theme.of(context).hintColor)),
          )));
       }
       return SliverList(
         delegate: SliverChildBuilderDelegate(
           (context, index) {
             final message = viewModel.messages[index];
             final bool isMyMessage = message.userId == currentUser?.uid;
             return _buildChatMessageItem(context, message, isMyMessage);
           },
           childCount: viewModel.messages.length,
         ),
       );
   }


   // --- Build Chat Message Item ---
  Widget _buildChatMessageItem(BuildContext context, ChatMessage message, bool isMyMessage) {
     final alignment = isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;
     final bubbleAlignment = isMyMessage ? Alignment.centerRight : Alignment.centerLeft;
     final Color bubbleColor = isMyMessage
        ? (Platform.isIOS ? CupertinoColors.activeBlue : Theme.of(context).primaryColor)
        : (Platform.isIOS ? CupertinoColors.systemGrey5 : Theme.of(context).colorScheme.surfaceVariant);
     final Color textColor = isMyMessage
        ? Colors.white
        : (Platform.isIOS ? CupertinoTheme.of(context).textTheme.textStyle.color ?? CupertinoColors.black : Theme.of(context).textTheme.bodyMedium!.color!);
     final timeFormat = DateFormat('h:mm a');

     return Container(
       margin: EdgeInsets.symmetric(vertical: 4.0),
       alignment: bubbleAlignment, // Align the whole container
       child: Column(
         crossAxisAlignment: alignment, // Align text and time inside the bubble container
         children: [
           // Optional: Display name for other users' messages
           if (!isMyMessage)
             Padding(
               padding: const EdgeInsets.only(bottom: 3.0, left: 10, right: 10),
               child: Text(message.userName, style: Platform.isIOS ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(color: CupertinoColors.systemGrey) : Theme.of(context).textTheme.labelSmall),
             ),
           ConstrainedBox(
             constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
             child: Container(
               padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
               decoration: BoxDecoration(
                 color: bubbleColor,
                 borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                    bottomLeft: isMyMessage ? Radius.circular(15) : Radius.circular(3),
                    bottomRight: isMyMessage ? Radius.circular(3) : Radius.circular(15),
                 )
               ),
               child: Text(message.text, style: TextStyle(color: textColor, fontSize: 15)), // Slightly larger font
             ),
           ),
            Padding(
               padding: const EdgeInsets.only(top: 4.0, left: 10, right: 10),
               child: Text(timeFormat.format(message.timestamp.toDate()), style: Platform.isIOS ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(color: CupertinoColors.systemGrey, fontSize: 11) : Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
             ),
         ],
       ),
     );
  }


  // --- Build Chat Input Field ---
  Widget _buildChatInput(BuildContext context, PostDetailsViewModel viewModel) {
     final bool isSending = viewModel.status == PostDetailsStatus.sendingMessage;
     final Color inputBackgroundColor = Platform.isIOS
        ? CupertinoTheme.of(context).barBackgroundColor // Use bar background for iOS input
        : Theme.of(context).cardColor;

     // Use Material for consistent elevation and theming of the input bar background
     return Material(
        elevation: 8.0,
        color: inputBackgroundColor,
        child: Padding(
          padding: EdgeInsets.only(
              left: 12.0,
              right: 8.0,
              top: 8.0,
              // Adjust bottom padding for keyboard inset AND safe area
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 8.0
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end, // Align items to bottom
            children: [
              Expanded(
                child: Platform.isIOS
                  ? CupertinoTextField(
                      controller: _chatController,
                      placeholder: 'Type an update...',
                      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                      maxLines: 5, // Allow more lines
                      minLines: 1,
                      textInputAction: TextInputAction.newline, // Allow new lines
                      keyboardType: TextInputType.multiline,
                      decoration: BoxDecoration(
                          border: Border.all(color: CupertinoColors.systemGrey4),
                          borderRadius: BorderRadius.circular(18.0),
                          color: CupertinoTheme.of(context).scaffoldBackgroundColor, // Match background
                      ),
                    )
                  : TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: 'Type an update...',
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor, // Match background better
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor), // Add subtle border
                        ),
                         enabledBorder: OutlineInputBorder( // Consistent border
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder( // Highlight border on focus
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                      ),
                      maxLines: 5, // Allow more lines
                      minLines: 1,
                      textInputAction: TextInputAction.newline, // Allow new lines
                       keyboardType: TextInputType.multiline,
                    ),
              ),
              SizedBox(width: 8.0),
              // Send Button
              ValueListenableBuilder<TextEditingValue>( // Use builder to enable/disable button based on text
                 valueListenable: _chatController,
                 builder: (context, value, child) {
                    final bool canSend = value.text.trim().isNotEmpty;
                    return Platform.isIOS
                      ? CupertinoButton(
                          padding: EdgeInsets.only(left: 8, right: 4, bottom: 4), // Adjust padding
                          child: isSending ? CupertinoActivityIndicator() : Icon(CupertinoIcons.arrow_up_circle_fill, size: 30),
                          onPressed: isSending || !canSend ? null : () => _sendChatMessage(viewModel), // Disable if empty or sending
                        )
                      : IconButton(
                          icon: isSending ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.send),
                          onPressed: isSending || !canSend ? null : () => _sendChatMessage(viewModel), // Disable if empty or sending
                          color: canSend ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, // Change color when disabled
                          padding: EdgeInsets.only(bottom: 4), // Adjust padding
                        );
                 }
              ),
            ],
          ),
        ),
     );
  }

   // --- Helper for Confirmation Dialog --- (Platform Aware)
  Future<void> _showConfirmationDialog(BuildContext context, Function onConfirm, String title, String content) async {
     if (!mounted) return; // Check if mounted
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
                    isDestructiveAction: true,
                    child: Text('Confirm'),
                    onPressed: () { Navigator.of(ctx).pop(); onConfirm(); },
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
                 TextButton(child: Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
                 TextButton(child: Text('Confirm', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(ctx).pop(); onConfirm(); }),
              ],
           ),
        );
     }
  }

   // --- Helper for Platform Snackbar ---
  void _showPlatformSnackbar(BuildContext context, String message, {bool isError = false}) {
       if (!mounted) return; // Check if mounted
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message),
              backgroundColor: isError ? Colors.redAccent : Colors.green,
              behavior: SnackBarBehavior.floating,
          )
       );
  }

}
