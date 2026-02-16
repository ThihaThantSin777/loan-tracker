import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class FirebaseService {
  static FirebaseMessaging? _messaging;
  static final ApiService _api = ApiService();
  static bool _initialized = false;

  /// Initialize Firebase and setup messaging
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      _initialized = true;

      // Request permission
      await requestPermission();

      // Get and save FCM token
      await _saveFcmToken();

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        _updateFcmToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      // Continue without Firebase - app will still work without push notifications
    }
  }

  /// Request notification permission
  static Future<bool> requestPermission() async {
    if (!_initialized || _messaging == null) return false;

    try {
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    if (!_initialized || _messaging == null) return null;

    try {
      return await _messaging!.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
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
