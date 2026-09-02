import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router/app_router.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init(Ref ref) async {
    if (kIsWeb) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await _messaging.getToken();
    if (token != null) await _uploadToken(ref, token);
    _messaging.onTokenRefresh.listen((t) => _uploadToken(ref, t));

    // Foreground messages
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('FCM foreground: ${msg.notification?.title}');
    });

    // Background tap — navigate using router
    FirebaseMessaging.onMessageOpenedApp.listen((msg) => _navigate(ref, msg));

    // Terminated app tap
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _navigate(ref, initial);
  }

  static Future<void> _uploadToken(Ref ref, String token) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(ApiConstants.updateFcmToken, data: {'fcmToken': token});
    } catch (_) {}
  }

  static void _navigate(Ref ref, RemoteMessage message) {
    try {
      final router = ref.read(appRouterProvider);
      final type = message.data['type'] ?? '';
      final relatedId = message.data['relatedId'] ?? '';

      switch (type) {
        case 'question_answered':
        case 'answer_verified':
          if (relatedId.isNotEmpty) {
            router.push('/community/questions/$relatedId');
          }
          break;
        case 'upload_approved':
        case 'upload_rejected':
          if (relatedId.isNotEmpty) {
            router.push('/resources/$relatedId/view');
          }
          break;
        case 'badge_earned':
          router.push('/profile');
          break;
        case 'new_resource':
          router.push('/courses');
          break;
        default:
          router.push('/notifications');
      }
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}
