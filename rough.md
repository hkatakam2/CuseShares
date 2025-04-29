
app icon


1. google sign in, app is crashing; just remove this method, I will just use the email and password based sign in
2. post_details_screen is not loading in iOS; The relevant error-causing widget was: SliverAppBar SliverAppBar:file:///Users/naga/Downloads/syracuse/iOS%20app/project/cuse_food_share_app/lib/views/post/post_de tails_screen.dart:119:15
3. in the create_post_screen when I am picking the location on the map, app is crashing. I am suspecting may be I have not specified some API key for using google maps in my app, but please tell me to solve this problem.
4. cloud functions are working in the .js version itself, so I am not using python version provided above. Just clarify the following functionality, when a user creates a new food post, all other users receive a notification on their devices
5. on the home_screen, I would like an option to filter out finished posts and see only avialable posts 

i created the post and I am getting the notification, its' everyone else that needs to get it.

colud functions are working in .js version itself. but 

long press/ slide left to delete?
persistence

dark mode
google maps integration


chat feature?


todo:
upload some food pictures
what are the device native features we are using? taking a photo, gps location;

cusefoodshare:
what are the advanced features?
theme, search, refresh, maps

may be i prefer BLoC architecure over the MVVM
fix google sign in

// - Search/filter logic
  // - Refresh mechanism (though stream handles updates)


  // lib/views/auth/login_screen.dart
// (Add platform adaptation for buttons/indicators if desired)
// ... (Keep previous LoginScreen code, potentially wrap buttons/indicators
//      with Platform.isIOS checks or use flutter_platform_widgets) ...
// Example for a button:
// Platform.isIOS
//   ? CupertinoButton.filled(child: Text('Login'), onPressed: ...)
//   : ElevatedButton(child: Text('Login'), onPressed: ...)
// Example for Activity Indicator:
// Platform.isIOS
//   ? CupertinoActivityIndicator()
//   : CircularProgressIndicator()


add sounds/ animations, badges

the content is not visible properly in iOS
when i click the map; app is crashing (catch errors, the app cannot crash)
google sign in still not working



