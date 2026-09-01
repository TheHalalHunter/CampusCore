import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';

/// Handles Firebase Cloud Messaging registration and message handling.
///
/// Call [FcmService.init] once after the user logs in.
class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  /// Request permission, get the FCM token, upload it to the backend,
  /// and set up foreground message handlers.
  static Future<void> init(Ref ref) async {
    // Web uses a different flow — skip for now on web
    if (kIsWeb) return;

    // Request permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Get token and send to backend
    final token = await _messaging.getToken();
    if (token != null) {
      await _uploadToken(ref, token);
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _uploadToken(ref, newToken);
    });

    // Foreground messages — show a local snackbar or banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Background / terminated app messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageTap(message);
    });
  }

  /// Upload the FCM token to the backend via PATCH /users/me
  static Future<void> _uploadToken(Ref ref, String token) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(ApiConstants.updateFcmToken, data: {'fcmToken': token});
    } catch (_) {
      // Non-critical — token upload can fail silently
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // The notification will show automatically on Android via the system tray.
    // For foreground, the app can show an in-app banner if needed.
    debugPrint(
      'FCM foreground: ${message.notification?.title} — ${message.notification?.body}',
    );
  }

  static void _handleMessageTap(RemoteMessage message) {
    // Navigate to the relevant screen based on data payload
    final type = message.data['type'] ?? '';
    final relatedId = message.data['relatedId'] ?? '';
    debugPrint('FCM tapped: type=$type relatedId=$relatedId');
    // Navigation will be handled by the router when context is available
  }
}

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}
