// lib/fcm_manager.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this after the user is logged in AND their profile is complete.
  static Future<void> initForLoggedInUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1) Ask user for notification permissions.
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

    // 2) Get the FCM token for this device.
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(user.uid, token);
    }

    // 3) Listen for token refresh and update Firestore.
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
