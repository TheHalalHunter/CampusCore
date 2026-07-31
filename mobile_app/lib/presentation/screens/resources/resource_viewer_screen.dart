import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class ResourceViewerScreen extends StatelessWidget {
  final String resourceId;
  const ResourceViewerScreen({super.key, required this.resourceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fish Nutrition — Notes'),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_outline), onPressed: () {}),
          IconButton(icon: const Icon(Icons.download_outlined), onPressed: () {}),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, size: 72, color: AppColors.grey600),
            SizedBox(height: 16),
            Text('PDF Viewer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('PDF will render here once resource URL is loaded.',
                style: TextStyle(color: AppColors.grey600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
