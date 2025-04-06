import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

    // Initialize local notifications plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Default icon
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(); // Basic iOS settings
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Subscribe to the topic for new food posts
    await subscribeToNewFoodTopic();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
          print('Showing local notification');
        _showLocalNotification(notification);
      }
    });

     // Handle background message taps
     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       print('Message clicked!');
       // TODO: Handle navigation if needed based on message data
     });

     // Get initial message if app was terminated and opened from notification
     RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
     if (initialMessage != null) {
        print('Opened from terminated state via message');
       // TODO: Handle navigation if needed based on message data
     }
  }

  // Show local notification helper
  void _showLocalNotification(RemoteNotification notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'new_food_channel', // Channel ID
      'New Food Alerts', // Channel Name
      channelDescription: 'Notifications for new food posts', // Channel Description
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode, // Unique ID for the notification
      notification.title,
      notification.body,
      platformChannelSpecifics,
      // payload: 'item x', // Optional payload
    );
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

  // Function to send a notification (typically called from backend/cloud function)
  // This is just an example - IN A REAL APP, a Cloud Function triggered
  // by Firestore document creation would send the FCM message.
  // You wouldn't typically send topic messages directly from the client app
  // due to security and scalability reasons.
  //
  // Example Cloud Function Trigger (JavaScript):
  /*
  const functions = require('firebase-functions');
  const admin = require('firebase-admin');
  admin.initializeApp();

  exports.sendNewFoodNotification = functions.firestore
      .document('foodPosts/{postId}')
      .onCreate(async (snap, context) => {
          const postData = snap.data();

          if (!postData.isAvailable) {
              console.log('Post created but not available, no notification sent.');
              return null;
          }

          const message = {
              notification: {
                  title: 'New Food Available!',
                  body: `${postData.foodName} at ${postData.location}`
              },
              topic: 'new_food' // Send to all subscribed users
              // You could add data payload here too:
              // data: { postId: context.params.postId }
          };

          try {
              const response = await admin.messaging().send(message);
              console.log('Successfully sent message:', response);
          } catch (error) {
              console.log('Error sending message:', error);
          }
          return null;
      });
  */
}
