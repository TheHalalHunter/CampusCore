import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/resource_model.dart';
import '../../providers/resources_provider.dart';

class ResourceViewerScreen extends ConsumerStatefulWidget {
  final String resourceId;
  const ResourceViewerScreen({super.key, required this.resourceId});

  @override
  ConsumerState<ResourceViewerScreen> createState() => _ResourceViewerScreenState();
}

class _ResourceViewerScreenState extends ConsumerState<ResourceViewerScreen> {
  bool _tracked = false;

  @override
  void initState() {
    super.initState();
    // Track download after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackDownload());
  }

  Future<void> _trackDownload() async {
    if (_tracked) return;
    _tracked = true;
    try {
      final api = ref.read(apiClientProvider);
      await api.post('${ApiConstants.resources}/${widget.resourceId}/download');
    } catch (_) {
      // Non-critical — never block the UI
    }
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resourceAsync = ref.watch(resourcesByCourseProvider('').select(
      (list) => list.whenData(
        (resources) => resources.where((r) => r.id == widget.resourceId).firstOrNull,
      ),
    ));

    // Fetch the specific resource directly
    final specificAsync = ref.watch(_resourceByIdProvider(widget.resourceId));

    return specificAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Resource')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Resource')),
        body: const Center(child: Text('Could not load resource.')),
      ),
      data: (resource) {
        if (resource == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Resource')),
            body: const Center(child: Text('Resource not found.')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(resource.title, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_browser_outlined),
                tooltip: 'Open in browser',
                onPressed: () => _openInBrowser(resource.fileUrl),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_typeIcon(resource.fileType),
                              color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(resource.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(resource.typeLabel,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 13)),
                              if (resource.academicYear != null) ...[
                                const SizedBox(height: 2),
                                Text(resource.academicYear!,
                                    style: const TextStyle(
                                        color: AppColors.textHint, fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(children: [
                  _StatChip(
                      icon: Icons.download_outlined,
                      label: '${resource.downloadCount} downloads'),
                  const SizedBox(width: 8),
                  if (resource.isOfficial)
                    _StatChip(icon: Icons.verified_outlined, label: 'Official',
                        color: AppColors.success),
                  if (resource.fileSizeLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _StatChip(icon: Icons.storage_outlined, label: resource.fileSizeLabel),
                  ],
                ]),
                const SizedBox(height: 24),

                if (resource.description != null && resource.description!.isNotEmpty) ...[
                  const Text('Description',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(resource.description!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.6)),
                  const SizedBox(height: 24),
                ],

                // Open button
                ElevatedButton.icon(
                  onPressed: () => _openInBrowser(resource.fileUrl),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open File'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _typeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'pptx':
      case 'ppt': return Icons.slideshow_outlined;
      case 'docx':
      case 'doc': return Icons.description_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }
}

// Fetch a single resource by ID
final _resourceByIdProvider =
    FutureProvider.family<ResourceModel?, String>((ref, id) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get('${ApiConstants.resources}/$id');
    final data = response.data['data'] ?? response.data;
    return ResourceModel.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
