import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Library'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Saved'), Tab(text: 'Downloads'), Tab(text: 'Bookmarks')],
          ),
        ),
        body: const TabBarView(
          children: [
            _SavedTab(),
            _DownloadsTab(),
            _BookmarksTab(),
          ],
        ),
      ),
    );
  }
}

class _SavedTab extends StatelessWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, i) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.bookmark, color: AppColors.primary),
          title: Text('Saved Resource ${i + 1}'),
          subtitle: const Text('AQU 201'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}

class _DownloadsTab extends StatelessWidget {
  const _DownloadsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Downloaded files will appear here for offline access.'));
  }
}

class _BookmarksTab extends StatelessWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Your bookmarked passages and resources appear here.'));
  }
}
