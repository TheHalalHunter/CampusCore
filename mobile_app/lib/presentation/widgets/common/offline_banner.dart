import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/storage/offline_cache.dart';

/// Shows a slim banner at the top when cached (stale) data is being displayed.
/// Wraps [child] in a Column — use inside a widget with bounded height.
class OfflineBanner extends StatelessWidget {
  final String cacheKey;
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.cacheKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isCached = OfflineCache.cachedAt(cacheKey) != null;
    final isStale = isCached && !OfflineCache.isFresh(cacheKey);

    if (!isStale) return child;

    return Column(
      children: [
        Material(
          color: AppColors.warning.withOpacity(0.12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: const [
              Icon(Icons.cloud_off_outlined,
                  size: 14, color: AppColors.warning),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Showing cached data. Pull down to refresh.',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
