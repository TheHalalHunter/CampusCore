import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Assistant'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Explain'),
            Tab(text: 'Quiz'),
            Tab(text: 'Flashcards'),
            Tab(text: 'Summarize'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ExplainTab(),
          _QuizTab(),
          _FlashcardsTab(),
          _SummarizeTab(),
        ],
      ),
    );
  }
}

class _ExplainTab extends StatefulWidget {
  const _ExplainTab();

  @override
  State<_ExplainTab> createState() => _ExplainTabState();
}

class _ExplainTabState extends State<_ExplainTab> {
  final _ctrl = TextEditingController();
  String? _result;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What would you like explained?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. "Explain the nitrogen cycle in aquaculture"',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _loading = true;
                      // TODO: call AI provider
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _result =
                                'The AI explanation will appear here once the backend is connected.';
                            _loading = false;
                          });
                        }
                      });
                    }),
            icon: const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'Thinking...' : 'Explain'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Text(_result!, style: const TextStyle(height: 1.6)),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizTab extends StatelessWidget {
  const _QuizTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Generate Practice Quizzes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Enter a topic and get AI-generated MCQ questions to test your knowledge.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _FlashcardsTab extends StatelessWidget {
  const _FlashcardsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style, size: 64, color: AppColors.accent),
            SizedBox(height: 16),
            Text('Flashcard Generator',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Get a deck of flashcards on any topic to help memorize key terms and concepts.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _SummarizeTab extends StatelessWidget {
  const _SummarizeTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.summarize, size: 64, color: AppColors.info),
            SizedBox(height: 16),
            Text('Summarize Content',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Paste a passage or chapter and get a concise summary with key points.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
