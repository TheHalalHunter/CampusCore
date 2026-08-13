import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getPadding(context);
    final spacing = Responsive.getSpacing(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Resources',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: isMobile ? 24 : 32,
              ),
            ),
            SizedBox(height: spacing + 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: isMobile ? 5 : 10,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Row(
                    children: [
                      Container(
                        width: isMobile ? 40 : 48,
                        height: isMobile ? 40 : 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_outlined,
                          color: AppColors.primary,
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lecture Notes - Week ${index + 1}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 12 : 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '2.4 MB • PDF',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey500,
                                fontSize: isMobile ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile)
                        IconButton(
                          icon: const Icon(Icons.download_outlined),
                          onPressed: () {},
                        )
                      else
                        Icon(Icons.download_outlined, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
