import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

/// Fetches the current logged-in user's profile from the backend.
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiConstants.me);
    final data = response.data['data'] ?? response.data;
    return UserModel.fromJson(data as Map<String, dynamic>);
  } catch (e) {
    return null;
  }
});
