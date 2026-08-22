import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connections_provider.dart';
import '../../../app/theme/app_theme.dart';

/// Displays the correct connection CTA depending on the current
/// connection status between the logged-in user and [targetUserId].
class ConnectButton extends ConsumerWidget {
  final String targetUserId;
  const ConnectButton({super.key, required this.targetUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(connectionStatusProvider(targetUserId));
    final actionsState = ref.watch(connectionActionsProvider);
    final isLoading = actionsState is AsyncLoading;

    return statusAsync.when(
      loading: () => const SizedBox(
        height: 36,
        width: 36,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        if (status.isConnected) {
          return OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () => _remove(context, ref, status.connectionId!),
            icon: const Icon(Icons.person_remove_outlined, size: 18),
            label: const Text('Connected'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
            ),
          );
        }

        if (status.isPending && status.isSender) {
          return OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () => _remove(context, ref, status.connectionId!),
            icon: const Icon(Icons.hourglass_top_outlined, size: 18),
            label: const Text('Pending'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
            ),
          );
        }

        if (status.isPending && !status.isSender) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => _accept(
                        context, ref, status.connectionId!, targetUserId),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Accept'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () => _remove(context, ref, status.connectionId!),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Decline'),
              ),
            ],
          );
        }

        // No connection — show Connect button
        return ElevatedButton.icon(
          onPressed: isLoading ? null : () => _send(context, ref),
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Connect'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 38),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        );
      },
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(connectionActionsProvider.notifier)
        .sendRequest(targetUserId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Connection request sent!' : 'Could not send request.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    }
  }

  Future<void> _accept(BuildContext context, WidgetRef ref,
      String connectionId, String requesterId) async {
    final ok = await ref
        .read(connectionActionsProvider.notifier)
        .acceptRequest(connectionId, requesterId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Connection accepted!' : 'Could not accept.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    }
  }

  Future<void> _remove(
      BuildContext context, WidgetRef ref, String connectionId) async {
    final ok = await ref
        .read(connectionActionsProvider.notifier)
        .removeConnection(connectionId, targetUserId);
    if (context.mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Connection removed.'),
      ));
    }
  }
}
