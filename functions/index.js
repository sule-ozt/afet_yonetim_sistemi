const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const fcmToken = data.fcmToken;
    const title = data.title;
    const body = data.body;

    if (!fcmToken) {
      console.log("FCM token bulunamadı.");
      return null;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: title || "Bildirim",
        body: body || "",
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log("Bildirim gönderildi:", response);
    } catch (error) {
      console.error("Gönderim hatası:", error);
    }

    return null;
  });
