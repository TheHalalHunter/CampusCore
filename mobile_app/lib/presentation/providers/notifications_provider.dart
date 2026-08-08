import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

/// User notifications.
final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiConstants.notifications);
    final data = response.data['data'] ?? response.data;
    return (data as List).map((n) => NotificationModel.fromJson(n)).toList();
  } catch (_) {
    return [];
  }
});

/// Unread notification count.
final unreadCountProvider = FutureProvider<int>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get('${ApiConstants.notifications}/unread-count');
    final data = response.data['data'] ?? response.data;
    return (data as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
});
