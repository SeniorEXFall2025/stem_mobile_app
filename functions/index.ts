import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';
import { Message } from 'firebase-admin/lib/messaging';

// Initialize the Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Type Definitions

// Define the expected type for the notification data in Firestore (the trigger document)
type NotificationData = {
    userId: string;
    title?: string;
    body?: string;
    route?: string;
};

// Define the expected type for the Event document in Firestore (the source document)
type EventData = {
    title: string;
    description: string;
    // Add other relevant fields if needed
};


/**
 * Sends a push notification to a target user when a new notification document is created.
 */
export const sendNotificationOnCreate = onDocumentCreated(
    // 1. Specify the document path listener
    'notifications/{notificationId}',
    async (event) => {
        const snapshot = event.data;

        if (!snapshot) {
            logger.error('No snapshot data found in event.');
            return;
        }

        const notificationData = snapshot.data() as NotificationData;
        const recipientUserId: any = notificationData?.userId; // Using lowercase 'i'

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
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                route: notificationData.route || '/events',
            },
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

/**
 * Automatically creates a notification document (a trigger) when a new event is posted.
 * This function handles the Fan-out Write and targets a single hardcoded student for testing.
 */
export const notifyOnNewEvent = onDocumentCreated(
    // Listen for new documents in the 'events' collection
    'events/{eventId}',
    async (event) => {
        const eventSnapshot = event.data;
        if (!eventSnapshot) {
            logger.error('No event data found for new event.');
            return;
        }

        const eventData = eventSnapshot.data() as EventData;


        // Replace this with logic to fetch all student UIDs in a production environment.
        const targetUserId = '5M7sr6LsnGQX8uFi2TfmiKdvMq72';


        // Prepare the payload for the NOTIFICATION trigger collection
        const notificationPayload: Omit<NotificationData, 'route'> & { createdAt: admin.firestore.FieldValue, route: string } = {
            // Using 'userId' casing to match Function 1's expectation
            userId: targetUserId,
            title: `🔔 NEW EVENT: ${eventData.title}`,
            // Truncate the description for the notification body limit
            body: eventData.description.substring(0, 150) + '...',
            route: `/events/${event.params.eventId}`,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        };

        try {
            // Write the trigger document to the 'notifications' collection
            await db.collection('notifications').add(notificationPayload);
            logger.log(`Automation successful: Queued notification for user ${targetUserId} based on new event.`);
        } catch (error) {
            logger.error('Error writing notification trigger document:', error);
        }
    }
);