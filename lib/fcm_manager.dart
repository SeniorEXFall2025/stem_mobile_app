import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this after the user is logged in AND their profile is complete.
  static Future<void> initForLoggedInUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Ask user for notification permissions.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // User said no — just stop here, app still works fine.
      return;
    }

    // Get the user's profile to find current interests.
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final currentInterests = (snap.data()?['interests'] as List<dynamic>?)
        ?.whereType<String>()
        .toList() ?? [];

    // Subscribe to topics matching interests.
    // Topics must be lowercase and only contain alphanumeric characters,
    // hyphens, or underscores. The topics defined in `onboarding_page.dart`
    // are suitable (e.g., 'AI', 'Robotics').
    for (final interest in currentInterests) {

      await _messaging.subscribeToTopic(interest.toLowerCase());
    }

    // Get the FCM token for this device.
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(user.uid, token);
    }

    // Listen for token refresh and update Firestore.
    _messaging.onTokenRefresh.listen((newToken) async {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) return;
      await _saveToken(u.uid, newToken);
    });
  }

  static Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }
}