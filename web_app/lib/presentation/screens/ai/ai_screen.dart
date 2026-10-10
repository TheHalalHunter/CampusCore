import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/conversation_storage.dart';

// ---------------------------------------------------------------------------
// Message model
// ---------------------------------------------------------------------------
enum _MsgType { user, ai, error }

class _Message {
  final String text;
  final _MsgType type;
  final String? toolLabel;

  const _Message({
    required this.text,
    this.type = _MsgType.ai,
    this.toolLabel,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'type': type.name,
    'toolLabel': toolLabel,
  };

  factory _Message.fromJson(Map<String, dynamic> j) => _Message(
    text: j['text']?.toString() ?? '',
    type: _MsgType.values.firstWhere(
      (t) => t.name == j['type'],
      orElse: () => _MsgType.ai,
    ),
    toolLabel: j['toolLabel']?.toString(),
  );
}

// ---------------------------------------------------------------------------
// AI mode
// ---------------------------------------------------------------------------
enum _AiMode { explain, summarize, quiz, flashcards, predictTopics }

extension _AiModeLabel on _AiMode {
  String get label {
    switch (this) {
      case _AiMode.explain:       return 'Ask / Explain';
      case _AiMode.summarize:     return 'Summarize';
      case _AiMode.quiz:          return 'Quiz Me';
      case _AiMode.flashcards:    return 'Flashcards';
      case _AiMode.predictTopics: return 'Predict Topics';
    }
  }

  IconData get icon {
    switch (this) {
      case _AiMode.explain:       return Icons.lightbulb_outline;
      case _AiMode.summarize:     return Icons.summarize_outlined;
      case _AiMode.quiz:          return Icons.quiz_outlined;
      case _AiMode.flashcards:    return Icons.style_outlined;
      case _AiMode.predictTopics: return Icons.track_changes_outlined;
    }
  }

  String get hint {
    switch (this) {
      case _AiMode.explain:       return 'Ask anything or type a concept to explain...';
      case _AiMode.summarize:     return 'Paste the text you want summarized...';
      case _AiMode.quiz:          return 'Enter a topic to generate quiz questions...';
      case _AiMode.flashcards:    return 'Enter a topic to generate flashcards...';
      case _AiMode.predictTopics: return 'Enter course title, e.g. Fisheries Management...';
    }
  }
}

// ---------------------------------------------------------------------------
// Notifier � manages message list
// ---------------------------------------------------------------------------
const _kWelcome = _Message(
  text: "Hi! I'm your CampusCore AI Study Assistant 🎓\n\nChoose a mode below:\n• **Ask / Explain** — explain any concept\n• **Summarize** — paste text to summarize\n• **Quiz Me** — generate practice questions\n• **Flashcards** — create study cards\n• **Predict Topics** — likely exam topics",
  type: _MsgType.ai,
);

class _AiNotifier extends StateNotifier<List<_Message>> {
  final ApiClient _api;

  _AiNotifier(this._api, {List<_Message>? initial})
      : super(initial ?? const [_kWelcome]);

  bool _loading = false;
  bool get isLoading => _loading;

  void reset() => state = const [_kWelcome];

  void restore(List<_Message> messages) {
    state = messages.isEmpty ? const [_kWelcome] : messages;
  }

  Future<void> send(_AiMode mode, String input) async {
    if (input.trim().isEmpty || _loading) return;
    state = [...state, _Message(text: input.trim(), type: _MsgType.user)];
    _loading = true;
    try {
      switch (mode) {
        case _AiMode.explain:       await _explain(input.trim());       break;
        case _AiMode.summarize:     await _summarize(input.trim());     break;
        case _AiMode.quiz:          await _quiz(input.trim());          break;
        case _AiMode.flashcards:    await _flashcards(input.trim());    break;
        case _AiMode.predictTopics: await _predictTopics(input.trim()); break;
      }
    } catch (e) {
      final msg = e.toString().contains('403')
          ? 'AI is currently disabled during an exam period.'
          : 'Could not reach AI. Check your connection and try again.';
      state = [...state, _Message(text: msg, type: _MsgType.error)];
    } finally {
      _loading = false;
    }
  }

  Future<void> _explain(String concept) async {
    final resp = await _api.post(ApiConstants.aiExplain, data: {'concept': concept});
    final body = resp.data as Map<String, dynamic>;
    final text = body['data']?.toString() ?? body['message']?.toString() ?? 'No response.';
    state = [...state, _Message(text: text, type: _MsgType.ai, toolLabel: 'Explanation')];
  }

  Future<void> _summarize(String text) async {
    final resp = await _api.post(ApiConstants.aiSummarize, data: {'text': text});
    final body = resp.data as Map<String, dynamic>;
    final result = body['data']?.toString() ?? body['message']?.toString() ?? 'No summary.';
    state = [...state, _Message(text: result, type: _MsgType.ai, toolLabel: 'Summary')];
  }

  Future<void> _quiz(String topic) async {
    final resp = await _api.post(ApiConstants.aiQuiz, data: {'topic': topic, 'count': 5});
    final body = resp.data as Map<String, dynamic>;
    final questions = body['data'] as List? ?? [];
    if (questions.isEmpty) {
      state = [...state, _Message(text: 'Could not generate quiz questions. Try a different topic.', type: _MsgType.error)];
      return;
    }
    final sb = StringBuffer('Here are 5 quiz questions on **$topic**:\n\n');
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i] as Map<String, dynamic>;
      sb.writeln('${i + 1}. ${q['question']}');
      final opts = q['options'] as List? ?? [];
      for (int j = 0; j < opts.length; j++) {
        sb.writeln('   ${String.fromCharCode(65 + j)}. ${opts[j]}');
      }
      final correct = q['correctAnswer'] as int? ?? 0;
      sb.writeln('   ? Answer: ${String.fromCharCode(65 + correct)}. ${q['explanation'] ?? ''}');
      sb.writeln();
    }
    state = [...state, _Message(text: sb.toString().trim(), type: _MsgType.ai, toolLabel: 'Quiz')];
  }

  Future<void> _flashcards(String topic) async {
    final resp = await _api.post(ApiConstants.aiFlashcards, data: {'topic': topic, 'count': 8});
    final body = resp.data as Map<String, dynamic>;
    final cards = body['data'] as List? ?? [];
    if (cards.isEmpty) {
      state = [...state, _Message(text: 'Could not generate flashcards. Try a different topic.', type: _MsgType.error)];
      return;
    }
    final sb = StringBuffer('Here are ${cards.length} flashcards for **$topic**:\n\n');
    for (int i = 0; i < cards.length; i++) {
      final c = cards[i] as Map<String, dynamic>;
      sb.writeln('?? **${c['front']}**');
      sb.writeln('   ? ${c['back']}');
      sb.writeln();
    }
    state = [...state, _Message(text: sb.toString().trim(), type: _MsgType.ai, toolLabel: 'Flashcards')];
  }

  Future<void> _predictTopics(String courseTitle) async {
    final resp = await _api.post(ApiConstants.aiPredictTopics, data: {
      'courseTitle': courseTitle,
      'recentTopics': <String>[],
    });
    final body = resp.data as Map<String, dynamic>;
    final topics = body['data'] as List? ?? [];
    if (topics.isEmpty) {
      state = [...state, _Message(text: 'Could not predict topics. Try a more specific course name.', type: _MsgType.error)];
      return;
    }
    final sb = StringBuffer('Likely exam topics for **$courseTitle**:\n\n');
    for (final t in topics) { sb.writeln('• $t'); }
    state = [...state, _Message(text: sb.toString().trim(), type: _MsgType.ai, toolLabel: 'Predicted Topics')];
  }
}

final _aiProvider = StateNotifierProvider.autoDispose<_AiNotifier, List<_Message>>((ref) {
  return _AiNotifier(ref.read(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  _AiMode _mode     = _AiMode.explain;
  bool _sending     = false;

  // -- Conversation state ----------------------------------------------------
  String _currentConvId    = '';
  String _currentTitle     = 'New Conversation';
  bool   _titleSet         = false; // true once first user msg sets the title
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final all  = await ConversationStorage.loadAll();
    final last = await ConversationStorage.loadLast();
    setState(() => _conversations = all);

    if (last != null) {
      _restoreConversation(last);
    } else {
      _currentConvId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentTitle  = 'New Conversation';
      _titleSet      = false;
    }
  }

  void _restoreConversation(Map<String, dynamic> conv) {
    final messages = (conv['messages'] as List? ?? [])
        .map((m) => _Message.fromJson(m as Map<String, dynamic>))
        .toList();
    setState(() {
      _currentConvId = conv['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      _currentTitle  = conv['title']?.toString() ?? 'New Conversation';
      _titleSet      = messages.any((m) => m.type == _MsgType.user);
    });
    ref.read(_aiProvider.notifier).restore(messages);
    _scrollToBottom();
  }

  Future<void> _saveCurrentConversation(List<_Message> messages) async {
    // Preserve the original createdAt — only fall back to now() for brand-new conversations.
    final existing = _conversations.firstWhere(
      (c) => c['id']?.toString() == _currentConvId,
      orElse: () => <String, dynamic>{},
    );
    final createdAt = existing['createdAt']?.toString() ?? DateTime.now().toIso8601String();

    final conv = {
      'id':        _currentConvId,
      'title':     _currentTitle,
      'messages':  messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await ConversationStorage.saveConversation(conv);
    await ConversationStorage.saveLastId(_currentConvId);
    final all = await ConversationStorage.loadAll();
    if (mounted) setState(() => _conversations = all);
  }

  void _newConversation() {
    ref.read(_aiProvider.notifier).reset();
    setState(() {
      _currentConvId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentTitle  = 'New Conversation';
      _titleSet      = false;
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _inputCtrl.clear();

    // Auto-title from first user message
    if (!_titleSet) {
      setState(() {
        _currentTitle = text.length > 40 ? '${text.substring(0, 40)}...' : text;
        _titleSet     = true;
      });
    }

    setState(() => _sending = true);
    await ref.read(_aiProvider.notifier).send(_mode, text);
    setState(() => _sending = false);
    _scrollToBottom();

    // Persist after response
    final msgs = ref.read(_aiProvider);
    await _saveCurrentConversation(msgs);
  }

  Future<void> _renameConversation() async {
    final ctrl = TextEditingController(text: _currentTitle);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _currentTitle = result);
      final msgs = ref.read(_aiProvider);
      await _saveCurrentConversation(msgs);
    }
  }

  Future<void> _deleteConversation(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ConversationStorage.deleteConversation(id);
    final all = await ConversationStorage.loadAll();
    setState(() => _conversations = all);
    if (id == _currentConvId) _newConversation();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(_aiProvider);
    final width    = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isMobile  = Responsive.isMobile(context);

    ref.listen(_aiProvider, (_, __) => _scrollToBottom());

    final chatPanel = _buildChatPanel(messages, isMobile);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: GestureDetector(
                onTap: _renameConversation,
                child: Text(
                  _currentTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontFamily: 'Nunito', fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!isDesktop)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.history_outlined, color: AppColors.coreBlue),
                tooltip: 'Conversations',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          TextButton.icon(
            onPressed: _newConversation,
            icon: const Icon(Icons.add, color: AppColors.coreBlue, size: 16),
            label: const Text('New Chat',
                style: TextStyle(color: AppColors.coreBlue, fontFamily: 'Nunito', fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isDesktop ? null : Drawer(
        backgroundColor: AppColors.navyMid,
        child: _buildConversationsList(),
      ),
      body: isDesktop
          ? Row(
              children: [
                SizedBox(width: 260, child: _buildConversationsList()),
                const VerticalDivider(width: 1, color: AppColors.border),
                Expanded(child: chatPanel),
              ],
            )
          : chatPanel,
    );
  }

  Widget _buildConversationsList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          color: AppColors.navyDark,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Conversations',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.coreBlue, size: 20),
                tooltip: 'New conversation',
                onPressed: _newConversation,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        Expanded(
          child: _conversations.isEmpty
              ? const Center(
                  child: Text(
                    'No saved conversations yet.',
                    style: TextStyle(color: AppColors.textOnDarkSub, fontSize: 12, fontFamily: 'Nunito'),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conv    = _conversations[index];
                    final id      = conv['id']?.toString() ?? '';
                    final title   = conv['title']?.toString() ?? 'Conversation';
                    final updated = DateTime.tryParse(conv['updatedAt']?.toString() ?? '');
                    final isActive = id == _currentConvId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        title: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive ? Colors.white : AppColors.textOnDarkSub,
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        subtitle: updated != null
                            ? Text(
                                DateFormat('MMM d').format(updated),
                                style: const TextStyle(
                                    color: AppColors.textOnDarkSub,
                                    fontSize: 10,
                                    fontFamily: 'Nunito'),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textOnDarkSub),
                          tooltip: 'Delete',
                          onPressed: () => _deleteConversation(id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                        onTap: () {
                          if (id != _currentConvId) _restoreConversation(conv);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatPanel(List<_Message> messages, bool isMobile) {
    return Column(
      children: [
        // Disclaimer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          color: AppColors.warning.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.warning, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI can make mistakes. Do not use for live exam answers. Always verify with your lecturer.',
                  style: TextStyle(color: AppColors.warning, fontSize: isMobile ? 10 : 11, fontFamily: 'Nunito'),
                ),
              ),
            ],
          ),
        ),

        // Mode selector
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _AiMode.values.map((mode) {
                final selected = _mode == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(mode.icon, size: 14,
                              color: selected ? Colors.white : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            mode.label,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.textSecondary,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Messages
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                itemCount: messages.length,
                itemBuilder: (context, index) =>
                    _MessageBubble(message: messages[index], isMobile: isMobile),
              ),
            ),
          ),
        ),

        // Typing indicator
        if (_sending)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 10),
                Text('${_mode.label} in progress...',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 12, fontStyle: FontStyle.italic, fontFamily: 'Nunito')),
                const SizedBox(width: 8),
                const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              ],
            ),
          ),

        // Input bar
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: 12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: _mode == _AiMode.summarize ? 8 : 4,
                      textInputAction: _mode == _AiMode.summarize
                          ? TextInputAction.newline
                          : TextInputAction.send,
                      onSubmitted: _mode == _AiMode.summarize ? null : (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _mode.hint,
                        hintStyle: const TextStyle(color: AppColors.textHint, fontFamily: 'Nunito'),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: _sending ? AppColors.border : AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _sending ? null : _send,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _sending ? Icons.hourglass_empty : Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------
class _MessageBubble extends StatelessWidget {
  final _Message message;
  final bool isMobile;
  const _MessageBubble({required this.message, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final isUser  = message.type == _MsgType.user;
    final isError = message.type == _MsgType.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: isError
                    ? const LinearGradient(colors: [AppColors.error, AppColors.error])
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(isError ? Icons.error_outline : Icons.auto_awesome,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.toolLabel != null && !isUser) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      message.toolLabel!,
                      style: const TextStyle(
                        color: AppColors.primary, fontSize: 10,
                        fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : isError
                            ? AppColors.error.withValues(alpha: 0.08)
                            : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser ? null : Border.all(
                      color: isError
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4, offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : isError ? AppColors.error : AppColors.textPrimary,
                      fontSize: isMobile ? 13 : 14,
                      height: 1.6,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}
