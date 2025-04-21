const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
try {
  admin.initializeApp();
} catch (e) {
  console.error("Admin SDK initialization error:", e);
}

// Update the function to use v2 syntax
exports.sendNewFoodNotification = onDocumentCreated({
  document: "foodPosts/{postId}",
  region: "us-east1", // Specify your preferred region
}, async (event) => {
  const postData = event.data.data();
  const postId = event.params.postId;

  console.log(`New post created with ID: ${postId}`);
  console.log("Post Data:", JSON.stringify(postData));

  // Ensure post data exists and is available
  if (!postData || !postData.isAvailable) {
    console.log("Post data missing or post not available, no notification sent.");
    return null;
  }

  const messagePayload = {
    notification: {
      title: "New Food Available! 🍊",
      body: `${postData.foodName || "Food"} at ${postData.locationText || "campus location"}`,
    },
    topic: "new_food",
    data: {
      postId: postId,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      notification: {
        channel_id: "new_food_channel",
        color: '#FFA500',
      }
    },
  };

  try {
    console.log("Sending notification payload:", JSON.stringify(messagePayload));
    const response = await admin.messaging().send(messagePayload);
    console.log("Successfully sent message to 'new_food' topic:", response);
  } catch (error) {
    console.error("Error sending message to 'new_food' topic:", error);
  }

  return null;
});