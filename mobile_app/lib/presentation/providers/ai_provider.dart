import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/error_helper.dart';

// ─── State models ─────────────────────────────────────────────────────────────

class AiResponse {
  final String content;
  final bool isLoading;
  final String? error;

  const AiResponse({
    this.content = '',
    this.isLoading = false,
    this.error,
  });

  AiResponse copyWith({String? content, bool? isLoading, String? error, bool clearError = false}) {
    return AiResponse(
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String? ?? '',
      options: (json['options'] as List?)?.map((o) => o.toString()).toList() ?? [],
      correctAnswer: (json['correctAnswer'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class Flashcard {
  final String front;
  final String back;
  bool flipped;

  Flashcard({required this.front, required this.back, this.flipped = false});

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
    );
  }
}

// ─── Explain Provider ─────────────────────────────────────────────────────────

final explainProvider = NotifierProvider<ExplainNotifier, AiResponse>(ExplainNotifier.new);

class ExplainNotifier extends Notifier<AiResponse> {
  @override
  AiResponse build() => const AiResponse();

  Future<void> explain(String concept, {String? courseContext}) async {
    state = const AiResponse(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(ApiConstants.aiExplain, data: {
        'concept': concept,
        if (courseContext != null) 'courseContext': courseContext,
      });
      final data = response.data['data'] ?? response.data;
      state = AiResponse(content: data.toString());
      // Save to history
      ref.read(aiHistoryProvider.notifier).add(
        type: 'explain',
        prompt: concept,
        result: data.toString(),
      );
    } catch (e) {
      state = AiResponse(error: extractErrorMessage(e));
    }
  }

  void clear() => state = const AiResponse();
}

// ─── Quiz Provider ────────────────────────────────────────────────────────────

class QuizState {
  final List<QuizQuestion> questions;
  final bool isLoading;
  final String? error;
  final int currentIndex;
  final Map<int, int> selectedAnswers;
  final bool submitted;

  const QuizState({
    this.questions = const [],
    this.isLoading = false,
    this.error,
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.submitted = false,
  });

  QuizState copyWith({
    List<QuizQuestion>? questions,
    bool? isLoading,
    String? error,
    int? currentIndex,
    Map<int, int>? selectedAnswers,
    bool? submitted,
    bool clearError = false,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      submitted: submitted ?? this.submitted,
    );
  }

  int get score {
    int correct = 0;
    for (final entry in selectedAnswers.entries) {
      if (entry.key < questions.length &&
          entry.value == questions[entry.key].correctAnswer) {
        correct++;
      }
    }
    return correct;
  }
}

final quizProvider = NotifierProvider<QuizNotifier, QuizState>(QuizNotifier.new);

class QuizNotifier extends Notifier<QuizState> {
  @override
  QuizState build() => const QuizState();

  Future<void> generate(String topic, {int count = 5}) async {
    state = const QuizState(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(ApiConstants.aiQuiz, data: {
        'topic': topic,
        'count': count,
      });
      final data = response.data['data'] ?? response.data;
      List<dynamic> raw = [];
      if (data is List) {
        raw = data;
      } else if (data is Map && data['questions'] != null) {
        raw = data['questions'] as List;
      }
      final questions = raw.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>)).toList();
      state = QuizState(questions: questions);
    } catch (e) {
      state = QuizState(error: extractErrorMessage(e));
    }
  }

  void selectAnswer(int questionIndex, int answerIndex) {
    if (state.submitted) return;
    final updated = Map<int, int>.from(state.selectedAnswers);
    updated[questionIndex] = answerIndex;
    state = state.copyWith(selectedAnswers: updated);
  }

  void submit() => state = state.copyWith(submitted: true);

  void next() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previous() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void reset() => state = const QuizState();
}

// ─── Flashcards Provider ──────────────────────────────────────────────────────

class FlashcardsState {
  final List<Flashcard> cards;
  final bool isLoading;
  final String? error;
  final int currentIndex;

  const FlashcardsState({
    this.cards = const [],
    this.isLoading = false,
    this.error,
    this.currentIndex = 0,
  });

  FlashcardsState copyWith({
    List<Flashcard>? cards,
    bool? isLoading,
    String? error,
    int? currentIndex,
    bool clearError = false,
  }) {
    return FlashcardsState(
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

final flashcardsProvider = NotifierProvider<FlashcardsNotifier, FlashcardsState>(FlashcardsNotifier.new);

class FlashcardsNotifier extends Notifier<FlashcardsState> {
  @override
  FlashcardsState build() => const FlashcardsState();

  Future<void> generate(String topic, {int count = 10}) async {
    state = const FlashcardsState(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(ApiConstants.aiFlashcards, data: {
        'topic': topic,
        'count': count,
      });
      final data = response.data['data'] ?? response.data;
      List<dynamic> raw = [];
      if (data is List) {
        raw = data;
      } else if (data is Map && data['flashcards'] != null) {
        raw = data['flashcards'] as List;
      }
      final cards = raw.map((c) => Flashcard.fromJson(c as Map<String, dynamic>)).toList();
      state = FlashcardsState(cards: cards);
    } catch (e) {
      state = FlashcardsState(error: extractErrorMessage(e));
    }
  }

  void flip(int index) {
    final updated = List<Flashcard>.from(state.cards);
    updated[index].flipped = !updated[index].flipped;
    state = state.copyWith(cards: updated);
  }

  void next() {
    if (state.currentIndex < state.cards.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previous() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void reset() => state = const FlashcardsState();
}

// ─── Summarize Provider ───────────────────────────────────────────────────────

final summarizeProvider = NotifierProvider<SummarizeNotifier, AiResponse>(SummarizeNotifier.new);

class SummarizeNotifier extends Notifier<AiResponse> {
  @override
  AiResponse build() => const AiResponse();

  Future<void> summarize(String text) async {
    state = const AiResponse(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(ApiConstants.aiSummarize, data: {'text': text});
      final data = response.data['data'] ?? response.data;
      state = AiResponse(content: data.toString());
    } catch (e) {
      state = AiResponse(error: extractErrorMessage(e));
    }
  }

  void clear() => state = const AiResponse();
}

// ─── AI History ───────────────────────────────────────────────────────────────

class AiHistoryEntry {
  final String type;
  final String prompt;
  final String result;
  final DateTime timestamp;

  AiHistoryEntry({
    required this.type,
    required this.prompt,
    required this.result,
    required this.timestamp,
  });
}

final aiHistoryProvider = NotifierProvider<AiHistoryNotifier, List<AiHistoryEntry>>(AiHistoryNotifier.new);

class AiHistoryNotifier extends Notifier<List<AiHistoryEntry>> {
  @override
  List<AiHistoryEntry> build() => [];

  void add({required String type, required String prompt, required String result}) {
    final entry = AiHistoryEntry(
      type: type,
      prompt: prompt,
      result: result,
      timestamp: DateTime.now(),
    );
    state = [entry, ...state.take(19)]; // keep last 20
  }

  void clear() => state = [];
}
