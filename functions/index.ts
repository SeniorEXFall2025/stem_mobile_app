import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';
import { Message } from 'firebase-admin/lib/messaging';

// Initialize the Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Define the expected type for the notification data in Firestore
type NotificationData = {
    userId: string;
    title?: string;
    body?: string;
    route?: string;
};

/**
 * Sends a push notification to a target user when a new notification document is created.
 * * Uses Firebase Functions V2 modular syntax.
 */
export const sendNotificationOnCreate = onDocumentCreated(
    // 1. Specify the document path listener
    'notifications/{notificationId}',
    async (event) => {
        // In V2 'onDocumentCreated', event.data is the QueryDocumentSnapshot of the new document.
        const snapshot = event.data;

        if (!snapshot) {
            logger.error('No snapshot data found in event.');
            return;
        }

        // Use the generic `data()` method and cast to our expected type.
        const notificationData = snapshot.data() as NotificationData;
        const recipientUserId = notificationData.userId;

        if (!recipientUserId) {
            logger.log('Notification document missing userId in:', event.params.notificationId);
            return;
        }

        // 1. Fetch the user's FCM token from the 'users' collection
        const userRef = db.collection('users').doc(recipientUserId);
        const userDoc = await userRef.get();

        const fcmToken = userDoc.data()?.fcmToken;

        if (!userDoc.exists || !fcmToken) {
            logger.log(`No FCM token found for user: ${recipientUserId}`);
            return;
        }

        // 2. Construct the FCM Message Payload
        const payload: Message = {
            token: fcmToken,
            notification: {
                title: notificationData.title || 'STEM App Notification',
                body: notificationData.body || 'You have a new update.',
            },
            data: {
                // This 'click_action' is necessary for Flutter FCM to handle routing.
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                route: notificationData.route || '/events',
            },
            // This setting targets the 'high_importance_channel' defined in your Flutter code.
            android: {
                notification: {
                    channelId: 'high_importance_channel',
                },
            },
        };

        try {
            // 3. Send the notification via the Firebase Admin SDK
            const response = await admin.messaging().send(payload);
            logger.log('Successfully sent message:', response);
        } catch (error) {
            logger.error('Error sending message:', error);
        }
    }
);