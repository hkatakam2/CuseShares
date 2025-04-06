/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Initialize Firebase Admin SDK (only once)
try {
    admin.initializeApp();
  } catch (e) {
    console.error("Admin SDK initialization error:", e);
    // May happen on subsequent deploys if already initialized
  }
  
  
  /**
   * Sends a notification to the 'new_food' topic when a new food post is created.
   */
  exports.sendNewFoodNotification = functions.firestore
      .document("foodPosts/{postId}")
      .onCreate(async (snap, context) => {
        const postData = snap.data();
        const postId = context.params.postId;
  
        console.log(`New post created with ID: ${postId}`);
        console.log("Post Data:", JSON.stringify(postData));
  
  
        // Ensure post data exists and is available (optional check)
        if (!postData || !postData.isAvailable) {
          console.log("Post data missing or post not available, no notification sent.");
          return null;
        }
  
        // Construct the notification message
        const messagePayload = {
          notification: {
            title: "New Food Available! 🍊", // Add an emoji!
            body: `${postData.foodName || "Food"} at ${postData.locationText || "campus location"}`,
            // Optional: Add sound, badge, click_action etc.
            // sound: "default", // Default notification sound
          },
          topic: "new_food", // Target the topic subscribed by apps
          // Optional: Add data payload for handling taps
          data: {
            postId: postId, // Send the post ID
            click_action: "FLUTTER_NOTIFICATION_CLICK", // Required for onMessageOpenedApp
            // Add other relevant data if needed
            // foodName: postData.foodName || "",
            // locationText: postData.locationText || "",
          },
          // --- Android Specific Config (Optional) ---
          android: {
            notification: {
              channel_id: "new_food_channel", // Match channel ID in Flutter app
              // icon: 'notification_icon', // Specify custom icon if needed
              color: '#FFA500', // Orange color
            }
          },
          // --- APNS Specific Config (Optional) ---
          // apns: {
          //   payload: {
          //     aps: {
          //       sound: 'default', // Default sound on iOS
          //       // badge: 1, // Set app badge number
          //     }
          //   }
          // }
        };
  
        try {
          console.log("Sending notification payload:", JSON.stringify(messagePayload));
          const response = await admin.messaging().send(messagePayload);
          console.log("Successfully sent message to 'new_food' topic:", response);
        } catch (error) {
          console.error("Error sending message to 'new_food' topic:", error);
        }
  
        return null; // Indicate function completion
      });
  
  // --- Optional: Function to clean up finished posts after some time ---
  // exports.cleanupOldPosts = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  //   const now = admin.firestore.Timestamp.now();
  //   const cutoff = admin.firestore.Timestamp.fromDate(new Date(now.toMillis() - (48 * 60 * 60 * 1000))); // 48 hours ago
  
  //   const postsRef = admin.firestore().collection('foodPosts');
  //   const oldFinishedPosts = await postsRef
  //       .where('isAvailable', '==', false)
  //       .where('timestamp', '<=', cutoff)
  //       .get();
  
  //   if (oldFinishedPosts.empty) {
  //     console.log('No old finished posts to delete.');
  //     return null;
  //   }
  
  //   const batch = admin.firestore().batch();
  //   oldFinishedPosts.docs.forEach(doc => {
  //     console.log(`Deleting old finished post: ${doc.id}`);
  //     // TODO: Also delete associated chat messages and image from storage?
  //     batch.delete(doc.ref);
  //   });
  
  //   await batch.commit();
  //   console.log(`Deleted ${oldFinishedPosts.size} old finished posts.`);
  //   return null;
  // });
