import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission for iOS/Web
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM Token (Optional, for debugging)
    String? vapidKey;
    if (kIsWeb) {
      vapidKey = dotenv.env['FIREBASE_VAPID_KEY'];
      if (vapidKey == null || vapidKey.isEmpty) {
        if (kDebugMode) {
          print('Missing FIREBASE_VAPID_KEY for web push.');
        }
      }
    }

    final token = await _messaging.getToken(
      vapidKey: kIsWeb && vapidKey != null && vapidKey.isNotEmpty
          ? vapidKey
          : null,
    );
    if (kDebugMode) {
      print('FCM Token: $token');
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
        }
      }
      // You can show a local notification here using flutter_local_notifications if needed
    });
  }

  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('subscribeToTopic() is not supported on web clients.');
      }
      return;
    }
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('unsubscribeFromTopic() is not supported on web clients.');
      }
      return;
    }
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }
}

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}
