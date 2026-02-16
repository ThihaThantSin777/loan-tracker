import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final ApiService _api = ApiService();

  /// Initialize Firebase and setup messaging
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Request permission
    await requestPermission();

    // Get and save FCM token
    await _saveFcmToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _updateFcmToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Request notification permission
  static Future<bool> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Save FCM token to backend
  static Future<void> _saveFcmToken() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _updateFcmToken(token);
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Update FCM token on backend
  static Future<void> _updateFcmToken(String token) async {
    try {
      await _api.put(ApiConfig.updateFcmToken, {'fcm_token': token});
      debugPrint('FCM token updated successfully');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');
    // You can show a local notification here or update UI
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    // Navigate to specific screen based on message data
  }
}

/// Handle background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Received background message: ${message.notification?.title}');
}
