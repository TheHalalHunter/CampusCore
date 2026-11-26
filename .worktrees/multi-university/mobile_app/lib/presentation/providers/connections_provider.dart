import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ConnectionModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status; // 'pending' | 'accepted'
  final DateTime createdAt;

  const ConnectionModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'] as String,
      requesterId: json['requesterId'] as String? ??
          json['requester_id'] as String? ?? '',
      receiverId: json['receiverId'] as String? ??
          json['receiver_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(
            json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

class ConnectionStatusModel {
  final String status; // 'none' | 'pending' | 'accepted'
  final String? connectionId;
  final bool isSender;

  const ConnectionStatusModel({
    required this.status,
    this.connectionId,
    required this.isSender,
  });

  factory ConnectionStatusModel.fromJson(Map<String, dynamic> json) {
    return ConnectionStatusModel(
      status: json['status'] as String? ?? 'none',
      connectionId: json['connectionId'] as String?,
      isSender: json['isSender'] as bool? ?? false,
    );
  }

  bool get isConnected => status == 'accepted';
  bool get isPending => status == 'pending';
  bool get isNone => status == 'none';
}

// ─── My Connections ───────────────────────────────────────────────────────────

final connectionsProvider = FutureProvider<List<ConnectionModel>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiConstants.connections);
    final data = response.data['data'] ?? response.data;
    return (data as List).map((c) => ConnectionModel.fromJson(c)).toList();
  } catch (_) {
    return [];
  }
});

// ─── Pending received requests ────────────────────────────────────────────────

final pendingRequestsProvider = FutureProvider<List<ConnectionModel>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiConstants.connectionsPendingReceived);
    final data = response.data['data'] ?? response.data;
    return (data as List).map((c) => ConnectionModel.fromJson(c)).toList();
  } catch (_) {
    return [];
  }
});

// ─── Status with a specific user ─────────────────────────────────────────────

final connectionStatusProvider =
    FutureProvider.family<ConnectionStatusModel, String>((ref, userId) async {
  try {
    final api = ref.read(apiClientProvider);
    final response =
        await api.get('${ApiConstants.connections}/status/$userId');
    final data = response.data['data'] ?? response.data;
    return ConnectionStatusModel.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    return const ConnectionStatusModel(status: 'none', isSender: false);
  }
});

// ─── Connection actions notifier ─────────────────────────────────────────────

final connectionActionsProvider =
    NotifierProvider<ConnectionActionsNotifier, AsyncValue<void>>(
        ConnectionActionsNotifier.new);

class ConnectionActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> sendRequest(String receiverId) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.connectionRequest,
          data: {'receiverId': receiverId});
      state = const AsyncValue.data(null);
      // Invalidate so status re-fetches
      ref.invalidate(connectionStatusProvider(receiverId));
      ref.invalidate(connectionsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> acceptRequest(String connectionId, String requesterId) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('${ApiConstants.connections}/$connectionId/accept');
      state = const AsyncValue.data(null);
      ref.invalidate(pendingRequestsProvider);
      ref.invalidate(connectionsProvider);
      ref.invalidate(connectionStatusProvider(requesterId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> removeConnection(
      String connectionId, String otherUserId) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('${ApiConstants.connections}/$connectionId');
      state = const AsyncValue.data(null);
      ref.invalidate(connectionStatusProvider(otherUserId));
      ref.invalidate(connectionsProvider);
      ref.invalidate(pendingRequestsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
