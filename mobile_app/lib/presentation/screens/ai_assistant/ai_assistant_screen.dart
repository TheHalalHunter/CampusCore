import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/error_helper.dart';
import '../../providers/ai_provider.dart';

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
    _tabController = TabController(length: 5, vsync: this);
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
            SizedBox(width: 8),
            Text('AI Study Assistant'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.lightbulb_outline, size: 18), text: 'Explain'),
            Tab(icon: Icon(Icons.quiz_outlined, size: 18), text: 'Quiz'),
            Tab(icon: Icon(Icons.style_outlined, size: 18), text: 'Flashcards'),
            Tab(
                icon: Icon(Icons.summarize_outlined, size: 18),
                text: 'Summarize'),
            Tab(
                icon: Icon(Icons.trending_up_outlined, size: 18),
                text: 'Predict'),
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
          _PredictTab(),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _AiInputCard extends StatelessWidget {
  final String hint;
  final String buttonLabel;
  final IconData buttonIcon;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;
  final int maxLines;

  const _AiInputCard({
    required this.hint,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: AppColors.textHint, fontSize: 13),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onSubmit,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(buttonIcon, size: 18),
            label: Text(isLoading ? 'Thinking...' : buttonLabel),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiResultCard extends StatelessWidget {
  final String content;
  final VoidCallback onClear;

  const _AiResultCard({required this.content, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'AI Response',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size(40, 32),
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 16),
          SelectableText(
            content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiErrorCard extends StatelessWidget {
  final String error;
  const _AiErrorCard({required this.error});

  bool get _isExamLock =>
      error.toLowerCase().contains('exam period') ||
      error.toLowerCase().contains('disabled during');

  @override
  Widget build(BuildContext context) {
    if (_isExamLock) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_clock, color: AppColors.warning, size: 36),
            const SizedBox(height: 12),
            const Text(
              'AI Locked During Exam Period',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(error,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── EXPLAIN TAB ──────────────────────────────────────────────────────────────

class _ExplainTab extends ConsumerStatefulWidget {
  const _ExplainTab();

  @override
  ConsumerState<_ExplainTab> createState() => _ExplainTabState();
}

class _ExplainTabState extends ConsumerState<_ExplainTab> {
  final _conceptCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();

  @override
  void dispose() {
    _conceptCtrl.dispose();
    _contextCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(explainProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F67FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.white, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Concept Explainer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Get a clear explanation of any concept in simple terms.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'What would you like explained?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _AiInputCard(
            hint: 'e.g. Explain the nitrogen cycle in aquaculture',
            buttonLabel: 'Explain',
            buttonIcon: Icons.auto_awesome,
            controller: _conceptCtrl,
            isLoading: state.isLoading,
            onSubmit: () {
              final concept = _conceptCtrl.text.trim();
              if (concept.isEmpty) return;
              ref.read(explainProvider.notifier).explain(
                    concept,
                    courseContext: _contextCtrl.text.trim().isEmpty
                        ? null
                        : _contextCtrl.text.trim(),
                  );
            },
          ),
          const SizedBox(height: 12),

          // Optional context
          TextField(
            controller: _contextCtrl,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Course context (optional) e.g. Fish Nutrition',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 12),
              prefixIcon: Icon(Icons.school_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 20),

          // Error
          if (state.error != null) ...[
            _AiErrorCard(error: state.error!),
            const SizedBox(height: 16),
          ],

          // Result
          if (state.content.isNotEmpty)
            _AiResultCard(
              content: state.content,
              onClear: () => ref.read(explainProvider.notifier).clear(),
            ),
        ],
      ),
    );
  }
}

// ─── QUIZ TAB ─────────────────────────────────────────────────────────────────

class _QuizTab extends ConsumerStatefulWidget {
  const _QuizTab();

  @override
  ConsumerState<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends ConsumerState<_QuizTab> {
  final _topicCtrl = TextEditingController();
  int _questionCount = 5;

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);

    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Generating quiz...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (state.questions.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.quiz, color: Colors.white, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Practice Quiz',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            )),
                        SizedBox(height: 4),
                        Text(
                          'Generate MCQ questions on any topic to test your knowledge.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Topic',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _topicCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Protein requirements in fish feed',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Number of Questions',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 8),
            Row(
              children: [5, 10, 15].map((n) {
                final selected = _questionCount == n;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _questionCount = n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            selected ? AppColors.accent : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '$n',
                        style: TextStyle(
                          color:
                              selected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (state.error != null) ...[
              _AiErrorCard(error: state.error!),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: () {
                final topic = _topicCtrl.text.trim();
                if (topic.isEmpty) return;
                ref.read(quizProvider.notifier).generate(
                      topic,
                      count: _questionCount,
                    );
              },
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Generate Quiz'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppColors.accent,
              ),
            ),
          ],
        ),
      );
    }

    // Quiz in progress or submitted
    return _QuizPlayer(state: state);
  }
}

class _QuizPlayer extends ConsumerWidget {
  final QuizState state;
  const _QuizPlayer({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.submitted) return _QuizResults(state: state);

    final q = state.questions[state.currentIndex];
    final selected = state.selectedAnswers[state.currentIndex];

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (state.currentIndex + 1) / state.questions.length,
          backgroundColor: AppColors.grey200,
          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          minHeight: 6,
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question number
                Text(
                  'Question ${state.currentIndex + 1} of ${state.questions.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Question
                Text(
                  q.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Options
                ...q.options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final opt = entry.value;
                  final isSelected = selected == idx;

                  return GestureDetector(
                    onTap: () => ref.read(quizProvider.notifier).selectAnswer(
                          state.currentIndex,
                          idx,
                        ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected ? AppColors.accent : AppColors.border,
                          width: isSelected ? 2 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.surfaceAlt,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + idx),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opt,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (state.currentIndex > 0)
                OutlinedButton(
                  onPressed: () => ref.read(quizProvider.notifier).previous(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 44),
                  ),
                  child: const Text('Back'),
                ),
              const Spacer(),
              if (state.currentIndex < state.questions.length - 1)
                ElevatedButton(
                  onPressed: selected != null
                      ? () => ref.read(quizProvider.notifier).next()
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 44),
                    backgroundColor: AppColors.accent,
                  ),
                  child: const Text('Next'),
                )
              else
                ElevatedButton(
                  onPressed:
                      state.selectedAnswers.length == state.questions.length
                          ? () => ref.read(quizProvider.notifier).submit()
                          : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 44),
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Submit Quiz'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuizResults extends ConsumerWidget {
  final QuizState state;
  const _QuizResults({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = state.score;
    final total = state.questions.length;
    final percentage = total > 0 ? (score / total * 100).round() : 0;

    Color resultColor;
    String resultLabel;
    if (percentage >= 80) {
      resultColor = AppColors.success;
      resultLabel = 'Excellent!';
    } else if (percentage >= 60) {
      resultColor = AppColors.info;
      resultLabel = 'Good job!';
    } else if (percentage >= 40) {
      resultColor = AppColors.warning;
      resultLabel = 'Keep studying!';
    } else {
      resultColor = AppColors.error;
      resultLabel = 'Need more practice';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Score card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: resultColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  resultLabel,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: resultColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$score / $total correct',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: resultColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Answer review
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Review Answers',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...state.questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final selected = state.selectedAnswers[idx];
            final isCorrect = selected == q.correctAnswer;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppColors.success.withValues(alpha: 0.05)
                    : AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCorrect
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Q${idx + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color:
                              isCorrect ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.question,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Correct: ${q.options.isNotEmpty && q.correctAnswer < q.options.length ? q.options[q.correctAnswer] : ""}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (q.explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      q.explanation,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(quizProvider.notifier).reset(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Another Quiz'),
          ),
        ],
      ),
    );
  }
}

// ─── FLASHCARDS TAB ───────────────────────────────────────────────────────────

class _FlashcardsTab extends ConsumerStatefulWidget {
  const _FlashcardsTab();

  @override
  ConsumerState<_FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends ConsumerState<_FlashcardsTab> {
  final _topicCtrl = TextEditingController();

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashcardsProvider);

    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Creating flashcards...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (state.cards.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.style, color: Colors.white, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flashcard Generator',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            )),
                        SizedBox(height: 4),
                        Text(
                          'Tap cards to flip and reveal the answer. Great for memorizing key terms.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Topic',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 8),
            _AiInputCard(
              hint: 'e.g. Aquaculture terminology, Fish diseases',
              buttonLabel: 'Generate Flashcards',
              buttonIcon: Icons.auto_awesome,
              controller: _topicCtrl,
              isLoading: false,
              onSubmit: () {
                final topic = _topicCtrl.text.trim();
                if (topic.isEmpty) return;
                ref.read(flashcardsProvider.notifier).generate(topic);
              },
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              _AiErrorCard(error: state.error!),
            ],
          ],
        ),
      );
    }

    // Show flashcard deck
    final card = state.cards[state.currentIndex];
    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.currentIndex + 1} / ${state.cards.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () => ref.read(flashcardsProvider.notifier).reset(),
                child: const Text('New Deck'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () => ref
                  .read(flashcardsProvider.notifier)
                  .flip(state.currentIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: card.flipped ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: card.flipped ? AppColors.primary : AppColors.border,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          card.flipped ? Icons.lightbulb : Icons.quiz,
                          color: card.flipped
                              ? Colors.white70
                              : AppColors.textHint,
                          size: 32,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          card.flipped ? 'ANSWER' : 'QUESTION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: card.flipped
                                ? Colors.white54
                                : AppColors.textHint,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          card.flipped ? card.back : card.front,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: card.flipped
                                ? Colors.white
                                : AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Tap to ${card.flipped ? 'see question' : 'reveal answer'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: card.flipped
                                ? Colors.white54
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Navigation
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.currentIndex > 0
                      ? () => ref.read(flashcardsProvider.notifier).previous()
                      : null,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.currentIndex < state.cards.length - 1
                      ? () => ref.read(flashcardsProvider.notifier).next()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SUMMARIZE TAB ────────────────────────────────────────────────────────────

class _SummarizeTab extends ConsumerStatefulWidget {
  const _SummarizeTab();

  @override
  ConsumerState<_SummarizeTab> createState() => _SummarizeTabState();
}

class _SummarizeTabState extends ConsumerState<_SummarizeTab> {
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(summarizeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.summarize, color: Colors.white, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Content Summarizer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          )),
                      SizedBox(height: 4),
                      Text(
                        'Paste a passage or chapter and get a concise summary with key points.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Paste your text here',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          _AiInputCard(
            hint: 'Paste the text you want to summarize...',
            buttonLabel: 'Summarize',
            buttonIcon: Icons.auto_awesome,
            controller: _textCtrl,
            isLoading: state.isLoading,
            maxLines: 8,
            onSubmit: () {
              final text = _textCtrl.text.trim();
              if (text.isEmpty) return;
              ref.read(summarizeProvider.notifier).summarize(text);
            },
          ),
          const SizedBox(height: 16),
          if (state.error != null) ...[
            _AiErrorCard(error: state.error!),
            const SizedBox(height: 16),
          ],
          if (state.content.isNotEmpty)
            _AiResultCard(
              content: state.content,
              onClear: () => ref.read(summarizeProvider.notifier).clear(),
            ),
        ],
      ),
    );
  }
}

// ─── Predict Topics Tab ───────────────────────────────────────────────────────

class _PredictTab extends ConsumerStatefulWidget {
  const _PredictTab();

  @override
  ConsumerState<_PredictTab> createState() => _PredictTabState();
}

class _PredictTabState extends ConsumerState<_PredictTab> {
  final _courseTitleCtrl = TextEditingController();
  final _topicsCtrl = TextEditingController();
  bool _loading = false;
  List<String> _results = [];
  String? _error;

  @override
  void dispose() {
    _courseTitleCtrl.dispose();
    _topicsCtrl.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    final title = _courseTitleCtrl.text.trim();
    final topics = _topicsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (title.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(
        ApiConstants.aiPredictTopics,
        data: {'courseTitle': title, 'recentTopics': topics},
      );
      final data = response.data['data'] ?? response.data;
      setState(() {
        _results = List<String>.from(data as List? ?? []);
      });
    } catch (e) {
      setState(() => _error = extractErrorMessage(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(children: [
              Icon(Icons.trending_up, color: Colors.white, size: 32),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Predict Exam Topics',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Get likely exam topics based on what you\'ve covered.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Course title input
          TextField(
            controller: _courseTitleCtrl,
            decoration: const InputDecoration(
              labelText: 'Course Title',
              hintText: 'e.g. Fish Nutrition and Feeding',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
          ),
          const SizedBox(height: 14),

          // Recent topics input
          TextField(
            controller: _topicsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Recent Topics Covered (comma-separated)',
              hintText: 'e.g. Protein metabolism, Feed formulation, Vitamins',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _loading ? null : _predict,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search, size: 18),
            label: Text(_loading ? 'Predicting…' : 'Predict Topics'),
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 16),
            _AiErrorCard(error: _error!),
          ],

          // Results
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(children: [
              const Icon(Icons.lightbulb, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text('${_results.length} Likely Exam Topics',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 12),
            ..._results.asMap().entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                                fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500)),
                    ),
                  ]),
                )),
          ],
        ],
      ),
    );
  }
}
