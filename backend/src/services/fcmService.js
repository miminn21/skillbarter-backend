const admin = require('firebase-admin');

/**
 * Firebase Cloud Messaging Service
 * Handles push notification delivery via FCM
 */

// Initialize Firebase Admin (called once on server start)
function initializeFCM() {
  if (!admin.apps.length) {
    try {
      // Use service account key file if available (Priority for Local Dev)
      const serviceAccount = require('../../serviceAccountKey.json');
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      
      console.log('✅ Firebase Admin initialized with serviceAccountKey.json');
    } catch (error) {
      // Fallback to env vars (For Railway/Cloud)
      try {
        console.log('⚠️ Failed to load serviceAccountKey.json, trying env vars...');
        if (process.env.FIREBASE_PRIVATE_KEY) {
           admin.initializeApp({
            credential: admin.credential.cert({
              projectId: process.env.FIREBASE_PROJECT_ID,
              privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
              clientEmail: process.env.FIREBASE_CLIENT_EMAIL
            })
          });
          console.log('✅ Firebase Admin initialized with Env Vars');
        } else {
          throw new Error('No Firebase configuration found');
        }
      } catch (envError) {
        console.error('❌ Firebase Admin initialization failed:', envError.message);
        console.error('   Push notifications will not work!');
      }
    }
  }
}

/**
 * Send push notification to single device
 * @param {string} fcmToken - User's FCM device token
 * @param {object} notification - Notification data
 * @param {string} notification.judul - Title
 * @param {string} notification.pesan - Message body
 * @param {string} notification.tipe - Notification type
 * @param {object} notification.data - Additional data
 * @param {number} notification.unread_count - Badge count
 */
async function sendPushNotification(fcmToken, notification) {
  console.log('🔔 ===== SEND PUSH NOTIFICATION CALLED =====');
  console.log('📱 FCM Token:', fcmToken ? `${fcmToken.substring(0, 20)}...` : 'NULL/EMPTY');
  console.log('📦 Notification:', JSON.stringify(notification, null, 2));
  
  if (!fcmToken) {
    console.log('⚠️ No FCM token provided, skipping push');
    return null;
  }

  if (!admin.apps.length) {
    console.log('⚠️ Firebase not initialized, skipping push');
    return null;
  }

  console.log('✅ Firebase initialized, apps count:', admin.apps.length);

  // DATA-ONLY STRATEGY: More reliable for custom notification handling
  const message = {
    token: fcmToken,
    data: {
      title: notification.judul || 'SkillBarter',
      body: notification.pesan || 'Anda memiliki notifikasi baru',
      id_notifikasi: notification.id?.toString() || '',
      id_barter: notification.data?.id_barter?.toString() || '',
      tipe: notification.tipe || 'general',
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    },
    android: {
      priority: 'high',
      ttl: 86400,
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: notification.judul || 'SkillBarter',
            body: notification.pesan || 'Anda memiliki notifikasi baru',
          },
          sound: 'default',
          badge: notification.unread_count || 1,
          contentAvailable: true
        }
      }
    }
  };

  console.log('📤 Sending FCM message:', JSON.stringify(message, null, 2));

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Push notification sent successfully:', response);
    return response;
  } catch (error) {
    console.error('❌ Push notification failed:', error.message);
    console.error('❌ Error code:', error.code);
    console.error('❌ Full error:', JSON.stringify(error, null, 2));
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      console.log('   Token is invalid or expired, should be removed from DB');
    }
    // Don't throw - notification is still saved in DB
    return null;
  }
}

/**
 * Send push notification to multiple devices
 * @param {string[]} fcmTokens - Array of FCM tokens
 * @param {object} notification - Notification data
 */
async function sendMulticastPushNotification(fcmTokens, notification) {
  if (!fcmTokens || fcmTokens.length === 0) {
    console.log('⚠️ No FCM tokens provided, skipping multicast push');
    return null;
  }

  if (!admin.apps.length) {
    console.log('⚠️ Firebase not initialized, skipping push');
    return null;
  }

  const message = {
    tokens: fcmTokens,
    notification: {
      title: notification.judul || 'SkillBarter',
      body: notification.pesan || 'Anda memiliki notifikasi baru'
    },
    data: {
      id_notifikasi: notification.id?.toString() || '',
      id_barter: notification.data?.id_barter?.toString() || '',
      tipe: notification.tipe || 'general'
    }
  };

  try {
    const response = await admin.messaging().sendMulticast(message);
    console.log(`✅ Multicast push sent: ${response.successCount}/${fcmTokens.length} successful`);
    return response;
  } catch (error) {
    console.error('❌ Multicast push failed:', error.message);
    return null;
  }
}

module.exports = {
  initializeFCM,
  sendPushNotification,
  sendMulticastPushNotification
};
