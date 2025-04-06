import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Define the channel (must match AndroidManifest.xml and Cloud Function if specified)
   final AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'new_food_channel', // id
      'New Food Alerts', // title
      description: 'Notifications for new food posts', // description
      importance: Importance.high,
    );

  Future<void> initialize() async {
    // Request permissions for iOS/Web
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Create the Android Notification Channel
     await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);


    // Initialize local notifications plugin
    // Use default Flutter icon for Android. Ensure you have 'app_icon' in drawable folders.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Or use specific icon name e.g. 'app_icon'
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            onDidReceiveLocalNotification: _onDidReceiveLocalNotification, // Handler for older iOS versions
        );
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse, // Handler for taps when app is background/terminated
    );

    // Set foreground notification presentation options for iOS/web
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );


    // Subscribe to the topic for new food posts
    await subscribeToNewFoodTopic();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground Message Received!');
      print('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      AppleNotification? apple = message.notification?.apple;

      // Display notification using flutter_local_notifications
      // Check if it has a notification payload
      if (notification != null) {
          print('Showing local notification from foreground message.');
           _flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: initializationSettingsAndroid.defaultIcon, // Use the same icon specified in settings
                  // other properties...
                ),
                 iOS: const DarwinNotificationDetails( // Basic iOS details
                    presentAlert: true,
                    presentBadge: true,
                    presentSound: true,
                 ),
              ),
              payload: message.data['postId'], // Pass postId as payload if available
           );
      }
    });

     // Handle background message taps (when app is opened from notification)
     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       print('Message clicked! Data: ${message.data}');
       _handleNotificationTap(message.data);
     });

     // Get initial message if app was terminated and opened from notification
     RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
     if (initialMessage != null) {
        print('Opened from terminated state via message. Data: ${initialMessage.data}');
        // Delay handling slightly to ensure Navigator is ready
        Future.delayed(Duration(milliseconds: 500), () {
            _handleNotificationTap(initialMessage.data);
        });
     }
  }

   // Handler for older iOS versions receiving foreground notifications
  void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, nav etc.
    print("iOS Foreground Notification (Old): $title - $body");
    // Optionally handle payload here if needed for older iOS
  }

  // Handler for notification taps (using flutter_local_notifications)
  void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      print('Local notification payload: $payload');
      // Assuming payload is the postId
      _handleNotificationTap({'postId': payload});
    }
     // Handle action taps if defined
     // if (notificationResponse.actionId == '...') { ... }
  }

  // Centralized handler for notification taps
  void _handleNotificationTap(Map<String, dynamic> data) {
     final String? postId = data['postId'];
     if (postId != null) {
        print("Handling tap, navigating to post ID: $postId");
        // TODO: Implement navigation logic
        // You'll need access to a Navigator key or pass BuildContext
        // Example (using a global navigator key):
        // GlobalNavigator.key.currentState?.push(MaterialPageRoute(builder: (_) => PostDetailsScreenFromNotification(postId: postId)));
     } else {
        print("Notification tapped, but no postId found in data.");
     }
  }


  // Subscribe to the 'new_food' topic
  Future<void> subscribeToNewFoodTopic() async {
    try {
      await _firebaseMessaging.subscribeToTopic('new_food');
      print("Subscribed to new_food topic");
    } catch (e) {
        print("Error subscribing to topic: $e");
    }
  }

  // Unsubscribe from the 'new_food' topic (optional, e.g., on logout)
  Future<void> unsubscribeFromNewFoodTopic() async {
     try {
        await _firebaseMessaging.unsubscribeFromTopic('new_food');
        print("Unsubscribed from new_food topic");
     } catch (e) {
        print("Error unsubscribing from topic: $e");
     }
  }
}

// TODO: Define GlobalNavigator key if using that approach for navigation from notification tap
// class GlobalNavigator {
//   static GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
// }
// TODO: Create PostDetailsScreenFromNotification wrapper if needed to fetch post by ID
